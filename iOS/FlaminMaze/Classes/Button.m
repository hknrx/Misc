#import "Button.h"
#import "Label.h"

#ifdef FLAMIN_MAZE_GIANT
	#define pathThickness 4.0f
#else
	#define pathThickness 2.0f
#endif

@implementation Button

@synthesize label;

- (id)initWithColor:(UIColor*)color withText:(NSString*)text withFontSize:(CGFloat)fontSize inRectangle:(CGRect)rectangle withTarget:(id)target withSelector:(SEL)selector
{
	if(self = [super initWithFrame:rectangle])
	{
		// Define the label (if any)
		if(text)
		{
			label = [[Label alloc] initWithFrame:self.bounds withSize:fontSize withColor:color];
			label.text = text;
			label.textAlignment = UITextAlignmentCenter;
			[self addSubview:label];
			[label release];
		}
		else
		{
			label = nil;
		}

		// Take note of the touch events' target
		touchTarget = target;
		touchSelector = selector;

		// Set the background color
		self.backgroundColor = [UIColor clearColor];

		// Define the shape (path) of the button
		path = CGPathCreateMutable();
		CGFloat const radius = rectangle.size.height / 2;
		CGPathMoveToPoint(path, NULL, radius, pathThickness / 2);
		CGPathAddArc(path, NULL, rectangle.size.width - radius, radius, radius - pathThickness / 2, -M_PI_2, M_PI_2, false);
		CGPathAddArc(path, NULL, radius, radius, radius - pathThickness / 2, M_PI_2, -M_PI_2, false);

		// Define the color gradient of the button
		CGFloat const*const colorComponents = CGColorGetComponents(color.CGColor);
		CGFloat colors[12];
		for(unsigned int component = 0; component < 3; ++component)
		{
			colors[component + 0] = colors[component + 8] = colorComponents[component] * 0.2f;
			colors[component + 4] = colorComponents[component] * 0.6f;
		}
		colors[3] = colors[7] = colors[11] = colorComponents[3];
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 3);
		CGColorSpaceRelease(colorSpace);
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	CGContextAddPath(context, path);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(0.0f, self.bounds.size.height), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);
	CGContextSetLineWidth(context, pathThickness);
	CGContextSetRGBStrokeColor(context, 0.1f, 0.1f, 0.1f, 1.0f);
	CGContextAddPath(context, path);
	CGContextStrokePath(context);
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	self.transform = CGAffineTransformMakeScale(0.95f, 0.95f);
	[touchTarget performSelector:touchSelector withObject:self];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	self.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
	[self touchesEnded:touches withEvent:event];
}

- (void)dealloc
{
	// Release the gradient
	CGGradientRelease(gradient);

	// Release the path
	CGPathRelease(path);

	// Destroy everything else
	[super dealloc];
}

@end
