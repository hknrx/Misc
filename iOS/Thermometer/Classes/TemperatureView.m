#import "TemperatureView.h"
#import "ThermometerView.h"

@implementation TemperatureView

- (void)drawRect:(CGRect)rect
{
	[(ThermometerView*)self.superview drawThermometerBarWithContext:UIGraphicsGetCurrentContext()];
}

@end
