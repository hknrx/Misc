#import "MenuPause.h"
#import "Label.h"
#import "Button.h"

#ifdef FLAMIN_MAZE_GIANT
	#define TITLE_WIDTH  320.0f
	#define TITLE_HEIGHT 64.0f

	#define BUTTON_WIDTH  320.0f
	#define BUTTON_HEIGHT 80.0f
#else
	#define TITLE_WIDTH  160.0f
	#define TITLE_HEIGHT 32.0f

	#define BUTTON_WIDTH  160.0f
	#define BUTTON_HEIGHT 40.0f
#endif

#define BOX_WIDTH  (TITLE_WIDTH + BOX_THICKNESS * 2 + BOX_MARGIN * 2)
#define BOX_HEIGHT (TITLE_HEIGHT + BUTTON_HEIGHT * 3 + BOX_THICKNESS * 2 + BOX_MARGIN * 5)

#define TITLE_OFFSET_X ((BOX_WIDTH - TITLE_WIDTH) / 2)
#define TITLE_OFFSET_Y (BOX_THICKNESS + BOX_MARGIN)

#define BUTTON_OFFSET_X            ((BOX_WIDTH - BUTTON_WIDTH) / 2)
#define BUTTON_OFFSET_Y_CONTINUE   (TITLE_OFFSET_Y + TITLE_HEIGHT + BOX_MARGIN)
#define BUTTON_OFFSET_Y_GIVE_UP    (BUTTON_OFFSET_Y_CONTINUE + BUTTON_HEIGHT + BOX_MARGIN)
#define BUTTON_OFFSET_Y_OPEN_FEINT (BUTTON_OFFSET_Y_GIVE_UP + BUTTON_HEIGHT + BOX_MARGIN)

@implementation MenuPause

- (id)initWithFrame:(CGRect)frame withParent:(id)parent
{
	if(self = [super initWithFrame:frame withSize:CGSizeMake(BOX_WIDTH, BOX_HEIGHT) withTitle:nil inRectangle:CGRectMake(TITLE_OFFSET_X, TITLE_OFFSET_Y, TITLE_WIDTH, TITLE_HEIGHT)])
	{
		// Add the continue button
		Button* button = [[Button alloc] initWithColor:labelColor withText:@"CONTINUE" withFontSize:FONT_SIZE inRectangle:CGRectMake(boxLeft + BUTTON_OFFSET_X, boxTop + BUTTON_OFFSET_Y_CONTINUE, BUTTON_WIDTH, BUTTON_HEIGHT) withTarget:parent withSelector:@selector(buttonBack:)];
		button.label.glow = YES;
		[self addSubview:button];
		[button release];

		// Add the give up button
		button = [[Button alloc] initWithColor:labelColor withText:@"GIVE UP" withFontSize:FONT_SIZE inRectangle:CGRectMake(boxLeft + BUTTON_OFFSET_X, boxTop + BUTTON_OFFSET_Y_GIVE_UP, BUTTON_WIDTH, BUTTON_HEIGHT) withTarget:parent withSelector:@selector(buttonGiveUp:)];
		button.label.glow = YES;
		[self addSubview:button];
		[button release];

		// Add the OpenFeint button
		[super addOpenFeintButtonInRectangle:CGRectMake(boxLeft + BUTTON_OFFSET_X, boxTop + BUTTON_OFFSET_Y_OPEN_FEINT, BUTTON_WIDTH, BUTTON_HEIGHT)];
	}
	return self;
}

@end
