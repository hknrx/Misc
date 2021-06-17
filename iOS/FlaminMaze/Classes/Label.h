#import <UIKit/UIKit.h>

@interface Label : UILabel
{
	UIColor* outlineColor;
	BOOL glow;
}

@property BOOL glow;

- (id)initWithFrame:(CGRect)frame withSize:(float)size withColor:(UIColor*)color;

@end
