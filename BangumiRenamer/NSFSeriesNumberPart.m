//
//  NSFSeriesNumberPart.m
//  BangumiRenamer
//
//  Created by nsfish on 2020/5/4.
//  Copyright © 2020 nsfish. All rights reserved.
//

#import "NSFSeriesNumberPart.h"

@interface NSFSeriesNumberPart()
@property (nonatomic, copy)   NSString *content;
@property (nonatomic, assign) NSRange range;

@end


@implementation NSFSeriesNumberPart

- (instancetype)initWithContent:(NSString *)content
                          range:(NSRange)range
{
    if (!content || content.length == 0)
    {
        return nil;
    }
    
    if (range.location == NSNotFound)
    {
        return nil;
    }
    
    if (self = [super init])
    {
        self.content = content;
        self.range = range;
    }
    
    return self;
}

+ (nullable instancetype)partWithContent:(NSString *)content
                                   range:(NSRange)range
{
    return [[NSFSeriesNumberPart alloc] initWithContent:content range:range];
}

#pragma mark - Equality
- (BOOL)isEqualToPart:(NSFSeriesNumberPart *)part
{
    if (!part)
    {
        return NO;
    }
    
    BOOL haveEqualContents = (!self.content && !part.content) || [self.content isEqualToString:part.content];
    BOOL haveEqualRanges = NSEqualRanges(self.range, part.range);
    
    return haveEqualContents && haveEqualRanges;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:[NSFSeriesNumberPart class]])
    {
        return NO;
    }
    
    return [self isEqualToPart:(NSFSeriesNumberPart *)object];
}

@end
