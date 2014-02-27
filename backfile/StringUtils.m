//
//  StringUtils.m
//  mtt
//
//  Created by puckshuang on 09-12-26.
//  Copyright 2009 tencent. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "StringUtils.h"

@implementation NSString (StringFunction)

- (id)initWithUTF8StringSafety:(const char *)nullTerminatedCString{
    
    /*
     Parameters
     
     bytes
     
     A NULL-terminated C array of bytes in UTF-8 encoding. This value must not be NULL.
     
     Raises an exception if bytes is NULL.
     */
    
    /* The following code will crash, so actually this function its not safe enough, but better then initWithUTF8String 
     QQINT testInt = 5;
     QQCHAR *pStr = (QQCHAR *)testInt;
     NSString *str = [[NSString alloc] initWithUTF8StringSafety:pStr];
     */
    
    if(!nullTerminatedCString){
        return nil; //so we dont get crash
    }
    
    id ret = [self initWithUTF8String:nullTerminatedCString];
    
    return ret;
}


+ (NSInteger)lineNum:(NSString *)str withFont:(UIFont *)font withLineWidth:(NSInteger)lineWidth
{
    if ((str == nil) || ([str isEqualToString:@""]))
    {
        return 1;
    }
    
    NSInteger ret = 0;
    NSArray *strArray = [str componentsSeparatedByString:@"\n"];
    for (NSString *tmp in strArray)
    {
        CGSize tmpSize = [tmp sizeWithFont:font];
        ret += ((NSInteger)(tmpSize.width / lineWidth) + 1);
    }
    
    return ret;
}

@end

@implementation StringUtils


+ (NSString*)trim:(NSString*)_str
{
	if(_str == nil)
		return _str;
	return [_str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (NSString*)MD5:(NSString*)str
{
	const char *cStr = [str UTF8String];
	
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	
	CC_MD5( cStr, strlen(cStr), result );
	
	return [NSString 
			
			stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			
			result[0], result[1],
			
			result[2], result[3],
			
			result[4], result[5],
			
			result[6], result[7],
			
			result[8], result[9],
			
			result[10], result[11],
			
			result[12], result[13],
			
			result[14], result[15]
			
			];
}

+ (NSString*)getRidOfCNWhitespace:(NSString*)str
{
    if(!str)
        return nil;
        
    unichar unichars[] = {(unichar)8198};
    NSString* whiteSpaceChar = [NSString stringWithCharacters:unichars length:1];
    return [str stringByReplacingOccurrencesOfString:whiteSpaceChar withString:@""];
}

@end


@implementation NSString (ByteLength)

- (NSInteger)getUnicodeByteLength{
    
    int strlength = 0;
    char* p = (char*)[self cStringUsingEncoding:NSUnicodeStringEncoding];
    for (int i=0 ; i<[self lengthOfBytesUsingEncoding:NSUnicodeStringEncoding] ;i++) {
        if (*p) {
            p++;
            strlength++;
        }
        else {
            p++;
        }
    }
    return strlength;
}

@end


#import "NSPathEx.h"
@implementation NSString (TimeProfileFileFlag)

+ (void)timeProfileFile:(NSString *)fileName{
    
    NSString * path = [NSString stringWithFormat:@"%@/%@%@", [NSPathEx DocPath], fileName, @"Flag.flg"];
    int f = open(path.UTF8String, O_CREAT | O_RDWR, 0777);
    //    write(f, fileName.UTF8String, strlen(fileName.UTF8String));
    close(f);
}

@end
