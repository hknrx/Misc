/*
** Bomb Jack - Sources\Game\GameLevels.h
** Nicolas ROBERT [NRX] - Hong Kong 2005 / France 2006
*/

#ifndef GAMELEVELS_H
#define GAMELEVELS_H

////////////
// Macros //
////////////
#define LEVEL_BACKGROUNDS_NB 5
#define LEVEL_LAYOUTS_NB     12

#define PLAT(x,y,width)  {(x)+(y)*32,(width)}
#define WALL(x,y,height) {(x)+(y)*32,(height)|128}
#define BOMB(x,y)        ((x)+(y)*9)

//#define GAME_DEMO_RECORDING 1

///////////
// Types //
///////////
typedef struct
{
   unsigned char* tiles;
   unsigned short* map;
   unsigned char palette[16];
}
GameBackground;

typedef struct
{
   struct
   {
      unsigned char xPosition;
      unsigned char yPosition;
   }
   enemy[2];
   unsigned char elementNb;
   struct
   {
      unsigned short firstTile;
      unsigned char length;
   }
   element[];
}
GameEnemiesPlatformsLocations;

typedef unsigned char GameBombsLocations[24];

typedef struct
{
   const GameEnemiesPlatformsLocations* enemiesPlatformsLocations;
   const GameBombsLocations* bombsLocations;
}
GameLayout;

////////////////////////
// Variables globales //
////////////////////////

// Definition des differents fonds de jeu
extern const unsigned char GameBackground1_Tiles[];
extern const unsigned char GameBackground2_Tiles[];
extern const unsigned char GameBackground3_Tiles[];
extern const unsigned char GameBackground4_Tiles[];
extern const unsigned char GameBackground5_Tiles[];
extern const unsigned short GameBackground1_Map[];
extern const unsigned short GameBackground2_Map[];
extern const unsigned short GameBackground3_Map[];
extern const unsigned short GameBackground4_Map[];
extern const unsigned short GameBackground5_Map[];

const GameBackground gameBackground[LEVEL_BACKGROUNDS_NB]=
{
   {(unsigned char*)GameBackground1_Tiles,(unsigned short*)GameBackground1_Map,{0,2,3,15,16,25,26,26,26,26,24,6,0,13,0,0}},
   {(unsigned char*)GameBackground2_Tiles,(unsigned short*)GameBackground2_Map,{0,9,11,18,13,26,26,26,26,26,24,6,0,13,0,0}},
   {(unsigned char*)GameBackground3_Tiles,(unsigned short*)GameBackground3_Map,{12,1,9,10,11,3,26,26,26,26,24,6,0,13,0,0}},
   {(unsigned char*)GameBackground4_Tiles,(unsigned short*)GameBackground4_Map,{0,10,11,13,24,26,26,26,26,26,24,6,0,13,0,0}},
   {(unsigned char*)GameBackground5_Tiles,(unsigned short*)GameBackground5_Map,{0,1,9,12,24,25,26,26,26,26,24,6,0,13,0,0}}
};

// Definition des plateformes
const GameEnemiesPlatformsLocations gameEPLocations00={{{48,24},{72,24}},5,{PLAT(13,3,8),PLAT(5,6,5),PLAT(11,11,6),PLAT(3,14,5),PLAT(14,15,8)}};
const GameEnemiesPlatformsLocations gameEPLocations01={{{8,24},{32,24}},6,{PLAT(0,6,5),PLAT(20,6,5),PLAT(3,11,5),PLAT(17,11,5),PLAT(6,15,5),PLAT(14,15,5)}};
const GameEnemiesPlatformsLocations gameEPLocations02={{{68,16},{68,16}},5,{PLAT(6,4,5),PLAT(14,4,5),PLAT(10,13,5),PLAT(3,15,4),PLAT(18,15,4)}};
const GameEnemiesPlatformsLocations gameEPLocations03={{{44,16},{44,16}},4,{PLAT(3,4,5),PLAT(17,4,5),PLAT(3,15,5),PLAT(17,15,5)}};
const GameEnemiesPlatformsLocations gameEPLocations04={{{56,62},{56,62}},0,{}};
const GameEnemiesPlatformsLocations gameEPLocations05={{{16,24},{48,24}},5,{PLAT(11,4,4),PLAT(0,6,8),PLAT(17,9,5),PLAT(5,15,13),WALL(17,9,7)}};
const GameEnemiesPlatformsLocations gameEPLocations06={{{60,52},{60,52}},6,{PLAT(10,4,5),PLAT(5,8,5),PLAT(15,8,5),PLAT(5,12,5),PLAT(15,12,5),PLAT(10,15,5)}};
const GameEnemiesPlatformsLocations gameEPLocations07={{{32,32},{32,32}},8,{PLAT(3,7,6),PLAT(16,7,6),PLAT(3,12,6),PLAT(16,12,6),WALL(8,3,5),WALL(16,3,5),WALL(8,12,5),WALL(16,12,5)}};
const GameEnemiesPlatformsLocations gameEPLocations08={{{32,56},{80,56}},8,{PLAT(12,3,4),PLAT(12,6,5),PLAT(8,9,13),PLAT(12,12,5),PLAT(12,16,7),WALL(12,3,4),WALL(12,9,4),WALL(12,16,4)}};
const GameEnemiesPlatformsLocations gameEPLocations09={{{20,16},{20,16}},6,{PLAT(5,4,7),PLAT(17,4,3),PLAT(5,14,3),PLAT(15,14,5),WALL(5,4,11),WALL(19,4,11)}};
const GameEnemiesPlatformsLocations gameEPLocations10={{{24,24},{176,16}},6,{PLAT(19,4,6),PLAT(0,6,6),PLAT(19,8,6),PLAT(0,10,6),PLAT(19,13,6),PLAT(0,14,6)}};

// Definition des suites de bombes
const GameBombsLocations gameBLocations00={BOMB(4,2),BOMB(5,2),BOMB(6,2),BOMB(7,2),BOMB(8,3),BOMB(8,4),BOMB(8,5),BOMB(8,6),BOMB(0,3),BOMB(0,4),BOMB(0,5),BOMB(0,6),BOMB(1,0),BOMB(2,0),BOMB(3,0),BOMB(7,6),BOMB(6,6),BOMB(5,6),BOMB(3,8),BOMB(2,8),BOMB(1,8),BOMB(8,0),BOMB(7,0),BOMB(6,0)};
const GameBombsLocations gameBLocations01={BOMB(5,6),BOMB(6,6),BOMB(7,6),BOMB(5,4),BOMB(6,4),BOMB(7,4),BOMB(6,1),BOMB(7,1),BOMB(8,1),BOMB(5,2),BOMB(4,2),BOMB(3,2),BOMB(5,0),BOMB(4,0),BOMB(3,0),BOMB(0,1),BOMB(1,1),BOMB(2,1),BOMB(1,4),BOMB(2,4),BOMB(3,4),BOMB(1,6),BOMB(2,6),BOMB(3,6)};
const GameBombsLocations gameBLocations02={BOMB(3,5),BOMB(3,4),BOMB(3,3),BOMB(5,3),BOMB(5,4),BOMB(5,5),BOMB(6,6),BOMB(7,6),BOMB(8,6),BOMB(5,1),BOMB(6,1),BOMB(7,0),BOMB(8,0),BOMB(3,1),BOMB(2,1),BOMB(0,0),BOMB(0,1),BOMB(2,8),BOMB(3,8),BOMB(5,8),BOMB(6,8),BOMB(0,6),BOMB(1,6),BOMB(2,6)};
const GameBombsLocations gameBLocations03={BOMB(6,8),BOMB(7,8),BOMB(8,8),BOMB(6,6),BOMB(7,6),BOMB(8,6),BOMB(2,6),BOMB(1,6),BOMB(0,6),BOMB(6,4),BOMB(7,4),BOMB(8,4),BOMB(2,4),BOMB(1,4),BOMB(0,4),BOMB(5,1),BOMB(6,1),BOMB(7,1),BOMB(3,1),BOMB(2,1),BOMB(1,1),BOMB(0,8),BOMB(1,8),BOMB(2,8)};
const GameBombsLocations gameBLocations04={BOMB(3,5),BOMB(3,6),BOMB(3,7),BOMB(1,1),BOMB(1,2),BOMB(1,3),BOMB(1,5),BOMB(1,6),BOMB(1,7),BOMB(5,5),BOMB(5,6),BOMB(5,7),BOMB(3,1),BOMB(3,2),BOMB(3,3),BOMB(7,1),BOMB(7,2),BOMB(7,3),BOMB(7,5),BOMB(7,6),BOMB(7,7),BOMB(5,1),BOMB(5,2),BOMB(5,3)};
const GameBombsLocations gameBLocations05={BOMB(2,3),BOMB(1,3),BOMB(0,3),BOMB(0,4),BOMB(0,5),BOMB(0,6),BOMB(0,7),BOMB(8,7),BOMB(8,6),BOMB(8,5),BOMB(8,4),BOMB(8,3),BOMB(7,3),BOMB(6,3),BOMB(4,7),BOMB(3,7),BOMB(2,7),BOMB(1,7),BOMB(6,1),BOMB(5,1),BOMB(1,0),BOMB(0,0),BOMB(7,0),BOMB(8,0)};
const GameBombsLocations gameBLocations06={BOMB(5,4),BOMB(6,4),BOMB(7,4),BOMB(3,6),BOMB(3,7),BOMB(3,8),BOMB(3,4),BOMB(2,4),BOMB(1,4),BOMB(1,1),BOMB(2,1),BOMB(3,1),BOMB(5,1),BOMB(6,1),BOMB(7,1),BOMB(0,6),BOMB(0,7),BOMB(0,8),BOMB(8,6),BOMB(8,7),BOMB(8,8),BOMB(5,6),BOMB(5,7),BOMB(5,8)};
const GameBombsLocations gameBLocations07={BOMB(7,8),BOMB(7,7),BOMB(7,6),BOMB(8,4),BOMB(7,4),BOMB(6,4),BOMB(2,4),BOMB(1,4),BOMB(0,4),BOMB(1,8),BOMB(1,7),BOMB(1,6),BOMB(3,1),BOMB(3,2),BOMB(3,3),BOMB(1,0),BOMB(1,1),BOMB(1,2),BOMB(7,0),BOMB(7,1),BOMB(7,2),BOMB(5,1),BOMB(5,2),BOMB(5,3)};
const GameBombsLocations gameBLocations08={BOMB(2,3),BOMB(2,2),BOMB(2,1),BOMB(1,1),BOMB(1,2),BOMB(1,3),BOMB(1,6),BOMB(2,6),BOMB(3,6),BOMB(6,3),BOMB(7,3),BOMB(8,3),BOMB(8,6),BOMB(8,7),BOMB(8,8),BOMB(1,8),BOMB(2,8),BOMB(3,8),BOMB(7,8),BOMB(6,8),BOMB(5,8),BOMB(0,8),BOMB(0,7),BOMB(0,6)};
const GameBombsLocations gameBLocations09={BOMB(4,3),BOMB(8,6),BOMB(8,7),BOMB(8,8),BOMB(0,0),BOMB(0,1),BOMB(0,2),BOMB(6,0),BOMB(6,1),BOMB(6,2),BOMB(6,3),BOMB(6,4),BOMB(6,5),BOMB(2,2),BOMB(2,3),BOMB(2,4),BOMB(3,4),BOMB(3,5),BOMB(3,6),BOMB(8,0),BOMB(8,1),BOMB(8,2),BOMB(4,1),BOMB(4,2)};
const GameBombsLocations gameBLocations10={BOMB(7,6),BOMB(8,6),BOMB(8,7),BOMB(8,8),BOMB(2,8),BOMB(1,8),BOMB(0,8),BOMB(6,0),BOMB(7,0),BOMB(8,0),BOMB(7,3),BOMB(8,3),BOMB(8,2),BOMB(5,2),BOMB(4,2),BOMB(3,2),BOMB(0,0),BOMB(0,1),BOMB(0,2),BOMB(1,3),BOMB(1,4),BOMB(1,5),BOMB(7,4),BOMB(7,5)};

// Definition des niveaux
const GameLayout gameLayout[LEVEL_LAYOUTS_NB]=
{
   {&gameEPLocations00,&gameBLocations00},
   {&gameEPLocations01,&gameBLocations01},
   {&gameEPLocations02,&gameBLocations02},
   {&gameEPLocations03,&gameBLocations03},
   {&gameEPLocations04,&gameBLocations04},
   {&gameEPLocations05,&gameBLocations05},
   {&gameEPLocations06,&gameBLocations06},
   {&gameEPLocations07,&gameBLocations07},
   {&gameEPLocations08,&gameBLocations08},
   {&gameEPLocations04,&gameBLocations00},
   {&gameEPLocations09,&gameBLocations09},
   {&gameEPLocations10,&gameBLocations10}
};

// Definition des replays pour les demonstrations
#ifdef GAME_DEMO_RECORDING
unsigned char gameReplay[1024]={};
const unsigned char* gameDemonstration[]={gameReplay,gameReplay,gameReplay};
#else
const unsigned char gameReplay1[]=
{
   179,8,0,46,1,7,17,14,16,3,17,5,16,3,17,4,16,3,17,4,16,3,17,4,16,3,17,5,16,3,
   17,5,16,28,0,18,32,100,33,50,32,4,33,5,32,2,33,7,32,30,0,16,64,14,65,32,81,41,80,2,
   81,6,80,2,81,6,80,13,16,86,32,85,0,232,16,108,17,5,1,28,33,2,32,3,33,7,32,48,0,77,
   32,31,0,40,1,10,33,0,32,4,33,8,32,17,33,7,32,4,33,4,32,17,0,10,16,9,0,8,32,51,
   96,2,97,0,65,33,81,47,80,2,81,8,80,4,16,85,0,21,16,1,80,1,81,24,65,16,97,4,33,2,
   32,78,0,16,16,41,0,73,16,31,0,43,16,0,17,30,1,11,33,36,32,3,0,9,32,6,0,8,1,0
};
const unsigned char gameReplay2[]=
{
   99,22,0,56,32,65,33,33,17,6,16,1,17,8,16,80,0,3,32,104,0,8,16,5,17,24,16,2,17,7,
   16,26,17,4,16,3,17,5,16,81,0,2,32,67,33,7,17,25,16,4,17,8,16,29,32,15,33,5,1,18,
   17,1,16,3,17,8,16,13,17,5,16,3,17,5,16,0,32,2,33,5,32,3,33,3,32,4,33,4,32,3,
   33,4,32,4,33,3,32,4,33,5,32,3,33,5,32,3,33,5,32,4,33,4,32,3,33,5,32,4,33,6,
   32,2,33,1,17,6,16,41,0,14,64,4,65,27,97,13,96,0,32,1,33,5,32,2,33,6,32,3,33,6,
   32,3,33,1,17,5,16,2,17,6,1,0,0,15,17,7,16,26,0,31,32,0,33,25,32,4,33,8,32,42,
   16,28,0,17,16,24,0,40,64,2,65,8,97,20,33,8,32,3,33,6,32,1,33,7,32,34,0,2,1,8,
   17,0,16,2,17,8,16,13,17,7,16,1
};
const unsigned char gameReplay3[]=
{
   82,8,0,71,1,5,33,23,32,5,33,4,32,4,33,6,32,34,33,3,1,2,0,15,1,7,0,2,1,1,
   17,4,16,29,0,11,16,19,0,16,32,3,0,32,1,7,17,11,1,21,17,12,16,3,17,4,16,4,17,3,
   16,4,17,5,16,4,0,36,16,85,0,12,64,9,65,8,97,20,65,13,97,47,33,0,32,5,16,29,17,5,
   16,4,17,2,16,4,17,3,16,4,17,4,16,3,32,0,33,4,32,3,33,4,32,3,33,5,32,2,33,6,
   32,26,0,93,1,0,33,5,32,3,33,5,32,4,33,5,32,3,33,6,32,0,0,76,32,0,33,6,32,3,
   33,4,32,3,33,7,32,3,0,23,32,0,33,6,32,3,33,4,32,4,33,5,32,2,33,7,32,8,0,1,
   16,24,0,4,16,2,17,6,16,5,17,6,16,2,17,4,16,125,0,7,32,15,0,25,16,6,17,0,1,11,
   33,2,32,4,33,8,32,10,0,27,16,1,17,12,1,22,33,29,32,4,0,131,32,40,0,17,32,34,0,43,
   16,13,0,28,16,8,0,10,16,6,0,10,16,9,0,10,16,9,0,11,16,6,0,58,16,15
};
const unsigned char* gameDemonstration[]={gameReplay1,gameReplay2,gameReplay3};
#endif // GAME_DEMO_RECORDING

#endif // GAMELEVELS_H
