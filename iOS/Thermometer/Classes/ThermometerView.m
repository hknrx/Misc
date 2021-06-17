#import "ThermometerView.h"
#import "ThermometerViewController.h"
#import "TemperatureView.h"
#import "GearView.h"

#define PI 3.14159

@implementation ThermometerView

CGGradientRef gradientBackground;
CGGradientRef gradientThermometer;
CGGradientRef gradientTemperatureBar;

@synthesize temperatureCelsiusExpected;

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGFloat colorsBackground[8] = {0.2, 0.5, 0.5, 1.0, 0.7, 1.0, 1.0, 1.0};
		gradientBackground = CGGradientCreateWithColorComponents(colorSpace, colorsBackground, NULL, 2);
		CGFloat colorsThermometer[8] = {1.0, 1.0, 1.0, 1.0, 0.6, 0.6, 1.0, 1.0};
		gradientThermometer = CGGradientCreateWithColorComponents(colorSpace, colorsThermometer, NULL, 2);
		CGFloat colorsTemperatureBar[8] = {1.0, 0.7, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0};
		gradientTemperatureBar = CGGradientCreateWithColorComponents(colorSpace, colorsTemperatureBar, NULL, 2);
		CGColorSpaceRelease(colorSpace);

		temperatureCelsiusDisplayed = 0.0;
		temperatureCelsiusExpected = 0.0;

		temperatureView = [[TemperatureView alloc] initWithFrame:CGRectMake(250.0, 60.0, 20.0, 363.0)];
		temperatureView.opaque = NO;
		[self addSubview:temperatureView];
		gearView = [[GearView alloc] initWithFrame:CGRectMake(24.0, 279.0, 152.0, 177.0)];
		gearView.opaque = NO;
		[self addSubview:gearView];

		displayTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 20) target:self selector:@selector(updateDisplay) userInfo:nil repeats:YES];
	}
	return self;
}

+ (double)convertToHeightFromCelsius:(double)value
{
	// Linear interpolation with the following settings:
	// - 0°C => 300
	// - 40°C => 40
	return 300.0 - (300.0 - 40.0) * (value - 0.0) / (40.0 - 0.0);
}

- (void)drawThermometerMarksWithContext:(CGContextRef)context usingCelsius:(BOOL)celsius from:(double)start to:(double)stop withStep:(double)step withMajorMark:(unsigned char)majorMark
{
	// Initialize the x-position of the marks
	double x1;
	NSString* textFormat;
	double textPosition;
	UITextAlignment textAlignment;
	if(celsius)
	{
		x1 = 23.0;
		textFormat = @"%.0f°C";
		textPosition = 17.0 - 40.0;
		textAlignment = UITextAlignmentRight;
	}
	else
	{
		x1 = 57.0;
		textFormat = @"%.0f°F";
		textPosition = 63.0;
		textAlignment = UITextAlignmentLeft;
	}

	// Set the font of the major mark labels
	UIFont* font = [UIFont systemFontOfSize:12.0];

	// Let's draw all the marks
	unsigned char mark = majorMark;
	double length;
	for(double temperature = start; temperature <= stop; temperature += step)
	{
		// Check whether this mark is a major one
		if(mark == majorMark)
		{
			// Set the width and length of the major mark
			length = 8.0;
			CGContextSetLineWidth(context, 3.0);
		}

		// Compute the position of the mark
		double x2;
		double y;
		if(celsius)
		{
			x2 = x1 + length;
			y = [ThermometerView convertToHeightFromCelsius:temperature];
		}
		else
		{
			x2 = x1 - length;
			y = [ThermometerView convertToHeightFromCelsius:[ThermometerViewController convertToCelsiusFromFahrenheit:temperature]];
		}

		// Draw the mark
		CGContextMoveToPoint(context, x1, y);
		CGContextAddLineToPoint(context, x2, y);
		CGContextStrokePath(context);

		// Check whether this mark is a major one
		if(mark == majorMark)
		{
			// Display the major mark labels
			NSString* label = [NSString stringWithFormat:textFormat, temperature];
			[label drawInRect:CGRectMake(textPosition, y - 8.0, 40.0, 16.0) withFont:font lineBreakMode:UILineBreakModeClip alignment:textAlignment];

			// Set the width and length of the minor marks
			length = 6.0;
			CGContextSetLineWidth(context, 1.0);

			// Reset the mark counter
			mark = 1;
		}
		else
		{
			// Next mark
			++mark;
		}
	}
}

- (void)drawThermometerWithContext:(CGContextRef)context atX:(CGFloat)x atY:(CGFloat)y
{
	// Save then translate the context
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, x, y);
	
	// Define the thermometer's body
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddArc(path, NULL, 40.0, 20.0, 17.0, PI, 0.0, 0);
	CGPathAddArc(path, NULL, 40.0, 363.0, 34.0, -PI / 3, -2 * PI / 3, 0);
	CGPathAddLineToPoint(path, NULL, 23.0, 20.0);

	// Fill the thermometer's body
	CGContextSaveGState(context);
	CGContextAddPath(context, path);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, gradientThermometer, CGPointMake(40.0, 40.0), CGPointMake(40.0, 360.0), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);

	// Draw the thermometer's body
	CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
	CGContextAddPath(context, path);
	CGContextSetLineWidth(context, 5.0);
	CGContextStrokePath(context);

	// Release the thermometer's body
	CGPathRelease(path);

	// Draw the liquid tank
	CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
	CGContextAddArc(context, 40.0, 363.0, 27.0, 0.0, 2 * PI, 0);
	CGContextFillPath(context);

	// Draw the marks
	CGContextSetRGBFillColor(context, 0.0, 0.0, 0.5, 1.0);
	[self drawThermometerMarksWithContext:context usingCelsius:YES from:0.0 to:40.0 withStep:2.0 withMajorMark:5];
	[self drawThermometerMarksWithContext:context usingCelsius:NO from:30.0 to:105.0 withStep:5.0 withMajorMark:4];
	
	// Restore the original context
	CGContextRestoreGState(context);
}

- (void)drawThermometerBarWithContext:(CGContextRef)context
{
	// Compute the height of the temperature bar
	temperatureCelsiusDisplayed += (temperatureCelsiusExpected - temperatureCelsiusDisplayed) / 20.0;
	double height = [ThermometerView convertToHeightFromCelsius:temperatureCelsiusDisplayed];
	
	// Draw the temperature bar
	CGContextDrawLinearGradient(context, gradientTemperatureBar, CGPointMake(0.0, height), CGPointMake(0.0, 363.0 - 27.0), kCGGradientDrawsAfterEndLocation);
}


- (void)drawGearWithContext:(CGContextRef)context atX:(CGFloat)x atY:(CGFloat)y withRadius:(CGFloat)radius withAngle:(CGFloat)angle withHole:(BOOL)hole
{
	// Check whether the gear shall have a hole
	if(hole)
	{
		// Save the context
		CGContextSaveGState(context);

		// Define the clipping path
		CGContextAddArc(context, x, y, radius / 3, 0.0f, 2 * PI, 0);
		CGContextClosePath(context);
		CGContextAddArc(context, x, y, radius + 6.0f, 0.0f, 2 * PI, 0);
		CGContextEOClip(context);
	}

	// Draw the gear
	unsigned int teethCount = ceil(PI * radius / 20.0f);
	CGFloat radiusCurrent = 0.0f;
	CGFloat angleStep = PI / teethCount;
	CGFloat angleCorrection = angleStep / 8;
	while(teethCount)
	{
		if(radiusCurrent < radius)
		{
			radiusCurrent = radius + 3.0f;
		}
		else
		{
			radiusCurrent = radius - 7.0f;
			--teethCount;
		}		
		CGFloat nextAngle = angle + angleStep;
		CGContextAddArc(context, x, y, radiusCurrent, angle + angleCorrection, nextAngle - angleCorrection, 0);
		angle = nextAngle;
	}
	CGContextClosePath(context);
	CGContextDrawPath(context, kCGPathFillStroke);

	// Restore the original context (if needed)
	if(hole)
	{
		CGContextRestoreGState(context);
	}
}

- (void)drawGearsWithContext:(CGContextRef)context
{
	CGContextSetLineWidth(context, 5.0);
	CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
	CGContextSetRGBFillColor(context, 0.1, 0.1, 0.2, 1.0);
	
	CGFloat angle = temperatureCelsiusDisplayed / 2;
	[self drawGearWithContext:context atX:66.0f atY:66.0f withRadius:60.0f withAngle:angle - 0.1f withHole:NO];
	[self drawGearWithContext:context atX:66.0f + (60.0f + 30.0f) * cosf(5 * PI / 16) atY:66.0 + (60.0f + 30.0f) * sinf(5 * PI / 16) withRadius:30.0f withAngle:-angle * 60.0f / 30.0f withHole:YES];
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Draw the background
	CGContextDrawLinearGradient(context, gradientBackground, CGPointMake(0.0, 0.0), CGPointMake(0.0, 480.0), 0);

	// Draw the thermometer
	[self drawThermometerWithContext:context atX:320.0 - 20.0 - 80.0 atY:480.0 - 20.0 - 400.0];
}

- (void)updateDisplay
{
	if(fabs(temperatureCelsiusDisplayed - temperatureCelsiusExpected) >= 0.1)
	{
		[temperatureView setNeedsDisplay];
		[gearView setNeedsDisplay];
	}
}

- (void)dealloc
{
	[displayTimer invalidate];
	[gearView release];
	[temperatureView release];

	CGGradientRelease(gradientTemperatureBar);
	CGGradientRelease(gradientThermometer);
	CGGradientRelease(gradientBackground);

	[super dealloc];
}

@end
