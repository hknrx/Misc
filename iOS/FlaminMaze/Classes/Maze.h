#import <UIKit/UIKit.h>

#define mazeFrameRate       20
#define mazePathCountWidth  7
#define mazePathCountHeight 10

@class Label;
@class Button;
@class MenuLoading;
@class MenuMain;
@class MenuStart;
@class MenuPause;

@interface Maze : UIView <UIAlertViewDelegate>
{
	UIImage* ledDoorOff;
	UIImage* ledPathOff;
	UIImageView* ledDoorH[mazePathCountWidth * (mazePathCountHeight + 1)];
	UIImageView* ledDoorV[(mazePathCountWidth + 1) * mazePathCountHeight];
	UIImageView* ledPath[mazePathCountWidth * mazePathCountHeight];

	UIImage* digitOff;
	UIImageView* digitOn[5][7];

	Label* labelTime;
	Label* labelLevel;
	Button* buttonMenu;
	MenuLoading* menuLoading;
	MenuMain* menuMain;
	MenuStart* menuStart;
	MenuPause* menuPause;

	unsigned int mazeDisableCount;
	enum {MAZE_STATE_MENU_LOADING = 0, MAZE_STATE_MENU_MAIN, MAZE_STATE_MENU_START, MAZE_STATE_MENU_PAUSE, MAZE_STATE_COUNTDOWN, MAZE_STATE_PLAY, MAZE_STATE_WIN_ESCAPE, MAZE_STATE_WIN_EXPLORE, MAZE_STATE_LOSE} mazeStatePrevious, mazeStateCurrent, mazeStateNext;
	BOOL mazeModeExplore;
	unsigned short maze[(mazePathCountWidth + 1) * (mazePathCountHeight + 1)];
	unsigned int mazeMusic;
	unsigned int mazeFrame;
	unsigned int mazeTimer;
	unsigned int mazeLevel;
	unsigned int mazeAchievmentLevelIndex;
	unsigned int mazeAchievmentCountIndex;
	unsigned int mazeStart;
	unsigned int mazeEnd;
	unsigned int mazeCount;
	float mazeAlphaDoor;
	unsigned int mazeAlphaPath;
	BOOL mazeInfoDisplay;

	UITouch* touch;
	UIAlertView* ratingView;
}

- (void)enable;
- (void)disable;
- (void)update;
- (void)userChanged;
- (void)pause;

@end
