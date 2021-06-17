#import "Menu.h"
#import "Slave.h"

@interface MenuClock : Menu <Slave>
{
	CGMutablePathRef clockStrokePath;
	CGMutablePathRef clockFillPath;
	NSTimer* timer;
}

@end
