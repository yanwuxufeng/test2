

#import <UIKit/UIKit.h>
#import "UIImageEx.h"


@interface UIImageEx : UIImage
{
	NSString* path;
}
@property (nonatomic, retain) NSString* path;

//+ (UIImageEx *)getGreyImage:(NSString *)filepath :(BOOL)enableAlaph;
+ (UIImageEx *)loadImage:(NSString *)path;
+ (UIImageEx *)loadAndCacheImage:(NSString *)path;
//+ (UIImageEx *)reloadImage:(NSString *)path;
//+ (UIImageEx *)loadImageWithout2x:(NSString *)path;
//+ (UIImageEx *)loadImageFromApp: (NSString*) imgName :(BOOL) graycale;
+ (UIImageEx *)loadImageFromApp:(NSString *)imgName;
+ (UIImageEx *)loadAndCacheImageFromApp:(NSString *)imgName;
//+(UIImageEx *)loadImageByScrathImg:(NSString*)path: (CGSize)size;
//+ (BOOL)removeImage:(id)hImg;
//+ (void)printfImgPool;
+ (void)garbageCollection;
+ (UIImage *)rotateImageByAngle:(UIImage *)originalImage
						  angle:(CGFloat)angle;
+ (UIImage *)buttonSelectedImage:(UIImage *)aImage;


+ (UIImageEx *)loadImageFromBitmapWhenAppLaunch:(NSString *)imgName andWithCache:(BOOL)needCache;

@end

@interface UIImage (MttUIImageCategory)

+ (UIImage *)imageByScalingToSize:(UIImage*)sourceImage Size:(CGSize)targetSize;

+ (UIImage *)imageWithNoOrientationInfo:(UIImage *)image;

- (UIImage *)squareThumbImageWithEdgeLength:(CGFloat)length;

- (UIImage*)resized:(CGSize)size;

@end



