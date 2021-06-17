#import <QuartzCore/QuartzCore.h>
#import "blobView.h"

@implementation BlobView

+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Setup the layer
		CAEAGLLayer* layer = (CAEAGLLayer*)self.layer;
		layer.opaque = YES;
		layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		if(!context || ![EAGLContext setCurrentContext:context])
		{
			[self release];
			return nil;
		}

		// Setup the OpenGL buffers
		glGenRenderbuffersOES(1, &viewRenderbuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
		glGenFramebuffersOES(1, &viewFramebuffer);
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
		[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);

		// Enable the "multi touch"
		self.multipleTouchEnabled = YES;
	}
	return self;
}

- (void)render
{
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

void screenshotFreeData(void* info, void const* data, size_t dataSize)
{
	free((void*)data);
}

- (UIImage*)screenshot
{
	GLint viewport[4];
	glGetIntegerv(GL_VIEWPORT, viewport);
	GLint const width = viewport[2];
	GLint const height = viewport[3];
	GLint const lineSize = width * sizeof(GLuint);
	GLint const dataSize = lineSize * height;

	GLubyte* buffer = (GLubyte*)malloc(dataSize);
	glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);

	GLuint* pointerTop = (GLuint*)&buffer[0];
	GLuint* pointerBottom = (GLuint*)&buffer[dataSize - lineSize];
	while(pointerTop < pointerBottom)
	{
		for(unsigned int x = 0; x < width; ++x)
		{
			GLuint const top = *pointerTop;
			*pointerTop++ = *pointerBottom;
			*pointerBottom++ = top;
		}
		pointerBottom -= width * 2;
	}

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, dataSize, screenshotFreeData);
	CGImageRef image = CGImageCreate(width, height, 8, 8 * sizeof(GLuint), lineSize, colorSpace, kCGBitmapByteOrderDefault, provider, NULL, NO, kCGRenderingIntentDefault);
	CGColorSpaceRelease(colorSpace);
	CGDataProviderRelease(provider);
	UIImage* screenshot = [UIImage imageWithCGImage:image];
	CGImageRelease(image);
	return screenshot;
}

- (void)dealloc
{
	// Destroy the view
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	if([EAGLContext currentContext] == context)
	{
		[EAGLContext setCurrentContext:nil];
	}
	[context release];

	// Destroy everything else
	[super dealloc];
}

@end
