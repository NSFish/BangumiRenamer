//
//  NSFBangumiRenamer.m
//  ConanSeriesRenamer
//
//  Created by nsfish on 2020/2/6.
//  Copyright © 2020 nsfish. All rights reserved.
//

#import "NSFBangumiRenamer.h"
#import "NSFSeriesNumberPart.h"

// 从 source.txt 中读取到的剧集名称数，用于判断是否需要为剧集数补 0
NSUInteger g_seriesCount = 0;

@implementation NSFBangumiRenamer

+ (NSArray<NSString *> *)renameFilesIn:(NSURL *)directoryURL
                            withSource:(NSURL *)sourceFileURL
                               pattern:(NSURL *)patternFileURL
                                dryrun:(BOOL)dryrun
{
    NSMutableArray<NSString *> *fileNames = [NSMutableArray array];
    
    NSString *content = [NSString stringWithContentsOfURL:patternFileURL
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    NSArray<NSString *> *patterns = [content componentsSeparatedByString:@"\n"];
    
    NSDictionary<NSString*, NSString*> *seriesDict = [NSFBangumiRenamer seriesFrom:sourceFileURL patterns:patterns];
    NSArray<NSURL *> *filesToBeRenamed = [NSFBangumiRenamer filesToBeRenamedIn:directoryURL];
    
    [filesToBeRenamed enumerateObjectsUsingBlock:^(NSURL *fileURL, NSUInteger idx, BOOL *stop) {
        [patterns enumerateObjectsUsingBlock:^(NSString *pattern, NSUInteger idx, BOOL *stop) {
            NSString *newFileName = [self figureOutNewNameOfFile:fileURL pattern:pattern seriesDict:seriesDict];
            if (newFileName)
            {
                if (dryrun)
                {
                    [fileNames addObject:newFileName];
                    *stop = YES;
                }
                else
                {
                    BOOL succeeded = [self tryRenameFile:fileURL withNewName:newFileName];
                    if (succeeded)
                    {
                        *stop = YES;
                    }
                }
            }
        }];
    }];
    
    printf("Done.\n");
    
    return fileNames;
}

#pragma mark - Private
+ (NSDictionary<NSString*, NSString*> *)seriesFrom:(NSURL *)sourceFileURL patterns:(NSArray<NSString *> *)patterns
{
    NSMutableDictionary<NSString*, NSString*> *seriesDict = [NSMutableDictionary dictionary];
    
    NSString *content = [NSString stringWithContentsOfURL:sourceFileURL
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    NSArray<NSString *> *lines = [content componentsSeparatedByString:@"\n"];
    g_seriesCount = lines.count;
    [lines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger idx, BOOL *stop) {
        if (line.length >= 3)
        {
            __block NSFSeriesNumberPart *seriesNumberPart = nil;
            [patterns enumerateObjectsUsingBlock:^(NSString *pattern, NSUInteger idx, BOOL *stop) {
                // 不直接返回 string，而专门构造了 NSFSeriesNumberPart，是为了把 part 所在的 NSRange 也传回来
                // 比如 "11（11~12） 钢琴奏鸣曲《月光》杀人事件★"
                // 用正则 "[0-9]{1,3}（"，取到的剧集数是最前面的 "11"，而剧集 part 是 "11（"
                // "11" 经过填充后变成了 "011"
                // 此时就可以用 "011" 替换掉 part.range 范围内的字符串，变成 "011（"
                // 而不会影响到括号内部的 "11"
                seriesNumberPart = [self tryExtractSeriesNumberPartFromFileName:line pattern:pattern];
                if (seriesNumberPart)
                {
                    *stop = YES;
                }
            }];
            
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
                NSLog(@"无法从源文件中的这一行: [%@] 中识别出剧集数, 跳过", line);
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
                
                seriesDict[newSeriesNumber] = fileName;
            }
        }
    }];
    
    return seriesDict;
}

+ (nullable NSFSeriesNumberPart *)tryExtractSeriesNumberPartFromFileName:(NSString *)fileName pattern:(NSString *)pattern
{
    NSFSeriesNumberPart *part = nil;
    
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange range = [regex rangeOfFirstMatchInString:fileName
                                             options:0
                                               range:NSMakeRange(0, fileName.length)];
    
    if (range.location != NSNotFound)
    {
        part = [NSFSeriesNumberPart partWithContent:[fileName substringWithRange:range] range:range];
    }
    
    return part;
}

+ (NSArray<NSURL *> *)filesToBeRenamedIn:(NSURL *)destDirectoryURL
{
    NSMutableArray<NSURL *> *filesToBeRenamed = [NSMutableArray array];
    
    // 将 destDirectoryURL 下包括子文件夹在内的所有文件一口气读取出来
    // https://stackoverflow.com/a/5750519
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:destDirectoryURL
                                         includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                         options:0
                                         errorHandler:^BOOL(NSURL *url, NSError *error) {
        return YES;
    }];
    
    for (NSURL *url in enumerator)
    {
        NSError *error = nil;
        NSNumber *isDirectory = nil;
        if (![url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            // handle error
        }
        else if (![isDirectory boolValue])
        {
            if (![[url lastPathComponent] hasPrefix:@"."]) // 过滤掉 .DS_Store 之类的隐藏文件
            {
                [filesToBeRenamed addObject:url];
            }
            // No error and it’s not a directory; do something with the file
        }
        else
        {
            // 子文件夹，什么也不做
        }
    }
    
    return filesToBeRenamed;
}

+ (nullable NSString *)figureOutNewNameOfFile:(NSURL *)fileURL pattern:(NSString *)pattern seriesDict:(NSDictionary<NSString*, NSString*> *)seriesDict
{
    NSString *newFileName = nil;
    NSString *fileName = [fileURL lastPathComponent];
    
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange range = [regex rangeOfFirstMatchInString:fileName
                                             options:0
                                               range:NSMakeRange(0, fileName.length)];
    
    if (range.location != NSNotFound)
    {
        NSString *string = [fileName substringWithRange:range];
        // 1.4：原本的做法是
        // NSString *seriesNumber = [self trimString:string with:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
        // 这样就无法处理类似 "S02E01"，对应正则 "S02E[0-9]{2}" 这样从文件名中匹配出的部分包含不止一个数字的 case
        // 考虑到剧集总是在最后的，取最后一个数字
        NSArray<NSString *> *array = [string componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
        __block NSString *seriesNumber = nil;
        
        // 1.4.3：原本的做法是
        // NSString *seriesNumber = [[string componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] lastObject];
        // 对于 "[001]" 这样的 case，会以 "[" 和 "]" 把字符串拆分成 ["", "001", ""]，导致取数组的 lastObject 取到空串
        // 改为从后遍历，取第一个非空字符串
        [array enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString *str, NSUInteger idx, BOOL *stop) {
            if (str.length > 0)
            {
                seriesNumber = str;
                *stop = YES;
            }
        }];
        seriesNumber = [self fillInSeriesNumberIfNeeded:seriesNumber];
        
        NSString *correctFileName = seriesDict[seriesNumber];
        correctFileName = [self legalizeIfNeeded:correctFileName];
        if (correctFileName.length > 0)
        {
            newFileName = correctFileName;
        }
    }
    
    return newFileName;
}

+ (BOOL)tryRenameFile:(NSURL *)fileURL withNewName:(NSString *)newFileName
{
    BOOL succeeded = YES;
    
    // 拼接出正确的文件名要用
    // [NSString stringByDeletingLastPathComponent:]
    // [NSString stringByAppendingPathComponent:]
    // 等方法，这里干脆直接用 path
    NSString *filePath = fileURL.path;
    NSString *pathExtension = [filePath pathExtension];
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
        NSLog(@"Rename file at %@ failed, error: %@", filePath, error);
        succeeded = NO;
    }
    
    return succeeded;
}

#pragma mark - Helper
/// 如果 source.txt 中的剧集名超过三位数，则将传入的不足三位数的剧集集数补全
/// @param seriesNumber 剧集集数
+ (NSString *)fillInSeriesNumberIfNeeded:(NSString *)seriesNumber
{
    NSUInteger formatSeriesNumberLength = g_seriesCount >= 100 ? 3 : 2;
    NSUInteger length = formatSeriesNumberLength - seriesNumber.length;
    for (NSUInteger i = 0; i < length; ++i)
    {
        seriesNumber = [@"0" stringByAppendingString:seriesNumber];
    }
    
    return seriesNumber;
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

@end






