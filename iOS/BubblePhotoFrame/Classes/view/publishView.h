#import <UIKit/UIKit.h>

@interface PublishView : UIView
{
	UIImageView* screenshotImage;
	CGMutablePathRef screenshotBorderPath;
	CGGradientRef screenshotBorderGradient;
}

@property (nonatomic, assign) UIImage* screenshot;

- (id)initWithFrame:(CGRect)frame withController:(UIViewController*)controller;

@end
