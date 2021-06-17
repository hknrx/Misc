#import "OpenFeint+Dashboard.h"
#import "OpenFeintLocalSettings.h"
#import "OFPaginatedSeries.h"
#import "OFHighScoreService.h"
#import "OFHighScore.h"
#import "Menu.h"
#import "Label.h"
#import "Button.h"

#ifdef FLAMIN_MAZE_GIANT
	#define HELP_HEIGHT 48.0f
	#define HELP_SPEED  160.0f
#else
	#define HELP_HEIGHT 24.0f
	#define HELP_SPEED  100.0f
#endif
#define HELP_MARGIN HELP_SPEED

@implementation Menu

static CGFloat const boxColors[8] = {0.5f, 0.5f, 1.0f, 0.5f, 0.3f, 0.3f, 0.6f, 0.5f};

@synthesize openFeintLeaderboardId;

- (id)initWithFrame:(CGRect)frame withSize:(CGSize)size withTitle:(NSString*)title inRectangle:(CGRect)titleRect
{
	if(self = [super initWithFrame:frame])
	{
		// Set the colors
		self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
		labelColor = [UIColor colorWithRed:1.0f green:0.2f blue:0.5f alpha:1.0f];

		// Define the box outer path
		boxTop = (frame.size.height - size.height) / 2;
		boxBottom = boxTop + size.height;
		boxLeft = (frame.size.width - size.width) / 2;
		boxRight = boxLeft + size.width;

		boxPathOuter = CGPathCreateMutable();
		CGPathMoveToPoint(boxPathOuter, NULL, boxLeft + BOX_RADIUS + BOX_THICKNESS, boxTop);
		CGPathAddArcToPoint(boxPathOuter, NULL, boxRight, boxTop, boxRight, boxBottom, BOX_RADIUS + BOX_THICKNESS);
		CGPathAddArcToPoint(boxPathOuter, NULL, boxRight, boxBottom, boxLeft, boxBottom, BOX_RADIUS + BOX_THICKNESS);
		CGPathAddArcToPoint(boxPathOuter, NULL, boxLeft, boxBottom, boxLeft, boxTop, BOX_RADIUS + BOX_THICKNESS);
		CGPathAddArcToPoint(boxPathOuter, NULL, boxLeft, boxTop, boxRight, boxTop, BOX_RADIUS + BOX_THICKNESS);

		// Define the box inner path
		CGFloat const boxInnerTop = boxTop + BOX_THICKNESS;
		CGFloat const boxInnerBottom = boxBottom - BOX_THICKNESS;
		CGFloat const boxInnerLeft = boxLeft + BOX_THICKNESS;
		CGFloat const boxInnerRight = boxRight - BOX_THICKNESS;

		boxPathInner = CGPathCreateMutable();
		CGPathMoveToPoint(boxPathInner, NULL, boxInnerLeft + BOX_RADIUS, boxInnerTop);
		CGPathAddArcToPoint(boxPathInner, NULL, boxInnerRight, boxInnerTop, boxInnerRight, boxInnerBottom, BOX_RADIUS);
		CGPathAddArcToPoint(boxPathInner, NULL, boxInnerRight, boxInnerBottom, boxInnerLeft, boxInnerBottom, BOX_RADIUS);
		CGPathAddArcToPoint(boxPathInner, NULL, boxInnerLeft, boxInnerBottom, boxInnerLeft, boxInnerTop, BOX_RADIUS);
		CGPathAddArcToPoint(boxPathInner, NULL, boxInnerLeft, boxInnerTop, boxInnerRight, boxInnerTop, BOX_RADIUS);

		// Define the box gradient
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		boxGradient = CGGradientCreateWithColorComponents(colorSpace, boxColors, NULL, 2);
		CGColorSpaceRelease(colorSpace);

		// Add the title label
		titleRect.origin.x += boxLeft;
		titleRect.origin.y += boxTop;
		titleLabel = [[Label alloc] initWithFrame:titleRect withSize:FONT_SIZE * 1.6f withColor:labelColor];
		titleLabel.text = title;
		titleLabel.textAlignment = UITextAlignmentCenter;
		titleLabel.numberOfLines = 0;
		titleLabel.glow = YES;
		[self addSubview:titleLabel];
		[titleLabel release];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame withParent:(id)parent
{
	return nil;
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Draw the box
	CGContextSaveGState(context);
	CGContextAddPath(context, boxPathInner);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, boxGradient, CGPointMake(0.0f, boxTop), CGPointMake(0.0f, boxBottom), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);

	CGContextAddPath(context, boxPathOuter);
	CGContextAddPath(context, boxPathInner);
	CGContextSetRGBFillColor(context, 0.8f, 0.8f, 1.0f, 0.5f);
	CGContextEOFillPath(context);
}

- (void)setTitle:(NSString*)title
{
	titleLabel.text = title;
}

- (void)addOpenFeintButtonInRectangle:(CGRect)rect
{
	openFeintButton = [[Button alloc] initWithColor:[UIColor greenColor] withText:openFeintDefaultLabel withFontSize:FONT_SIZE inRectangle:rect withTarget:self withSelector:@selector(handleOpenFeintButton)];
	openFeintButton.label.glow = YES;
	[self addSubview:openFeintButton];
	[openFeintButton release];

	UIImageView* openFeintImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"OpenFeint.png"]];
	openFeintImage.center = CGPointMake(rect.size.height / 2, rect.size.height / 2);
	[openFeintButton addSubview:openFeintImage];
	[openFeintImage release];

	CGFloat const openFeintLabelShift = (rect.size.height + openFeintImage.image.size.width) / 2;
	CGRect openFeintLabelFrame = openFeintButton.label.frame;
	openFeintLabelFrame.origin.x += openFeintLabelShift;
	openFeintLabelFrame.size.width -= openFeintLabelShift;
	openFeintButton.label.frame = openFeintLabelFrame;
}

- (void)updateOpenFeintButtonWithLeaderboardId:(NSString*)leaderboardId
{
	openFeintLeaderboardId = leaderboardId;
	[OFHighScoreService getLocalHighScores:leaderboardId onSuccess:OFDelegate(self, @selector(gotHighScore:)) onFailure:OFDelegate()];
}

- (void)handleOpenFeintButton
{
	if(openFeintLeaderboardId)
	{
		[OpenFeint launchDashboardWithHighscorePage:openFeintLeaderboardId];
	}
	else
	{
		[OpenFeint launchDashboard];
	}
}

- (BOOL)canReceiveCallbacksNow
{
	return YES;
}

- (void)gotHighScore:(OFPaginatedSeries*)page
{
	if([page count])
	{
		openFeintButton.label.text = [NSString stringWithFormat:@"BEST: %d", ((OFHighScore*)[page objectAtIndex:0]).score];
	}
	else
	{
		openFeintButton.label.text = openFeintDefaultLabel;
	}
}

- (void)addHelpText:(NSString*)helpText
{
	if(!helpView)
	{
		helpView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, self.frame.size.height - HELP_HEIGHT, self.frame.size.width, HELP_HEIGHT)];
		helpView.clipsToBounds = YES;
		[self addSubview:helpView];
		[helpView release];
	}

	[helpLabel removeFromSuperview];
	helpLabel = [[Label alloc] initWithFrame:CGRectNull withSize:FONT_SIZE withColor:[UIColor blueColor]];
	helpLabel.text = helpText;
	helpLabel.glow = YES;
	[helpView addSubview:helpLabel];
	[helpLabel release];

	CGSize const helpLabelSize = [helpLabel.text sizeWithFont:helpLabel.font];
	helpLabel.frame = CGRectMake(0.0f, 0.0f, helpLabelSize.width, helpView.frame.size.height);
	helpLabel.transform = CGAffineTransformTranslate(helpView.transform, helpView.frame.size.width + HELP_MARGIN, 0.0f);
}

- (void)hideHelp:(BOOL)hidden
{
	if(helpLabel)
	{
		[UIView beginAnimations:@"help" context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		if(hidden)
		{
			[UIView setAnimationDuration:0.0f];
			[UIView setAnimationRepeatCount:0.0f];
			helpLabel.transform = CGAffineTransformTranslate(helpView.transform, helpView.frame.size.width + HELP_MARGIN, 0.0f);
		}
		else
		{
			[UIView setAnimationCurve:UIViewAnimationCurveLinear];
			[UIView setAnimationDuration:(helpLabel.frame.size.width + HELP_MARGIN + helpView.frame.size.width) / HELP_SPEED];
			[UIView setAnimationRepeatCount:FLT_MAX];
			helpLabel.transform = CGAffineTransformTranslate(helpView.transform, -helpLabel.frame.size.width, 0.0f);
		}
		[UIView commitAnimations];
	}
}

- (void)setHidden:(BOOL)hidden
{
	[self hideHelp:hidden];
	super.hidden = hidden;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
}

- (void)dealloc
{
	// Release the OpenFeint leaderboard ID
	[openFeintLeaderboardId release];

	// Release the box gradient
	CGGradientRelease(boxGradient);

	// Release the box paths
	CGPathRelease(boxPathInner);
	CGPathRelease(boxPathOuter);

	// Destroy everything else
	[super dealloc];
}

@end
