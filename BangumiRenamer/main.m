//
//  main.m
//  BangumiRenamer
//
//  Created by nsfish on 2020/2/12.
//  Copyright © 2020 nsfish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSFBangumiRenamer.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 3)
        {
            printf("usage: bangumi-renamer -s /Path/to/source.txt -d /Path/to/directory -p /Path/to/pattern.txt\n");
            printf("options:\n");
            printf("    -s, -source       file that holds the correct names\n");
            printf("    -d, -directory    directory that contains files you wanna rename\n");
            printf("    -r, -rule         包含特殊规则的文件，比如如何命名剧集数相同的文件\n");
            printf("    -p, -pattern      file that holds regular expressions that identifie the serial number of files to be renamed\n");
            printf("    -se, -specific-extension 指定要处理的文件扩展名，要处理文件夹则传入\n");
            printf("    --order 按文件排序用 source.txt 中的文件名一一命名，即使从文件名中提取的序列号对不上\n");
            
            return 0;
        }
        
        NSString *sourceFilePath = nil;
        NSString *destDirectoryPath = nil;
        NSString *patternFilePath = nil;
        NSString *ruleFilePath = nil;
        NSString *specificExtension = nil;
        NSString *orderString = nil;
        
        for (NSUInteger i = 0; i < argc; i++)
        {
            NSString *string = [NSString stringWithUTF8String:argv[i]];
            if ([string isEqualToString:@"-s"]
                && (i + 1 < argc))
            {
                sourceFilePath = [NSString stringWithUTF8String:argv[i + 1]];
            }
            else if ([string isEqualToString:@"-d"]
                     && (i + 1 < argc))
            {
                destDirectoryPath = [NSString stringWithUTF8String:argv[i + 1]];
            }
            else if ([string isEqualToString:@"-r"]
                     && (i + 1 < argc))
            {
                ruleFilePath = [NSString stringWithUTF8String:argv[i + 1]];
            }
            else if ([string isEqualToString:@"-p"]
                     && (i + 1 < argc))
            {
                patternFilePath = [NSString stringWithUTF8String:argv[i + 1]];
            }
            else if ([string isEqualToString:@"-se"]
                     && (i + 1 < argc))
            {
                specificExtension = [NSString stringWithUTF8String:argv[i + 1]];
            }
            else if ([string isEqualToString:@"--order"])
            {
                orderString = @"YES";
            }
            
        }
        
        BOOL inputInvalid = NO;
        // 检查是否输入足够的路径参数
        if (!sourceFilePath)
        {
            printf("请输入源文件路径.\n");
            inputInvalid = YES;
        }
        else if (!destDirectoryPath)
        {
            printf("请输入待处理的文件夹路径.\n");
            inputInvalid = YES;
        }
        else if (!patternFilePath)
        {
            printf("请输入匹配剧集集数的正则文件路径.\n");
            inputInvalid = YES;
        }
        
        // 检查路径参数是否真实存在
        BOOL isDirectory = NO;
        BOOL sourceFileExist = [[NSFileManager defaultManager] fileExistsAtPath:sourceFilePath isDirectory:&isDirectory];
        if (!sourceFileExist || isDirectory) // source.txt(或其他用户指定的名字)必须存在且只能是文件
        {
            printf("输入的源文件不存在，请重新输入.\n");
            inputInvalid = YES;
        }
        
        BOOL destDirectoryExist = [[NSFileManager defaultManager] fileExistsAtPath:destDirectoryPath isDirectory:&isDirectory];
        if (!destDirectoryExist || !isDirectory) // directory 必须存在且只能是文件夹
        {
            printf("输入的待处理文件夹不存在，请重新输入.\n");
            inputInvalid = YES;
        }
        
        BOOL patternFileExist = [[NSFileManager defaultManager] fileExistsAtPath:patternFilePath isDirectory:&isDirectory];
        if (!patternFileExist || isDirectory) // pattern.txt(或其他用户指定的名字)必须存在且只能是文件
        {
            printf("输入的匹配剧集集数的正则文件不存在，请重新输入.\n");
            inputInvalid = YES;
        }
        
        if (inputInvalid)
        {
            return 0;
        }
        
        BOOL order = orderString.length > 0;
        
        // 转换成 NSURL
        NSURL *sourceFileURL = [NSURL fileURLWithPath:sourceFilePath isDirectory:NO];
        NSURL *destDirectoryURL = [NSURL fileURLWithPath:destDirectoryPath isDirectory:YES];
        NSURL *patternFileURL = [NSURL fileURLWithPath:patternFilePath isDirectory:NO];
        NSURL *ruleFileURL = [NSURL fileURLWithPath:ruleFilePath isDirectory:NO];
        
        [NSFBangumiRenamer renameFilesIn:destDirectoryURL
                              withSource:sourceFileURL
                                 pattern:patternFileURL
                                    rule:ruleFileURL
                       specificExtension:specificExtension
                                   order:order
                                  dryrun:NO];
    }
    
    return 0;
}
