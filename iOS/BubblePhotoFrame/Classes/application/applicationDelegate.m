#import "applicationDelegate.h"
#import "viewController.h"

@implementation applicationDelegate

- (void)applicationDidFinishLaunching:(UIApplication*)application
{
	// Disable the "idle timer"
	application.idleTimerDisabled = YES;

	// Set the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	// Set the view controller
	viewController = [[ViewController alloc] initWithFrame:[window bounds]];

	// Add the view to the window and make everything visible
	[window addSubview:viewController.view];
	[window makeKeyAndVisible];
}

- (void)dealloc
{
	[viewController.renderTimer invalidate];
	[viewController release];
	[window release];
	[super dealloc];
}

@end
