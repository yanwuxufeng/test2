

#import "UIImageEx.h"
#import "Log.h"
#import <CoreGraphics/CGColorSpace.h>
#import "NSPathEx.h"
#import "UISkinManager.h"
#import "UIThemeManager.h"
#import "MttSystemInterface.h"
#import "UIDeviceHelper.h"
#import <ImageIO/ImageIO.h>

//因为UIImageEx有可能被多线程调用，因此涉及到NSMutableDictionary的操作要做线程保护
static NSMutableDictionary * s_ui_img_pool = nil;
//static NSMutableArray	   * s_ui_head_pool = nil;

//@interface imgNode : NSObject
//{
//@public
//	UIImageEx * m_img;
////	BOOL m_bRetain;
//}

//@property(readwrite) BOOL m_bRetain;
//@end
//
//@implementation imgNode
////@synthesize m_bRetain;
//@end

static NSString *docPath = nil;

@implementation UIImageEx
@synthesize path;

+(BOOL)removeImage:(id)hImg
{
    //    NSString* countString = [NSString stringWithFormat:@"%d", [s_ui_img_pool count]];
    //    CommonLog_i(@"%@", countString);
    if ( [hImg isKindOfClass:[UIImageEx class]] ) {
        @synchronized ( s_ui_img_pool )
        {
            if( s_ui_img_pool && [s_ui_img_pool count] > 0 ){
                UIImageEx* imageInThePool = [s_ui_img_pool objectForKey:((UIImageEx*)hImg).path];
                if ( imageInThePool && imageInThePool == hImg ) {
                    [s_ui_img_pool removeObjectForKey:((UIImageEx*)hImg).path];
                }
                return TRUE;
            }
        }
    }
    return FALSE;
}

- (void)dealloc
{
    if (self.path) {
        [UIImageEx removeImage:self];
        self.path = nil;
    }
    [super dealloc];
}

//+(UIImageEx *) getGreyImage:(NSString *)filepath :(BOOL)enableAlaph
//{
//	int bitmapByteCount;
//	int bitmapBytesPerRow;
//	size_t pixelsWide =  40;//CGImageGetWidth(inImage);
//	size_t pixelsHigh =  40;//CGImageGetHeight(inImage);
//	bitmapBytesPerRow = pixelsWide * (enableAlaph ? 4 : 1);
//	bitmapByteCount = bitmapBytesPerRow * pixelsHigh;
//	
//	static CGContextRef context = NULL;
//	static unsigned char *bitmapData = NULL;
//	
//	if(context == NULL)
//	{
//		CGColorSpaceRef colorspace = NULL;
////		colorspace = CGColorSpaceCreateWithName(enableAlaph ? kCGColorSpaceGenericRGB : kCGColorSpaceGenericGray);
//		//colorspace = CGColorSpaceCreateDeviceGray();
//		if(enableAlaph)
//			colorspace = CGColorSpaceCreateDeviceRGB();
//		else
//			colorspace = CGColorSpaceCreateDeviceGray();
//		
//		
//		unsigned char *bitmapData;
//
//		//LOGDEBUG("bitmapdata is %d", bitmapByteCount);
//		bitmapData = malloc(bitmapByteCount);
//		context = CGBitmapContextCreate(bitmapData, 
//										pixelsWide, 
//										pixelsHigh, 
//										8, 
//										bitmapBytesPerRow, 
//										colorspace, 
//										(enableAlaph ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNone));
//		CGColorSpaceRelease(colorspace);
//		
//	}
//
//	UIImageEx * img = nil;
//    if ( [[NSFileManager defaultManager] fileExistsAtPath:filepath] ) {
//        UIImageEx * tmpImg = [ [ UIImageEx alloc ] initWithContentsOfFile: filepath];	
//        CGImageRef inImage = [tmpImg CGImage];
//		
//        CGRect rect = {{0, 0}, {pixelsWide, pixelsHigh}};
//        CGContextDrawImage(context, rect, inImage);
//        if(enableAlaph)
//        {
//            int i,j;
//            for(i = 0; i < bitmapBytesPerRow; i += 4)
//                for(j = 0; j < pixelsHigh; j++)
//                {
//                    int grey = (int)(bitmapData[j * bitmapBytesPerRow + i]*0.299 + bitmapData[j * bitmapBytesPerRow + i+1]*0.587 + bitmapData[j * bitmapBytesPerRow + i+2]*0.114);
//                    bitmapData[j * bitmapBytesPerRow + i] = bitmapData[j * bitmapBytesPerRow + i + 1] = bitmapData[j * bitmapBytesPerRow + i + 2] = grey;
//                }		
//        }
//        CGImageRef test = CGBitmapContextCreateImage(context) ;
//        //free(bitmapData);
//        //LOGDEBUG("test is %s", test == nil ? "nil" : "full");
//        [tmpImg release];
//        img = [[UIImageEx alloc] initWithCGImage:test];
//        
//        //CGColorSpaceRelease(colorspace);
//        //CGContextRelease(context);
//        CGImageRelease(test);
//    }
//	return img;
//}


+ (void)beginImageContextWithSize:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
}

+ (void)endImageContext
{
    UIGraphicsEndImageContext();
}

//
//+ (UIImageEx *)loadImageWithout2x:(NSString *)path
//{
//    @synchronized ( s_ui_img_pool )
//    {
//        return [self loadImageInternal:path :NO];
//    }
//}

+ (UIImageEx *)loadImage:(NSString *)path
{
    UIImageEx* img = [[[UIImageEx alloc] initWithContentsOfFile:path] autorelease];
    
    if (img == nil)
    {
        NSString* newPath = [path stringByReplacingOccurrencesOfString:@".png" withString:@"@2x.png"];
        img = [[UIImageEx alloc] initWithContentsOfFile:newPath];
    }
    
    return img;
}

+ (UIImageEx *)loadAndCacheImage:(NSString *)path
{
	UIImageEx * img  =  nil;
    if( path )
    {
        if( nil == s_ui_img_pool )
        {
            s_ui_img_pool = [[NSMutableDictionary alloc] init];
        }
        if ( s_ui_img_pool ) {
            @synchronized ( s_ui_img_pool )
            {
                img =  [s_ui_img_pool objectForKey:path];
                if ( nil == img )
                {
                    img = [[UIImageEx alloc] initWithContentsOfFile:path];
                    //在添加快链时，上报了一个crash，NSInvalidArgumentException,参数异常，在下面
                    //的代码中，newimg, newpath都不能为空，否则会crash。初步判断是在拉取快链图片时
                    //出现了错误，导致了图片不可读，但文件名又存在，所以这里做了判断当图片不可读时把这个
                    //图片删除。
                    if (img == nil) {
                        NSString* newPath = [path stringByReplacingOccurrencesOfString:@".png" withString:@"@2x.png"];
                        img = [[UIImageEx alloc] initWithContentsOfFile:newPath];
                    }
                    if ( img && path )
                    {
                        img.path = path;
                        [s_ui_img_pool setObject:img forKey:path];
                        [img release];
                    }
                    else
                    {
                        if ( path ) {
                            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                        }
                        if ( img ) {
                            [img release];
                            img  =  nil;
                        }
                    }
                }
            }
        }
    }
    return img;
}

//+ (UIImageEx *)reloadImage:(NSString *)path
//{
//    @synchronized ( s_ui_img_pool )
//    {
//        UIImageEx* imageInThePool = [s_ui_img_pool objectForKey:path];
//        if ( imageInThePool ) {
//            [s_ui_img_pool removeObjectForKey:path];
//        }
//        
//        UIImageEx * image  =  nil;
//        if ( [[NSFileManager defaultManager] fileExistsAtPath:path] ) {
//            image = [[UIImageEx alloc] initWithContentsOfFile:path];
//            image.path = path;
//            [s_ui_img_pool setObject:image forKey:path];
//            [image release];
//        }
//        return image;
//    }
//}

+ (UIImageEx *)loadImageFromApp:(NSString *)imgName
{
#if 0
	return [UIImageEx loadImage:[NSString stringWithFormat:@"%@%@", [NSPathEx AppPath],ImagePath(imgName)]];
#else
	return [UIImageEx loadImage:[[UIThemeManager getInstance] getImagePath:imgName]];
#endif
}

+ (UIImageEx *)loadAndCacheImageFromApp:(NSString *)imgName
{
#if 0
    return [UIImageEx loadAndCacheImage:[NSString stringWithFormat:@"%@%@", [NSPathEx AppPath],ImagePath(imgName)]];
#else
	return [UIImageEx loadAndCacheImage:[[UIThemeManager getInstance] getImagePath:imgName]];
#endif
}

+ (void)garbageCollection
{
    @synchronized ( s_ui_img_pool )
    {
        if( s_ui_img_pool && [s_ui_img_pool count] > 0 ){
            NSArray* images = [s_ui_img_pool allValues];
            for (int i=0; i<[s_ui_img_pool count]; i++) {
                UIImageEx* image = [images objectAtIndex:i];
                if ( [image retainCount] <= 1 ) {
                    [s_ui_img_pool removeObjectForKey:image.path];
                }
            }
        }
    }
}

+(void)printfImgPool
{
    @synchronized ( s_ui_img_pool )
    {
        NSEnumerator *enumerator = nil;
        NSString* key = nil;
        enumerator = [s_ui_img_pool keyEnumerator];
        while ((key = [enumerator nextObject]))
        {
            //LOGDEBUG("%s\n", [key cStringUsingEncoding:NSUTF8StringEncoding]);
        }
    }
}

+ (UIImage *)rotateImageByAngle:(UIImage *)originalImage
						  angle:(CGFloat)angle{
	
	CGSize rotatedSize = originalImage.size;
	UIGraphicsBeginImageContext(rotatedSize);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextTranslateCTM(context, rotatedSize.width/2, rotatedSize.height/2);
	CGContextRotateCTM(context, angle * M_PI/180);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	CGContextDrawImage(context, CGRectMake(-originalImage.size.width / 2, -originalImage.size.height / 2, originalImage.size.width, originalImage.size.height), originalImage.CGImage);
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage;
}

// 以后uibutton的选中图片效果是用遮罩的形式，用下面这个函数来生成
+ (UIImage *)buttonSelectedImage:(UIImage *)aImage
{
	UIImage	*image = aImage;
	UIImage *returnImage = nil;

	UIGraphicsBeginImageContextWithOptions(image.size, NO, 0);
	CGContextRef imageContext = UIGraphicsGetCurrentContext();
	
    int width = image.size.width;
    int height = image.size.height;
    int radius = 4;
    
	CGRect rect = CGRectMake(0, 0, width, height);
	[image drawInRect:rect];
    
    
    CGContextMoveToPoint(imageContext, (int)(width/2), 0);
    CGContextAddArcToPoint(imageContext, width, 0, width, (int)(height/2), radius);
    CGContextAddArcToPoint(imageContext, width, height, (int)(width/2), height, radius);
    CGContextAddArcToPoint(imageContext, 0, height, 0, (int)(height/2), radius);
    CGContextAddArcToPoint(imageContext, 0, 0, (int)(width/2), 0, radius);
    CGContextClosePath(imageContext);
    CGContextClip(imageContext);
    
    
	[[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.3f] set];
	CGContextFillRect(imageContext, rect);
    
	
	returnImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return returnImage;
}


+ (NSString *)getImageBitmapPath:(NSString *)imgName
{
    if (!docPath) {
        docPath = [[NSPathEx DocPath] retain];
    }
    return [NSString stringWithFormat:@"%@/imgData%@", docPath, ImagePath(imgName)];
}

+ (void)createBitmapImagePath:(NSString *)imgName
{
    NSString *imgPath = [self getImageBitmapPath:imgName];
    NSString *dirPath = [imgPath substringToIndex:imgPath.length - imgName.length - 3];
    [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    
}

+ (void)saveBitmapImage:(UIImage *)UIImage toPath:(NSString *)path
{
    
//    [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    
    CGImageRef CGImage = UIImage.CGImage;
    size_t width  = CGImageGetWidth(CGImage);
    size_t height = CGImageGetHeight(CGImage);
    size_t bpr = CGImageGetBytesPerRow(CGImage);
    size_t bpc = CGImageGetBitsPerComponent(CGImage);
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(CGImage);
    CGFloat scale = UIImage.scale;
    
    NSMutableData *infoData = [NSMutableData dataWithCapacity:32];
    [infoData appendBytes:(void *)(&width) length:sizeof(size_t)];
    [infoData appendBytes:(void *)(&height) length:sizeof(size_t)];
    [infoData appendBytes:(void *)(&bpr) length:sizeof(size_t)];
    [infoData appendBytes:(void *)(&bpc) length:sizeof(size_t)];
    [infoData appendBytes:(void *)(&alphaInfo) length:sizeof(CGImageAlphaInfo)];
    [infoData appendBytes:(void *)(&scale) length:sizeof(CGFloat)];
    
    
    CGDataProviderRef provider = CGImageGetDataProvider(CGImage);
    NSData* bitmapData = (id)CGDataProviderCopyData(provider);
    
    NSMutableData *imageData = [NSMutableData dataWithData:infoData];
    [imageData appendData:bitmapData];
    [imageData writeToFile:path atomically:YES];
    
    [bitmapData release];
    
}

+ (UIImageEx*)loadBitmapImage:(NSString *)imgName
{
    NSString *bImgPath = [self getImageBitmapPath:imgName];
    NSData *imageData = [NSData dataWithContentsOfFile:bImgPath];
    
    if (imageData)
    {
//        NSData *imageData = [NSData dataWithContentsOfFile:bImgPath];
        const char *bytes = imageData.bytes;
        NSInteger index = 0;
        size_t width  = *(size_t *)(&(bytes[index]));
        index += sizeof(size_t);
        
        size_t height = *(size_t *)(&(bytes[index]));
        index += sizeof(size_t);
        
        size_t bpr = *(size_t *)(&(bytes[index]));
        index += sizeof(size_t);
        
        size_t bpc = *(size_t *)(&(bytes[index]));
        index += sizeof(size_t);
        
        CGImageAlphaInfo alphaInfo = *(CGImageAlphaInfo *)(&(bytes[index]));
        index += sizeof(CGImageAlphaInfo);
        
        CGFloat scale = *(CGFloat *)(&(bytes[index]));
        index += sizeof(CGFloat);
        
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef bitmapContext = CGBitmapContextCreate(
                                                           (char *)&bytes[index],
                                                           width,
                                                           height,
                                                           bpc, // bitsPerComponent
                                                           bpr, // bytesPerRow
                                                           colorSpace,
                                                           alphaInfo);
        
        
        
        CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
        UIImageEx* newImage = [[UIImageEx alloc] initWithCGImage:cgImage scale:scale orientation:UIImageOrientationDown];
        
        CFRelease(colorSpace);
//        CFRelease(bitmapContext);
//        CFRelease(cgImage);
        
        return [newImage autorelease];
    }
    
    
    return nil;
    
}

+ (UIImageEx *)loadImageFromBitmapWhenAppLaunch:(NSString *)imgName andWithCache:(BOOL)needCache
{
    UIImageEx *image = nil;
//    NSString *path = [NSString stringWithFormat:@"%@%@", [NSPathEx AppPath],ImagePath(imgName)];
//    
//    if ( s_ui_img_pool ) {
//        @synchronized ( s_ui_img_pool )
//        {
//            image =  [s_ui_img_pool objectForKey:path];
//        }
//    }
//    
//    if (image) {
//        return image;
//    }
    
    image = [self loadBitmapImage:imgName];
    
    if (image)
    {
        if (needCache) {
//            if( nil == s_ui_img_pool )
//            {
//                s_ui_img_pool = [[NSMutableDictionary alloc] init];
//            }
//            if ( s_ui_img_pool) {
//                @synchronized ( s_ui_img_pool )
//                {
//                    if (path) {
//                        image.path = path;
//                        [s_ui_img_pool setObject:image forKey:path];
//                    }
//                }
//            }
        }
    }
    else
    {
        if (needCache)
        {
            image = [UIImageEx loadAndCacheImageFromApp:imgName];
        }
        else
        {
            image = [UIImageEx loadImageFromApp:imgName];
        }
        
        [self createBitmapImagePath:imgName];
        [self saveBitmapImage:image toPath:[self getImageBitmapPath:imgName]];
    }
    
    return image;
}


@end

@implementation UIImage (MttUIImageCategory)

+ (UIImage *)imageByScalingToSize:(UIImage*)sourceImage Size:(CGSize)targetSize
{
    CGFloat targetWidth = targetSize.width;
	CGFloat targetHeight = targetSize.height;
	
	CGImageRef imageRef = [sourceImage CGImage];
	CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
	CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(imageRef);
	
	if (bitmapInfo == kCGImageAlphaNone) {
		bitmapInfo = kCGImageAlphaNoneSkipLast;
	}
	
	CGContextRef bitmap;
	
	if (sourceImage.imageOrientation == UIImageOrientationUp || sourceImage.imageOrientation == UIImageOrientationDown) {
		bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
		
	} else {
		bitmap = CGBitmapContextCreate(NULL, targetHeight, targetWidth, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
		
	}       
	
	if (bitmap == NULL) {
		return sourceImage;
	}
	
	if (sourceImage.imageOrientation == UIImageOrientationLeft) {
		CGContextRotateCTM (bitmap,M_PI/2.0);
		CGContextTranslateCTM (bitmap, 0, -targetHeight);
		
	} else if (sourceImage.imageOrientation == UIImageOrientationRight) {
		CGContextRotateCTM (bitmap, -M_PI/2.0);
		CGContextTranslateCTM (bitmap, -targetWidth, 0);
		
	} else if (sourceImage.imageOrientation == UIImageOrientationUp) {
		// NOTHING
	} else if (sourceImage.imageOrientation == UIImageOrientationDown) {
		CGContextTranslateCTM (bitmap, targetWidth, targetHeight);
		CGContextRotateCTM (bitmap, -M_PI);
	}
	
	CGContextDrawImage(bitmap, CGRectMake(0, 0, targetWidth, targetHeight), imageRef);
	CGImageRef ref = CGBitmapContextCreateImage(bitmap);
	UIImage* newImage = [UIImage imageWithCGImage:ref];
	
	CGContextRelease(bitmap);
	CGImageRelease(ref);
	
	return newImage; 
}

+ (UIImage *)imageWithNoOrientationInfo:(UIImage *)image
{
    if (image.imageOrientation == UIImageOrientationUp || image.imageOrientation == UIImageOrientationDown) {
        image = [self imageByScalingToSize:image Size:image.size];
    }
    else {
        image = [self imageByScalingToSize:image Size:CGSizeMake(image.size.height, image.size.width)];
    }
    return image;
}


//将一个任意形状的图变成一张正方形缩略图，无形变
- (UIImage *)squareThumbImageWithEdgeLength:(CGFloat)length
{
    UIImage *image = nil;
    
    CGFloat thumbSize = length;
    
    CGFloat imageWidth = self.size.width;
    CGFloat imageHeight = self.size.height;
    
    CGFloat shortSide = MIN(imageWidth, imageHeight);
    CGFloat rate = shortSide / thumbSize;
    
    CGFloat thumbWidth = imageWidth / rate;
    CGFloat thumbHeight = imageHeight / rate;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(thumbWidth, thumbHeight), NO, 1.0f);
    [self drawInRect:CGRectMake(0, 0, thumbWidth, thumbHeight)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRef tempCGImage = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(0, 0, thumbSize, thumbSize));
    image = [UIImage imageWithCGImage:tempCGImage];
    CGImageRelease(tempCGImage);
    
    return image;
}

- (UIImage*)resized:(CGSize)size
{
    UIImage* retImg = nil;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0f);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    retImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return retImg;
}

@end

