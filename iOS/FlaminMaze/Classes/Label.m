#import "Label.h"

@implementation Label

- (id)initWithFrame:(CGRect)frame withSize:(float)size withColor:(UIColor*)color
{
	if(self = [super initWithFrame:frame])
	{
		self.font = [UIFont fontWithName:@"Arial-BoldMT" size:size];
		self.backgroundColor = [UIColor clearColor];
		outlineColor = [color retain];
		glow = NO;
	}
	return self;
}

- (void)drawTextInRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	if(glow)
	{
		CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 0.0f), 10.0f, outlineColor.CGColor);
		self.textColor = [UIColor whiteColor];
		self.alpha = 1.0f;
	}
	else
	{
		self.textColor = outlineColor;
		self.alpha = 0.3f;
	}
	[super drawTextInRect:rect];
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

- (void)dealloc
{
	[outlineColor release];
	[super dealloc];
}

@end
