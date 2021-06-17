#import "Menu.h"

@class Label;

@interface MenuHelp : Menu
{
	UIView* container;
	Label* label;
}

- (void)setText:(NSString*)text;
- (void)animate;

@end
