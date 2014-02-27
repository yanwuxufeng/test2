//
//  StringUtils.h
//  mtt
//
//  Created by puckshuang on 09-12-26.
//  Copyright 2009 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (StringFunction)

- (id)initWithUTF8StringSafety:(const char *)nullTerminatedCString;
+ (NSInteger)lineNum:(NSString *)str withFont:(UIFont *)font withLineWidth:(NSInteger)lineWidth;

@end

@interface StringUtils : NSObject {

}

+ (NSString*)MD5:(NSString*)str;
+ (NSString*)trim:(NSString*)_str;
// 返回一段字符串(分行符),在指定宽度的控件上排版需要的行数

// 去除中文输入下的空格。
+ (NSString*)getRidOfCNWhitespace:(NSString*)str;

@end

@interface NSString (ByteLength)

- (NSInteger)getUnicodeByteLength;

@end

@interface NSString (TimeProfileFileFlag)

+ (void)timeProfileFile:(NSString *)fileName;

@end
