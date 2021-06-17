#import <Foundation/Foundation.h>
#import "level.h"

@interface LevelTorture : NSObject <Level>
{
	BlobReference defaultButton;

	BOOL blobMechanismEnabled;
	unsigned char blobMechanismBlenderAngle;
	BlobTransformation blobMechanismBlenderTransformation;
	BOOL blobMechanismLiftUp;
	BlobTransformation blobMechanismLiftTransformation;
}

@end
