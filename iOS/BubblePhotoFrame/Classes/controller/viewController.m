/*
 TODO (mandatory):
 - N/A.

 TODO (optional):
 - Adapt the application for slow devices (Washing Level): change the number of elements to 8 when the device isn't a 3GS.
 - Add a new environment "compass": a unique bubble, attracted by the magnetic field instead of the gravity.
 - Allow to take pictures from the Address Book.
 */

#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTimingFunction.h>
#import "viewController.h"
#import "blobView.h"
#import "helpView.h"
#import "publishView.h"
#import "errorView.h"
#import "levelMain.h"
#import "levelRocks.h"
#import "levelTorture.h"
#ifndef LITE_VERSION
#import "levelLove.h"
#import "levelMaze.h"
#import "levelPinball.h"
#import "levelSpace.h"
#import "levelWashing.h"
#endif
#import "math.h"

#define GRAVITY_SHIFT 3

#define FACEBOOK_BUTTON_MARGIN      10.0f
#define FACEBOOK_BUTTON_ALPHA       0.6f
#define FACEBOOK_BUTTON_SHOT_WIDTH  60.0f
#define FACEBOOK_BUTTON_SHOT_HEIGHT 31.0f

static NSString *const facebookApiKey = @"c104ae475466e216eb9c550af72dd626";
static NSString *const facebookSecretKey = @"9f39cc55fab962252071bea5a4a6710f";
#ifdef LITE_VERSION
static NSString *const fullVersionUrl = @"http://hknrx.free.fr/photoBubble/full.htm";
#endif

@implementation ViewController

@synthesize texturePathTemp, texturePathDoc, renderTimer;

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super init])
	{
		// Initialize the Facebook session
		facebookSession = [[FBSession sessionForApplication:facebookApiKey secret:facebookSecretKey delegate:self] retain];
		[facebookSession resume];

		// Initialize the blob view
		self.view = [[BlobView alloc] initWithFrame:frame];

		// Add the Facebook login button
		facebookButtonLogin = [[FBLoginButton alloc] init];
		facebookButtonLogin.center = CGPointMake(frame.size.width - FACEBOOK_BUTTON_MARGIN - facebookButtonLogin.bounds.size.width / 2, FACEBOOK_BUTTON_MARGIN + facebookButtonLogin.bounds.size.height / 2);
		[self.view addSubview:facebookButtonLogin];
		[facebookButtonLogin release];

		// Add the Facebook shot button
		facebookButtonShot = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[facebookButtonShot setFrame:CGRectMake(frame.size.width - FACEBOOK_BUTTON_MARGIN - FACEBOOK_BUTTON_SHOT_WIDTH, 0.0f, FACEBOOK_BUTTON_SHOT_WIDTH, FACEBOOK_BUTTON_SHOT_HEIGHT)];
		[facebookButtonShot setTitle:@"SHOT!" forState:UIControlStateNormal];
		[facebookButtonShot addTarget:self action:@selector(publishAsk) forControlEvents:UIControlEventTouchDown];
		[self.view addSubview:facebookButtonShot];

		// Add the Facebook publish view
		facebookViewPublish = [[PublishView alloc] initWithFrame:frame withController:self];
		facebookViewPublish.hidden = YES;
		[self.view addSubview:facebookViewPublish];
		[facebookViewPublish release];

		// Add the Facebook error view
		facebookViewError = [[ErrorView alloc] initWithFrame:frame withController:self];
		facebookViewError.hidden = YES;
		[self.view addSubview:facebookViewError];
		[facebookViewError release];

		// Initialize the help view
		helpView = [[HelpView alloc] initWithFrame:frame withController:self];

		// Initialize the blob engine
		BlobInitialize(BLOB_CONTAINER_XMIN, BLOB_CONTAINER_XMAX, BLOB_CONTAINER_YMIN, BLOB_CONTAINER_YMAX, 16);

		// Initiliaze the texture paths
		self.texturePathTemp = NSTemporaryDirectory();
		NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		self.texturePathDoc = [paths objectAtIndex:0];

		// Initialize the main level
		levelCurrentInstance = nil;
		[self levelInitializeWithClass:[LevelMain class]];

		// Initialize the gravity
#if TARGET_IPHONE_SIMULATOR
		blobGravityForce = FIXED_POINT >> GRAVITY_SHIFT;
		blobGravityAngle = -PI / 2;
#else
		blobGravityForce = 0;
		blobGravityAngle = 0;
#endif

		// Setup the accelerometer
		[[UIAccelerometer sharedAccelerometer] setDelegate:self];
		[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / 30.0)];

		// Render the view once immediately, then launch a timer to periodically refresh the screen
		[self render];
		renderTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 30.0) target:self selector:@selector(render) userInfo:nil repeats:YES];
	}
	return self;
}

- (void)levelInitializeWithClass:(Class)levelClass
{
	// Release the current level (if any)
	[levelCurrentInstance release];

	// Destroy all the existing blobs
	BlobObjectDestroy(NULL);

	// Initialize the level
	levelCurrentInstance = [[levelClass alloc] init];
	levelCurrentButton = levelCurrentInstance.defaultButton;
	levelExpectedClass = levelClass;

	// Set the Facebook buttons
	FacebookButton const facebookButton = [levelCurrentInstance facebookButton];
	if(facebookButton == FACEBOOK_LOGIN)
	{
		facebookButtonLogin.hidden = NO;
		facebookButtonShot.hidden = YES;
	}
	else
	{
		facebookButtonLogin.hidden = YES;
		if(facebookSession.isConnected && facebookPermissionPhotoUpload)
		{
			facebookButtonShot.hidden = NO;
			if(facebookButton == FACEBOOK_PUBLISH_TOP)
			{
				facebookButtonShot.center = CGPointMake(facebookButtonShot.center.x, FACEBOOK_BUTTON_MARGIN + FACEBOOK_BUTTON_SHOT_HEIGHT / 2);
			}
			else
			{
				facebookButtonShot.center = CGPointMake(facebookButtonShot.center.x, self.view.bounds.size.height - FACEBOOK_BUTTON_MARGIN - FACEBOOK_BUTTON_SHOT_HEIGHT / 2);
			}
		}
		else
		{
			facebookButtonShot.hidden = YES;
		}
	}

	// Load the textures
	for(unsigned int index = 0; index < levelCurrentInstance.textureCount; ++index)
	{
		Texture const* texture = &levelCurrentInstance.textures[index];
		UIImage* textureImage;
		if(texture->modifiable)
		{
			NSString* textureName = [self.texturePathDoc stringByAppendingPathComponent:texture->fileName];
			textureImage = [UIImage imageWithContentsOfFile:textureName];
			if(!textureImage)
			{
				textureImage = [UIImage imageNamed:@"BubbleDefault.png"];
			}
		}
		else
		{
			textureImage = [UIImage imageNamed:texture->fileName];
		}
		if(textureImage)
		{
			BlobLoadTexture(textureImage.CGImage, NULL, index, texture->size);
		}
	}
}

- (void)render
{
	// Display the blobs
	BlobDisplay();

	// Render everything
	[(BlobView*)self.view render];

	// Update the level's mechanisms
	[levelCurrentInstance update];

	// Update the physics of the blobs
	BlobUpdate((blobGravityForce * COS(blobGravityAngle)) >> FIXED_POINT_SHIFT, (blobGravityForce * SIN(blobGravityAngle)) >> FIXED_POINT_SHIFT);

	// Update the screen shutter and swap the levels as needed
	unsigned char const shutterLevel = BlobShutterLevelGet();
	if(levelExpectedClass != [levelCurrentInstance class])
	{
		if(shutterLevel < 16)
		{
			BlobShutterLevelSet(shutterLevel + 1);
		}
		else
		{
			[self levelInitializeWithClass:levelExpectedClass];
		}
	}
	else if(shutterLevel)
	{
		BlobShutterLevelSet(shutterLevel - 1);
	}

	// Update the transparency of the Facebook buttons
	float const alpha = (16 - shutterLevel) * (FACEBOOK_BUTTON_ALPHA / 16);
	facebookButtonLogin.alpha = alpha;
	facebookButtonShot.alpha = alpha;
}

-(BOOL)imagePickerControllerStartWithSourceType:(UIImagePickerControllerSourceType)sourceType WithBlob:(BlobReference)blobReference
{
	if(![UIImagePickerController isSourceTypeAvailable:sourceType])
	{
		return NO;
	}

	if(BlobTextureIdGet(blobReference) >= levelCurrentInstance.textureCount)
	{
		return NO;
	}

	UIImagePickerController* picker = [[UIImagePickerController alloc] init];
	picker.sourceType = sourceType;
	picker.delegate = self;
	picker.allowsImageEditing = YES;
	pickerBlobReference = blobReference;

	[renderTimer invalidate];
	[self presentModalViewController:picker animated:YES];
	return YES;
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingImage:(UIImage*)image editingInfo:(NSDictionary*)editingInfo
{
	unsigned char textureId = BlobTextureIdGet(pickerBlobReference);
	if(textureId < levelCurrentInstance.textureCount)
	{
		Texture const* texture = &levelCurrentInstance.textures[textureId];
		CGImageRef textureCGImage = NULL;
		BlobLoadTexture(image.CGImage, &textureCGImage, textureId, texture->size);
		if(texture->modifiable && textureCGImage)
		{
			UIImage* textureUIImage = [[UIImage alloc] initWithCGImage:textureCGImage];
			NSData* texturePng = UIImagePNGRepresentation(textureUIImage);
			[texturePng writeToFile:[self.texturePathDoc stringByAppendingPathComponent:texture->fileName] atomically:YES];
			[textureUIImage release];
			CGImageRelease(textureCGImage);
		}
	}

	[self imagePickerControllerDidCancel:picker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
	[picker release];
	renderTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 30.0) target:self selector:@selector(render) userInfo:nil repeats:YES];
}

- (void)helpOpen
{
	// Cancel the rendering timer
	[renderTimer invalidate];

	// Reset the help page scrolling
	[helpView resetScrolling];

	// Swap the views
	UIView* window = [self.view superview];
	[self.view removeFromSuperview];
	[window addSubview:helpView];

	// Setup the transition
	CATransition* animation = [CATransition animation];
	[animation setDuration:0.5];
	[animation setType:kCATransitionMoveIn];
	[animation setSubtype:kCATransitionFromLeft];
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
	[[window layer] addAnimation:animation forKey:nil];
}

- (void)helpClose:(id)sender
{
	// Swap the views
	UIView* window = [helpView superview];
	[helpView removeFromSuperview];
	[window addSubview:self.view];

	// Setup the transition
	CATransition* animation = [CATransition animation];
	[animation setDuration:0.5];
	[animation setType:kCATransitionReveal];
	[animation setSubtype:kCATransitionFromLeft];
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
	[[window layer] addAnimation:animation forKey:nil];

	// Set the rendering timer
	renderTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 30.0) target:self selector:@selector(render) userInfo:nil repeats:YES];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	// Do not accept any touch event if the screen shutter isn't fully opened
	if(BlobShutterLevelGet())
	{
		return;
	}

	// Get the coordinates of the touch event
	UITouch* touch = [touches anyObject];
	CGPoint point = [touch locationInView:self.view];

	// Find the corresponding blob (if any)
	signed long x = ((signed long)point.x - SCREEN_CENTER_X) << (FIXED_POINT_SHIFT - SCREEN_CONVERT_SHIFT);
	signed long y = (SCREEN_CENTER_Y - (signed long)point.y) << (FIXED_POINT_SHIFT - SCREEN_CONVERT_SHIFT);
	BlobReference blobReference = BlobTouch(x, y);
	if(!blobReference)
	{
		return;
	}

	// Get the blob's user type
	switch(BlobUserIdGet(blobReference))
	{
		case TYPE_PHOTO:
			switch(BlobUserIdGet(levelCurrentButton))
			{
				case TYPE_BUTTON_CAMERA:
					[self imagePickerControllerStartWithSourceType:UIImagePickerControllerSourceTypeCamera WithBlob:blobReference];
					break;
				case TYPE_BUTTON_PHOTO_LIBRARY:
					[self imagePickerControllerStartWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary WithBlob:blobReference];
					break;
				case TYPE_BUTTON_COLOR_FILTER:
					BlobColorIdSet(blobReference, BlobColorIdGet(blobReference) - 1);
					break;
			}
			break;
		case TYPE_BUTTON_MENU_MAIN:
			levelExpectedClass = [LevelMain class];
			break;
		case TYPE_BUTTON_MENU_ROCKS:
			levelExpectedClass = [LevelRocks class];
			break;
		case TYPE_BUTTON_MENU_TORTURE:
			levelExpectedClass = [LevelTorture class];
			break;
#ifndef LITE_VERSION
		case TYPE_BUTTON_MENU_LOVE:
			levelExpectedClass = [LevelLove class];
			break;
		case TYPE_BUTTON_MENU_MAZE:
			levelExpectedClass = [LevelMaze class];
			break;
		case TYPE_BUTTON_MENU_PINBALL:
			levelExpectedClass = [LevelPinball class];
			break;
		case TYPE_BUTTON_MENU_SPACE:
			levelExpectedClass = [LevelSpace class];
			break;
		case TYPE_BUTTON_MENU_WASHING:
			levelExpectedClass = [LevelWashing class];
			break;
#else
		case TYPE_BUTTON_MENU_FULL_VERSION:
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:fullVersionUrl]];
			break;
#endif
		case TYPE_BUTTON_MENU_HELP:
			[self helpOpen];
			break;
		case TYPE_BUTTON_CAMERA:
		case TYPE_BUTTON_PHOTO_LIBRARY:
		case TYPE_BUTTON_COLOR_FILTER:
			if(levelCurrentButton != blobReference)
			{
				BlobColorIdSet(levelCurrentButton, 7);
				levelCurrentButton = blobReference;
				BlobColorIdSet(levelCurrentButton, 4);
			}
			break;
		default:
			if(![levelCurrentInstance handleTouchBegan:touch withBlob:blobReference])
			{
				BlobObjectDestroy(blobReference);
			}
			break;
	}
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	[levelCurrentInstance handleTouchEnded:[touches anyObject]];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
	[levelCurrentInstance handleTouchEnded:[touches anyObject]];
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
	// Update the gravity
	signed long x = acceleration.x * FIXED_POINT;
	signed long y = acceleration.y * FIXED_POINT;
	blobGravityForce = MathNormFast(x, y) >> GRAVITY_SHIFT;
	blobGravityAngle = MathAngleFast(x, y);
}

- (void)publishAsk
{
	// Check whether the screenshot can be published
	if(facebookSession.isConnected && facebookPermissionPhotoUpload)
	{
		// Show the Facebook publish view
		facebookViewPublish.screenshot = [(BlobView*)self.view screenshot];
		facebookViewPublish.hidden = NO;

		// Setup the transition
		CATransition* animation = [CATransition animation];
		[animation setDuration:0.5];
		[animation setType:kCATransitionMoveIn];
		[animation setSubtype:kCATransitionFromLeft];
		[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
		[facebookViewPublish.layer addAnimation:animation forKey:nil];
	}
}

- (void)publishCancel
{
	// Hide the Facebook publish view
	facebookViewPublish.hidden = YES;
	facebookViewPublish.screenshot = nil;

	// Setup the transition
	CATransition* animation = [CATransition animation];
	[animation setDuration:0.5];
	[animation setType:kCATransitionReveal];
	[animation setSubtype:kCATransitionFromLeft];
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
	[facebookViewPublish.layer addAnimation:animation forKey:nil];
}

- (void)publishDo
{
	// Check whether the screenshot can be published
	if(facebookSession.isConnected && facebookPermissionPhotoUpload)
	{
		// Define the caption
		NSString* caption;
		if(facebookUserName)
		{
			caption = [NSString stringWithFormat:@"%@ has just taken a nice screenshot", facebookUserName];
		}
		else
		{
			caption = @"Here is another nice screenshot taken";
		}
		caption = [caption stringByAppendingString:@" in Photo Bubble for iPhone! Get the application and share bubbles with your friends too!"];

		// Upload the screenshot to Facebook
		NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:caption, @"caption", nil];
		[[FBRequest requestWithDelegate:self] call:@"facebook.photos.upload" params:parameters dataParam:(NSData*)facebookViewPublish.screenshot];
	}

	// Hide the Facebook publish view
	[self publishCancel];
}

- (void)errorOk
{
	// Hide the Facebook error view
	facebookViewError.hidden = YES;
	facebookViewError.label.text = nil;

	// Setup the transition
	CATransition* animation = [CATransition animation];
	[animation setDuration:0.5];
	[animation setType:kCATransitionReveal];
	[animation setSubtype:kCATransitionFromLeft];
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
	[facebookViewError.layer addAnimation:animation forKey:nil];
}

- (void)session:(FBSession*)session didLogin:(FBUID)uid
{
	// Check whether photos can be uploaded to the Facebook account
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%llu", uid], @"uid", @"photo_upload", @"ext_perm", nil];
	[[FBRequest requestWithDelegate:self] call:@"facebook.Users.hasAppPermission" params:parameters];

	// Get the Facebook user name
	parameters = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"select name from user where uid == %lld", uid] forKey:@"query"];
	[[FBRequest requestWithDelegate:self] call:@"facebook.fql.query" params:parameters];
}

- (void)request:(FBRequest*)request didLoad:(id)result
{
	if([request.method isEqualToString:@"facebook.Users.hasAppPermission"])
	{
		// Check whether photos can be uploaded to the Facebook account
		facebookPermissionPhotoUpload = [(NSString*)result isEqualToString:@"1"];
		if(!facebookPermissionPhotoUpload)
		{
			// Display the dialog allowing to change the permissions
			FBPermissionDialog* dialog = [[FBPermissionDialog alloc] init];
			dialog.delegate = self;
			dialog.permission = @"photo_upload";
			[dialog show];
			[dialog release];
		}
	}
	else if([request.method isEqualToString:@"facebook.fql.query"])
	{
		// Take note of the Facebook user name
		facebookUserName = [[[(NSArray*)result objectAtIndex:0] objectForKey:@"name"] retain];
	}
}

- (void)request:(FBRequest*)request didFailWithError:(NSError*)error
{
	if([request.method isEqualToString:@"facebook.Users.hasAppPermission"])
	{
		// Permissions could not be checked, so logout
		[facebookSession logout];
	}
	else if([request.method isEqualToString:@"facebook.photos.upload"])
	{
		// Show the Facebook error view
		facebookViewError.label.text = [NSString stringWithFormat:@"An error occurred while uploading the screenshot to Facebook servers: %@", error.localizedDescription];
		facebookViewError.hidden = NO;

		// Setup the transition
		CATransition* animation = [CATransition animation];
		[animation setDuration:0.5];
		[animation setType:kCATransitionMoveIn];
		[animation setSubtype:kCATransitionFromLeft];
		[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
		[facebookViewError.layer addAnimation:animation forKey:nil];
	}
}

- (void)dialogDidSucceed:(FBDialog*)dialog
{
	if([dialog isKindOfClass:[FBPermissionDialog class]] && [((FBPermissionDialog*)dialog).permission isEqualToString:@"photo_upload"])
	{
		// The user has just granted the permission to upload photos
		facebookPermissionPhotoUpload = YES;
	}
}

- (void)dialogDidCancel:(FBDialog*)dialog
{
	if([dialog isKindOfClass:[FBPermissionDialog class]] && [((FBPermissionDialog*)dialog).permission isEqualToString:@"photo_upload"])
	{
		// The user forbids photo uploading, so logout
		[facebookSession logout];
	}
}

- (void)dealloc
{
	// Release the current level
	[levelCurrentInstance release];

	// Finalize the blob engine
	BlobFinalize();

	// Release the views
	[helpView release];
	[self.view release];

	// Finalize the Facebook session
	[facebookSession release];
	[facebookUserName release];

	// Complete the deallocation of the object
	[super dealloc];
}

@end
