/*
** God - Sources\World\3dIso\3dIso.h
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

#ifndef THREEDISO_H
#define THREEDISO_H

////////////////
// Inclusions //
////////////////
#include "..\..\Common\Common.h"

////////////
// Macros //
////////////
#define RX_MIN    (SINNB/8)
#define RX_MAX    (SINNB/4)
#define ZOOM_MIN  (FIXED_POINT*SQRT2/4)
#define ZOOM_LOW  (FIXED_POINT*SQRT2/2)
#define ZOOM_HIGH (1.2*FIXED_POINT)
#define ZOOM_MAX  (3.0*FIXED_POINT)

#define WALL_WIDTH_SHIFT  4
#define WALL_WIDTH        (1<<WALL_WIDTH_SHIFT)
#define WALL_HEIGHT_SHIFT 4
#define WALL_HEIGHT       (1<<WALL_HEIGHT_SHIFT)

#define XM XM4
#define YM YM4
#define XO (XM/2)
#define YO (YM/2)

////////////////
// Prototypes //
////////////////
void IsoInit(unsigned char (*mapIsGround)(signed short),unsigned char (*mapIsWall)(signed short),
             unsigned short mapWidthShift,unsigned short mapHeightShift);
void IsoDestroy(void);

inline void IsoMenuClean(unsigned char ymin,unsigned char ymax);
inline void IsoMenuChangeBg(unsigned char tile);
void IsoMenuWriteString(unsigned char x,unsigned char y,const unsigned char* string);
void IsoMenuWriteNumber(unsigned char xmin,unsigned char xmax,unsigned char y,unsigned short number);

void IsoMapSet(void);
void IsoMapModify(signed short mapIdx);

void IsoSplitSet(unsigned short timer,signed short value);
signed short IsoSplitGetValue(void);

signed short CODE_IN_IWRAM IsoDisplay(signed long x,signed long z,unsigned char Rx,unsigned char Ry,signed long zoom,
                                      signed short xPointer,signed short yPointer,signed short pointer);

#endif // THREEDISO_H
