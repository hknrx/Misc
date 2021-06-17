#import "levelLove.h"
#import "math.h"

#define BLOB_FRAME_WIDTH (signed long)(FIXED_POINT * 8.00)

static Texture const textures[] =
{
	{@"LoveBackground.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"LoveFrame.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuPhotoLibrary.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuColorFilter.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuCamera.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuMain.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"BubbleLove.png", BLOB_TEXTURE_SIZE_LARGE, YES},
};

@implementation LevelLove

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
		BlobBackgroundColorIdSet(7);

		// Define a button shape
		BlobShapeReference blobShapeButton = BlobShapeCreateBalloon(16);

		// Create the static button
		BlobCharacteristics blobCharacteristics;
		blobCharacteristics.type = BLOB_TYPE_STATIC_VISIBLE;
		blobCharacteristics.textureId = 5;
		blobCharacteristics.textureRepeat = NO;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_MAIN;
		blobCharacteristics.elasticity = (signed long)(FIXED_POINT * 1.00);
		blobCharacteristics.friction =   (signed long)(FIXED_POINT * 1.00);
		blobCharacteristics.special.staticTransformation = NULL;
		blobCharacteristics.collisionMask = 1;
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeButton, -33 << FIXED_POINT_SHIFT, -53 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);

		// Create the frame
		blobCharacteristics.textureId = 1;
		blobCharacteristics.textureRepeat = YES;
		blobCharacteristics.userId = TYPE_SPECIAL_1;

		BlobShapeReference blobShapeMisc = BlobShapeCreateBox();
		BlobTransformation blobTransformation;
		blobTransformation.tX = -BLOB_FRAME_WIDTH / 2;
		blobTransformation.tY = BLOB_CONTAINER_YMIN + (BLOB_FRAME_WIDTH / 2);
		blobTransformation.mA = BLOB_CONTAINER_WIDTH;
		blobTransformation.mB = -BLOB_FRAME_WIDTH;
		blobTransformation.mC = 0;
		blobTransformation.mD = BLOB_FRAME_WIDTH;
		BlobObjectCreate(&blobCharacteristics, blobShapeMisc, &blobTransformation);
		blobTransformation.tX = BLOB_CONTAINER_XMAX - (BLOB_FRAME_WIDTH / 2);
		blobTransformation.tY = -BLOB_FRAME_WIDTH / 2;
		blobTransformation.mA = BLOB_FRAME_WIDTH;
		blobTransformation.mB = 0;
		blobTransformation.mC = BLOB_FRAME_WIDTH;
		blobTransformation.mD = BLOB_CONTAINER_HEIGHT;
		BlobObjectCreate(&blobCharacteristics, blobShapeMisc, &blobTransformation);
		blobTransformation.tX = BLOB_FRAME_WIDTH / 2;
		blobTransformation.tY = BLOB_CONTAINER_YMAX - (BLOB_FRAME_WIDTH / 2);
		blobTransformation.mA = BLOB_CONTAINER_WIDTH;
		blobTransformation.mB = -BLOB_FRAME_WIDTH;
		blobTransformation.mC = 0;
		blobTransformation.mD = BLOB_FRAME_WIDTH;
		BlobObjectCreate(&blobCharacteristics, blobShapeMisc, &blobTransformation);
		blobTransformation.tX = BLOB_CONTAINER_XMIN + (BLOB_FRAME_WIDTH / 2);
		blobTransformation.tY = BLOB_FRAME_WIDTH / 2;
		blobTransformation.mA = BLOB_FRAME_WIDTH;
		blobTransformation.mB = 0;
		blobTransformation.mC = BLOB_FRAME_WIDTH;
		blobTransformation.mD = BLOB_CONTAINER_HEIGHT;
		BlobObjectCreate(&blobCharacteristics, blobShapeMisc, &blobTransformation);
		BlobShapeRelease(blobShapeMisc);

		// Create the dynamic buttons
		blobCharacteristics.type = BLOB_TYPE_DYNAMIC;
		blobCharacteristics.textureRepeat = NO;
		blobCharacteristics.special.dynamic.mass =      (signed long)(FIXED_POINT *  1.00);
		blobCharacteristics.special.dynamic.stiffness = (signed long)(FIXED_POINT *  4.00);
		blobCharacteristics.special.dynamic.damping =   (signed long)(FIXED_POINT *  0.20);
		blobCharacteristics.special.dynamic.pressure =  (signed long)(FIXED_POINT * 60.00);

		blobCharacteristics.textureId = 2;
		blobCharacteristics.colorId = 4;
		blobCharacteristics.userId = TYPE_BUTTON_PHOTO_LIBRARY;
		defaultButton = BlobObjectCreateEasy(&blobCharacteristics, blobShapeButton, BLOB_CONTAINER_XMAX - BLOB_FRAME_WIDTH - (25 << FIXED_POINT_SHIFT), BLOB_CONTAINER_YMIN + BLOB_FRAME_WIDTH + (9 << FIXED_POINT_SHIFT), 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 3;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_BUTTON_COLOR_FILTER;
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeButton, BLOB_CONTAINER_XMAX - BLOB_FRAME_WIDTH - (9 << FIXED_POINT_SHIFT), BLOB_CONTAINER_YMIN + BLOB_FRAME_WIDTH + (9 << FIXED_POINT_SHIFT), 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		{
			blobCharacteristics.textureId = 4;
			blobCharacteristics.userId = TYPE_BUTTON_CAMERA;
			BlobObjectCreateEasy(&blobCharacteristics, blobShapeButton, BLOB_CONTAINER_XMAX - BLOB_FRAME_WIDTH - (41 << FIXED_POINT_SHIFT), BLOB_CONTAINER_YMIN + BLOB_FRAME_WIDTH + (9 << FIXED_POINT_SHIFT), 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		}

		// Forget about the button shape
		BlobShapeRelease(blobShapeButton);

		// Create a dynamic blob
		// Note: blobs that are likely to become concave (e.g. big balloons) should be added last so that other blobs will be displayed above, hiding potential drawing errors
		blobCharacteristics.type = BLOB_TYPE_DYNAMIC;
		blobCharacteristics.textureId = 6;
		blobCharacteristics.textureRepeat = NO;
		blobCharacteristics.userId = TYPE_PHOTO;
		blobCharacteristics.elasticity =                (signed long)(FIXED_POINT *   0.10);
		blobCharacteristics.friction =                  (signed long)(FIXED_POINT *   0.50);
		blobCharacteristics.special.dynamic.mass =      (signed long)(FIXED_POINT *   0.50);
		blobCharacteristics.special.dynamic.stiffness = (signed long)(FIXED_POINT *   2.00);
		blobCharacteristics.special.dynamic.damping =   (signed long)(FIXED_POINT *   0.30);
		blobCharacteristics.special.dynamic.pressure =  (signed long)(FIXED_POINT * 250.00);

		blobShapeMisc = BlobShapeCreateBalloon(36);
		BlobObjectCreateEasy(&blobCharacteristics, blobShapeMisc, 0, 0, 26 << FIXED_POINT_SHIFT, 26 << FIXED_POINT_SHIFT);
		BlobShapeRelease(blobShapeMisc);
	}
	return self;
}

-(void)update
{
}

-(BOOL)handleTouchBegan:(UITouch*)touch withBlob:(BlobReference)blobReference
{
	return BlobUserIdGet(blobReference) == TYPE_SPECIAL_1;
}

-(void)handleTouchEnded:(UITouch*)touch
{
}

@end
