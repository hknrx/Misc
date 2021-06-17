#import "ClockBarcode.h"

#define screenWidth  320.0f
#define screenHeight (480.0f - 44.0f)

#define ledRadius   12.0f
#define ledGap      6.0f
#define ledCountMax 9

#define barCount      4
#define barWidth      (2 * ledRadius)
#define barHeight     (2 * ledRadius * ledCountMax + ledGap * (ledCountMax + 1))
#define barGap        18.0f
#define barTop        ((screenHeight - barHeight) / 2)
#define barBottom     (barTop + barHeight)
#define barCenterLeft ((screenWidth - (barWidth + barGap) * (barCount - 1)) / 2)

#define clockWidth  (barWidth * barCount + barGap * (barCount + 1))
#define clockHeight (barHeight + 8 * ledRadius)
#define clockRadius barWidth
#define clockTop    ((screenHeight - clockHeight) / 2)
#define clockBottom (clockTop + clockHeight)
#define clockLeft   ((screenWidth - clockWidth) / 2)
#define clockRight  (clockLeft + clockWidth)

@implementation ClockBarcode

static unsigned char const barLedIndex[4] = {4, 8, 13, 22};
static CGFloat const ledColors[8] = {1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f};
static CGFloat const clockColors[12] = {0.2f, 0.2f, 0.2f, 1.0f, 0.3f, 0.3f, 0.3f, 1.0f, 0.1f, 0.1f, 0.1f, 1.0f};

- (NSString*)helpText
{
	return @"The two bars on the left represent hours, the two on the right minutes. LEDs in the first bar count for 5, LEDs in the third bar count for 10, LEDs in the 2 other bars count for 1. Easy!";
}

- (NSString*)infoText
{
	return @"Enjoy this beautiful barcode clock, which displays the time using bars of LEDs in a somehow cryptic way that all Geeks love!";
}

+ (NSString*)menuName
{
	return @"Barcode";
}

+ (BarContent)barContent
{
	return BAR_NOTHING;
}

- (void)update
{
	// Get the time
	NSDateComponents const*const dateComponents = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:[NSDate date]];
	NSInteger const hour = [dateComponents hour];
	NSInteger const minute = [dateComponents minute];

	// Display the time
	unsigned char const number[4] = {hour / 5, hour % 5, minute / 10, minute % 10};
	unsigned char ledIndexCurrent = 0;
	for(unsigned char barIndex = 0; barIndex < 4; ++ barIndex)
	{
		unsigned char const ledIndexOn = ledIndexCurrent + number[barIndex];
		unsigned char const ledIndexEnd = barLedIndex[barIndex];
		while(ledIndexCurrent < ledIndexEnd)
		{
			led[ledIndexCurrent].hidden = ledIndexCurrent >= ledIndexOn;
			++ledIndexCurrent;
		}
	}
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Define the bars path
		barsPath = CGPathCreateMutable();
		CGRect barCoordinates;
		barCoordinates.origin.x = barCenterLeft - barWidth / 2;
		barCoordinates.origin.y = barTop;
		barCoordinates.size.width = barWidth;
		barCoordinates.size.height = barHeight;
		for(unsigned char barIndex = 0; barIndex < barCount; ++barIndex)
		{
			CGPathAddRect(barsPath, NULL, barCoordinates);
			barCoordinates.origin.x += barWidth + barGap;
		}

		// Define the clock path
		clockPath = CGPathCreateMutable();
		CGPathMoveToPoint(clockPath, NULL, clockLeft + clockRadius, clockTop);
		CGPathAddArcToPoint(clockPath, NULL, clockRight, clockTop, clockRight, clockBottom, clockRadius);
		CGPathAddArcToPoint(clockPath, NULL, clockRight, clockBottom, clockLeft, clockBottom, clockRadius);
		CGPathAddArcToPoint(clockPath, NULL, clockLeft, clockBottom, clockLeft, clockTop, clockRadius);
		CGPathAddArcToPoint(clockPath, NULL, clockLeft, clockTop, clockRight, clockTop, clockRadius);

		// Create a color space to define gradients
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

		// Define the clock gradient
		clockGradient = CGGradientCreateWithColorComponents(colorSpace, clockColors, NULL, 3);

		// Define the LEDs
		UIGraphicsBeginImageContext(CGSizeMake(ledRadius, ledRadius * 4));
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGPoint center = CGPointMake(ledRadius / 2, ledRadius * 2);
		CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, ledColors, NULL, 2);
		CGContextDrawRadialGradient(context, gradient, center, ledRadius * 0.3f, center, ledRadius * 1.8f, kCGGradientDrawsBeforeStartLocation);
		UIImage* ledImage = UIGraphicsGetImageFromCurrentImageContext();
		CGGradientRelease(gradient);
		UIGraphicsEndImageContext();

		// Release the color space
		CGColorSpaceRelease(colorSpace);

		// Set the LEDs
		center.x = barCenterLeft;
		unsigned char ledIndexCurrent = 0;
		for(unsigned char barIndex = 0; barIndex < 4; ++ barIndex)
		{
			center.y = barBottom - ledGap - ledRadius;
			unsigned char const ledIndexEnd = barLedIndex[barIndex];
			while(ledIndexCurrent < ledIndexEnd)
			{
				led[ledIndexCurrent] = [[UIImageView alloc] initWithImage:ledImage];
				led[ledIndexCurrent].center = center;
				[self addSubview:led[ledIndexCurrent]];
				[led[ledIndexCurrent] release];
				++ledIndexCurrent;
				center.y -= ledRadius * 2 + ledGap;
			}
			center.x += barWidth + barGap;
		}

		// Perform a first update
		[self update];
	}
	return self;
}

- (void)willMoveToSuperview:(UIView*)superView
{
	if(superView)
	{
		// Launch a timer to refresh the display
		timer = [NSTimer scheduledTimerWithTimeInterval:(60.0) target:self selector:@selector(update) userInfo:nil repeats:YES];
	}
	else
	{
		// Invalidate the timer
		[timer invalidate];
	}
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Display the bars
	CGContextSetRGBFillColor(context, 0.1f, 0.1f, 0.1f, 1.0f);
	CGContextAddPath(context, barsPath);
	CGContextFillPath(context);

	// Display the LEDs
	CGPoint center;
	center.x = barCenterLeft;
	unsigned char ledIndexCurrent = 0;
	CGContextSetRGBFillColor(context, 0.0f, 0.0f, 0.0f, 0.2f);
	for(unsigned char barIndex = 0; barIndex < 4; ++ barIndex)
	{
		center.y = barBottom - ledGap - ledRadius;
		unsigned char const ledIndexEnd = barLedIndex[barIndex];
		while(ledIndexCurrent < ledIndexEnd)
		{
			CGContextAddArc(context, center.x, center.y, ledRadius * 0.6f, 0.0f, 2 * M_PI, 0);
			CGContextFillPath(context);
			++ledIndexCurrent;
			center.y -= ledRadius * 2 + ledGap;
		}
		center.x += barWidth + barGap;
	}

	// Display the clock
	CGContextSaveGState(context);
	CGContextAddPath(context, clockPath);
	CGContextAddPath(context, barsPath);
	CGContextEOClip(context);
	CGContextDrawLinearGradient(context, clockGradient, CGPointMake(0.0f, clockTop), CGPointMake(0.0f, clockBottom), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);
	CGContextSetLineWidth(context, 5.0f);
	CGContextSetRGBStrokeColor(context, 0.3f, 0.3f, 0.3f, 1.0f);
	CGContextAddPath(context, clockPath);
	CGContextStrokePath(context);
}

- (void)dealloc
{
	// Release the clock gradient
	CGGradientRelease(clockGradient);

	// Release the paths
	CGPathRelease(clockPath);
	CGPathRelease(barsPath);

	// Destroy everything else
	[super dealloc];
}

@end
