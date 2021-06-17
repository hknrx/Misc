#import "ClockBinary.h"

#define ledRadius 10.0f
#define ledGap    20.0f

@implementation ClockBinary

static CGFloat const colorsClock[12] = {0.2f, 0.2f, 0.4f, 1.0f, 0.3f, 0.3f, 0.6f, 1.0f, 0.1f, 0.1f, 0.3f, 1.0f};
static CGFloat const colorsLed[3][8] =
{
	{0.5f, 1.0f, 0.5f, 1.0f, 0.2f, 0.5f, 0.2f, 0.0f},
	{1.0f, 0.5f, 0.5f, 1.0f, 0.5f, 0.2f, 0.2f, 0.0f},
	{1.0f, 1.0f, 0.5f, 1.0f, 0.5f, 0.5f, 0.2f, 0.0f},
};

- (NSString*)helpText
{
	return @"The upper row of LEDs represent hours, the one in the middle minutes, and the lower row seconds. LEDs from the right to the left have the following values: 1, 2, 4, 8, 16 and 32; just sum the values to read the time!";
}

- (NSString*)infoText
{
	return @"Enjoy this nice classic binary clock that all Geeks dream of having at home!";
}

+ (NSString*)menuName
{
	return @"Binary";
}

+ (BarContent)barContent
{
	return BAR_NOTHING;
}

- (void)displayLeds:(UIImageView**)leds atHeight:(CGFloat)y withBits:(unsigned char)bitCount withImage:(UIImage*)image
{
	CGPoint center;
	center.x = 160.0f - (ledRadius + (ledGap / 2)) * (bitCount - 1);
	center.y = y;
	while(bitCount--)
	{
		leds[bitCount] = [[UIImageView alloc] initWithImage:image];
		leds[bitCount].center = center;
		[self addSubview:leds[bitCount]];
		[leds[bitCount] release];
		center.x += ledRadius * 2 + ledGap;
	}
}

- (void)displayLedsAtHeight:(CGFloat)y withBits:(unsigned char)bitCount onContext:(CGContextRef)context
{
	CGPoint center;
	center.x = 160.0f - (ledRadius + (ledGap / 2)) * (bitCount - 1);
	center.y = y;
	while(bitCount--)
	{
		CGContextAddArc(context, center.x, center.y, ledRadius, 0.0f, 2 * M_PI, 0);
		CGContextFillPath(context);
		center.x += ledRadius * 2 + ledGap;
	}
}

- (void)update
{
	// Get the time
	NSDateComponents const*const dateComponents = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:[NSDate date]];
	NSInteger const hour = [dateComponents hour];
	NSInteger const minute = [dateComponents minute];
	NSInteger const second = [dateComponents second];

	// Display the time
	for(unsigned char bitCount = 0; bitCount < 5; ++bitCount)
	{
		NSInteger const mask = 1 << bitCount;
		ledHour[bitCount].hidden = !(hour & mask);
		ledMinute[bitCount].hidden = !(minute & mask);
		ledSecond[bitCount].hidden = !(second & mask);
	}
	ledMinute[5].hidden = !(minute & 32);
	ledSecond[5].hidden = !(second & 32);
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Define the clock path
		clockPath = CGPathCreateMutable();
		CGPathAddArc(clockPath, NULL, 160.0f, 240.0f - 22.0f, 140.0f, 0.0f, 2 * M_PI, 0);

		// Create a color space to define gradients
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

		// Define the clock gradient
		clockGradient = CGGradientCreateWithColorComponents(colorSpace, colorsClock, NULL, 3);

		// Define the LEDs
		UIImage* ledImage[3];
		UIGraphicsBeginImageContext(CGSizeMake(ledRadius * 4, ledRadius * 4));
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGPoint center = CGPointMake(ledRadius * 2, ledRadius * 2);
		for(unsigned char ledIndex = 0; ledIndex < 3; ++ledIndex)
		{
			CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colorsLed[ledIndex], NULL, 2);
			CGContextClearRect(context, CGRectInfinite);
			CGContextDrawRadialGradient(context, gradient, center, ledRadius * 0.6f, center, ledRadius * 2.0f, kCGGradientDrawsBeforeStartLocation);
			ledImage[ledIndex] = UIGraphicsGetImageFromCurrentImageContext();
			CGGradientRelease(gradient);
		}
		UIGraphicsEndImageContext();

		// Release the color space
		CGColorSpaceRelease(colorSpace);

		// Set the LEDs
		[self displayLeds:ledHour atHeight:200.0f - 22.0f withBits:5 withImage:ledImage[0]];
		[self displayLeds:ledMinute atHeight:240.0f - 22.0f withBits:6 withImage:ledImage[1]];
		[self displayLeds:ledSecond atHeight:280.0f - 22.0f withBits:6 withImage:ledImage[2]];

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
		timer = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self selector:@selector(update) userInfo:nil repeats:YES];
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

	// Display the clock
	CGContextSaveGState(context);
	CGContextAddPath(context, clockPath);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, clockGradient, CGPointMake(0.0f, 240.0f - 22.0f - 140.0f), CGPointMake(0.0f, 240.0f - 22.0f + 140.0f), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);
	CGContextSetLineWidth(context, 5.0f);
	CGContextSetRGBStrokeColor(context, 0.3f, 0.3f, 0.3f, 1.0f);
	CGContextAddPath(context, clockPath);
	CGContextStrokePath(context);

	// Display the LEDs
	CGContextSetRGBFillColor(context, 0.1f, 0.1f, 0.1f, 0.8f);
	[self displayLedsAtHeight:200.0f - 22.0f withBits:5 onContext:context];
	[self displayLedsAtHeight:240.0f - 22.0f withBits:6 onContext:context];
	[self displayLedsAtHeight:280.0f - 22.0f withBits:6 onContext:context];
}

- (void)dealloc
{
	// Release the clock gradient
	CGGradientRelease(clockGradient);

	// Release the clock path
	CGPathRelease(clockPath);

	// Destroy everything else
	[super dealloc];
}

@end
