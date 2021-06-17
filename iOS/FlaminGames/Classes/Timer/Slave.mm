#import "Sound.h"
#import "Slave.h"
#import "Master.h"
#import "Label.h"
#import "Button.h"
#import "OFAchievement.h"
#import "OFHighScoreService.h"
#import "OpenFeintLocalSettings.h"

#define screenFrameRate 120

#define areaWidth  screenWidth
#define areaHeight (screenHeight - topBarHeight)

#ifdef FLAMIN_GIANT
	#define coinSlotRadius     60.0f
	#define coinSlotWidth      16.0f
	#define coinSlotLabelWidth 160.0f

	#define buttonStopRadius 150.0f
	#define buttonPrizeWidth 200.0f

	#define timerMargin 15.0f

	#define digitLength 120.0f
	#define digitWidth  35.0f

	#define labelTopHeight     52.0f
	#define labelBottomHeight  40.0f
	#define labelSwapHeight    50.0f
	#define label100CoinsWidth 360.0f
	#define labelMajorWidth    560.0f
	#define label3CoinsWidth   260.0f
	#define labelMinorWidth    540.0f
	#define labelSwapWidth     200.0f
#else
	#define coinSlotRadius     30.0f
	#define coinSlotWidth      8.0f
	#define coinSlotLabelWidth 80.0f

	#define buttonStopRadius 70.0f
	#define buttonPrizeWidth 100.0f

	#define timerMargin 5.0f

	#define digitLength 48.0f
	#define digitWidth  14.0f

	#define labelTopHeight     26.0f
	#define labelBottomHeight  20.0f
	#define labelSwapHeight    20.0f
	#define label100CoinsWidth 180.0f
	#define labelMajorWidth    280.0f
	#define label3CoinsWidth   130.0f
	#define labelMinorWidth    270.0f
	#define labelSwapWidth     80.0f
#endif

#define coinSlotLabelHeight (coinSlotRadius * 2)
#define coinSlotLabelX      0.0f
#define coinSlotLabelY      (areaHeight - coinSlotLabelHeight)
#define coinSlotCenterX     (coinSlotLabelWidth  / 2)
#define coinSlotCenterY     (coinSlotLabelY - coinSlotRadius)
#define coinSlotThickness   4.0f

#define buttonStopCornerX (areaWidth / 2 - buttonStopRadius)
#define buttonStopCornerY (coinSlotCenterY - buttonStopRadius)
#define buttonPrizeHeight (coinSlotRadius * 2)

#define timerThickness 5.0f
#define timerWidth     (areaWidth - timerThickness - timerMargin * 2)

#define digitGap    ((timerWidth - timerThickness - 4 * (digitLength + digitWidth)) / 5)
#define digitFirst  (timerMargin + timerThickness + digitGap + (digitLength + digitWidth) / 2)
#define digitStep   (digitGap + digitLength + digitWidth)
#define digitCenter (buttonStopCornerY / 2)

#define timerHeight (digitLength * 2 + digitWidth + digitGap * 2)
#define timerTop    (digitCenter - timerHeight / 2)
#define timerLeft   (timerMargin + timerThickness / 2)

#define label100CoinsCornerX ((areaWidth - label100CoinsWidth) / 2)
#define label100CoinsCornerY (timerTop - labelTopHeight)
#define labelMajorCornerX    ((areaWidth - labelMajorWidth) / 2)
#define labelMajorCornerY    (label100CoinsCornerY - labelTopHeight)
#define label3CoinsCornerX   ((areaWidth - label3CoinsWidth) / 2)
#define label3CoinsCornerY   (timerTop + timerHeight)
#define labelMinorCornerX    ((areaWidth - labelMinorWidth) / 2)
#define labelMinorCornerY    (label3CoinsCornerY + labelBottomHeight)
#define labelSwapCornerX     (areaWidth - labelSwapWidth)
#define labelSwapCornerY     buttonStopCornerY

#define timerDurationAcceleration (screenFrameRate * 4)
#define timerDurationStable       (screenFrameRate * 7)
#define timerDurationDeceleration (screenFrameRate * 7)
#define timerTriggerStable        timerDurationAcceleration
#define timerTriggerDeceleration  (timerTriggerStable + timerDurationStable)
#define timerTriggerEnd           (timerTriggerDeceleration + timerDurationDeceleration)

@implementation Slave

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

static enum {VERSION_MALL = 0, VERSION_CLUB, VERSION_VIP, VERSION_COUNT} version = VERSION_MALL;

static struct
{
	CGFloat colorsSegmentOff[4];
	CGFloat colorsSegmentOn[4];
	CGFloat colorsStopButton[3];
	NSString* helpText;
	NSString* labelSwap;
	NSInteger coinsMajorPrize;
	NSInteger coinsMinorPrize;
	NSInteger coinsPlay;
}
const settings[VERSION_COUNT] =
{
	// VERSION_MALL
	{
		{0.2f, 0.05f, 0.1f, 1.0f},
		{1.0f, 0.2f, 0.5f, 1.0f},
		{1.0f, 0.0f, 0.0f},
		@"WELCOME TO\nFLAMIN TIMER!\n\nFirst, insert a coin to start playing. Tap the STOP button to attempt stopping the timer precisely at 1000; you will be awarded 3 coins if you miss the target but stop between 995 and 1005, or 100 coins if you succeed to stop on 1000!\n\nWhen not playing, you can tap the label \"CLUB\" to go try the Frozen Timer!\n\nAnd if you feel like you can compete against other players and get more coins than them, be sure to check your ranking on the online leaderboards: just press the OpenFeint button at any time! This is also the way to access the list of achievements and see your actual progress - do you think you have what is needed to unlock all the items?!",
		@"CLUB ➔",
		100,
		3,
		1
	},

	// VERSION_CLUB
	{
		{0.05f, 0.1f, 0.2f, 1.0f},
		{0.6f, 0.9f, 1.0f, 1.0f},
		{0.5f, 0.5f, 1.0f},
		@"Insert 10 coins to start playing. Tap the STOP button to attempt stopping the timer precisely at 1000; you will get your 10 coins back if you miss the target but stop between 995 and 1005, or 200 coins if you succeed to stop on 1000!\n\nIf not playing, dare to tap the label \"V.I.P.\" which will lead you to the Enlightened Timer!\n\nOh, by the way, have you checked the list of achievements and the online leaderboards? Don't be shy, tap the OpenFeint button!",
		@"V.I.P. ➔",
		200,
		10,
		10
	},

	// VERSION_VIP
	{
		{0.1f, 0.1f, 0.1f, 1.0f},
		{1.0f, 1.0f, 1.0f, 1.0f},
		{0.5f, 0.5f, 0.5f},
		@"Dare to insert 100 coins to start playing. Tap the STOP button to attempt stopping the timer precisely at 1000; you will be awarded just 50 coins if you miss the target but stop between 995 and 1005, but 1000 coins if you succeed to stop on 1000!\n\nWhen not playing, simply tap the label \"MALL\" to go back to the less risky Flamin Timer...",
		@"MALL ➔",
		1000,
		50,
		100
	},
};

static NSString const*const ratingKey = @"RATING";
static NSInteger const ratingThreshold = 10;

static unsigned int achievementCountAnyPrize = 0;
static unsigned int achievementCountMajorPrize = 0;

- (unsigned int)frameRate
{
	return screenFrameRate;
}

- (NSString*)title
{
	return @"FLAMIN\nTIMER";
}

- (NSString*)helpText
{
	return settings[version].helpText;
}

- (id)initWithFrame:(CGRect)frame withMaster:(Master*)_master
{
	if(self = [super initWithFrame:frame])
	{
		// Take note of the master
		master = _master;

		// Create a color space to define gradients and fill colors
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

		// Define the background and coin slot gradients
		gradientBackground = CGGradientCreateWithColorComponents(colorSpace, colorsBackground, NULL, 3);
		gradientCoinSlot = CGGradientCreateWithColorComponents(colorSpace, colorsCoinSlot, NULL, 3);

		// Create the segment images
		if(UIGraphicsBeginImageContextWithOptions)
		{
			UIGraphicsBeginImageContextWithOptions(CGSizeMake(digitLength, digitWidth), NO, 0.0f);
		}
		else
		{
			UIGraphicsBeginImageContext(CGSizeMake(digitLength, digitWidth));
		}
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextTranslateCTM(context, digitLength / 2, digitWidth / 2);
		CGContextSetFillColorSpace(context, colorSpace);
		CGContextSetFillColor(context, settings[version].colorsSegmentOff);
		CGContextAddLines(context, segmentPoints, 6);
		CGContextFillPath(context);
		segmentOff = [UIGraphicsGetImageFromCurrentImageContext() retain];
		CGContextClearRect(context, CGRectInfinite);
		CGContextSetFillColor(context, settings[version].colorsSegmentOn);
		CGContextAddLines(context, segmentPoints, 6);
		CGContextFillPath(context);
		UIImage* segmentOnImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		// Release the color space
		CGColorSpaceRelease(colorSpace);

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
		labelStopMajor = [[Label alloc] initWithFrame:CGRectMake(labelMajorCornerX, labelMajorCornerY, labelMajorWidth, labelTopHeight) withSize:labelTopHeight * 0.7f withColor:[UIColor blueColor]];
		labelStopMajor.text = @"STOP ON 1000: MAJOR PRIZE";
		labelStopMajor.textAlignment = UITextAlignmentCenter;
		[self addSubview:labelStopMajor];
		[labelStopMajor release];

		labelStop100Coins = [[Label alloc] initWithFrame:CGRectMake(label100CoinsCornerX, label100CoinsCornerY, label100CoinsWidth, labelTopHeight) withSize:labelTopHeight * 0.7f withColor:[UIColor purpleColor]];
		labelStop100Coins.text = [NSString stringWithFormat:@">>> %d COIN%@ <<<", settings[version].coinsMajorPrize, settings[version].coinsMajorPrize > 1 ? @"S" : @""];
		labelStop100Coins.textAlignment = UITextAlignmentCenter;
		[self addSubview:labelStop100Coins];
		[labelStop100Coins release];

		labelStop3Coins = [[Label alloc] initWithFrame:CGRectMake(label3CoinsCornerX, label3CoinsCornerY, label3CoinsWidth, labelBottomHeight) withSize:labelBottomHeight * 0.7f withColor:[UIColor purpleColor]];
		labelStop3Coins.text = [NSString stringWithFormat:@">>> %d COIN%@ <<<", settings[version].coinsMinorPrize, settings[version].coinsMinorPrize > 1 ? @"S" : @""];
		labelStop3Coins.textAlignment = UITextAlignmentCenter;
		[self addSubview:labelStop3Coins];
		[labelStop3Coins release];

		labelStopMinor = [[Label alloc] initWithFrame:CGRectMake(labelMinorCornerX, labelMinorCornerY, labelMinorWidth, labelBottomHeight) withSize:labelBottomHeight * 0.7f withColor:[UIColor blueColor]];
		labelStopMinor.text = @"STOP ON 995 TO 1005: MINOR PRIZE";
		labelStopMinor.textAlignment = UITextAlignmentCenter;
		[self addSubview:labelStopMinor];
		[labelStopMinor release];

		labelInsertCoin = [[Label alloc] initWithFrame:CGRectMake(coinSlotLabelX, coinSlotLabelY, coinSlotLabelWidth, coinSlotLabelHeight) withSize:labelBottomHeight * 0.7f withColor:[UIColor blueColor]];
		labelInsertCoin.text = [NSString stringWithFormat:@"INSERT\n%d COIN%@", settings[version].coinsPlay, settings[version].coinsPlay > 1 ? @"S" : @""];
		labelInsertCoin.textAlignment = UITextAlignmentCenter;
		labelInsertCoin.numberOfLines = 0;
		[self addSubview:labelInsertCoin];
		[labelInsertCoin release];

		// Define the buttons
		buttonStop = [[Button alloc] initWithColor:[UIColor colorWithRed:settings[version].colorsStopButton[0] green:settings[version].colorsStopButton[1] blue:settings[version].colorsStopButton[2] alpha:1.0f] withText:@"STOP" withFontSize:buttonStopRadius * 2 / 3 inRectangle:CGRectMake(buttonStopCornerX, buttonStopCornerY, buttonStopRadius * 2, buttonStopRadius * 2) withTarget:self withSelector:@selector(buttonPressed:)];
		[self addSubview:buttonStop];
		[buttonStop release];

		buttonPrize = [[Button alloc] initWithColor:[UIColor greenColor] withText:@"GET\nPRIZE" withFontSize:buttonPrizeHeight / 3 inRectangle:CGRectMake(areaWidth - buttonPrizeWidth, areaHeight - buttonPrizeHeight, buttonPrizeWidth, buttonPrizeHeight) withTarget:self withSelector:@selector(buttonPressed:)];
		buttonPrize.label.numberOfLines = 0;
		[self addSubview:buttonPrize];
		[buttonPrize release];

		// Define a special button to swap between versions
		buttonSwap = [UIButton buttonWithType:UIButtonTypeCustom];
		[buttonSwap setFrame:CGRectMake(labelSwapCornerX, labelSwapCornerY, labelSwapWidth, labelSwapHeight)];
		[buttonSwap setTitle:settings[version].labelSwap forState:UIControlStateNormal];
		[buttonSwap setTitleColor:[UIColor colorWithWhite:0.5f alpha:0.2f] forState:UIControlStateNormal];
		buttonSwap.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
		buttonSwap.titleLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:labelSwapHeight * 0.9f];
		[buttonSwap addTarget:self action:@selector(changeVersion) forControlEvents:UIControlEventTouchDown];
		[self addSubview:buttonSwap];

		// Initialize the sound system
		Sound const*const sound = [Sound sharedInstance];
		[sound loadSoundNamed:@"Alarm" withFileNamed:@"EffectAlarm" withLoopFlag:YES];
		[sound loadSoundNamed:@"Lose" withFileNamed:@"EffectLose" withLoopFlag:NO];
		[sound loadSoundNamed:@"Stop" withFileNamed:@"EffectDing" withLoopFlag:NO];

		// Set the initial state of the game
		statePrevious = TIME_BUSTER_LOADING;
		stateCurrent = TIME_BUSTER_LOADING;
		stateNext = TIME_BUSTER_WAIT;
		music = rand();
	}
	return self;
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

	CGContextSetLineWidth(context, coinSlotWidth);
	CGContextSetLineCap(context, kCGLineCapRound);
	CGContextMoveToPoint(context, coinSlotCenterX, coinSlotCenterY - coinSlotRadius * 0.6f);
	CGContextAddLineToPoint(context, coinSlotCenterX, coinSlotCenterY + coinSlotRadius * 0.6f);
	CGContextStrokePath(context);
}

- (void)update
{
	// Check whether there is a change of state
	if(stateCurrent != stateNext)
	{
		// Exit the current state
		statePrevious = stateCurrent;
		switch(stateCurrent)
		{
			case TIME_BUSTER_WAIT:
			{
				// Set the button
				buttonSwap.alpha = 1.0f;
				break;
			}
			case TIME_BUSTER_MINOR_PRIZE:
			case TIME_BUSTER_MAJOR_PRIZE:
			{
				// Stop the alarm sound effect
				[[Sound sharedInstance] stopSoundNamed:@"Alarm"];
				break;
			}
		}

		// Reset the frame counter
		frameCounter = 0;

		// Enter the new state
		stateCurrent = stateNext;
		switch(stateCurrent)
		{
			case TIME_BUSTER_WAIT:
			{
				// Launch the music
				[[Sound sharedInstance] playMusicNamed:@"MusicMenu" withLoopFlag:YES];

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
				// Launch the music
				[[Sound sharedInstance] playMusicNamed:[NSString stringWithFormat:@"MusicPlay%d", ++music & 3] withLoopFlag:YES];

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
				// Stop the music
				[[Sound sharedInstance] stopMusic];

				// Play the sound effect
				[[Sound sharedInstance] playSoundNamed:@"Lose"];

				// Set the labels
				labelStopMajor.glow = NO;
				labelStop100Coins.glow = NO;
				labelStop3Coins.glow = NO;
				labelStopMinor.glow = NO;
				labelInsertCoin.glow = NO;

				// Set the buttons
				buttonStop.label.glow = NO;
				buttonPrize.label.glow = NO;

				// Reset the counts of prizes won in a row
				achievementCountAnyPrize = 0;
				achievementCountMajorPrize = 0;
				break;
			}
			case TIME_BUSTER_MINOR_PRIZE:
			{
				// Launch the alarm sound effect
				[[Sound sharedInstance] playSoundNamed:@"Alarm"];

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
				// Launch the alarm sound effect
				[[Sound sharedInstance] playSoundNamed:@"Alarm"];

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

	// Execute the current state
	unsigned char const* segmentConvert;
	switch(stateCurrent)
	{
		case TIME_BUSTER_WAIT:
		{
			// Update the label
			labelInsertCoin.glow = frameCounter & 32;

			// Update the button
			buttonSwap.alpha = frameCounter & (256 - 8 * 3) ? 1.0f : 0.1f;

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
				// Unlock achievements
				[[OFAchievement achievement:openFeintAchievementIdSleepy] updateProgressionComplete:100.0 andShowNotification:YES];

				// Game is over
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
			// Play the sound effect
			[[Sound sharedInstance] playSoundNamed:@"Stop"];

			// Stop the timer
			unsigned int const digits = timer;
			if(digits == 1000)
			{
				// Let's award a major prize
				stateNext = TIME_BUSTER_MAJOR_PRIZE;
			}
			else if(digits >= 995 && digits <= 1005)
			{
				// Let's award a minor prize
				stateNext = TIME_BUSTER_MINOR_PRIZE;
			}
			else
			{
				// Unlock achievements
				if(digits < 100)
				{
					[[OFAchievement achievement:openFeintAchievementIdSpeedy] updateProgressionComplete:100.0 andShowNotification:YES];
				}

				// Game is over
				stateNext = TIME_BUSTER_FAILED;
			}
		}
	}
	else if(sender == buttonPrize)
	{
		if(stateCurrent == TIME_BUSTER_MAJOR_PRIZE || stateCurrent == TIME_BUSTER_MINOR_PRIZE)
		{
			// Check which prize shall be awarded
			NSInteger coins;
			if(stateCurrent == TIME_BUSTER_MAJOR_PRIZE)
			{
				// Get the prize
				coins = [master addCoins:settings[version].coinsMajorPrize];

				// Unlock achievements
				[[OFAchievement achievement:openFeintAchievementIdWinner] updateProgressionComplete:100.0 andShowNotification:YES];

				// Unlock other achievements
				++achievementCountMajorPrize;
				if(achievementCountMajorPrize >= 3)
				{
					[[OFAchievement achievement:openFeintAchievementIdGodOfTime] updateProgressionComplete:100.0 andShowNotification:YES];
				}
				else if(achievementCountMajorPrize >= 2)
				{
					[[OFAchievement achievement:openFeintAchievementIdTimeMaster] updateProgressionComplete:100.0 andShowNotification:YES];
				}
			}
			else
			{
				// Get the prize
				coins = [master addCoins:settings[version].coinsMinorPrize];

				// Unlock achievements
				[[OFAchievement achievement:openFeintAchievementIdFirstStep] updateProgressionComplete:100.0 andShowNotification:YES];

				// Reset the count of major prizes won in a row
				achievementCountMajorPrize = 0;
			}

			// Update the leaderboard
			[OFHighScoreService setHighScore:coins forLeaderboard:openFeintLeaderboardIdCoinBuckets onSuccess:OFDelegate() onFailure:OFDelegate()];

			// Unlock some more achievements
			if(coins >= 5000)
			{
				[[OFAchievement achievement:openFeintAchievementIdParadise] updateProgressionComplete:100.0 andShowNotification:YES];
			}
			else if(coins >= 1000)
			{
				[[OFAchievement achievement:openFeintAchievementIdOpulence] updateProgressionComplete:100.0 andShowNotification:YES];
			}
			else if(coins >= 500)
			{
				[[OFAchievement achievement:openFeintAchievementIdNiceBonus] updateProgressionComplete:100.0 andShowNotification:YES];
			}
			else if(coins >= 100)
			{
				[[OFAchievement achievement:openFeintAchievementIdPocketMoney] updateProgressionComplete:100.0 andShowNotification:YES];
			}

			// Unlock even more achievements
			++achievementCountAnyPrize;
			if(achievementCountAnyPrize >= 50)
			{
				[[OFAchievement achievement:openFeintAchievementIdCheater] updateProgressionComplete:100.0 andShowNotification:YES];
			}
			else if(achievementCountAnyPrize >= 20)
			{
				[[OFAchievement achievement:openFeintAchievementIdJustGood] updateProgressionComplete:100.0 andShowNotification:YES];
			}
			else if(achievementCountAnyPrize >= 10)
			{
				[[OFAchievement achievement:openFeintAchievementIdRegular] updateProgressionComplete:100.0 andShowNotification:YES];
			}

			// Go back to the wait state
			stateNext = TIME_BUSTER_WAIT;

			// Display the rating alert message when it is appropriate
			NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
			NSInteger const ratingCount = [userDefaults integerForKey:ratingKey];
			if(ratingCount < ratingThreshold)
			{
				[userDefaults setInteger:(ratingCount + 1) forKey:ratingKey];
			}
			else if(ratingCount == ratingThreshold && coins >= 200)
			{
				ratingView = [[UIAlertView alloc] initWithTitle:@"Support Flamin Timer!" message:@"Congratulations! You have got a lot of coins already! Would you please rate the game on the App Store?" delegate:self cancelButtonTitle:@"No way!" otherButtonTitles:@"Yes, sure!", nil];
				[ratingView show];
				[ratingView release];
			}
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
			// Insert some coins
			NSInteger const games = [master playGameWithCoins:settings[version].coinsPlay];

			// Update the leaderboard
			[OFHighScoreService setHighScore:games forLeaderboard:openFeintLeaderboardIdPlayedGames silently:YES onSuccess:OFDelegate() onFailure:OFDelegate()];

			// Unlock achievements
			if(games >= 1000)
			{
				[[OFAchievement achievement:openFeintAchievementIdCrazyGambler] updateProgressionComplete:100.0 andShowNotification:YES];
			}
			else if(games >= 500)
			{
				[[OFAchievement achievement:openFeintAchievementIdAddicterGambler] updateProgressionComplete:100.0 andShowNotification:YES];
			}
			else if(games >= 100)
			{
				[[OFAchievement achievement:openFeintAchievementIdSeriousGambler] updateProgressionComplete:100.0 andShowNotification:YES];
			}
			else if(games >= 50)
			{
				[[OFAchievement achievement:openFeintAchievementIdLittleGambler] updateProgressionComplete:100.0 andShowNotification:YES];
			}

			// Start the game
			stateNext = TIME_BUSTER_RUN;
		}
	}
}

- (void)changeToUser:(NSString*)userId
{
	achievementCountAnyPrize = 0;
	achievementCountMajorPrize = 0;
}

- (void)changeVersion
{
	if(stateCurrent == TIME_BUSTER_WAIT)
	{
		if(version == VERSION_MALL)
		{
			version = VERSION_CLUB;
		}
		else if(version == VERSION_CLUB)
		{
			version = VERSION_VIP;
		}
		else
		{
			version = VERSION_MALL;
		}
		[master restartSlave];
	}
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(alertView == ratingView)
	{
		ratingView = nil;

		NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setInteger:(ratingThreshold + 1) forKey:ratingKey];
		[userDefaults synchronize];

		if(buttonIndex == 1)
		{
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id="
#ifdef FLAMIN_GIANT
														@"418154640"
#else
														@"402458425"
#endif
														]];
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
