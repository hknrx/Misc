/*
** Mario Balls - Sources\Bump\Bump.h
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

#ifndef BUMP_H
#define BUMP_H

////////////////
// Inclusions //
////////////////
#include "..\Commun\Commun.h"

////////////
// Macros //
////////////
#define HAUTEUR_ 6
#define HAUTEUR  (1<<HAUTEUR_)

#define TEMPO_FADE 2
#define TEMPO_BUMP 100
#define BUMP_MOVE  6

////////////////
// Prototypes //
////////////////
void CODE_IN_IWRAM BumpSequence(void);

#endif // BUMP_H
