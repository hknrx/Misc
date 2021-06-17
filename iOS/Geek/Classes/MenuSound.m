#import "MenuSound.h"
#import "Dance.h"
#import "Voice.h"

#define ground 300.0f

#define poleWidth  10.0f
#define poleHeight 60.0f
#define poleCenter 200.0f
#define poleLeft   (poleCenter - poleWidth / 2)
#define poleRight  (poleCenter + poleWidth / 2)
#define poleTop    (ground - poleHeight)

#define micWidth         60.0f
#define micHeight        100.0f
#define micCornerRadius  20.0f
#define micCouplerRadius 10.0f
#define micLeft          (-micWidth / 2)
#define micRight         (micWidth / 2)
#define micTop           (-micHeight - micCouplerRadius)
#define micBottom        (-micCouplerRadius)
#define micHoleCount     5
#define micHoleGap       ((micHeight - micCornerRadius * 2) / (micHoleCount * 2 - 1))
#define micHoleTop       (micTop + micCornerRadius)
#define micHoleWidth     20.0f
#define micAngle         (M_PI / 6)

@implementation MenuSound

- (NSString*)helpText
{
	return @"Tap the screen to select one of these 2 weird sound experiments: Dance Floor and Pitch Robot!";
}

- (NSString*)infoText
{
	return @"Because Geeks like things that no other would pay attention to, and because they usually have ears, Geek Systems had to propose them a couple of funny sound experiments!";
}

+ (NSString*)menuName
{
	return @"Sound Experiments";
}

+ (BarContent)barContent
{
	return BAR_NOTHING;
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame withButtonClasses:[NSArray arrayWithObjects:[Dance class], [Voice class], nil]])
	{
		// Define the microphone
		CGAffineTransform micTransform = CGAffineTransformMakeTranslation(poleCenter, poleTop);
		micTransform = CGAffineTransformRotate(micTransform, micAngle);
		micPath = CGPathCreateMutable();
		CGPathAddArc(micPath, NULL, poleCenter, poleTop, poleWidth / 6, 0.0f, 2 * M_PI, 0);
		CGPathMoveToPoint(micPath, NULL, poleRight, ground);
		CGPathAddArc(micPath, NULL, poleCenter, poleTop, poleWidth / 2, 0.0f, M_PI, 1);
		CGPathAddLineToPoint(micPath, NULL, poleLeft, ground);
		CGPathMoveToPoint(micPath, NULL, 40.0f, ground);
		CGPathAddLineToPoint(micPath, NULL, 280.0f, ground);
		CGPathMoveToPoint(micPath, &micTransform, micLeft + micCornerRadius, micTop);
		CGPathAddArcToPoint(micPath, &micTransform, micRight, micTop, micRight, micBottom, micCornerRadius);
		CGPathAddArcToPoint(micPath, &micTransform, micRight, micBottom, micLeft, micBottom, micCornerRadius);
		CGPathAddArcToPoint(micPath, &micTransform, micLeft, micBottom, micLeft, micTop, micCornerRadius);
		CGPathAddArcToPoint(micPath, &micTransform, micLeft, micTop, micRight, micTop, micCornerRadius);
		CGPathMoveToPoint(micPath, &micTransform, micCouplerRadius, -micCouplerRadius);
		CGPathAddArc(micPath, &micTransform, 0.0f, 0.0f, micCouplerRadius, 0.0f, M_PI, 0);
		CGPathAddLineToPoint(micPath, &micTransform, -micCouplerRadius, -micCouplerRadius);
		CGFloat y = micHoleTop;
		for(unsigned int micHoleIndex = 0; micHoleIndex < micHoleCount; ++micHoleIndex)
		{
			CGPathMoveToPoint(micPath, &micTransform, micLeft, y);
			CGPathAddLineToPoint(micPath, &micTransform, micLeft + micHoleWidth, y);
			y += micHoleGap;
			CGPathAddLineToPoint(micPath, &micTransform, micLeft + micHoleWidth, y);
			CGPathAddLineToPoint(micPath, &micTransform, micLeft, y);
			CGPathMoveToPoint(micPath, &micTransform, micRight, y);
			CGPathAddLineToPoint(micPath, &micTransform, micRight - micHoleWidth, y);
			y -= micHoleGap;
			CGPathAddLineToPoint(micPath, &micTransform, micRight - micHoleWidth, y);
			CGPathAddLineToPoint(micPath, &micTransform, micRight, y);
			y += micHoleGap * 2;
		}
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	// Draw the computer
	[super drawRect:rect];

	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Draw the microphone
	CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 1.0f, 1.0f);
	CGContextSetLineWidth(context, 2.0f);
	CGContextAddPath(context, micPath);
	CGContextStrokePath(context);
}

- (void)dealloc
{
	// Release the path
	CGPathRelease(micPath);

	// Destroy everything else
	[super dealloc];
}

@end
