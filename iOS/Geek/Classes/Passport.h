#import <UIKit/UIKit.h>
#import "Slave.h"

@interface Passport : UIView <Slave>
{
	CGMutablePathRef passportPath;
	UILabel* passportGeneralLabel;
	UIButton* passportGeneralButton;
}

@end
