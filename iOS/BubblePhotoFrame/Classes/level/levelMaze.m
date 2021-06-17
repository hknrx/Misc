#import "levelMaze.h"
#import "math.h"

#define BLOB_MAZE_THICKNESS (signed long)(FIXED_POINT *   2.00)
#define BLOB_MAZE_X0        (signed long)(FIXED_POINT * -40.00)
#define BLOB_MAZE_X1        (signed long)(FIXED_POINT * -24.00)
#define BLOB_MAZE_X2        (signed long)(FIXED_POINT *  -8.00)
#define BLOB_MAZE_X3        (signed long)(FIXED_POINT *   8.00)
#define BLOB_MAZE_X4        (signed long)(FIXED_POINT *  24.00)
#define BLOB_MAZE_X5        (signed long)(FIXED_POINT *  40.00)
#define BLOB_MAZE_Y0        (signed long)(FIXED_POINT * -60.00)
#define BLOB_MAZE_Y1        (signed long)(FIXED_POINT * -45.00)
#define BLOB_MAZE_Y2        (signed long)(FIXED_POINT * -30.00)
#define BLOB_MAZE_Y3        (signed long)(FIXED_POINT * -15.00)
#define BLOB_MAZE_Y4        (signed long)(FIXED_POINT *   0.00)
#define BLOB_MAZE_Y5        (signed long)(FIXED_POINT *  15.00)
#define BLOB_MAZE_Y6        (signed long)(FIXED_POINT *  30.00)
#define BLOB_MAZE_Y7        (signed long)(FIXED_POINT *  45.00)
#define BLOB_MAZE_Y8        (signed long)(FIXED_POINT *  60.00)
#define BLOB_MAZE_DIAMETER  (signed long)(FIXED_POINT *  12.00)

static Texture const textures[] =
{
	{@"MazeBackground.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MazeWall.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuMain.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuColorFilter.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuCamera.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"MenuPhotoLibrary.png", BLOB_TEXTURE_SIZE_SMALL, NO},
	{@"BubbleMaze1.png", BLOB_TEXTURE_SIZE_SMALL, YES},
	{@"BubbleMaze2.png", BLOB_TEXTURE_SIZE_SMALL, YES},
	{@"BubbleMaze3.png", BLOB_TEXTURE_SIZE_SMALL, YES},
};

@implementation LevelMaze

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

		// Create the container
		BlobCharacteristics blobCharacteristics;
		blobCharacteristics.type = BLOB_TYPE_STATIC_VISIBLE;
		blobCharacteristics.textureId = 1;
		blobCharacteristics.textureRepeat = YES;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_SPECIAL_1;
		blobCharacteristics.elasticity = (signed long)(FIXED_POINT * 0.10);
		blobCharacteristics.friction =   (signed long)(FIXED_POINT * 0.20);
		blobCharacteristics.special.staticTransformation = NULL;
		blobCharacteristics.collisionMask = 1;

		BlobShapeReference blobShape = BlobShapeCreateBox();
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X0 + BLOB_MAZE_X5) / 2, BLOB_MAZE_Y0, BLOB_MAZE_THICKNESS + BLOB_MAZE_X5 - BLOB_MAZE_X0, BLOB_MAZE_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X0 + BLOB_MAZE_X5) / 2, BLOB_MAZE_Y8, BLOB_MAZE_THICKNESS + BLOB_MAZE_X5 - BLOB_MAZE_X0, BLOB_MAZE_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_MAZE_X0, (BLOB_MAZE_Y0 + BLOB_MAZE_Y8) / 2, BLOB_MAZE_THICKNESS, BLOB_MAZE_THICKNESS + BLOB_MAZE_Y8 - BLOB_MAZE_Y0);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_MAZE_X5, (BLOB_MAZE_Y0 + BLOB_MAZE_Y8) / 2, BLOB_MAZE_THICKNESS, BLOB_MAZE_THICKNESS + BLOB_MAZE_Y8 - BLOB_MAZE_Y0);

		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X1 + BLOB_MAZE_X2) / 2, BLOB_MAZE_Y1, BLOB_MAZE_THICKNESS + BLOB_MAZE_X2 - BLOB_MAZE_X1, BLOB_MAZE_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X3 + BLOB_MAZE_X5) / 2, BLOB_MAZE_Y1, BLOB_MAZE_THICKNESS + BLOB_MAZE_X5 - BLOB_MAZE_X3, BLOB_MAZE_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X0 + BLOB_MAZE_X1) / 2, BLOB_MAZE_Y2, BLOB_MAZE_THICKNESS + BLOB_MAZE_X1 - BLOB_MAZE_X0, BLOB_MAZE_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X1 + BLOB_MAZE_X3) / 2, BLOB_MAZE_Y3, BLOB_MAZE_THICKNESS + BLOB_MAZE_X3 - BLOB_MAZE_X1, BLOB_MAZE_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X3 + BLOB_MAZE_X4) / 2, BLOB_MAZE_Y4, BLOB_MAZE_THICKNESS + BLOB_MAZE_X4 - BLOB_MAZE_X3, BLOB_MAZE_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X0 + BLOB_MAZE_X1) / 2, BLOB_MAZE_Y5, BLOB_MAZE_THICKNESS + BLOB_MAZE_X1 - BLOB_MAZE_X0, BLOB_MAZE_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X2 + BLOB_MAZE_X3) / 2, BLOB_MAZE_Y6, BLOB_MAZE_THICKNESS + BLOB_MAZE_X3 - BLOB_MAZE_X2, BLOB_MAZE_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X1 + BLOB_MAZE_X2) / 2, BLOB_MAZE_Y7, BLOB_MAZE_THICKNESS + BLOB_MAZE_X2 - BLOB_MAZE_X1, BLOB_MAZE_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X3 + BLOB_MAZE_X5) / 2, BLOB_MAZE_Y7, BLOB_MAZE_THICKNESS + BLOB_MAZE_X5 - BLOB_MAZE_X3, BLOB_MAZE_THICKNESS);

		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_MAZE_X1, (BLOB_MAZE_Y1 + BLOB_MAZE_Y3) / 2, BLOB_MAZE_THICKNESS, BLOB_MAZE_THICKNESS + BLOB_MAZE_Y3 - BLOB_MAZE_Y1);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_MAZE_X1, (BLOB_MAZE_Y4 + BLOB_MAZE_Y7) / 2, BLOB_MAZE_THICKNESS, BLOB_MAZE_THICKNESS + BLOB_MAZE_Y7 - BLOB_MAZE_Y4);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_MAZE_X2, (BLOB_MAZE_Y3 + BLOB_MAZE_Y6) / 2, BLOB_MAZE_THICKNESS, BLOB_MAZE_THICKNESS + BLOB_MAZE_Y6 - BLOB_MAZE_Y3);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_MAZE_X3, (BLOB_MAZE_Y2 + BLOB_MAZE_Y3) / 2, BLOB_MAZE_THICKNESS, BLOB_MAZE_THICKNESS + BLOB_MAZE_Y3 - BLOB_MAZE_Y2);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_MAZE_X3, (BLOB_MAZE_Y4 + BLOB_MAZE_Y6) / 2, BLOB_MAZE_THICKNESS, BLOB_MAZE_THICKNESS + BLOB_MAZE_Y6 - BLOB_MAZE_Y4);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_MAZE_X4, (BLOB_MAZE_Y2 + BLOB_MAZE_Y5) / 2, BLOB_MAZE_THICKNESS, BLOB_MAZE_THICKNESS + BLOB_MAZE_Y5 - BLOB_MAZE_Y2);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_MAZE_X4, (BLOB_MAZE_Y6 + BLOB_MAZE_Y7) / 2, BLOB_MAZE_THICKNESS, BLOB_MAZE_THICKNESS + BLOB_MAZE_Y7 - BLOB_MAZE_Y6);
		BlobShapeRelease(blobShape);

		// Define a bubble shape
		blobShape = BlobShapeCreateBalloon(16);

		// Create the dynamic buttons
		blobCharacteristics.type = BLOB_TYPE_DYNAMIC;
		blobCharacteristics.textureRepeat = NO;
		blobCharacteristics.special.dynamic.mass =      (signed long)(FIXED_POINT *  0.30);
		blobCharacteristics.special.dynamic.stiffness = (signed long)(FIXED_POINT *  4.00);
		blobCharacteristics.special.dynamic.damping =   (signed long)(FIXED_POINT *  1.00);
		blobCharacteristics.special.dynamic.pressure =  (signed long)(FIXED_POINT * 50.00);

		blobCharacteristics.textureId = 2;
		blobCharacteristics.userId = TYPE_BUTTON_MENU_MAIN;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X0 + BLOB_MAZE_X1) / 2, (BLOB_MAZE_Y1 + BLOB_MAZE_Y2) / 2, BLOB_MAZE_DIAMETER, BLOB_MAZE_DIAMETER);
		blobCharacteristics.textureId = 3;
		blobCharacteristics.userId = TYPE_BUTTON_COLOR_FILTER;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X4 + BLOB_MAZE_X5) / 2, (BLOB_MAZE_Y0 + BLOB_MAZE_Y1) / 2, BLOB_MAZE_DIAMETER, BLOB_MAZE_DIAMETER);
		if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		{
			blobCharacteristics.textureId = 4;
			blobCharacteristics.userId = TYPE_BUTTON_CAMERA;
			BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X0 + BLOB_MAZE_X1) / 2, (BLOB_MAZE_Y6 + BLOB_MAZE_Y7) / 2, BLOB_MAZE_DIAMETER, BLOB_MAZE_DIAMETER);
		}
		blobCharacteristics.textureId = 5;
		blobCharacteristics.colorId = 4;
		blobCharacteristics.userId = TYPE_BUTTON_PHOTO_LIBRARY;
		defaultButton = BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X4 + BLOB_MAZE_X5) / 2, (BLOB_MAZE_Y7 + BLOB_MAZE_Y8) / 2, BLOB_MAZE_DIAMETER, BLOB_MAZE_DIAMETER);

		// Create several dynamic blobs
		// Note: blobs that are likely to become concave (e.g. big balloons) should be added last so that other blobs will be displayed above, hiding potential drawing errors
		blobCharacteristics.textureId = 6;
		blobCharacteristics.colorId = 7;
		blobCharacteristics.userId = TYPE_PHOTO;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X1 + BLOB_MAZE_X2) / 2, (BLOB_MAZE_Y3 + BLOB_MAZE_Y4) / 2, BLOB_MAZE_DIAMETER, BLOB_MAZE_DIAMETER);
		blobCharacteristics.textureId = 7;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X2 + BLOB_MAZE_X3) / 2, (BLOB_MAZE_Y5 + BLOB_MAZE_Y6) / 2, BLOB_MAZE_DIAMETER, BLOB_MAZE_DIAMETER);
		blobCharacteristics.textureId = 8;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, (BLOB_MAZE_X3 + BLOB_MAZE_X4) / 2, (BLOB_MAZE_Y2 + BLOB_MAZE_Y3) / 2, BLOB_MAZE_DIAMETER, BLOB_MAZE_DIAMETER);

		// Forget about the bubble shape
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
