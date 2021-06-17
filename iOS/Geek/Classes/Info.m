#import "Info.h"
#import "Label.h"

@implementation Info

static CGFloat const colorsInfo[8] = {0.2f, 0.2f, 0.5f, 0.8f, 0.5f, 0.5f, 1.0f, 0.8f};
static CGFloat const colorsHelp[8] = {0.5f, 0.2f, 0.2f, 0.8f, 1.0f, 0.5f, 0.5f, 0.8f};

@synthesize help;

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

		// Define the gradients
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		gradientInfo = CGGradientCreateWithColorComponents(colorSpace, colorsInfo, NULL, 2);
		gradientHelp = CGGradientCreateWithColorComponents(colorSpace, colorsHelp, NULL, 2);
		CGColorSpaceRelease(colorSpace);

		// Make sure the view is transparent
		self.backgroundColor = [UIColor colorWithWhite:0.1f alpha:0.7f];

		// Define a label to display the text
		label = [[Label alloc] initWithFrame:CGRectMake(40.0f, 120.0f, 240.0f, 240.0f) withSize:16.0f withColor:[UIColor magentaColor]];
		label.textAlignment = UITextAlignmentCenter;
		label.numberOfLines = 0;
		label.glow = YES;
		[self addSubview:label];
		[label release];
	}
	return self;
}

- (void)prepareSlaveView:(UIView<Slave>*)slaveView displayHelp:(BOOL)displayHelp
{
	help = displayHelp;
	if(help)
	{
		label.text = [slaveView helpText];
	}
	else
	{
		label.text = [slaveView infoText];
	}
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Fill the text box
	CGContextSaveGState(context);
	CGContextAddPath(context, textBoxPath);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, help ? gradientHelp : gradientInfo, CGPointMake(0.0f, 100.0f), CGPointMake(0.0f, 380.0f), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);

	// Draw the text box
	CGContextSetRGBStrokeColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
	CGContextAddPath(context, textBoxPath);
	CGContextSetLineWidth(context, 5.0f);
	CGContextStrokePath(context);
}

- (void)dealloc
{
	// Release the gradients
	CGGradientRelease(gradientHelp);
	CGGradientRelease(gradientInfo);

	// Release the text box
	CGPathRelease(textBoxPath);

	// Destroy everything else
	[super dealloc];
}

@end
