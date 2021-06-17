#import <UIKit/UIKit.h>

@class Label;

@interface Button : UIView
{
	Label* label;
	id touchTarget;
	SEL touchSelector;

	CGMutablePathRef path;
	CGGradientRef gradient;
}

@property (nonatomic, readonly) Label* label;

- (id)initWithColor:(UIColor*)color withText:(NSString*)text withFontSize:(CGFloat)fontSize inRectangle:(CGRect)rectangle withTarget:(id)target withSelector:(SEL)selector;

@end
