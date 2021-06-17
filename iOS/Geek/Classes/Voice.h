#import <UIKit/UIKit.h>
#import "Slave.h"

@interface Voice : UIView <Slave>
{
	UIButton* recordingButton;
	UIButton* playingButton;
}

@end
