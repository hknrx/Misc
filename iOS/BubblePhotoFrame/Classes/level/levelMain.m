#import "levelMain.h"
#import "math.h"

#define BLOB_TITLE_PRESSURE_LOW     (signed long)(FIXED_POINT * 250.00)
#define BLOB_TITLE_PRESSURE_HIGH    (signed long)(FIXED_POINT * 600.00)
#define BLOB_TITLE_TIMER_HIGH_SLOW  90
#define BLOB_TITLE_TIMER_RESET_SLOW 100
#define BLOB_TITLE_TIMER_HIGH_FAST  5
#define BLOB_TITLE_TIMER_RESET_FAST 7
#define BLOB_TITLE_TIMER_FAST       150

static Texture const textures[] =
{
	{@"MainBackground.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuHelp.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuRocks.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuTorture.png", BLOB_TEXTURE_SIZE_SMALL, NO},
#ifndef LITE_VERSION
	{@"MainTitleFull.png", BLOB_TEXTURE_SIZE_LARGE, NO},
	{@"MenuLove.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuMaze.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuPinball.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuSpace.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuWashing.png", BLOB_TEXTURE_SIZE_SMALL, NO},
#else
	{@"MainTitleLite.png", BLOB_TEXTURE_SIZE_LARGE, NO},
	{@"MenuFull.png", BLOB_TEXTURE_SIZE_SMALL, NO},
#endif
};

@implementation LevelMain

@synthesize defaultButton;

- (unsigned int)textureCount
{
	return sizeof(textures) / sizeof(Texture);
}

- (Texture const*)textures
{
	return textures;
}

- (FacebookButton)facebookButton
{
	return FACEBOOK_LOGIN;
}

- (id)init
{
	if(self = [super init])
	{
		// Set the background
		BlobBackgroundTextureIdSet(0);
		BlobBackgroundColorIdSet(0);

		// Create the container
		BlobCharacteristics blobCharacteristics;
		blobCharacteristics.type = BLOB_TYPE_STATIC_HIDDEN;
		blobCharacteristics.elasticity = (signed long)(FIXED_POINT * 1.00);
		blobCharacteristics.friction =   (signed long)(FIXED_POINT * 1.00);
		blobCharacteristics.special.staticTransformation = NULL;
		blobCharacteristics.collisionMask = 1;

		BlobShapeReference blobShape = BlobShapeCreateBox();
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_CONTAINER_XMIN - (BLOB_CONTAINER_MARGIN / 2), 0, BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_HEIGHT + BLOB_CONTAINER_MARGIN);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_CONTAINER_XMAX + (BLOB_CONTAINER_MARGIN / 2), 0, BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_HEIGHT + BLOB_CONTAINER_MARGIN);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0, BLOB_CONTAINER_YMIN - (BLOB_CONTAINER_MARGIN / 2), BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_WIDTH + BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0, BLOB_CONTAINER_YMAX + (BLOB_CONTAINER_MARGIN / 2), BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_WIDTH + BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN);
		BlobShapeRelease(blobShape);

		// Create the static button
		blobCharacteristics.type = BLOB_TYPE_STATIC_VISIBLE;
		blobCharacteristics.textureId = 1;
		blobCharacteristics.textureRepeat = NO;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_HELP;

		blobShape = BlobShapeCreateBalloon(16);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, -33 << FIXED_POINT_SHIFT, 53 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT);
		BlobShapeRelease(blobShape);

		// Create several dynamic blobs
		// Note: blobs that are likely to become concave (e.g. big balloons) should be added last so that other blobs will be displayed above, hiding potential drawing errors
		blobCharacteristics.type = BLOB_TYPE_DYNAMIC;
		blobCharacteristics.elasticity =                (signed long)(FIXED_POINT * 0.10);
		blobCharacteristics.friction =                  (signed long)(FIXED_POINT * 0.50);
		blobCharacteristics.special.dynamic.mass =      (signed long)(FIXED_POINT * 0.50);
		blobCharacteristics.special.dynamic.stiffness = (signed long)(FIXED_POINT * 2.00);
		blobCharacteristics.special.dynamic.damping =   (signed long)(FIXED_POINT * 0.30);

		blobTitleTimer1 = 0;
		blobTitleTimer2 = 0;
		blobShape = BlobShapeCreateBalloon(32);
		blobCharacteristics.textureId = 4;
		blobCharacteristics.userId = TYPE_SPECIAL_1;
		blobCharacteristics.special.dynamic.pressure = BLOB_TITLE_PRESSURE_LOW;
		blobTitle = BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0 << FIXED_POINT_SHIFT, 0 << FIXED_POINT_SHIFT, 24 << FIXED_POINT_SHIFT, 24 << FIXED_POINT_SHIFT);
		BlobShapeRelease(blobShape);

		blobShape = BlobShapeCreateBalloon(24);
		blobCharacteristics.textureId = 2;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_ROCKS;
		blobCharacteristics.special.dynamic.pressure = (signed long)(FIXED_POINT * 150.00);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 26 * SIN(2 * 2 * PI / 7), 26 * COS(2 * 2 * PI / 7), 12 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 3;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_TORTURE;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 26 * SIN(5 * 2 * PI / 7), 26 * COS(5 * 2 * PI / 7), 12 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT);
#ifndef LITE_VERSION
		blobCharacteristics.textureId = 5;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_LOVE;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 26 * SIN(0 * 2 * PI / 7), 26 * COS(0 * 2 * PI / 7), 12 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 6;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_MAZE;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 26 * SIN(1 * 2 * PI / 7), 26 * COS(1 * 2 * PI / 7), 12 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 7;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_PINBALL;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 26 * SIN(3 * 2 * PI / 7), 26 * COS(3 * 2 * PI / 7), 12 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 8;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_SPACE;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 26 * SIN(4 * 2 * PI / 7), 26 * COS(4 * 2 * PI / 7), 12 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 9;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_WASHING;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 26 * SIN(6 * 2 * PI / 7), 26 * COS(6 * 2 * PI / 7), 12 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT);
#else
		blobCharacteristics.textureId = 5;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_FULL_VERSION;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 26 * SIN(0 * 2 * PI / 7), 26 * COS(0 * 2 * PI / 7), 12 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT);
#endif
		BlobShapeRelease(blobShape);

		// There is no default button
		defaultButton = NULL;
	}
	return self;
}

-(void)update
{
	// Handle the first timer (state: slow/fast)
	unsigned char reset;
	unsigned char high;
	if(blobTitleTimer1)
	{
		--blobTitleTimer1;
		reset = BLOB_TITLE_TIMER_RESET_FAST;
		high = BLOB_TITLE_TIMER_HIGH_FAST;
		BlobColorIdSet(blobTitle, 6);
	}
	else
	{
		reset = BLOB_TITLE_TIMER_RESET_SLOW;
		high = BLOB_TITLE_TIMER_HIGH_SLOW;
		BlobColorIdSet(blobTitle, 7);
	}

	// Handle the second timer (pressure: low/high)
	if(blobTitleTimer2 < reset)
	{
		++blobTitleTimer2;
	}
	else
	{
		blobTitleTimer2 = 0;
	}

	// Set the pressure of the title
	if(blobTitleTimer2 < high)
	{
		BlobPressureSet(blobTitle, BLOB_TITLE_PRESSURE_LOW);
	}
	else
	{
		BlobPressureSet(blobTitle, BLOB_TITLE_PRESSURE_HIGH);
	}
}

-(BOOL)handleTouchBegan:(UITouch*)touch withBlob:(BlobReference)blobReference
{
	if(BlobUserIdGet(blobReference) == TYPE_SPECIAL_1)
	{
		if(!blobTitleTimer1)
		{
			blobTitleTimer1 = BLOB_TITLE_TIMER_FAST;
		}
		return YES;
	}
	return NO;
}

-(void)handleTouchEnded:(UITouch*)touch
{
}

@end
