/*
 * Libraries.
 */
#include <stdlib.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <OpenGLES/ES1/gl.h>
#include "math.h"
#include "blob.h"

/*
 * Macros.
 */
/**
 * Number of available textures.
 */
#define BLOB_TEXTURE_COUNT 16

/**
 * Number of steps of the Euler integration.<br/>
 * IMPORTANT NOTE: the number of steps of the Euler integration must be as low as possible to increase performances, but high enough to prevent computation overflows (this depends on the characteristics of the blobs).
 */
#define BLOB_EULER (1 << BLOB_EULER_SHIFT)

/**
 * Size of a pool's block, in power of 2 (i.e. the value "N" actually means "2^N" elements in the block).
 */
#define BLOB_POOL_BLOCK_SIZE_SHIFT 4

/**
 * Binary mask used to round the size of a pool to the next block.
 */
#define BLOB_POOL_ROUND_MASK ((1 << BLOB_POOL_BLOCK_SIZE_SHIFT) - 1)

/**
 * Maximum number of elements that a "snail" blob can have.
 */
#define BLOB_SNAIL_ELEMENT_MAX 46

/*
 * Types.
 */
/**
 * Basic 2D vector:
 * <ul>
 * <li>x X component of the vector;</li>
 * <li>y Y component of the vector.</li>
 * </ul>
 */
typedef struct
{
	signed long x;
	signed long y;
}
BlobVector;

/**
 * Position of a blob element:
 * <ul>
 * <li>x X coordinate;</li>
 * <li>y Y coordinate.</li>
 * </ul>
 */
typedef struct
{
	signed short x;
	signed short y;
}
BlobElementPosition;

/**
 * Link of a blob:
 * <ul>
 * <li>elementIndex1 Index of the first element of the link;</li>
 * <li>elementIndex2 Index of the second element of the link.</li>
 * </ul>
 * Note: elements that define external links have to be ordered so that the outer border is on the right side of the vector.
 */
typedef struct
{
	unsigned char elementIndex1;
	unsigned char elementIndex2;
}
BlobLink;

/**
 * Area of a blob:
 * <ul>
 * <li>elementIndex1 Index of the first element of the triangle;</li>
 * <li>elementIndex2 Index of the second element of the triangle;</li>
 * <li>elementIndex3 Index of the third element of the triangle.</li>
 * </ul>
 * Note: elements that define the area must be given in the trigonometric order.
 */
typedef struct
{
	unsigned char elementIndex1;
	unsigned char elementIndex2;
	unsigned char elementIndex3;
}
BlobArea;

/**
 * Blob shape:
 * <ul>
 * <li>referenceCount Number of references of the shape (the shape should be destroyed when the count of references reaches 0);</li>
 * <li>elementCount Number of elements that compose the shape (excluding its center of mass);</li>
 * <li>elementFirstExternalIndex Index of the first element that is on the outer border of the shape (all following elements are also external);</li>
 * <li>element Pointer to the element position array (which contains the center of mass);</li>
 * <li>linkCount Number of links that compose the shape;</li>
 * <li>link Pointer to the link array;</li>
 * <li>areaCount Number of area that compose the shape;</li>
 * <li>area Pointer to the area array.</li>
 * </ul>
 */
typedef struct
{
	unsigned char referenceCount;

	unsigned char elementCount;
	unsigned char elementFirstExternalIndex;
	BlobVector* elementPosition;

	unsigned char linkCount;
	BlobLink* link;

	unsigned char areaCount;
	BlobArea* area;
}
BlobShape;

/**
 * Blob object:
 * <ul>
 * <li>blobPrevious Pointer to the previous blob in the chain of blobs;</li>
 * <li>blobNext Pointer to the next blob in the chain of blobs;</li>
 * <li>type Type of the blob;</li>
 * <li>textureId Identifier (index) of the texture;</li>
 * <li>textureRepeat Flag that indicates whether the texture shall be repeated (YES) or scaled (NO);</li>
 * <li>colorId Identifier (index) of the color;</li>
 * <li>userId User defined identifier;</li>
 * <li>mass Mass of each element that compose the blob;</li>
 * <li>elasticity Elasticity of the blob;</li>
 * <li>friction Friction of the blob;</li>
 * <li>shape Pointer to the shape of the blob;</li>
 * <li>elementSpeed Pointer to the element speed array;</li>
 * <li>elementPosition Pointer to the element position array;</li>
 * <li>special Special characteristics of the blob (i.e. characteristics that depend on the type of the blob):</li>
 * <ul>
 * <li>staticTransformation Pointer to the transformation information of a static blob;</li>
 * <li>stiffness Stiffness of the springs that compose a dynamic blob;</li>
 * <li>damping Damping of the springs that compose a dynamic blob;</li>
 * <li>pressure Pressure of the gaz inside a dynamic blob;</li>
 * <li>linkLength Pointer to the link length array (default length of each spring of a dynamic blob).</li>
 * </ul>
 * <li>xMin Left of the blob's bounding box;</li>
 * <li>xMax Right of the blob's bounding box;</li>
 * <li>yMin Bottom of the blob's bounding box;</li>
 * <li>yMax Top of the blob's bounding box;</li>
 * <li>scaleX Texture scaling along the X axis (applicable only when "textureRepeat" is set);</li>
 * <li>scaleY Texture scaling along the Y axis (applicable only when "textureRepeat" is set);</li>
 * <li>collisionMask Collision mask of the blob (1 bit per group).</li>
 * </ul>
 */
typedef struct Blob
{
	struct Blob* blobPrevious;
	struct Blob* blobNext;

	BlobType type;

	unsigned char textureId;
	unsigned char textureRepeat;
	unsigned char colorId;
	unsigned char userId;
	signed long mass;
	signed long elasticity;
	signed long friction;

	BlobShape* shape;
	BlobVector* elementSpeed;
	BlobElementPosition* elementPosition;

	union
	{
		BlobTransformation* staticTransformation;
		struct
		{
			signed long stiffness;
			signed long damping;
			signed long pressure;
			signed long* linkLength;
		}
		dynamic;
	}
	special;

	signed long xMin;
	signed long xMax;
	signed long yMin;
	signed long yMax;

	signed long scaleX;
	signed long scaleY;

	unsigned char collisionMask;
}
Blob;

/**
 * Blob background:
 * <ul>
 * <li>textureId Identifier (index) of the texture;</li>
 * <li>colorId Identifier (index) of the color;</li>
 * <li>shutterLevel Level of the screen shutter, from 0 (fully opened) to 16 (fully closed);</li>
 * <li>vertices Vertices (x and y coordinates) that define the background quad;</li>
 * <li>matrix Texture transformation matrix;</li>
 * <li>elements List of vertex indexes (ordered for the triangle strip to be displayed properly).</li>
 * </ul>
 */
typedef struct
{
	unsigned char textureId;
	unsigned char colorId;
	unsigned char shutterLevel;
	GLshort vertices[8];
	GLfixed matrix[16];
	GLubyte elements[4];
}
BlobBackground;

/*
 * Global variables.
 */
/**
 * Textures.
 */
GLuint blobTextureName[BLOB_TEXTURE_COUNT];

/**
 * Pointer to the first object of the chain of blob objects.
 */
Blob* blobFirst = NULL;

/**
 * Pointer to the last object of the chain of blob objects.
 */
Blob* blobLast = NULL;

/**
 * Pool of force vectors, used when the forces applied on a blob object have to be updated.
 */
BlobVector* blobForcePool = NULL;

/**
 * Size of the pool of force vectors.
 */
unsigned char blobForcePoolSize = 0;

/**
 * Current gravity vector.
 */
BlobVector blobGravity = {0, 0};

/**
 * Background data.
 */
BlobBackground blobBackground;

/*
 * Functions.
 */
/**
 * Initialize the blob engine.
 *
 * @param left Left coordindate of the view port.
 * @param right Right coordindate of the view port.
 * @param bottom Bottom coordindate of the view port.
 * @param top Top coordindate of the view port.
 * @param shutterLevel Level of the screen shutter, from 0 (fully opened) to 16 (fully closed).
 */
void BlobInitialize(GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, unsigned char const shutterLevel)
{
	// Initialize the view port
	GLint width;
	GLint height;
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &width);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &height);
	glViewport(0, 0, width, height);
	glMatrixMode(GL_PROJECTION);
	glOrthof(left, right, bottom, top, -1.0f, 1.0f);

	// Initialize the textures
	glGenTextures(BLOB_TEXTURE_COUNT, blobTextureName);

	// Enable the backface culling
	glEnable(GL_CULL_FACE);

	// Initialize the model's matrix
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	// Initialize the background data
	blobBackground.vertices[0] = left;
	blobBackground.vertices[1] = bottom;
	blobBackground.vertices[2] = right;
	blobBackground.vertices[3] = bottom;
	blobBackground.vertices[4] = left;
	blobBackground.vertices[5] = top;
	blobBackground.vertices[6] = right;
	blobBackground.vertices[7] = top;

	blobBackground.matrix[0] = (GLfixed)(right - left) >> BLOB_TEXTURE_REPEAT_SHIFT;
	blobBackground.matrix[1] = 0;
	blobBackground.matrix[2] = 0;
	blobBackground.matrix[3] = 0;
	blobBackground.matrix[4] = 0;
	blobBackground.matrix[5] = (GLfixed)(bottom - top) >> BLOB_TEXTURE_REPEAT_SHIFT;
	blobBackground.matrix[6] = 0;
	blobBackground.matrix[7] = 0;
	blobBackground.matrix[8] = 0;
	blobBackground.matrix[9] = 0;
	blobBackground.matrix[10] = 0x10000;
	blobBackground.matrix[11] = 0;
	blobBackground.matrix[12] = 0;
	blobBackground.matrix[13] = 0;
	blobBackground.matrix[14] = 0;
	blobBackground.matrix[15] = 0x10000;

	blobBackground.elements[0] = 0;
	blobBackground.elements[1] = 1;
	blobBackground.elements[2] = 2;
	blobBackground.elements[3] = 3;

	// Initialize the screen shutter
	blobBackground.shutterLevel = shutterLevel;
}

/**
 * Finalize the blob engine.
 */
void BlobFinalize()
{
	// Destroy all the blobs
	BlobObjectDestroy(NULL);

	// Destroy the textures
	glDeleteTextures(BLOB_TEXTURE_COUNT, blobTextureName);
}

/**
 * Load a texture.
 *
 * @param imageIn Image to be loaded.
 * @param imageOut Pointer to the loaded image (this image will have to be released using "CGImageRelease").
 * @param textureId Texture identifier (index).
 * @param textureSize Size of the texture (width / height).
 */
void BlobLoadTexture(CGImageRef imageIn, CGImageRef* imageOut, GLuint textureId, GLuint textureSize)
{
	if(textureId >= BLOB_TEXTURE_COUNT)
	{
		return;
	}

	textureSize = MathRoundPower2(textureSize);
	GLubyte* texturePixels = malloc(textureSize * textureSize * 4 * sizeof(GLubyte));
	CGContextRef textureContext = CGBitmapContextCreate(texturePixels, textureSize, textureSize, 8, textureSize * 4, CGImageGetColorSpace(imageIn), kCGImageAlphaNoneSkipLast);
	CGContextDrawImage(textureContext, CGRectMake(0.0f, 0.0f, (CGFloat)textureSize, (CGFloat)textureSize), imageIn);
	if(imageOut)
	{
		*imageOut = CGBitmapContextCreateImage(textureContext);
	}
	CGContextRelease(textureContext);

	glBindTexture(GL_TEXTURE_2D, blobTextureName[textureId]);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureSize, textureSize, 0, GL_RGBA, GL_UNSIGNED_BYTE, texturePixels);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	free(texturePixels);
}

/**
 * Add an element to a shape.
 *
 * @param shape Pointer to the shape which an element has to be added to.
 * @param elementPosition Pointer to the position of the element.
 */
void BlobShapeAddElement(BlobShape* shape, const BlobVector* elementPosition)
{
	BlobVector* elementPositionShape = &shape->elementPosition[shape->elementCount++];
	elementPositionShape->x = elementPosition->x;
	elementPositionShape->y = elementPosition->y;
}

/**
 * Add a link to a shape.
 *
 * @param shape Pointer to the shape which a link has to be added to.
 * @param elementIndex1 Index of the first element of the link.
 * @param elementIndex2 Index of the second element of the link.
 */
void BlobShapeAddLink(BlobShape* shape, const unsigned char elementIndex1, const unsigned char elementIndex2)
{
	BlobLink* link = &shape->link[shape->linkCount++];
	link->elementIndex1 = elementIndex1;
	link->elementIndex2 = elementIndex2;
}

/**
 * Add an area to a shape.
 *
 * @param shape Pointer to the shape which an area has to be added to.
 * @param elementIndex1 Index of the first element of the triangle.
 * @param elementIndex2 Index of the second element of the triangle.
 * @param elementIndex3 Index of the third element of the triangle.
 */
void BlobShapeAddArea(BlobShape* shape, const unsigned char elementIndex1, const unsigned char elementIndex2, const unsigned char elementIndex3)
{
	BlobArea* area = &shape->area[shape->areaCount++];
	area->elementIndex1 = elementIndex1;
	area->elementIndex2 = elementIndex2;
	area->elementIndex3 = elementIndex3;
}

/**
 * Create a simple shape, without any topology information.<br/>
 * Notes:
 * <ul>
 * <li>This function doesn't handle memory allocation failures;</li>
 * <li>This function doesn't initialize the link and area arrays.</li>
 * </ul>
 *
 * @param elementCount Number of elements that compose the shape (excluding its center of mass).
 * @return Pointer to the newly created shape, or NULL if the number of elements is too low.
 */
BlobShape* BlobShapeCreateBegin(const unsigned char elementCount)
{
	// Check whether there are enough elements
	if(elementCount < 3)
	{
		return(NULL);
	}

	// Create the shape and initialize its count of references
	BlobShape* shape = malloc(sizeof(BlobShape));
	shape->referenceCount = 1;

	// Reset the shape's number of elements, links and areas
	shape->elementCount = 0;
	shape->linkCount = 0;
	shape->areaCount = 0;

	// Initialize the element position array
	// Note: this array actually has elementCount+1 elements (the last element is the center of mass of the blob)
	shape->elementPosition = malloc((elementCount + 1) * sizeof(BlobVector));

	// Return a pointer to the newly created shape
	return(shape);
}

/**
 * Finalize the creation of a shape: set the position of the shape's center of mass and scale the shape so that it fits in the texture.<br/>
 * Notes:
 * <ul>
 * <li>This function shall only be called once all the elements have been added to the shape;</li>
 * <li>The center of mass being used to improve the display and help detecting collisions, it doesn't need to represent the entire shape but just its envelop (i.e. external elements).</li>
 * </ul>
 *
 * @param shape Pointer to the shape which is being created.
 */
void BlobShapeCreateEnd(BlobShape* shape)
{
	// Initialize the coordinates of the bounding box
	signed long xMin = FIXED_INFINITY;
	signed long xMax = -FIXED_INFINITY;
	signed long yMin = FIXED_INFINITY;
	signed long yMax = -FIXED_INFINITY;

	// Initialize the position of the center of mass
	BlobVector* centerPosition = &shape->elementPosition[shape->elementCount];
	centerPosition->x = 0;
	centerPosition->y = 0;

	// Check the position of each external element
	for(unsigned char elementIndex = shape->elementFirstExternalIndex; elementIndex < shape->elementCount; ++elementIndex)
	{
		// Get a pointer to the position of the element
		BlobVector* elementPosition = &shape->elementPosition[elementIndex];

		// Update the coordinates of the bounding box
		if(xMin > elementPosition->x)
		{
			xMin = elementPosition->x;
		}
		if(xMax < elementPosition->x)
		{
			xMax = elementPosition->x;
		}
		if(yMin > elementPosition->y)
		{
			yMin = elementPosition->y;
		}
		if(yMax < elementPosition->y)
		{
			yMax = elementPosition->y;
		}

		// Prepare the update of the position of the center of mass
		centerPosition->x += elementPosition->x;
		centerPosition->y += elementPosition->y;
	}

	// Update the position of the center of mass
	const signed long elementExternalCount = shape->elementCount - shape->elementFirstExternalIndex;
	centerPosition->x /= elementExternalCount;
	centerPosition->y /= elementExternalCount;

	// Apply a basic scaling transformation so that all the elements are within the texture coordinates (incl. the center of mass)
	xMax -= xMin;
	yMax -= yMin;
	for(unsigned char elementIndex = 0; elementIndex <= shape->elementCount; ++elementIndex)
	{
		BlobVector* elementPosition = &shape->elementPosition[elementIndex];
		elementPosition->x = ((elementPosition->x - xMin) << (FIXED_POINT_SHIFT + FIXED_POINT_SHIFT)) / xMax;
		elementPosition->y = ((elementPosition->y - yMin) << (FIXED_POINT_SHIFT + FIXED_POINT_SHIFT)) / yMax;
	}
}

/**
 * Create a "box" shape.<br/>
 * Note: this function doesn't handle memory allocation failures.
 *
 * @return Reference of the newly created shape, or NULL if it couldn't be created.
 */
BlobShapeReference BlobShapeCreateBox()
{
	// Create the shape
	BlobShape* shape = BlobShapeCreateBegin(4);
	if(!shape)
	{
		return(NULL);
	}

	// Initialize the link arrays
	shape->link = malloc(4 * sizeof(BlobLink));

	// Initialize the area array
	shape->area = malloc(2 * sizeof(BlobArea));

	// Set the shape's topology
	shape->elementFirstExternalIndex = 0;

	BlobVector elementPosition;
	elementPosition.x = 0;
	elementPosition.y = 0;
	BlobShapeAddElement(shape, &elementPosition);
	elementPosition.x = FIXED_POINT;
	BlobShapeAddElement(shape, &elementPosition);
	elementPosition.y = FIXED_POINT;
	BlobShapeAddElement(shape, &elementPosition);
	elementPosition.x = 0;
	BlobShapeAddElement(shape, &elementPosition);

	BlobShapeAddLink(shape, 0, 1);
	BlobShapeAddLink(shape, 1, 2);
	BlobShapeAddLink(shape, 2, 3);
	BlobShapeAddLink(shape, 3, 0);

	BlobShapeAddArea(shape, 0, 1, 2);
	BlobShapeAddArea(shape, 2, 3, 0);

	// Finalize the creation of the shape
	BlobShapeCreateEnd(shape);

	// Return the reference of the newly created shape
	return((BlobShapeReference)shape);
}

/**
 * Create a "snail" shape.<br/>
 * Notes:
 * <ul>
 * <li>This function doesn't handle memory allocation failures;</li>
 * <li>This type of shape can have up to "BLOB_SNAIL_ELEMENT_MAX" elements only.</li>
 * </ul>
 *
 * @param elementCount Number of elements that compose the shape (excluding its center of mass).
 * @return Reference of the newly created shape, or NULL if the number of elements isn't correct.
 */
BlobShapeReference BlobShapeCreateSnail(const unsigned char elementCount)
{
	// Check whether the number of elements is too high for our assumptions to be correct
	if(elementCount > BLOB_SNAIL_ELEMENT_MAX)
	{
		return(NULL);
	}

	// Create the shape
	BlobShape* shape = BlobShapeCreateBegin(elementCount);
	if(!shape)
	{
		return(NULL);
	}

	// Initialize the link array
	// Note: the estimated number of links is 2.5*elementCount (which is true up to 50 elements)
	shape->link = malloc(((elementCount * 5) >> 1) * sizeof(BlobLink));

	// Initialize the area array
	// Note: the estimated number of areas is 1.5*elementCount (which is true up to 46 elements)
	shape->area = malloc(((elementCount * 3) >> 1) * sizeof(BlobArea));

	// Initialize the local link counter array
	unsigned char* linkCounter = malloc(elementCount * sizeof(unsigned char));

	// First and second elements
	shape->elementFirstExternalIndex = 0;

	BlobVector elementPosition;
	elementPosition.x = 0;
	elementPosition.y = 0;
	BlobShapeAddElement(shape, &elementPosition);
	elementPosition.x = FIXED_POINT;
	BlobShapeAddElement(shape, &elementPosition);

	BlobShapeAddLink(shape, 0, 1);
	linkCounter[0] = 1;
	linkCounter[1] = 1;

	// Other elements
	const signed long cos60deg = COS(PI / 3);
	const signed long sin60deg = SIN(PI / 3);
	for(unsigned char elementIndex = 2; elementIndex < elementCount; ++elementIndex)
	{
		const BlobVector* centerPosition = &shape->elementPosition[shape->elementFirstExternalIndex];
		BlobVector vector;
		vector.x = elementPosition.x - centerPosition->x;
		vector.y = elementPosition.y - centerPosition->y;
		elementPosition.x = ((vector.x * cos60deg - vector.y * sin60deg) >> FIXED_POINT_SHIFT) + centerPosition->x;
		elementPosition.y = ((vector.x * sin60deg + vector.y * cos60deg) >> FIXED_POINT_SHIFT) + centerPosition->y;
		BlobShapeAddElement(shape, &elementPosition);

		BlobShapeAddLink(shape, elementIndex - 1, elementIndex);
		BlobShapeAddLink(shape, elementIndex, shape->elementFirstExternalIndex);
		BlobShapeAddArea(shape, elementIndex - 1, elementIndex, shape->elementFirstExternalIndex);

		++linkCounter[elementIndex - 1];
		linkCounter[elementIndex] = 2;
		if(++linkCounter[shape->elementFirstExternalIndex] >= 6)
		{
			BlobShapeAddLink(shape, elementIndex, ++shape->elementFirstExternalIndex);
			BlobShapeAddArea(shape, shape->elementFirstExternalIndex - 1, elementIndex, shape->elementFirstExternalIndex);

			++linkCounter[elementIndex];
			++linkCounter[shape->elementFirstExternalIndex];
		}
	}

	// Free the memory allocated for the local link counter array
	free(linkCounter);

	// Finalize the creation of the shape
	BlobShapeCreateEnd(shape);

	// Return the reference of the newly created shape
	return((BlobShapeReference)shape);
}

/**
 * Create a "balloon" shape.<br/>
 * Note: this function doesn't handle memory allocation failures.
 *
 * @param elementCount Number of elements that compose the shape (excluding its center of mass).
 * @return Reference of the newly created shape, or NULL if the number of elements is too low.
 */
BlobShapeReference BlobShapeCreateBalloon(const unsigned char elementCount)
{
	// Create the shape
	BlobShape* shape = BlobShapeCreateBegin(elementCount);
	if(!shape)
	{
		return(NULL);
	}

	// Initialize the link array
	shape->link = malloc(elementCount * sizeof(BlobLink));

	// Initialize the area array
	shape->area = malloc(elementCount * sizeof(BlobArea));

	// First element
	shape->elementFirstExternalIndex = 0;

	BlobVector elementPosition;
	elementPosition.x = FIXED_POINT;
	elementPosition.y = 0;
	BlobShapeAddElement(shape, &elementPosition);

	// Other elements
	for(unsigned char elementIndex = 1; elementIndex < elementCount; ++elementIndex)
	{
		const unsigned char angle = (elementIndex * 2 * PI) / elementCount;
		elementPosition.x = COS(angle);
		elementPosition.y = SIN(angle);
		BlobShapeAddElement(shape, &elementPosition);

		BlobShapeAddLink(shape, elementIndex - 1, elementIndex);
		BlobShapeAddArea(shape, elementCount, elementIndex - 1, elementIndex);
	}
	BlobShapeAddLink(shape, elementCount - 1, 0);
	BlobShapeAddArea(shape, elementCount, elementCount - 1, 0);

	// Finalize the creation of the shape
	BlobShapeCreateEnd(shape);

	// Return the reference of the newly created shape
	return((BlobShapeReference)shape);
}

/**
 * Release a shape and destroy it if its count of references reaches 0.
 */
void BlobShapeRelease(const BlobShapeReference shapeReference)
{
	// Check whether the reference is null or not
	if(shapeReference)
	{
		// Check the shape's count of references
		BlobShape* shape = (BlobShape*)shapeReference;
		if(shape->referenceCount > 1)
		{
			// Decrement the count of references
			--shape->referenceCount;
		}
		else
		{
			// Destroy the shape
			free(shape->area);
			free(shape->link);
			free(shape->elementPosition);
			free(shape);
		}
	}
}

/**
 * Create a blob object and insert it at the beginning of the chain of blobs.<br/>
 * Note: this function doesn't handle memory allocation failures.
 *
 * @param characteristics Pointer to the characteristics of the blob to be created.
 * @param shapeReference Reference of the shape that the blob shall used.
 * @param transformation Pointer to the transformation information.
 * @return Reference of the newly created blob, or NULL if the parameters aren't correct.
 */
BlobReference BlobObjectCreate(const BlobCharacteristics* characteristics, const BlobShapeReference shapeReference, const BlobTransformation* transformation)
{
	// Check whether the parameters are correct
	if(characteristics->type >= BLOB_TYPE_COUNT || !shapeReference || !transformation)
	{
		return(NULL);
	}

	// Create the blob object and insert it at the beginning of the chain of blobs
	Blob* blob = malloc(sizeof(Blob));
	blob->blobPrevious = NULL;
	blob->blobNext = blobFirst;
	if(blobFirst)
	{
		blobFirst->blobPrevious = blob;
	}
	else
	{
		blobLast = blob;
	}
	blobFirst = blob;

	// Set the shape of the blob
	BlobShape* shape = (BlobShape*)shapeReference;
	blob->shape = shape;
	++shape->referenceCount;

	// Check whether the pool of force vectors needs to be enlarged
	if(blobForcePoolSize < shape->elementCount)
	{
		free(blobForcePool);
		blobForcePoolSize = (shape->elementCount + BLOB_POOL_ROUND_MASK) & ~BLOB_POOL_ROUND_MASK;
		blobForcePool = malloc(blobForcePoolSize * sizeof(BlobVector));
	}

	// Initialize the element speed array
	blob->elementSpeed = malloc(shape->elementCount * sizeof(BlobVector));

	// Initialize the element position arrays
	// Note: this array actually has elementCount+1 elements (the last element is the center of mass of the blob)
	blob->elementPosition = malloc((shape->elementCount + 1) * sizeof(BlobElementPosition));

	// Translate the center of mass of the object
	BlobElementPosition* centerPositionObject = &blob->elementPosition[shape->elementCount];
	centerPositionObject->x = transformation->tX;
	centerPositionObject->y = transformation->tY;

	// Take note of the object's scaling (in case the texture needs to be repeated)
	if(characteristics->textureId < BLOB_TEXTURE_COUNT && characteristics->textureRepeat)
	{
		blob->scaleX = MathNorm(transformation->mA, transformation->mC) << (FIXED_POINT_SHIFT - BLOB_TEXTURE_REPEAT_SHIFT);
		blob->scaleY = -MathNorm(transformation->mB, transformation->mD) << (FIXED_POINT_SHIFT - BLOB_TEXTURE_REPEAT_SHIFT);
	}

	// Get the center of mass of the shape
	BlobVector* centerPositionShape = &shape->elementPosition[shape->elementCount];

	// Apply the transformation on all the other elements of the object and set the position of its bounding box
	blob->xMin = FIXED_INFINITY;
	blob->xMax = -FIXED_INFINITY;
	blob->yMin = FIXED_INFINITY;
	blob->yMax = -FIXED_INFINITY;

	unsigned char elementIndex = shape->elementCount;
	while(elementIndex--)
	{
		// Reset the speed of the element
		BlobVector* elementSpeed = &blob->elementSpeed[elementIndex];
		elementSpeed->x = 0;
		elementSpeed->y = 0;

		// Get pointers to the position of the element in the object and in the shape
		BlobElementPosition* elementPositionObject = &blob->elementPosition[elementIndex];
		BlobVector* elementPositionShape = &shape->elementPosition[elementIndex];

		// Compute the relative position of the element to the position of the center of mass
		signed long vX = elementPositionShape->x - centerPositionShape->x;
		signed long vY = elementPositionShape->y - centerPositionShape->y;

		// Apply the transformation
		elementPositionObject->x = centerPositionObject->x + ((transformation->mA * vX + transformation->mB * vY) >> (FIXED_POINT_SHIFT + FIXED_POINT_SHIFT));
		elementPositionObject->y = centerPositionObject->y + ((transformation->mC * vX + transformation->mD * vY) >> (FIXED_POINT_SHIFT + FIXED_POINT_SHIFT));

		// Set the position of the bounding box
		// Note: only take external elements into account
		if(elementIndex >= shape->elementFirstExternalIndex)
		{
			if(blob->xMin > elementPositionObject->x)
			{
				blob->xMin = elementPositionObject->x;
			}
			if(blob->xMax < elementPositionObject->x)
			{
				blob->xMax = elementPositionObject->x;
			}
			if(blob->yMin > elementPositionObject->y)
			{
				blob->yMin = elementPositionObject->y;
			}
			if(blob->yMax < elementPositionObject->y)
			{
				blob->yMax = elementPositionObject->y;
			}
		}
	}

	// Set the type of the blob
	blob->type = characteristics->type;
	if(blob->type != BLOB_TYPE_DYNAMIC)
	{
		// Static blobs are really heavy and do not need to define their stiffness, damping and pressure characteristics... but they have transformation information
		blob->mass = FIXED_INFINITY;
		blob->special.staticTransformation = characteristics->special.staticTransformation;
	}
	else
	{
		// Initialize the blob's mass, stiffness, damping and pressure
		blob->mass = characteristics->special.dynamic.mass;
		blob->special.dynamic.stiffness = characteristics->special.dynamic.stiffness;
		blob->special.dynamic.damping = characteristics->special.dynamic.damping;
		blob->special.dynamic.pressure = characteristics->special.dynamic.pressure;

		// Initialize the link length array
		blob->special.dynamic.linkLength = malloc(shape->linkCount * sizeof(signed long));
		unsigned char linkIndex = shape->linkCount;
		while(linkIndex--)
		{
			// Get a pointer to the link
			const BlobLink* link = &shape->link[linkIndex];

			// Get pointers to the position of the 2 elements involved in this link
			BlobElementPosition* element1Position = &blob->elementPosition[link->elementIndex1];
			BlobElementPosition* element2Position = &blob->elementPosition[link->elementIndex2];

			// Set the default length of the spring
			BlobVector deltaPosition;
			deltaPosition.x = element2Position->x - element1Position->x;
			deltaPosition.y = element2Position->y - element1Position->y;
			blob->special.dynamic.linkLength[linkIndex] = MathSqrt(deltaPosition.x * deltaPosition.x + deltaPosition.y * deltaPosition.y);
		}
	}

	// Initialize the blob's elasticity, making sure it is positive
	if(characteristics->elasticity < 0)
	{
		blob->elasticity = 0;
	}
	else
	{
		blob->elasticity = characteristics->elasticity;
	}

	// Initialize the blob's friction, making sure it is in the range [0,1]
	if(characteristics->friction < 0)
	{
		blob->friction = 0;
	}
	else if(characteristics->friction > FIXED_POINT)
	{
		blob->friction = FIXED_POINT;
	}
	else
	{
		blob->friction = characteristics->friction;
	}

	// Set the blob's texture, color, user defined identifier and collision mask
	blob->textureId = characteristics->textureId;
	blob->textureRepeat = characteristics->textureRepeat;
	blob->colorId = characteristics->colorId;
	blob->userId = characteristics->userId;
	blob->collisionMask = characteristics->collisionMask;

	// Return the reference of the newly created blob
	return((BlobReference)blob);
}

/**
 * Create a blob object and insert it at the beginning of the chain of blobs.<br/>
 * Note: this function doesn't handle memory allocation failures.
 *
 * @param characteristics Pointer to the characteristics of the blob to be created.
 * @param shapeReference Reference of the shape that the blob shall used.
 * @param x X coordinate of the blob's center point.
 * @param y Y coordinate of the blob's center point.
 * @param scaleX Scaling factor on the X axis.
 * @param scaleY Scaling factor on the Y axis.
 * @return Reference of the newly created blob, or NULL if the parameters aren't correct.
 */
BlobReference BlobObjectCreateEasy(const BlobCharacteristics* characteristics, const BlobShapeReference shapeReference, const signed long x, const signed long y, const signed long scaleX, const signed long scaleY)
{
	BlobTransformation transformation;
	transformation.tX = x;
	transformation.tY = y;
	transformation.mA = scaleX;
	transformation.mB = 0;
	transformation.mC = 0;
	transformation.mD = scaleY;
	return BlobObjectCreate(characteristics, shapeReference, &transformation);
}

/**
 * Destroy a blob object.
 *
 * @param blob Pointer to the blob to be destroyed.
 */
void BlobObjectDestroyBlob(Blob* blob)
{
	// Update the chain of blobs
	if(blob->blobPrevious)
	{
		blob->blobPrevious->blobNext = blob->blobNext;
	}
	else
	{
		blobFirst = blob->blobNext;
		if(!blobFirst)
		{
			// Free the memory allocated for the pool of force vectors
			free(blobForcePool);
			blobForcePoolSize = 0;
			blobForcePool = NULL;
		}
	}
	if(blob->blobNext)
	{
		blob->blobNext->blobPrevious = blob->blobPrevious;
	}
	else
	{
		blobLast = blob->blobPrevious;
	}

	// Free the memory allocated for the shape
	BlobShapeRelease(blob->shape);

	// Free the memory allocated for the blob
	if(blob->type == BLOB_TYPE_DYNAMIC)
	{
		free(blob->special.dynamic.linkLength);
	}
	free(blob->elementPosition);
	free(blob->elementSpeed);
	free(blob);
}

/**
 * Destroy a particular blob object or all the blobs of the chain.
 *
 * @param blobReference Reference of the blob to be destroyed, or NULL if all the blobs have to be destroyed at once.
 */
void BlobObjectDestroy(const BlobReference blobReference)
{
	// Check whether the reference is null or not
	if(blobReference)
	{
		// Destroy this particular blob
		BlobObjectDestroyBlob((Blob*)blobReference);
	}
	else
	{
		// Destroy all the blobs
		while(blobFirst)
		{
			BlobObjectDestroyBlob(blobFirst);
		}
	}
}

/**
 * Update all the forces applied on a blob.<br/>
 * Note: only do 1 step of the Euler integration.
 *
 * @param blob Pointer to the blob to be updated.
 * @param iteration Euler integration step number.
 */
static inline void BlobUpdateForce(Blob* blob, unsigned char iteration)
{
	// Get a pointer to the shape
	BlobShape* shape = blob->shape;

	// Check whether this blob is a static or dynamic blob
	if(blob->type != BLOB_TYPE_DYNAMIC)
	{
		// Get a pointer to the transformation information
		BlobTransformation* transformation = blob->special.staticTransformation;
		if(!transformation)
		{
			// Static blobs that aren't transformed (i.e. blobs that never move) don't have to be updated
			return;
		}

		// Get a pointer to the center of mass of the shape
		BlobVector* centerPositionShape = &shape->elementPosition[shape->elementCount];

		// Set the force and speed of all the elements
		unsigned char elementIndex = shape->elementCount;
		while(elementIndex--)
		{
			// Reset the force of the element
			BlobVector* elementForce = &blobForcePool[elementIndex];
			elementForce->x = 0;
			elementForce->y = 0;

			// Check whether the speed needs to be updated
			if(!iteration)
			{
				// Get pointers to the position of the element in the object and in the shape
				BlobElementPosition* elementPositionObject = &blob->elementPosition[elementIndex];
				BlobVector* elementPositionShape = &shape->elementPosition[elementIndex];

				// Compute the relative position of the element to the position of the center of mass
				signed long vX = elementPositionShape->x - centerPositionShape->x;
				signed long vY = elementPositionShape->y - centerPositionShape->y;

				// Set the speed of the element
				BlobVector* elementSpeed = &blob->elementSpeed[elementIndex];
				elementSpeed->x = transformation->tX + ((transformation->mA * vX + transformation->mB * vY) >> (FIXED_POINT_SHIFT + FIXED_POINT_SHIFT)) - elementPositionObject->x;
				elementSpeed->y = transformation->tY + ((transformation->mC * vX + transformation->mD * vY) >> (FIXED_POINT_SHIFT + FIXED_POINT_SHIFT)) - elementPositionObject->y;
			}
		}
	}
	else
	{
		// Compute the total area of the blob (well, "double" its area, but this will be simplified later on)
		signed long areaTotal = 0;
		unsigned char areaIndex = shape->areaCount;
		while(areaIndex--)
		{
			// Get a pointer to the area
			const BlobArea* area = &shape->area[areaIndex];

			// Get pointers to the position of the 3 elements involved in this triangle
			const BlobElementPosition* element1Position = &blob->elementPosition[area->elementIndex1];
			const BlobElementPosition* element2Position = &blob->elementPosition[area->elementIndex2];
			const BlobElementPosition* element3Position = &blob->elementPosition[area->elementIndex3];

			// Define the first vector
			BlobVector deltaPosition1;
			deltaPosition1.x = element2Position->x - element1Position->x;
			deltaPosition1.y = element2Position->y - element1Position->y;

			// Define the second vector
			BlobVector deltaPosition2;
			deltaPosition2.x = element3Position->x - element1Position->x;
			deltaPosition2.y = element3Position->y - element1Position->y;

			// Compute the area of the triangle (well, "double" its area, but this will be simplified later on)
			areaTotal += (deltaPosition1.x * deltaPosition2.y - deltaPosition1.y * deltaPosition2.x) >> FIXED_POINT_SHIFT;
		}

		// Compute the impact of the pressure (which depends on the total area of the blob)
		if(areaTotal <= 0)
		{
			// Oups! This shouldn't have happened!
			BlobObjectDestroyBlob(blob);
			return;
		}
		const signed long pressure = (blob->special.dynamic.pressure << FIXED_POINT_SHIFT) / areaTotal;

		// Initialize the force of every element: we first take the gravity into account
		BlobVector force;
		force.x = blob->mass * blobGravity.x;
		force.y = blob->mass * blobGravity.y;

		unsigned char elementIndex = shape->elementCount;
		while(elementIndex--)
		{
			BlobVector* elementForce = &blobForcePool[elementIndex];
			elementForce->x = force.x;
			elementForce->y = force.y;
		}

		// Update the forces according to the links between elements (stiffness and damping of the springs) as well as the pressure of the gaz inside the blob
		unsigned char linkIndex = shape->linkCount;
		while(linkIndex--)
		{
			// Get a pointer to the link
			const BlobLink* link = &shape->link[linkIndex];

			// Get pointers to the position of the 2 elements involved in this link
			BlobElementPosition* element1Position = &blob->elementPosition[link->elementIndex1];
			BlobElementPosition* element2Position = &blob->elementPosition[link->elementIndex2];

			// Compute the distance between the 2 elements
			BlobVector deltaPosition;
			deltaPosition.x = element2Position->x - element1Position->x;
			deltaPosition.y = element2Position->y - element1Position->y;
			signed long distance = MathSqrt(deltaPosition.x * deltaPosition.x + deltaPosition.y * deltaPosition.y);
			if(!distance)
			{
				// Oups! This shouldn't have happened!
				continue;
			}

			// Get pointers to the speed of the 2 elements involved in this link
			BlobVector* element1Speed = &blob->elementSpeed[link->elementIndex1];
			BlobVector* element2Speed = &blob->elementSpeed[link->elementIndex2];

			// Compute the difference of speed
			BlobVector deltaSpeed;
			deltaSpeed.x = element2Speed->x - element1Speed->x;
			deltaSpeed.y = element2Speed->y - element1Speed->y;

			// Compute the force of the spring (stiffness and damping)
			signed long temp = (deltaSpeed.x * deltaPosition.x + deltaSpeed.y * deltaPosition.y) / distance;
			temp = (temp * blob->special.dynamic.damping + (distance - blob->special.dynamic.linkLength[linkIndex]) * blob->special.dynamic.stiffness) / distance;

			force.x = temp * deltaPosition.x;
			force.y = temp * deltaPosition.y;

			// Get pointers to the force of the 2 elements involved in this link
			BlobVector* element1Force = &blobForcePool[link->elementIndex1];
			BlobVector* element2Force = &blobForcePool[link->elementIndex2];

			// Update the force of the 2 elements
			element1Force->x += force.x;
			element1Force->y += force.y;
			element2Force->x -= force.x;
			element2Force->y -= force.y;

			// If the link is an external link, then also compute the impact of the gaz (= pressure)
			if(link->elementIndex1 >= shape->elementFirstExternalIndex && link->elementIndex2 >= shape->elementFirstExternalIndex)
			{
				// Compute the force
				force.x = pressure * deltaPosition.y;
				force.y = pressure * deltaPosition.x;

				// Update the force of the 2 elements
				element1Force->x += force.x;
				element1Force->y -= force.y;
				element2Force->x += force.x;
				element2Force->y -= force.y;
			}
		}
	}

	// Update the speed and the position of all the elements, as well as the position of the bounding box of the blob
	blob->xMin = FIXED_INFINITY;
	blob->xMax = -FIXED_INFINITY;
	blob->yMin = FIXED_INFINITY;
	blob->yMax = -FIXED_INFINITY;

	BlobVector sumPosition;
	sumPosition.x = 0;
	sumPosition.y = 0;

	unsigned char elementIndex = shape->elementCount;
	while(elementIndex--)
	{
		// Get pointers to the force, speed and position of the element
		BlobVector* elementForce = &blobForcePool[elementIndex];
		BlobVector* elementSpeed = &blob->elementSpeed[elementIndex];
		BlobElementPosition* elementPosition = &blob->elementPosition[elementIndex];

		// Update the speed of the element
		elementSpeed->x += elementForce->x / (blob->mass << BLOB_EULER_SHIFT);
		elementSpeed->y += elementForce->y / (blob->mass << BLOB_EULER_SHIFT);

		// Update the position of the element
		elementPosition->x += elementSpeed->x >> BLOB_EULER_SHIFT;
		elementPosition->y += elementSpeed->y >> BLOB_EULER_SHIFT;

		// Update the position of the bounding box
		// Note: only take external elements into account
		if(elementIndex >= shape->elementFirstExternalIndex)
		{
			if(blob->xMin > elementPosition->x)
			{
				blob->xMin = elementPosition->x;
			}
			if(blob->xMax < elementPosition->x)
			{
				blob->xMax = elementPosition->x;
			}
			if(blob->yMin > elementPosition->y)
			{
				blob->yMin = elementPosition->y;
			}
			if(blob->yMax < elementPosition->y)
			{
				blob->yMax = elementPosition->y;
			}
			sumPosition.x += elementPosition->x;
			sumPosition.y += elementPosition->y;
		}
	}

	// Update the position of the blob's center of mass
	const signed long elementExternalCount = shape->elementCount - shape->elementFirstExternalIndex;
	BlobElementPosition* centerPosition = &blob->elementPosition[shape->elementCount];
	centerPosition->x = sumPosition.x / elementExternalCount;
	centerPosition->y = sumPosition.y / elementExternalCount;
}

/**
 * Check the constraints (collisions) between the external elements of a blob and the links of another blob.
 *
 * @param blob1 Pointer to the blob which the elements have to be checked.
 * @param blob2 Pointer to the blob which the links have to be taken into account.
 */
void BlobUpdateConstraintBlobBlob(const Blob* blob1, const Blob* blob2)
{
	// Get pointers to the shapes
	BlobShape* shape1 = blob1->shape;
	BlobShape* shape2 = blob2->shape;

	// Get a pointer to the position of the center of mass of the first blob
	BlobElementPosition* centerPosition = &blob1->elementPosition[shape1->elementCount];

	// Let's check each external element of the first blob
	for(unsigned char elementIndex = shape1->elementFirstExternalIndex; elementIndex < shape1->elementCount; ++elementIndex)
	{
		// Get a pointer to the position of the element
		BlobElementPosition* elementMPosition = &blob1->elementPosition[elementIndex];

		// Check whether this element is in the bounding box of the second blob
		if(elementMPosition->x >= blob2->xMin && elementMPosition->x <= blob2->xMax && elementMPosition->y >= blob2->yMin && elementMPosition->y <= blob2->yMax)
		{
			// Assume there is no collision (the element of the first blob isn't part of the second blob)
			unsigned char collideFlag = 0;
			signed long collideDistance = FIXED_INFINITY;
			BlobLink* collideLink = NULL;
			signed long collideNorm2;
			signed long collideCrossProduct;

			// Let's check each link of the second blob
			unsigned char linkIndex = shape2->linkCount;
			while(linkIndex--)
			{
				// Get a pointer to the link
				const BlobLink* link = &shape2->link[linkIndex];

				// Make sure that this link is external
				if(link->elementIndex1 < shape2->elementFirstExternalIndex || link->elementIndex2 < shape2->elementFirstExternalIndex)
				{
					continue;
				}

				// Get pointers to the position of the 2 elements involved in this link
				const BlobElementPosition* elementAPosition = &blob2->elementPosition[link->elementIndex1];
				const BlobElementPosition* elementBPosition = &blob2->elementPosition[link->elementIndex2];

				// Compute the 2 vectors "AB" and "AM"
				const signed long vABx = elementBPosition->x - elementAPosition->x;
				const signed long vABy = elementBPosition->y - elementAPosition->y;
				const signed long vAMx = elementMPosition->x - elementAPosition->x;
				const signed long vAMy = elementMPosition->y - elementAPosition->y;

				// Compute their cross product (which indicates on which side of AB the point M is located)
				const signed long crossProduct = vABx * vAMy - vABy * vAMx;
				if(crossProduct < 0)
				{
					// The point is on the right side of the line, so we won't check its distance; however, we update the collision status flag
					if(elementAPosition->y <= elementMPosition->y && elementMPosition->y < elementBPosition->y)
					{
						collideFlag = !collideFlag;
					}
					continue;
				}

				// The point is on the left side of the line; we first update the collision status flag
				if(elementBPosition->y <= elementMPosition->y && elementMPosition->y < elementAPosition->y)
				{
					collideFlag = !collideFlag;
				}

				// Make sure that the center of mass of the first blob is on the right side
				const signed long vAGx = centerPosition->x - elementAPosition->x;
				const signed long vAGy = centerPosition->y - elementAPosition->y;
				if(vABx * vAGy > vABy * vAGx)
				{
					continue;
				}

				// Compute the norm of AB
				const signed long norm2 = vABx * vABx + vABy * vABy;

				// Compute the dot product of the vectors (which allows computing the distance from the point A to the projection of the point M on the line AB)
				const signed long dotProduct = vABx * vAMx + vABy * vAMy;
				signed long distance;
				if(dotProduct < 0)
				{
					// Compute the distance from the point M to the point A
					distance = MathNormFast(vAMx, vAMy);
				}
				else if(dotProduct > norm2)
				{
					// Compute the distance from the point M to the point B
					distance = MathNormFast(elementMPosition->x - elementBPosition->x, elementMPosition->y - elementBPosition->y);
				}
				else
				{
					// Compute the distance from the point M to the line AB
					distance = crossProduct / MathSqrt(norm2);
				}

				// Check whether the distance is the lowest found so far
				if(distance < collideDistance)
				{
					// Record this link
					collideDistance = distance;
					collideLink = (BlobLink*)link;
					collideNorm2 = norm2;
					collideCrossProduct = crossProduct;
				}
			}

			// If this element of the first blob collides with the second blob, then compute the appropriate reaction
			if(collideFlag && collideLink)
			{
				// Get a pointer to the speed of the element
				BlobVector* elementMSpeed = &blob1->elementSpeed[elementIndex];

				// Get pointers to the speed and position of the 2 elements involved in the link
				BlobVector* collideElementASpeed = &blob2->elementSpeed[collideLink->elementIndex1];
				BlobVector* collideElementBSpeed = &blob2->elementSpeed[collideLink->elementIndex2];
				BlobElementPosition* collideElementAPosition = &blob2->elementPosition[collideLink->elementIndex1];
				BlobElementPosition* collideElementBPosition = &blob2->elementPosition[collideLink->elementIndex2];

				// Compute the difference of speed
				BlobVector deltaSpeed;
				deltaSpeed.x = elementMSpeed->x - ((collideElementASpeed->x + collideElementBSpeed->x) >> 1);
				deltaSpeed.y = elementMSpeed->y - ((collideElementASpeed->y + collideElementBSpeed->y) >> 1);

				// Compute the vector "AB"
				const signed long vABx = collideElementBPosition->x - collideElementAPosition->x;
				const signed long vABy = collideElementBPosition->y - collideElementAPosition->y;

				// Check whether the blobs are separating
				const signed long crossProduct = (vABx * deltaSpeed.y - vABy * deltaSpeed.x) >> FIXED_POINT_SHIFT;
				if(crossProduct < 0)
				{
					continue;
				}

				// Compute the denominator to be used in our future computations
				const signed long denominator = (collideNorm2 / blob1->mass) + (collideNorm2 / (blob2->mass << 1));
				if(!denominator)
				{
					continue;
				}

				// Compute the impact of the friction
				const signed long dotProduct = (vABx * deltaSpeed.x + vABy * deltaSpeed.y) >> FIXED_POINT_SHIFT;
				const signed long friction = (blob1->friction * blob2->friction) >> FIXED_POINT_SHIFT;
				signed long force = (friction * dotProduct) / denominator;
				deltaSpeed.x = force * vABx;
				deltaSpeed.y = force * vABy;

				// Compute the impulse
				const signed long elasticity = (blob1->elasticity * blob2->elasticity) >> FIXED_POINT_SHIFT;
				force = (crossProduct * (FIXED_POINT + elasticity)) / denominator;
				deltaSpeed.x -= force * vABy;
				deltaSpeed.y += force * vABx;

				// Apply the impulse and friction to the elements M, A and B
				elementMSpeed->x -= deltaSpeed.x / blob1->mass;
				elementMSpeed->y -= deltaSpeed.y / blob1->mass;
				deltaSpeed.x /= blob2->mass << 1;
				deltaSpeed.y /= blob2->mass << 1;
				collideElementASpeed->x += deltaSpeed.x;
				collideElementASpeed->y += deltaSpeed.y;
				collideElementBSpeed->x += deltaSpeed.x;
				collideElementBSpeed->y += deltaSpeed.y;

				// Compute the vector that can help moving the elements to solve the interpenetration
				force = collideCrossProduct / denominator;
				deltaSpeed.x = force * vABy;
				deltaSpeed.y = force * vABx;

				// Move the elements M, A and B
				elementMPosition->x += deltaSpeed.x / blob1->mass;
				elementMPosition->y -= deltaSpeed.y / blob1->mass;
				deltaSpeed.x /= blob2->mass << 1;
				deltaSpeed.y /= blob2->mass << 1;
				collideElementAPosition->x -= deltaSpeed.x;
				collideElementAPosition->y += deltaSpeed.y;
				collideElementBPosition->x -= deltaSpeed.x;
				collideElementBPosition->y += deltaSpeed.y;
			}
		}
	}
}

/**
 * Update the constraints (collisions) of all the blobs of the chain.
 */
static inline void BlobUpdateConstraintAll()
{
	Blob* blob1 = blobFirst;
	while(blob1)
	{
		Blob* blob2 = blob1->blobNext;
		while(blob2)
		{
			// Check whether one of the blobs (at least) is dynamic and they share a collision group
			if((blob1->type == BLOB_TYPE_DYNAMIC || blob2->type == BLOB_TYPE_DYNAMIC) && (blob1->collisionMask & blob2->collisionMask))
			{
				// Check whether the bounding boxes collide
				if(blob1->xMin <= blob2->xMax && blob1->xMax >= blob2->xMin && blob1->yMin <= blob2->yMax && blob1->yMax >= blob2->yMin)
				{
					// Check the constraints (collisions) between the external elements of the first blob and the links of the second
					BlobUpdateConstraintBlobBlob(blob1, blob2);

					// Check the constraints (collisions) between the external elements of the second blob and the links of the first
					BlobUpdateConstraintBlobBlob(blob2, blob1);
				}
			}

			// Next blob...
			blob2 = blob2->blobNext;
		}

		// Next blob...
		blob1 = blob1->blobNext;
	}
}

/**
 * Update the physics of all the blobs.
 *
 * @param x X coordinate of the gravity vector.
 * @param y Y coordinate of the gravity vector.
 */
void BlobUpdate(const signed long x, const signed long y)
{
	// Update the gravity vector
	blobGravity.x = x;
	blobGravity.y = y;

	// Update all the blobs (Euler integration)
	for(unsigned char iteration = 0; iteration < BLOB_EULER; ++iteration)
	{
		// Let the blobs move
		Blob* blob = blobFirst;
		while(blob)
		{
			// Update all the forces applied on the blob
			BlobUpdateForce(blob, iteration);

			// Next blob...
			blob = blob->blobNext;
		}

		// Update the constraints (collisions) of all the blobs of the chain
		BlobUpdateConstraintAll();
	}
}

/**
 * Display the background.
 */
static inline void BlobDisplayBackground()
{
	// Check whether there is a texture for the background
	if(blobBackground.textureId >= BLOB_TEXTURE_COUNT)
	{
		glClearColorx(blobBackground.colorId & 1 ? 0x10000 : 0x05555, blobBackground.colorId & 2 ? 0x10000 : 0x05555, blobBackground.colorId & 4 ? 0x10000 : 0x05555, 0x10000);
		glClear(GL_COLOR_BUFFER_BIT);
		return;
	}

	// Define the vertices
	glVertexPointer(2, GL_SHORT, 0, blobBackground.vertices);
	glEnableClientState(GL_VERTEX_ARRAY);

	// Enable the texture mapping
	GLshort static texCoord[] = {0, 0, FIXED_POINT, 0, 0, FIXED_POINT, FIXED_POINT, FIXED_POINT};
	glTexCoordPointer(2, GL_SHORT, 0, texCoord);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glBindTexture(GL_TEXTURE_2D, blobTextureName[blobBackground.textureId]);
	glEnable(GL_TEXTURE_2D);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	glMatrixMode(GL_TEXTURE);
	glLoadMatrixx(blobBackground.matrix);

	// Set the color blending
	glColor4x(blobBackground.colorId & 1 ? 0x10000 : 0x05555, blobBackground.colorId & 2 ? 0x10000 : 0x05555, blobBackground.colorId & 4 ? 0x10000 : 0x05555, 0x10000);

	// Display the background
	glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_BYTE, blobBackground.elements);

	// Clean-up
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
}

/**
 * Display a blob.
 *
 * @param blob Pointer to the blob to be displayed.
 */
static inline void BlobDisplayBlob(const Blob* blob)
{
	// Get a pointer to the shape
	BlobShape* shape = blob->shape;

	// Define the vertices
	glVertexPointer(2, GL_SHORT, 0, blob->elementPosition);
	glEnableClientState(GL_VERTEX_ARRAY);

	// Enable the texture mapping
	if(blob->textureId < BLOB_TEXTURE_COUNT)
	{
		glTexCoordPointer(2, GL_FIXED, 0, shape->elementPosition);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glBindTexture(GL_TEXTURE_2D, blobTextureName[blob->textureId]);
		glEnable(GL_TEXTURE_2D);
		glMatrixMode(GL_TEXTURE);
		if(blob->textureRepeat)
		{
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
			GLfixed matrix[] = {blob->scaleX, 0, 0, 0, 0, blob->scaleY, 0, 0, 0, 0, 0x10000, 0, 0, 0, 0, 0x10000};
			glLoadMatrixx(matrix);
		}
		else
		{
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
			GLfixed static matrix[] = {0x10000, 0, 0, 0, 0, -0x10000, 0, 0, 0, 0, 0x10000, 0, 0, 0x10000, 0, 0x10000};
			glLoadMatrixx(matrix);
		}
	}

	// Set the color blending
	glColor4x(blob->colorId & 1 ? 0x10000 : 0x05555, blob->colorId & 2 ? 0x10000 : 0x05555, blob->colorId & 4 ? 0x10000 : 0x05555, 0x10000);

	// Display the areas
	unsigned char areaIndex = shape->areaCount;
	while(areaIndex--)
	{
		glDrawElements(GL_TRIANGLE_STRIP, 3, GL_UNSIGNED_BYTE, &shape->area[areaIndex]);
	}

	// Disable the texture mapping
	if(blob->textureId < BLOB_TEXTURE_COUNT)
	{
		glDisable(GL_TEXTURE_2D);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	}

	// Display the border
	glEnable(GL_BLEND);
	glColor4ub(0, 0, 0, 95);
	glLineWidth(3.0f);
	glDrawArrays(GL_LINE_LOOP, shape->elementFirstExternalIndex, shape->elementCount - shape->elementFirstExternalIndex);
	glDisable(GL_BLEND);
	glColor4ub(0, 0, 0, 255);
	glLineWidth(1.0f);
	glDrawArrays(GL_LINE_LOOP, shape->elementFirstExternalIndex, shape->elementCount - shape->elementFirstExternalIndex);

	// Clean-up
	glDisableClientState(GL_VERTEX_ARRAY);
}

/**
 * Display the screen shutter.
 */
static inline void BlobDisplayShutter()
{
	// Check whether the screen shutter is fully opened
	if(!blobBackground.shutterLevel)
	{
		return;
	}

	// Define the vertices
	glVertexPointer(2, GL_SHORT, 0, blobBackground.vertices);
	glEnableClientState(GL_VERTEX_ARRAY);

	// Set the color blending
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glColor4x(0, 0, 0, blobBackground.shutterLevel << (16 - 4));

	// Display the shutter
	glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_BYTE, blobBackground.elements);

	// Clean-up
	glDisable(GL_BLEND);
	glDisableClientState(GL_VERTEX_ARRAY);
}

/**
 * Display all the blobs.
 */
void BlobDisplay()
{
	// Clean-up the screen (display the background)
	BlobDisplayBackground();

	// Display all the blobs
	Blob* blob = blobFirst;
	while(blob)
	{
		// Display this blob if it isn't hidden
		if(blob->type != BLOB_TYPE_STATIC_HIDDEN)
		{
			BlobDisplayBlob(blob);
		}

		// Next blob...
		blob = blob->blobNext;
	}

	// Display the screen shutter
	BlobDisplayShutter();
}

/**
 * Check whether a point is inside a blob.
 *
 * @param blob Pointer to the blob.
 * @param elementMPosition Pointer to the coordinates of the point.
 * @return Pointer to the blob if it is in contact with the point, NULL otherwise.
 */
const Blob* BlobTouchBlob(const Blob* blob, const BlobElementPosition* elementMPosition)
{
	// Check whether this element is in the bounding box of the second blob
	if(elementMPosition->x < blob->xMin || elementMPosition->x > blob->xMax || elementMPosition->y < blob->yMin || elementMPosition->y > blob->yMax)
	{
		return NULL;
	}

	// Let's check each link of the blob
	unsigned char collideFlag = 0;
	BlobShape* shape = blob->shape;
	unsigned char linkIndex = shape->linkCount;
	while(linkIndex--)
	{
		// Get a pointer to the link
		const BlobLink* link = &shape->link[linkIndex];

		// Make sure that this link is external
		if(link->elementIndex1 < shape->elementFirstExternalIndex || link->elementIndex2 < shape->elementFirstExternalIndex)
		{
			continue;
		}

		// Get pointers to the position of the 2 elements involved in this link
		const BlobElementPosition* elementAPosition = &blob->elementPosition[link->elementIndex1];
		const BlobElementPosition* elementBPosition = &blob->elementPosition[link->elementIndex2];

		// Compute the 2 vectors "AB" and "AM"
		const signed long vABx = elementBPosition->x - elementAPosition->x;
		const signed long vABy = elementBPosition->y - elementAPosition->y;
		const signed long vAMx = elementMPosition->x - elementAPosition->x;
		const signed long vAMy = elementMPosition->y - elementAPosition->y;

		// Compute their cross product (which indicates on which side of AB the point M is located)
		const signed long crossProduct = vABx * vAMy - vABy * vAMx;
		if(crossProduct < 0)
		{
			// The point is on the right side of the line
			if(elementAPosition->y <= elementMPosition->y && elementMPosition->y < elementBPosition->y)
			{
				collideFlag = !collideFlag;
			}
		}
		else
		{
			// The point is on the left side of the line; we first update the collision status flag
			if(elementBPosition->y <= elementMPosition->y && elementMPosition->y < elementAPosition->y)
			{
				collideFlag = !collideFlag;
			}
		}
	}
	if(collideFlag)
	{
		return blob;
	}
	return NULL;
}

/**
 * Check whether a point is inside a blob.
 *
 * @param x X coordinate of the point.
 * @param y Y coordinate of the point.
 * @return Reference of the blob in contact with the point, or NULL if the point doesn't touch any blob.
 */
BlobReference BlobTouch(const signed long x, const signed long y)
{
	// Take note of the point's position
	BlobElementPosition pointPosition;
	pointPosition.x = x;
	pointPosition.y = y;

	// Check all the blobs
	Blob* blob = blobLast;
	while(blob)
	{
		// Check this blob if it isn't hidden
		if(blob->type != BLOB_TYPE_STATIC_HIDDEN)
		{
			if(BlobTouchBlob(blob, &pointPosition))
			{
				return (BlobReference)blob;
			}
		}

		// Previous blob...
		blob = blob->blobPrevious;
	}
	return(NULL);
}

/**
 * Get the texture ID of a blob.
 *
 * @param blobReference Reference of the blob.
 * @return Identifier (index) of the texture.
 */
unsigned char BlobTextureIdGet(const BlobReference blobReference)
{
	if(!blobReference)
	{
		return(-1);
	}
	return(((Blob*)blobReference)->textureId);
}

/**
 * Get the color ID of a blob.
 *
 * @param blobReference Reference of the blob.
 * @return Identifier (index) of the color.
 */
unsigned char BlobColorIdGet(const BlobReference blobReference)
{
	if(!blobReference)
	{
		return(-1);
	}
	return(((Blob*)blobReference)->colorId);
}

/**
 * Set the color ID of a blob.
 *
 * @param blobReference Reference of the blob.
 * @param colorId Identifier (index) of the color.
 */
void BlobColorIdSet(const BlobReference blobReference, const unsigned char colorId)
{
	if(blobReference)
	{
		((Blob*)blobReference)->colorId = colorId;
	}
}

/**
 * Get the user ID of a blob.
 *
 * @param blobReference Reference of the blob.
 * @return User defined identifier.
 */
unsigned char BlobUserIdGet(const BlobReference blobReference)
{
	if(!blobReference)
	{
		return(-1);
	}
	return(((Blob*)blobReference)->userId);
}

/**
 * Set the pressure of the gaz inside a dynamic blob.
 *
 * @param blobReference Reference of the dynamic blob.
 * @param pressure Pressure of the gaz.
 */
void BlobPressureSet(const BlobReference blobReference, const signed long pressure)
{
	if(blobReference && ((Blob*)blobReference)->type == BLOB_TYPE_DYNAMIC)
	{
		((Blob*)blobReference)->special.dynamic.pressure = pressure;
	}
}

/**
 * Get the screen shutter level.
 *
 * @return Level of the screen shutter, from 0 (fully opened) to 16 (fully closed).
 */
unsigned char BlobShutterLevelGet()
{
	return(blobBackground.shutterLevel);
}

/**
 * Set the screen shutter level.
 *
 * @param shutterLevel Level of the screen shutter, from 0 (fully opened) to 16 (fully closed).
 */
void BlobShutterLevelSet(const unsigned char shutterLevel)
{
	blobBackground.shutterLevel = shutterLevel;
}

/**
 * Set the texture ID of the background.
 *
 * @param backgroundTextureId Identifier (index) of the background texture.
 */
void BlobBackgroundTextureIdSet(unsigned char const backgroundTextureId)
{
	blobBackground.textureId = backgroundTextureId;
}

/**
 * Set the color ID of the background.
 *
 * @param backgroundColorId Identifier (index) of the background color.
 */
void BlobBackgroundColorIdSet(unsigned char const backgroundColorId)
{
	blobBackground.colorId = backgroundColorId;
}
