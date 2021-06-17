#import <Foundation/Foundation.h>
#import "level.h"

@interface LevelMain : NSObject <Level>
{
	BlobReference defaultButton;

	unsigned char blobTitleTimer1;
	unsigned char blobTitleTimer2;
	BlobReference blobTitle;
}

@end
