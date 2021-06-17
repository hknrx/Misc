#import <Foundation/Foundation.h>
#import "level.h"

@interface LevelPinball : NSObject <Level>
{
	BlobReference defaultButton;

	BOOL blobMechanismBoosterUp;
	BlobTransformation blobMechanismBoosterTransformation;

	UITouch* blobMechanismFlipLeft;
	signed char blobMechanismFlipLeftAngle;
	BlobTransformation blobMechanismFlipLeftTransformation;

	UITouch* blobMechanismFlipRight;
	signed char blobMechanismFlipRightAngle;
	BlobTransformation blobMechanismFlipRightTransformation;
}

@end
