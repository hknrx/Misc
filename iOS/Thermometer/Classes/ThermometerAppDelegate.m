#import <CoreLocation/CoreLocation.h>
#import "ThermometerAppDelegate.h"
#import "ThermometerViewController.h"
#import "ThermometerView.h"

@implementation ThermometerAppDelegate

@synthesize window, viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	application.idleTimerDisabled = YES;

	ThermometerView* viewThermometer = [[ThermometerView alloc] initWithFrame:[window bounds]];
	[window addSubview:viewThermometer];
	[viewThermometer addSubview:viewController.view];	
	[viewThermometer release];
	[window makeKeyAndVisible];

	locationManager = [[CLLocationManager alloc] init];
	if(locationManager.headingAvailable)
	{
		locationManager.delegate = viewController;
		[locationManager startUpdatingHeading]; // To be commented-out when generating "Default.png"
	}
}

- (void)dealloc
{
	[locationManager release];
	[viewController release];
	[window release];
	[super dealloc];
}

@end
