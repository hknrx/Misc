/*
** Bomb Jack - Sources\Game\Game.h
** Nicolas ROBERT [NRX] - Hong Kong 2005 / France 2006
*/

#ifndef GAME_H
#define GAME_H

////////////////
// Inclusions //
////////////////
#include "GamePersistentData.h"

////////////////
// Prototypes //
////////////////
void GameInit(void);
void GameLevelInit(void);
void GameLevelNext(GamePlayer* player);
unsigned char GameMain(GamePlayer* player);
void GameDemoReplay(void);

#endif // GAME_H
