#import <UIKit/UIKit.h>

@interface ErrorView : UIView
{
	CGFloat boxTop;
	CGFloat boxBottom;
	CGMutablePathRef boxPathOuter;
	CGMutablePathRef boxPathInner;
	CGGradientRef boxGradientOuter;
	CGGradientRef boxGradientInner;
	UILabel* label;
}

@property (nonatomic, readonly) UILabel* label;

- (id)initWithFrame:(CGRect)frame withController:(UIViewController*)controller;

@end
