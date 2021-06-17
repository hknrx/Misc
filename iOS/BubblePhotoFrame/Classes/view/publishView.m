#import "publishView.h"

#define BUTTON_MARGIN 20.0f
#define BUTTON_WIDTH  110.0f
#define BUTTON_HEIGHT 46.0f

#define SCREENSHOT_THICKNESS 10.0f
#define SCREENSHOT_MARGIN    (BUTTON_MARGIN * 2 + BUTTON_HEIGHT)
#define SCREENSHOT_TOP       SCREENSHOT_MARGIN

static CGFloat const screenshotBorderColors[12] = {0.1f, 0.1f, 0.4f, 0.8f, 0.2f, 0.2f, 0.8f, 0.8f, 0.15f, 0.15f, 0.6f, 0.8f};

@implementation PublishView

- (id)initWithFrame:(CGRect)frame withController:(UIViewController*)controller
{
	if(self = [super initWithFrame:frame])
	{
		// Set the background color
		self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.8f];

		// Add the screenshot holder
		CGFloat const screenshotBottom = frame.size.height - SCREENSHOT_MARGIN;
		CGFloat const screenshotHeight = screenshotBottom - SCREENSHOT_TOP;
		CGFloat const screenshotWidth = frame.size.width * screenshotHeight / frame.size.height;
		CGFloat const screenshotLeft = (frame.size.width - screenshotWidth) / 2;
		CGFloat const screenshotRight = screenshotLeft + screenshotWidth;
		screenshotImage = [[UIImageView alloc] initWithFrame:CGRectMake(screenshotLeft + SCREENSHOT_THICKNESS, SCREENSHOT_TOP + SCREENSHOT_THICKNESS, screenshotWidth - SCREENSHOT_THICKNESS * 2, screenshotHeight - SCREENSHOT_THICKNESS * 2)];
		[self addSubview:screenshotImage];
		[screenshotImage release];

		// Define the screenshot border path
		screenshotBorderPath = CGPathCreateMutable();
		CGPathMoveToPoint(screenshotBorderPath, NULL, screenshotLeft + SCREENSHOT_THICKNESS, SCREENSHOT_TOP);
		CGPathAddArcToPoint(screenshotBorderPath, NULL, screenshotRight, SCREENSHOT_TOP, screenshotRight, screenshotBottom, SCREENSHOT_THICKNESS);
		CGPathAddArcToPoint(screenshotBorderPath, NULL, screenshotRight, screenshotBottom, screenshotLeft, screenshotBottom, SCREENSHOT_THICKNESS);
		CGPathAddArcToPoint(screenshotBorderPath, NULL, screenshotLeft, screenshotBottom, screenshotLeft, SCREENSHOT_TOP, SCREENSHOT_THICKNESS);
		CGPathAddArcToPoint(screenshotBorderPath, NULL, screenshotLeft, SCREENSHOT_TOP, screenshotRight, SCREENSHOT_TOP, SCREENSHOT_THICKNESS);
		CGPathAddRect(screenshotBorderPath, NULL, screenshotImage.frame);

		// Define the screenshot border gradient
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		screenshotBorderGradient = CGGradientCreateWithColorComponents(colorSpace, screenshotBorderColors, NULL, 3);
		CGColorSpaceRelease(colorSpace);

		// Add the cancel button
		CGFloat const buttonTop = frame.size.height - BUTTON_MARGIN - BUTTON_HEIGHT;
		CGFloat const buttonGap = (frame.size.width - 2 * BUTTON_WIDTH) / 3;
		UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[button setFrame:CGRectMake(buttonGap, buttonTop, BUTTON_WIDTH, BUTTON_HEIGHT)];
		[button setTitle:@"CANCEL" forState:UIControlStateNormal];
		[button addTarget:controller action:@selector(publishCancel) forControlEvents:UIControlEventTouchDown];
		[self addSubview:button];

		// Add the publish button
		button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[button setFrame:CGRectMake(buttonGap + BUTTON_WIDTH + buttonGap, buttonTop, BUTTON_WIDTH, BUTTON_HEIGHT)];
		[button setTitle:@"PUBLISH TO FACEBOOK" forState:UIControlStateNormal];
		button.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
		button.titleLabel.textAlignment = UITextAlignmentCenter;
		[button addTarget:controller action:@selector(publishDo) forControlEvents:UIControlEventTouchDown];
		[self addSubview:button];
	}
	return self;
}

- (UIImage*)screenshot
{
	return screenshotImage.image;
}

- (void)setScreenshot:(UIImage*)image
{
	screenshotImage.image = image;
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Draw the screenshot border
	CGContextSaveGState(context);
	CGContextAddPath(context, screenshotBorderPath);
	CGContextEOClip(context);
	CGContextDrawLinearGradient(context, screenshotBorderGradient, screenshotImage.frame.origin, CGPointMake(screenshotImage.frame.origin.x, screenshotImage.frame.origin.y + screenshotImage.frame.size.height), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);
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
	// Release the screenshot border gradient
	CGGradientRelease(screenshotBorderGradient);

	// Release the screenshot border path
	CGPathRelease(screenshotBorderPath);

	// Destroy everything else
	[super dealloc];
}

@end
