//
//  NSURL+NSFExt.h
//  BangumiRenamer
//
//  Created by nsfish on 2021/9/27.
//  Copyright © 2021 nsfish. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (NSFExt)

/// 兼容文件夹名称中包含 "." 的 case
- (NSString *)nsf_pathExtension;

@end

NS_ASSUME_NONNULL_END
