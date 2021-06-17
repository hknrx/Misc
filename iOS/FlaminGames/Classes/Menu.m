#import "Menu.h"

@implementation Menu

static CGFloat const boxColors[8] = {0.5f, 0.5f, 1.0f, 0.5f, 0.3f, 0.3f, 0.6f, 0.5f};

- (id)initWithFrame:(CGRect)frame withSize:(CGSize)size
{
	if(self = [super initWithFrame:frame])
	{
		// Set the background color
		self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];

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
	CGContextDrawLinearGradient(context, boxGradient, CGPointMake(0.0f, boxTop), CGPointMake(0.0f, boxBottom), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);

	CGContextAddPath(context, boxPathOuter);
	CGContextAddPath(context, boxPathInner);
	CGContextSetRGBFillColor(context, 0.8f, 0.8f, 1.0f, 0.5f);
	CGContextEOFillPath(context);
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
	// Release the box gradient
	CGGradientRelease(boxGradient);

	// Release the box paths
	CGPathRelease(boxPathInner);
	CGPathRelease(boxPathOuter);

	// Destroy everything else
	[super dealloc];
}

@end
