#import "Help.h"
#import "Label.h"

@implementation Help

static CGFloat const colors[8] = {0.5f, 0.2f, 0.2f, 0.8f, 1.0f, 0.5f, 0.5f, 0.8f};

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Define the text box
		textBoxPath = CGPathCreateMutable();
		CGPathMoveToPoint(textBoxPath, NULL, 40.0f, 100.0f);
		CGPathAddArcToPoint(textBoxPath, NULL, 300.0f, 100.0f, 300.0f, 380.0f, 20.0f);
		CGPathAddArcToPoint(textBoxPath, NULL, 300.0f, 380.0f, 20.0f, 380.0f, 20.0f);
		CGPathAddArcToPoint(textBoxPath, NULL, 20.0f, 380.0f, 20.0f, 100.0f, 20.0f);
		CGPathAddArcToPoint(textBoxPath, NULL, 20.0f, 100.0f, 300.0f, 100.0f, 20.0f);

		// Define the gradient
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
		CGColorSpaceRelease(colorSpace);

		// Make sure the view is transparent
		self.backgroundColor = [UIColor colorWithWhite:0.1f alpha:0.7f];

		// Define a label to display the text
		label = [[Label alloc] initWithFrame:CGRectMake(40.0f, 120.0f, 240.0f, 240.0f) withSize:16.0f withColor:[UIColor magentaColor]];
		label.text = @"Paint the paper sheet by moving your finger like if you were holding a pencil, then tap the \"OK\" button when done. You can of course can change the paint color at any time and use the eraser to clean part of your drawing. To cut the paper, defining a shape by moving your finger on the sheet then tap the \"OK\" button when done.";
		label.textAlignment = UITextAlignmentCenter;
		label.numberOfLines = 0;
		label.glow = YES;
		[self addSubview:label];
		[label release];
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Fill the text box
	CGContextSaveGState(context);
	CGContextAddPath(context, textBoxPath);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, gradient, CGPointMake(0.0f, 100.0f), CGPointMake(0.0f, 380.0f), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);

	// Draw the text box
	CGContextSetRGBStrokeColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
	CGContextAddPath(context, textBoxPath);
	CGContextSetLineWidth(context, 5.0f);
	CGContextStrokePath(context);
}

- (void)dealloc
{
	// Release the gradient
	CGGradientRelease(gradient);

	// Release the text box
	CGPathRelease(textBoxPath);

	// Destroy everything else
	[super dealloc];
}

@end
