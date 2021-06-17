#import "Menu.h"
#import "Slave.h"

@interface MenuSound : Menu <Slave>
{
	CGMutablePathRef micPath;
}

@end
