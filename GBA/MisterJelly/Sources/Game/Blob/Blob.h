/*
** Mister Jelly - Sources\Game\Blob\Blob.h
** Nicolas ROBERT [NRX] - France 2006
*/

#ifndef BLOB_H
#define BLOB_H

////////////////
// Inclusions //
////////////////
#include "..\..\Common\Common.h"

////////////
// Macros //
////////////
#define BLOB_EULER_SHIFT 1
#define BLOB_FRICTION    (signed long)(FIXED_POINT*0.20)

///////////
// Types //
///////////
typedef struct
{
   signed long x;
   signed long y;
}
BlobVector;

typedef struct
{
   BlobVector force;
   BlobVector speed;
   BlobVector position;
}
BlobElement;

typedef struct
{
   unsigned char element1;
   unsigned char element2;
   unsigned char flagExternal;
}
BlobLink;

typedef struct
{
   unsigned char element1;
   unsigned char element2;
   unsigned char element3;
}
BlobSurface;

typedef struct
{
   signed long stiffness;
   signed long damping;
   signed long length;
   signed long mass;
   signed long pression;

   unsigned char nbElements;
   BlobElement* element;

   unsigned char nbLinks;
   BlobLink* link;

   unsigned char nbSurfaces;
   BlobSurface* surface;
}
Blob;

////////////////
// Prototypes //
////////////////
Blob* BlobCreateSnail(signed long stiffness,signed long damping,signed long length,signed long mass,signed long pression,unsigned char nbElements,BlobVector* position);
Blob* BlobCreateBalloon(signed long stiffness,signed long damping,signed long length,signed long mass,signed long pression,unsigned char nbElements,BlobVector* position);
void BlobDestroy(Blob* blob);
void CODE_IN_IWRAM BlobMove(Blob* blob,BlobVector* gravity);
void BlobDisplay(Blob* blob,BlobVector* camPosition,unsigned char camAngle,unsigned char flagSmooth);

#endif // BLOB_H
