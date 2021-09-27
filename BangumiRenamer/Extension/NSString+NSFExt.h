//
//  NSString+NSFExt.h
//  NSFKitObjC
//
//  Created by shlexingyu on 2018/12/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (NSFExt)

/**
 移除字符串中所有 unicode 对应的空格
 完整空格列表见 http://jkorpela.fi/chars/spaces.html
 */
- (NSString *)nsf_trim;

/**
 移除字符串中所有指定字符集
 */
- (NSString *)nsf_trim:(NSCharacterSet *)characterSet;

/**
 移除字符串中除指定字符集外的所有字符
 */
- (NSString *)nsf_trimAllBut:(NSCharacterSet *)characterSet;

/**
 兼容 NSJSONSerialization 可能带来的精度损失（比如后端传回的 8.8 变成 8.80000000001）
 */
+ (NSString *)fromDouble:(double)doubleValue;

/**
 兼容 NSJSONSerialization 可能带来的精度损失（比如后端传回的 8.8 变成 8.80000000001）
 */
- (NSString *)doubleFormatted;

@end

NS_ASSUME_NONNULL_END
