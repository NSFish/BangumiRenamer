//
//  NSFBangumiRenamer.m
//  ConanSeriesRenamer
//
//  Created by nsfish on 2020/2/6.
//  Copyright © 2020 nsfish. All rights reserved.
//

#import "NSFBangumiRenamer.h"
#import "NSFSeriesNumberPart.h"
#import "NSString+NSFExt.h"
#import "NSURL+NSFExt.h"

// 从 source.txt 中读取到的剧集名称数，用于判断是否需要为集数补 0
NSUInteger g_seriesCount = 0;

typedef NSMutableDictionary<NSString *, NSString *> * Source;
typedef NSDictionary<NSString *, NSString *> * Rules;

@implementation NSFBangumiRenamer

+ (NSArray<NSString *> *)renameFilesIn:(NSURL *)directoryURL
                            withSource:(NSURL *)sourceFileURL
                               pattern:(NSURL *)patternFileURL
                                  rule:(nullable NSURL *)ruleFileURL
                     specificExtension:(nullable NSString *)specificExtension
                                 order:(BOOL)order
                                dryrun:(BOOL)dryrun
{
    NSMutableArray<NSString *> *fileNames = [NSMutableArray array];
    
    NSString *content = [NSString stringWithContentsOfURL:patternFileURL
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    NSArray<NSString *> *patterns = [content componentsSeparatedByString:@"\n"];
    Rules rules = [self rulesFrom:ruleFileURL];
    
    Source source = [NSFBangumiRenamer sourceFrom:sourceFileURL
                                         patterns:patterns
                                            rules:rules];
    NSArray<NSURL *> *filesToBeRenamed = [NSFBangumiRenamer filesToBeRenamedIn:directoryURL
                                                             specificExtension:specificExtension];
    
    [filesToBeRenamed enumerateObjectsUsingBlock:^(NSURL *fileURL, NSUInteger _, BOOL *stop) {
        NSString *newFileName = [self figureOutNewNameOfFile:fileURL
                                                    patterns:patterns
                                                      source:source
                                                       rules:rules
                                                       order:order];
        if (newFileName)
        {
            if (dryrun)
            {
                [fileNames addObject:newFileName];
            }
            else
            {
                BOOL succeeded = [self tryRenameFile:fileURL withNewName:newFileName];
                if (!succeeded)
                {
                    
                }
            }
        }
        else
        {
            printf("无法从文件名 %s 中识别出集数\n", [fileURL.lastPathComponent cStringUsingEncoding:NSUTF8StringEncoding]);
        }
    }];
    
    printf("Done.\n");
    
    return fileNames;
}

#pragma mark - Source
+ (Source)sourceFrom:(NSURL *)sourceFileURL
            patterns:(NSArray<NSString *> *)patterns
               rules:(Rules)rules
{
    Source source = [NSMutableDictionary dictionary];
    
    NSString *content = [NSString stringWithContentsOfURL:sourceFileURL
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    NSArray<NSString *> *lines = [content componentsSeparatedByString:@"\n"];
    g_seriesCount = lines.count;
    [lines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger idx, BOOL *stop) {
        if (line.length >= 3)
        {
            NSFSeriesNumberPart *seriesNumberPart = [self tryExtractSeriesNumberPartFromSourceFileLine:line patterns:patterns];
            
            BOOL cannotDetectSeriesNumber = NO;
            if (!seriesNumberPart)
            {
                cannotDetectSeriesNumber = YES;
            }
            
            NSString *seriesNumber = [self trimString:seriesNumberPart.content with:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
            if (seriesNumber.length == 0)
            {
                cannotDetectSeriesNumber = YES;
            }
            
            if (cannotDetectSeriesNumber)
            {
                printf("无法从源文件中的这一行: [%s] 中识别出集数, 跳过", [line UTF8String]);
            }
            else
            {
                NSString *newSeriesNumber = [self fillInSeriesNumberIfNeeded:seriesNumber];
                
                // 替换上补全后的集数
                NSString *fileName = [line stringByReplacingOccurrencesOfString:seriesNumberPart.content
                                                                     withString:newSeriesNumber
                                                                        options:0
                                                                          range:seriesNumberPart.range];
                
                // 移除文件名首尾的空格
                fileName = [fileName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                // 将集数相同但有"前篇""后篇"之分的剧集按 rules 中的规定拆分
                NSString *extraSeriesNumber = [self extraSeriesNumber:newSeriesNumber inFileName:fileName rules:rules];
                if (extraSeriesNumber.length > 0)
                {
                    NSString *editedSeriesNumber = [NSString stringWithFormat:@"%@%@", newSeriesNumber, extraSeriesNumber];
                    fileName = [fileName stringByReplacingOccurrencesOfString:newSeriesNumber withString:editedSeriesNumber];
                    newSeriesNumber = editedSeriesNumber;
                }
                
                source[newSeriesNumber] = fileName;
            }
        }
    }];
    
    return source;
}

/// 从 source 的一行中提取集数
+ (nullable NSFSeriesNumberPart *)tryExtractSeriesNumberPartFromSourceFileLine:(NSString *)line
                                                                      patterns:(NSArray<NSString *> *)patterns
{
    // 不直接返回 string，而是专门构造了 NSFSeriesNumberPart，是为了把 part 所在的 NSRange 也传回来
    // 比如 "11（11~12） 钢琴奏鸣曲《月光》杀人事件★"
    // 用正则 "[0-9]{1,3}（"，取到的集数是最前面的 "11"，而剧集 part 是 "11（"
    // "11" 经过填充后变成了 "011"
    // 此时就可以用 "011" 替换掉 part.range 范围内的字符串，变成 "011（"
    // 而不会影响到括号内部的 "11"
    __block NSFSeriesNumberPart *seriesNumberPart = nil;
    [patterns enumerateObjectsUsingBlock:^(NSString *pattern, NSUInteger idx, BOOL *stop) {
        NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern
                                                                          options:NSRegularExpressionCaseInsensitive
                                                                            error:nil];
        NSRange range = [regex rangeOfFirstMatchInString:line
                                                 options:0
                                                   range:NSMakeRange(0, line.length)];
        
        if (range.location != NSNotFound)
        {
            seriesNumberPart = [NSFSeriesNumberPart partWithContent:[line substringWithRange:range] range:range];
            *stop = YES;
        }
    }];
    
    return seriesNumberPart;
}

#pragma mark - Files
+ (NSArray<NSURL *> *)filesToBeRenamedIn:(NSURL *)destDirectoryURL
                       specificExtension:(nullable NSString *)specificExtension
{
    NSMutableArray<NSURL *> *filesToBeRenamed = [NSMutableArray array];
    
    // 将 destDirectoryURL 下包括子文件夹在内的所有文件一口气读取出来
    // https://stackoverflow.com/a/5750519
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:destDirectoryURL
                                         includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                         options:NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                         errorHandler:^BOOL(NSURL *url, NSError *error) {
        return YES;
    }];
    
    for (NSURL *url in enumerator)
    {        
        if (specificExtension)
        {
            NSString *pathExtension = [[url nsf_pathExtension] lowercaseString];
            if ([pathExtension isEqualToString:specificExtension])
            {
                [filesToBeRenamed addObject:url];
            }
        }
        else if (!url.hasDirectoryPath)
        {
            if ([self worthDeal:url])
            {
                [filesToBeRenamed addObject:url];
            }
        }
        else
        {
            // 子文件夹，什么也不做
        }
    }
    
    return filesToBeRenamed;
}

/// 从文件名中提取集数
/// 和 source 中不同的是，文件名的格式可谓是千奇百怪，所以需要额外的过滤处理
/// 且由于不需要保留文件名原本的格式，直接返回取到的集数即可，无需构造 NSFSeriesNumberPart
+ (nullable NSString *)tryExtractSeriesNumberFromFileName:(NSString *)fileName
                                                 patterns:(NSArray<NSString *> *)patterns
                                                    rules:(Rules)rules
{
    __block NSString *seriesNumber = nil;
    
    NSMutableArray<NSString *> *possibleSeriesNumbers = [NSMutableArray array];
    [patterns enumerateObjectsUsingBlock:^(NSString *pattern, NSUInteger _, BOOL *stop) {
        NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern
                                                                          options:NSRegularExpressionCaseInsensitive
                                                                            error:nil];
        NSRange range = [regex rangeOfFirstMatchInString:fileName
                                                 options:0
                                                   range:NSMakeRange(0, fileName.length)];
        
        if (range.location != NSNotFound
            && range.length > 0)
        {
            NSString *string = [fileName substringWithRange:range];
            // 版本 1.4：原本的做法是
            // NSString *seriesNumber = [self trimString:string with:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
            // 这样就无法处理类似 "S02E01"，对应正则 "S02E[0-9]{2}" 这样从文件名中匹配出的部分包含不止一个数字的 case
            // 考虑到剧集总是在最后的，取最后一个数字
            NSCharacterSet *dot = [NSCharacterSet characterSetWithCharactersInString:@"."];
            NSMutableCharacterSet *usefulSet = [NSMutableCharacterSet new];
            [usefulSet formUnionWithCharacterSet:dot];
            [usefulSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
            NSArray<NSString *> *array = [string componentsSeparatedByCharactersInSet:[usefulSet invertedSet]];
            
            // 版本 1.4.3：原本的做法是
            // NSString *seriesNumber = [[string componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] lastObject];
            // 对于 "[001]" 这样的 case，会以 "[" 和 "]" 把字符串拆分成 ["", "001", ""]，导致取数组的 lastObject 取到空串
            // 改为从后遍历，取第一个非空字符串
            NSMutableArray<NSString *> *mArray = [array mutableCopy];
            [mArray removeObject:@""];
            
            [possibleSeriesNumbers addObject:mArray.lastObject];
        }
    }];
    
    // 多个匹配结果中取最长值
    // 比如 "83" 和 "83.5" 取后者
    [possibleSeriesNumbers enumerateObjectsUsingBlock:^(NSString *possibleSeriesNumber, NSUInteger _, BOOL *stop) {
        if (possibleSeriesNumber.length > seriesNumber.length)
        {
            seriesNumber = possibleSeriesNumber;
        }
    }];
    
    // 文件名中可能本身已经包含了"前篇"等字样，所以也要和 source 那边一样
    // 将集数相同但有"前篇""后篇"之分的剧集按 rules 中的规定拆分
    if (![seriesNumber containsString:@"."])
    {
        NSString *extraSeriesNumber = [self extraSeriesNumber:seriesNumber inFileName:fileName rules:rules];
        if (extraSeriesNumber.length > 0)
        {
            NSString *editedSeriesNumber = [NSString stringWithFormat:@"%@%@", seriesNumber, extraSeriesNumber];
            fileName = [fileName stringByReplacingOccurrencesOfString:seriesNumber withString:editedSeriesNumber];
            seriesNumber = editedSeriesNumber;
        }
    }
    
    return seriesNumber;
}

+ (nullable NSString *)figureOutNewNameOfFile:(NSURL *)fileURL
                                     patterns:(NSArray<NSString *> *)patterns
                                       source:(Source)source
                                        rules:(Rules)rules
                                        order:(BOOL)order
{
    NSString *newFileName = nil;
    NSString *fileName = [fileURL lastPathComponent];
    
    // 1. 首先尝试从文件名中提取到集数
    NSString *seriesNumber = [self tryExtractSeriesNumberFromFileName:fileName
                                                             patterns:patterns
                                                                rules:rules];
    
    // 2. 若提取失败，则直接返回 nil，上层调用处会统一报错
    if (seriesNumber.length == 0)
    {
        return nil;
    }
    
    // 3. 提取成功后，先判断要不要根据设定的基数整体平移集数：
    // 以 JOJO 的《石之海》为例
    // source.txt 里是 64-80 卷，但是下载来的东立的漫画文件名是 01-17
    // 则需要取出 source.txt 中的基数，然后 apply 到最终的 seriesNumber 上
    if (order)
    {
        NSArray<NSString *> *keys = [source.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *left, NSString *right) {
            return left.integerValue > right.integerValue;
        }];
        NSInteger basic = keys.firstObject.integerValue;
        NSInteger temp = seriesNumber.intValue;
        seriesNumber = @(temp + basic - 1).stringValue;
    }
    
    // 4. 适当为集数补零
    seriesNumber = [self fillInSeriesNumberIfNeeded:seriesNumber];
    
    NSString *correctFileName = source[seriesNumber];
    correctFileName = [self legalizeIfNeeded:correctFileName];
    if (correctFileName.length > 0)
    {
        newFileName = correctFileName;
    }
    
    return newFileName;
}

+ (BOOL)tryRenameFile:(NSURL *)fileURL withNewName:(NSString *)newFileName
{
    BOOL succeeded = YES;
    
    NSString *filePath = fileURL.path;
    NSString *pathExtension = [fileURL nsf_pathExtension];
    NSString *correctFilePath = [[[filePath stringByDeletingLastPathComponent]
                                  stringByAppendingPathComponent:newFileName]
                                 stringByAppendingPathExtension:pathExtension];
    
    NSError *error = nil;
    // 若已经存在同名文件，说明该文件已经 Renamed 过了，直接跳过
    if (![[NSFileManager defaultManager] fileExistsAtPath:correctFilePath])
    {
        [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:correctFilePath error:&error];
    }
    
    if (error)
    {
        printf("重命名文件 %s 失败，error: %s", [[filePath lastPathComponent] UTF8String], [[error localizedFailureReason] UTF8String]);
        succeeded = NO;
    }
    
    return succeeded;
}

#pragma mark - 前篇、后篇
+ (NSMutableDictionary<NSString *, NSString *> *)rulesFrom:(NSURL *)ruleFileURL
{
    NSMutableDictionary<NSString *, NSString *> *dict = [NSMutableDictionary dictionary];
    if (!ruleFileURL)
    {
        return dict;
    }
    
    NSString *content = [NSString stringWithContentsOfURL:ruleFileURL
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    NSArray<NSString *> *lines = [content componentsSeparatedByString:@"\n"];
    for (NSString *line in lines)
    {
        NSArray *array = [line componentsSeparatedByString:@"->"];
        NSString *key = [array.firstObject nsf_trim];
        NSString *value = [[array.lastObject nsf_trim:[NSCharacterSet characterSetWithCharactersInString:@"\""]] nsf_trim];
        
        dict[key] = value;
    }
    
    return dict;
}

/// 处理"80 XXX（前篇）""80 XXX（后篇）"这样的特殊情况
+ (NSString *)extraSeriesNumber:(NSString *)seriesNumber
                     inFileName:(NSString *)fileName
                          rules:(Rules)rules
{
    // 1. 先找出当前文件名中包含的关键词，比如"前篇""后篇"
    __block NSString *matchedKey = nil;
    [rules.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger _, BOOL *stop) {
        if ([fileName containsString:key])
        {
            matchedKey = key;
            *stop = YES;
        }
    }];
    
    // 2. 然后从 rules 中提取额外的集数部分
    // 比如 "后篇" -> "0.5"
    return rules[matchedKey];
}

#pragma mark - Helper
/// 如果 source.txt 中的剧集名超过三位数，则将传入的不足三位数的剧集集数补全
/// @param seriesNumber 剧集集数
+ (NSString *)fillInSeriesNumberIfNeeded:(NSString *)seriesNumber
{
    // 若传入的集数包含小数点，则先截取出整数部分
    NSString *intPart = seriesNumber;
    NSString *decimalsPart = @"";
    NSArray *array = [seriesNumber componentsSeparatedByString:@"."];
    if (array.count > 1)
    {
        intPart = array.firstObject;
        decimalsPart = array.lastObject;
    }
    
    NSUInteger formatSeriesNumberLength = g_seriesCount >= 100 ? 3 : 2;
    
    // NSUInteger 总是大于 0，如果 formatSeriesNumberLength < intPart.length
    // 得到的 length 会是一个超级大的数字，导致循环无法退出
    if (formatSeriesNumberLength > intPart.length)
    {
        NSUInteger length = formatSeriesNumberLength - intPart.length;
        for (NSUInteger i = 0; i < length; ++i)
        {
            intPart = [@"0" stringByAppendingString:intPart];
        }
    }
    
    NSString *result = intPart;
    if (array.count > 1)
    {
        result = [NSString stringWithFormat:@"%@.%@", intPart, decimalsPart];
    }
    
    return result;
}

/// 去除非法命名字符
/// @param fileName 文件名
+ (NSString *)legalizeIfNeeded:(NSString *)fileName
{
    // 用 : 来替代路径分隔符 /，比如 "287（309） 工藤新一纽约事件（推理篇） B/S"，在 Finder 中仍然会正常显示
    // https://stackoverflow.com/a/60105599/2135264
    fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@":"];
    
    return fileName;
}

+ (NSString *)trimString:(NSString *)string with:(NSCharacterSet *)characterSet
{
    return [[string componentsSeparatedByCharactersInSet:characterSet] componentsJoinedByString:@""];
}

// 根据 MIMEType 过滤掉非视频和字幕文件
// .DS_Store 之类的隐藏文件也在其中，无须再单独处理
+ (BOOL)worthDeal:(NSURL *)url
{
    NSString *MIMEType = nil;
    
    // macOS 下 mkv 文件和字幕文件返回的 MIMEType 都是 null，只好硬编码了
    NSString *const kVideo = @"video";
    NSString *const kSubtitles = @"subtitles";
    NSString *pathExtension = [url.pathExtension lowercaseString];
    if ([pathExtension isEqualToString:@"mkv"])
    {
        MIMEType = [NSString stringWithFormat:@"%@/%@", kVideo, pathExtension];
    }
    else if ([pathExtension isEqualToString:@"ass"]
             || [pathExtension isEqualToString:@"ssa"]
             || [pathExtension isEqualToString:@"srt"])
    {
        MIMEType = [NSString stringWithFormat:@"%@/%@", kSubtitles, pathExtension];
    }
    else
    {
        // https://stackoverflow.com/questions/41219416/get-mime-type-from-nsurl
        CFStringRef fileExtension = (__bridge CFStringRef)[url pathExtension];
        CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
        CFStringRef cfMIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
        CFRelease(UTI);
        
        MIMEType = (__bridge_transfer NSString *)cfMIMEType;
    }
    
    return [MIMEType hasPrefix:kVideo]
    || [MIMEType hasPrefix:kSubtitles];
}

@end






