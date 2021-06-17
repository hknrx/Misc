/*
 TODO (TASKS):
 - Compute the bounding box of the shape to center it on the screen.
 - Compute the center of mass of the shape then suspend it to the top of the screen with a string.
 - Handle loops when defining the cut shape: detect intersections, add a vertex for each of them and 2 indexes, revert the order of the indexes in the between.
 - Add a background texture (to be displayed once the cut shape is defined); it could be the "inn"...
 - N/A.

 TODO (OPTIONAL):
 - N/A.

 DESIGN:
 - Create your paper globe-trotter and your moving inn.
 - Receive post cards from your globe-trotter (screenshot of the globe-trotter in his current inn).
 - Look at your guests and give them an appreciation (0 to 5 stars).
 - Check your globe-trotter history (passport: position and name of the last 10 inns, total number of inns visited, distance traveled, average ranking).
 - Check your inn history (guest book).
 - See the global ranking (newspaper: the 5 globe-trotters with the highest rank + the 5 globe trotters who traveled the most).
 - Post feeds on Facebook (passport information) and screenshots (guests).
 - Note: the basic version (free) doesn't allow to open the passport nor to give appreciation to guests; these options have to be unlocked (InAppPurchase - 0.79€).
 - From the passport, one can edit his/her globe-trotter at any time (which resets its ranking).

 IDEAS:
 - Use PVRTC textures?
 - When the application is launched for the first time (= if it has NO data), it shall connect to the server to download any existing data (e.g. the globe-trotter and the inn if they have already been defined).
 - The background for the title should show the earth; the background for the moving inn should show a nice place (forest, river, waterfall, etc.); the background for the globe-trotter should show the inside of the inn (a wooden door, a table, etc.).
 - There must be 2 main sections: the "moving inn" and the "paper globe-trotter".
 - The moving inn has a name (editable) and a position (country name from the GPS). In case the position cannot be found, it is "underworld".
 - Note: the globe-trotter may have 2 textures, one for each side... The front side would be editable by the globe-trotter's owner, the back side by any inn owner who would receive the globe-trotter.
 - Connections to server must be reliable, hence there shall be a fallback system: if the main URL isn't known, then it is taken from a special reference server; the application will then always connect to the main URL, except if the connection fails, in which case it would display an error message and check the reference server again (not more than once every 24 hours).
 - The application handles 2 timeout values: one to know when it is time to check for the globe-trotter's position, one to know when it is time to check for guests. No connection is made to the server when there is no need to do so.
 - When the application connects to the server to look for a guest (removing the existing guest, if any), the server searches for a globe-trotter whose the expiration timestamp is lower than the current time and whose the ID is different from the inn ID. There could be an additional check on the relative position of the inn and the globe-trotter (= get the closest one)...
 - Once the application has got the ID of a globe-trotter, it downloads its data from the server, which also sets its expiration timestamp to "now + 24 hours".
 - If the server couldn't find an available globe-trotter, the application sets its (inn) timeout to a default value.
 - When a globe-trotter has just been created, the timeout on the application side is set to a default value, and the expiration timestamp set to 0 on server side.
 - When the globe-trotter's timeout has been reached on the application side, it checks its status on the server. If it is in a inn, then its timeout is then set to "default value + expiration time - server time", otherwise it is set to "default value".
 - When in the inn, one can see the current guest (if any): name, drawing, original location, previous location.
 - There shall be a button to kick-out an unwelcomed guest (just a flag on application side to hide the guest).
 - When looking at one's own globe-trotter, a passport displays the last 10 visited inns (date, name, location - these information are saved locally by the application).
 - It is possible to get a few statistics for the inn: total number of guests and number of different countries.
 - It is possible to get a few statistics for the globe-trotter (passport): total number of inn visites, number of different countries, distance traveled (km and miles).
 - There shall be an option to publish statistics and/or screen captures to Facebook.
 - Pre-drawn characters could be shown right after the launch of the application (randomly), which would demonstrate what is feasible...
*/

#import <QuartzCore/QuartzCore.h>
#import "Paint.h"
#import "Button.h"
#import "Label.h"

#define paintPointMax 128
#define pathPointMax  256

#define brushSizeBig   32
#define brushSizeSmall (brushSizeBig / 2)
#define brushGap       (brushSizeBig / 8)

#define paperSize 64

static CGFloat const brushColors[8] = {1.0f, 1.0f, 1.0f, 0.4f, 1.0f, 1.0f, 1.0f, 0.0f};
static GLubyte const paintColors[][3] =
{
	{  0,   0,   0},
	{255,   0,   0},
	{255, 128,   0},
	{192, 192,   0},
	{  0, 128,   0},
	{  0, 128, 255},
	{  0,   0, 128},
	{192,   0, 128},
	{128, 128, 128},
};
static unsigned char const paintColorCount = sizeof(paintColors) / sizeof(*paintColors);

@implementation Paint

+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

unsigned long MathRoundPower2(unsigned long x)
{
	--x;
	x |= x >> 1;
	x |= x >> 2;
	x |= x >> 4;
	x |= x >> 8;
	x |= x >> 16;
	return(x + 1);
}

- (void)createTextureId:(GLuint)textureId withSize:(CGSize)textureSize
{
	if(textureId >= TEXTURE_COUNT)
	{
		return;
	}

	glBindTexture(GL_TEXTURE_2D, textureName[textureId]);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, MathRoundPower2(textureSize.width), MathRoundPower2(textureSize.height), 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
}

- (void)loadTextureId:(GLuint)textureId withImage:(CGImageRef)image withSize:(GLuint)textureSize
{
	if(textureId >= TEXTURE_COUNT)
	{
		return;
	}

	textureSize = MathRoundPower2(textureSize);
	GLubyte* texturePixels = malloc(textureSize * textureSize * 4 * sizeof(GLubyte));
	CGContextRef textureContext = CGBitmapContextCreate(texturePixels, textureSize, textureSize, 8, textureSize * 4, CGImageGetColorSpace(image), kCGImageAlphaPremultipliedLast);
	CGContextDrawImage(textureContext, CGRectMake(0.0f, 0.0f, (CGFloat)textureSize, (CGFloat)textureSize), image);
	CGContextRelease(textureContext);

	glBindTexture(GL_TEXTURE_2D, textureName[textureId]);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureSize, textureSize, 0, GL_RGBA, GL_UNSIGNED_BYTE, texturePixels);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	free(texturePixels);
}

- (void)loadBrushTextureId:(GLuint)textureId withSize:(GLuint)textureSize
{
	if(textureId >= TEXTURE_COUNT)
	{
		return;
	}
	textureSize = MathRoundPower2(textureSize);

	GLubyte* brushPixels = malloc(textureSize * textureSize * 4 * sizeof(GLubyte));
	CGColorSpaceRef brushColorSpace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef brushGradient = CGGradientCreateWithColorComponents(brushColorSpace, brushColors, NULL, 2);
	CGContextRef brushContext = CGBitmapContextCreate(brushPixels, textureSize, textureSize, 8, textureSize * 4, brushColorSpace, kCGImageAlphaPremultipliedLast);
	CGPoint const brushCenter = CGPointMake(brushSizeBig / 2, brushSizeBig / 2);
	CGContextClearRect(brushContext, CGRectInfinite);
	CGContextDrawRadialGradient(brushContext, brushGradient, brushCenter, brushSizeBig / 6, brushCenter, brushSizeBig / 2, kCGGradientDrawsBeforeStartLocation);
	CGContextRelease(brushContext);
	CGGradientRelease(brushGradient);
	CGColorSpaceRelease(brushColorSpace);

	glBindTexture(GL_TEXTURE_2D, textureName[textureId]);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureSize, textureSize, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushPixels);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	free(brushPixels);
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

		GLint width;
		GLint height;
		glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &width);
		glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &height);
		glViewport(0, 0, width, height);
		glMatrixMode(GL_PROJECTION);
		glOrthof(0.0f, width, height, 0.0f, -1.0f, 1.0f);

		// Initialize the textures
		glGenTextures(TEXTURE_COUNT, textureName);

		// Load the brush
		[self loadBrushTextureId:0 withSize:brushSizeBig];

		// Load the paper
		[self loadTextureId:1 withImage:[UIImage imageNamed:@"Paper.png"].CGImage withSize:paperSize];
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

		// Prepare a texture to render the painting
		[self createTextureId:2 withSize:CGSizeMake(width, height)];
		glGenFramebuffersOES(1, &textureFramebuffer);
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, textureFramebuffer);
		glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, textureName[2], 0);
		glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
		glClear(GL_COLOR_BUFFER_BIT);
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);

		screen.vertices[0] = 0;
		screen.vertices[1] = height;
		screen.vertices[2] = width;
		screen.vertices[3] = height;
		screen.vertices[4] = 0;
		screen.vertices[5] = 0;
		screen.vertices[6] = width;
		screen.vertices[7] = 0;

		screen.coordinates[0] = 0;
		screen.coordinates[1] = 0;
		screen.coordinates[2] = (width << 16) / MathRoundPower2(width);
		screen.coordinates[3] = 0;
		screen.coordinates[4] = 0;
		screen.coordinates[5] = (height << 16) / MathRoundPower2(height);
		screen.coordinates[6] = screen.coordinates[2];
		screen.coordinates[7] = screen.coordinates[5];

		screen.elements[0] = 0;
		screen.elements[1] = 1;
		screen.elements[2] = 2;
		screen.elements[3] = 3;

		textureCoordinates[0] = 0;
		textureCoordinates[1] = 0;
		textureCoordinates[2] = (width << 16) / paperSize;
		textureCoordinates[3] = 0;
		textureCoordinates[4] = 0;
		textureCoordinates[5] = (height << 16) / paperSize;
		textureCoordinates[6] = textureCoordinates[2];
		textureCoordinates[7] = textureCoordinates[5];

		textureMatrix1[0] = 0x10000 / paperSize;
		textureMatrix1[1] = 0;
		textureMatrix1[2] = 0;
		textureMatrix1[3] = 0;
		textureMatrix1[4] = 0;
		textureMatrix1[5] = -textureMatrix1[0];
		textureMatrix1[6] = 0;
		textureMatrix1[7] = 0;
		textureMatrix1[8] = 0;
		textureMatrix1[9] = 0;
		textureMatrix1[10] = 0x10000;
		textureMatrix1[11] = 0;
		textureMatrix1[12] = 0;
		textureMatrix1[13] = textureCoordinates[5];
		textureMatrix1[14] = 0;
		textureMatrix1[15] = 0x10000;

		textureMatrix2[0] = 0x10000 / MathRoundPower2(width);
		textureMatrix2[1] = 0;
		textureMatrix2[2] = 0;
		textureMatrix2[3] = 0;
		textureMatrix2[4] = 0;
		textureMatrix2[5] = -(0x10000 / MathRoundPower2(height));
		textureMatrix2[6] = 0;
		textureMatrix2[7] = 0;
		textureMatrix2[8] = 0;
		textureMatrix2[9] = 0;
		textureMatrix2[10] = 0x10000;
		textureMatrix2[11] = 0;
		textureMatrix2[12] = 0;
		textureMatrix2[13] = screen.coordinates[5];
		textureMatrix2[14] = 0;
		textureMatrix2[15] = 0x10000;

		// Enable the backface culling
		glEnable(GL_CULL_FACE);

		// Initialize the paint
		paintPoints = malloc(paintPointMax * sizeof(CGPoint));

		// Initialize the path and the triangles
		pathPoints = malloc(pathPointMax * sizeof(CGPoint));
		area = malloc((pathPointMax - 2) * sizeof(*area));

		// Add a button to allow changing the color
		buttons[0] = [[Button alloc] initWithColor:[UIColor redColor] withText:@"COLOR" withFontSize:12.0f inRectangle:CGRectMake(60.0f * 1, height - 40.0f, 60.0f, 40.0f) withTarget:self withSelector:@selector(button:)];
		buttons[0].label.glow = YES;
		[self addSubview:buttons[0]];
		[buttons[0] release];

		// Add a button to allow erasing the drawing
		buttons[1] = [[Button alloc] initWithColor:[UIColor redColor] withText:@"ERASER" withFontSize:12.0f inRectangle:CGRectMake(60.0f * 2, height - 40.0f, 60.0f, 40.0f) withTarget:self withSelector:@selector(button:)];
		buttons[1].label.glow = YES;
		[self addSubview:buttons[1]];
		[buttons[1] release];

		// Add a button to allow changing the size of the brush
		buttons[2] = [[Button alloc] initWithColor:[UIColor redColor] withText:@"SIZE" withFontSize:12.0f inRectangle:CGRectMake(60.0f * 3, height - 40.0f, 60.0f, 40.0f) withTarget:self withSelector:@selector(button:)];
		buttons[2].label.glow = YES;
		[self addSubview:buttons[2]];
		[buttons[2] release];

		// Add buttons to allow modifying the state
		buttons[3] = [[Button alloc] initWithColor:[UIColor redColor] withText:@"BACK" withFontSize:12.0f inRectangle:CGRectMake(60.0f * 0, height - 40.0f, 60.0f, 40.0f) withTarget:self withSelector:@selector(button:)];
		buttons[3].label.glow = YES;
		[self addSubview:buttons[3]];
		[buttons[3] release];

		buttons[4] = [[Button alloc] initWithColor:[UIColor redColor] withText:@"OK" withFontSize:12.0f inRectangle:CGRectMake(60.0f * 4, height - 40.0f, 60.0f, 40.0f) withTarget:self withSelector:@selector(button:)];
		buttons[4].label.glow = YES;
		[self addSubview:buttons[4]];
		[buttons[4] release];

		// Set the initial state
		state = STATE_PAINT;
		buttons[3].hidden = YES;
	}
	return self;
}

- (void)render
{
	static unsigned int frameCounter = 0;
	if(state != STATE_DONE)
	{
		// Make sure the shape isn't rotated
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		frameCounter = 0;

		// Setup everything to display a full screen quad
		glVertexPointer(2, GL_SHORT, 0, screen.vertices);
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glEnable(GL_TEXTURE_2D);
		glMatrixMode(GL_TEXTURE);
		glLoadIdentity();
		glColor4ub(255, 255, 255, 255);

		// Display the sheet of paper
		glTexCoordPointer(2, GL_FIXED, 0, textureCoordinates);
		glBindTexture(GL_TEXTURE_2D, textureName[1]);
		glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_BYTE, screen.elements);

		// Display the painted area
		glTexCoordPointer(2, GL_FIXED, 0, screen.coordinates);
		glBindTexture(GL_TEXTURE_2D, textureName[2]);
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);
		glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_BYTE, screen.elements);
		glDisable(GL_BLEND);

		// Clean-up
		glDisable(GL_TEXTURE_2D);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glDisableClientState(GL_VERTEX_ARRAY);

		// Display the shape
		if(state == STATE_CUT)
		{
			glVertexPointer(2, GL_FLOAT, 0, pathPoints);
			glEnableClientState(GL_VERTEX_ARRAY);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			glEnable(GL_BLEND);
			glColor4ub(127, 127, 127, 63);
			unsigned short areaIndex = areaCount;
			while(areaIndex--)
			{
				glDrawElements(GL_TRIANGLE_STRIP, 3, GL_UNSIGNED_SHORT, &area[areaIndex]);
			}
			glColor4ub(0, 0, 0, 63);
			glLineWidth(6.0f);
			glDrawArrays(drawTouch ? GL_LINE_STRIP : GL_LINE_LOOP, 0, pathPointCount);
			glColor4ub(0, 0, 0, 255);
			glLineWidth(2.0f);
			glDrawArrays(drawTouch ? GL_LINE_STRIP : GL_LINE_LOOP, 0, pathPointCount);
			glDisable(GL_BLEND);
			glDisableClientState(GL_VERTEX_ARRAY);
		}
	}
	else
	{
		// Rotate the shape
		++frameCounter;
		glMatrixMode(GL_MODELVIEW);

		// Clear the screen
		glClearColor(0.8f, 0.8f, 1.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		// Display the shape
		glVertexPointer(2, GL_FLOAT, 0, pathPoints);
		glEnableClientState(GL_VERTEX_ARRAY);

		glLoadIdentity();
		glTranslatef(160.0f + 5.0f, 240.0f + 20.0f, 0.0f);
		glRotatef(frameCounter * (90.0f / 60), 0.0f, 0.0f, 1.0f);
		glTranslatef(-160.0f, -240.0f, 0.0f);
		glColor4ub(0, 0, 0, 127);
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);
		unsigned short areaIndex = areaCount;
		while(areaIndex--)
		{
			glDrawElements(GL_TRIANGLE_STRIP, 3, GL_UNSIGNED_SHORT, &area[areaIndex]);
		}
		glDisable(GL_BLEND);

		glLoadIdentity();
		glTranslatef(160.0f, 240.0f, 0.0f);
		glRotatef(frameCounter * (90.0f / 60), 0.0f, 0.0f, 1.0f);
		glTranslatef(-160.0f, -240.0f, 0.0f);
		glTexCoordPointer(2, GL_FLOAT, 0, pathPoints);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, textureName[1]);
		glMatrixMode(GL_TEXTURE);
		glLoadMatrixx(textureMatrix1);
		glColor4ub(255, 255, 255, 255);
		areaIndex = areaCount;
		while(areaIndex--)
		{
			glDrawElements(GL_TRIANGLE_STRIP, 3, GL_UNSIGNED_SHORT, &area[areaIndex]);
		}

		glBindTexture(GL_TEXTURE_2D, textureName[2]);
		glLoadMatrixx(textureMatrix2);
		glEnable(GL_BLEND);
		areaIndex = areaCount;
		while(areaIndex--)
		{
			glDrawElements(GL_TRIANGLE_STRIP, 3, GL_UNSIGNED_SHORT, &area[areaIndex]);
		}
		glDisable(GL_BLEND);
		glDisable(GL_TEXTURE_2D);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glDisableClientState(GL_VERTEX_ARRAY);
	}

	// Render the frame
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (void)paint
{
	// Bind the texture to which everything shall be rendered
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, textureFramebuffer);

	// Draw the points
	glVertexPointer(2, GL_FLOAT, 0, paintPoints);
	glEnableClientState(GL_VERTEX_ARRAY);
	glBindTexture(GL_TEXTURE_2D, textureName[0]);
	glEnable(GL_TEXTURE_2D);
	glTexEnvf(GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE);
	glPointSize(paintBrushBig ? brushSizeBig : brushSizeSmall);
	glEnable(GL_POINT_SPRITE_OES);
	if(paintBrushErase)
	{
		glColor4ub(255, 255, 255, 255);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	}
	else
	{
		GLubyte const*const colors = paintColors[paintColorIndex];
		glColor4ub(colors[0], colors[1], colors[2], 255);
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	}
	glEnable(GL_BLEND);
	glDrawArrays(GL_POINTS, 0, paintPointCount);
	glDisable(GL_BLEND);
	glDisable(GL_POINT_SPRITE_OES);
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_VERTEX_ARRAY);

	// Restore the binding
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
}

- (void)button:(Button*)button
{
	// Handle the buttons actions
	if(button == buttons[0])
	{
		if(paintBrushErase)
		{
			paintBrushErase = NO;
		}
		else if(++paintColorIndex >= paintColorCount)
		{
			paintColorIndex = 0;
		}
	}
	else if(button == buttons[1])
	{
		paintBrushErase = YES;
	}
	else if(button == buttons[2])
	{
		paintBrushBig = !paintBrushBig;
	}
	else if(button == buttons[3])
	{
		if(state > STATE_PAINT)
		{
			if(state == STATE_DONE)
			{
				[timer invalidate];
			}
			--state;
			[self render];
		}
	}
	else if(button == buttons[4])
	{
		if(state < STATE_DONE)
		{
			++state;
			if(state == STATE_DONE)
			{
				timer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60 target:self selector:@selector(render) userInfo:nil repeats:YES];
			}
			[self render];
		}
	}

	// Hide / show buttons according to the curren state
	buttons[0].hidden = buttons[1].hidden = buttons[2].hidden = state != STATE_PAINT;
	buttons[3].hidden = state == STATE_PAINT;
	buttons[4].hidden = state == STATE_DONE;
}

- (void)willMoveToSuperview:(UIView*)superView
{
	if(superView)
	{
		[self render];
	}
	else
	{
		[timer invalidate];
	}
}

- (CGFloat)crossProductVertexIndex:(unsigned short)indexCurrent
{
	unsigned short const indexPrevious = vertexInfo[indexCurrent].indexPrevious;
	unsigned short const indexNext = vertexInfo[indexCurrent].indexNext;

	CGPoint vectorPrevious;
	vectorPrevious.x = pathPoints[indexCurrent].x - pathPoints[indexPrevious].x;
	vectorPrevious.y = pathPoints[indexCurrent].y - pathPoints[indexPrevious].y;
	CGPoint vectorNext;
	vectorNext.x = pathPoints[indexNext].x - pathPoints[indexCurrent].x;
	vectorNext.y = pathPoints[indexNext].y - pathPoints[indexCurrent].y;

	return vectorNext.x * vectorPrevious.y - vectorNext.y * vectorPrevious.x;
}

- (BOOL)isEarVertexIndex:(unsigned short)indexCurrent
{
	// Make sure the vertex is convex
	if(!vertexInfo[indexCurrent].convex)
	{
		return NO;
	}

	// Define the triangle
	unsigned short const indexPrevious = vertexInfo[indexCurrent].indexPrevious;
	unsigned short const indexNext = vertexInfo[indexCurrent].indexNext;

	CGPoint vector[3];
	vector[0].x = pathPoints[indexCurrent].x - pathPoints[indexPrevious].x;
	vector[0].y = pathPoints[indexCurrent].y - pathPoints[indexPrevious].y;
	vector[1].x = pathPoints[indexNext].x - pathPoints[indexCurrent].x;
	vector[1].y = pathPoints[indexNext].y - pathPoints[indexCurrent].y;
	vector[2].x = pathPoints[indexPrevious].x - pathPoints[indexNext].x;
	vector[2].y = pathPoints[indexPrevious].y - pathPoints[indexNext].y;

	// Let's check all other vertices
	unsigned short indexOther = vertexInfo[indexNext].indexNext;
	while(indexOther != indexPrevious)
	{
		// Check whether this vertex is reflex
		if(!vertexInfo[indexOther].convex)
		{
			// Check whether it is inside the triangle being tested
			CGPoint vectorEdgePoint;
			vectorEdgePoint.x = pathPoints[indexOther].x - pathPoints[indexPrevious].x;
			vectorEdgePoint.y = pathPoints[indexOther].y - pathPoints[indexPrevious].y;
			if(vector[0].x * vectorEdgePoint.y < vector[0].y * vectorEdgePoint.x)
			{
				vectorEdgePoint.x = pathPoints[indexOther].x - pathPoints[indexCurrent].x;
				vectorEdgePoint.y = pathPoints[indexOther].y - pathPoints[indexCurrent].y;
				if(vector[1].x * vectorEdgePoint.y < vector[1].y * vectorEdgePoint.x)
				{
					vectorEdgePoint.x = pathPoints[indexOther].x - pathPoints[indexNext].x;
					vectorEdgePoint.y = pathPoints[indexOther].y - pathPoints[indexNext].y;
					if(vector[2].x * vectorEdgePoint.y < vector[2].y * vectorEdgePoint.x)
					{
						return NO;
					}
				}
			}
		}

		// Next vertex
		indexOther = vertexInfo[indexOther].indexNext;
	}
	return YES;
}

- (void)triangulate
{
	// Make sure there are enough points
	if(pathPointCount < 3)
	{
		return;
	}

	// Allocate some memory to store the vertex information
	vertexInfo = malloc(sizeof(VertexInfo) * pathPointCount);

	// Define the information of each vertex
	CGFloat areaDouble = 0.0f;
	unsigned short indexPrevious = pathPointCount - 2;
	unsigned short indexCurrent = pathPointCount - 1;
	for(unsigned short indexNext = 0; indexNext < pathPointCount; ++indexNext)
	{
		vertexInfo[indexCurrent].indexPrevious = indexPrevious;
		vertexInfo[indexCurrent].indexNext = indexNext;

		CGFloat const crossProduct = [self crossProductVertexIndex:indexCurrent];
		vertexInfo[indexCurrent].convex = crossProduct > 0;
		areaDouble += crossProduct;

		indexPrevious = indexCurrent;
		indexCurrent = indexNext;
	}

	// Check whether the polygon is defined in the wrong direction
	if(areaDouble < 0)
	{
		for(unsigned short index = 0; index < pathPointCount; ++index)
		{
			unsigned short const indexSwap = vertexInfo[index].indexPrevious;
			vertexInfo[index].indexPrevious = vertexInfo[index].indexNext;
			vertexInfo[index].indexNext = indexSwap;
			vertexInfo[index].convex = !vertexInfo[index].convex;
		}
	}

	// Perform the triangulation
	areaCount = 0;
	unsigned short const triangleCount = pathPointCount - 2;
	indexCurrent = 0;
	unsigned short indexGiveUp = vertexInfo[indexCurrent].indexPrevious;
	while(areaCount < triangleCount && indexCurrent != indexGiveUp)
	{
		unsigned short const indexNext = vertexInfo[indexCurrent].indexNext;
		if([self isEarVertexIndex:indexCurrent])
		{
			// Take note of this triangle
			unsigned short const indexPrevious = vertexInfo[indexCurrent].indexPrevious;
			area[areaCount].a = indexPrevious;
			area[areaCount].b = indexCurrent;
			area[areaCount].c = indexNext;
			++areaCount;

			// Remove this vertex
			vertexInfo[indexPrevious].indexNext = indexNext;
			vertexInfo[indexNext].indexPrevious = indexPrevious;

			// Update its neighbors
			vertexInfo[indexPrevious].convex = vertexInfo[indexPrevious].convex || [self crossProductVertexIndex:indexPrevious] > 0;
			vertexInfo[indexNext].convex = vertexInfo[indexNext].convex || [self crossProductVertexIndex:indexNext] > 0;

			// Update the "give up" index
			indexGiveUp = indexPrevious;
		}
		indexCurrent = indexNext;
	}

	// Free the memory allocated for the vertex information
	free(vertexInfo);
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	drawTouch = [touches anyObject];
	if(state == STATE_PAINT)
	{
		paintPoints[0] = [drawTouch previousLocationInView:self];
		paintPointCount = 1;
		drawDistance = 0;
		[self paint];
	}
	else if(state == STATE_CUT)
	{
		pathPoints[0] = [drawTouch locationInView:self];
		pathPointCount = 1;
		areaCount = 0;
	}
	[self render];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	if(![touches containsObject:drawTouch])
	{
		return;
	}
	if(state == STATE_PAINT)
	{
		CGPoint point = [drawTouch previousLocationInView:self];
		CGPoint direction = [drawTouch locationInView:self];
		direction.x -= point.x;
		direction.y -= point.y;
		CGFloat const norm = sqrtf(direction.x * direction.x + direction.y * direction.y);

		CGFloat const rest = drawDistance;
		drawDistance += norm;
		if(drawDistance >= brushGap)
		{
			CGFloat scale = (brushGap - rest) / norm;
			point.x += direction.x * scale;
			point.y += direction.y * scale;
			paintPoints[0] = point;
			paintPointCount = 1;
			drawDistance -= brushGap;

			if(drawDistance >= brushGap)
			{
				scale = brushGap / norm;
				direction.x *= scale;
				direction.y *= scale;
				do
				{
					if(paintPointCount >= paintPointMax)
					{
						[self paint];
						paintPointCount = 0;
					}
					point.x += direction.x;
					point.y += direction.y;
					paintPoints[paintPointCount++] = point;
					drawDistance -= brushGap;
				}
				while(drawDistance >= brushGap);
			}
			[self paint];
			[self render];
		}
	}
	else if(state == STATE_CUT && pathPointCount < pathPointMax)
	{
		CGPoint const point = [drawTouch locationInView:self];
		CGFloat const dx = point.x - pathPoints[pathPointCount - 1].x;
		CGFloat const dy = point.y - pathPoints[pathPointCount - 1].y;
		CGFloat const norm = sqrtf(dx * dx + dy * dy);
		if(norm > 9.0f)
		{
			if(pathPointCount == 1 || pathVector.x * dx + pathVector.y * dy < 0.95f * norm * pathVectorNorm)
			{
				++pathPointCount;
				pathVector.x = dx;
				pathVector.y = dy;
				pathVectorNorm = norm;
			}
			pathPoints[pathPointCount - 1].x = point.x;
			pathPoints[pathPointCount - 1].y = point.y;
		}
		[self render];
	}
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	drawTouch = nil;
	if(state == STATE_CUT)
	{
		[self triangulate];
		[self render];
	}
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
	[self touchesEnded:touches withEvent:event];
}

void ScreenshotFreeData(void* info, void const* data, size_t dataSize)
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
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, dataSize, ScreenshotFreeData);
	CGImageRef image = CGImageCreate(width, height, 8, 8 * sizeof(GLuint), lineSize, colorSpace, kCGBitmapByteOrderDefault, provider, NULL, NO, kCGRenderingIntentDefault);
	CGColorSpaceRelease(colorSpace);
	CGDataProviderRelease(provider);
	UIImage* screenshot = [UIImage imageWithCGImage:image];
	CGImageRelease(image);
	return screenshot;
}

- (void)dealloc
{
	// Release the triangles and the path
	free(area);
	free(pathPoints);

	// Release the points
	free(paintPoints);

	// Delete the textures
	glDeleteTextures(TEXTURE_COUNT, textureName);

	// Destroy the view
	glDeleteFramebuffersOES(1, &textureFramebuffer);
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
