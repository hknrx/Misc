#import <UIKit/UIKit.h>

@interface Menu : UIView
{
	UIImage* keyboardImage;

	CGMutablePathRef monitorPath;
	CGMutablePathRef screenPath;
	CGMutablePathRef powerLightPath;

	CGPoint powerLightCenter;

	CGGradientRef monitorGradient;
	CGGradientRef powerLightGradient;
}

- (id)initWithFrame:(CGRect)frame withButtonClasses:(NSArray*)buttonClasses;

@end
