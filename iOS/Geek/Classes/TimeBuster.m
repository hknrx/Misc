#import "TimeBuster.h"
#import "Master.h"
#import "Label.h"
#import "Button.h"

#define screenFrameRate 120
#define screenWidth     320.0f
#define screenHeight    (480.0f - 44.0f)

#define coinSlotRadius      30.0f
#define coinSlotLabelWidth  80.0f
#define coinSlotLabelHeight (coinSlotRadius * 2)
#define coinSlotLabelX      0.0f
#define coinSlotLabelY      (screenHeight - coinSlotLabelHeight)
#define coinSlotCenterX     (coinSlotLabelWidth  / 2)
#define coinSlotCenterY     (coinSlotLabelY - coinSlotRadius)
#define coinSlotThickness   4.0f

#define buttonStopRadius  70.0f
#define buttonStopMargin  20.0f
#define buttonStopCornerX (screenWidth / 2 - buttonStopRadius)
#define buttonStopCornerY (screenHeight - buttonStopMargin - buttonStopRadius * 2)
#define buttonPrizeWidth  100.0f
#define buttonPrizeHeight (coinSlotRadius * 2)

#define timerMargin    5.0f
#define timerThickness 5.0f
#define timerWidth     (screenWidth - timerThickness - timerMargin * 2)

#define digitLength 48.0f
#define digitWidth  14.0f
#define digitGap    ((timerWidth - timerThickness - 4 * (digitLength + digitWidth)) / 5)
#define digitFirst  (timerMargin + timerThickness + digitGap + (digitLength + digitWidth) / 2)
#define digitStep   (digitGap + digitLength + digitWidth)
#define digitCenter (buttonStopCornerY / 2)

#define timerHeight (digitLength * 2 + digitWidth + digitGap * 2)
#define timerTop    (digitCenter - timerHeight / 2)
#define timerLeft   (timerMargin + timerThickness / 2)

#define labelTopHeight       26.0f
#define labelBottomHeight    22.0f
#define label100CoinsWidth   180.0f
#define label100CoinsCornerX ((screenWidth - label100CoinsWidth) / 2)
#define label100CoinsCornerY (timerTop - labelTopHeight)
#define labelMajorWidth      280.0f
#define labelMajorCornerX    ((screenWidth - labelMajorWidth) / 2)
#define labelMajorCornerY    (label100CoinsCornerY - labelTopHeight)
#define label3CoinsWidth     130.0f
#define label3CoinsCornerX   ((screenWidth - label3CoinsWidth) / 2)
#define label3CoinsCornerY   (timerTop + timerHeight)
#define labelMinorWidth      270.0f
#define labelMinorCornerX    ((screenWidth - labelMinorWidth) / 2)
#define labelMinorCornerY    (label3CoinsCornerY + labelBottomHeight)

#define timerDurationAcceleration (screenFrameRate * 4)
#define timerDurationStable       (screenFrameRate * 7)
#define timerDurationDeceleration (screenFrameRate * 7)
#define timerTriggerStable        timerDurationAcceleration
#define timerTriggerDeceleration  (timerTriggerStable + timerDurationStable)
#define timerTriggerEnd           (timerTriggerDeceleration + timerDurationDeceleration)

@implementation TimeBuster

static CGFloat const colorsBackground[12] = {0.0f, 0.0f, 0.0f, 1.0f, 0.3f, 0.3f, 0.5f, 1.0f, 0.1f, 0.1f, 0.1f, 1.0f};
static CGFloat const colorsCoinSlot[12] = {0.2f, 0.2f, 0.2f, 1.0f, 0.4f, 0.4f, 0.4f, 1.0f, 0.3f, 0.3f, 0.3f, 1.0f};
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
static unsigned char const segmentConvertDigit[10] = {1, 47, 72, 40, 38, 48, 16, 45, 0, 32};
static unsigned char const segmentConvertSpecial[4][4] =
{
	{127, 127, 127, 127}, // "    "
	{ 48,  82,  26,  68}, // "STOP"
	{127,  26,  30, 127}, // " ON "
	{ 47,   1,   1,   1}, // "1000"
};

- (NSString*)helpText
{
	return @"First, insert a coin to start playing. Tap the STOP button to attempt stopping the timer precisely at 1000; you will be awarded 3 coins if you miss the target but stop between 995 and 1005, or 100 coins if you succeed to stop on 1000!";
}

- (NSString*)infoText
{
	return @"Because Geeks must have a perfect timing to perform well in video games, Geek System kindly proposes them a nice challenge: Time Master!";
}

+ (NSString*)menuName
{
	return @"Time Master";
}

+ (BarContent)barContent
{
	return BAR_COINS;
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Define the background and coin slot gradients
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		gradientBackground = CGGradientCreateWithColorComponents(colorSpace, colorsBackground, NULL, 3);
		gradientCoinSlot = CGGradientCreateWithColorComponents(colorSpace, colorsCoinSlot, NULL, 3);
		CGColorSpaceRelease(colorSpace);

		// Create the segment images
		UIGraphicsBeginImageContext(CGSizeMake(digitLength, digitWidth));
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextTranslateCTM(context, digitLength / 2, digitWidth / 2);
		CGContextSetRGBFillColor(context, 0.2f, 0.05f, 0.1f, 1.0f);
		CGContextAddLines(context, segmentPoints, 6);
		CGContextFillPath(context);
		segmentOff = [UIGraphicsGetImageFromCurrentImageContext() retain];
		CGContextClearRect(context, CGRectInfinite);
		CGContextSetRGBFillColor(context, 1.0f, 0.2f, 0.5f, 1.0f);
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
				segmentOn[digitIndex][segmentIndex].hidden = YES;
				[self addSubview:segmentOn[digitIndex][segmentIndex]];
				[segmentOn[digitIndex][segmentIndex] release];
			}
			center.x += digitStep;
		}

		// Define the labels
		labelStopMajor = [[Label alloc] initWithFrame:CGRectMake(labelMajorCornerX, labelMajorCornerY, labelMajorWidth, labelTopHeight) withSize:18.0f withColor:[UIColor blueColor]];
		labelStopMajor.text = @"STOP ON 1000: MAJOR PRIZE";
		labelStopMajor.textAlignment = UITextAlignmentCenter;
		[self addSubview:labelStopMajor];
		[labelStopMajor release];

		labelStop100Coins = [[Label alloc] initWithFrame:CGRectMake(label100CoinsCornerX, label100CoinsCornerY, label100CoinsWidth, labelTopHeight) withSize:18.0f withColor:[UIColor purpleColor]];
		labelStop100Coins.text = @">>> 100 COINS <<<";
		labelStop100Coins.textAlignment = UITextAlignmentCenter;
		[self addSubview:labelStop100Coins];
		[labelStop100Coins release];

		labelStop3Coins = [[Label alloc] initWithFrame:CGRectMake(label3CoinsCornerX, label3CoinsCornerY, label3CoinsWidth, labelBottomHeight) withSize:14.0f withColor:[UIColor purpleColor]];
		labelStop3Coins.text = @">>> 3 COINS <<<";
		labelStop3Coins.textAlignment = UITextAlignmentCenter;
		[self addSubview:labelStop3Coins];
		[labelStop3Coins release];

		labelStopMinor = [[Label alloc] initWithFrame:CGRectMake(labelMinorCornerX, labelMinorCornerY, labelMinorWidth, labelBottomHeight) withSize:14.0f withColor:[UIColor blueColor]];
		labelStopMinor.text = @"STOP ON 995 TO 1005: MINOR PRIZE";
		labelStopMinor.textAlignment = UITextAlignmentCenter;
		[self addSubview:labelStopMinor];
		[labelStopMinor release];

		labelInsertCoin = [[Label alloc] initWithFrame:CGRectMake(coinSlotLabelX, coinSlotLabelY, coinSlotLabelWidth, coinSlotLabelHeight) withSize:14.0f withColor:[UIColor blueColor]];
		labelInsertCoin.text = @"INSERT\n1 COIN";
		labelInsertCoin.textAlignment = UITextAlignmentCenter;
		labelInsertCoin.numberOfLines = 0;
		[self addSubview:labelInsertCoin];
		[labelInsertCoin release];

		// Define the buttons
		buttonStop = [[Button alloc] initWithColor:[UIColor redColor] withText:@"STOP" withFontSize:buttonStopRadius * 2 / 3 inRectangle:CGRectMake(buttonStopCornerX, buttonStopCornerY, buttonStopRadius * 2, buttonStopRadius * 2) withTarget:self withSelector:@selector(buttonPressed:)];
		[self addSubview:buttonStop];
		[buttonStop release];

		buttonPrize = [[Button alloc] initWithColor:[UIColor greenColor] withText:@"GET\nPRIZE" withFontSize:buttonPrizeHeight / 3 inRectangle:CGRectMake(screenWidth - buttonPrizeWidth, screenHeight - buttonPrizeHeight, buttonPrizeWidth, buttonPrizeHeight) withTarget:self withSelector:@selector(buttonPressed:)];
		buttonPrize.label.numberOfLines = 0;
		[self addSubview:buttonPrize];
		[buttonPrize release];

		// Initialize the state machine
		stateCurrent = -1;
		stateNext = TIME_BUSTER_WAIT;
	}
	return self;
}

- (void)willMoveToSuperview:(UIView*)superView
{
	if(superView)
	{
		// Launch a timer to refresh the display
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / screenFrameRate) target:self selector:@selector(update) userInfo:nil repeats:YES];
	}
	else
	{
		// Invalidate the timer
		[updateTimer invalidate];
	}
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Display the background
	CGContextSaveGState(context);
	CGContextAddRect(context, rect);
	CGContextAddRect(context, CGRectMake(timerLeft, timerTop, timerWidth, timerHeight));
	CGContextEOClip(context);
	CGContextDrawLinearGradient(context, gradientBackground, CGPointZero, CGPointMake(0.0f, coinSlotCenterY), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);

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
	CGContextSetLineWidth(context, timerThickness);
	CGContextSetRGBStrokeColor(context, 0.1f, 0.1f, 0.1f, 1.0f);
	CGContextAddRect(context, CGRectMake(timerLeft, timerTop, timerWidth, timerHeight));
	CGContextStrokePath(context);

	// Display the coin slot
	CGContextSaveGState(context);
	CGContextAddArc(context, coinSlotCenterX, coinSlotCenterY, coinSlotRadius, 0.0f, 2 * M_PI, 0);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, gradientCoinSlot, CGPointMake(0.0f, coinSlotCenterY - coinSlotRadius), CGPointMake(0.0f, coinSlotCenterY + coinSlotRadius), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);
	CGContextSetLineWidth(context, coinSlotThickness);
	CGContextAddArc(context, coinSlotCenterX, coinSlotCenterY, coinSlotRadius, 0.0f, 2 * M_PI, 0);
	CGContextStrokePath(context);

	CGContextSetLineWidth(context, coinSlotThickness * 2);
	CGContextSetLineCap(context, kCGLineCapRound);
	CGContextMoveToPoint(context, coinSlotCenterX, coinSlotCenterY - coinSlotRadius * 0.6f);
	CGContextAddLineToPoint(context, coinSlotCenterX, coinSlotCenterY + coinSlotRadius * 0.6f);
	CGContextStrokePath(context);
}

- (void)update
{
	// Update the state machine: initialize a new state
	if(stateCurrent != stateNext)
	{
		// Reset the frame counter
		frameCounter = 0;

		// Set the state
		stateCurrent = stateNext;
		switch(stateCurrent)
		{
			case TIME_BUSTER_WAIT:
			{
				// Set the labels
				labelStopMajor.glow = YES;
				labelStop100Coins.glow = NO;
				labelStop3Coins.glow = NO;
				labelStopMinor.glow = YES;

				// Set the buttons
				buttonStop.label.glow = NO;
				buttonPrize.label.glow = NO;
				break;
			}
			case TIME_BUSTER_RUN:
			{
				// Set the labels
				labelStop100Coins.glow = NO;
				labelStop3Coins.glow = NO;
				labelInsertCoin.glow = NO;

				// Set the buttons
				buttonStop.label.glow = YES;
				buttonPrize.label.glow = NO;

				// Initialize the timer
				timer = 0.0f;
				break;
			}
			case TIME_BUSTER_FAILED:
			{
				// Set the labels
				labelStopMajor.glow = NO;
				labelStop100Coins.glow = NO;
				labelStop3Coins.glow = NO;
				labelStopMinor.glow = NO;
				labelInsertCoin.glow = NO;

				// Set the buttons
				buttonStop.label.glow = NO;
				buttonPrize.label.glow = NO;
				break;
			}
			case TIME_BUSTER_MINOR_PRIZE:
			{
				// Set the labels
				labelStopMajor.glow = NO;
				labelStop100Coins.glow = NO;
				labelStopMinor.glow = YES;
				labelInsertCoin.glow = NO;

				// Set the buttons
				buttonStop.label.glow = NO;
				buttonPrize.label.glow = YES;
				break;
			}
			case TIME_BUSTER_MAJOR_PRIZE:
			{
				// Set the labels
				labelStopMajor.glow = YES;
				labelStop3Coins.glow = NO;
				labelStopMinor.glow = NO;
				labelInsertCoin.glow = NO;

				// Set the buttons
				buttonStop.label.glow = NO;
				buttonPrize.label.glow = YES;
				break;
			}
		}
	}

	// Update the state machine: execute the current state
	unsigned char const* segmentConvert;
	switch(stateCurrent)
	{
		case TIME_BUSTER_WAIT:
		{
			// Update the label
			labelInsertCoin.glow = frameCounter & 32;

			// Update the timer
			segmentConvert = segmentConvertSpecial[(frameCounter >> 7) & 3];
			break;
		}
		case TIME_BUSTER_RUN:
		{
			// Update the labels
			labelStopMajor.glow = frameCounter & 32;
			labelStopMinor.glow = frameCounter & 32;

			// Update the timer
			segmentConvert = NULL;
			if(frameCounter < timerTriggerStable)
			{
				timer += frameCounter * 1.0f / timerDurationAcceleration;
			}
			else if(frameCounter < timerTriggerDeceleration)
			{
				timer += 1.0f;
			}
			else if(frameCounter < timerTriggerEnd)
			{
				timer += (timerTriggerEnd - frameCounter) * 1.0f / timerDurationDeceleration;
			}
			else
			{
				stateNext = TIME_BUSTER_FAILED;
			}
			break;
		}
		case TIME_BUSTER_FAILED:
		{
			// Update the timer
			segmentConvert = frameCounter & 32 ? NULL : segmentConvertSpecial[0];
			if(frameCounter & 512)
			{
				stateNext = TIME_BUSTER_WAIT;
			}
			break;
		}
		case TIME_BUSTER_MINOR_PRIZE:
		{
			// Update the label
			labelStop3Coins.glow = frameCounter & 32;

			// Update the timer
			segmentConvert = frameCounter & 32 ? NULL : segmentConvertSpecial[0];
			break;
		}
		case TIME_BUSTER_MAJOR_PRIZE:
		{
			// Update the label
			labelStop100Coins.glow = frameCounter & 32;

			// Update the timer
			segmentConvert = frameCounter & 32 ? NULL : segmentConvertSpecial[0];
			break;
		}
	}

	// Update the frame counter
	++frameCounter;

	// Update the 4 digits
	unsigned int digits = timer;
	for(char digitIndex = 3; digitIndex >= 0; --digitIndex)
	{
		unsigned char segmentConverted;
		if(segmentConvert)
		{
			segmentConverted = segmentConvert[digitIndex];
		}
		else
		{
			unsigned int const digitsTenth = digits / 10;
			segmentConverted = segmentConvertDigit[digits - 10 * digitsTenth];
			digits = digitsTenth;
		}
		for(unsigned char segmentIndex = 0; segmentIndex < 7; ++segmentIndex)
		{
			segmentOn[digitIndex][segmentIndex].hidden = segmentConverted & (1 << segmentIndex);
		}
	}
}

- (void)buttonPressed:(id)sender
{
	if(sender == buttonStop)
	{
		if(stateCurrent == TIME_BUSTER_RUN)
		{
			// Stop the timer
			unsigned int const digits = timer;
			if(digits == 1000)
			{
				stateNext = TIME_BUSTER_MAJOR_PRIZE;
			}
			else if(digits >= 995 && digits <= 1005)
			{
				stateNext = TIME_BUSTER_MINOR_PRIZE;
			}
			else
			{
				stateNext = TIME_BUSTER_FAILED;
			}
		}
	}
	else if(sender == buttonPrize)
	{
		if(stateCurrent == TIME_BUSTER_MAJOR_PRIZE || stateCurrent == TIME_BUSTER_MINOR_PRIZE)
		{
			// Get the prize
			if(stateCurrent == TIME_BUSTER_MAJOR_PRIZE)
			{
				[(Master*)[self superview] cashAdd:100 increaseKey:@"FUNFAIR_TIME_MAJOR"];
			}
			else
			{
				[(Master*)[self superview] cashAdd:3 increaseKey:@"FUNFAIR_TIME_MINOR"];
			}

			// Go back to the wait state
			stateNext = TIME_BUSTER_WAIT;
		}
	}
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	// Only care about touch events when the game is in its wait state
	if(stateCurrent == TIME_BUSTER_WAIT)
	{
		// Check whether the coin slot has been touched
		CGPoint point = [[touches anyObject] locationInView:self];
		point.x -= coinSlotCenterX;
		point.y -= coinSlotCenterY;
		if(point.x * point.x + point.y * point.y <= coinSlotRadius * coinSlotRadius)
		{
			// Insert a coin
			[(Master*)[self superview] cashAdd:-1 increaseKey:@"FUNFAIR_TIME_COUNT"];

			// Start the game
			stateNext = TIME_BUSTER_RUN;
		}
	}
}

- (void)dealloc
{
	// Release the segment image
	[segmentOff release];

	// Release the background and coin slot gradients
	CGGradientRelease(gradientCoinSlot);
	CGGradientRelease(gradientBackground);

	// Destroy everything else
	[super dealloc];
}

@end
