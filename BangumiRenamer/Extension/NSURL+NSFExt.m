//
//  NSURL+NSFExt.m
//  BangumiRenamer
//
//  Created by nsfish on 2021/9/27.
//  Copyright © 2021 nsfish. All rights reserved.
//

#import "NSURL+NSFExt.h"

@implementation NSURL (NSFExt)

- (NSString *)nsf_pathExtension
{
    if (self.hasDirectoryPath)
    {
        return @"";
    }
    
    return [self.path pathExtension];
}

@end
