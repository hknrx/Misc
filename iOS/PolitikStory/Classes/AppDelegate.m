// TODO:
// - Add a timer to prevent users to update data too frequently?
// - Add a background music (loop) and a bunch of sound effects.

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()
{
	ViewController * viewController;
	UIWindow * window;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	application.statusBarHidden = YES;

	viewController = [[ViewController alloc] init];

	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[window setRootViewController:viewController];
	[window makeKeyAndVisible];

	return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end
