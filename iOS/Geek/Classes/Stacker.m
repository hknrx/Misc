#import "Stacker.h"
#import "Master.h"
#import "Label.h"
#import "Button.h"

#define screenFrameRate 60
#define screenWidth     320.0f
#define screenHeight    (480.0f - 44.0f)

#define coinBarWidth 80.0f

#define buttonBarGap    10.0f
#define buttonBarHeight 44.0f
#define buttonWidth     ((screenWidth - 2 * buttonBarGap) / 3)

#define containerThickness 5.0f
#define containerMaxWidth  (screenWidth - containerThickness - coinBarWidth)
#define containerMaxHeight (screenHeight - containerThickness - buttonBarGap - buttonBarHeight)

#define blockMaxWidth  ((containerMaxWidth - containerThickness) / 7)
#define blockMaxHeight ((containerMaxHeight - containerThickness) / 12)
#define blockSize      (blockMaxWidth < blockMaxHeight ? blockMaxWidth : blockMaxHeight)

#define containerWidth   (blockSize * 7 + containerThickness)
#define containerHeight  (blockSize * 12 + containerThickness)
#define containerOriginX ((containerThickness + containerMaxWidth - containerWidth) / 2)
#define containerOriginY ((containerThickness + containerMaxHeight - containerHeight) / 2)

#define blockOriginX (containerOriginX + containerThickness / 2)
#define blockOriginY (containerOriginY + containerThickness / 2)

#define coinSlotCenterX   (screenWidth - coinBarWidth / 2)
#define coinSlotCenterY   (blockOriginY + blockSize * 10)
#define coinSlotThickness 4.0f

@implementation Stacker

static CGFloat const colorsBackground[12] = {0.0f, 0.0f, 0.0f, 1.0f, 0.3f, 0.3f, 0.5f, 1.0f, 0.1f, 0.1f, 0.1f, 1.0f};
static CGFloat const colorsCoinSlot[12] = {0.2f, 0.2f, 0.2f, 1.0f, 0.4f, 0.4f, 0.4f, 1.0f, 0.3f, 0.3f, 0.3f, 1.0f};
static CGFloat const colorsBlockLedOff[8] = {0.4f, 0.1f, 0.2f, 1.0f, 0.2f, 0.0f, 0.1f, 1.0f};
static CGFloat const colorsBlockLedOn[8] = {1.0f, 0.2f, 0.5f, 1.0f, 0.2f, 0.0f, 0.1f, 1.0f};

- (NSString*)helpText
{
	return @"First, insert a coin to start playing. Tap the STACK button to stop the blocks and build your stack; you will be awarded 3 coins if you stop at the 9th row, or 100 coins if you succeed to reach the 12th row!";
}

- (NSString*)infoText
{
	return @"Because Geeks need to have very good reaction time in their every day life (read: to play video games), Geek System offers them a little training with this Stack Game!";
}

+ (NSString*)menuName
{
	return @"Stack Game";
}

+ (BarContent)barContent
{
	return BAR_COINS;
}

- (UIImage*)createWinnerRowWithLabel:(NSString*)label
{
	// Define the image context
	UIGraphicsBeginImageContext(CGSizeMake(blockSize * 7, blockSize));
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

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Create a color space to define gradients
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

		// Define the background and coin slot gradients
		gradientBackground = CGGradientCreateWithColorComponents(colorSpace, colorsBackground, NULL, 3);
		gradientCoinSlot = CGGradientCreateWithColorComponents(colorSpace, colorsCoinSlot, NULL, 3);

		// Define the LED blocks
		UIGraphicsBeginImageContext(CGSizeMake(blockSize, blockSize));
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGPoint center = CGPointMake(blockSize / 2, blockSize / 2);

		CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colorsBlockLedOff, NULL, 2);
		CGContextDrawRadialGradient(context, gradient, center, blockSize / 4, center, blockSize * M_SQRT1_2, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
		UIImage* blockLedOffImage = UIGraphicsGetImageFromCurrentImageContext();
		CGGradientRelease(gradient);

		CGContextClearRect(context, CGRectInfinite);

		gradient = CGGradientCreateWithColorComponents(colorSpace, colorsBlockLedOn, NULL, 2);
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
		label12thRow = [[Label alloc] initWithFrame:CGRectMake(screenWidth - coinBarWidth, blockOriginY, coinBarWidth, blockSize) withSize:14.0f withColor:[UIColor yellowColor]];
		label12thRow.text = @"100 COINS";
		[self addSubview:label12thRow];
		[label12thRow release];

		label9thRow = [[Label alloc] initWithFrame:CGRectMake(screenWidth - coinBarWidth, blockOriginY + blockSize * 3, coinBarWidth, blockSize) withSize:14.0f withColor:[UIColor greenColor]];
		label9thRow.text = @"3 COINS";
		[self addSubview:label9thRow];
		[label9thRow release];

		labelInsertCoin = [[Label alloc] initWithFrame:CGRectMake(screenWidth - coinBarWidth, coinSlotCenterY - blockSize * 3, coinBarWidth, blockSize * 2) withSize:14.0f withColor:[UIColor redColor]];
		labelInsertCoin.text = @"INSERT\n1 COIN";
		labelInsertCoin.textAlignment = UITextAlignmentCenter;
		labelInsertCoin.numberOfLines = 0;
		[self addSubview:labelInsertCoin];
		[labelInsertCoin release];

		// Define the buttons
		buttonContinue = [[Button alloc] initWithColor:[UIColor yellowColor] withText:@"CONTINUE" withFontSize:buttonBarHeight / 3 inRectangle:CGRectMake(0.0f, screenHeight - buttonBarHeight, buttonWidth, buttonBarHeight) withTarget:self withSelector:@selector(buttonPressed:)];
		[self addSubview:buttonContinue];
		[buttonContinue release];

		buttonStack = [[Button alloc] initWithColor:[UIColor redColor] withText:@"STACK" withFontSize:buttonBarHeight / 2 inRectangle:CGRectMake(buttonWidth + buttonBarGap, screenHeight - buttonBarHeight, buttonWidth, buttonBarHeight) withTarget:self withSelector:@selector(buttonPressed:)];
		[self addSubview:buttonStack];
		[buttonStack release];

		buttonGetPrize = [[Button alloc] initWithColor:[UIColor greenColor] withText:@"GET PRIZE" withFontSize:buttonBarHeight / 3 inRectangle:CGRectMake(screenWidth - buttonWidth, screenHeight - buttonBarHeight, buttonWidth, buttonBarHeight) withTarget:self withSelector:@selector(buttonPressed:)];
		[self addSubview:buttonGetPrize];
		[buttonGetPrize release];

		// Initialize the state machine
		blockGameStateCurrent = -1;
		blockGameStateNext = STATE_TITLE;

		// Initialize the message
		char const*const message = " STACK GAME INSERT A COIN TO PLAY ";
		messageLength = strlen(message);
		messageBytes = malloc(8 * messageLength);

		unsigned int const pixelsPerRow = 7 * messageLength;
		unsigned char *const pixels = malloc(pixelsPerRow * 8);
		colorSpace = CGColorSpaceCreateDeviceGray();
		context = CGBitmapContextCreate(pixels, pixelsPerRow, 8, 8, pixelsPerRow, colorSpace, kCGImageAlphaNone);
		CGContextClearRect(context, CGRectMake(0.0f, 0.0f, pixelsPerRow, 8.0f));
		CGContextSelectFont(context, "Courier-Bold", 11.7f, kCGEncodingMacRoman);
		CGContextSetTextDrawingMode(context, kCGTextFill);
		CGContextSetGrayFillColor(context, 1.0f, 1.0f);
		CGContextSetShouldAntialias(context, false);
		CGContextShowTextAtPoint(context, 0.0f, 0.0f, message, messageLength);

		unsigned int byteIndex = 0;
		unsigned int pixelIndex = 0;
		for(unsigned int character = 0; character < messageLength; ++character)
		{
			for(unsigned int row = 0; row < 8; ++row)
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
				pixelIndex += pixelsPerRow - 7;
			}
			pixelIndex -= pixelsPerRow * 8 - 7;
		}

		CGContextRelease(context);
		CGColorSpaceRelease(colorSpace);
		free(pixels);
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
	CGContextDrawLinearGradient(context, gradientBackground, CGPointZero, CGPointMake(0.0f, screenHeight), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);

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

	CGContextSetLineWidth(context, coinSlotThickness * 2);
	CGContextSetLineCap(context, kCGLineCapRound);
	CGContextMoveToPoint(context, coinSlotCenterX, coinSlotCenterY - blockSize * 0.6f);
	CGContextAddLineToPoint(context, coinSlotCenterX, coinSlotCenterY + blockSize * 0.6f);
	CGContextStrokePath(context);
}

- (void)update
{
	// Update the state machine: initialize a new state
	if(blockGameStateCurrent != blockGameStateNext)
	{
		blockGameStateCurrent = blockGameStateNext;
		switch(blockGameStateCurrent)
		{
			case STATE_TITLE:
			{
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
				labelInsertCoin.glow = NO;

				// Set the buttons
				buttonContinue.label.glow = NO;
				buttonStack.label.glow = YES;
				buttonGetPrize.label.glow = NO;
				break;
			}
			case STATE_STACK:
			{
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
				// Set the labels
				label12thRow.glow = NO;
				label9thRow.glow = NO;
				labelInsertCoin.glow = NO;

				// Set the buttons
				buttonContinue.label.glow = NO;
				buttonStack.label.glow = NO;
				buttonGetPrize.label.glow = NO;
				break;
			}
			case STATE_9TH_ROW:
			{
				// Set the labels
				label12thRow.glow = YES;
				labelInsertCoin.glow = NO;

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
				// Set the labels
				label9thRow.glow = NO;
				labelInsertCoin.glow = NO;

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

	// Update the state machine: execute the current state
	switch(blockGameStateCurrent)
	{
		case STATE_TITLE:
		{
			// Update the label
			labelInsertCoin.glow = blockTimer & 16;

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
			blockRowState[y] = messageBytes[(blockTimer / 3) % (messageLength * 8)];
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
			// Get the prize
			if(blockGameStateCurrent == STATE_12TH_ROW)
			{
				[(Master*)[self superview] cashAdd:100 increaseKey:@"FUNFAIR_STACK_MAJOR"];
			}
			else
			{
				[(Master*)[self superview] cashAdd:3 increaseKey:@"FUNFAIR_STACK_MINOR"];
			}

			// Go back to the title
			blockGameStateNext = STATE_TITLE;
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
			// Insert a coin
			[(Master*)[self superview] cashAdd:-1 increaseKey:@"FUNFAIR_STACK_COUNT"];

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
