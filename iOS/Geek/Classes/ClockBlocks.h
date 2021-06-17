#import <UIKit/UIKit.h>
#import "Slave.h"

#define containerRowCount         3
#define containerLeftColumnCount  2
#define containerRightColumnCount 3

#define blockCountTotal (containerRowCount * 2 * (containerLeftColumnCount + containerRightColumnCount))

@interface ClockBlocks : UIView <Slave>
{
	unsigned short blockTimer;
	UIImage* blockImage[7];
	UIImageView* blockView[blockCountTotal];

	NSTimer* timer;
}

@end
