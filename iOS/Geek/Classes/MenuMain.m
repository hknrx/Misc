#import "MenuMain.h"
#import "MenuClock.h"
#import "MenuFunfair.h"
#import "MenuSound.h"
#import "Passport.h"
#import "Test.h"

#define monitorCrtRight    280.0f
#define monitorCrtLength   65.0f
#define monitorBodyLength  (monitorCrtLength * 0.5f)
#define monitorBodyLeft    (monitorCrtRight - monitorCrtLength)
#define monitorBodyRight   (monitorBodyLeft + monitorBodyLength)
#define monitorKeyboardGap 15.0f

#define keyboardLength 40.0f
#define keyboardRight  (monitorBodyLeft - monitorKeyboardGap)
#define keyboardLeft   (keyboardRight - keyboardLength)

#define tableGap       4.0f
#define tableRight     (monitorCrtRight - tableGap)
#define tableLeft      (keyboardLeft - tableGap)
#define tableLength    (tableRight - tableLeft)
#define tableLegWidth  5.0f
#define tableLegMargin 10.0f
#define tableLeg1Left  (tableLeft + tableLegMargin)
#define tableLeg1Right (tableLeg1Left + tableLegWidth)
#define tableLeg2Right (tableRight - tableLegMargin)
#define tableLeg2Left  (tableLeg2Right - tableLegWidth)

#define ground 310.0f

#define tableThickness 8.0f
#define tableLegHeight 30.0f
#define tableLegTop    (ground - tableLegHeight)
#define tableTop       (tableLegTop - tableThickness)

#define keyboardThicknessLeft  8.0f
#define keyboardThicknessRight 14.0f
#define keyboardBottom         (tableTop - tableGap)
#define keyboardTopLeft        (keyboardBottom - keyboardThicknessLeft)
#define keyboardTopRight       (keyboardBottom - keyboardThicknessRight)

#define monitorCrtHeightMax   70.0f
#define monitorCrtHeightMin   30.0f
#define monitorBodyBottom     (tableTop - tableGap)
#define monitorBodyTop        (monitorBodyBottom - monitorCrtHeightMax)
#define monitorCrtTopRight    (monitorBodyTop + (monitorCrtHeightMax - monitorCrtHeightMin) / 2)
#define monitorCrtBottomRight (monitorBodyBottom - (monitorCrtHeightMax - monitorCrtHeightMin) / 2)
#define monitorBodyCrtTop     (monitorBodyTop + monitorBodyLength * (monitorCrtHeightMax - monitorCrtHeightMin) / (2 * monitorCrtLength))
#define monitorBodyCrtBottom  (monitorBodyBottom - monitorBodyLength * (monitorCrtHeightMax - monitorCrtHeightMin) / (2 * monitorCrtLength))

@implementation MenuMain

- (NSString*)helpText
{
	return @"When on a menu, simply tap an entry to launch the corresponding application.\n\nOn each screen, you can also tap the information or help buttons located in the top bar.";
}

- (NSString*)infoText
{
	return @"Welcome to \"Geek System\", a collection of little applications that Geeks might find useful... ...or not! :) Have fun!\n\n(Just tap the screen to dismiss this message.)";
}

+ (NSString*)menuName
{
	return @"Main Menu";
}

+ (BarContent)barContent
{
	return BAR_NOTHING;
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame withButtonClasses:[NSArray arrayWithObjects:[MenuClock class], [MenuFunfair class], [MenuSound class], [Test class], [Passport class], nil]])
	{
		// Define the little computer
		computerPath = CGPathCreateMutable();
		CGPathAddRect(computerPath, NULL, CGRectMake(tableLeft, tableTop, tableLength, tableThickness));
		CGPathMoveToPoint(computerPath, NULL, tableLeg1Left, tableLegTop);
		CGPathAddLineToPoint(computerPath, NULL, tableLeg1Left, ground);
		CGPathMoveToPoint(computerPath, NULL, tableLeg1Right, tableLegTop);
		CGPathAddLineToPoint(computerPath, NULL, tableLeg1Right, ground);
		CGPathMoveToPoint(computerPath, NULL, tableLeg2Left, tableLegTop);
		CGPathAddLineToPoint(computerPath, NULL, tableLeg2Left, ground);
		CGPathMoveToPoint(computerPath, NULL, tableLeg2Right, tableLegTop);
		CGPathAddLineToPoint(computerPath, NULL, tableLeg2Right, ground);
		CGPathMoveToPoint(computerPath, NULL, keyboardLeft, keyboardBottom);
		CGPathAddLineToPoint(computerPath, NULL, keyboardLeft, keyboardTopLeft);
		CGPathAddLineToPoint(computerPath, NULL, keyboardRight, keyboardTopRight);
		CGPathAddLineToPoint(computerPath, NULL, keyboardRight, keyboardBottom);
		CGPathCloseSubpath(computerPath);
		CGPathAddRect(computerPath, NULL, CGRectMake(monitorBodyLeft, monitorBodyTop, monitorBodyLength, monitorCrtHeightMax));
		CGPathMoveToPoint(computerPath, NULL, monitorBodyRight, monitorBodyCrtTop);
		CGPathAddLineToPoint(computerPath, NULL, monitorCrtRight, monitorCrtTopRight);
		CGPathAddLineToPoint(computerPath, NULL, monitorCrtRight, monitorCrtBottomRight);
		CGPathAddLineToPoint(computerPath, NULL, monitorBodyRight, monitorBodyCrtBottom);
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	// Draw the computer
	[super drawRect:rect];

	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Draw the little computer
	CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 1.0f, 1.0f);
	CGContextSetLineWidth(context, 2.0f);
	CGContextAddPath(context, computerPath);
	CGContextStrokePath(context);
}

- (void)dealloc
{
	// Release the path
	CGPathRelease(computerPath);

	// Destroy everything else
	[super dealloc];
}

@end
