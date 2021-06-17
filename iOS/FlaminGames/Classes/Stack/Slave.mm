#import "Sound.h"
#import "Slave.h"
#import "Master.h"
#import "Label.h"
#import "Button.h"
#import "OFAchievement.h"
#import "OFHighScoreService.h"
#import "OpenFeintLocalSettings.h"

#define screenFrameRate 60

#define areaWidth  screenWidth
#define areaHeight (screenHeight - topBarHeight)

#ifdef FLAMIN_GIANT
	#define coinBarWidth      240.0f
	#define coinBarFontSize   35.0f
	#define coinBarButtonSize 50.0f
#else
	#define coinBarWidth      80.0f
	#define coinBarFontSize   14.0f
	#define coinBarButtonSize 20.0f
#endif

#define buttonBarGap    5.0f
#define buttonBarHeight topBarHeight
#define buttonWidth     ((areaWidth - 2 * buttonBarGap) / 3)

#define containerThickness 5.0f
#define containerMaxWidth  (areaWidth - containerThickness - coinBarWidth)
#define containerMaxHeight (areaHeight - containerThickness - 2 * buttonBarGap - buttonBarHeight)

#define blockMaxWidth  ((containerMaxWidth - containerThickness) / 7)
#define blockMaxHeight ((containerMaxHeight - containerThickness) / 12)
#define blockSize      (blockMaxWidth < blockMaxHeight ? blockMaxWidth : blockMaxHeight)

#define containerWidth   (blockSize * 7 + containerThickness)
#define containerHeight  (blockSize * 12 + containerThickness)
#define containerOriginX ((containerThickness + containerMaxWidth - containerWidth) / 2)
#define containerOriginY (buttonBarGap + ((containerThickness + containerMaxHeight - containerHeight) / 2))

#define blockOriginX (containerOriginX + containerThickness / 2)
#define blockOriginY (containerOriginY + containerThickness / 2)

#define coinSlotCenterX   (areaWidth - coinBarWidth / 2)
#define coinSlotCenterY   (blockOriginY + blockSize * 10)
#define coinSlotThickness 4.0f
#ifdef FLAMIN_GIANT
	#define coinSlotWidth 16.0f
#else
	#define coinSlotWidth 8.0f
#endif

@implementation Slave

static CGFloat const colorsBackground[12] = {0.0f, 0.0f, 0.0f, 1.0f, 0.3f, 0.3f, 0.5f, 1.0f, 0.1f, 0.1f, 0.1f, 1.0f};
static CGFloat const colorsCoinSlot[12] = {0.2f, 0.2f, 0.2f, 1.0f, 0.4f, 0.4f, 0.4f, 1.0f, 0.3f, 0.3f, 0.3f, 1.0f};

static enum {VERSION_MALL = 0, VERSION_CLUB, VERSION_VIP, VERSION_COUNT} version = VERSION_MALL;

static struct
{
	CGFloat colorsBlockLedOff[8];
	CGFloat colorsBlockLedOn[8];
	CGFloat colorsStackButton[3];
	NSString* helpText;
	NSString* labelSwap;
	NSString* message;
	NSInteger coins12thRow;
	NSInteger coins9thRow;
	NSInteger coinsPlay;
}
const settings[VERSION_COUNT] =
{
	// VERSION_MALL
	{
		{0.4f, 0.1f, 0.2f, 1.0f, 0.2f, 0.0f, 0.1f, 1.0f},
		{1.0f, 0.2f, 0.5f, 1.0f, 0.2f, 0.0f, 0.1f, 1.0f},
		{1.0f, 0.0f, 0.0f},
		@"WELCOME TO\nFLAMIN STACK!\n\nFirst, insert a coin to start playing. Tap the STACK button to stop the blocks and build your stack; you will be awarded 3 coins if you stop at the 9th row, or 100 coins if you succeed to reach the 12th row!\n\nWhen not playing, you can tap the label \"CLUB\" to go try the Frozen Stack!\n\nAnd if you feel like you can compete against other players and get more coins than them, be sure to check your ranking on the online leaderboards: just press the OpenFeint button at any time! This is also the way to access the list of achievements and see your actual progress - do you think you have what is needed to unlock all the items?!",
		@"CLUB ➔",
		@"MessageMall.png",
		100,
		3,
		1
	},

	// VERSION_CLUB
	{
		{0.1f, 0.2f, 0.5f, 1.0f, 0.1f, 0.2f, 0.3f, 1.0f},
		{0.6f, 0.9f, 1.0f, 1.0f, 0.1f, 0.4f, 0.6f, 1.0f},
		{0.5f, 0.5f, 1.0f},
		@"Insert 10 coins to start playing. Tap the STACK button to stop the blocks and build your stack; you will get your 10 coins back if you stop at the 9th row, or get 200 coins if you succeed to reach the 12th row!\n\nIf not playing, dare to tap the label \"V.I.P.\" which will lead you to the Enlightened Stack!\n\nOh, by the way, have you checked the list of achievements and the online leaderboards? Don't be shy, tap the OpenFeint button!",
		@"V.I.P. ➔",
		@"MessageClub.png",
		200,
		10,
		10
	},

	// VERSION_VIP
	{
		{0.2f, 0.2f, 0.2f, 1.0f, 0.1f, 0.1f, 0.1f, 1.0f},
		{1.0f, 1.0f, 1.0f, 1.0f, 0.3f, 0.3f, 0.2f, 1.0f},
		{0.5f, 0.5f, 0.5f},
		@"Dare to insert 100 coins to start playing. Tap the STACK button to stop the blocks and build your stack; you will be awarded just 1 coin if you stop at the 9th row, but 500 coins if you succeed to reach the 12th row!\n\nWhen not playing, simply tap the label \"MALL\" to go back to the less risky Flamin Stack...",
		@"MALL ➔",
		@"MessageVip.png",
		500,
		1,
		100
	},
};

static NSString const*const ratingKey = @"RATING";
static NSInteger const ratingThreshold = 10;

static unsigned int achievementCountAnyPrize = 0;
static unsigned int achievementCountMajorPrize = 0;
static unsigned int achievementCountLost = 0;

- (unsigned int)frameRate
{
	return screenFrameRate;
}

- (NSString*)title
{
	return @"FLAMIN\nSTACK";
}

- (NSString*)helpText
{
	return settings[version].helpText;
}

- (UIImage*)createWinnerRowWithLabel:(NSString*)label
{
	// Define the image context
	if(UIGraphicsBeginImageContextWithOptions)
	{
		UIGraphicsBeginImageContextWithOptions(CGSizeMake(blockSize * 7, blockSize), NO, 0.0f);
	}
	else
	{
		UIGraphicsBeginImageContext(CGSizeMake(blockSize * 7, blockSize));
	}
	CGContextRef const context = UIGraphicsGetCurrentContext();

	// Draw the dashed rectangle
	static CGFloat const dash[] = {blockSize / 6, blockSize / 6};
	CGContextSetLineDash(context, 0.0, dash, 2);
	CGContextSetRGBStrokeColor(context, 1.0f, 1.0f, 1.0f, 0.4f);
	CGContextAddRect(context, CGRectMake(0.0f, 0.0f, blockSize * 7, blockSize));
	CGContextStrokePath(context);

	// Draw the text
	CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 0.4f);
	UIFont *const font = [UIFont fontWithName:@"Arial" size:blockSize / 2];
	CGSize const size = [label sizeWithFont:font];
	[label drawAtPoint:CGPointMake((blockSize * 7 - size.width) / 2, (blockSize - size.height) / 2) withFont:font];

	// Return the image
	UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

- (id)initWithFrame:(CGRect)frame withMaster:(Master*)_master
{
	if(self = [super initWithFrame:frame])
	{
		// Take note of the master
		master = _master;

		// Create a color space to define gradients
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

		// Define the background and coin slot gradients
		gradientBackground = CGGradientCreateWithColorComponents(colorSpace, colorsBackground, NULL, 3);
		gradientCoinSlot = CGGradientCreateWithColorComponents(colorSpace, colorsCoinSlot, NULL, 3);

		// Define the LED blocks
		if(UIGraphicsBeginImageContextWithOptions)
		{
			UIGraphicsBeginImageContextWithOptions(CGSizeMake(blockSize, blockSize), YES, 0.0f);
		}
		else
		{
			UIGraphicsBeginImageContext(CGSizeMake(blockSize, blockSize));
		}
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGPoint center = CGPointMake(blockSize / 2, blockSize / 2);

		CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, settings[version].colorsBlockLedOff, NULL, 2);
		CGContextDrawRadialGradient(context, gradient, center, blockSize / 4, center, blockSize * M_SQRT1_2, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
		UIImage* blockLedOffImage = UIGraphicsGetImageFromCurrentImageContext();
		CGGradientRelease(gradient);

		CGContextClearRect(context, CGRectInfinite);

		gradient = CGGradientCreateWithColorComponents(colorSpace, settings[version].colorsBlockLedOn, NULL, 2);
		CGContextDrawRadialGradient(context, gradient, center, blockSize / 4, center, blockSize * M_SQRT1_2, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
		blockLedOn = [UIGraphicsGetImageFromCurrentImageContext() retain];
		CGGradientRelease(gradient);

		UIGraphicsEndImageContext();

		// Release the color space
		CGColorSpaceRelease(colorSpace);

		// Define the game area
		center.y = blockOriginY + blockSize / 2;
		for(unsigned int y = 0; y < 12; ++y)
		{
			blockRowState[y] = 0;
			center.x = blockOriginX + blockSize / 2;
			for(unsigned int x = 0; x < 7; ++x)
			{
				blockLedOff[x][y] = [[UIImageView alloc] initWithImage:blockLedOffImage];
				blockLedOff[x][y].center = center;
				[self addSubview:blockLedOff[x][y]];
				[blockLedOff[x][y] release];
				center.x += blockSize;
			}
			center.y += blockSize;
		}

		// Define the winner row markers
		UIImage* winnerRowMarkerImage = [self createWinnerRowWithLabel:@"MAJOR PRIZE"];
		UIImageView* winnerRowMarkerView = [[UIImageView alloc] initWithImage:winnerRowMarkerImage];
		winnerRowMarkerView.center = CGPointMake(blockOriginX + winnerRowMarkerImage.size.width / 2, blockOriginY + winnerRowMarkerImage.size.height / 2);
		[self addSubview:winnerRowMarkerView];
		[winnerRowMarkerView release];

		winnerRowMarkerImage = [self createWinnerRowWithLabel:@"MINOR PRIZE"];
		winnerRowMarkerView = [[UIImageView alloc] initWithImage:winnerRowMarkerImage];
		winnerRowMarkerView.center = CGPointMake(blockOriginX + winnerRowMarkerImage.size.width / 2, blockOriginY + blockSize * 3 + winnerRowMarkerImage.size.height / 2);;
		[self addSubview:winnerRowMarkerView];
		[winnerRowMarkerView release];

		// Define the labels
		label12thRow = [[Label alloc] initWithFrame:CGRectMake(areaWidth - coinBarWidth, blockOriginY, coinBarWidth, blockSize) withSize:coinBarFontSize withColor:[UIColor yellowColor]];
		label12thRow.text = [NSString stringWithFormat:@"%d COIN%@", settings[version].coins12thRow, settings[version].coins12thRow > 1 ? @"S" : @""];
		[self addSubview:label12thRow];
		[label12thRow release];

		label9thRow = [[Label alloc] initWithFrame:CGRectMake(areaWidth - coinBarWidth, blockOriginY + blockSize * 3, coinBarWidth, blockSize) withSize:coinBarFontSize withColor:[UIColor greenColor]];
		label9thRow.text = [NSString stringWithFormat:@"%d COIN%@", settings[version].coins9thRow, settings[version].coins9thRow > 1 ? @"S" : @""];
		[self addSubview:label9thRow];
		[label9thRow release];

		labelInsertCoin = [[Label alloc] initWithFrame:CGRectMake(areaWidth - coinBarWidth, coinSlotCenterY - blockSize * 3, coinBarWidth, blockSize * 2) withSize:coinBarFontSize withColor:[UIColor redColor]];
		labelInsertCoin.text = [NSString stringWithFormat:@"INSERT\n%d COIN%@", settings[version].coinsPlay, settings[version].coinsPlay > 1 ? @"S" : @""];
		labelInsertCoin.textAlignment = UITextAlignmentCenter;
		labelInsertCoin.numberOfLines = 0;
		[self addSubview:labelInsertCoin];
		[labelInsertCoin release];

		// Define the buttons
		buttonContinue = [[Button alloc] initWithColor:[UIColor yellowColor] withText:@"CONTINUE" withFontSize:buttonBarHeight / 3 inRectangle:CGRectMake(0.0f, areaHeight - buttonBarHeight, buttonWidth, buttonBarHeight) withTarget:self withSelector:@selector(buttonPressed:)];
		[self addSubview:buttonContinue];
		[buttonContinue release];

		buttonStack = [[Button alloc] initWithColor:[UIColor colorWithRed:settings[version].colorsStackButton[0] green:settings[version].colorsStackButton[1] blue:settings[version].colorsStackButton[2] alpha:1.0f] withText:@"STACK" withFontSize:buttonBarHeight / 2 inRectangle:CGRectMake(buttonWidth + buttonBarGap, areaHeight - buttonBarHeight, buttonWidth, buttonBarHeight) withTarget:self withSelector:@selector(buttonPressed:)];
		[self addSubview:buttonStack];
		[buttonStack release];

		buttonGetPrize = [[Button alloc] initWithColor:[UIColor greenColor] withText:@"GET PRIZE" withFontSize:buttonBarHeight / 3 inRectangle:CGRectMake(areaWidth - buttonWidth, areaHeight - buttonBarHeight, buttonWidth, buttonBarHeight) withTarget:self withSelector:@selector(buttonPressed:)];
		[self addSubview:buttonGetPrize];
		[buttonGetPrize release];

		// Define a special button to swap between versions
		buttonSwap = [UIButton buttonWithType:UIButtonTypeCustom];
		[buttonSwap setFrame:CGRectMake(areaWidth - coinBarWidth, blockOriginY + blockSize * 5, coinBarWidth, blockSize * 2)];
		[buttonSwap setTitle:settings[version].labelSwap forState:UIControlStateNormal];
		[buttonSwap setTitleColor:[UIColor colorWithWhite:0.5f alpha:0.2f] forState:UIControlStateNormal];
		buttonSwap.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
		buttonSwap.titleLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:coinBarButtonSize];
		[buttonSwap addTarget:self action:@selector(changeVersion) forControlEvents:UIControlEventTouchDown];
		[self addSubview:buttonSwap];

		// Initialize the message
		CGImageRef const message = [[UIImage imageNamed:settings[version].message] CGImage];
		unsigned int const messageWidth = CGImageGetWidth(message);
		messageHeight = CGImageGetHeight(message);
		messageBytes = (unsigned char*)malloc(messageHeight);

		unsigned char *const pixels = (unsigned char*)malloc(messageWidth * messageHeight);
		colorSpace = CGColorSpaceCreateDeviceGray();
		context = CGBitmapContextCreate(pixels, messageWidth, messageHeight, 8, messageWidth, colorSpace, kCGImageAlphaNone);
		CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, messageWidth, messageHeight), message);

		unsigned int byteIndex = 0;
		unsigned int pixelIndex = 0;
		for(unsigned int row = 0; row < messageHeight; ++row)
		{
			messageBytes[byteIndex] = 0;
			for(unsigned int column = 0; column < 7; ++column)
			{
				if(pixels[pixelIndex])
				{
					messageBytes[byteIndex] |= 1 << column;
				}
				++pixelIndex;
			}
			++byteIndex;
			pixelIndex += messageWidth - 7;
		}

		CGContextRelease(context);
		CGColorSpaceRelease(colorSpace);
		free(pixels);

		// Initialize the sound system
		Sound const*const sound = [Sound sharedInstance];
		[sound loadSoundNamed:@"Alarm" withFileNamed:@"EffectAlarm" withLoopFlag:YES];
		[sound loadSoundNamed:@"Lose" withFileNamed:@"EffectLose" withLoopFlag:NO];
		[sound loadSoundNamed:@"Stack0" withFileNamed:@"EffectDing" withLoopFlag:NO];
		[sound loadSoundNamed:@"Stack1" withFileNamed:@"EffectDing" withLoopFlag:NO];
		[sound loadSoundNamed:@"Stack2" withFileNamed:@"EffectDing" withLoopFlag:NO];
		[sound loadSoundNamed:@"Stack3" withFileNamed:@"EffectDing" withLoopFlag:NO];

		// Set the initial state of the game
		blockGameStatePrevious = STATE_LOADING;
		blockGameStateCurrent = STATE_LOADING;
		blockGameStateNext = STATE_TITLE;
		blockMusic = rand();
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Display the background
	CGContextDrawLinearGradient(context, gradientBackground, CGPointZero, CGPointMake(0.0f, areaHeight), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);

	// Display the game area
	CGPoint point;
	point.y = blockOriginY;
	for(unsigned int y = 0; y < 12; ++y)
	{
		point.x = blockOriginX;
		for(unsigned int x = 0; x < 7; ++x)
		{
			[blockLedOn drawAtPoint:point];
			point.x += blockSize;
		}
		point.y += blockSize;
	}

	// Display the container
	CGContextSetLineWidth(context, containerThickness);
	CGContextSetRGBStrokeColor(context, 0.1f, 0.1f, 0.1f, 1.0f);
	CGContextAddRect(context, CGRectMake(containerOriginX, containerOriginY, containerWidth, containerHeight));
	CGContextStrokePath(context);

	// Display the coin slot
	CGContextSaveGState(context);
	CGContextAddArc(context, coinSlotCenterX, coinSlotCenterY, blockSize, 0.0f, 2 * M_PI, 0);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, gradientCoinSlot, CGPointMake(0.0f, coinSlotCenterY - blockSize), CGPointMake(0.0f, coinSlotCenterY + blockSize), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);
	CGContextSetLineWidth(context, coinSlotThickness);
	CGContextAddArc(context, coinSlotCenterX, coinSlotCenterY, blockSize, 0.0f, 2 * M_PI, 0);
	CGContextStrokePath(context);

	CGContextSetLineWidth(context, coinSlotWidth);
	CGContextSetLineCap(context, kCGLineCapRound);
	CGContextMoveToPoint(context, coinSlotCenterX, coinSlotCenterY - blockSize * 0.6f);
	CGContextAddLineToPoint(context, coinSlotCenterX, coinSlotCenterY + blockSize * 0.6f);
	CGContextStrokePath(context);
}

- (void)update
{
	// Check whether there is a change of state
	if(blockGameStateCurrent != blockGameStateNext)
	{
		// Exit the current state
		blockGameStatePrevious = blockGameStateCurrent;
		switch(blockGameStateCurrent)
		{
			case STATE_TITLE:
			{
				// Set the label
				labelInsertCoin.glow = NO;

				// Set the button
				buttonSwap.alpha = 1.0f;

				// Launch the music
				[[Sound sharedInstance] playMusicNamed:[NSString stringWithFormat:@"MusicPlay%d", ++blockMusic & 3] withLoopFlag:YES];
				break;
			}
			case STATE_MOVE:
			case STATE_STACK:
			case STATE_FAILED:
			{
				break;
			}
			case STATE_9TH_ROW:
			case STATE_12TH_ROW:
			{
				// Stop the alarm sound effect
				[[Sound sharedInstance] stopSoundNamed:@"Alarm"];
				break;
			}
		}

		// Enter the new state
		blockGameStateCurrent = blockGameStateNext;
		switch(blockGameStateCurrent)
		{
			case STATE_TITLE:
			{
				// Launch the music
				[[Sound sharedInstance] playMusicNamed:@"MusicMenu" withLoopFlag:YES];

				// Set the labels
				label12thRow.glow = NO;
				label9thRow.glow = NO;

				// Set the buttons
				buttonContinue.label.glow = NO;
				buttonStack.label.glow = NO;
				buttonGetPrize.label.glow = NO;

				// Initialize the timer
				blockTimer = 0;
				break;
			}
			case STATE_MOVE:
			{
				// Count the number of blocks in the current row, then move up 1 row
				unsigned char blockCount;
				if(blockRowNumber < 12)
				{
					unsigned char blockRowStateCurrent = blockRowState[blockRowNumber] & 127;
					for(blockCount = 0; blockRowStateCurrent; ++blockCount)
					{
						blockRowStateCurrent &= blockRowStateCurrent - 1;
					}
					--blockRowNumber;
				}
				else
				{
					blockCount = 7;
					blockRowNumber = 11;
				}

				// Compute the maximum number of blocks for the new row
				unsigned char const blockCountMax = (blockRowNumber >> 2) + 1;
				if(blockCount > blockCountMax)
				{
					blockCount = blockCountMax;
				}

				// Set the state of the new row
				if(rand() & 1)
				{
					blockRowState[blockRowNumber] = (1 << blockCount) - 1;
				}
				else
				{
					blockRowState[blockRowNumber] = -(1 << (7 - blockCount));
				}

				// Initialize the timer
				blockTimer = 2 + ((3 * blockRowNumber) >> 2);

				// Set the labels
				label12thRow.glow = blockRowNumber < 3;
				label9thRow.glow = blockRowNumber >= 3;

				// Set the buttons
				buttonContinue.label.glow = NO;
				buttonStack.label.glow = YES;
				buttonGetPrize.label.glow = NO;
				break;
			}
			case STATE_STACK:
			{
				// Play the sound effect
				[[Sound sharedInstance] playSoundNamed:[NSString stringWithFormat:@"Stack%d", blockRowNumber & 3]];

				// Check whether the blocks are well aligned
				if(blockRowNumber < 11)
				{
					blockRowError = blockRowState[blockRowNumber] & ~blockRowState[blockRowNumber + 1] & 127;
				}
				else
				{
					blockRowError = 0;
				}
				if(blockRowError)
				{
					// Set the timer
					blockTimer = screenFrameRate * 2;

					// Set the buttons
					buttonContinue.label.glow = NO;
					buttonStack.label.glow = NO;
					buttonGetPrize.label.glow = NO;

					// Check whether the game is over
					if((blockRowState[blockRowNumber] & 127) == blockRowError)
					{
						// Play the sound effect
						[[Sound sharedInstance] playSoundNamed:@"Lose"];
					}
				}
				else
				{
					// Reset the timer
					blockTimer = 0;
				}
				break;
			}
			case STATE_FAILED:
			{
				// Stop the music
				[[Sound sharedInstance] stopMusic];

				// Set the labels
				label12thRow.glow = NO;
				label9thRow.glow = NO;

				// Set the buttons
				buttonContinue.label.glow = NO;
				buttonStack.label.glow = NO;
				buttonGetPrize.label.glow = NO;

				// Unlock achievements
				if(blockRowNumber == 10)
				{
					[[OFAchievement achievement:openFeintAchievementIdLoser] updateProgressionComplete:100.0 andShowNotification:YES];
				}
				if(++achievementCountLost >= 20)
				{
					[[OFAchievement achievement:openFeintAchievementIdNoLuck] updateProgressionComplete:100.0 andShowNotification:YES];
				}

				// Reset the counts of prizes won in a row
				achievementCountAnyPrize = 0;
				achievementCountMajorPrize = 0;
				break;
			}
			case STATE_9TH_ROW:
			{
				// Launch the alarm sound effect
				[[Sound sharedInstance] playSoundNamed:@"Alarm"];

				// Set the label
				label12thRow.glow = YES;

				// Set the buttons
				buttonContinue.label.glow = YES;
				buttonStack.label.glow = NO;
				buttonGetPrize.label.glow = YES;

				// Define a mask to change the state of all the blocks of the current row
				blockRowError = ~blockRowState[blockRowNumber];
				break;
			}
			case STATE_12TH_ROW:
			{
				// Launch the alarm sound effect
				[[Sound sharedInstance] playSoundNamed:@"Alarm"];

				// Set the label
				label9thRow.glow = NO;

				// Set the buttons
				buttonContinue.label.glow = NO;
				buttonStack.label.glow = NO;
				buttonGetPrize.label.glow = YES;

				// Invert the state of the current row
				blockRowState[blockRowNumber] ^= 127;
				break;
			}
		}
	}

	// Execute the current state
	switch(blockGameStateCurrent)
	{
		case STATE_TITLE:
		{
			// Update the label
			labelInsertCoin.glow = blockTimer & 16;

			// Update the button
			buttonSwap.alpha = blockTimer & (128 - 4 * 3) ? 1.0f : 0.1f;

			// Limit the speed
			if(++blockTimer % 3)
			{
				break;
			}

			// Scroll the game area
			unsigned int y;
			for(y = 0; y < 11; ++y)
			{
				blockRowState[y] = blockRowState[y + 1];
			}

			// Display the message, row per row
			blockRowState[y] = messageBytes[(blockTimer / 3) % messageHeight];
			break;
		}
		case STATE_MOVE:
		{
			// Limit the speed
			if(blockTimer)
			{
				--blockTimer;
				break;
			}

			// Move the blocks
			unsigned char blockRowStateCurrent = blockRowState[blockRowNumber];
			if(blockRowStateCurrent & 128)
			{
				blockRowStateCurrent = (blockRowStateCurrent & 127) >> 1;
				if(!(blockRowStateCurrent & 1))
				{
					blockRowStateCurrent |= 128;
				}
			}
			else
			{
				blockRowStateCurrent <<= 1;
				if(blockRowStateCurrent & 64)
				{
					blockRowStateCurrent |= 128;
				}
			}
			blockRowState[blockRowNumber] = blockRowStateCurrent;

			// Rearm the timer
			blockTimer = 2 + ((3 * blockRowNumber) >> 2);
			break;
		}
		case STATE_STACK:
		{
			// Handle the timer
			if(blockTimer)
			{
				// Make the blocks to blink
				if(!(blockTimer & 15))
				{
					blockRowState[blockRowNumber] ^= blockRowError;
				}
				--blockTimer;
				break;
			}

			// Define the next state
			if(!(blockRowState[blockRowNumber] & 127))
			{
				blockGameStateNext = STATE_FAILED;
			}
			else if(blockRowNumber == 0)
			{
				blockGameStateNext = STATE_12TH_ROW;
			}
			else if(blockRowNumber == 3)
			{
				blockGameStateNext = STATE_9TH_ROW;
			}
			else
			{
				blockGameStateNext = STATE_MOVE;
			}
			break;
		}
		case STATE_FAILED:
		{
			// Limit the speed
			if(++blockTimer & 1)
			{
				break;
			}

			// Make all the blocks to fall down (row per row)
			unsigned int y;
			for(y = 11; y > 0; --y)
			{
				if(blockRowState[y] & 127)
				{
					if(y < 11)
					{
						blockRowState[y + 1] = blockRowState[y];
					}
					blockRowState[y] = 0;
					break;
				}
			}

			// Go back to the title once all the blocks disappeared
			if(!y)
			{
				blockGameStateNext = STATE_TITLE;
			}
			break;
		}
		case STATE_9TH_ROW:
		{
			// Update the label
			label9thRow.glow = blockTimer & 16;

			// Make the row to blink
			if(!(++blockTimer & 7))
			{
				blockRowState[blockRowNumber] ^= blockRowError;
			}
			break;
		}
		case STATE_12TH_ROW:
		{
			// Update the label
			label12thRow.glow = blockTimer & 16;

			// Limit the speed
			if(++blockTimer & 1)
			{
				break;
			}

			// Invert the state of each row, one by one
			blockRowState[blockRowNumber] ^= 127;
			if(blockRowNumber < 11)
			{
				++blockRowNumber;
			}
			else
			{
				blockRowNumber = 0;
			}
			blockRowState[blockRowNumber] ^= 127;
			break;
		}
	}

	// Update the game area
	for(unsigned int y = 0; y < 12; ++y)
	{
		unsigned char blockRowStateCurrent = blockRowState[y];
		for(unsigned int x = 0; x < 7; ++x)
		{
			blockLedOff[x][y].hidden = blockRowStateCurrent & 1;
			blockRowStateCurrent >>= 1;
		}
	}
}

- (void)buttonPressed:(id)sender
{
	if(sender == buttonStack)
	{
		if(blockGameStateCurrent == STATE_MOVE)
		{
			// Stack the blocks
			blockGameStateNext = STATE_STACK;
		}
	}
	else if(sender == buttonContinue)
	{
		if(blockGameStateCurrent == STATE_9TH_ROW)
		{
			// Restore the 9th row then continue
			blockRowState[blockRowNumber] &= ~blockRowError;
			blockTimer = 0;
			blockGameStateNext = STATE_MOVE;
		}
	}
	else if(sender == buttonGetPrize)
	{
		if(blockGameStateCurrent == STATE_12TH_ROW || blockGameStateCurrent == STATE_9TH_ROW)
		{
			// Check which prize shall be awarded
			NSInteger coins;
			if(blockGameStateCurrent == STATE_12TH_ROW)
			{
				// Get the prize
				coins = [master addCoins:settings[version].coins12thRow];

				// Unlock achievements
				[[OFAchievement achievement:openFeintAchievementIdWinner] updateProgressionComplete:100.0 andShowNotification:YES];

				// Unlock other achievements
				++achievementCountMajorPrize;
				if(achievementCountMajorPrize >= 3)
				{
					[[OFAchievement achievement:openFeintAchievementIdGodOfStack] updateProgressionComplete:100.0 andShowNotification:YES];
				}
				else if(achievementCountMajorPrize >= 2)
				{
					[[OFAchievement achievement:openFeintAchievementIdStackMaster] updateProgressionComplete:100.0 andShowNotification:YES];
				}
			}
			else
			{
				// Get the prize
				coins = [master addCoins:settings[version].coins9thRow];

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

			// Reset the count of games lost in a row
			achievementCountLost = 0;

			// Go back to the title
			blockGameStateNext = STATE_TITLE;

			// Display the rating alert message when it is appropriate
			NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
			NSInteger const ratingCount = [userDefaults integerForKey:ratingKey];
			if(ratingCount < ratingThreshold)
			{
				[userDefaults setInteger:(ratingCount + 1) forKey:ratingKey];
			}
			else if(ratingCount == ratingThreshold && coins >= 200)
			{
				ratingView = [[UIAlertView alloc] initWithTitle:@"Support Flamin Stack!" message:@"Congratulations! You have got a lot of coins already! Would you please rate the game on the App Store?" delegate:self cancelButtonTitle:@"No way!" otherButtonTitles:@"Yes, sure!", nil];
				[ratingView show];
				[ratingView release];
			}
		}
	}
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	// Only care about touch events when the game is displaying the title
	if(blockGameStateCurrent == STATE_TITLE)
	{
		// Check whether the coin slot has been touched
		CGPoint point = [[touches anyObject] locationInView:self];
		point.x -= coinSlotCenterX;
		point.y -= coinSlotCenterY;
		if(point.x * point.x + point.y * point.y <= blockSize * blockSize)
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

			// Clear the game area
			for(blockRowNumber = 0; blockRowNumber < 12; ++blockRowNumber)
			{
				blockRowState[blockRowNumber] = 0;
			}

			// Start the game
			blockGameStateNext = STATE_MOVE;
		}
	}
}

- (void)changeToUser:(NSString*)userId
{
	achievementCountAnyPrize = 0;
	achievementCountMajorPrize = 0;
	achievementCountLost = 0;
}

- (void)changeVersion
{
	if(blockGameStateCurrent == STATE_TITLE)
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
														@"416417309"
#else
														@"400028077"
#endif
														]];
		}
	}
}

- (void)dealloc
{
	// Destroy the message
	free(messageBytes);

	// Release the LED block image
	[blockLedOn release];

	// Release the background and coin slot gradients
	CGGradientRelease(gradientCoinSlot);
	CGGradientRelease(gradientBackground);

	// Destroy everything else
	[super dealloc];
}

@end
