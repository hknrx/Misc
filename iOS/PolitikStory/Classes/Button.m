#import "Button.h"

@implementation Button

+ (UIButton *)createButtonWithBackground:(UIImage *)imageBackground withIcon:(UIImage *)imageIcon withText:(NSString *)text ofSize:(CGFloat)size withSpacing:(CGFloat)spacing
{
	UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setBackgroundImage:imageBackground forState:UIControlStateNormal];
	button.frame = CGRectMake(0.0f, 0.0f, imageBackground.size.width, imageBackground.size.height);

	if(imageIcon)
	{
		[button setImage:imageIcon forState:UIControlStateNormal];
		button.imageEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, spacing);
	}

	if(text)
	{
		[button setTitle:text forState:UIControlStateNormal];
		[button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
		button.titleLabel.font = [UIFont fontWithName:@"Verdana-Bold" size:size];
		button.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
		button.titleLabel.textAlignment = UITextAlignmentCenter;
		button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, spacing, 0.0f, 0.0f);
	}

	return button;
}

@end
