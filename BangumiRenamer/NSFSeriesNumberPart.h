//
//  NSFSeriesNumberPart.h
//  BangumiRenamer
//
//  Created by nsfish on 2020/5/4.
//  Copyright © 2020 nsfish. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFSeriesNumberPart : NSObject
@property (readonly) NSString *content;
@property (readonly) NSRange range;

- (nullable instancetype)initWithContent:(NSString *)content
                                   range:(NSRange)range NS_DESIGNATED_INITIALIZER;

+ (nullable instancetype)partWithContent:(NSString *)content
                                   range:(NSRange)range;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
