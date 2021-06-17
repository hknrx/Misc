#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/glext.h>

@interface BlobView : UIView
{
	EAGLContext* context;
	GLuint viewRenderbuffer;
	GLuint viewFramebuffer;
}

- (void)render;
- (UIImage*)screenshot;

@end
