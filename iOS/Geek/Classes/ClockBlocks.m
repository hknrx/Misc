#import "ClockBlocks.h"

#define screenFrameRate 20
#define screenWidth     320.0f
#define screenHeight    (480.0f - 44.0f)

#define blockWidth      50.0f
#define blockHeight     50.0f
#define blockTimerLimit (5 * screenFrameRate)

#define containerGap        20.0f
#define containerHeight     (containerRowCount * blockHeight)
#define containerLeftWidth  (containerLeftColumnCount * blockWidth)
#define containerRightWidth (containerRightColumnCount * blockWidth)
#define containerThickness  5.0f

#define clockHeight (containerHeight * 2 + containerGap)
#define clockWidth  (containerLeftWidth + containerGap + containerRightWidth)

#define containerTopTop    ((screenHeight - clockHeight) / 2)
#define containerBottomTop (containerTopTop + containerHeight + containerGap)
#define containerLeftLeft  ((screenWidth - clockWidth) / 2)
#define containerRightLeft (containerLeftLeft + containerLeftWidth + containerGap)

@implementation ClockBlocks

- (NSString*)helpText
{
	return @"Each group of blocks represents one digit of the time; the upper row gives hours, the lower row minutes. Just count the number of lights in each group to read the time!";
}

- (NSString*)infoText
{
	return @"Enjoy this classy blocks clock that every Geek shall have at home!";
}

+ (NSString*)menuName
{
	return @"Blocks";
}

+ (BarContent)barContent
{
	return BAR_NOTHING;
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Define the blocks
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGFloat colors[8];
		colors[3] = 1.0f;
		colors[4] = 0.1f;
		colors[5] = 0.1f;
		colors[6] = 0.1f;
		colors[7] = 1.0f;

		UIGraphicsBeginImageContext(CGSizeMake(blockWidth, blockHeight));
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGPoint center = CGPointMake(blockWidth / 2, blockHeight / 2);
		for(unsigned char indexColor = 0; indexColor < 7; ++indexColor)
		{
			for(unsigned char indexComponent = 0; indexComponent < 3; ++indexComponent)
			{
				colors[indexComponent] = indexColor & (1 << indexComponent) ? 1.0f : 0.3f;
			}
			CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
			CGContextClearRect(context, CGRectInfinite);
			CGContextDrawRadialGradient(context, gradient, center, blockHeight / 4, center, blockHeight * M_SQRT1_2, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
			blockImage[indexColor] = [UIGraphicsGetImageFromCurrentImageContext() retain];
			CGGradientRelease(gradient);
		}
		UIGraphicsEndImageContext();
		CGColorSpaceRelease(colorSpace);
	}
	return self;
}

- (void)willMoveToSuperview:(UIView*)superView
{
	if(superView)
	{
		// Launch a timer to refresh the display
		timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / screenFrameRate) target:self selector:@selector(update) userInfo:nil repeats:YES];
	}
	else
	{
		// Invalidate the timer
		[timer invalidate];
	}
}

- (void)displayLeftContainer:(BOOL)left topContainer:(BOOL)top onContext:(CGContextRef)context
{
	// Define the number of blocks in the container as well as its bounding box and the position and index of the first block
	unsigned char blockIndex;
	unsigned char blockCount;
	CGPoint blockCoordinates;
	CGRect containerCoordinates;
	if(left)
	{
		blockIndex = 0;
		blockCount = containerRowCount * containerLeftColumnCount;
		blockCoordinates.x = containerLeftLeft;
		containerCoordinates.size.width = containerLeftWidth + containerThickness;
	}
	else
	{
		blockIndex = containerRowCount * containerLeftColumnCount;
		blockCount = containerRowCount * containerRightColumnCount;
		blockCoordinates.x = containerRightLeft;
		containerCoordinates.size.width = containerRightWidth + containerThickness;
	}
	if(top)
	{
		blockCoordinates.y = containerTopTop;
	}
	else
	{
		blockIndex += containerRowCount * (containerLeftColumnCount + containerRightColumnCount);
		blockCoordinates.y = containerBottomTop;
	}
	containerCoordinates.origin.x = blockCoordinates.x - containerThickness / 2;
	containerCoordinates.origin.y = blockCoordinates.y - containerThickness / 2;
	containerCoordinates.size.height = containerHeight + containerThickness;

	// Display all the blocks of the container
	unsigned char rowCount = containerRowCount;
	while(blockCount--)
	{
		[blockImage[rand() % 6 + 1] drawAtPoint:blockCoordinates];
		if(!blockView[blockIndex])
		{
			CGPoint blockCenter;
			blockCenter.x = blockCoordinates.x + blockWidth / 2;
			blockCenter.y = blockCoordinates.y + blockHeight / 2;
			blockView[blockIndex] = [[UIImageView alloc] initWithImage:blockImage[0]];
			blockView[blockIndex].center = blockCenter;
			[self addSubview:blockView[blockIndex]];
			[blockView[blockIndex] release];
		}
		++blockIndex;
		if(--rowCount)
		{
			blockCoordinates.y += blockHeight;
		}
		else
		{
			rowCount = containerRowCount;
			blockCoordinates.y -= containerHeight - blockHeight;
			blockCoordinates.x += blockWidth;
		}
	}

	// Display the container
	CGContextSetLineWidth(context, containerThickness);
	CGContextSetRGBStrokeColor(context, 0.1f, 0.1f, 0.1f, 1.0f);
	CGContextAddRect(context, containerCoordinates);
	CGContextStrokePath(context);
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Display the 4 containers
	[self displayLeftContainer:YES topContainer:YES onContext:context];
	[self displayLeftContainer:NO topContainer:YES onContext:context];
	[self displayLeftContainer:YES topContainer:NO onContext:context];
	[self displayLeftContainer:NO topContainer:NO onContext:context];
}

- (void)setNumber:(NSInteger)number inLeftContainer:(BOOL)left inTopContainer:(BOOL)top
{
	// Define the number of blocks in the container and the index of the first block
	unsigned char blockIndex;
	unsigned char blockCount;
	if(top)
	{
		blockIndex = 0;
	}
	else
	{
		blockIndex = containerRowCount * (containerLeftColumnCount + containerRightColumnCount);
	}
	if(left)
	{
		blockCount = containerRowCount * containerLeftColumnCount;
	}
	else
	{
		blockIndex += containerRowCount * containerLeftColumnCount;
		blockCount = containerRowCount * containerRightColumnCount;
	}

	// Select blocks that should be switched-on
	unsigned short blockSwitch;
	unsigned short blockControl;
	if(number < blockCount - number)
	{
		blockSwitch = 0;
		blockControl = 0;
	}
	else
	{
		number = blockCount - number;
		blockSwitch = (1 << blockCount) - 1;
		blockControl = 1;
	}
	while(number--)
	{
		unsigned short blockNumber = rand() % blockCount;
		while(((blockSwitch >> blockNumber) & 1) ^ blockControl)
		{
			if(++blockNumber >= blockCount)
			{
				blockNumber -= blockCount;
			}
		}
		blockSwitch ^= 1 << blockNumber;
	}

	// Set the state of each block
	while(blockCount--)
	{
		blockView[blockIndex++].tag = blockSwitch & (1 << blockCount);
	}
}

- (void)update
{
	if(blockTimer)
	{
		// Animate all the blocks
		for(unsigned char blockIndex = 0; blockIndex < blockCountTotal; ++blockIndex)
		{
			if(blockView[blockIndex].tag)
			{
				if(blockView[blockIndex].alpha >= 0.1f)
				{
					blockView[blockIndex].alpha -= 0.1f;
				}
			}
			else
			{
				if(blockView[blockIndex].alpha <= 0.9f)
				{
					blockView[blockIndex].alpha += 0.1f;
				}
			}
		}

		// Handle the timer
		--blockTimer;
	}
	else
	{
		// Get the time
		NSDateComponents const*const dateComponents = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:[NSDate date]];
		NSInteger const hour = [dateComponents hour];
		NSInteger const minute = [dateComponents minute];

		// Set the color of each block
		[self setNumber:hour / 10 inLeftContainer:YES inTopContainer:YES];
		[self setNumber:hour % 10 inLeftContainer:NO inTopContainer:YES];
		[self setNumber:minute / 10 inLeftContainer:YES inTopContainer:NO];
		[self setNumber:minute % 10 inLeftContainer:NO inTopContainer:NO];

		// Rearm the timer
		blockTimer = blockTimerLimit;
	}
}

- (void)dealloc
{
	// Release the block images
	for(unsigned char indexColor = 0; indexColor < 7; ++indexColor)
	{
		[blockImage[indexColor] release];
	}

	// Destroy everything else
	[super dealloc];
}

@end
