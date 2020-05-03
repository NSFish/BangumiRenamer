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
            printf("usage: bangumi-renamer -s /Path/to/source.txt -d /Path/to/directoryToBeRenamed -p /Path/to/pattern.txt\n");
            printf("options:\n");
            printf("    -s, -source       file that holds the correct names\n");
            printf("    -d, -directory    folder that contains files you wanna rename\n");
            printf("    -p, -pattern      file that holds regular expressions that identifie the serial number of files to be renamed\n");
            printf("\n");
            printf("A simplest example would be:\n");
            printf("bangumi-renamer -p /Path/to/pattern.txt\n");
            printf("renamer will try to find and use ./source.txt along with pattern.txt to rename files in the current directory.\n");
            
            return 0;
        }
        
        NSString *sourceFilePath = nil;
        NSString *destDirectoryPath = nil;
        NSString *patternFilePath = nil;
        
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
            else if ([string isEqualToString:@"-p"]
                     && (i + 1 < argc))
            {
                patternFilePath = [NSString stringWithUTF8String:argv[i + 1]];
            }
        }
        
        BOOL inputInvalid = NO;
        if (!sourceFilePath)
        {
            inputInvalid = YES;
            printf("请输入源文件路径");
        }
        else if (!destDirectoryPath)
        {
            inputInvalid = YES;
            printf("请输入待重命名的文件夹路径");
        }
        else if (!patternFilePath)
        {
            inputInvalid = YES;
            printf("请输入匹配剧集集数的正则文件路径");
        }
        
        if (inputInvalid)
        {
            return 0;
        }
        
        [NSFBangumiRenamer renameFilesIn:destDirectoryPath
                              withSource:sourceFilePath
                                 pattern:patternFilePath];
    }
    
    return 0;
}
