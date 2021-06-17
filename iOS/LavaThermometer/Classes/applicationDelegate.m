#import "applicationDelegate.h"
#import "controller.h"

@implementation ApplicationDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	// Disable the "idle timer"
	application.idleTimerDisabled = YES;

	// Set the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[window setUserInteractionEnabled:NO];

	// Set the view controller
	controller = [[Controller alloc] initWithFrame:[window bounds]];

	// Add the view to the window and make everything visible
	[window addSubview:controller.view];
	[window makeKeyAndVisible];
}

- (void)dealloc
{
	[controller release];
	[window release];
	[super dealloc];
}

@end
