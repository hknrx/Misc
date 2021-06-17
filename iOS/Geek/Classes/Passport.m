#import "Passport.h"
#import "Master.h"
#import "Test.h"

#define screenWidth  320.0f
#define screenHeight (480.0f - 44.0f)

#define passportWidth        280.0f
#define passportHeight       400.0f
#define passportLeft         ((screenWidth - passportWidth) / 2)
#define passportRight        (passportLeft + passportWidth)
#define passportTop          ((screenHeight - passportHeight) / 2)
#define passportBottom       (passportTop + passportHeight)
#define passportCenterX      (passportLeft + passportWidth / 2)
#define passportCenterY      (passportTop + passportHeight / 2)
#define passportCornerRadius 30.0f

#define passportTextMargin 15.0f
#define passportTextLeft   (passportLeft + passportTextMargin)
#define passportTextRight  (passportRight - passportTextMargin)
#define passportTextTop    (passportTop + passportTextMargin)
#define passportTextBottom (passportBottom - passportTextMargin)

#define passportTitleWidth  (passportTextRight - passportTextLeft)
#define passportTitleHeight 30.0f
#define passportTitleLeft   ((passportTextLeft + passportTextRight - passportTitleWidth) / 2)
#define passportTitleTop    passportTextTop
#define passportTitleBottom (passportTextTop + passportTitleHeight)

#define passportCategoryWidth  180.0f
#define passportCategoryHeight 16.0f
#define passportCategoryLeft   passportTextLeft
#define passportItemWidth      150.0f
#define passportItemHeight     17.0f
#define passportItemMargin     10.0f
#define passportItemLeft       (passportCategoryLeft + passportItemMargin)
#define passportStatisticLeft  (passportItemLeft + passportItemWidth)
#define passportStatisticWidth (passportTextRight - passportStatisticLeft)
#define passportPublishWidth   (passportTextRight - passportTextLeft - passportCategoryWidth)
#define passportPublishLeft    (passportTextRight - passportPublishWidth)

#define passportGeneralItemCount   3
#define passportFunfairItemCount   8
#define passportNerdTestItemCount  4
#define passportGeneralItemHeight  (passportItemHeight * passportGeneralItemCount)
#define passportFunfairItemHeight  (passportItemHeight * passportFunfairItemCount)
#define passportNerdTestItemHeight (passportItemHeight * passportNerdTestItemCount)
#define passportCategoryGap        ((passportTextBottom - passportTitleBottom - passportGeneralItemHeight - passportFunfairItemHeight - passportNerdTestItemHeight) / 3 - passportCategoryHeight)

#define passportGeneralCategoryTop  (passportTitleBottom + passportCategoryGap)
#define passportGeneralItemTop      (passportGeneralCategoryTop + passportCategoryHeight)
#define passportFunfairCategoryTop  (passportGeneralItemTop + passportGeneralItemHeight + passportCategoryGap)
#define passportFunfairItemTop      (passportFunfairCategoryTop + passportCategoryHeight)
#define passportNerdTestCategoryTop (passportFunfairItemTop + passportFunfairItemHeight + passportCategoryGap)
#define passportNerdTestItemTop     (passportNerdTestCategoryTop + passportCategoryHeight)

@implementation Passport

- (NSString*)helpText
{
	return @"Just enjoy the available statistics and tap any of the PUBLISH labels to display a feed on your Facebook page!";
}

- (NSString*)infoText
{
	return @"Because Geeks love numbers, they like having statistics for everything and nothing. Luckily, Geek System does record many figures for them to enjoy!";
}

+ (NSString*)menuName
{
	return @"Passport";
}

+ (BarContent)barContent
{
	return BAR_FACEBOOK;
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Make sure the view is transparent
		self.backgroundColor = [UIColor clearColor];

		// Define the passport
		passportPath = CGPathCreateMutable();
		CGPathMoveToPoint(passportPath, NULL, passportLeft, passportTop);
		CGPathAddArcToPoint(passportPath, NULL, passportRight, passportTop, passportRight, passportBottom, passportCornerRadius);
		CGPathAddArcToPoint(passportPath, NULL, passportRight, passportBottom, passportLeft, passportBottom, passportCornerRadius);
		CGPathAddLineToPoint(passportPath, NULL, passportLeft, passportBottom);
		CGPathCloseSubpath(passportPath);

		// Display the title
		UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(passportTitleLeft, passportTitleTop, passportTitleWidth, passportTitleHeight)];
		label.text = @"PASSPORT";
		label.textAlignment = UITextAlignmentCenter;
		label.font = [UIFont fontWithName:@"Arial-BoldMT" size:28.0f];
		[self addSubview:label];
		[label release];

		// Set 2 fonts
		UIFont* fontArial = [UIFont fontWithName:@"Arial" size:14.0f];
		UIFont* fontArialBold = [UIFont fontWithName:@"Arial-BoldMT" size:14.0f];

		// Display the categories
		label = [[UILabel alloc] initWithFrame:CGRectMake(passportCategoryLeft, passportGeneralCategoryTop, passportCategoryWidth, passportCategoryHeight)];
		label.backgroundColor = [UIColor clearColor];
		label.text = @"GENERAL";
		label.font = fontArialBold;
		[self addSubview:label];
		[label release];

		label = [[UILabel alloc] initWithFrame:CGRectMake(passportCategoryLeft, passportFunfairCategoryTop, passportCategoryWidth, passportCategoryHeight)];
		label.backgroundColor = [UIColor clearColor];
		label.text = @"FUNFAIR ACHIEVEMENTS";
		label.font = fontArialBold;
		[self addSubview:label];
		[label release];

		label = [[UILabel alloc] initWithFrame:CGRectMake(passportCategoryLeft, passportNerdTestCategoryTop, passportCategoryWidth, passportCategoryHeight)];
		label.backgroundColor = [UIColor clearColor];
		label.text = @"NERD TEST RESULTS";
		label.font = fontArialBold;
		[self addSubview:label];
		[label release];

		// Display the items
		label = [[UILabel alloc] initWithFrame:CGRectMake(passportItemLeft, passportGeneralItemTop, passportItemWidth, passportGeneralItemHeight)];
		label.backgroundColor = [UIColor clearColor];
		label.text = @"Total uptime\nNumber of launches\nFavorite Geek App";
		label.numberOfLines = 0;
		label.font = fontArial;
		[self addSubview:label];
		[label release];

		label = [[UILabel alloc] initWithFrame:CGRectMake(passportItemLeft, passportFunfairItemTop, passportItemWidth, passportFunfairItemHeight)];
		label.backgroundColor = [UIColor clearColor];
		label.text = @"Money spent\nMoney won\nStack Game play count\n   Minor prizes\n   Major prizes\nTime Master play count\n   Minor prizes\n   Major prizes";
		label.numberOfLines = 0;
		label.font = fontArial;
		[self addSubview:label];
		[label release];

		label = [[UILabel alloc] initWithFrame:CGRectMake(passportItemLeft, passportNerdTestItemTop, passportItemWidth, passportNerdTestItemHeight)];
		label.backgroundColor = [UIColor clearColor];
		label.text = @"Test count\nQuestions\nCorrect answers\nAverage score";
		label.numberOfLines = 0;
		label.font = fontArial;
		[self addSubview:label];
		[label release];

		// Get the statistics
		NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];

		NSInteger const funfairStackCount = [userDefaults integerForKey:@"FUNFAIR_STACK_COUNT"];
		NSInteger const funfairStackMinor = [userDefaults integerForKey:@"FUNFAIR_STACK_MINOR"];
		NSInteger const funfairStackMinorPercentage = funfairStackCount ? (funfairStackMinor * 100) / funfairStackCount : 0;
		NSInteger const funfairStackMajor = [userDefaults integerForKey:@"FUNFAIR_STACK_MAJOR"];
		NSInteger const funfairStackMajorPercentage = funfairStackCount ? (funfairStackMajor * 100) / funfairStackCount : 0;
		NSInteger const funfairTimeCount = [userDefaults integerForKey:@"FUNFAIR_TIME_COUNT"];
		NSInteger const funfairTimeMinor = [userDefaults integerForKey:@"FUNFAIR_TIME_MINOR"];
		NSInteger const funfairTimeMinorPercentage = funfairTimeCount ? (funfairTimeMinor * 100) / funfairTimeCount : 0;
		NSInteger const funfairTimeMajor = [userDefaults integerForKey:@"FUNFAIR_TIME_MAJOR"];
		NSInteger const funfairTimeMajorPercentage = funfairTimeCount ? (funfairTimeMajor * 100) / funfairTimeCount : 0;
		NSInteger const funfairCashCurrent = [userDefaults integerForKey:@"CASH"];
		NSInteger const funfairCashSpent = funfairStackCount + funfairTimeCount;
		NSInteger const funfairCashWon = funfairCashCurrent + funfairCashSpent;

		NSInteger const nerdTestNumber = [userDefaults integerForKey:@"TEST_NUMBER"];
		NSInteger const nerdTestQuestionCount = [Test questionCountForTestCount:nerdTestNumber];
		NSInteger const nerdTestCorrectCount = [userDefaults integerForKey:@"TEST_CORRECT"];
		NSInteger const nerdTestPercentage = nerdTestQuestionCount ? (nerdTestCorrectCount * 100) / nerdTestQuestionCount : 0;
		NSString const*const nerdTestAverage = [Test scoreForCorrectAnswerCount:nerdTestCorrectCount inTestCount:nerdTestNumber];

		// Display the statistics
		passportGeneralLabel = [[UILabel alloc] initWithFrame:CGRectMake(passportStatisticLeft, passportGeneralItemTop, passportStatisticWidth, passportGeneralItemHeight - passportItemHeight)];
		passportGeneralLabel.backgroundColor = [UIColor clearColor];
		passportGeneralLabel.textAlignment = UITextAlignmentRight;
		passportGeneralLabel.textColor = [UIColor purpleColor];
		passportGeneralLabel.numberOfLines = 0;
		passportGeneralLabel.font = fontArial;
		[self addSubview:passportGeneralLabel];
		[passportGeneralLabel release];

		passportGeneralButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[passportGeneralButton setFrame:CGRectMake(passportStatisticLeft, passportGeneralItemTop + 2 * passportItemHeight, passportStatisticWidth, passportItemHeight)];
		passportGeneralButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
		passportGeneralButton.titleLabel.font = fontArial;
		passportGeneralButton.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
		[self addSubview:passportGeneralButton];

		label = [[UILabel alloc] initWithFrame:CGRectMake(passportStatisticLeft, passportFunfairItemTop, passportStatisticWidth, passportFunfairItemHeight)];
		label.backgroundColor = [UIColor clearColor];
		label.text = [NSString stringWithFormat:@"$%d\n$%d\n%d\n%d (%d%%)\n%d (%d%%)\n%d\n%d (%d%%)\n%d (%d%%)", funfairCashSpent, funfairCashWon, funfairStackCount, funfairStackMinor, funfairStackMinorPercentage, funfairStackMajor, funfairStackMajorPercentage, funfairTimeCount, funfairTimeMinor, funfairTimeMinorPercentage, funfairTimeMajor, funfairTimeMajorPercentage];
		label.textAlignment = UITextAlignmentRight;
		label.textColor = [UIColor purpleColor];
		label.numberOfLines = 0;
		label.font = fontArial;
		[self addSubview:label];
		[label release];

		label = [[UILabel alloc] initWithFrame:CGRectMake(passportStatisticLeft, passportNerdTestItemTop, passportStatisticWidth, passportNerdTestItemHeight)];
		label.backgroundColor = [UIColor clearColor];
		label.text = [NSString stringWithFormat:@"%d\n%d\n%d (%d%%)\n%@", nerdTestNumber, nerdTestQuestionCount, nerdTestCorrectCount, nerdTestPercentage, nerdTestAverage];
		label.textAlignment = UITextAlignmentRight;
		label.textColor = [UIColor purpleColor];
		label.numberOfLines = 0;
		label.font = fontArial;
		[self addSubview:label];
		[label release];

		// Add the publish buttons
		UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
		[button setFrame:CGRectMake(passportPublishLeft, passportGeneralCategoryTop, passportPublishWidth, passportCategoryHeight)];
		[button setTitle:@"PUBLISH" forState:UIControlStateNormal];
		button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
		button.titleLabel.font = fontArialBold;
		button.titleLabel.alpha = 0.66f;
		[button addTarget:nil action:@selector(facebookPublishGeneral) forControlEvents:UIControlEventTouchDown];
		[self addSubview:button];

		button = [UIButton buttonWithType:UIButtonTypeCustom];
		[button setFrame:CGRectMake(passportPublishLeft, passportFunfairCategoryTop, passportPublishWidth, passportCategoryHeight)];
		[button setTitle:@"PUBLISH" forState:UIControlStateNormal];
		button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
		button.titleLabel.font = fontArialBold;
		button.titleLabel.alpha = 0.66f;
		[button addTarget:nil action:@selector(facebookPublishFunfair) forControlEvents:UIControlEventTouchDown];
		[self addSubview:button];

		button = [UIButton buttonWithType:UIButtonTypeCustom];
		[button setFrame:CGRectMake(passportPublishLeft, passportNerdTestCategoryTop, passportPublishWidth, passportCategoryHeight)];
		[button setTitle:@"PUBLISH" forState:UIControlStateNormal];
		button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
		button.titleLabel.font = fontArialBold;
		button.titleLabel.alpha = 0.66f;
		[button addTarget:nil action:@selector(facebookPublishNerdTest) forControlEvents:UIControlEventTouchDown];
		[self addSubview:button];
	}
	return self;
}

- (void)willMoveToSuperview:(UIView*)superView
{
	// Make sure that the parent view is a kind of master class
	if([superView isKindOfClass:[Master class]])
	{
		// Get the statistics
		float generalUptimeTotal;
		Class<Slave> const generalFavoriteClass = [(Master*)superView slaveViewFavoriteClassAndTotalUptime:&generalUptimeTotal];
		unsigned int generalUptimeSeconds = generalUptimeTotal;
		unsigned int const generalUptimeHours = generalUptimeSeconds / 3600;
		generalUptimeSeconds -= generalUptimeHours * 3600;
		unsigned int const generalUptimeMinutes = generalUptimeSeconds / 60;
		generalUptimeSeconds -= generalUptimeMinutes * 60;
		NSInteger const generalLaunchCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"LAUNCH_COUNT"];

		// Update the display
		passportGeneralLabel.text = [NSString stringWithFormat:@"%d:%02d:%02d\n%d", generalUptimeHours, generalUptimeMinutes, generalUptimeSeconds, generalLaunchCount];
		[passportGeneralButton setTitle:[generalFavoriteClass menuName] forState:UIControlStateNormal];
		if(generalFavoriteClass == [self class] || [(Master*)superView slaveViewHistoryContainsClass:generalFavoriteClass])
		{
			[passportGeneralButton setTitleColor:[UIColor purpleColor] forState:UIControlStateNormal];
		}
		else
		{
			[passportGeneralButton setTitleColor:[UIColor magentaColor] forState:UIControlStateNormal];
			passportGeneralButton.tag = (NSInteger)generalFavoriteClass;
			[passportGeneralButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
		}
	}
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Display the passport
	CGContextSetRGBFillColor(context, 0.7f, 0.7f, 1.0f, 1.0f);
	CGContextAddPath(context, passportPath);
	CGContextDrawPath(context, kCGPathEOFill);

	static NSString const*const watermark = @":-)";
	UIFont *const font = [UIFont fontWithName:@"Arial-BoldMT" size:220.0f];
	CGSize const size = [watermark sizeWithFont:font];
	CGContextSetRGBFillColor(context, 0.74f, 0.74f, 1.0f, 1.0f);
	[watermark drawAtPoint:CGPointMake(passportCenterX - size.width / 2, passportCenterY - size.height / 2) withFont:font];
}

- (void)buttonPressed:(UIButton*)sender
{
	[(Master*)[self superview] slaveViewSwap:(Class)sender.tag];
}

- (void)dealloc
{
	// Release the path
	CGPathRelease(passportPath);

	// Destroy everything else
	[super dealloc];
}

@end
