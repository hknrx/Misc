#import "Menu.h"
#import "Master.h"

#define screenWidth  320.0f
#define screenHeight (480.0f - 44.0f)

#define monitorMargin 10.0f
#define monitorBottom 40.0f
#define monitorWidth  (screenWidth - monitorMargin * 2)

#define menuEntryHeight   32.0f
#define menuEntryWidth    220.0f
#define menuEntryCountMax 6

#define displayMargin       10.0f
#define displayCornerRadius 30.0f
#define displayWidth        (monitorWidth - displayMargin * 2)
#define displayHeight       (menuEntryHeight * menuEntryCountMax + displayCornerRadius * 2 - menuEntryHeight / 2)
#define displayLeft         (monitorCornerX + displayMargin)
#define displayRight        (displayLeft + displayWidth)
#define displayTop          (monitorCornerY + displayMargin)
#define displayBottom       (displayTop + displayHeight)

#define monitorHeight  (monitorMargin + displayHeight + monitorBottom)
#define monitorCornerX monitorMargin
#define monitorCornerY ((screenHeight - monitorHeight) / 2)

#define menuEntryCornerX (displayLeft + displayCornerRadius)
#define menuEntryCornerY (displayTop + displayCornerRadius - menuEntryHeight / 4)

#define powerLightRadius  10.0f
#define powerLightCenterX (monitorCornerX + monitorWidth - monitorBottom / 2)
#define powerLightCenterY (displayBottom + monitorBottom / 2)

@implementation Menu

static CGFloat const colorsMonitor[12] = {0.1f, 0.1f, 0.1f, 1.0f, 0.2f, 0.2f, 0.3f, 1.0f, 0.1f, 0.1f, 0.2f, 1.0f};
static CGFloat const colorsPowerLight[8] = {0.5f, 1.0f, 0.5f, 1.0f, 0.2f, 0.5f, 0.2f, 0.0f};

- (id)initWithFrame:(CGRect)frame withButtonClasses:(NSArray*)buttonClasses
{
	if(self = [super initWithFrame:frame])
	{
		// Load the keyboard
		keyboardImage = [UIImage imageNamed:@"Keyboard.png"];

		// Define the monitor
		monitorPath = CGPathCreateMutable();
		CGPathAddRect(monitorPath, NULL, CGRectMake(monitorCornerX, monitorCornerY, monitorWidth, monitorHeight));

		// Define the screen
		screenPath = CGPathCreateMutable();
		CGPathMoveToPoint(screenPath, NULL, displayLeft + displayCornerRadius, displayTop);
		CGPathAddArcToPoint(screenPath, NULL, displayRight, displayTop, displayRight, displayBottom, displayCornerRadius);
		CGPathAddArcToPoint(screenPath, NULL, displayRight, displayBottom, displayLeft, displayBottom, displayCornerRadius);
		CGPathAddArcToPoint(screenPath, NULL, displayLeft, displayBottom, displayLeft, displayTop, displayCornerRadius);
		CGPathAddArcToPoint(screenPath, NULL, displayLeft, displayTop, displayRight, displayTop, displayCornerRadius);

		// Define the power light
		powerLightPath = CGPathCreateMutable();
		CGPathAddArc(powerLightPath, NULL, powerLightCenterX, powerLightCenterY, powerLightRadius, 0.0f, 2 * M_PI, 0);
		powerLightCenter.x = powerLightCenterX;
		powerLightCenter.y = powerLightCenterY;

		// Define the gradients
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		monitorGradient = CGGradientCreateWithColorComponents(colorSpace, colorsMonitor, NULL, 3);
		powerLightGradient = CGGradientCreateWithColorComponents(colorSpace, colorsPowerLight, NULL, 2);
		CGColorSpaceRelease(colorSpace);

		// Create the menu buttons
		UIButton* button;
		UIColor* buttonColor = [UIColor yellowColor];
		UIFont* buttonFont = [UIFont fontWithName:@"Courier" size:menuEntryHeight / 2];
		CGRect buttonFrame = CGRectMake(menuEntryCornerX, menuEntryCornerY, menuEntryWidth, menuEntryHeight);
		for(Class<Slave> buttonClass in buttonClasses)
		{
			button = [UIButton buttonWithType:UIButtonTypeCustom];
			[button setFrame:buttonFrame];
			[button setTitle:[@"> " stringByAppendingString:[[buttonClass menuName] uppercaseString]] forState:UIControlStateNormal];
			[button setTitleColor:buttonColor forState:UIControlStateNormal];
			button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
			button.titleLabel.font = buttonFont;
			button.tag = (NSInteger)buttonClass;
			[button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
			[self addSubview:button];
			buttonFrame.origin.y += menuEntryHeight;
		}
	}
	return self;
}

- (void)buttonPressed:(UIButton*)sender
{
	[(Master*)[self superview] slaveViewSwap:(Class)sender.tag];
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Draw the monitor
	CGContextSaveGState(context);
	CGContextAddPath(context, monitorPath);
	CGContextAddPath(context, screenPath);
	CGContextEOClip(context);
	CGContextDrawLinearGradient(context, monitorGradient, CGPointMake(0.0f, monitorCornerY), CGPointMake(0.0f, monitorCornerY + monitorHeight), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);

	// Draw the screen
	CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 0.0f, 1.0f);
	CGContextSetRGBFillColor(context, 0.0f, 0.0f, 0.5f, 1.0f);
	CGContextSetLineWidth(context, 2.0f);
	CGContextAddPath(context, screenPath);
	CGContextDrawPath(context, kCGPathFillStroke);

	// Draw the power light
	CGContextSaveGState(context);
	CGContextAddPath(context, powerLightPath);
	CGContextClip(context);
	CGContextDrawRadialGradient(context, powerLightGradient, powerLightCenter, powerLightRadius / 5, powerLightCenter, powerLightRadius, kCGGradientDrawsBeforeStartLocation);
	CGContextRestoreGState(context);

	// Display the keyboard
	[keyboardImage drawAtPoint:CGPointMake(0.0f, screenHeight - keyboardImage.size.height)];
}

- (void)dealloc
{
	// Release the gradients
	CGGradientRelease(powerLightGradient);
	CGGradientRelease(monitorGradient);

	// Release the paths
	CGPathRelease(powerLightPath);
	CGPathRelease(screenPath);
	CGPathRelease(monitorPath);

	// Destroy everything else
	[super dealloc];
}

@end
