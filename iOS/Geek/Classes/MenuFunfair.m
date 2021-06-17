#import "MenuFunfair.h"
#import "Stacker.h"
#import "TimeBuster.h"

#define ferrisWheelRadius       70.0f
#define ferrisWheelCenterRadius 10.0f
#define ferrisWheelCarSize      20.0f
#define ferrisWheelCarOffset    2.0f
#define ferrisWheelMargin       2.0f
#define ferrisWheelSize         (ferrisWheelRadius * 2 + ferrisWheelCarSize + ferrisWheelMargin * 2)
#define ferrisWheelCenterX      (ferrisWheelSize / 2)
#define ferrisWheelCenterY      (ferrisWheelCarOffset + ferrisWheelRadius + ferrisWheelMargin)
#define ferrisWheelTowerGap     (ferrisWheelSize / 2)
#define ferrisWheelGround       300.0f
#define ferrisWheelPositionX    200.0f
#define ferrisWheelPositionY    (ferrisWheelGround - ferrisWheelSize / 2)

@implementation MenuFunfair

- (NSString*)helpText
{
	return @"Tap the screen to select one of these 2 classic funfair games: Stack Game and Time Master!";
}

- (NSString*)infoText
{
	return @"Because Geeks love video games, they also enjoy going to funfairs to waste their pocket money playing stressful games. Geek System now lets them train at home!";
}

+ (NSString*)menuName
{
	return @"Funfair";
}

+ (BarContent)barContent
{
	return BAR_COINS;
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame withButtonClasses:[NSArray arrayWithObjects:[Stacker class], [TimeBuster class], nil]])
	{
		// Create the ferris wheel images
		UIGraphicsBeginImageContext(CGSizeMake(ferrisWheelSize, ferrisWheelSize));
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 1.0f, 1.0f);
		CGContextSetRGBFillColor(context, 0.0f, 0.0f, 1.0f, 1.0f);
		float angle = 0.0f;
		CGPoint const center = CGPointMake(ferrisWheelPositionX, ferrisWheelPositionY);
		for(unsigned char frameIndex = 0; frameIndex < 8; ++ frameIndex)
		{
			CGContextClearRect(context, CGRectInfinite);
			CGContextSetLineWidth(context, 2.0f);
			CGContextAddArc(context, ferrisWheelCenterX, ferrisWheelCenterY, ferrisWheelRadius, 0.0f, 2 * M_PI, 0);
			CGContextMoveToPoint(context, ferrisWheelCenterX - ferrisWheelTowerGap / 2, ferrisWheelSize);
			CGContextAddLineToPoint(context, ferrisWheelCenterX, ferrisWheelCenterY);
			CGContextAddLineToPoint(context, ferrisWheelCenterX + ferrisWheelTowerGap / 2, ferrisWheelSize);
			for(unsigned char gondola = 0; gondola < 12; ++gondola)
			{
				float const x = ferrisWheelCenterX + ferrisWheelRadius * sinf(angle) - ferrisWheelCarSize / 2;
				float const y = ferrisWheelCenterY + ferrisWheelRadius * cosf(angle) - ferrisWheelCarOffset;
				CGContextAddRect(context, CGRectMake(x, y, ferrisWheelCarSize, ferrisWheelCarSize));
				angle += M_PI / 6;
			}
			CGContextStrokePath(context);
			CGContextSetLineWidth(context, 1.0f);
			for(unsigned char gondola = 0; gondola < 12; ++gondola)
			{
				float const x = ferrisWheelCenterX + ferrisWheelRadius * sinf(angle);
				float const y = ferrisWheelCenterY + ferrisWheelRadius * cosf(angle);
				CGContextMoveToPoint(context, ferrisWheelCenterX, ferrisWheelCenterY);
				CGContextAddLineToPoint(context, x, y);
				angle += M_PI / 6;
			}
			CGContextStrokePath(context);
			CGContextAddArc(context, ferrisWheelCenterX, ferrisWheelCenterY, ferrisWheelCenterRadius, 0.0f, 2 * M_PI, 0);
			CGContextFillPath(context);
			ferrisWheel[frameIndex] = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
			ferrisWheel[frameIndex].hidden = frameIndex;
			ferrisWheel[frameIndex].center = center;
			[self insertSubview:ferrisWheel[frameIndex] atIndex:0];
			[ferrisWheel[frameIndex] release];
			angle += M_PI / 48;
		}
		UIGraphicsEndImageContext();
	}
	return self;
}

- (void)willMoveToSuperview:(UIView*)superView
{
	if(superView)
	{
		// Launch a timer to refresh the display
		timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 15) target:self selector:@selector(update) userInfo:nil repeats:YES];
	}
	else
	{
		// Invalidate the timer
		[timer invalidate];
	}
}

- (void)drawRect:(CGRect)rect
{
	// Draw the computer
	[super drawRect:rect];

	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Draw the ground below the ferris wheel
	CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 1.0f, 1.0f);
	CGContextSetLineWidth(context, 2.0f);
	CGContextMoveToPoint(context, 40.0f, ferrisWheelGround);
	CGContextAddLineToPoint(context, 280.0f, ferrisWheelGround);
	CGContextStrokePath(context);
}

- (void)update
{
	// Animate the ferris wheel
	for(unsigned char frameIndex = 0; frameIndex < 8; ++ frameIndex)
	{
		ferrisWheel[frameIndex].hidden = ++frameCounter & 7;
	}
	++frameCounter;
}

@end
