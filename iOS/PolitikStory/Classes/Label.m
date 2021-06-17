#import "Label.h"

@implementation Label

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self)
	{
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)drawTextInRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	if(outlineColor)
	{
		if(glow)
		{
			CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 0.0f), 3.0f, outlineColor.CGColor);
		}
		else
		{
			UIColor *const textColor = self.textColor;
			CGContextSetLineWidth(context, 3.0f);
			CGContextSetTextDrawingMode(context, kCGTextStroke);
			self.textColor = outlineColor;
			[super drawTextInRect:rect];
			CGContextSetTextDrawingMode(context, kCGTextFill);
			self.textColor = textColor;
		}
	}
	[super drawTextInRect:rect];
}

- (void)setOutlineColor:(UIColor *)value
{
	if(outlineColor != value)
	{
		outlineColor = value;
		[self setNeedsDisplay];
	}
}

- (UIColor *)outlineColor
{
	return outlineColor;
}

- (void)setGlow:(BOOL)value
{
	if(glow != value)
	{
		glow = value;
		[self setNeedsDisplay];
	}
}

- (BOOL)glow
{
	return glow;
}

@end
