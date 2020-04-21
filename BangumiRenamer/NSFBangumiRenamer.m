//
//  NSFBangumiRenamer.m
//  ConanSeriesRenamer
//
//  Created by nsfish on 2020/2/6.
//  Copyright © 2020 nsfish. All rights reserved.
//

#import "NSFBangumiRenamer.h"

@implementation NSFBangumiRenamer

+ (void)renameFilesIn:(NSString *)destDirectoryPath withSource:(NSString *)sourceFilePath pattern:(NSString *)patternFilePath
{
    NSString *content = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:patternFilePath]
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    NSArray<NSString *> *patterns = [content componentsSeparatedByString:@"\n"];
    
    NSDictionary<NSString*, NSString*> *seriesDict = [NSFBangumiRenamer seriesFrom:sourceFilePath patterns:patterns];
    NSArray<NSString *> *filesToBeRenamed = [NSFBangumiRenamer filesToBeRenamedIn:destDirectoryPath];
    
    [filesToBeRenamed enumerateObjectsUsingBlock:^(NSString *filePath, NSUInteger idx, BOOL *stop) {
        [patterns enumerateObjectsUsingBlock:^(NSString *pattern, NSUInteger idx, BOOL *stop) {
            BOOL succeeded = [self tryRenameFile:filePath pattern:pattern seriesDict:seriesDict];
            if (succeeded)
            {
                *stop = YES;
            }
        }];
    }];
    
    NSLog(@"Done.");
}

#pragma mark - Private
+ (NSDictionary<NSString*, NSString*> *)seriesFrom:(NSString *)sourceFilePath patterns:(NSArray<NSString *> *)patterns
{
    NSMutableDictionary<NSString*, NSString*> *seriesDict = [NSMutableDictionary dictionary];
    
    NSString *content = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:sourceFilePath]
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    NSArray<NSString *> *lines = [content componentsSeparatedByString:@"\n"];
    [lines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger idx, BOOL *stop) {
        if (line.length >= 3)
        {
            __block NSString *seriesNumberPart = nil;
            [patterns enumerateObjectsUsingBlock:^(NSString *pattern, NSUInteger idx, BOOL *stop) {
                seriesNumberPart = [self tryExtractSeriesNumberPartFromFileName:line pattern:pattern];
                if (seriesNumberPart)
                {
                    *stop = YES;
                }
            }];
            
            if (seriesNumberPart)
            {
                NSString *seriesNumber = [self trimString:seriesNumberPart with:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
                seriesNumber = [self trimString:seriesNumber with:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
                seriesNumber = [self fillInSeriesNumberIfNeeded:seriesNumber];
                
                // 替换上补全后的集数
                NSString *fileName = [line stringByReplacingOccurrencesOfString:seriesNumberPart withString:@""];
                // 移除文件名首尾的空格
                fileName = [fileName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                fileName = [NSString stringWithFormat:@"%@ %@", seriesNumber, fileName];
                
                seriesDict[seriesNumber] = fileName;
            }
            else
            {
                // TODO: 如何处理无法识别出剧集的文件？
            }
        }
    }];
    
    return seriesDict;
}

+ (nullable NSString *)tryExtractSeriesNumberPartFromFileName:(NSString *)fileName pattern:(NSString *)pattern
{
    NSString *seriesNumberPart = nil;
    
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange range = [regex rangeOfFirstMatchInString:fileName
                                             options:0
                                               range:NSMakeRange(0, fileName.length)];
    
    if (range.location != NSNotFound)
    {
        seriesNumberPart = [fileName substringWithRange:range];
    }
    
    return seriesNumberPart;
}

+ (NSArray<NSString *> *)filesToBeRenamedIn:(NSString *)destDirectoryPath
{
    NSMutableArray<NSString *> *filesToBeRenamed = [NSMutableArray array];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:destDirectoryPath error:nil];
    [contents enumerateObjectsUsingBlock:^(NSString *contentName, NSUInteger idx, BOOL *stop) {
        BOOL flag = YES;
        NSString *fullPath = [destDirectoryPath stringByAppendingPathComponent:contentName];
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&flag])
        {
            if (!flag)
            {
                if (![[contentName substringToIndex:1] isEqualToString:@"."]) // 过滤掉 .DS_Store
                {
                    [filesToBeRenamed addObject:fullPath];
                }
            }
        }
    }];
    
    return filesToBeRenamed;
}

+ (BOOL)tryRenameFile:(NSString *)filePath pattern:(NSString *)pattern seriesDict:(NSDictionary<NSString*, NSString*> *)seriesDict
{
    __block BOOL succeeded = YES;
    
    NSString *fileName = [filePath lastPathComponent];
    
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange range = [regex rangeOfFirstMatchInString:fileName
                                             options:0
                                               range:NSMakeRange(0, fileName.length)];
    
    if (range.location == NSNotFound)
    {
        succeeded = NO;
    }
    else
    {
        NSString *string = [fileName substringWithRange:range];
        NSString *seriesNumber = [self trimString:string with:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
        seriesNumber = [self fillInSeriesNumberIfNeeded:seriesNumber];
        
        NSString *correctFileName = seriesDict[seriesNumber];
        correctFileName = [self legalizeIfNeeded:correctFileName];
        if (correctFileName.length > 0)
        {
            NSString *pathExtension = [filePath pathExtension];
            NSString *correctFilePath = [[[filePath stringByDeletingLastPathComponent]
                                          stringByAppendingPathComponent:correctFileName]
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
        }
    }
    
    return succeeded;
}

#pragma mark - Helper
/// 将不足三位数的剧集集数补全
/// @param seriesNumber 剧集集数
+ (NSString *)fillInSeriesNumberIfNeeded:(NSString *)seriesNumber
{
    const NSUInteger kFormatSeriesNumberLength = 3;
    NSUInteger length = kFormatSeriesNumberLength - seriesNumber.length;
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



