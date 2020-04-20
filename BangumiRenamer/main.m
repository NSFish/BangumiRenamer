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
            printf("Usage: bangumi-renamer -source /Path/to/source.txt -d /Path/to/directoryToBeRenamed -p /Path/to/pattern.txt");
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
