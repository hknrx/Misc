#import <UIKit/UIKit.h>
#import "Slave.h"

@class Label;

@interface Info : UIView
{
	BOOL help;

	CGMutablePathRef textBoxPath;
	CGGradientRef gradientInfo;
	CGGradientRef gradientHelp;

	Label* label;
}

@property (nonatomic, readonly) BOOL help;

- (void)prepareSlaveView:(UIView<Slave>*)slaveView displayHelp:(BOOL)displayHelp;

@end
