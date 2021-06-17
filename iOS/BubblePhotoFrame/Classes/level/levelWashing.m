#import "levelWashing.h"
#import "math.h"

#define BLOB_MECHANISM_BARREL_COUNT     16
#define BLOB_MECHANISM_BARREL_RADIUS    (signed long)(FIXED_POINT * 42.00)
#define BLOB_MECHANISM_BARREL_WIDTH     (signed long)(FIXED_POINT *  6.00)
#define BLOB_MECHANISM_BARREL_LENGTH    (((BLOB_MECHANISM_BARREL_RADIUS + (BLOB_MECHANISM_BARREL_WIDTH / 2)) * SIN(PI / BLOB_MECHANISM_BARREL_COUNT)) >> (FIXED_POINT_SHIFT - 1))
#define BLOB_MECHANISM_BARREL_TRANSLATE ((BLOB_MECHANISM_BARREL_RADIUS * COS(PI / BLOB_MECHANISM_BARREL_COUNT)) >> FIXED_POINT_SHIFT)
#define BLOB_MECHANISM_BLADE_COUNT      3
#define BLOB_MECHANISM_BLADE_WIDTH      (signed long)(FIXED_POINT *  3.00)
#define BLOB_MECHANISM_BLADE_LENGTH     (signed long)(FIXED_POINT * 10.00)
#define BLOB_MECHANISM_SPEED_SLOW       1
#define BLOB_MECHANISM_SPEED_FAST       5
#define BLOB_MECHANISM_TIMER            150

static Texture const textures[] =
{
	{@"WashingBackground.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"WashingMechanism.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuPhotoLibrary.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuColorFilter.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuCamera.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuMain.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuMechanism.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"BubbleWashing1.png", BLOB_TEXTURE_SIZE_LARGE, YES},
	{@"BubbleWashing2.png", BLOB_TEXTURE_SIZE_LARGE, YES},
	{@"BubbleWashing3.png", BLOB_TEXTURE_SIZE_LARGE, YES},
};

@implementation LevelWashing

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
	return FACEBOOK_PUBLISH_BOTTOM;
}

- (void)updateBlobMechanismTransformation
{
	// Set the transformation information of the barrel's elements
	BlobTransformation* transformation;
	unsigned char angle = blobMechanismAngle + (PI / BLOB_MECHANISM_BARREL_COUNT);
	for(unsigned char element = 0; element < BLOB_MECHANISM_BARREL_COUNT; ++element)
	{
		transformation = &blobMechanismTransformation[element];
		signed long const cos = COS(angle);
		signed long const sin = SIN(angle);

		transformation->tX = (BLOB_MECHANISM_BARREL_TRANSLATE * cos) >> FIXED_POINT_SHIFT;
		transformation->tY = ((BLOB_MECHANISM_BARREL_TRANSLATE * sin) >> FIXED_POINT_SHIFT) - (9 << FIXED_POINT_SHIFT);
		transformation->mA = (BLOB_MECHANISM_BARREL_WIDTH * cos) >> FIXED_POINT_SHIFT;
		transformation->mB = -(BLOB_MECHANISM_BARREL_LENGTH * sin) >> FIXED_POINT_SHIFT;
		transformation->mC = (BLOB_MECHANISM_BARREL_WIDTH * sin) >> FIXED_POINT_SHIFT;
		transformation->mD = (BLOB_MECHANISM_BARREL_LENGTH * cos) >> FIXED_POINT_SHIFT;

		angle += 2 * PI / BLOB_MECHANISM_BARREL_COUNT;
	}

	// Set the transformation information of the blades
	angle = blobMechanismAngle;
	for(unsigned char element = 0; element < BLOB_MECHANISM_BLADE_COUNT; ++element)
	{
		transformation = &blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + element];
		signed long const cos = COS(angle);
		signed long const sin = SIN(angle);

		transformation->tX = ((BLOB_MECHANISM_BARREL_TRANSLATE - BLOB_MECHANISM_BLADE_LENGTH / 2) * cos) >> FIXED_POINT_SHIFT;
		transformation->tY = (((BLOB_MECHANISM_BARREL_TRANSLATE - BLOB_MECHANISM_BLADE_LENGTH / 2) * sin) >> FIXED_POINT_SHIFT) - (9 << FIXED_POINT_SHIFT);
		transformation->mA = (BLOB_MECHANISM_BLADE_LENGTH * cos) >> FIXED_POINT_SHIFT;
		transformation->mB = -(BLOB_MECHANISM_BLADE_WIDTH * sin) >> FIXED_POINT_SHIFT;
		transformation->mC = (BLOB_MECHANISM_BLADE_LENGTH * sin) >> FIXED_POINT_SHIFT;
		transformation->mD = (BLOB_MECHANISM_BLADE_WIDTH * cos) >> FIXED_POINT_SHIFT;

		angle += 2 * PI / BLOB_MECHANISM_BLADE_COUNT;
	}

	// Set the transformation information of the background
	transformation = &blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT];
	transformation->mA = (COS(blobMechanismAngle) * BLOB_MECHANISM_BARREL_RADIUS) >> (FIXED_POINT_SHIFT - 1);
	transformation->mC = (SIN(blobMechanismAngle) * BLOB_MECHANISM_BARREL_RADIUS) >> (FIXED_POINT_SHIFT - 1);
	transformation->mB = -transformation->mC;
	transformation->mD = transformation->mA;

	// Set the transformation information of the buttons
	for(unsigned char element = 0; element < 5; ++element)
	{
		transformation = &blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT + 1 + element];
		if(blobMechanismTimer)
		{
			transformation->tY = (50 - 0.4) * FIXED_POINT + MathRand(0.8 * FIXED_POINT);
		}
		else
		{
			transformation->tY = (50 - 0.1) * FIXED_POINT + MathRand(0.2 * FIXED_POINT);
		}
	}
}

- (void)setBlobMechanismTransformation
{
	// Set the background's translation
	BlobTransformation* transformation = &blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT];
	transformation->tX = 0;
	transformation->tY = -12 << FIXED_POINT_SHIFT;

	// Set the X-coordinate and the rotation matrix of each button
	blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT + 1 + 0].tX =   2 << FIXED_POINT_SHIFT;
	blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT + 1 + 1].tX =  16 << FIXED_POINT_SHIFT;
	blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT + 1 + 2].tX = -12 << FIXED_POINT_SHIFT;
	blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT + 1 + 3].tX = -30 << FIXED_POINT_SHIFT;
	blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT + 1 + 4].tX =  30 << FIXED_POINT_SHIFT;
	for(unsigned char element = 0; element < 5; ++element)
	{
		transformation = &blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT + 1 + element];
		transformation->mA = 12 << FIXED_POINT_SHIFT;
		transformation->mB = 0;
		transformation->mC = 0;
		transformation->mD = 12 << FIXED_POINT_SHIFT;
	}

	// Set all the other transformation information
	[self updateBlobMechanismTransformation];
}

- (id)init
{
	if(self = [super init])
	{
		// Set the background
		BlobBackgroundTextureIdSet(-1);
		BlobBackgroundColorIdSet(7);

		// Define a box shape
		BlobShapeReference blobShapeBox = BlobShapeCreateBox();

		// Create the container
		blobMechanismAngle = 0;
		blobMechanismTimer = 0;
		blobMechanismTransformation = (BlobTransformation*)malloc((BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT + 1 + 5) * sizeof(BlobTransformation));
		[self setBlobMechanismTransformation];

		BlobCharacteristics blobCharacteristics;
		blobCharacteristics.type = BLOB_TYPE_STATIC_VISIBLE;
		blobCharacteristics.textureId = 1;
		blobCharacteristics.textureRepeat = YES;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_SPECIAL_1;
		blobCharacteristics.elasticity = (signed long)(FIXED_POINT * 0.50);
		blobCharacteristics.friction =   (signed long)(FIXED_POINT * 0.20);
		blobCharacteristics.collisionMask = 1;

		for(unsigned char element = 0; element < BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT; ++element)
		{
			blobCharacteristics.special.staticTransformation = &blobMechanismTransformation[element];
			BlobObjectCreate(&blobCharacteristics, blobShapeBox, blobCharacteristics.special.staticTransformation);
		}

		// Create the buttons
		blobCharacteristics.textureRepeat = NO;
		blobCharacteristics.elasticity = (signed long)(FIXED_POINT * 0.50);
		blobCharacteristics.friction =   (signed long)(FIXED_POINT * 1.00);
		blobCharacteristics.collisionMask = 0;

		BlobShapeReference blobShapeBalloon = BlobShapeCreateBalloon(16);
		blobCharacteristics.textureId = 2;
		blobCharacteristics.colorId = 4;
		blobCharacteristics.userId = TYPE_BUTTON_PHOTO_LIBRARY;
		blobCharacteristics.special.staticTransformation = &blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT + 1 + 0];
		defaultButton = BlobObjectCreate(&blobCharacteristics, blobShapeBalloon, blobCharacteristics.special.staticTransformation);
		blobCharacteristics.textureId = 3;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_BUTTON_COLOR_FILTER;
		blobCharacteristics.special.staticTransformation = &blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT + 1 + 1];
		BlobObjectCreate(&blobCharacteristics, blobShapeBalloon, blobCharacteristics.special.staticTransformation);
		if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		{
			blobCharacteristics.textureId = 4;
			blobCharacteristics.userId = TYPE_BUTTON_CAMERA;
			blobCharacteristics.special.staticTransformation = &blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT + 1 + 2];
			BlobObjectCreate(&blobCharacteristics, blobShapeBalloon, blobCharacteristics.special.staticTransformation);
		}
		blobCharacteristics.textureId = 5;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_MAIN;
		blobCharacteristics.special.staticTransformation = &blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT + 1 + 3];
		BlobObjectCreate(&blobCharacteristics, blobShapeBalloon, blobCharacteristics.special.staticTransformation);
		blobCharacteristics.textureId = 6;
		blobCharacteristics.colorId = 0;
		blobCharacteristics.userId = TYPE_SPECIAL_2;
		blobCharacteristics.special.staticTransformation = &blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT + 1 + 4];
		blobMechanismButton = BlobObjectCreate(&blobCharacteristics, blobShapeBalloon, blobCharacteristics.special.staticTransformation);
		BlobShapeRelease(blobShapeBalloon);

		// Create several dynamic blobs
		// Note: blobs that are likely to become concave (e.g. big balloons) should be added last so that other blobs will be displayed above, hiding potential drawing errors
		blobCharacteristics.type = BLOB_TYPE_DYNAMIC;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_PHOTO;
		blobCharacteristics.elasticity =                (signed long)(FIXED_POINT *   0.10);
		blobCharacteristics.friction =                  (signed long)(FIXED_POINT *   0.50);
		blobCharacteristics.special.dynamic.mass =      (signed long)(FIXED_POINT *   0.50);
		blobCharacteristics.special.dynamic.stiffness = (signed long)(FIXED_POINT *   1.50);
		blobCharacteristics.special.dynamic.damping =   (signed long)(FIXED_POINT *   0.30);
		blobCharacteristics.special.dynamic.pressure =  (signed long)(FIXED_POINT * 100.00);
		blobCharacteristics.collisionMask = 1;

		blobShapeBalloon = BlobShapeCreateBalloon(30);
		blobCharacteristics.textureId = 7;
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeBalloon,   0 << FIXED_POINT_SHIFT,   8 << FIXED_POINT_SHIFT, 22 << FIXED_POINT_SHIFT, 22 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 8;
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeBalloon, -17 << FIXED_POINT_SHIFT, -22 << FIXED_POINT_SHIFT, 22 << FIXED_POINT_SHIFT, 22 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 9;
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeBalloon,  17 << FIXED_POINT_SHIFT, -22 << FIXED_POINT_SHIFT, 22 << FIXED_POINT_SHIFT, 22 << FIXED_POINT_SHIFT);
		BlobShapeRelease(blobShapeBalloon);

		// Create the background
		blobCharacteristics.type = BLOB_TYPE_STATIC_VISIBLE;
		blobCharacteristics.textureId = 0;
		blobCharacteristics.textureRepeat = YES;
		blobCharacteristics.userId = TYPE_SPECIAL_1;
		blobCharacteristics.special.staticTransformation = &blobMechanismTransformation[BLOB_MECHANISM_BARREL_COUNT + BLOB_MECHANISM_BLADE_COUNT];
		blobCharacteristics.collisionMask = 0;
		blobShapeBalloon = BlobShapeCreateBalloon(BLOB_MECHANISM_BARREL_COUNT);
		BlobObjectCreate(&blobCharacteristics, blobShapeBalloon, blobCharacteristics.special.staticTransformation);
		BlobShapeRelease(blobShapeBalloon);

		// Create the panel
		blobCharacteristics.textureId = 1;
		blobCharacteristics.special.staticTransformation = NULL;
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeBox, 0, 50 << FIXED_POINT_SHIFT, 76 << FIXED_POINT_SHIFT, 16 << FIXED_POINT_SHIFT);

		// Forget about the box shape
		BlobShapeRelease(blobShapeBox);
	}
	return self;
}

-(void)update
{
	if(blobMechanismTimer)
	{
		--blobMechanismTimer;
		blobMechanismAngle -= BLOB_MECHANISM_SPEED_FAST;
		BlobColorIdSet(blobMechanismButton, 1);
	}
	else
	{
		blobMechanismAngle -= BLOB_MECHANISM_SPEED_SLOW;
		BlobColorIdSet(blobMechanismButton, 0);
	}
	[self updateBlobMechanismTransformation];
}

-(BOOL)handleTouchBegan:(UITouch*)touch withBlob:(BlobReference)blobReference
{
	switch(BlobUserIdGet(blobReference))
	{
		case TYPE_SPECIAL_1:
			return YES;
		case TYPE_SPECIAL_2:
			if(!blobMechanismTimer)
			{
				blobMechanismTimer = BLOB_MECHANISM_TIMER;
			}
			return YES;
		default:
			return NO;
	}
}

-(void)handleTouchEnded:(UITouch*)touch
{
}

- (void)dealloc
{
	// Free the memory allocated for the transformation matrices
	free(blobMechanismTransformation);

	// Complete the deallocation of the object
	[super dealloc];
}

@end
