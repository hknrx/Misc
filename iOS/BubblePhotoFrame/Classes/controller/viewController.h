#import <UIKit/UIKit.h>
#import "blob.h"
#import "FBConnect/FBConnect.h"

@class HelpView;
@class PublishView;
@class ErrorView;
@protocol Level;

@interface ViewController : UIViewController <UIAccelerometerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FBSessionDelegate, FBRequestDelegate, FBDialogDelegate>
{
	NSString* facebookUserName;
	FBSession* facebookSession;
	BOOL facebookPermissionPhotoUpload;
	FBLoginButton* facebookButtonLogin;
	UIButton* facebookButtonShot;
	PublishView* facebookViewPublish;
	ErrorView* facebookViewError;

	HelpView* helpView;

	NSString* texturePathTemp;
	NSString* texturePathDoc;

	id <Level> levelCurrentInstance;
	BlobReference levelCurrentButton;
	Class levelExpectedClass;

	signed long blobGravityForce;
	unsigned char blobGravityAngle;

	NSTimer* renderTimer;
	BlobReference pickerBlobReference;
}

- (void)levelInitializeWithClass:(Class)levelClass;
- (void)render;

@property (nonatomic, retain) NSString* texturePathTemp;
@property (nonatomic, retain) NSString* texturePathDoc;
@property (nonatomic, readonly) NSTimer* renderTimer;

@end
