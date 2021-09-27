//
//  NSString+NSFExt.m
//  NSFKitObjC
//
//  Created by shlexingyu on 2018/12/18.
//

#import "NSString+NSFExt.h"

@implementation NSString (NSFExt)

- (NSString *)nsf_trim
{
    return [self nsf_trim:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSString *)nsf_trim:(NSCharacterSet *)characterSet
{
    // 直接使用 [self stringByReplacingOccurrencesOfString:@" " withString:@""]
    // 只能处理 unicode 为 \u0020 的空格，无法处理其它空格，比如\u00a0
    return [[self componentsSeparatedByCharactersInSet:characterSet] componentsJoinedByString:@""];
}

- (NSString *)nsf_trimAllBut:(NSCharacterSet *)characterSet
{
    return [self nsf_trim:[characterSet invertedSet]];
}

+ (NSString *)fromDouble:(double)doubleValue
{
    NSString *doubleString = [NSString stringWithFormat:@"%lf", doubleValue];
    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:doubleString];
    
    return number.stringValue;
}

- (NSString *)doubleFormatted
{
    NSString *doubleString = [NSString stringWithFormat:@"%lf", self.doubleValue];
    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:doubleString];
    
    return number.stringValue;
}

@end
