#import <UIKit/UIKit.h>

#ifdef FLAMIN_MAZE_GIANT
	#define BOX_THICKNESS 8.0f
	#define BOX_MARGIN    40.0f
	#define BOX_RADIUS    40.0f

	#define FONT_SIZE 36.0f
#else
	#define BOX_THICKNESS 4.0f
	#define BOX_MARGIN    20.0f
	#define BOX_RADIUS    20.0f

	#define FONT_SIZE 18.0f
#endif

@class Button;
@class Label;

@interface Menu : UIView
{
	UIColor* labelColor;

	CGFloat boxTop;
	CGFloat boxBottom;
	CGFloat boxLeft;
	CGFloat boxRight;
	CGMutablePathRef boxPathOuter;
	CGMutablePathRef boxPathInner;
	CGGradientRef boxGradient;

	Label* titleLabel;
	Button* openFeintButton;
	NSString* openFeintLeaderboardId;
	UIView* helpView;
	Label* helpLabel;
}

@property (nonatomic, copy) NSString* openFeintLeaderboardId;

- (id)initWithFrame:(CGRect)frame withSize:(CGSize)size withTitle:(NSString*)title inRectangle:(CGRect)titleRect;
- (id)initWithFrame:(CGRect)frame withParent:(id)parent;
- (void)setTitle:(NSString*)title;
- (void)addOpenFeintButtonInRectangle:(CGRect)rect;
- (void)updateOpenFeintButtonWithLeaderboardId:(NSString*)leaderboardId;
- (void)addHelpText:(NSString const*const)helpText;
- (void)hideHelp:(BOOL)hidden;

@end
