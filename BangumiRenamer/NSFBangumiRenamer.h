//
//  NSFBangumiRenamer.h
//  ConanSeriesRenamer
//
//  Created by nsfish on 2020/2/6.
//  Copyright © 2020 nsfish. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFBangumiRenamer : NSObject

+ (NSArray<NSString *> *)renameFilesIn:(NSURL *)directoryURL
                            withSource:(NSURL *)sourceFileURL
                               pattern:(NSURL *)patternFileURL
                                  rule:(nullable NSURL *)ruleFileURL
                     specificExtension:(nullable NSString *)specificExtension
                                 order:(BOOL)order
                                dryrun:(BOOL)dryrun;

@end

NS_ASSUME_NONNULL_END
