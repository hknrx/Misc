#import "MenuMain.h"
#import "Label.h"
#import "Button.h"

#ifdef FLAMIN_MAZE_GIANT
	#define TITLE_WIDTH  240.0f
	#define TITLE_HEIGHT 128.0f

	#define BUTTON_WIDTH  320.0f
	#define BUTTON_HEIGHT 80.0f
#else
	#define TITLE_WIDTH  120.0f
	#define TITLE_HEIGHT 64.0f

	#define BUTTON_WIDTH  160.0f
	#define BUTTON_HEIGHT 40.0f
#endif

#define BOX_WIDTH  (BUTTON_WIDTH + BOX_THICKNESS * 2 + BOX_MARGIN * 2)
#define BOX_HEIGHT (TITLE_HEIGHT + BUTTON_HEIGHT * 3 + BOX_THICKNESS * 2 + BOX_MARGIN * 5)

#define TITLE_OFFSET_X ((BOX_WIDTH - TITLE_WIDTH) / 2)
#define TITLE_OFFSET_Y (BOX_THICKNESS + BOX_MARGIN)

#define BUTTON_OFFSET_X            ((BOX_WIDTH - BUTTON_WIDTH) / 2)
#define BUTTON_OFFSET_Y_ESCAPE     (TITLE_OFFSET_Y + TITLE_HEIGHT + BOX_MARGIN)
#define BUTTON_OFFSET_Y_EXPLORE    (BUTTON_OFFSET_Y_ESCAPE + BUTTON_HEIGHT + BOX_MARGIN)
#define BUTTON_OFFSET_Y_OPEN_FEINT (BUTTON_OFFSET_Y_EXPLORE + BUTTON_HEIGHT + BOX_MARGIN)

@implementation MenuMain

static NSString const*const helpText = @"Welcome to the Devil's hideout, an inextricable underground structure from which no adventurer ever came back... It is said that each floor is a maze that absorbs vital energy quickly! Will you accept this challenge and try to go as deep as possible in these dangerous labyrinths? How many levels will you walk in before the time runs out?   ***   Once entered a new maze, quickly move your finger on the screen to draw your path; you'll be awarded a bit of time everytime you'll complete a maze, then instantly move to the entrance of the next level... Good luck!";

- (id)initWithFrame:(CGRect)frame withParent:(id)parent
{
	if(self = [super initWithFrame:frame withSize:CGSizeMake(BOX_WIDTH, BOX_HEIGHT) withTitle:@"FLAMIN\nMAZE" inRectangle:CGRectMake(TITLE_OFFSET_X, TITLE_OFFSET_Y, TITLE_WIDTH, TITLE_HEIGHT)])
	{
		// Add the escape button
		Button* button = [[Button alloc] initWithColor:labelColor withText:@"ESCAPE" withFontSize:FONT_SIZE inRectangle:CGRectMake(boxLeft + BUTTON_OFFSET_X, boxTop + BUTTON_OFFSET_Y_ESCAPE, BUTTON_WIDTH, BUTTON_HEIGHT) withTarget:parent withSelector:@selector(buttonEscape:)];
		button.label.glow = YES;
		[self addSubview:button];
		[button release];

		// Add the explore button
		button = [[Button alloc] initWithColor:labelColor withText:@"EXPLORE" withFontSize:FONT_SIZE inRectangle:CGRectMake(boxLeft + BUTTON_OFFSET_X, boxTop + BUTTON_OFFSET_Y_EXPLORE, BUTTON_WIDTH, BUTTON_HEIGHT) withTarget:parent withSelector:@selector(buttonExplore:)];
		button.label.glow = YES;
		[self addSubview:button];
		[button release];

		// Add the OpenFeint button
		[super addOpenFeintButtonInRectangle:CGRectMake(boxLeft + BUTTON_OFFSET_X, boxTop + BUTTON_OFFSET_Y_OPEN_FEINT, BUTTON_WIDTH, BUTTON_HEIGHT)];

		// Add the help text
		[super addHelpText:helpText];
	}
	return self;
}

@end
