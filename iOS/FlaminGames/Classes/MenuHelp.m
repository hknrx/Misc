#import "MenuHelp.h"
#import "Master.h"
#import "Label.h"

#ifdef FLAMIN_GIANT
	#define TEXT_WIDTH     400.0f
	#define TEXT_HEIGHT    400.0f
	#define TEXT_FONT_SIZE 32.0f
	#define TEXT_SPEED     40.0f
#else
	#define TEXT_WIDTH     200.0f
	#define TEXT_HEIGHT    200.0f
	#define TEXT_FONT_SIZE 16.0f
	#define TEXT_SPEED     30.0f
#endif

#define BOX_WIDTH  (TEXT_WIDTH + BOX_THICKNESS * 2 + BOX_MARGIN * 2)
#define BOX_HEIGHT (TEXT_HEIGHT + BOX_THICKNESS * 2 + BOX_MARGIN * 2)

#define TEXT_OFFSET_X ((BOX_WIDTH - TEXT_WIDTH) / 2)
#define TEXT_OFFSET_Y (BOX_THICKNESS + BOX_MARGIN)

@implementation MenuHelp

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame withSize:CGSizeMake(BOX_WIDTH, BOX_HEIGHT)])
	{
		// Define the container
		container = [[UIView alloc] initWithFrame:CGRectMake(boxLeft + TEXT_OFFSET_X, boxTop + TEXT_OFFSET_Y, TEXT_WIDTH, TEXT_HEIGHT)];
		container.clipsToBounds = YES;
		[self addSubview:container];
		[container release];
	}
	return self;
}

- (void)setText:(NSString*)text
{
	[label removeFromSuperview];
	label = [[Label alloc] initWithFrame:CGRectNull withSize:TEXT_FONT_SIZE withColor:[UIColor blueColor]];
	label.text = text;
	label.textAlignment = UITextAlignmentCenter;
	label.numberOfLines = 0;
	label.glow = YES;
	[container addSubview:label];
	[label release];

	CGSize const labelSize = [label.text sizeWithFont:label.font constrainedToSize:CGSizeMake(container.frame.size.width, FLT_MAX)];
	label.frame = CGRectMake(0.0f, 0.0f, container.frame.size.width, labelSize.height);

	[self animate];
}

- (void)setHidden:(BOOL)hidden
{
	super.hidden = hidden;
	[self animate];
}

- (void)animate
{
	if(label.frame.size.height > container.frame.size.height)
	{
		label.transform = CGAffineTransformTranslate(container.transform, 0.0f, container.frame.size.height);
		if(!self.hidden)
		{
			[UIView beginAnimations:@"help" context:nil];
			[UIView setAnimationCurve:UIViewAnimationCurveLinear];
			[UIView setAnimationDuration:(label.frame.size.height + container.frame.size.height) / TEXT_SPEED];
			[UIView setAnimationRepeatCount:FLT_MAX];
			label.transform = CGAffineTransformTranslate(container.transform, 0.0f, -label.frame.size.height);
			[UIView commitAnimations];
		}
	}
	else
	{
		label.transform = CGAffineTransformTranslate(container.transform, 0.0f, (container.frame.size.height - label.frame.size.height) / 2);
	}
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	[Master animateView:self setHidden:YES];
}

@end
