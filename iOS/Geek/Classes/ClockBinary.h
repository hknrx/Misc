#import <UIKit/UIKit.h>
#import "Slave.h"

@interface ClockBinary : UIView <Slave>
{
	CGMutablePathRef clockPath;
	CGGradientRef clockGradient;
	UIImageView* ledHour[5];
	UIImageView* ledMinute[6];
	UIImageView* ledSecond[6];
	NSTimer* timer;
}

@end
