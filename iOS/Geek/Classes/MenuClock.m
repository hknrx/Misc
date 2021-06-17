#import "MenuClock.h"
#import "ClockBarcode.h"
#import "ClockBinary.h"
#import "ClockBlocks.h"
#import "ClockReverseLcd.h"

#define clockBottom           300.0f
#define clockWidth            120.0f
#define clockBodyRight        280.0f
#define clockBodyRadius       (clockWidth / 2)
#define clockCenterRadius     3.0f
#define clockCenterX          (clockBodyRight - clockBodyRadius)
#define clockCenterY          (clockBottom - clockBodyRadius)
#define clockFaceRadius       (clockBodyRadius - 8.0f)
#define clockMarkSizeMinute   4.0f
#define clockMarkSizeHour     8.0f
#define clockMarkLeftMinute   (clockCenterX - clockMarkSizeMinute / 2)
#define clockMarkLeftHour     (clockCenterX - clockMarkSizeHour / 2)
#define clockMarkTopMinute    (clockCenterY - clockMarkSizeMinute / 2)
#define clockMarkTopHour      (clockCenterY - clockMarkSizeHour / 2)
#define clockMarkRadius       (clockFaceRadius - 6.0f)
#define clockHandMinute       (clockMarkRadius * 0.9f)
#define clockHandHour         (clockMarkRadius * 0.5f)
#define clockButtonWidth      20.0f
#define clockButtonHeight     10.0f
#define clockButtonLeft       (clockCenterX - clockButtonWidth / 2)
#define clockButtonBottom     (clockCenterY - clockBodyRadius)
#define clockButtonTop        (clockButtonBottom - clockButtonHeight)
#define clockButtonStripCount 3
#define clockButtonStripGap   (clockButtonWidth / (clockButtonStripCount + 1))
#define clockButtonStripLeft  (clockButtonLeft + clockButtonStripGap)

@implementation MenuClock

- (NSString*)helpText
{
	return @"Tap the screen to select one of these fantastic LED clocks: binary, reverse LCD, barcode or blocks!";
}

- (NSString*)infoText
{
	return @"Because Geeks don't use classic watches and dislike normal clocks, they usually manage to find weird devices that only them can understand. Geek Systems brings them a nice collections of LED clocks!";
}

+ (NSString*)menuName
{
	return @"LED Clocks";
}

+ (BarContent)barContent
{
	return BAR_NOTHING;
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame withButtonClasses:[NSArray arrayWithObjects:[ClockBinary class], [ClockReverseLcd class], [ClockBarcode class], [ClockBlocks class], nil]])
	{
		// Define the clock
		clockStrokePath = CGPathCreateMutable();
		CGPathAddArc(clockStrokePath, NULL, clockCenterX, clockCenterY, clockFaceRadius, 0.0f, 2 * M_PI, 0);
		CGPathMoveToPoint(clockStrokePath, NULL, clockBodyRight, clockCenterY);
		CGPathAddArc(clockStrokePath, NULL, clockCenterX, clockCenterY, clockBodyRadius, 0.0f, 2 * M_PI, 0);
		CGPathAddRect(clockStrokePath, NULL, CGRectMake(clockButtonLeft, clockButtonTop, clockButtonWidth, clockButtonHeight));
		CGFloat x = clockButtonStripLeft;
		for(unsigned char stripIndex = 0; stripIndex < clockButtonStripCount; ++stripIndex)
		{
			CGPathMoveToPoint(clockStrokePath, NULL, x, clockButtonTop);
			CGPathAddLineToPoint(clockStrokePath, NULL, x, clockButtonBottom);
			x += clockButtonStripGap;
		}

		clockFillPath = CGPathCreateMutable();
		CGPathAddArc(clockFillPath, NULL, clockCenterX, clockCenterY, clockCenterRadius, 0.0f, 2 * M_PI, 0);
		float angle = 0.0f;
		for(unsigned char markIndex = 0; markIndex < 12; ++markIndex)
		{
			CGFloat const x = clockMarkRadius * sinf(angle);
			CGFloat const y = clockMarkRadius * cosf(angle);
			if(markIndex % 3)
			{
				CGPathAddRect(clockFillPath, NULL, CGRectMake(clockMarkLeftMinute + x, clockMarkTopMinute + y, clockMarkSizeMinute, clockMarkSizeMinute));
			}
			else
			{
				CGPathAddRect(clockFillPath, NULL, CGRectMake(clockMarkLeftHour + x, clockMarkTopHour + y, clockMarkSizeHour, clockMarkSizeHour));
			}
			angle += M_PI / 6;
		}
	}
	return self;
}

- (void)willMoveToSuperview:(UIView*)superView
{
	if(superView)
	{
		// Launch a timer to refresh the display
		timer = [NSTimer scheduledTimerWithTimeInterval:(60.0) target:self selector:@selector(setNeedsDisplay) userInfo:nil repeats:YES];
	}
	else
	{
		// Invalidate the timer
		[timer invalidate];
	}
}

- (void)drawRect:(CGRect)rect
{
	// Get the time
	NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:[NSDate date]];
	NSInteger hour = [dateComponents hour];
	NSInteger minute = [dateComponents minute];

	// Draw the computer
	[super drawRect:rect];

	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Draw the clock
	float const angleHour = (hour * 60 + minute) * M_PI / 360;
	float const angleMinute = minute * M_PI / 30;

	CGPoint points[3];
	points[0].x = clockCenterX + clockHandHour * sinf(angleHour);
	points[0].y = clockCenterY - clockHandHour * cosf(angleHour);
	points[1].x = clockCenterX;
	points[1].y = clockCenterY;
	points[2].x = clockCenterX + clockHandMinute * sinf(angleMinute);
	points[2].y = clockCenterY - clockHandMinute * cosf(angleMinute);

	CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 1.0f, 1.0f);
	CGContextSetLineWidth(context, 2.0f);
	CGContextAddPath(context, clockStrokePath);
	CGContextAddLines(context, points, 3);
	CGContextStrokePath(context);

	CGContextSetRGBFillColor(context, 0.0f, 0.0f, 1.0f, 1.0f);
	CGContextAddPath(context, clockFillPath);
	CGContextFillPath(context);
}

- (void)dealloc
{
	// Release the paths
	CGPathRelease(clockFillPath);
	CGPathRelease(clockStrokePath);

	// Destroy everything else
	[super dealloc];
}

@end
