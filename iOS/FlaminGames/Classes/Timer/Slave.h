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

	UIImage* segmentOff;
	UIImageView* segmentOn[4][7];

	Label* labelStopMajor;
	Label* labelStop100Coins;
	Label* labelStop3Coins;
	Label* labelStopMinor;
	Label* labelInsertCoin;

	Button* buttonStop;
	Button* buttonPrize;
	UIButton* buttonSwap;

	enum {TIME_BUSTER_LOADING = 0, TIME_BUSTER_WAIT, TIME_BUSTER_RUN, TIME_BUSTER_FAILED, TIME_BUSTER_MINOR_PRIZE, TIME_BUSTER_MAJOR_PRIZE} statePrevious, stateCurrent, stateNext;
	unsigned int music;
	unsigned int frameCounter;
	float timer;

	UIAlertView* ratingView;
}

@end
