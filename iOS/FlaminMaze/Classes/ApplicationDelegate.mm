#import <sys/sysctl.h>
#import "OpenFeint.h"
#import "OpenFeintLocalSettings.h"
#import "ApplicationDelegate.h"
#import "Maze.h"
#import "Sound.h"

#define frameRatePause 1

@interface Controller : UIViewController
{
}

@end

@implementation Controller

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if(UIInterfaceOrientationIsPortrait(interfaceOrientation))
	{
		[OpenFeint setDashboardOrientation:interfaceOrientation];
		return YES;
	}
	return NO;
}

@end

@implementation ApplicationDelegate

static BOOL slowDevice = NO;

+ (void)initialize
{
	if(self == [ApplicationDelegate class])
	{
		// Check whether the application is running on a fast or a slow device
		size_t deviceNameSize;
		sysctlbyname("hw.machine", NULL, &deviceNameSize, NULL, 0);
		char *const deviceName = (char*)malloc(deviceNameSize);
		sysctlbyname("hw.machine", deviceName, &deviceNameSize, NULL, 0);
		slowDevice = !strncmp(deviceName, "iPhone1", 7) || !strncmp(deviceName, "iPod1", 5);
		free(deviceName);
	}
}

+ (BOOL)slowDevice
{
	return slowDevice;
}

- (void)process
{
	while(maze)
	{
		// Create a dedicated autorelease pool to handle the memory
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

		// Update the maze
		CFTimeInterval time = CACurrentMediaTime();
		[maze performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:YES];
		time += (1.0 / frameRate) - CACurrentMediaTime();

		// Make sure the OS has time to process events (in case the application is running considerably slower than the desired framerate)
		if(time < 0.01)
		{
			time = 0.01;
		}

		// Wait before handling the next frame
		[NSThread sleepForTimeInterval:time];

		// Clean up the memory (release the pool)
		[pool release];
	}
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	// Initialize the PRNG
	srand([[NSDate date] timeIntervalSince1970]);

	// Create the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	// Create the maze
	maze = [[Maze alloc] initWithFrame:[window bounds]];

	// Create the controller
	controller = [[Controller alloc] init];
	controller.view = maze;
	[window addSubview:maze];
	[window makeKeyAndVisible];

	// Initialize OpenFeint
	NSDictionary const*const openFeintSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], OpenFeintSettingDisableUserGeneratedContent, window, OpenFeintSettingPresentationWindow, nil];
	OFDelegatesContainer const*const openFeintDelegates = [OFDelegatesContainer containerWithOpenFeintDelegate:self];
	[OpenFeint initializeWithProductKey:openFeintProductKey andSecret:openFeintSecret andDisplayName:openFeintDisplayName andSettings:openFeintSettings andDelegates:openFeintDelegates];
	[OpenFeint respondToApplicationLaunchOptions:launchOptions];

	// Launch a thread to update the maze
	frameRate = frameRatePause;
	[NSThread detachNewThreadSelector:@selector(process) toTarget:self withObject:nil];

	// Initialization is completed
	return YES;
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
	// Notify OpenFeint
	[OpenFeint applicationDidBecomeActive];

	// Notify the maze
	[maze enable];
	frameRate = mazeFrameRate;
}

- (void)applicationWillResignActive:(UIApplication*)application
{
	// Notify the maze
	[maze disable];
	[maze pause];
	frameRate = frameRatePause;

	// Notify OpenFeint
	[OpenFeint applicationWillResignActive];
}

- (void)applicationWillTerminate:(UIApplication*)application
{
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
	// Notify the maze
	[maze disable];
	frameRate = frameRatePause;
}

- (void)dashboardDidAppear
{
	// Hide the maze
	maze.hidden = YES;
}

- (void)dashboardWillDisappear
{
	// Show the maze
	maze.hidden = NO;
}

- (void)dashboardDidDisappear
{
	// Notify the maze
	[maze enable];
	frameRate = mazeFrameRate;
}

- (void)offlineUserLoggedIn:(NSString*)userId
{
	// Notify the maze
	[maze userChanged];
}

- (void)userLoggedIn:(NSString*)userId
{
	// Notify the maze
	[maze userChanged];
}

- (void)userLoggedOut:(NSString*)userId
{
	// Notify the maze
	[maze userChanged];
}

- (void)dealloc
{
	// Destroy the controller
	[controller release];

	// Destroy the maze
	[maze release];
	maze = nil;

	// Destroy the window
	[window release];

	// Destroy everything else
	[super dealloc];
}

@end
