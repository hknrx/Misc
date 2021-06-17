#import <UIKit/UIKit.h>
#import "blob.h"

#define SCREEN_WIDTH         320
#define SCREEN_HEIGHT        480
#define SCREEN_CENTER_X      (SCREEN_WIDTH / 2)
#define SCREEN_CENTER_Y      (SCREEN_HEIGHT / 2)
#define SCREEN_CONVERT_SHIFT 2

#define BLOB_TEXTURE_SIZE_SMALL 64
#define BLOB_TEXTURE_SIZE_LARGE 128

#define BLOB_CONTAINER_WIDTH  (SCREEN_WIDTH << (FIXED_POINT_SHIFT - SCREEN_CONVERT_SHIFT))
#define BLOB_CONTAINER_HEIGHT (SCREEN_HEIGHT << (FIXED_POINT_SHIFT - SCREEN_CONVERT_SHIFT))
#define BLOB_CONTAINER_XMIN   (-BLOB_CONTAINER_WIDTH / 2)
#define BLOB_CONTAINER_XMAX   (BLOB_CONTAINER_WIDTH / 2)
#define BLOB_CONTAINER_YMIN   (-BLOB_CONTAINER_HEIGHT / 2)
#define BLOB_CONTAINER_YMAX   (BLOB_CONTAINER_HEIGHT / 2)
#define BLOB_CONTAINER_MARGIN (signed long)(FIXED_POINT * 20.00)

typedef struct
{
	NSString* fileName;
	unsigned int size;
	BOOL modifiable;
}
Texture;

typedef enum
{
	TYPE_PHOTO,
	TYPE_BUTTON_MENU_MAIN,
	TYPE_BUTTON_MENU_ROCKS,
	TYPE_BUTTON_MENU_TORTURE,
#ifndef LITE_VERSION
	TYPE_BUTTON_MENU_LOVE,
	TYPE_BUTTON_MENU_MAZE,
	TYPE_BUTTON_MENU_PINBALL,
	TYPE_BUTTON_MENU_SPACE,
	TYPE_BUTTON_MENU_WASHING,
#else
	TYPE_BUTTON_MENU_FULL_VERSION,
#endif
	TYPE_BUTTON_MENU_HELP,
	TYPE_BUTTON_CAMERA,
	TYPE_BUTTON_PHOTO_LIBRARY,
	TYPE_BUTTON_ADDRESS_BOOK,
	TYPE_BUTTON_COLOR_FILTER,
	TYPE_SPECIAL_1,
	TYPE_SPECIAL_2,
	TYPE_SPECIAL_3,
}
Type;

typedef enum
{
	FACEBOOK_LOGIN,
	FACEBOOK_PUBLISH_TOP,
	FACEBOOK_PUBLISH_BOTTOM,
}
FacebookButton;

@protocol Level <NSObject>

-(void)update;
-(BOOL)handleTouchBegan:(UITouch*)touch withBlob:(BlobReference)blobReference;
-(void)handleTouchEnded:(UITouch*)touch;

@property (nonatomic, readonly) unsigned int textureCount;
@property (nonatomic, readonly) Texture const* textures;
@property (nonatomic, readonly) BlobReference defaultButton;
@property (nonatomic, readonly) FacebookButton facebookButton;

@end
