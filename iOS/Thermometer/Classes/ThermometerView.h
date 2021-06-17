#import <UIKit/UIKit.h>

@class TemperatureView;
@class GearView;

@interface ThermometerView : UIView
{
	double temperatureCelsiusDisplayed;
	double temperatureCelsiusExpected;

	TemperatureView* temperatureView;
	GearView* gearView;
	NSTimer* displayTimer;
}

@property (nonatomic,assign) double temperatureCelsiusExpected;

- (void)drawThermometerBarWithContext:(CGContextRef)context;
- (void)drawGearsWithContext:(CGContextRef)context;

@end
