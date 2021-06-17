/*
** Bomb Jack - Sources\Game\GamePersistentData.h
** Nicolas ROBERT [NRX] - Hong Kong 2005 / France 2006
*/

#ifndef GAMEPERSISTENTDATA_H
#define GAMEPERSISTENTDATA_H

///////////
// Types //
///////////
typedef struct
{
   unsigned long score;
   unsigned char numLives;
   struct
   {
      signed short speed;
      unsigned char background;
      unsigned char layout;
   }
   level;
   struct
   {
      unsigned char id[9*9];
      unsigned char left;
      unsigned char sparkingNb;
      unsigned char bonusTrigger;
   }
   bombs;
}
GamePlayer;

typedef struct
{
   unsigned char keyMode; // Mode normal ou turbo...
   unsigned char numPlayers;
   unsigned char numDeadPlayers;
   unsigned char numCurrentPlayer;
   GamePlayer player[2];
}
GamePersistentData;

////////////////////////
// Variables globales //
////////////////////////
extern GamePersistentData gamePData;

#endif // GAMEPERSISTENTDATA_H
