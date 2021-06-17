@class ViewController;
@class Plunger;

@interface Vote : UIImageView

- (id)initWithViewController:(ViewController *)viewController;
- (void)plungerTouchBegan:(Plunger *)plunger;
- (void)plungerTouchMoved:(Plunger *)plunger;
- (void)plungerTouchEnded:(Plunger *)plunger;
- (void)plungerTouchCancelled:(Plunger *)plunger;

@end
