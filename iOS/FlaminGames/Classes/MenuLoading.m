#import "MenuLoading.h"
#import "Label.h"

#ifdef FLAMIN_GIANT
	#define TITLE_WIDTH     240.0f
	#define TITLE_HEIGHT    128.0f
	#define TITLE_FONT_SIZE 60.0f

	#define LABEL_WIDTH     200.0f
	#define LABEL_HEIGHT    80.0f
	#define LABEL_FONT_SIZE 36.0f
#else
	#define TITLE_WIDTH     120.0f
	#define TITLE_HEIGHT    64.0f
	#define TITLE_FONT_SIZE 30.0f

	#define LABEL_WIDTH     100.0f
	#define LABEL_HEIGHT    40.0f
	#define LABEL_FONT_SIZE 18.0f
#endif

#define BOX_WIDTH  (TITLE_WIDTH + BOX_THICKNESS * 2 + BOX_MARGIN * 2)
#define BOX_HEIGHT (TITLE_HEIGHT + LABEL_HEIGHT + BOX_THICKNESS * 2 + BOX_MARGIN * 3)

#define TITLE_OFFSET_X ((BOX_WIDTH - TITLE_WIDTH) / 2)
#define TITLE_OFFSET_Y (BOX_THICKNESS + BOX_MARGIN)

#define LABEL_OFFSET_X ((BOX_WIDTH - LABEL_WIDTH) / 2)
#define LABEL_OFFSET_Y (TITLE_OFFSET_Y + TITLE_HEIGHT + BOX_MARGIN)

@implementation MenuLoading

- (id)initWithFrame:(CGRect)frame withTitle:(NSString*)title
{
	if(self = [super initWithFrame:frame withSize:CGSizeMake(BOX_WIDTH, BOX_HEIGHT)])
	{
		// Add the title label
		Label* label = [[Label alloc] initWithFrame:CGRectMake(boxLeft + TITLE_OFFSET_X, boxTop + TITLE_OFFSET_Y, TITLE_WIDTH, TITLE_HEIGHT) withSize:TITLE_FONT_SIZE withColor:[UIColor colorWithRed:1.0f green:0.2f blue:0.5f alpha:1.0f]];
		label.text = title;
		label.textAlignment = UITextAlignmentCenter;
		label.numberOfLines = 0;
		label.glow = YES;
		[self addSubview:label];
		[label release];

		// Add the loading label
		label = [[Label alloc] initWithFrame:CGRectMake(boxLeft + LABEL_OFFSET_X, boxTop + LABEL_OFFSET_Y, LABEL_WIDTH, LABEL_HEIGHT) withSize:LABEL_FONT_SIZE withColor:[UIColor blueColor]];
		label.text = @"LOADING...";
		label.textAlignment = UITextAlignmentCenter;
		label.glow = YES;
		[self addSubview:label];
		[label release];
	}
	return self;
}

@end
