#import <UIKit/UIKit.h>
#import "SlaveProtocol.h"

@class Master;
@class Label;
@class Button;

@interface Slave : UIView <SlaveProtocol, UIAlertViewDelegate>
{
	Master* master;

	CGGradientRef gradientBackground;
	CGGradientRef gradientCoinSlot;

	Label* label12thRow;
	Label* label9thRow;
	Label* labelInsertCoin;

	Button* buttonContinue;
	Button* buttonStack;
	Button* buttonGetPrize;
	UIButton* buttonSwap;

	UIImage* blockLedOn;
	UIImageView* blockLedOff[7][12];
	enum {STATE_LOADING = 0, STATE_TITLE, STATE_MOVE, STATE_STACK, STATE_FAILED, STATE_9TH_ROW, STATE_12TH_ROW} blockGameStatePrevious, blockGameStateCurrent, blockGameStateNext;
	unsigned char blockRowState[12];
	unsigned char blockRowNumber;
	unsigned char blockRowError;
	unsigned int blockMusic;
	unsigned int blockTimer;

	unsigned int messageHeight;
	unsigned char* messageBytes;

	UIAlertView* ratingView;
}

@end
