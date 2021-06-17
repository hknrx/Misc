#import "AlertBox.h"
#import "Label.h"
#import "Button.h"

@interface AlertBox ()
{
	void (^block)(void);
}

@end

@implementation AlertBox

- (id)initWithFirstLabel:(NSString *)firstLabel andSecondLabel:(NSString *)secondLabel andButtonLabel:(NSString *)buttonLabel andButtonIcon:(UIImage *)buttonIcon andBlock:(void (^)(void))_block
{
	self = [super initWithImage:[UIImage imageNamed:@"AlertBox.png"]];
	if(self)
	{
		self.userInteractionEnabled = YES;
		block = _block;

		Label * label = [[Label alloc] initWithFrame:CGRectMake(0.0f, 8.0f, self.frame.size.width, 30.0f)];
		label.font = [UIFont fontWithName:@"Verdana-Bold" size:16.0f];
		label.text = firstLabel;
		label.textColor = [UIColor whiteColor];
		label.textAlignment = UITextAlignmentCenter;
		label.outlineColor = [UIColor redColor];
		label.glow = YES;
		[self addSubview:label];

		label = [[Label alloc] initWithFrame:CGRectMake(0.0f, 38.0f, self.frame.size.width, 30.0f)];
		label.font = [UIFont fontWithName:@"Verdana-Bold" size:16.0f];
		label.text = secondLabel;
		label.textColor = [UIColor whiteColor];
		label.textAlignment = UITextAlignmentCenter;
		label.outlineColor = [UIColor redColor];
		label.glow = YES;
		[self addSubview:label];

		UIButton * button = [Button createButtonWithBackground:[UIImage imageNamed:@"Button_Long.png"] withIcon:buttonIcon withText:buttonLabel ofSize:16.0f withSpacing:(buttonIcon && buttonLabel ? 20.0f : 0.0f)];
		button.center = CGPointMake(self.frame.size.width / 2, 93.0f);
		[button addTarget:self action:@selector(action) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:button];
	}
	return self;
}

- (void)action
{
	if(block)
	{
		block();
	}
}

@end
