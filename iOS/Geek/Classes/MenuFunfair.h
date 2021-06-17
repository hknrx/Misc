#import "Menu.h"
#import "Slave.h"

@interface MenuFunfair : Menu <Slave>
{
	UIImageView* ferrisWheel[8];
	unsigned char frameCounter;
	NSTimer* timer;
}

@end
