#import <UIKit/UIKit.h>
#import "OpenFeintDelegate.h"

@class Master;

@interface ApplicationDelegate : NSObject <UIApplicationDelegate, OpenFeintDelegate>
{
	UIWindow* window;
	Master* master;
	NSTimer* updateTimer;
	BOOL openFeintDashboard;
}

@end
