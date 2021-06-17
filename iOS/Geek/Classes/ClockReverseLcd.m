#import "ClockReverseLcd.h"

#define screenWidth  320.0f
#define screenHeight (480.0f - 44.0f)

#define digitLength 50.0f
#define digitWidth  15.0f
#define digitGap    ((screenWidth - 4 * (digitLength + digitWidth)) / 5)
#define digitFirst  (digitGap + (digitLength + digitWidth) / 2)
#define digitStep   (digitGap + digitLength + digitWidth)
#define digitCenter (screenHeight / 2)

@implementation ClockReverseLcd

static CGPoint const segmentPoints[6] =
{
	{-digitLength * 0.45f, 0.0f},
	{-(digitLength - digitWidth) * 0.45f, digitWidth * 0.45f},
	{(digitLength - digitWidth) * 0.45f, digitWidth * 0.45f},
	{digitLength * 0.45f, 0.0f},
	{(digitLength - digitWidth) * 0.45f, -digitWidth * 0.45f},
	{-(digitLength - digitWidth) * 0.45f, -digitWidth * 0.45f},
};
static CGAffineTransform const segmentTransforms[7] =
{
	{1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f},
	{1.0f, 0.0f, 0.0f, 1.0f, 0.0f, -digitLength},
	{1.0f, 0.0f, 0.0f, 1.0f, 0.0f, digitLength},
	{0.0f, 1.0f, -1.0f, 0.0f, -digitLength / 2, -digitLength / 2},
	{0.0f, 1.0f, -1.0f, 0.0f, digitLength / 2, -digitLength / 2},
	{0.0f, 1.0f, -1.0f, 0.0f, -digitLength / 2, digitLength / 2},
	{0.0f, 1.0f, -1.0f, 0.0f, digitLength / 2, digitLength / 2},
};
static unsigned char const segmentConvert[10] = {254, 208, 183, 215, 217, 207, 239, 210, 255, 223};

- (NSString*)helpText
{
	return @"Just be aware that the 7 segments of each digit have got their connections inverted (ON <-> OFF)!";
}

- (NSString*)infoText
{
	return @"Enjoy a weird 4 digits LCD-like clock that only Geeks won't think it is broken!";
}

+ (NSString*)menuName
{
	return @"Reverse LCD";
}

+ (BarContent)barContent
{
	return BAR_NOTHING;
}

- (void)updateDigit:(unsigned char)digitIndex withNumber:(NSInteger)number
{
	unsigned char const segmentConverted = segmentConvert[number];
	for(unsigned char segmentIndex = 0; segmentIndex < 7; ++segmentIndex)
	{
		segmentOn[digitIndex][segmentIndex].hidden = segmentConverted & (1 << segmentIndex);
	}
}

- (void)update
{
	// Get the time
	NSDateComponents const*const dateComponents = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:[NSDate date]];
	NSInteger const hour = [dateComponents hour];
	NSInteger const minute = [dateComponents minute];

	// Update the 4 digits
	[self updateDigit:0 withNumber:hour / 10];
	[self updateDigit:1 withNumber:hour % 10];
	[self updateDigit:2 withNumber:minute / 10];
	[self updateDigit:3 withNumber:minute % 10];
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Create the segment images
		UIGraphicsBeginImageContext(CGSizeMake(digitLength, digitWidth));
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextTranslateCTM(context, digitLength / 2, digitWidth / 2);
		CGContextSetRGBFillColor(context, 0.1f, 0.05f, 0.05f, 1.0f);
		CGContextAddLines(context, segmentPoints, 6);
		CGContextFillPath(context);
		segmentOff = [UIGraphicsGetImageFromCurrentImageContext() retain];
		CGContextClearRect(context, CGRectInfinite);
		CGContextSetRGBFillColor(context, 1.0f, 0.2f, 0.2f, 1.0f);
		CGContextAddLines(context, segmentPoints, 6);
		CGContextFillPath(context);
		UIImage* segmentOnImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		// Set the digits
		CGPoint center;
		center.x = digitFirst;
		center.y = digitCenter;
		for(unsigned char digitIndex = 0; digitIndex < 4; ++digitIndex)
		{
			for(unsigned char segmentIndex = 0; segmentIndex < 7; ++segmentIndex)
			{
				segmentOn[digitIndex][segmentIndex] = [[UIImageView alloc] initWithImage:segmentOnImage];
				segmentOn[digitIndex][segmentIndex].transform = segmentTransforms[segmentIndex];
				segmentOn[digitIndex][segmentIndex].center = center;
				[self addSubview:segmentOn[digitIndex][segmentIndex]];
				[segmentOn[digitIndex][segmentIndex] release];
			}
			center.x += digitStep;
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

	// Display the 4 digits
	for(unsigned char digitIndex = 0; digitIndex < 4; ++digitIndex)
	{
		for(unsigned char segmentIndex = 0; segmentIndex < 7; ++segmentIndex)
		{
			CGContextSaveGState(context);
			CGContextTranslateCTM(context, digitFirst + digitIndex * digitStep, digitCenter);
			CGContextConcatCTM(context, segmentTransforms[segmentIndex]);
			CGContextTranslateCTM(context, -digitLength / 2, -digitWidth / 2);
			[segmentOff drawAtPoint:CGPointZero];
			CGContextRestoreGState(context);
		}
	}
}

- (void)dealloc
{
	// Release the segment image
	[segmentOff release];

	// Destroy everything else
	[super dealloc];
}

@end
