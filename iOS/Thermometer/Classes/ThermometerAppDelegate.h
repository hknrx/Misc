#import <UIKit/UIKit.h>

@class ThermometerViewController;
@class CLLocationManager;

@interface ThermometerAppDelegate : NSObject <UIApplicationDelegate>
{
	UIWindow* window;
	ThermometerViewController* viewController;
	CLLocationManager* locationManager;
}

@property (nonatomic, retain) IBOutlet UIWindow* window;
@property (nonatomic, retain) IBOutlet ThermometerViewController* viewController;

@end
