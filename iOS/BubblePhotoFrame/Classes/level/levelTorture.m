#import "levelTorture.h"
#import "math.h"

#define BLOB_MECHANISM_BLENDER_WIDTH  (signed long)(FIXED_POINT * 28.00)
#define BLOB_MECHANISM_BLENDER_HEIGHT (signed long)(FIXED_POINT *  4.00)
#define BLOB_MECHANISM_BLENDER_SPEED  4
#define BLOB_MECHANISM_LIFT_WIDTH     (signed long)(FIXED_POINT * 30.00)
#define BLOB_MECHANISM_LIFT_HEIGHT    (signed long)(FIXED_POINT *  8.00)
#define BLOB_MECHANISM_LIFT_GAP       (signed long)(FIXED_POINT * 16.00)
#define BLOB_MECHANISM_LIFT_SPEED     (signed long)(FIXED_POINT *  0.20)

static Texture const textures[] =
{
	{@"TortureBackground.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"TortureMechanism.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuColorFilter.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuCamera.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuPhotoLibrary.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuMain.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuMechanism.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"BubbleTorture1.png", BLOB_TEXTURE_SIZE_LARGE, YES},
	{@"BubbleTorture2.png", BLOB_TEXTURE_SIZE_LARGE, YES},
	{@"BubbleTorture3.png", BLOB_TEXTURE_SIZE_LARGE, YES},
};

@implementation LevelTorture

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
	return FACEBOOK_PUBLISH_TOP;
}

- (id)init
{
	if(self = [super init])
	{
		// Set the background
		BlobBackgroundTextureIdSet(0);
		BlobBackgroundColorIdSet(0);

		// Create the mechanism button
		BlobCharacteristics blobCharacteristics;
		blobCharacteristics.type = BLOB_TYPE_STATIC_VISIBLE;
		blobCharacteristics.textureId = 6;
		blobCharacteristics.textureRepeat = NO;
		blobCharacteristics.colorId = 1;
		blobCharacteristics.userId = TYPE_SPECIAL_2;
		blobCharacteristics.elasticity = (signed long)(FIXED_POINT * 1.00);
		blobCharacteristics.friction =   (signed long)(FIXED_POINT * 1.00);
		blobCharacteristics.special.staticTransformation = NULL;
		blobCharacteristics.collisionMask = 1;

		BlobShapeReference blobShape = BlobShapeCreateBalloon(12);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, -15 << FIXED_POINT_SHIFT, 0, 10 << FIXED_POINT_SHIFT, 10 << FIXED_POINT_SHIFT);
		BlobShapeRelease(blobShape);

		// Define a box shape
		blobShape = BlobShapeCreateBox();

		// Add mechanisms (blender & lift)
		blobMechanismEnabled = YES;

		blobCharacteristics.type = BLOB_TYPE_STATIC_VISIBLE;
		blobCharacteristics.textureId = 1;
		blobCharacteristics.textureRepeat = YES;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_SPECIAL_1;

		blobMechanismBlenderAngle = 0;
		blobMechanismBlenderTransformation.tX = -15 << FIXED_POINT_SHIFT;
		blobMechanismBlenderTransformation.tY = 0;
		blobMechanismBlenderTransformation.mA = BLOB_MECHANISM_BLENDER_WIDTH;
		blobMechanismBlenderTransformation.mB = 0;
		blobMechanismBlenderTransformation.mC = 0;
		blobMechanismBlenderTransformation.mD = BLOB_MECHANISM_BLENDER_HEIGHT;

		blobCharacteristics.special.staticTransformation = &blobMechanismBlenderTransformation;
		BlobObjectCreate(&blobCharacteristics, blobShape, &blobMechanismBlenderTransformation);

		blobMechanismLiftTransformation.tX = BLOB_CONTAINER_XMAX - (BLOB_MECHANISM_LIFT_WIDTH / 2);
		blobMechanismLiftTransformation.tY = 0;
		blobMechanismLiftTransformation.mA = BLOB_MECHANISM_LIFT_WIDTH;
		blobMechanismLiftTransformation.mB = 0;
		blobMechanismLiftTransformation.mC = 0;
		blobMechanismLiftTransformation.mD = BLOB_MECHANISM_LIFT_HEIGHT;

		blobCharacteristics.special.staticTransformation = &blobMechanismLiftTransformation;
		BlobObjectCreate(&blobCharacteristics, blobShape, &blobMechanismLiftTransformation);

		// Create the container
		blobCharacteristics.type = BLOB_TYPE_STATIC_HIDDEN;
		blobCharacteristics.special.staticTransformation = NULL;

		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_CONTAINER_XMIN - (BLOB_CONTAINER_MARGIN / 2), 0, BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_HEIGHT + BLOB_CONTAINER_MARGIN);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_CONTAINER_XMAX + (BLOB_CONTAINER_MARGIN / 2), 0, BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_HEIGHT + BLOB_CONTAINER_MARGIN);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0, BLOB_CONTAINER_YMIN - (BLOB_CONTAINER_MARGIN / 2), BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_WIDTH + BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0, BLOB_CONTAINER_YMAX + (BLOB_CONTAINER_MARGIN / 2), BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_WIDTH + BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN);

		// Forget about the box shape
		BlobShapeRelease(blobShape);

		// Create several dynamic blobs
		// Note: blobs that are likely to become concave (e.g. big balloons) should be added last so that other blobs will be displayed above, hiding potential drawing errors
		blobCharacteristics.type = BLOB_TYPE_DYNAMIC;
		blobCharacteristics.textureRepeat = NO;
		blobCharacteristics.elasticity =                (signed long)(FIXED_POINT *   0.50);
		blobCharacteristics.friction =                  (signed long)(FIXED_POINT *   1.00);
		blobCharacteristics.special.dynamic.mass =      (signed long)(FIXED_POINT *   1.00);
		blobCharacteristics.special.dynamic.stiffness = (signed long)(FIXED_POINT *   8.00);
		blobCharacteristics.special.dynamic.damping =   (signed long)(FIXED_POINT *   0.00);
		blobCharacteristics.special.dynamic.pressure =  (signed long)(FIXED_POINT * 100.00);

		blobShape = BlobShapeCreateBalloon(16);
		blobCharacteristics.textureId = 4;
		blobCharacteristics.colorId = 4;
		blobCharacteristics.userId = TYPE_BUTTON_PHOTO_LIBRARY;
		defaultButton = BlobObjectCreateEasy(&blobCharacteristics, blobShape, 10 << FIXED_POINT_SHIFT, -50 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 2;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_BUTTON_COLOR_FILTER;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 30 << FIXED_POINT_SHIFT, -50 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		{
			blobCharacteristics.textureId = 3;
			blobCharacteristics.userId = TYPE_BUTTON_CAMERA;
			BlobObjectCreateEasy(&blobCharacteristics, blobShape, -10 << FIXED_POINT_SHIFT, -50 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		}
		blobCharacteristics.textureId = 5;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_MAIN;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, -30 << FIXED_POINT_SHIFT, -50 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		BlobShapeRelease(blobShape);

		blobCharacteristics.userId = TYPE_PHOTO;
		blobCharacteristics.elasticity =                (signed long)(FIXED_POINT *   0.10);
		blobCharacteristics.friction =                  (signed long)(FIXED_POINT *   0.50);
		blobCharacteristics.special.dynamic.mass =      (signed long)(FIXED_POINT *   0.50);
		blobCharacteristics.special.dynamic.stiffness = (signed long)(FIXED_POINT *   2.00);
		blobCharacteristics.special.dynamic.damping =   (signed long)(FIXED_POINT *   0.30);
		blobCharacteristics.special.dynamic.pressure =  (signed long)(FIXED_POINT * 200.00);

		blobShape = BlobShapeCreateBalloon(30);
		blobCharacteristics.textureId = 7;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, -26 << FIXED_POINT_SHIFT, 30 << FIXED_POINT_SHIFT, 22 << FIXED_POINT_SHIFT, 22 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 8;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape,   0 << FIXED_POINT_SHIFT, 30 << FIXED_POINT_SHIFT, 22 << FIXED_POINT_SHIFT, 22 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 9;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape,  26 << FIXED_POINT_SHIFT, 30 << FIXED_POINT_SHIFT, 22 << FIXED_POINT_SHIFT, 22 << FIXED_POINT_SHIFT);
		BlobShapeRelease(blobShape);
	}
	return self;
}

-(void)update
{
	// Check whether the mechanisms are enabled or not
	if(!blobMechanismEnabled)
	{
		return;
	}

	// Rotate the blender's blade
	blobMechanismBlenderAngle += BLOB_MECHANISM_BLENDER_SPEED;
	blobMechanismBlenderTransformation.mA = (BLOB_MECHANISM_BLENDER_WIDTH * COS(blobMechanismBlenderAngle)) >> FIXED_POINT_SHIFT;
	blobMechanismBlenderTransformation.mB = (BLOB_MECHANISM_BLENDER_HEIGHT * SIN(blobMechanismBlenderAngle)) >> FIXED_POINT_SHIFT;
	blobMechanismBlenderTransformation.mC = -(BLOB_MECHANISM_BLENDER_WIDTH * SIN(blobMechanismBlenderAngle)) >> FIXED_POINT_SHIFT;
	blobMechanismBlenderTransformation.mD = (BLOB_MECHANISM_BLENDER_HEIGHT * COS(blobMechanismBlenderAngle)) >> FIXED_POINT_SHIFT;

	// Move the lift
	if(blobMechanismLiftUp)
	{
		if(blobMechanismLiftTransformation.tY < BLOB_CONTAINER_YMAX - BLOB_MECHANISM_LIFT_GAP)
		{
			blobMechanismLiftTransformation.tY += BLOB_MECHANISM_LIFT_SPEED;
		}
		else
		{
			blobMechanismLiftUp = NO;
		}
	}
	else
	{
		if(blobMechanismLiftTransformation.tY > BLOB_CONTAINER_YMIN + BLOB_MECHANISM_LIFT_GAP)
		{
			blobMechanismLiftTransformation.tY -= BLOB_MECHANISM_LIFT_SPEED;
		}
		else
		{
			blobMechanismLiftUp = YES;
		}
	}
}

-(BOOL)handleTouchBegan:(UITouch*)touch withBlob:(BlobReference)blobReference
{
	switch(BlobUserIdGet(blobReference))
	{
		case TYPE_SPECIAL_1:
			return YES;
		case TYPE_SPECIAL_2:
			if(blobMechanismEnabled)
			{
				blobMechanismEnabled = NO;
				BlobColorIdSet(blobReference, 0);
			}
			else
			{
				blobMechanismEnabled = YES;
				BlobColorIdSet(blobReference, 1);
			}
			return YES;
		default:
			return NO;
	}
}

-(void)handleTouchEnded:(UITouch*)touch
{
}

@end
