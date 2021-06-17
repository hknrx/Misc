#import <UIKit/UIKit.h>
#import "Slave.h"

@class Label;
@class Button;

@interface Stacker : UIView <Slave>
{
	CGGradientRef gradientBackground;
	CGGradientRef gradientCoinSlot;

	Label* label12thRow;
	Label* label9thRow;
	Label* labelInsertCoin;

	Button* buttonContinue;
	Button* buttonStack;
	Button* buttonGetPrize;

	UIImage* blockLedOn;
	UIImageView* blockLedOff[7][12];
	enum {STATE_TITLE = 0, STATE_MOVE, STATE_STACK, STATE_FAILED, STATE_9TH_ROW, STATE_12TH_ROW} blockGameStateCurrent, blockGameStateNext;
	unsigned char blockRowState[12];
	unsigned char blockRowNumber;
	unsigned char blockRowError;
	unsigned int blockTimer;

	unsigned int messageLength;
	unsigned char* messageBytes;

	NSTimer* updateTimer;
}

@end
