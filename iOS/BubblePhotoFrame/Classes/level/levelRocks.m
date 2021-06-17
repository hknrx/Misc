#import "levelRocks.h"
#import "math.h"

#define BLOB_ROCKS_THICKNESS (signed long)(FIXED_POINT * 4.00)

static Texture const textures[] =
{
	{@"RocksBackground.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuMain.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuColorFilter.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuCamera.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuPhotoLibrary.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"BubbleRocks1.png", BLOB_TEXTURE_SIZE_LARGE, YES},
	{@"BubbleRocks2.png", BLOB_TEXTURE_SIZE_LARGE, YES},
	{@"BubbleRocks3.png", BLOB_TEXTURE_SIZE_LARGE, YES},
};

@implementation LevelRocks

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
		blobCharacteristics.type = BLOB_TYPE_STATIC_VISIBLE;
		blobCharacteristics.textureId = 0;
		blobCharacteristics.textureRepeat = YES;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_SPECIAL_1;
		blobCharacteristics.elasticity = (signed long)(FIXED_POINT * 0.10);
		blobCharacteristics.friction =   (signed long)(FIXED_POINT * 1.00);
		blobCharacteristics.special.staticTransformation = NULL;
		blobCharacteristics.collisionMask = 1;

		BlobShapeReference blobShape = BlobShapeCreateBox();
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_CONTAINER_XMIN + (BLOB_ROCKS_THICKNESS / 2), 0, BLOB_ROCKS_THICKNESS, BLOB_CONTAINER_HEIGHT);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_CONTAINER_XMAX - (BLOB_ROCKS_THICKNESS / 2), 0, BLOB_ROCKS_THICKNESS, BLOB_CONTAINER_HEIGHT);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0, BLOB_CONTAINER_YMIN + (BLOB_ROCKS_THICKNESS / 2), BLOB_CONTAINER_WIDTH, BLOB_ROCKS_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0, BLOB_CONTAINER_YMAX - (BLOB_ROCKS_THICKNESS / 2), BLOB_CONTAINER_WIDTH, BLOB_ROCKS_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, -32 << FIXED_POINT_SHIFT, 10 << FIXED_POINT_SHIFT, 16 << FIXED_POINT_SHIFT, BLOB_ROCKS_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 32 << FIXED_POINT_SHIFT, -10 << FIXED_POINT_SHIFT, 16 << FIXED_POINT_SHIFT, BLOB_ROCKS_THICKNESS);
		BlobShapeRelease(blobShape);

		// Define a rock shape
		blobShape = BlobShapeCreateSnail(7);

		// Create the dynamic buttons
		blobCharacteristics.type = BLOB_TYPE_DYNAMIC;
		blobCharacteristics.textureRepeat = NO;
		blobCharacteristics.special.dynamic.mass =      (signed long)(FIXED_POINT *  1.00);
		blobCharacteristics.special.dynamic.stiffness = (signed long)(FIXED_POINT *  3.00);
		blobCharacteristics.special.dynamic.damping =   (signed long)(FIXED_POINT *  2.00);
		blobCharacteristics.special.dynamic.pressure =  (signed long)(FIXED_POINT * 10.00);

		blobCharacteristics.textureId = 1;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_MAIN;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, -24 << FIXED_POINT_SHIFT, 48 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 2;
		blobCharacteristics.userId = TYPE_BUTTON_COLOR_FILTER;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 24 << FIXED_POINT_SHIFT, 48 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		{
			blobCharacteristics.textureId = 3;
			blobCharacteristics.userId = TYPE_BUTTON_CAMERA;
			BlobObjectCreateEasy(&blobCharacteristics, blobShape, -8 << FIXED_POINT_SHIFT, 48 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);
		}
		blobCharacteristics.textureId = 4;
		blobCharacteristics.colorId = 4;
		blobCharacteristics.userId = TYPE_BUTTON_PHOTO_LIBRARY;
		defaultButton = BlobObjectCreateEasy(&blobCharacteristics, blobShape, 8 << FIXED_POINT_SHIFT, 48 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT, 14 << FIXED_POINT_SHIFT);

		// Create several dynamic blobs
		// Note: blobs that are likely to become concave (e.g. big balloons) should be added last so that other blobs will be displayed above, hiding potential drawing errors
		blobCharacteristics.textureId = 5;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_PHOTO;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, -20 << FIXED_POINT_SHIFT, 25 << FIXED_POINT_SHIFT, 20 << FIXED_POINT_SHIFT, 20 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 6;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 15 << FIXED_POINT_SHIFT, 20 << FIXED_POINT_SHIFT, 30 << FIXED_POINT_SHIFT, 30 << FIXED_POINT_SHIFT);
		blobCharacteristics.textureId = 7;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0, -30 << FIXED_POINT_SHIFT, 36 << FIXED_POINT_SHIFT, 36 << FIXED_POINT_SHIFT);

		// Forget about the rock shape
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
