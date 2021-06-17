#ifndef BLOB_H
#define BLOB_H

/*
 * Libraries.
 */
#include <CoreGraphics/CGImage.h>
#include <OpenGLES/ES1/glext.h>

/*
 * Macros.
 */
/**
 * Number of steps of the Euler integration, in power of 2 (i.e. the value "N" actually means "2^N" steps).<br/>
 * IMPORTANT NOTE: the number of steps of the Euler integration must be as low as possible to increase performances, but high enough to prevent computation overflows (this depends on the characteristics of the blobs).
 */
#define BLOB_EULER_SHIFT 3

/**
 * Size of a texture when it isn't scaled but mapped repeatedly over the shape, in power of 2 (i.e. the value "N" actually means "2^N" units).
 */
#define BLOB_TEXTURE_REPEAT_SHIFT 5

/*
 * Types.
 */
/**
 * Different types of blobs.
 */
typedef enum
{
	BLOB_TYPE_STATIC_HIDDEN = 0,
	BLOB_TYPE_STATIC_VISIBLE,
	BLOB_TYPE_DYNAMIC,
	BLOB_TYPE_COUNT,
}
BlobType;

/**
 * Reference of a blob shape (pointer to the blob shape's structure).
 */
typedef void* BlobShapeReference;

/**
 * Blob object's transformation information:
 * <ul>
 * <li>tX X component of the translation vector;</li>
 * <li>tY Y component of the translation vector;</li>
 * <li>mA Element [0,0] of the linear transformation matrix;</li>
 * <li>mB Element [0,1] of the linear transformation matrix;</li>
 * <li>mC Element [1,0] of the linear transformation matrix;</li>
 * <li>mD Element [1,1] of the linear transformation matrix.</li>
 * </ul>
 */
typedef struct
{
	signed long tX;
	signed long tY;
	signed long mA;
	signed long mB;
	signed long mC;
	signed long mD;
}
BlobTransformation;

/**
 * Blob object's characteristics:
 * <ul>
 * <li>type Type of the blob;</li>
 * <li>textureId Identifier (index) of the texture;</li>
 * <li>textureRepeat Flag that indicates whether the texture shall be repeated (YES) or scaled (NO);</li>
 * <li>colorId Identifier (index) of the color;</li>
 * <li>elasticity Elasticity of the blob;</li>
 * <li>friction Friction of the blob;</li>
 * <li>special Special characteristics of the blob (i.e. characteristics that depend on the type of the blob):</li>
 * <ul>
 * <li>staticTransformation Pointer to the transformation information of a static blob;</li>
 * <li>mass Mass of each element that compose a dynamic blob;</li>
 * <li>stiffness Stiffness of the springs that compose a dynamic blob;</li>
 * <li>damping Damping of the springs that compose a dynamic blob;</li>
 * <li>pressure Pressure of the gaz inside a dynamic blob.</li>
 * </ul>
 * <li>collisionMask Collision mask of the blob (1 bit per group);</li>
 * <li>timer Timer.</li>
 * </ul>
 */
typedef struct
{
	BlobType type;
	unsigned char textureId;
	unsigned char textureRepeat;
	unsigned char colorId;
	signed long elasticity;
	signed long friction;

	union
	{
		BlobTransformation* staticTransformation;
		struct
		{
			signed long mass;
			signed long stiffness;
			signed long damping;
			signed long pressure;
		}
		dynamic;
	}
	special;

	unsigned char collisionMask;
	unsigned short timer;
}
BlobCharacteristics;

/**
 * Reference of a blob object (pointer to the blob object's structure).
 */
typedef void* BlobReference;

/*
 * Prototypes.
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
void BlobInitialize(GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, unsigned char const shutterLevel);

/**
 * Finalize the blob engine.
 */
void BlobFinalize();

/**
 * Load a texture.
 *
 * @param textureImage Image to be loaded.
 * @param textureId Texture identifier (index).
 * @param textureSize Size of the texture (width / height).
 * @param text Text to be displayed on the texture.
 */
void BlobLoadTexture(CGImageRef const textureImage, GLuint const textureId, GLuint textureSize, char const*const text);

/**
 * Create a "box" shape.<br/>
 * Note: this function doesn't handle memory allocation failures.
 *
 * @return Reference of the newly created shape, or NULL if it couldn't be created.
 */
BlobShapeReference BlobShapeCreateBox();

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
BlobShapeReference BlobShapeCreateSnail(const unsigned char elementCount);

/**
 * Create a "balloon" shape.<br/>
 * Note: this function doesn't handle memory allocation failures.
 *
 * @param elementCount Number of elements that compose the shape (excluding its center of mass).
 * @return Reference of the newly created shape, or NULL if the number of elements is too low.
 */
BlobShapeReference BlobShapeCreateBalloon(const unsigned char elementCount);

/**
 * Release a shape and destroy it if its count of references reaches 0.
 */
void BlobShapeRelease(const BlobShapeReference shapeReference);

/**
 * Create a blob object and insert it at the beginning of the chain of blobs.<br/>
 * Note: this function doesn't handle memory allocation failures.
 *
 * @param characteristics Pointer to the characteristics of the blob to be created.
 * @param shapeReference Reference of the shape that the blob shall used.
 * @param transformation Pointer to the transformation information.
 * @return Reference of the newly created blob, or NULL if the parameters aren't correct.
 */
BlobReference BlobObjectCreate(const BlobCharacteristics* characteristics, const BlobShapeReference shapeReference, const BlobTransformation* transformation);

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
BlobReference BlobObjectCreateEasy(const BlobCharacteristics* characteristics, const BlobShapeReference shapeReference, const signed long x, const signed long y, const signed long scaleX, const signed long scaleY);

/**
 * Destroy a particular blob object or all the blobs of the chain.
 *
 * @param blobReference Reference of the blob to be destroyed, or NULL if all the blobs have to be destroyed at once.
 */
void BlobObjectDestroy(const BlobReference blobReference);

/**
 * Update the physics of all the blobs.
 *
 * @param x X coordinate of the gravity vector.
 * @param y Y coordinate of the gravity vector.
 */
void BlobUpdate(const signed long x, const signed long y);

/**
 * Display all the blobs.
 */
void BlobDisplay();

/**
 * Check whether a point is inside a blob.
 *
 * @param x X coordinate of the point.
 * @param y Y coordinate of the point.
 * @return Reference of the blob in contact with the point, or NULL if the point doesn't touch any blob.
 */
BlobReference BlobTouch(const signed long x, const signed long y);

/**
 * Get the texture ID of a blob.
 *
 * @param blobReference Reference of the blob.
 * @return Identifier (index) of the texture.
 */
unsigned char BlobTextureIdGet(const BlobReference blobReference);

/**
 * Set the texture ID of a blob.
 *
 * @param blobReference Reference of the blob.
 * @param textureId Identifier (index) of the texture.
 */
void BlobTextureIdSet(const BlobReference blobReference, unsigned char const textureId);

/**
 * Get the color ID of a blob.
 *
 * @param blobReference Reference of the blob.
 * @return Identifier (index) of the color.
 */
unsigned char BlobColorIdGet(const BlobReference blobReference);

/**
 * Set the color ID of a blob.
 *
 * @param blobReference Reference of the blob.
 * @param colorId Identifier (index) of the color.
 */
void BlobColorIdSet(const BlobReference blobReference, const unsigned char colorId);

/**
 * Set the pressure of the gaz inside a dynamic blob.
 *
 * @param blobReference Reference of the dynamic blob.
 * @param pressure Pressure of the gaz.
 */
void BlobPressureSet(const BlobReference blobReference, const signed long pressure);

/**
 * Get the screen shutter level.
 *
 * @return Level of the screen shutter, from 0 (fully opened) to 16 (fully closed).
 */
unsigned char BlobShutterLevelGet();

/**
 * Set the screen shutter level.
 *
 * @param shutterLevel Level of the screen shutter, from 0 (fully opened) to 16 (fully closed).
 */
void BlobShutterLevelSet(const unsigned char shutterLevel);

/**
 * Set the texture ID of the background.
 *
 * @param backgroundTextureId Identifier (index) of the background texture.
 */
void BlobBackgroundTextureIdSet(unsigned char const backgroundTextureId);

/**
 * Set the color ID of the background.
 *
 * @param backgroundColorId Identifier (index) of the background color.
 */
void BlobBackgroundColorIdSet(unsigned char const backgroundColorId);

#endif // BLOB_H
