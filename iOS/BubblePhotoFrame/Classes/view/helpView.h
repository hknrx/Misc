#import <UIKit/UIKit.h>

@interface HelpView : UIView <UIWebViewDelegate>
{
	UIWebView* webView;
}

- (id)initWithFrame:(CGRect)frame withController:(UIViewController*)controller;
- (void)resetScrolling;

@end
