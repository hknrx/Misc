#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/glext.h>

#define TEXTURE_COUNT 3

typedef struct
{
	GLshort vertices[8];
	GLfixed coordinates[8];
	GLubyte elements[4];
}
Screen;

typedef struct
{
	unsigned short indexPrevious;
	unsigned short indexNext;
	BOOL convex;
}
VertexInfo;

@class Button;

@interface Paint : UIView
{
	Button* buttons[5];

	EAGLContext* context;
	GLuint viewRenderbuffer;
	GLuint viewFramebuffer;
	GLuint textureFramebuffer;

	enum {STATE_PAINT, STATE_CUT, STATE_DONE} state;

	UITouch* drawTouch;
	CGFloat drawDistance;

	GLuint textureName[TEXTURE_COUNT];
	Screen screen;
	GLfixed textureCoordinates[8];
	GLfixed textureMatrix1[16];
	GLfixed textureMatrix2[16];

	unsigned char paintColorIndex;
	BOOL paintBrushErase;
	BOOL paintBrushBig;
	unsigned short paintPointCount;
	CGPoint* paintPoints;

	unsigned short pathPointCount;
	CGPoint* pathPoints;
	CGPoint pathVector;
	CGFloat pathVectorNorm;

	VertexInfo* vertexInfo;
	unsigned short areaCount;
	struct {unsigned short a; unsigned short b; unsigned short c;}* area;

	NSTimer* timer;
}

- (UIImage*)screenshot;

@end
