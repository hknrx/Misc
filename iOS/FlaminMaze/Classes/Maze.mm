#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTimingFunction.h>
#import <mach/mach.h>
#import "OpenFeintLocalSettings.h"
#import "OFHighScoreService.h"
#import "OFAchievement.h"
#import "Maze.h"
#import "ApplicationDelegate.h"
#import "Label.h"
#import "Button.h"
#import "Sound.h"
#import "MenuLoading.h"
#import "MenuMain.h"
#import "MenuStart.h"
#import "MenuPause.h"

#define timerStart     999
#define timerDecrement 1
#define timerIncrement 2

#ifdef FLAMIN_MAZE_GIANT
	#define screenWidth  768.0f
	#define screenHeight 1024.0f

	#define infoBarHeight 80.0f
	#define infoBarMargin 8.0f

	#define doorThickness 16.0f
#else
	#define screenWidth  320.0f
	#define screenHeight 480.0f

	#define infoBarHeight 40.0f
	#define infoBarMargin 4.0f

	#define doorThickness 8.0f
#endif

#define cellMaxWidth  ((screenWidth - doorThickness) / mazePathCountWidth)
#define cellMaxHeight ((screenHeight - infoBarHeight - doorThickness) / mazePathCountHeight)
#define cellSize      (cellMaxWidth < cellMaxHeight ? cellMaxWidth : cellMaxHeight)
#define cellSpacing   0.9f

#define mazeWidth   (cellSize * mazePathCountWidth)
#define mazeHeight  (cellSize * mazePathCountHeight)

#define doorOriginX ((screenWidth - mazeWidth) / 2)
#define doorOriginY ((screenHeight + infoBarHeight - mazeHeight) / 2)

#define blockSize    ((cellSize - doorThickness) * cellSpacing)
#define blockOriginX (doorOriginX + (cellSize - blockSize) / 2)
#define blockOriginY (doorOriginY + (cellSize - blockSize) / 2)

#ifdef FLAMIN_MAZE_GIANT
	#define digitSegmentThickness 8.0f
#else
	#define digitSegmentThickness 4.0f
#endif
#define digitCenterY        (infoBarHeight / 2)
#define digitHeight         (infoBarHeight - infoBarMargin * 2)
#define digitSegmentSpacing 0.9f
#define digitSegmentLength  ((digitHeight - digitSegmentThickness) / 2)
#define digitWidth          (digitSegmentLength + digitSegmentThickness)
#define digitGap            digitSegmentThickness

#define labelTop    infoBarMargin
#define labelHeight (infoBarHeight - infoBarMargin * 2)
#define labelMargin 4.0f

#ifdef FLAMIN_MAZE_GIANT
	#define timerLabelWidth 86.0f
#else
	#define timerLabelWidth 43.0f
#endif
#define timerLabelLeft     infoBarMargin
#define timerDigitLeft     (timerLabelLeft + timerLabelWidth + labelMargin)
#define timerDigitCenterX1 (timerDigitLeft + digitWidth / 2)
#define timerDigitCenterX2 (timerDigitCenterX1 + digitWidth + digitGap)
#define timerDigitCenterX3 (timerDigitCenterX2 + digitWidth + digitGap)
#define timerRight         (timerDigitCenterX3 + digitWidth / 2)

#ifdef FLAMIN_MAZE_GIANT
	#define levelLabelWidth 118.0f
#else
	#define levelLabelWidth 59.0f
#endif
#define levelLabelLeft     (screenWidth - infoBarMargin - 2 * digitWidth - digitGap - labelMargin - levelLabelWidth)
#define levelDigitLeft     (levelLabelLeft + levelLabelWidth + labelMargin)
#define levelDigitCenterX1 (levelDigitLeft + digitWidth / 2)
#define levelDigitCenterX2 (levelDigitCenterX1 + digitWidth + digitGap)

#ifdef FLAMIN_MAZE_GIANT
	#define menuWidth 150.0f
#else
	#define menuWidth 60.0f
#endif
#define menuLeft ((levelLabelLeft + timerRight - menuWidth) / 2)

@implementation Maze

static NSString const*const helpTextEscape = @"It is said that the exit is hidden at the end of the longest path from the entrance...   ***   Draw a path to the spot the farther away (note that there can be several dead ends at the same distance from the entrance, you'll have to check them all and find the good one)... Good luck!";
static NSString const*const helpTextExplore = @"Will you dare explore the whole maze?   ***   Quickly draw a path to each spot of the labyrinth! Good luck!";

static CGFloat const colorsBlockLedOff[8] = {0.2f, 0.0f, 0.1f, 1.0f, 0.0f, 0.0f, 0.0f, 1.0f};
static CGFloat const colorsBlockLedPath[8] = {1.0f, 0.2f, 0.5f, 1.0f, 0.2f, 0.0f, 0.1f, 1.0f};
static CGPoint const doorPoints[6] =
{
	{-cellSize * cellSpacing / 2, 0.0f},
	{-(cellSize - doorThickness) * cellSpacing / 2, doorThickness * cellSpacing / 2},
	{(cellSize - doorThickness) * cellSpacing / 2, doorThickness * cellSpacing / 2},
	{cellSize * cellSpacing / 2, 0.0f},
	{(cellSize - doorThickness) * cellSpacing / 2, -doorThickness * cellSpacing / 2},
	{-(cellSize - doorThickness) * cellSpacing / 2, -doorThickness * cellSpacing / 2},
};
static CGAffineTransform const doorTransforms[2] =
{
	{1.0f, 0.0f, 0.0f, 1.0f, cellSize / 2, 0.0f},
	{0.0f, 1.0f, -1.0f, 0.0f, 0.0f, cellSize / 2},
};
static int const directionOffset[] = {-1, -mazePathCountWidth - 1, 1, mazePathCountWidth + 1};
static unsigned char const symbols[][mazePathCountHeight + 1] =
{
	{0, 28, 34, 32, 24, 32, 32, 34, 28, 0, 0},
	{0, 28, 34, 32, 16, 8, 4, 2, 62, 0, 0},
	{0, 8, 12, 8, 8, 8, 8, 8, 28, 0, 0},
	{6, 1, 13, 9, 6, 48, 72, 72, 72, 48, 0},
	{62, 127, 73, 73, 127, 119, 62, 42, 42, 62, 0}
};
static CGPoint const digitSegmentPoints[6] =
{
	{-digitSegmentLength * digitSegmentSpacing / 2, 0.0f},
	{-(digitSegmentLength - digitSegmentThickness) * digitSegmentSpacing / 2, digitSegmentThickness * digitSegmentSpacing / 2},
	{(digitSegmentLength - digitSegmentThickness) * digitSegmentSpacing / 2, digitSegmentThickness * digitSegmentSpacing / 2},
	{digitSegmentLength * digitSegmentSpacing / 2, 0.0f},
	{(digitSegmentLength - digitSegmentThickness) * digitSegmentSpacing / 2, -digitSegmentThickness * digitSegmentSpacing / 2},
	{-(digitSegmentLength - digitSegmentThickness) * digitSegmentSpacing / 2, -digitSegmentThickness * digitSegmentSpacing / 2},
};
static CGAffineTransform const digitSegmentTransforms[7] =
{
	{1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f},
	{1.0f, 0.0f, 0.0f, 1.0f, 0.0f, -digitSegmentLength},
	{1.0f, 0.0f, 0.0f, 1.0f, 0.0f, digitSegmentLength},
	{0.0f, 1.0f, -1.0f, 0.0f, -digitSegmentLength / 2, -digitSegmentLength / 2},
	{0.0f, 1.0f, -1.0f, 0.0f, digitSegmentLength / 2, -digitSegmentLength / 2},
	{0.0f, 1.0f, -1.0f, 0.0f, -digitSegmentLength / 2, digitSegmentLength / 2},
	{0.0f, 1.0f, -1.0f, 0.0f, digitSegmentLength / 2, digitSegmentLength / 2},
};
static CGFloat const digitCenterX[5] = {timerDigitCenterX1, timerDigitCenterX2, timerDigitCenterX3, levelDigitCenterX1, levelDigitCenterX2};
static unsigned char const digitConvert[10] = {1, 47, 72, 40, 38, 48, 16, 45, 0, 32};

enum
{
	MAZE_DIRECTION_MASK = 3,
	MAZE_DIRECTION_INVALID = 4,
	MAZE_BLOCK = 8,
	MAZE_PATH = 16,
	MAZE_DOOR_OPENED_TOP = 32,
	MAZE_DOOR_OPENED_LEFT = 64,
	MAZE_ID_MASK = 7,
	MAZE_ID_SHIFT = 7
};

unsigned char Log2(unsigned char x)
{
	x |= (x >> 1);
	x |= (x >> 2);
	x |= (x >> 4);

	x -= (x >> 1) & 0x55;
	x = ((x >> 2) & 0x33) + (x & 0x33);
	x = ((x >> 4) + x) & 0x0f;

	return x;
}

vm_size_t memoryUsage(void)
{
	task_basic_info_data_t info;
	mach_msg_type_number_t size = sizeof(info);
	kern_return_t const status = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
	if(status == KERN_SUCCESS)
	{
		return info.resident_size;
	}
	return -1;
}

- (unsigned int)mazeCreate
{
	// Compute the width of the maze
	unsigned int width = Log2(mazeLevel++) + 1;
	if(width > mazePathCountWidth)
	{
		width = mazePathCountWidth;
	}

	// Initialize the maze
	unsigned int const left = (mazePathCountWidth - width) >> 1;
	unsigned int const right = left + width;
	for(unsigned int x = 0; x <= mazePathCountWidth; ++x)
	{
		unsigned int index = x + mazePathCountHeight * (mazePathCountWidth + 1);
		unsigned short value;
		if(x < left || x > right)
		{
			maze[index] = MAZE_DIRECTION_INVALID | MAZE_BLOCK | MAZE_DOOR_OPENED_TOP | MAZE_DOOR_OPENED_LEFT;
			value = MAZE_DIRECTION_INVALID | MAZE_BLOCK | MAZE_DOOR_OPENED_TOP | MAZE_DOOR_OPENED_LEFT;
		}
		else if(x == right)
		{
			maze[index] = MAZE_DIRECTION_INVALID | MAZE_BLOCK | MAZE_DOOR_OPENED_TOP | MAZE_DOOR_OPENED_LEFT;
			value = MAZE_DIRECTION_INVALID | MAZE_BLOCK | MAZE_DOOR_OPENED_TOP;
		}
		else
		{
			maze[index] = MAZE_DIRECTION_INVALID | MAZE_BLOCK | MAZE_DOOR_OPENED_LEFT;
			value = MAZE_DIRECTION_INVALID;
		}
		while(index > mazePathCountWidth)
		{
			index -= mazePathCountWidth + 1;
			maze[index] = value;
		}
	}

	// Create the path (note: "mazeStart" must be set prior to calling this method)
	unsigned int current = mazeStart;
	maze[current] |= MAZE_PATH;
	mazeCount = 0;
	unsigned int length = 0;
	unsigned int lengthMax = 0;
	while(1)
	{
		unsigned int direction = rand() & MAZE_DIRECTION_MASK;
		unsigned int rotate = 0;
		while(1)
		{
			// Check the neighbor
			unsigned int const next = current + directionOffset[direction];
			if(next < (mazePathCountWidth + 1) * mazePathCountHeight && maze[next] == MAZE_DIRECTION_INVALID)
			{
				// Take note of this neighbor
				++mazeCount;
				if(++length > lengthMax)
				{
					lengthMax = length;
					mazeEnd = next;
				}
				maze[next] = direction | ((length & MAZE_ID_MASK) << MAZE_ID_SHIFT);

				// Open the door
				if(directionOffset[direction] < 0)
				{
					maze[current] |= directionOffset[direction] == -1 ? MAZE_DOOR_OPENED_LEFT : MAZE_DOOR_OPENED_TOP;
				}
				else
				{
					maze[next] |= directionOffset[direction] == 1 ? MAZE_DOOR_OPENED_LEFT : MAZE_DOOR_OPENED_TOP;
				}

				// Continue
				current = next;
				break;
			}

			// Are there other directions to try?
			if(++rotate >= 4)
			{
				if(maze[current] & MAZE_DIRECTION_INVALID)
				{
					// Return the length of the path
					return lengthMax;
				}
				current -= directionOffset[maze[current] & MAZE_DIRECTION_MASK];
				--length;
				break;
			}

			// Try another direction
			if(direction >= 3)
			{
				direction = 0;
			}
			else
			{
				++direction;
			}
		}
	}
}

- (void)mazeUsingSymbolIndex:(unsigned int)symbolIndex
{
	unsigned int index = 0;
	for(unsigned int y = 0; y <= mazePathCountHeight; ++y)
	{
		unsigned char row = symbols[symbolIndex][y];
		for(unsigned int x = 0; x <= mazePathCountWidth; ++x)
		{
			unsigned char path = row & 1;
			unsigned short value = MAZE_DIRECTION_INVALID;
			if(path)
			{
				value |= MAZE_PATH;
			}
			if((x && maze[index - 1] & MAZE_PATH) ^ !path)
			{
				value |= MAZE_DOOR_OPENED_LEFT;
			}
			if((y && maze[index - mazePathCountWidth - 1] & MAZE_PATH) ^ !path)
			{
				value |= MAZE_DOOR_OPENED_TOP;
			}
			maze[index] = value;
			row >>= 1;
			++index;
		}
	}
}

- (void)updateDigitsFromIndex:(char)digitIndexStart toIndex:(char)digitIndexEnd withValue:(unsigned int)value
{
	while(digitIndexEnd >= digitIndexStart)
	{
		unsigned int const valueTenth = value / 10;
		unsigned char segmentConverted = digitConvert[value - 10 * valueTenth];
		value = valueTenth;
		for(unsigned char segmentIndex = 0; segmentIndex < 7; ++segmentIndex)
		{
			digitOn[digitIndexEnd][segmentIndex].hidden = segmentConverted & (1 << segmentIndex);
		}
		--digitIndexEnd;
	}
}

- (void)cleanDigitsFromIndex:(char)digitIndexStart toIndex:(char)digitIndexEnd
{
	while(digitIndexEnd >= digitIndexStart)
	{
		for(unsigned char segmentIndex = 0; segmentIndex < 7; ++segmentIndex)
		{
			digitOn[digitIndexEnd][segmentIndex].hidden = YES;
		}
		--digitIndexEnd;
	}
}

- (void)display
{
	// Set the alpha values for the path
	float alphaPath[8];
	if([ApplicationDelegate slowDevice])
	{
		for(unsigned int index = 0; index < 8; ++index)
		{
			alphaPath[index] = 1.0f;
		}
	}
	else
	{
		float angle = mazeAlphaPath * 2 * M_PI / mazeFrameRate;
		for(unsigned int index = 0; index < 8; ++index)
		{
			alphaPath[index] = 0.8f + 0.2f * sinf(angle);
			angle += M_PI_4;
		}
	}

	// Update the maze display
	unsigned int indexMaze = 0;
	unsigned int indexBlock = 0;
	for(unsigned int y = 0; y < mazePathCountHeight; ++y)
	{
		for(unsigned int x = 0; x < mazePathCountWidth; ++x)
		{
			ledPath[indexBlock].hidden = !(maze[indexMaze] & MAZE_PATH);
			ledPath[indexBlock].alpha = alphaPath[(maze[indexMaze] >> MAZE_ID_SHIFT) & MAZE_ID_MASK];
			ledDoorH[indexBlock].hidden = maze[indexMaze] & MAZE_DOOR_OPENED_TOP;
			ledDoorH[indexBlock].alpha = mazeAlphaDoor;
			ledDoorV[indexMaze].hidden = maze[indexMaze] & MAZE_DOOR_OPENED_LEFT;
			ledDoorV[indexMaze].alpha = mazeAlphaDoor;
			++indexBlock;
			++indexMaze;
		}
		ledDoorV[indexMaze].hidden = maze[indexMaze] & MAZE_DOOR_OPENED_LEFT;
		ledDoorV[indexMaze].alpha = mazeAlphaDoor;
		++indexMaze;
	}
	for(unsigned int x = 0; x < mazePathCountWidth; ++x)
	{
		ledDoorH[indexBlock].hidden = maze[indexMaze] & MAZE_DOOR_OPENED_TOP;
		ledDoorH[indexBlock].alpha = mazeAlphaDoor;
		++indexBlock;
		++indexMaze;
	}

	// Update the information bar
	labelTime.glow = mazeInfoDisplay;
	labelLevel.glow = mazeInfoDisplay;
	if(mazeInfoDisplay)
	{
		[self updateDigitsFromIndex:0 toIndex:2 withValue:mazeTimer];
		[self updateDigitsFromIndex:3 toIndex:4 withValue:mazeLevel];
	}
	else
	{
		[self cleanDigitsFromIndex:0 toIndex:4];
	}
}

- (void)enable
{
	--mazeDisableCount;
	if(!mazeDisableCount)
	{
		if(mazeStateCurrent == MAZE_STATE_MENU_MAIN)
		{
			[menuMain hideHelp:NO];
		}
		else if(mazeStateCurrent == MAZE_STATE_MENU_START)
		{
			[menuStart hideHelp:NO];
		}
	}
}

- (void)disable
{
	if(!mazeDisableCount)
	{
		if(mazeStateCurrent == MAZE_STATE_MENU_MAIN)
		{
			[menuMain hideHelp:YES];
		}
		else if(mazeStateCurrent == MAZE_STATE_MENU_START)
		{
			[menuStart hideHelp:YES];
		}
	}
	++mazeDisableCount;
}

+ (void)animateView:(UIView const*const)view setHidden:(BOOL)hidden
{
	view.hidden = hidden;
	CATransition const*const animation = [CATransition animation];
	[animation setDuration:0.5];
	[animation setType:hidden?kCATransitionReveal:kCATransitionMoveIn];
	[animation setSubtype:kCATransitionFromLeft];
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
	[view.layer addAnimation:animation forKey:nil];
}

- (void)update
{
	// Check whether the state machine is enabled or disabled
	if(mazeDisableCount)
	{
		return;
	}

	// Check whether there is a change of state
	if(mazeStateCurrent != mazeStateNext)
	{
		// DEBUG: display the memory usage
		NSLog(@"Memory usage: %u", memoryUsage());

		// Exit the current state
		mazeStatePrevious = mazeStateCurrent;
		switch(mazeStateCurrent)
		{
			case MAZE_STATE_MENU_LOADING:
			{
				// Hide the loading menu
				[Maze animateView:menuLoading setHidden:YES];
				break;
			}
			case MAZE_STATE_MENU_MAIN:
			{
				// Hide the main menu
				[Maze animateView:menuMain setHidden:YES];
				break;
			}
			case MAZE_STATE_MENU_START:
			{
				// Hide the start menu
				[Maze animateView:menuStart setHidden:YES];

				// Switch on the menu button
				buttonMenu.label.glow = YES;
				break;
			}
			case MAZE_STATE_MENU_PAUSE:
			{
				// Hide the pause menu
				[Maze animateView:menuPause setHidden:YES];

				// Switch on the menu button
				buttonMenu.label.glow = YES;

				// Resume the music
				[[Sound sharedInstance] resumeAll];
				break;
			}
			case MAZE_STATE_PLAY:
			{
				// Stop the alarm sound effect (if it is playing)
				[[Sound sharedInstance] stopSoundNamed:@"Alarm"];
				break;
			}
			case MAZE_STATE_LOSE:
			{
				// Display the rating alert message when it is appropriate
				if(mazeLevel >= 30)
				{
					NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
					if([userDefaults integerForKey:@"COUNT"] >= 200 && ![userDefaults boolForKey:@"RATING"])
					{
						[userDefaults setBool:YES forKey:@"RATING"];
						[userDefaults synchronize];

						ratingView = [[UIAlertView alloc] initWithTitle:@"Support Flamin Maze!" message:@"Congratulations! You went quite deep in these dangerous labyrinths! Would you please rate the game on the App Store?" delegate:self cancelButtonTitle:@"No way!" otherButtonTitles:@"Yes, sure!", nil];
						[ratingView show];
						[ratingView release];
					}
				}
				break;
			}
		}

		// Enter the new state
		mazeStateCurrent = mazeStateNext;
		switch(mazeStateCurrent)
		{
			case MAZE_STATE_MENU_MAIN:
			{
				// Launch the music
				[[Sound sharedInstance] playMusicNamed:@"MusicMenu" withLoopFlag:YES];

				// Switch off the menu button
				buttonMenu.label.glow = NO;

				// Show the main menu
				[Maze animateView:menuMain setHidden:NO];
				break;
			}
			case MAZE_STATE_MENU_START:
			{
				// Update the title, the OpenFeint button and the help text
				if(mazeModeExplore)
				{
					[menuStart setTitle:@"EXPLORE"];
					[menuStart updateOpenFeintButtonWithLeaderboardId:openFeintLeaderboardIdExplore];
					[menuStart addHelpText:helpTextExplore];
				}
				else
				{
					[menuStart setTitle:@"ESCAPE"];
					[menuStart updateOpenFeintButtonWithLeaderboardId:openFeintLeaderboardIdEscape];
					[menuStart addHelpText:helpTextEscape];
				}

				// Show the start menu
				[Maze animateView:menuStart setHidden:NO];
				break;
			}
			case MAZE_STATE_MENU_PAUSE:
			{
				// Pause the music
				[[Sound sharedInstance] pauseAll];

				// Switch off the menu button
				buttonMenu.label.glow = NO;

				// Update the title
				[menuPause setTitle:mazeModeExplore?@"EXPLORE":@"ESCAPE"];

				// Show the pause menu
				[Maze animateView:menuPause setHidden:NO];
				break;
			}
			case MAZE_STATE_COUNTDOWN:
			{
				// Stop the music (if it is playing)
				[[Sound sharedInstance] stopMusic];

				// Set the countdown
				[self mazeUsingSymbolIndex:0];
				[[Sound sharedInstance] playSoundNamed:@"Countdown"];
				mazeInfoDisplay = YES;

				// Initialize the parameters of the very first maze
				mazeTimer = timerStart;
				mazeLevel = 0;
				mazeStart = mazePathCountWidth / 2;

				// Reset the frame counter
				mazeFrame = 0;
				break;
			}
			case MAZE_STATE_PLAY:
			{
				// Don't reinitialize the state if the game was paused!
				if(mazeStatePrevious == MAZE_STATE_MENU_PAUSE)
				{
					break;
				}

				// Create a new maze
				[self mazeCreate];
				mazeAlphaDoor = 0.0f;
				mazeInfoDisplay = YES;
				break;
			}
			case MAZE_STATE_WIN_ESCAPE:
			{
				// Don't reinitialize the state if the game was paused!
				if(mazeStatePrevious == MAZE_STATE_MENU_PAUSE)
				{
					break;
				}

				// Clean the path
				for(unsigned int index = 0; index < mazePathCountHeight * (mazePathCountWidth + 1); ++index)
				{
					maze[index] &= ~MAZE_PATH;
				}

				// Set the right path
				unsigned int index = mazeEnd;
				maze[index] |= MAZE_PATH;
				while(!(maze[index] & MAZE_DIRECTION_INVALID))
				{
					index -= directionOffset[maze[index] & MAZE_DIRECTION_MASK];
					maze[index] |= MAZE_PATH;
				}

				// Reset the frame counter
				mazeFrame = 0;

				// Update achievments
				while(mazeAchievmentLevelIndex < sizeof(openFeintAchievmentLevel) / sizeof(*openFeintAchievmentLevel) && openFeintAchievmentLevel[mazeAchievmentLevelIndex].level <= mazeLevel)
				{
					[[OFAchievement achievement:openFeintAchievmentLevel[mazeAchievmentLevelIndex].achievementId] updateProgressionComplete:100.0 andShowNotification:YES];
					++mazeAchievmentLevelIndex;
				}
				break;
			}
			case MAZE_STATE_WIN_EXPLORE:
			{
				// Don't reinitialize the state if the game was paused!
				if(mazeStatePrevious == MAZE_STATE_MENU_PAUSE)
				{
					break;
				}

				// Reset the frame counter
				mazeFrame = 0;

				// Update achievments
				while(mazeAchievmentLevelIndex < sizeof(openFeintAchievmentLevel) / sizeof(*openFeintAchievmentLevel) && openFeintAchievmentLevel[mazeAchievmentLevelIndex].level <= mazeLevel)
				{
					[[OFAchievement achievement:openFeintAchievmentLevel[mazeAchievmentLevelIndex].achievementId] updateProgressionComplete:100.0 andShowNotification:YES];
					++mazeAchievmentLevelIndex;
				}
				break;
			}
			case MAZE_STATE_LOSE:
			{
				// Don't reinitialize the state if the game was paused!
				if(mazeStatePrevious == MAZE_STATE_MENU_PAUSE)
				{
					break;
				}

				// Update the leaderboard
				[OFHighScoreService setHighScore:mazeLevel forLeaderboard:mazeModeExplore?openFeintLeaderboardIdExplore:openFeintLeaderboardIdEscape onSuccess:OFDelegate() onFailure:OFDelegate()];

				// Update achievments
				NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
				NSInteger const count = [userDefaults integerForKey:@"COUNT"] + mazeLevel;
				[userDefaults setInteger:count forKey:@"COUNT"];
				while(mazeAchievmentCountIndex < sizeof(openFeintAchievmentCount) / sizeof(*openFeintAchievmentCount) && openFeintAchievmentCount[mazeAchievmentCountIndex].level <= count)
				{
					[[OFAchievement achievement:openFeintAchievmentCount[mazeAchievmentCountIndex].achievementId] updateProgressionComplete:100.0 andShowNotification:YES];
					++mazeAchievmentCountIndex;
				}

				// Launch the music
				[[Sound sharedInstance] playMusicNamed:@"MusicLose" withLoopFlag:NO];

				// Set the skull
				[self mazeUsingSymbolIndex:4];

				// Reset the frame counter
				mazeFrame = 0;
				break;
			}
		}
	}

	// Execute the current state
	switch(mazeStateCurrent)
	{
		case MAZE_STATE_COUNTDOWN:
		{
			// Animate the doors
			mazeAlphaDoor = mazeFrame < mazeFrameRate * 3 || mazeFrame & 1 ? 1.0f : 0.0f;

			// Animate the path
			++mazeAlphaPath;

			// Handle the countdown
			if(mazeFrame == mazeFrameRate * 1)
			{
				[self mazeUsingSymbolIndex:1];
				[[Sound sharedInstance] playSoundNamed:@"Countdown"];
			}
			else if(mazeFrame == mazeFrameRate * 2)
			{
				[self mazeUsingSymbolIndex:2];
				[[Sound sharedInstance] playSoundNamed:@"Countdown"];
			}
			else if(mazeFrame == mazeFrameRate * 3)
			{
				[self mazeUsingSymbolIndex:3];
				[[Sound sharedInstance] playMusicNamed:[NSString stringWithFormat:@"MusicPlay%d", ++mazeMusic & 3] withLoopFlag:YES];
			}
			else if(mazeFrame == mazeFrameRate * 4)
			{
				mazeStateNext = MAZE_STATE_PLAY;
			}

			// Update the frame counter
			++mazeFrame;
			break;
		}
		case MAZE_STATE_PLAY:
		{
			// Animate the path
			++mazeAlphaPath;

			// Handle the timer
			if(mazeTimer > timerDecrement)
			{
				mazeTimer -= timerDecrement;
				if(mazeTimer < mazeFrameRate * 5)
				{
					// Launch the alarm sound effect (if it isn't playing already)
					[[Sound sharedInstance] playSoundNamed:@"Alarm"];

					// Warning animation
					if(![ApplicationDelegate slowDevice])
					{
						mazeAlphaDoor = 0.6f + 0.4f * cosf(mazeFrame * 4 * M_PI / mazeFrameRate);
					}
				}
				else if(mazeAlphaDoor < 1.0f)
				{
					// Fade-in
					mazeAlphaDoor += 0.2f;
				}
			}
			else
			{
				mazeTimer = 0;
				mazeStateNext = MAZE_STATE_LOSE;
			}

			// Update the frame counter
			++mazeFrame;
			break;
		}
		case MAZE_STATE_WIN_ESCAPE:
		{
			// Animate the path
			++mazeAlphaPath;

			// Animate the information bar
			mazeInfoDisplay = mazeFrame & 4;

			// Check whether the path has been cleared
			if(mazeStart == mazeEnd)
			{
				// Fade-out
				if(mazeAlphaDoor > 0.0f)
				{
					mazeAlphaDoor -= 0.2f;
				}
				else
				{
					mazeStateNext = MAZE_STATE_PLAY;
				}
				break;
			}

			// Animate the doors
			mazeAlphaDoor = mazeFrame > mazeFrameRate / 2 || mazeFrame & 1 ? 1.0f : 0.0f;

			// Clean the path
			maze[mazeStart] &= ~MAZE_PATH;
			for(unsigned int direction = 0; direction < 4; ++direction)
			{
				unsigned int const next = mazeStart + directionOffset[direction];
				if(next < (mazePathCountWidth + 1) * mazePathCountHeight && (maze[next] & (MAZE_DIRECTION_MASK | MAZE_DIRECTION_INVALID | MAZE_PATH)) == (direction | MAZE_PATH))
				{
					mazeStart = next;
					break;
				}
			}

			// Increment the timer
			if(mazeTimer < timerStart - timerIncrement)
			{
				mazeTimer += timerIncrement;
			}
			else
			{
				mazeTimer = timerStart;
			}

			// Update the frame counter
			++mazeFrame;
			break;
		}
		case MAZE_STATE_WIN_EXPLORE:
		{
			// Animate the path
			++mazeAlphaPath;

			// Animate the information bar
			mazeInfoDisplay = mazeFrame & 4;

			// Check whether the path has been cleared
			if(mazeFrame == mazePathCountHeight)
			{
				// Fade-out
				if(mazeAlphaDoor > 0.0f)
				{
					mazeAlphaDoor -= 0.2f;
				}
				else
				{
					mazeStateNext = MAZE_STATE_PLAY;
				}
				break;
			}

			// Animate the doors
			mazeAlphaDoor = mazeFrame > mazeFrameRate / 2 || mazeFrame & 1 ? 1.0f : 0.0f;

			// Clean the path and increment the timer
			unsigned int index = mazeFrame * (mazePathCountWidth + 1);
			for(unsigned int x = 0; x < mazePathCountWidth; ++x)
			{
				if(maze[index] & MAZE_PATH)
				{
					if(index != mazeStart)
					{
						maze[index] &= ~MAZE_PATH;
					}
					mazeTimer += timerIncrement;
				}
				++index;
			}
			if(mazeTimer > timerStart)
			{
				mazeTimer = timerStart;
			}

			// Update the frame counter
			++mazeFrame;
			break;
		}
		case MAZE_STATE_LOSE:
		{
			// Animate the doors
			mazeAlphaDoor = mazeFrame > mazeFrameRate || mazeFrame & 1 ? 1.0f : 0.0f;

			// Animate the path
			++mazeAlphaPath;

			// Animate the information bar
			mazeInfoDisplay = mazeFrame & 8;

			// Update the frame counter
			++mazeFrame;
			break;
		}
	}

	// Refresh the display
	[self display];
}

- (void)userChanged
{
	// Update the OpenFeint button
	[menuStart updateOpenFeintButtonWithLeaderboardId:mazeModeExplore?openFeintLeaderboardIdExplore:openFeintLeaderboardIdEscape];

	// Reset the achievment indexes
	mazeAchievmentLevelIndex = 0;
	mazeAchievmentCountIndex = 0;
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Create the door images
		if(UIGraphicsBeginImageContextWithOptions)
		{
			UIGraphicsBeginImageContextWithOptions(CGSizeMake(cellSize, doorThickness), NO, 0.0f);
		}
		else
		{
			UIGraphicsBeginImageContext(CGSizeMake(cellSize, doorThickness));
		}
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextTranslateCTM(context, cellSize / 2, doorThickness / 2);
		CGContextSetRGBFillColor(context, 0.1f, 0.07f, 0.0f, 1.0f);
		CGContextAddLines(context, doorPoints, 6);
		CGContextFillPath(context);
		ledDoorOff = [UIGraphicsGetImageFromCurrentImageContext() retain];
		CGContextClearRect(context, CGRectInfinite);
		CGContextSetRGBFillColor(context, 1.0f, 0.7f, 0.2f, 1.0f);
		CGContextAddLines(context, doorPoints, 6);
		CGContextFillPath(context);
		UIImage* ledDoorOnImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		// Create the path images
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		if(UIGraphicsBeginImageContextWithOptions)
		{
			UIGraphicsBeginImageContextWithOptions(CGSizeMake(blockSize, blockSize), YES, 0.0f);
		}
		else
		{
			UIGraphicsBeginImageContext(CGSizeMake(blockSize, blockSize));
		}
		context = UIGraphicsGetCurrentContext();
		CGPoint center = CGPointMake(blockSize / 2, blockSize / 2);
		CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colorsBlockLedOff, NULL, 2);
		CGContextDrawRadialGradient(context, gradient, center, blockSize / 4, center, blockSize * M_SQRT1_2, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
		ledPathOff = [UIGraphicsGetImageFromCurrentImageContext() retain];
		CGGradientRelease(gradient);
		CGContextClearRect(context, CGRectInfinite);
		gradient = CGGradientCreateWithColorComponents(colorSpace, colorsBlockLedPath, NULL, 2);
		CGContextDrawRadialGradient(context, gradient, center, blockSize / 4, center, blockSize * M_SQRT1_2, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
		UIImage* ledPathOnImage = UIGraphicsGetImageFromCurrentImageContext();
		CGGradientRelease(gradient);
		UIGraphicsEndImageContext();
		CGColorSpaceRelease(colorSpace);

		// Create the digit images
		if(UIGraphicsBeginImageContextWithOptions)
		{
			UIGraphicsBeginImageContextWithOptions(CGSizeMake(digitSegmentLength, digitSegmentThickness), NO, 0.0f);
		}
		else
		{
			UIGraphicsBeginImageContext(CGSizeMake(digitSegmentLength, digitSegmentThickness));
		}
		context = UIGraphicsGetCurrentContext();
		CGContextTranslateCTM(context, digitSegmentLength / 2, digitSegmentThickness / 2);
		CGContextSetRGBFillColor(context, 0.2f, 0.0f, 0.1f, 1.0f);
		CGContextAddLines(context, digitSegmentPoints, 6);
		CGContextFillPath(context);
		digitOff = [UIGraphicsGetImageFromCurrentImageContext() retain];
		CGContextClearRect(context, CGRectInfinite);
		CGContextSetRGBFillColor(context, 1.0f, 0.2f, 0.5f, 1.0f);
		CGContextAddLines(context, digitSegmentPoints, 6);
		CGContextFillPath(context);
		UIImage* digitOnImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		// Define the maze
		center.y = doorOriginY;
		unsigned int index = 0;
		for(unsigned int y = 0; y <= mazePathCountHeight; ++y)
		{
			center.x = doorOriginX;
			for(unsigned int x = 0; x < mazePathCountWidth; ++x)
			{
				ledDoorH[index] = [[UIImageView alloc] initWithImage:ledDoorOnImage];
				ledDoorH[index].transform = doorTransforms[0];
				ledDoorH[index].center = center;
				[self addSubview:ledDoorH[index]];
				[ledDoorH[index] release];

				++index;
				center.x += cellSize;
			}
			center.y += cellSize;
		}
		center.y = doorOriginY;
		index = 0;
		for(unsigned int y = 0; y < mazePathCountHeight; ++y)
		{
			center.x = doorOriginX;
			for(unsigned int x = 0; x <= mazePathCountWidth; ++x)
			{
				ledDoorV[index] = [[UIImageView alloc] initWithImage:ledDoorOnImage];
				ledDoorV[index].transform = doorTransforms[1];
				ledDoorV[index].center = center;
				[self addSubview:ledDoorV[index]];
				[ledDoorV[index] release];

				++index;
				center.x += cellSize;
			}
			center.y += cellSize;
		}
		center.y = blockOriginY + blockSize / 2;
		index = 0;
		for(unsigned int y = 0; y < mazePathCountHeight; ++y)
		{
			center.x = blockOriginX + blockSize / 2;
			for(unsigned int x = 0; x < mazePathCountWidth; ++x)
			{
				ledPath[index] = [[UIImageView alloc] initWithImage:ledPathOnImage];
				ledPath[index].center = center;
				[self addSubview:ledPath[index]];
				[ledPath[index] release];

				++index;
				center.x += cellSize;
			}
			center.y += cellSize;
		}

		// Define the digits
		center.y = digitCenterY;
		for(unsigned char digitIndex = 0; digitIndex < 5; ++digitIndex)
		{
			center.x = digitCenterX[digitIndex];
			for(unsigned char segmentIndex = 0; segmentIndex < 7; ++segmentIndex)
			{
				digitOn[digitIndex][segmentIndex] = [[UIImageView alloc] initWithImage:digitOnImage];
				digitOn[digitIndex][segmentIndex].transform = digitSegmentTransforms[segmentIndex];
				digitOn[digitIndex][segmentIndex].center = center;
				[self addSubview:digitOn[digitIndex][segmentIndex]];
				[digitOn[digitIndex][segmentIndex] release];
			}
		}

		// Define the labels
		labelTime = [[Label alloc] initWithFrame:CGRectMake(timerLabelLeft, labelTop, timerLabelWidth, labelHeight) withSize:FONT_SIZE withColor:[UIColor yellowColor]];
		labelTime.text = @"TIME";
		[self addSubview:labelTime];
		[labelTime release];

		labelLevel = [[Label alloc] initWithFrame:CGRectMake(levelLabelLeft, labelTop, levelLabelWidth, labelHeight) withSize:FONT_SIZE withColor:[UIColor yellowColor]];
		labelLevel.text = @"LEVEL";
		[self addSubview:labelLevel];
		[labelLevel release];

		// Define the menu button
		buttonMenu = [[Button alloc] initWithColor:[UIColor colorWithRed:1.0f green:0.2f blue:0.5f alpha:1.0f] withText:@"MENU" withFontSize:FONT_SIZE * 0.8f inRectangle:CGRectMake(menuLeft, labelTop, menuWidth, labelHeight) withTarget:self withSelector:@selector(buttonMenu:)];
		[self addSubview:buttonMenu];
		[buttonMenu release];

		// Define and display the loading menu
		menuLoading = [[MenuLoading alloc] initWithFrame:frame withParent:self];
		[self addSubview:menuLoading];
		[menuLoading release];

		// Define the main menu
		menuMain = [[MenuMain alloc] initWithFrame:frame withParent:self];
		menuMain.hidden = YES;
		[self addSubview:menuMain];
		[menuMain release];

		// Define the start menu
		menuStart = [[MenuStart alloc] initWithFrame:frame withParent:self];
		menuStart.hidden = YES;
		[self addSubview:menuStart];
		[menuStart release];

		// Define the pause menu
		menuPause = [[MenuPause alloc] initWithFrame:frame withParent:self];
		menuPause.hidden = YES;
		[self addSubview:menuPause];
		[menuPause release];

		// Initialize the sound system
		Sound const*const sound = [Sound sharedInstance];
		[sound loadSoundNamed:@"Alarm" withFileNamed:@"EffectAlarm" withLoopFlag:YES];
		[sound loadSoundNamed:@"Countdown" withFileNamed:@"EffectCountdown" withLoopFlag:NO];

		// Clean the maze
		for(index = 0; index < sizeof(maze) / sizeof(*maze); ++index)
		{
			maze[index] = MAZE_DIRECTION_INVALID | MAZE_BLOCK | MAZE_DOOR_OPENED_TOP | MAZE_DOOR_OPENED_LEFT;
		}

		// Set the initial state of the game
		mazeDisableCount = 1;
		mazeStatePrevious = MAZE_STATE_MENU_LOADING;
		mazeStateCurrent = MAZE_STATE_MENU_LOADING;
		mazeStateNext = MAZE_STATE_MENU_MAIN;
		mazeMusic = rand();

		// Perform a first display
		[self display];
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Display the maze
	CGPoint point;
	point.y = doorOriginY;
	for(unsigned int y = 0; y <= mazePathCountHeight; ++y)
	{
		point.x = doorOriginX;
		for(unsigned int x = 0; x < mazePathCountWidth; ++x)
		{
			CGContextSaveGState(context);
			CGContextTranslateCTM(context, point.x, point.y);
			CGContextConcatCTM(context, doorTransforms[0]);
			CGContextTranslateCTM(context, -cellSize / 2, -doorThickness / 2);
			[ledDoorOff drawAtPoint:CGPointZero];
			CGContextRestoreGState(context);
			point.x += cellSize;
		}
		point.y += cellSize;
	}
	point.y = doorOriginY;
	for(unsigned int y = 0; y < mazePathCountHeight; ++y)
	{
		point.x = doorOriginX;
		for(unsigned int x = 0; x <= mazePathCountWidth; ++x)
		{
			CGContextSaveGState(context);
			CGContextTranslateCTM(context, point.x, point.y);
			CGContextConcatCTM(context, doorTransforms[1]);
			CGContextTranslateCTM(context, -cellSize / 2, -doorThickness / 2);
			[ledDoorOff drawAtPoint:CGPointZero];
			CGContextRestoreGState(context);
			point.x += cellSize;
		}
		point.y += cellSize;
	}
	point.y = blockOriginY;
	for(unsigned int y = 0; y < mazePathCountHeight; ++y)
	{
		point.x = blockOriginX;
		for(unsigned int x = 0; x < mazePathCountWidth; ++x)
		{
			[ledPathOff drawAtPoint:point];
			point.x += cellSize;
		}
		point.y += cellSize;
	}

	// Display the digits
	for(unsigned char digitIndex = 0; digitIndex < 5; ++digitIndex)
	{
		for(unsigned char segmentIndex = 0; segmentIndex < 7; ++segmentIndex)
		{
			CGContextSaveGState(context);
			CGContextTranslateCTM(context, digitCenterX[digitIndex], digitCenterY);
			CGContextConcatCTM(context, digitSegmentTransforms[segmentIndex]);
			CGContextTranslateCTM(context, -digitSegmentLength / 2, -digitSegmentThickness / 2);
			[digitOff drawAtPoint:CGPointZero];
			CGContextRestoreGState(context);
		}
	}
}

- (void)touchMaze
{
	// Get the position touched by the player
	CGPoint const point = [touch locationInView:self];
	if(point.x >= doorOriginX && point.x < doorOriginX + mazePathCountWidth * cellSize && point.y >= doorOriginY && point.y < doorOriginY + mazePathCountHeight * cellSize)
	{
		unsigned int const x = (point.x - doorOriginX) / cellSize;
		unsigned int const y = (point.y - doorOriginY) / cellSize;
		unsigned int const index = x + y * (mazePathCountWidth + 1);

		// Make sure the current position is an empty corridor that is next to the path
		if(!(maze[index] & (MAZE_DIRECTION_INVALID | MAZE_PATH)) && maze[index - directionOffset[maze[index] & MAZE_DIRECTION_MASK]] & MAZE_PATH)
		{
			maze[index] |= MAZE_PATH;
			if(mazeModeExplore)
			{
				// Check whether the maze has been fully explored
				if(!--mazeCount)
				{
					mazeStart = index;
					mazeStateNext = MAZE_STATE_WIN_EXPLORE;
				}
			}
			else
			{
				// Check whether the end of the maze has been reached
				if(index == mazeEnd)
				{
					mazeStateNext = MAZE_STATE_WIN_ESCAPE;
				}
			}
		}
	}
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	if(mazeStateCurrent == MAZE_STATE_PLAY)
	{
		touch = [touches anyObject];
		[self touchMaze];
	}
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	if(mazeStateCurrent == MAZE_STATE_PLAY && [touches containsObject:touch])
	{
		[self touchMaze];
	}
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	touch = nil;
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
	touch = nil;
}

- (void)buttonMenu:(id)sender
{
	// Check whether the game is over
	if(mazeStateCurrent == MAZE_STATE_LOSE)
	{
		// Go back to the main menu
		mazeStateNext = MAZE_STATE_MENU_MAIN;
	}
	else
	{
		// Display the pause menu
		mazeStateNext = MAZE_STATE_MENU_PAUSE;
	}
}

- (void)buttonEscape:(id)sender
{
	// Set the game mode
	mazeModeExplore = NO;

	// Display the start menu
	mazeStateNext = MAZE_STATE_MENU_START;
}

- (void)buttonExplore:(id)sender
{
	// Set the game mode
	mazeModeExplore = YES;

	// Display the start menu
	mazeStateNext = MAZE_STATE_MENU_START;
}

- (void)buttonStart:(id)sender
{
	// Launch the countdown
	mazeStateNext = MAZE_STATE_COUNTDOWN;
}

- (void)buttonBack:(id)sender
{
	// Go back to the previous state
	mazeStateNext = mazeStatePrevious;
}

- (void)buttonGiveUp:(id)sender
{
	// Update achievments
	for(unsigned int index = 0; index < sizeof(openFeintAchievmentGiveUp) / sizeof(*openFeintAchievmentGiveUp); ++index)
	{
		if(openFeintAchievmentGiveUp[index].level > mazeLevel)
		{
			[[OFAchievement achievement:openFeintAchievmentGiveUp[index].achievementId] updateProgressionComplete:100.0 andShowNotification:YES];
			break;
		}
	}

	// Go back to the main menu
	mazeStateNext = MAZE_STATE_MENU_MAIN;
}

- (void)pause
{
	// Check whether the game is running
	if(mazeStateCurrent > MAZE_STATE_MENU_PAUSE)
	{
		// Display the pause menu
		mazeStateNext = MAZE_STATE_MENU_PAUSE;
	}
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(alertView == ratingView)
	{
		ratingView = nil;
		if(buttonIndex == 1)
		{
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id="
#ifdef FLAMIN_MAZE_GIANT
														@"417008200"
#else
														@"356583731"
#endif
														]];
		}
	}
}

- (void)dealloc
{
	// Release the digit image
	[digitOff release];

	// Release the LED images
	[ledPathOff release];
	[ledDoorOff release];

	// Destroy everything else
	[super dealloc];
}

@end
