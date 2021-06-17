#import <sys/sysctl.h>
#import <CoreLocation/CoreLocation.h>
#import "ApplicationDelegate.h"
#import "Thermometer.h"

@implementation ApplicationDelegate

static BOOL device3GS = NO;

+ (void)initialize
{
	if(self == [ApplicationDelegate class])
	{
		// Check whether the application is running on a fast or a slow device
		size_t deviceNameSize;
		sysctlbyname("hw.machine", NULL, &deviceNameSize, NULL, 0);
		char *const deviceName = (char*)malloc(deviceNameSize);
		sysctlbyname("hw.machine", deviceName, &deviceNameSize, NULL, 0);
		device3GS = !strncmp(deviceName, "iPhone2", 7);
		free(deviceName);
	}
}

+ (BOOL)device3GS
{
	return device3GS;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	// Disable the idle timer
	application.idleTimerDisabled = YES;

	// Create the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];

	// Create the thermometer
	Thermometer const*const thermometer = [[Thermometer alloc] initWithFrame:[window bounds]];
	[window addSubview:thermometer];
	[window makeKeyAndVisible];
	[thermometer release];
}

- (void)dealloc
{
	// Destroy the window
	[window release];

	// Destroy everything else
	[super dealloc];
}

@end
