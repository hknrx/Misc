#import <UIKit/UIKit.h>
#import "OpenFeintDelegate.h"

@class Maze;

@interface ApplicationDelegate : NSObject <UIApplicationDelegate, OpenFeintDelegate>
{
	UIWindow* window;
	UIViewController* controller;
	Maze* maze;
	double frameRate;
}

+ (BOOL)slowDevice;

@end
