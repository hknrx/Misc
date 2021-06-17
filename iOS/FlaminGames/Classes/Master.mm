#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTimingFunction.h>
#import <mach/mach.h>
#import "OpenFeint.h"
#import "Master.h"
#import "Label.h"
#import "Button.h"
#import "MenuLoading.h"
#import "MenuHelp.h"
#import "Slave.h"

#ifdef FLAMIN_GIANT
	#define barHelpWidth      150.0f
	#define barCoinsWidth     150.0f
	#define barOpenFeintWidth 325.0f
#else
	#define barHelpWidth      60.0f
	#define barCoinsWidth     60.0f
	#define barOpenFeintWidth 130.0f
#endif
#define barCoinsOriginX     ((screenWidth + barHelpWidth - barCoinsWidth - barOpenFeintWidth) / 2)
#define barOpenFeintOriginX (screenWidth - barOpenFeintWidth)

@interface MasterView : UIView
{
	CGGradientRef gradientBackground;
}

@end

@implementation MasterView

static CGFloat const colorsBackground[12] = {0.5f, 0.5f, 0.5f, 1.0f, 0.1f, 0.1f, 0.1f, 1.0f, 0.0f, 0.0f, 0.0f, 1.0f};

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Define the background gradient
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		gradientBackground = CGGradientCreateWithColorComponents(colorSpace, colorsBackground, NULL, 3);
		CGColorSpaceRelease(colorSpace);
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Display the background
	CGContextDrawLinearGradient(context, gradientBackground, CGPointZero, CGPointMake(0.0f, topBarHeight), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
}

- (void)dealloc
{
	// Release the background gradient
	CGGradientRelease(gradientBackground);

	// Destroy everything else
	[super dealloc];
}

@end

@implementation Master

+ (vm_size_t)memoryUsage
{
	task_basic_info_data_t info;
	mach_msg_type_number_t size = sizeof(info);
	kern_return_t const status = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
	if(status == KERN_SUCCESS)
	{
		return info.resident_size;
	}
	return -1;
}

+ (void)animateView:(UIView const*const)view setHidden:(BOOL)hidden
{
	view.hidden = hidden;
	CATransition const*const animation = [CATransition animation];
	[animation setDuration:0.5];
	[animation setType:hidden?kCATransitionReveal:kCATransitionMoveIn];
	[animation setSubtype:kCATransitionFromLeft];
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
	[view.layer addAnimation:animation forKey:nil];
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super init])
	{
		// Take note of the frame
		viewFrame = frame;
	}
	return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if(UIInterfaceOrientationIsPortrait(interfaceOrientation))
	{
		[OpenFeint setDashboardOrientation:interfaceOrientation];
		return YES;
	}
	return NO;
}

- (void)loadView
{
	// Create the view
	self.view = [[MasterView alloc] initWithFrame:viewFrame];

	// Define and display the help button
	Button* button = [[Button alloc] initWithColor:[UIColor grayColor] withText:@"?" withFontSize:topBarHeight / 2 inRectangle:CGRectMake(0.0f, 0.0f, barHelpWidth, topBarHeight) withTarget:self withSelector:@selector(showHelp)];
	button.label.glow = YES;
	[self.view addSubview:button];
	[button release];

	// Define and hide the coins label
	barLabelCoins = [[Label alloc] initWithFrame:CGRectMake(barCoinsOriginX, 0.0f, barCoinsWidth, topBarHeight) withSize:topBarHeight / 3 withColor:[UIColor blueColor]];
	barLabelCoins.textAlignment = UITextAlignmentCenter;
	barLabelCoins.numberOfLines = 0;
	barLabelCoins.glow = YES;
	barLabelCoins.hidden = YES;
	[self.view addSubview:barLabelCoins];
	[barLabelCoins release];

	// Define and display the OpenFeint button
	button = [[Button alloc] initWithColor:[UIColor grayColor] withText:@"OpenFeint" withFontSize:topBarHeight / 3 inRectangle:CGRectMake(barOpenFeintOriginX, 0.0f, barOpenFeintWidth, topBarHeight) withTarget:[OpenFeint class] withSelector:@selector(launchDashboard)];

	UIImageView* openFeintImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"OpenFeint.png"]];
	openFeintImage.center = CGPointMake(topBarHeight / 2, topBarHeight / 2);
	[button addSubview:openFeintImage];
	[openFeintImage release];

	CGFloat const buttonLabelShift = (topBarHeight + openFeintImage.image.size.width) / 2;
	CGRect buttonLabelFrame = button.label.frame;
	buttonLabelFrame.origin.x += buttonLabelShift;
	buttonLabelFrame.size.width -= buttonLabelShift;
	button.label.frame = buttonLabelFrame;
	button.label.glow = YES;
	[self.view addSubview:button];
	[button release];

	// Initialize the slave view
	slave = [[Slave alloc] initWithFrame:CGRectMake(0.0f, topBarHeight, viewFrame.size.width, viewFrame.size.height - topBarHeight) withMaster:self];
	[self.view addSubview:slave];
	[slave release];

	// Define and display the loading menu
	menuLoading = [[MenuLoading alloc] initWithFrame:viewFrame withTitle:[slave title]];
	[self.view addSubview:menuLoading];
	[menuLoading release];

	// Define and hide the help menu
	menuHelp = [[MenuHelp alloc] initWithFrame:viewFrame];
	[menuHelp setText:[slave helpText]];
	menuHelp.hidden = YES;
	[self.view addSubview:menuHelp];
	[menuHelp release];

	// Initialize the game
	[self changeToUser:nil];
}

- (void)slaveRestarted
{
	slaveRestarting = NO;
}

- (void)restartSlave
{
	// Create a new slave view
	UIView<SlaveProtocol>* slaveRefreshed = [[Slave alloc] initWithFrame:slave.frame withMaster:self];
	[self.view insertSubview:slaveRefreshed belowSubview:slave];
	[slaveRefreshed release];

	// Remove the previous slave view
	[slave removeFromSuperview];
	slave = slaveRefreshed;
	slaveRestarting = YES;

	// Set the help
	[menuHelp setText:[slave helpText]];

	// Animate the transition
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(slaveRestarted)];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view cache:YES];
	[UIView commitAnimations];
}

- (unsigned int)frameRate
{
	return [slave frameRate];
}

- (void)update
{
	// Check whether the view is hidden or not, and whether the slave is being restarted
	if(!(self.view.hidden || slaveRestarting))
	{
		// Check whether the loading menu is being shown
		if(menuLoading)
		{
			// Hide the loading menu
			[Master animateView:menuLoading setHidden:YES];
			menuLoading = nil;

			// Show the coins label
			[Master animateView:barLabelCoins setHidden:NO];

			// Show the help menu
			[Master animateView:menuHelp setHidden:NO];
		}

		// Animate the coins label
		if(barLabelCoinsTimer)
		{
			--barLabelCoinsTimer;
			barLabelCoins.glow = !(((barLabelCoinsTimer * 15) / [slave frameRate]) & 1);
		}

		// Update the slave view
		[slave update];
	}
}

- (void)resume
{
	// Resume the scrolling in the help menu, if needed
	[menuHelp animate];
}

- (void)showHelp
{
	// Show the help menu
	[Master animateView:menuHelp setHidden:NO];
}

- (NSInteger)addCoins:(NSInteger)amount
{
	// Update the count of coins
	NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
	NSInteger coins = [userDefaults integerForKey:savingKeyCoins];
	if(amount)
	{
		coins += amount;
		[userDefaults setInteger:coins forKey:savingKeyCoins];
		barLabelCoinsTimer = [slave frameRate] * 2;
	}

	// Upate the coins label
	if(coins >= 0)
	{
		barLabelCoins.text = [NSString stringWithFormat:@"COINS\n$%d", coins];
	}
	else
	{
		barLabelCoins.text = [NSString stringWithFormat:@"COINS\n-$%d", -coins];
	}

	// Return the count of coins
	return coins;
}

- (NSInteger)playGameWithCoins:(NSInteger)amount
{
	// DEBUG: display the memory usage
	NSLog(@"Memory usage: %u", [Master memoryUsage]);

	// Insert a coin
	[self addCoins:-amount];

	// Update and return the count of games
	NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
	NSInteger const games = [userDefaults integerForKey:savingKeyGames] + 1;
	[userDefaults setInteger:games forKey:savingKeyGames];
	return games;
}

- (void)changeToUser:(NSString*)userId
{
	// Set the default user ID if needed
	if(!userId)
	{
		userId = @"0";
	}

	// Check whether there is a change of user
	if(!savingUserId || [savingUserId compare:userId] != NSOrderedSame)
	{
		// Take note of the ID of the user
		[savingUserId release];
		savingUserId = [userId copy];

		// Set the saving keys
		[savingKeyCoins release];
		savingKeyCoins = [[NSString alloc] initWithFormat:@"COINS_%@", userId];
		[savingKeyGames release];
		savingKeyGames = [[NSString alloc] initWithFormat:@"GAMES_%@", userId];

		// Notify the slave view
		[slave changeToUser:userId];

		// Upate the coins label
		[self addCoins:0];
	}
}

- (void)dealloc
{
	// Release the saving keys
	[savingKeyGames release];
	[savingKeyCoins release];

	// Release the saving user ID
	[savingUserId release];

	// Release the view
	[self.view release];

	// Destroy everything else
	[super dealloc];
}

@end
