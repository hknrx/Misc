#import "GearView.h"
#import "ThermometerView.h"

@implementation GearView

- (void)drawRect:(CGRect)rect
{
	[(ThermometerView*)self.superview drawGearsWithContext:UIGraphicsGetCurrentContext()];
}

@end
