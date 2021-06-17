#import <Foundation/Foundation.h>
#import "level.h"

@interface LevelWashing : NSObject <Level>
{
	BlobReference defaultButton;

	unsigned char blobMechanismAngle;
	unsigned char blobMechanismTimer;
	BlobTransformation* blobMechanismTransformation;
	BlobReference blobMechanismButton;
}

@end
