/*
** God - Sources\Intro\Bump\Bump.h
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

#ifndef BUMP_H
#define BUMP_H

////////////////
// Inclusions //
////////////////
#include "..\..\Common\Common.h"

////////////
// Macros //
////////////
#define HEIGHT_SHIFT 6
#define HEIGHT       (1<<HEIGHT_SHIFT)

////////////////
// Prototypes //
////////////////
void BumpInit(const unsigned char* image);
void BumpDestroy(void);
void CODE_IN_IWRAM BumpDisplay(signed short x,signed short y);
unsigned short CODE_IN_IWRAM BumpTransition(const unsigned char* newImage);

#endif // BUMP_H
