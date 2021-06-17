#import "OpenFeint.h"
#import "OpenFeintLocalSettings.h"
#import "ApplicationDelegate.h"
#import "Master.h"
#import "Sound.h"

@implementation ApplicationDelegate

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	// Disable the "idle timer"
	application.idleTimerDisabled = YES;

	// Initialize the PRNG
	srand([[NSDate date] timeIntervalSince1970]);

	// Create the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	// Create the master view
	master = [[Master alloc] initWithFrame:[window bounds]];
	[window addSubview:master.view];
	[window makeKeyAndVisible];

	// Initialize OpenFeint
	NSDictionary const*const openFeintSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], OpenFeintSettingDisableUserGeneratedContent, window, OpenFeintSettingPresentationWindow, nil];
	OFDelegatesContainer const*const openFeintDelegates = [OFDelegatesContainer containerWithOpenFeintDelegate:self];
	[OpenFeint initializeWithProductKey:openFeintProductKey andSecret:openFeintSecret andDisplayName:openFeintDisplayName andSettings:openFeintSettings andDelegates:openFeintDelegates];
	[OpenFeint respondToApplicationLaunchOptions:launchOptions];

	// Initialization is completed
	return YES;
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
	// Notify OpenFeint
	[OpenFeint applicationDidBecomeActive];
	if(!openFeintDashboard)
	{
		// Launch a timer to update the display (if there isn't a timer already)
		if(!updateTimer)
		{
			updateTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / [master frameRate]) target:master selector:@selector(update) userInfo:nil repeats:YES];
		}

		// Resume operations
		[master resume];
	}
}

- (void)applicationWillResignActive:(UIApplication*)application
{
	// Invalidate the update timer
	[updateTimer invalidate];
	updateTimer = nil;

	// Notify OpenFeint
	[OpenFeint applicationWillResignActive];
}

- (void)applicationWillTerminate:(UIApplication*)application
{
	// Invalidate the update timer
	[updateTimer invalidate];
	updateTimer = nil;

	// Stop all sounds and music immediately
	Sound const*const sound = [Sound sharedInstance];
	[sound stopSoundNamed:nil];
	[sound stopMusic];

	// Make sure to save data that should be saved
	[[NSUserDefaults standardUserDefaults] synchronize];

	// Shutdown OpenFeint
	[OpenFeint shutdown];
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
	// Notify OpenFeint
	[OpenFeint applicationDidEnterBackground];
}

- (void)applicationWillEnterForeground:(UIApplication*)application
{
	// Notify OpenFeint
	[OpenFeint applicationWillEnterForeground];
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	// Notify OpenFeint
	[OpenFeint applicationDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	// Notify OpenFeint
	[OpenFeint applicationDidFailToRegisterForRemoteNotifications];
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
	// Notify OpenFeint
	[OpenFeint applicationDidReceiveRemoteNotification:userInfo];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication*)application
{
	// Make sure to save data that should be saved
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)dashboardWillAppear
{
	// Invalidate the update timer
	[updateTimer invalidate];
	updateTimer = nil;

	// Take note that the dashboard will appeare
	openFeintDashboard = YES;
}

- (void)dashboardDidAppear
{
	// Hide the master view
	master.view.hidden = YES;
}

- (void)dashboardWillDisappear
{
	// Show the master view
	master.view.hidden = NO;
}

- (void)dashboardDidDisappear
{
	// Take note that the dashboard disappeared
	openFeintDashboard = NO;

	// Launch a timer to update the display (if there isn't a timer already)
	if(!updateTimer)
	{
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / [master frameRate]) target:master selector:@selector(update) userInfo:nil repeats:YES];
	}
}

- (void)offlineUserLoggedIn:(NSString*)userId
{
	// Notify the master view
	[master changeToUser:userId];
}

- (void)userLoggedIn:(NSString*)userId
{
	// Notify the master view
	[master changeToUser:userId];
}

- (void)userLoggedOut:(NSString*)userId
{
	// Notify the master view
	[master changeToUser:nil];
}

- (void)dealloc
{
	// Destroy the master view
	[master release];
	master = nil;

	// Destroy the window
	[window release];

	// Destroy everything else
	[super dealloc];
}

@end
