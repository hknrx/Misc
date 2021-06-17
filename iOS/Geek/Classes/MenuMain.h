#import "Menu.h"
#import "Slave.h"

@interface MenuMain : Menu <Slave>
{
	CGMutablePathRef computerPath;
}

@end
