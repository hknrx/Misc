#import "MenuStart.h"
#import "Label.h"
#import "Button.h"

#ifdef FLAMIN_MAZE_GIANT
	#define TITLE_WIDTH  320.0f
	#define TITLE_HEIGHT 64.0f

	#define BUTTON_WIDTH_START       240.0f
	#define BUTTON_WIDTH_BACK        320.0f
	#define BUTTON_WIDTH_OPEN_FEINT  320.0f
	#define BUTTON_HEIGHT_START      120.0f
	#define BUTTON_HEIGHT_BACK       80.0f
	#define BUTTON_HEIGHT_OPEN_FEINT 80.0f
#else
	#define TITLE_WIDTH  160.0f
	#define TITLE_HEIGHT 32.0f

	#define BUTTON_WIDTH_START       120.0f
	#define BUTTON_WIDTH_BACK        160.0f
	#define BUTTON_WIDTH_OPEN_FEINT  160.0f
	#define BUTTON_HEIGHT_START      60.0f
	#define BUTTON_HEIGHT_BACK       40.0f
	#define BUTTON_HEIGHT_OPEN_FEINT 40.0f
#endif

#define BOX_WIDTH  (TITLE_WIDTH + BOX_THICKNESS * 2 + BOX_MARGIN * 2)
#define BOX_HEIGHT (TITLE_HEIGHT + BUTTON_HEIGHT_START + BUTTON_HEIGHT_BACK + BUTTON_HEIGHT_OPEN_FEINT + BOX_THICKNESS * 2 + BOX_MARGIN * 5)

#define TITLE_OFFSET_X ((BOX_WIDTH - TITLE_WIDTH) / 2)
#define TITLE_OFFSET_Y (BOX_THICKNESS + BOX_MARGIN)

#define BUTTON_OFFSET_X_START      ((BOX_WIDTH - BUTTON_WIDTH_START) / 2)
#define BUTTON_OFFSET_X_BACK       ((BOX_WIDTH - BUTTON_WIDTH_BACK) / 2)
#define BUTTON_OFFSET_X_OPEN_FEINT ((BOX_WIDTH - BUTTON_WIDTH_OPEN_FEINT) / 2)
#define BUTTON_OFFSET_Y_START      (TITLE_OFFSET_Y + TITLE_HEIGHT + BOX_MARGIN)
#define BUTTON_OFFSET_Y_BACK       (BUTTON_OFFSET_Y_START + BUTTON_HEIGHT_START + BOX_MARGIN)
#define BUTTON_OFFSET_Y_OPEN_FEINT (BUTTON_OFFSET_Y_BACK + BUTTON_HEIGHT_BACK + BOX_MARGIN)

@implementation MenuStart

- (id)initWithFrame:(CGRect)frame withParent:(id)parent
{
	if(self = [super initWithFrame:frame withSize:CGSizeMake(BOX_WIDTH, BOX_HEIGHT) withTitle:nil inRectangle:CGRectMake(TITLE_OFFSET_X, TITLE_OFFSET_Y, TITLE_WIDTH, TITLE_HEIGHT)])
	{
		// Add the start button
		Button* button = [[Button alloc] initWithColor:labelColor withText:@"START" withFontSize:FONT_SIZE * 1.6f inRectangle:CGRectMake(boxLeft + BUTTON_OFFSET_X_START, boxTop + BUTTON_OFFSET_Y_START, BUTTON_WIDTH_START, BUTTON_HEIGHT_START) withTarget:parent withSelector:@selector(buttonStart:)];
		button.label.glow = YES;
		[self addSubview:button];
		[button release];

		// Add the back button
		button = [[Button alloc] initWithColor:labelColor withText:@"BACK" withFontSize:FONT_SIZE inRectangle:CGRectMake(boxLeft + BUTTON_OFFSET_X_BACK, boxTop + BUTTON_OFFSET_Y_BACK, BUTTON_WIDTH_BACK, BUTTON_HEIGHT_BACK) withTarget:parent withSelector:@selector(buttonBack:)];
		button.label.glow = YES;
		[self addSubview:button];
		[button release];

		// Add the OpenFeint button
		[super addOpenFeintButtonInRectangle:CGRectMake(boxLeft + BUTTON_OFFSET_X_OPEN_FEINT, boxTop + BUTTON_OFFSET_Y_OPEN_FEINT, BUTTON_WIDTH_OPEN_FEINT, BUTTON_HEIGHT_OPEN_FEINT)];
	}
	return self;
}

@end
