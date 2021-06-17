#import <AudioToolbox/AudioToolbox.h>
#import "ApplicationDelegate.h"
#import "Master.h"

@implementation ApplicationDelegate

static void AudioSessionInterruptionHandler(void* userData, UInt32 interruptionState)
{
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	// Disable the "idle timer"
	application.idleTimerDisabled = YES;

	// Create the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	// Create the master view
	masterView = [[Master alloc] initWithFrame:[window bounds]];
	[window addSubview:masterView];
	[window makeKeyAndVisible];

	// Initialize the audio session
	AudioSessionInitialize(NULL, NULL, AudioSessionInterruptionHandler, self);

	// Initialize the PRNG
	srand([[NSDate date] timeIntervalSince1970]);
}

- (void)applicationWillTerminate:(UIApplication*)application
{
	// Update the uptime of the current slave view
	[masterView slaveViewUpdateUptime];

	// Make sure to save data that should be saved
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)dealloc
{
	// Destroy the master view
	[masterView release];

	// Destroy the window
	[window release];

	// Destroy everything else
	[super dealloc];
}

@end
