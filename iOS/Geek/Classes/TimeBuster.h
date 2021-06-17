#import <UIKit/UIKit.h>
#import "Slave.h"

@class Label;
@class Button;

@interface TimeBuster : UIView <Slave>
{
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

	enum {TIME_BUSTER_WAIT = 0, TIME_BUSTER_RUN, TIME_BUSTER_FAILED, TIME_BUSTER_MINOR_PRIZE, TIME_BUSTER_MAJOR_PRIZE} stateCurrent, stateNext;
	unsigned int frameCounter;
	float timer;

	NSTimer* updateTimer;
}

@end
