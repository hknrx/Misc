#import <UIKit/UIKit.h>
#import "Slave.h"

@interface ClockBarcode : UIView <Slave>
{
	CGMutablePathRef barsPath;
	CGMutablePathRef clockPath;
	CGGradientRef clockGradient;
	UIImageView* led[22];
	NSTimer* timer;
}

@end
