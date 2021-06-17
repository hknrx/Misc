#import "Candidate.h"

@interface Candidate ()
{
	UIImage * firstImage;
	CGRect firstImageRect;

	UIImage * secondImage;
	CGRect secondImageRect;

	UIColor * blendColor;
}

@end

@implementation Candidate

static unsigned char const pixelTouchThreshold = 160;

- (id)initWithFrame:(CGRect)frame withName:(NSString *)name
{
	self = [super initWithFrame:frame];
	if(self)
	{
		self.backgroundColor = [UIColor clearColor];

		firstImage = [UIImage imageNamed:[NSString stringWithFormat:@"Candidate_%@.png", name]];
		firstImageRect = CGRectMake((frame.size.width - firstImage.size.width) / 2, firstImage.size.height - frame.size.height, firstImage.size.width, firstImage.size.height);

		secondImage = [UIImage imageNamed:[NSString stringWithFormat:@"Candidate_%@_Hit.png", name]];
		secondImageRect = CGRectMake((frame.size.width - secondImage.size.width) / 2, secondImage.size.height - frame.size.height, secondImage.size.width, secondImage.size.height);
	}
	return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
	if(event || !CGRectContainsPoint(self.bounds, point))
	{
		return NO;
	}

	unsigned char pixel = 0;
	CGContextRef context = CGBitmapContextCreate(&pixel, 1, 1, 8, 1, NULL, kCGImageAlphaOnly);
	UIGraphicsPushContext(context);
	if([self.subviews count])
	{
		[secondImage drawAtPoint:CGPointMake(secondImageRect.origin.x - point.x, -secondImageRect.origin.y - point.y)];
	}
	else
	{
		[firstImage drawAtPoint:CGPointMake(firstImageRect.origin.x - point.x, -firstImageRect.origin.y - point.y)];
	}
	UIGraphicsPopContext();
	CGContextRelease(context);
	return pixel >= pixelTouchThreshold;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	if(event)
	{
		for(UIView * subView in self.subviews)
		{
			UIView * hitView = [subView hitTest:[self convertPoint:point toView:subView] withEvent:event];
			if(hitView)
			{
				return hitView;
			}
		}
		return nil;
	}

	if([self pointInside:point withEvent:event])
	{
		return self;
	}
	return nil;
}

- (void)drawRect:(CGRect)rect
{
	UIImage * image;
	CGRect imageRect;
	if([self.subviews count])
	{
		image = secondImage;
		imageRect = secondImageRect;
	}
	else
	{
		image = firstImage;
		imageRect = firstImageRect;
	}

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextScaleCTM(context, 1.0f, -1.0f);
	CGContextTranslateCTM(context, 0.0f, -imageRect.size.height);
	CGContextDrawImage(context, imageRect, image.CGImage);
	if(blendColor)
	{
		CGContextClipToMask(context, imageRect, image.CGImage);
		CGContextSetBlendMode(context, kCGBlendModeMultiply);
		CGContextSetFillColor(context, CGColorGetComponents(blendColor.CGColor));
		CGContextFillRect(context, imageRect);
	}
}

- (void)setBlendColor:(UIColor *)_blendColor
{
	blendColor = _blendColor;
	[self setNeedsDisplay];
}

- (UIColor *)blendColor
{
	return blendColor;
}

@end
