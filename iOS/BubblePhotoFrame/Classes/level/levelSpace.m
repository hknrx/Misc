#import "levelSpace.h"
#import "math.h"

static Texture const textures[] =
{
	{@"SpaceBackground.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuMain.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuColorFilter.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuCamera.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuPhotoLibrary.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"BubbleSpace.png", BLOB_TEXTURE_SIZE_LARGE, YES},
};

@implementation LevelSpace

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

		// Create the container
		BlobCharacteristics blobCharacteristics;
		blobCharacteristics.type = BLOB_TYPE_STATIC_HIDDEN;
		blobCharacteristics.userId = TYPE_SPECIAL_1;
		blobCharacteristics.elasticity = (signed long)(FIXED_POINT * 0.10);
		blobCharacteristics.friction =   (signed long)(FIXED_POINT * 1.00);
		blobCharacteristics.special.staticTransformation = NULL;
		blobCharacteristics.collisionMask = 1;

		BlobShapeReference blobShape = BlobShapeCreateBox();
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_CONTAINER_XMIN - (BLOB_CONTAINER_MARGIN / 2), 0, BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_HEIGHT + BLOB_CONTAINER_MARGIN);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_CONTAINER_XMAX + (BLOB_CONTAINER_MARGIN / 2), 0, BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_HEIGHT + BLOB_CONTAINER_MARGIN);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0, BLOB_CONTAINER_YMIN - (BLOB_CONTAINER_MARGIN / 2), BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_WIDTH + BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0, BLOB_CONTAINER_YMAX + (BLOB_CONTAINER_MARGIN / 2), BLOB_CONTAINER_MARGIN + BLOB_CONTAINER_WIDTH + BLOB_CONTAINER_MARGIN, BLOB_CONTAINER_MARGIN);
		BlobShapeRelease(blobShape);

		// Define a button shape
		blobShape = BlobShapeCreateBalloon(16);

		// Create the dynamic buttons
		blobCharacteristics.type = BLOB_TYPE_DYNAMIC;
		blobCharacteristics.textureRepeat = NO;
		blobCharacteristics.special.dynamic.mass =      (signed long)(FIXED_POINT *  0.30);
		blobCharacteristics.special.dynamic.stiffness = (signed long)(FIXED_POINT *  4.00);
		blobCharacteristics.special.dynamic.damping =   (signed long)(FIXED_POINT *  1.00);
		blobCharacteristics.special.dynamic.pressure =  (signed long)(FIXED_POINT * 60.00);

		blobCharacteristics.textureId = 1;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_MAIN;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, -30 << FIXED_POINT_SHIFT, -50 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 2;
		blobCharacteristics.userId = TYPE_BUTTON_COLOR_FILTER;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 30 << FIXED_POINT_SHIFT, -50 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		{
			blobCharacteristics.textureId = 3;
			blobCharacteristics.userId = TYPE_BUTTON_CAMERA;
			BlobObjectCreateEasy(&blobCharacteristics, blobShape, -10 << FIXED_POINT_SHIFT, -50 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		}
		blobCharacteristics.textureId = 4;
		blobCharacteristics.colorId = 4;
		blobCharacteristics.userId = TYPE_BUTTON_PHOTO_LIBRARY;
		defaultButton = BlobObjectCreateEasy(&blobCharacteristics, blobShape, 10 << FIXED_POINT_SHIFT, -50 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);

		// Forget about the button shape
		BlobShapeRelease(blobShape);

		// Create a dynamic blob
		// Note: blobs that are likely to become concave (e.g. big balloons) should be added last so that other blobs will be displayed above, hiding potential drawing errors
		blobCharacteristics.textureId = 5;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_PHOTO;
		blobCharacteristics.elasticity =                (signed long)(FIXED_POINT *   0.50);
		blobCharacteristics.friction =                  (signed long)(FIXED_POINT *   0.50);
		blobCharacteristics.special.dynamic.mass =      (signed long)(FIXED_POINT *   0.50);
		blobCharacteristics.special.dynamic.stiffness = (signed long)(FIXED_POINT *   1.00);
		blobCharacteristics.special.dynamic.damping =   (signed long)(FIXED_POINT *   0.30);
		blobCharacteristics.special.dynamic.pressure =  (signed long)(FIXED_POINT * 400.00);

		blobShape = BlobShapeCreateBalloon(40);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0, 0, 38 << FIXED_POINT_SHIFT, 38 << FIXED_POINT_SHIFT);
		BlobShapeRelease(blobShape);
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
