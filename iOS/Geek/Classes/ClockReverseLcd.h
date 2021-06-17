#import <UIKit/UIKit.h>
#import "Slave.h"

@interface ClockReverseLcd : UIView <Slave>
{
	UIImage* segmentOff;
	UIImageView* segmentOn[4][7];
	NSTimer* timer;
}

@end
