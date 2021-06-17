#import "ScrollingMessage.h"

static CGFloat const HELP_HEIGHT = 30.0f;
static CGFloat const HELP_SPEED = 100.0f;
static CGFloat const HELP_MARGIN = HELP_SPEED;

@interface ScrollingMessage ()
{
	UILabel * label;
}

@end

@implementation ScrollingMessage

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:CGRectMake(0.0f, frame.size.height - HELP_HEIGHT, frame.size.width, HELP_HEIGHT)];
	if(self)
	{
		self.clipsToBounds = YES;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(animate) name:UIApplicationDidBecomeActiveNotification object:nil];
	}
	return self;
}

- (void)animate
{
	if(label)
	{
		label.transform = CGAffineTransformTranslate(self.transform, self.frame.size.width + HELP_MARGIN, 0.0f);
		[UIView animateWithDuration:(label.frame.size.width + HELP_MARGIN + self.frame.size.width) / HELP_SPEED delay:0.0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveLinear|UIViewAnimationOptionRepeat
						 animations:^{
							 label.transform = CGAffineTransformTranslate(self.transform, -label.frame.size.width, 0.0f);
						 }
						 completion:nil];
	}
}

- (void)setText:(NSString *)_text
{
	[label removeFromSuperview];
	label = [[UILabel alloc] initWithFrame:CGRectNull];
	label.font = [UIFont fontWithName:@"Verdana-Bold" size:16.0f];
	label.text = _text;
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
	CGSize const labelSize = [label.text sizeWithFont:label.font];
	label.frame = CGRectMake(0.0f, 0.0f, labelSize.width, self.frame.size.height);

	[self addSubview:label];
	[self animate];
}

- (NSString *)text
{
	return label.text;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
