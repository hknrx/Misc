@interface AlertBox : UIImageView

- (id)initWithFirstLabel:(NSString *)firstLabel andSecondLabel:(NSString *)secondLabel andButtonLabel:(NSString *)buttonLabel andButtonIcon:(UIImage *)buttonIcon andBlock:(void (^)(void))block;

@end
