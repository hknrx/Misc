#import "levelPinball.h"
#import "math.h"

#define BLOB_MECHANISM_BOOSTER_WIDTH      (signed long)(FIXED_POINT *  14.00)
#define BLOB_MECHANISM_BOOSTER_HEIGHT     (signed long)(FIXED_POINT *  26.00)
#define BLOB_MECHANISM_BOOSTER_YMIN       (BLOB_CONTAINER_YMIN - (BLOB_MECHANISM_BOOSTER_HEIGHT / 2) + 2 * FIXED_POINT)
#define BLOB_MECHANISM_BOOSTER_YMAX       (BLOB_CONTAINER_YMIN + (BLOB_MECHANISM_BOOSTER_HEIGHT / 2) - 2 * FIXED_POINT)
#define BLOB_MECHANISM_BOOSTER_SPEED_UP   (signed long)(FIXED_POINT *   6.00)
#define BLOB_MECHANISM_BOOSTER_SPEED_DOWN (signed long)(FIXED_POINT *   0.20)
#define BLOB_MECHANISM_FLIP_WIDTH         (signed long)(FIXED_POINT *  20.00)
#define BLOB_MECHANISM_FLIP_HEIGHT        (signed long)(FIXED_POINT *   4.00)
#define BLOB_MECHANISM_FLIP_X_MARGIN      (signed long)(FIXED_POINT *   6.00)
#define BLOB_MECHANISM_FLIP_X_LEFT        (BLOB_CONTAINER_XMIN + BLOB_MECHANISM_FLIP_X_MARGIN)
#define BLOB_MECHANISM_FLIP_X_RIGHT       (BLOB_CONTAINER_XMAX - BLOB_MECHANISM_FLIP_X_MARGIN)
#define BLOB_MECHANISM_FLIP_Y             (signed long)(FIXED_POINT * -25.00)
#define BLOB_MECHANISM_FLIP_ANGLE         (PI / 6)
#define BLOB_MECHANISM_FLIP_ANGLE_SPEED   (PI / 12)

static Texture const textures[] =
{
	{@"PinballBackground.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"PinballMechanism.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuPhotoLibrary.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuColorFilter.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuCamera.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuMain.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuMechanism.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"BubblePinball1.png", BLOB_TEXTURE_SIZE_LARGE, YES},
	{@"BubblePinball2.png", BLOB_TEXTURE_SIZE_LARGE, YES},
};

@implementation LevelPinball

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

- (void)updateBlobMechanismFlipTransformation
{
	// Left flip
	signed long cos = COS(blobMechanismFlipLeftAngle);
	signed long sin = SIN(blobMechanismFlipLeftAngle);

	blobMechanismFlipLeftTransformation.mA = (BLOB_MECHANISM_FLIP_WIDTH * cos) >> FIXED_POINT_SHIFT;
	blobMechanismFlipLeftTransformation.mB = -(BLOB_MECHANISM_FLIP_HEIGHT * sin) >> FIXED_POINT_SHIFT;
	blobMechanismFlipLeftTransformation.mC = (BLOB_MECHANISM_FLIP_WIDTH * sin) >> FIXED_POINT_SHIFT;
	blobMechanismFlipLeftTransformation.mD = (BLOB_MECHANISM_FLIP_HEIGHT * cos) >> FIXED_POINT_SHIFT;
	blobMechanismFlipLeftTransformation.tX = BLOB_MECHANISM_FLIP_X_LEFT + (blobMechanismFlipLeftTransformation.mA >> 1);
	blobMechanismFlipLeftTransformation.tY = BLOB_MECHANISM_FLIP_Y + (blobMechanismFlipLeftTransformation.mC >> 1);

	// Right flip
	cos = COS(blobMechanismFlipRightAngle);
	sin = SIN(blobMechanismFlipRightAngle);

	blobMechanismFlipRightTransformation.mA = (BLOB_MECHANISM_FLIP_WIDTH * cos) >> FIXED_POINT_SHIFT;
	blobMechanismFlipRightTransformation.mB = -(BLOB_MECHANISM_FLIP_HEIGHT * sin) >> FIXED_POINT_SHIFT;
	blobMechanismFlipRightTransformation.mC = (BLOB_MECHANISM_FLIP_WIDTH * sin) >> FIXED_POINT_SHIFT;
	blobMechanismFlipRightTransformation.mD = (BLOB_MECHANISM_FLIP_HEIGHT * cos) >> FIXED_POINT_SHIFT;
	blobMechanismFlipRightTransformation.tX = BLOB_MECHANISM_FLIP_X_RIGHT - (blobMechanismFlipRightTransformation.mA >> 1);
	blobMechanismFlipRightTransformation.tY = BLOB_MECHANISM_FLIP_Y - (blobMechanismFlipRightTransformation.mC >> 1);
}

- (id)init
{
	if(self = [super init])
	{
		// Set the background
		BlobBackgroundTextureIdSet(0);
		BlobBackgroundColorIdSet(0);

		// Create the menu buttons
		BlobCharacteristics blobCharacteristics;
		blobCharacteristics.type = BLOB_TYPE_STATIC_VISIBLE;
		blobCharacteristics.textureRepeat = NO;
		blobCharacteristics.elasticity = (signed long)(FIXED_POINT * 3.00);
		blobCharacteristics.friction =   (signed long)(FIXED_POINT * 1.00);
		blobCharacteristics.special.staticTransformation = NULL;
		blobCharacteristics.collisionMask = 1;

		BlobShapeReference blobShapeBalloon = BlobShapeCreateBalloon(16);
		blobCharacteristics.textureId = 2;
		blobCharacteristics.colorId = 4;
		blobCharacteristics.userId = TYPE_BUTTON_PHOTO_LIBRARY;
		defaultButton = BlobObjectCreateEasy(&blobCharacteristics, blobShapeBalloon, 13 << FIXED_POINT_SHIFT, 50 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 3;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_BUTTON_COLOR_FILTER;
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeBalloon, 30 << FIXED_POINT_SHIFT, 50 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		{
			blobCharacteristics.textureId = 4;
			blobCharacteristics.userId = TYPE_BUTTON_CAMERA;
			BlobObjectCreateEasy(&blobCharacteristics, blobShapeBalloon, -4 << FIXED_POINT_SHIFT, 50 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		}
		blobCharacteristics.textureId = 5;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_MAIN;
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeBalloon, -30 << FIXED_POINT_SHIFT, 50 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		BlobShapeRelease(blobShapeBalloon);

		// Create the flip buttons
		blobCharacteristics.elasticity = (signed long)(FIXED_POINT * 0.20);
		blobCharacteristics.textureId = 6;
		blobCharacteristics.colorId = 1;
		blobShapeBalloon = BlobShapeCreateBalloon(12);
		blobCharacteristics.userId = TYPE_SPECIAL_2;
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeBalloon, BLOB_MECHANISM_FLIP_X_LEFT, BLOB_MECHANISM_FLIP_Y, 10 << FIXED_POINT_SHIFT, 10 << FIXED_POINT_SHIFT);
		blobCharacteristics.userId = TYPE_SPECIAL_3;
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeBalloon, BLOB_MECHANISM_FLIP_X_RIGHT, BLOB_MECHANISM_FLIP_Y, 10 << FIXED_POINT_SHIFT, 10 << FIXED_POINT_SHIFT);
		BlobShapeRelease(blobShapeBalloon);

		// Define a box shape
		BlobShapeReference blobShapeBox = BlobShapeCreateBox();

		// Create the container
		blobCharacteristics.type = BLOB_TYPE_STATIC_HIDDEN;
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeBox, BLOB_CONTAINER_XMIN - (BLOB_CONTAINER_MARGIN / 2), 0, BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_HEIGHT + BLOB_CONTAINER_MARGIN);
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeBox, BLOB_CONTAINER_XMAX + (BLOB_CONTAINER_MARGIN / 2), 0, BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_HEIGHT + BLOB_CONTAINER_MARGIN);
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeBox, 0, BLOB_CONTAINER_YMAX + (BLOB_CONTAINER_MARGIN / 2), BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_WIDTH + BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN);

		blobCharacteristics.type = BLOB_TYPE_STATIC_VISIBLE;
		blobCharacteristics.textureId = 1;
		blobCharacteristics.textureRepeat = YES;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_SPECIAL_1;

		BlobTransformation blobTransformation;
		blobTransformation.tY = -55 << FIXED_POINT_SHIFT;
		blobTransformation.mA =  30 << FIXED_POINT_SHIFT;
		blobTransformation.mB =   0 << FIXED_POINT_SHIFT;
		blobTransformation.mD =  25 << FIXED_POINT_SHIFT;

		blobTransformation.tX = -25 << FIXED_POINT_SHIFT;
		blobTransformation.mC = -15 << FIXED_POINT_SHIFT;
		BlobObjectCreate(&blobCharacteristics, blobShapeBox, &blobTransformation);

		blobTransformation.tX = 25 << FIXED_POINT_SHIFT;
		blobTransformation.mC = 15 << FIXED_POINT_SHIFT;
		BlobObjectCreate(&blobCharacteristics, blobShapeBox, &blobTransformation);

		// Create the mechanisms
		blobMechanismBoosterUp = NO;
		blobMechanismBoosterTransformation.tX = 0;
		blobMechanismBoosterTransformation.tY = BLOB_CONTAINER_YMIN;
		blobMechanismBoosterTransformation.mA = BLOB_MECHANISM_BOOSTER_WIDTH;
		blobMechanismBoosterTransformation.mB = 0;
		blobMechanismBoosterTransformation.mC = 0;
		blobMechanismBoosterTransformation.mD = BLOB_MECHANISM_BOOSTER_HEIGHT;

		blobCharacteristics.textureId = -1;
		blobCharacteristics.special.staticTransformation = &blobMechanismBoosterTransformation;
		BlobObjectCreate(&blobCharacteristics, blobShapeBox, &blobMechanismBoosterTransformation);

		blobMechanismFlipLeft = nil;
		blobMechanismFlipLeftAngle = -BLOB_MECHANISM_FLIP_ANGLE;
		blobMechanismFlipRight = nil;
		blobMechanismFlipRightAngle = BLOB_MECHANISM_FLIP_ANGLE;
		[self updateBlobMechanismFlipTransformation];

		blobCharacteristics.special.staticTransformation = &blobMechanismFlipLeftTransformation;
		BlobObjectCreate(&blobCharacteristics, blobShapeBox, &blobMechanismFlipLeftTransformation);
		blobCharacteristics.special.staticTransformation = &blobMechanismFlipRightTransformation;
		BlobObjectCreate(&blobCharacteristics, blobShapeBox, &blobMechanismFlipRightTransformation);

		// Create several dynamic blobs
		// Note: blobs that are likely to become concave (e.g. big balloons) should be added last so that other blobs will be displayed above, hiding potential drawing errors
		blobCharacteristics.type = BLOB_TYPE_DYNAMIC;
		blobCharacteristics.textureRepeat = NO;
		blobCharacteristics.userId = TYPE_PHOTO;
		blobCharacteristics.elasticity =                (signed long)(FIXED_POINT *   0.80);
		blobCharacteristics.friction =                  (signed long)(FIXED_POINT *   0.50);
		blobCharacteristics.special.dynamic.mass =      (signed long)(FIXED_POINT *   0.30);
		blobCharacteristics.special.dynamic.stiffness = (signed long)(FIXED_POINT *   8.00);
		blobCharacteristics.special.dynamic.damping =   (signed long)(FIXED_POINT *   0.50);
		blobCharacteristics.special.dynamic.pressure =  (signed long)(FIXED_POINT * 200.00);

		blobShapeBalloon = BlobShapeCreateBalloon(24);
		blobCharacteristics.textureId = 7;
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeBalloon, -18 << FIXED_POINT_SHIFT, 10 << FIXED_POINT_SHIFT, 24 << FIXED_POINT_SHIFT, 24 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 8;
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeBalloon,  18 << FIXED_POINT_SHIFT, 10 << FIXED_POINT_SHIFT, 24 << FIXED_POINT_SHIFT, 24 << FIXED_POINT_SHIFT);
		BlobShapeRelease(blobShapeBalloon);

		// Forget about the box shape
		BlobShapeRelease(blobShapeBox);
	}
	return self;
}

-(void)update
{
	// Handle the booster
	if(blobMechanismBoosterUp)
	{
		blobMechanismBoosterTransformation.tY += BLOB_MECHANISM_BOOSTER_SPEED_UP;
		if(blobMechanismBoosterTransformation.tY > BLOB_MECHANISM_BOOSTER_YMAX)
		{
			blobMechanismBoosterTransformation.tY = BLOB_MECHANISM_BOOSTER_YMAX;
			blobMechanismBoosterUp = NO;
		}
	}
	else
	{
		blobMechanismBoosterTransformation.tY -= BLOB_MECHANISM_BOOSTER_SPEED_DOWN;
		if(blobMechanismBoosterTransformation.tY < BLOB_MECHANISM_BOOSTER_YMIN)
		{
			blobMechanismBoosterTransformation.tY = BLOB_MECHANISM_BOOSTER_YMIN;
			blobMechanismBoosterUp = YES;
		}
	}

	// Handle the left flip
	if(blobMechanismFlipLeft)
	{
		blobMechanismFlipLeftAngle += BLOB_MECHANISM_FLIP_ANGLE_SPEED;
		if(blobMechanismFlipLeftAngle > BLOB_MECHANISM_FLIP_ANGLE)
		{
			blobMechanismFlipLeftAngle = BLOB_MECHANISM_FLIP_ANGLE;
		}
	}
	else
	{
		blobMechanismFlipLeftAngle -= BLOB_MECHANISM_FLIP_ANGLE_SPEED;
		if(blobMechanismFlipLeftAngle < -BLOB_MECHANISM_FLIP_ANGLE)
		{
			blobMechanismFlipLeftAngle = -BLOB_MECHANISM_FLIP_ANGLE;
		}
	}

	// Handle the right flip
	if(blobMechanismFlipRight)
	{
		blobMechanismFlipRightAngle -= BLOB_MECHANISM_FLIP_ANGLE_SPEED;
		if(blobMechanismFlipRightAngle < -BLOB_MECHANISM_FLIP_ANGLE)
		{
			blobMechanismFlipRightAngle = -BLOB_MECHANISM_FLIP_ANGLE;
		}
	}
	else
	{
		blobMechanismFlipRightAngle += BLOB_MECHANISM_FLIP_ANGLE_SPEED;
		if(blobMechanismFlipRightAngle > BLOB_MECHANISM_FLIP_ANGLE)
		{
			blobMechanismFlipRightAngle = BLOB_MECHANISM_FLIP_ANGLE;
		}
	}

	// Update the flips' transformation information
	[self updateBlobMechanismFlipTransformation];
}

-(BOOL)handleTouchBegan:(UITouch*)touch withBlob:(BlobReference)blobReference
{
	switch(BlobUserIdGet(blobReference))
	{
		case TYPE_SPECIAL_1:
			return YES;
		case TYPE_SPECIAL_2:
			blobMechanismFlipLeft = touch;
			return YES;
		case TYPE_SPECIAL_3:
			blobMechanismFlipRight = touch;
			return YES;
		default:
			return NO;
	}
}

-(void)handleTouchEnded:(UITouch*)touch
{
	if(touch == blobMechanismFlipLeft)
	{
		blobMechanismFlipLeft = nil;
	}
	else if(touch == blobMechanismFlipRight)
	{
		blobMechanismFlipRight = nil;
	}
}

@end
