#import "errorView.h"

#define BOX_WIDTH     240.0f
#define BOX_HEIGHT    200.0f
#define BOX_MARGIN    10.0f
#define BOX_THICKNESS 10.0f

#define BUTTON_WIDTH  60.0f
#define BUTTON_HEIGHT 31.0f

#define LABEL_WIDTH  (BOX_WIDTH - BOX_THICKNESS * 2 - BOX_MARGIN * 2)
#define LABEL_HEIGHT (BOX_HEIGHT - BOX_THICKNESS * 2 - BOX_MARGIN * 3 - BUTTON_HEIGHT)

static CGFloat const boxColorsOuter[12] = {0.4f, 0.2f, 0.1f, 0.8f, 1.0f, 0.5f, 0.25f, 0.8f, 0.6f, 0.3f, 0.15f, 0.8f};
static CGFloat const boxColorsInner[8] = {0.4f, 0.1f, 0.1f, 0.8f, 0.8f, 0.2f, 0.2f, 0.8f};

@implementation ErrorView

@synthesize label;

- (id)initWithFrame:(CGRect)frame withController:(UIViewController*)controller
{
	if(self = [super initWithFrame:frame])
	{
		// Set the background color
		self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.8f];

		// Define the box paths
		boxTop = (frame.size.height - BOX_HEIGHT) / 2;
		boxBottom = boxTop + BOX_HEIGHT;
		CGFloat const boxLeft = (frame.size.width - BOX_WIDTH) / 2;
		CGFloat const boxRight = boxLeft + BOX_WIDTH;

		boxPathOuter = CGPathCreateMutable();
		CGPathMoveToPoint(boxPathOuter, NULL, boxLeft + BOX_THICKNESS, boxTop);
		CGPathAddArcToPoint(boxPathOuter, NULL, boxRight, boxTop, boxRight, boxBottom, BOX_THICKNESS);
		CGPathAddArcToPoint(boxPathOuter, NULL, boxRight, boxBottom, boxLeft, boxBottom, BOX_THICKNESS);
		CGPathAddArcToPoint(boxPathOuter, NULL, boxLeft, boxBottom, boxLeft, boxTop, BOX_THICKNESS);
		CGPathAddArcToPoint(boxPathOuter, NULL, boxLeft, boxTop, boxRight, boxTop, BOX_THICKNESS);

		boxPathInner = CGPathCreateMutable();
		CGPathAddRect(boxPathInner, NULL, CGRectMake(boxLeft + BOX_THICKNESS, boxTop + BOX_THICKNESS, BOX_WIDTH - BOX_THICKNESS * 2, BOX_HEIGHT - BOX_THICKNESS * 2));

		// Define the box gradient
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		boxGradientOuter = CGGradientCreateWithColorComponents(colorSpace, boxColorsOuter, NULL, 3);
		boxGradientInner = CGGradientCreateWithColorComponents(colorSpace, boxColorsInner, NULL, 2);
		CGColorSpaceRelease(colorSpace);

		// Add the label
		label = [[UILabel alloc] initWithFrame:CGRectMake(boxLeft + BOX_THICKNESS + BOX_MARGIN, boxTop + BOX_THICKNESS + BOX_MARGIN, LABEL_WIDTH, LABEL_HEIGHT)];
		label.backgroundColor = [UIColor clearColor];
		label.textColor = [UIColor whiteColor];
		label.textAlignment = UITextAlignmentCenter;
		label.numberOfLines = 0;
		[self addSubview:label];
		[label release];

		// Add the button
		UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[button setFrame:CGRectMake(boxRight - BOX_THICKNESS - BOX_MARGIN - BUTTON_WIDTH, boxBottom - BOX_THICKNESS - BOX_MARGIN - BUTTON_HEIGHT, BUTTON_WIDTH, BUTTON_HEIGHT)];
		[button setTitle:@"OK" forState:UIControlStateNormal];
		[button addTarget:controller action:@selector(errorOk) forControlEvents:UIControlEventTouchDown];
		[self addSubview:button];
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Draw the box
	CGContextSaveGState(context);
	CGContextAddPath(context, boxPathInner);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, boxGradientInner, CGPointMake(0.0f, boxTop), CGPointMake(0.0f, boxBottom), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);

	CGContextSaveGState(context);
	CGContextAddPath(context, boxPathOuter);
	CGContextAddPath(context, boxPathInner);
	CGContextEOClip(context);
	CGContextDrawLinearGradient(context, boxGradientOuter, CGPointMake(0.0f, boxTop), CGPointMake(0.0f, boxBottom), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
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
	// Release the box gradients
	CGGradientRelease(boxGradientInner);
	CGGradientRelease(boxGradientOuter);

	// Release the box paths
	CGPathRelease(boxPathInner);
	CGPathRelease(boxPathOuter);

	// Destroy everything else
	[super dealloc];
}

@end
