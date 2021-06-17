#import <UIKit/UIKit.h>

#ifdef FLAMIN_GIANT
	#define BOX_THICKNESS 8.0f
	#define BOX_MARGIN    40.0f
	#define BOX_RADIUS    40.0f
#else
	#define BOX_THICKNESS 4.0f
	#define BOX_MARGIN    20.0f
	#define BOX_RADIUS    20.0f
#endif

@interface Menu : UIView
{
	CGFloat boxTop;
	CGFloat boxBottom;
	CGFloat boxLeft;
	CGFloat boxRight;
	CGMutablePathRef boxPathOuter;
	CGMutablePathRef boxPathInner;
	CGGradientRef boxGradient;
}

- (id)initWithFrame:(CGRect)frame withSize:(CGSize)size;

@end
