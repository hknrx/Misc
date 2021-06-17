#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTimingFunction.h>
#import "Master.h"
#import "Info.h"
#import "MenuMain.h"
#import "Test.h"
#import "Label.h"
#import "Encode.h"

#define UPTIME_DISPLAY_INFO 0.2f

@implementation Master

static NSString *const facebookApiKey = @"5d0020be2f869f1301d42ee8348f4698";
static NSString *const facebookSecretKey = @"9e77419904ca604cb7b3eda8070b877c";
static NSString *const facebookHref = @"http://hknrx.free.fr/geekSystem";
static NSString *const facebookImage = @"http://hknrx.free.fr/geekSystem/facebook.png";

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Initialize the Facebook session
		facebookPublish = FACEBOOK_DONE;
		facebookSession = [[FBSession sessionForApplication:facebookApiKey secret:facebookSecretKey delegate:self] retain];
		[facebookSession resume];

		// Initialize the bar items
		barLabelCoins = [[Label alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 60.0f, 40.0) withSize:14.0f withColor:[UIColor blueColor]];
		barLabelCoins.textAlignment = UITextAlignmentCenter;
		barLabelCoins.numberOfLines = 0;
		barLabelCoins.glow = YES;
		[self cashAdd:0 increaseKey:@"LAUNCH_COUNT"];

		FBLoginButton* barButtonFacebook = [[FBLoginButton alloc] init];

		barButtonItemHelp = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ButtonHelp.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(barButtonHelp)];
		barButtonItemBack = [[UIBarButtonItem alloc] initWithTitle:@"BACK" style:UIBarButtonItemStyleBordered target:self action:@selector(barButtonBack)];
		barButtonItemCoins = [[UIBarButtonItem alloc] initWithCustomView:barLabelCoins];
		barButtonItemFacebook = [[UIBarButtonItem alloc] initWithCustomView:barButtonFacebook];
		barButtonItemInfo = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ButtonInfo.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(barButtonInfo)];
		barButtonItemSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

		[barButtonFacebook release];
		[barLabelCoins release];

		// Initialize the bar view
		barView = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, 44.0f)];
		[barView setBarStyle:UIBarStyleBlack];
		[barView setItems:[NSArray arrayWithObjects:barButtonItemHelp, barButtonItemSpace, barButtonItemInfo, nil] animated:NO];
		[self addSubview:barView];
		[barView release];

		// Initialize the slave view history
		slaveViewHistory = [[NSMutableArray arrayWithCapacity:3] retain];

		// Initialize the slave view with the main menu
		slaveViewTimestamp = [[NSDate date] timeIntervalSince1970];
		slaveView = [[MenuMain alloc] initWithFrame:CGRectMake(0.0f, 44.0f, self.frame.size.width, self.frame.size.height - 44.0f)];
		[self addSubview:slaveView];
		[slaveView release];

		// Initialize the info view container
		infoViewContainer = [[UIView alloc] initWithFrame:frame];
		infoViewContainer.userInteractionEnabled = NO;
		[self addSubview:infoViewContainer];
		[infoViewContainer release];

		// Initialize the info view
		infoView = [[Info alloc] initWithFrame:frame];
		infoViewAutomatic = [[NSUserDefaults standardUserDefaults] floatForKey:NSStringFromClass([slaveView class])] < UPTIME_DISPLAY_INFO;
		if(infoViewAutomatic)
		{
			[self performSelector:@selector(barButtonInfo) withObject:nil afterDelay:0.5f];
		}
	}
	return self;
}

- (void)infoViewToggle
{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5];
	if([infoView superview])
	{
		[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:infoViewContainer cache:YES];
		if(infoViewAutomatic)
		{
			infoViewAutomatic = NO;
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(barButtonHelp)];
		}
		[infoView removeFromSuperview];
		infoViewContainer.userInteractionEnabled = NO;
	}
	else
	{
		[self bringSubviewToFront:infoViewContainer];
		[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:infoViewContainer cache:YES];
		[infoViewContainer addSubview:infoView];
		infoViewContainer.userInteractionEnabled = YES;
	}
	[UIView commitAnimations];
}

- (BOOL)slaveViewHistoryContainsClass:(Class<Slave>)viewClass
{
	return [slaveViewHistory containsObject:viewClass];
}

- (void)slaveViewUpdateUptime
{
	// Get the name of the current slave view class
	NSString *const slaveViewClassName = NSStringFromClass([slaveView class]);

	// Update the uptime of the slave view
	NSTimeInterval const timestampCurrent = [[NSDate date] timeIntervalSince1970];
	NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
	float const uptime = [userDefaults floatForKey:slaveViewClassName] + timestampCurrent - slaveViewTimestamp;
	[userDefaults setFloat:uptime forKey:slaveViewClassName];
	slaveViewTimestamp = timestampCurrent;

	// Add the name of the slave view class to the list of class names (except if it is already in the list)
	NSArray* classNames = [userDefaults stringArrayForKey:@"CLASS_NAMES"];
	if(!classNames)
	{
		[userDefaults setObject:[NSArray arrayWithObject:slaveViewClassName] forKey:@"CLASS_NAMES"];
	}
	else if(![classNames containsObject:slaveViewClassName])
	{
		[userDefaults setObject:[classNames arrayByAddingObject:slaveViewClassName] forKey:@"CLASS_NAMES"];
	}
}

- (Class<Slave>)slaveViewFavoriteClassAndTotalUptime:(float*)uptimeTotal
{
	*uptimeTotal = 0.0f;
	float uptimeBest = -1.0f;
	NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
	NSArray* classNames = [userDefaults stringArrayForKey:@"CLASS_NAMES"];
	NSString* classNameBest;
	for(NSString* className in classNames)
	{
		float const uptime = [userDefaults floatForKey:className];
		*uptimeTotal += uptime;
		if(uptime > uptimeBest)
		{
			uptimeBest = uptime;
			classNameBest = className;
		}
	}
	return NSClassFromString(classNameBest);
}

- (void)slaveViewSwap:(Class)viewClass
{
	// Handle the stack of views
	if(viewClass)
	{
		// Push the current slave view class on the stack
		[slaveViewHistory addObject:[slaveView class]];
	}
	else
	{
		// Pop the class from the stack
		viewClass = [slaveViewHistory lastObject];
		[slaveViewHistory removeLastObject];
	}

	// Update the bar view
	NSMutableArray* barViewItems = [NSMutableArray arrayWithCapacity:7];
	[barViewItems addObject:barButtonItemHelp];
	[barViewItems addObject:barButtonItemSpace];
	if([slaveViewHistory count])
	{
		[barViewItems addObject:barButtonItemBack];
		[barViewItems addObject:barButtonItemSpace];
	}
	BarContent const barContent = [viewClass barContent];
	if(barContent == BAR_COINS)
	{
		[barViewItems addObject:barButtonItemCoins];
		[barViewItems addObject:barButtonItemSpace];
	}
	else if(barContent == BAR_FACEBOOK)
	{
		[barViewItems addObject:barButtonItemFacebook];
		[barViewItems addObject:barButtonItemSpace];
	}
	[barViewItems addObject:barButtonItemInfo];
	[barView setItems:barViewItems animated:NO];

	// Initialize the animation
	infoViewAutomatic = [[NSUserDefaults standardUserDefaults] floatForKey:NSStringFromClass(viewClass)] < UPTIME_DISPLAY_INFO;
	if([viewClass isSubclassOfClass:[Menu class]] && [slaveView isKindOfClass:[Menu class]])
	{
		CATransition* animation = [CATransition animation];
		[animation setDuration:1.0];
		[animation setType:kCATransitionFade];
		[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
		if(infoViewAutomatic)
		{
			[animation setDelegate:self];
		}
		[self.layer addAnimation:animation forKey:nil];
	}
	else
	{
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.5];
		[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self cache:YES];
		if(infoViewAutomatic)
		{
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(barButtonInfo)];
		}
		[UIView commitAnimations];
	}

	// Update the uptime of the current slave view
	[self slaveViewUpdateUptime];

	// Remove the current slave view
	[slaveView removeFromSuperview];

	// Add the new slave view
	slaveView = [[viewClass alloc] initWithFrame:CGRectMake(0.0f, 44.0f, self.frame.size.width, self.frame.size.height - 44.0f)];
	[self addSubview:slaveView];
	[slaveView release];
}

- (void)barButtonHelp
{
	[infoView prepareSlaveView:slaveView displayHelp:YES];
	[self infoViewToggle];
}

- (void)barButtonInfo
{
	[infoView prepareSlaveView:slaveView displayHelp:NO];
	[self infoViewToggle];
}

- (void)barButtonBack
{
	[self slaveViewSwap:nil];
}

- (void)cashAdd:(NSInteger)amount increaseKey:(NSString*)key
{
	NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
	NSInteger cash = [userDefaults integerForKey:@"CASH"];
	if(amount)
	{
		cash += amount;
		[userDefaults setInteger:cash forKey:@"CASH"];
	}
	if(cash >= 0)
	{
		barLabelCoins.text = [NSString stringWithFormat:@"CASH\n$%d", cash];
	}
	else
	{
		barLabelCoins.text = [NSString stringWithFormat:@"CASH\n-$%d", -cash];
	}
	if(key)
	{
		[userDefaults setInteger:[userDefaults integerForKey:key] + 1 forKey:key];
	}
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	if([[event touchesForView:infoView] count])
	{
		[self infoViewToggle];
	}
}

- (void)animationDidStop:(CAAnimation*)animation finished:(BOOL)flag
{
	[self barButtonInfo];
}

- (void)session:(FBSession*)session didLogin:(FBUID)uid
{
	// Check whether something needs to be published
	if(facebookPublish == FACEBOOK_DONE)
	{
		return;
	}

	// Set up and display the appropriate dialog
	FBStreamDialog* faceboookDialog = [[FBStreamDialog alloc] init];
	NSString* caption;
	NSString* description;
	if(facebookPublish == FACEBOOK_PUBLISH_FUNFAIR)
	{
		NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
		NSInteger const funfairCount = [userDefaults integerForKey:@"FUNFAIR_STACK_COUNT"] + [userDefaults integerForKey:@"FUNFAIR_TIME_COUNT"];
		NSInteger const funfairCashCurrent = [userDefaults integerForKey:@"CASH"];
		NSString* captionEnd;
		if(funfairCashCurrent < 0)
		{
			captionEnd = [NSString stringWithFormat:@"is now in debt of %d Geek coin%@! :(", -funfairCashCurrent, funfairCashCurrent < -1 ? @"s" : @""];
		}
		else
		{
			captionEnd = [NSString stringWithFormat:@"now owns %d Geek coin%@!", funfairCashCurrent, funfairCashCurrent > 1 ? @"s" : @""];
		}

		faceboookDialog.userMessagePrompt = @"Publish your Funfair achievements!";
		caption = [NSString stringWithFormat:@"After having played Stack Game and Time Master %d time%@, {*actor*} %@", funfairCount, funfairCount > 1 ? @"s" : @"", captionEnd];
		description = @"How much have you gotten?";
	}
	else if(facebookPublish == FACEBOOK_PUBLISH_NERD_TEST)
	{
		NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
		NSInteger const nerdTestNumber = [userDefaults integerForKey:@"TEST_NUMBER"];
		NSInteger const nerdTestQuestionCount = [Test questionCountForTestCount:nerdTestNumber];
		NSInteger const nerdTestCorrectCount = [userDefaults integerForKey:@"TEST_CORRECT"];
		NSString const*const nerdTestAverage = [Encode urlEncodeString:[Test scoreForCorrectAnswerCount:nerdTestCorrectCount inTestCount:nerdTestNumber]];

		faceboookDialog.userMessagePrompt = @"Publish your Nerd Test results!";
		caption = [NSString stringWithFormat:@"{*actor*} answered %d question%@ of the Nerd Test and found the correct answer %d time%@!", nerdTestQuestionCount, nerdTestQuestionCount > 1 ? @"s" : @"", nerdTestCorrectCount, nerdTestCorrectCount > 1 ? @"s" : @""];
		description = [NSString stringWithFormat:@"Your friend's average score is \\\"%@\\\", what's yours?", nerdTestAverage];
	}
	else
	{
		float generalUptimeTotal;
		Class<Slave> const generalFavoriteClass = [self slaveViewFavoriteClassAndTotalUptime:&generalUptimeTotal];
		unsigned int const generalUptimeMinutes = generalUptimeTotal / 60;

		faceboookDialog.userMessagePrompt = @"Publish your Geek status!";
		caption = [NSString stringWithFormat:@"{*actor*} has already spent %d minute%@ playing Geek System!", generalUptimeMinutes, generalUptimeMinutes > 1 ? @"s" : @""];
		description = [NSString stringWithFormat:@"Your friend's favorite Geek App is \\\"%@\\\", what's yours?", [generalFavoriteClass menuName]];
	}
	faceboookDialog.attachment = [NSString stringWithFormat:
		@"{"
			"\"name\":\"Geek System for iPhone\","
			"\"href\":\"%@\","
			"\"caption\":\"%@\","
			"\"description\":\"%@\","
			"\"media\":[{\"type\":\"image\",\"src\":\"%@\",\"href\":\"%@\"}]"
		"}", facebookHref, caption, description, facebookImage, facebookHref];
	[faceboookDialog show];
	[faceboookDialog release];

	// There is nothing to publish anymore
	facebookPublish = FACEBOOK_DONE;
}

- (void)sessionDidNotLogin:(FBSession*)session
{
	// Nothing can be published at the moment
	facebookPublish = FACEBOOK_DONE;
}

- (void)facebookPublish
{
	// Check whether the player is connected to Facebook
	if(facebookSession.isConnected)
	{
		// Go publish a new stream
		[self session:facebookSession didLogin:facebookSession.uid];
	}
	else
	{
		// Display the login dialog
		FBLoginDialog* faceboookDialog = [[FBLoginDialog alloc] initWithSession:facebookSession];
		[faceboookDialog show];
		[faceboookDialog release];
	}
}

- (void)facebookPublishGeneral
{
	facebookPublish = FACEBOOK_PUBLISH_GENERAL;
	[self facebookPublish];
}

- (void)facebookPublishFunfair
{
	facebookPublish = FACEBOOK_PUBLISH_FUNFAIR;
	[self facebookPublish];
}

- (void)facebookPublishNerdTest
{
	facebookPublish = FACEBOOK_PUBLISH_NERD_TEST;
	[self facebookPublish];
}

- (void)dealloc
{
	[infoView release];
	[slaveViewHistory release];
	[barButtonItemSpace release];
	[barButtonItemInfo release];
	[barButtonItemFacebook release];
	[barButtonItemCoins release];
	[barButtonItemBack release];
	[barButtonItemHelp release];
	[facebookSession release];
	[super dealloc];
}

@end
