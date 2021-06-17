@interface Button : NSObject

+ (UIButton *)createButtonWithBackground:(UIImage *)imageBackground withIcon:(UIImage *)imageIcon withText:(NSString *)text ofSize:(CGFloat)size withSpacing:(CGFloat)spacing;

@end
