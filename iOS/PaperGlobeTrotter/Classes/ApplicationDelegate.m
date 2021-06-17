#import "ApplicationDelegate.h"
#import "Paint.h"

@implementation ApplicationDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	// Disable the "idle timer"
	application.idleTimerDisabled = YES;

	// Initialize the PRNG
	srand([[NSDate date] timeIntervalSince1970]);

	// Create the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];

	// Create the paint view
	Paint* paint = [[Paint alloc] initWithFrame:[window bounds]];
	[window addSubview:paint];
	[window makeKeyAndVisible];
	[paint release];
}

- (void)applicationWillTerminate:(UIApplication*)application
{
	// Make sure to save data that should be saved
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)dealloc
{
	// Destroy the window
	[window release];

	// Destroy everything else
	[super dealloc];
}

@end
