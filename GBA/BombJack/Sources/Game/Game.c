/*
** Bomb Jack - Sources\Game\Game.c
** Nicolas ROBERT [NRX] - Hong Kong 2005 / France 2006
*/

////////////////
// Inclusions //
////////////////
#include "..\Common\Common.h"
#include "GameLevels.h"
#include "GamePersistentData.h"

////////////
// Macros //
////////////
#define TIMER_NOTIFICATION_DISAPPEAR 120
#define TIMER_ENEMY_A_APPEAR         240
#define TIMER_ENEMY_A_TRANSFORM      30
#define TIMER_ENEMY_E_CHANGE_DIR     120
#define TIMER_BONUS_APPEAR           900
#define TIMER_BONUS_WARNING          240
#define TIMER_BONUS_DISAPPEAR        360
#define TIMER_GAME_START             120
#define TIMER_GAME_OVER              240

#define POINTS_JUMP          10
#define POINTS_BOMB_NORMAL   100
#define POINTS_BOMB_SPARKING 200
#define POINTS_ENEMY         100
#define POINTS_BONUS_1       2000
#define POINTS_BONUS_2       3000
#define POINTS_BONUS_3       1000

#define JACK_INIT_LIVES 3
#define JACK_INIT_X     100
#define JACK_INIT_Y     64

#define ENEMY_A_CHANGE_DIR 3

#define ACCELERATION_FALL (FIXED_POINT*3/64)

#define SPEED_JACK_JUMP_TURBO  (-FIXED_POINT*117/32)
#define SPEED_JACK_JUMP_NORMAL (-FIXED_POINT*95/32)
#define SPEED_JACK_JUMP_DEAD   (-FIXED_POINT*5/4)
#define SPEED_JACK_FALL_QUICK  (FIXED_POINT*3/4)
#define SPEED_ENEMY_INIT       (signed short)(FIXED_POINT*0.1)
#define SPEED_ENEMY_INCREMENT  (signed short)(FIXED_POINT*0.025)
#define SPEED_BONUS            (signed short)(FIXED_POINT*0.4)

#define WALL_WIDTH      6
#define PLATFORM_HEIGHT 6

#define SPRITE_JACK    0
#define SPRITE_ENEMY_A 0
#define SPRITE_ENEMY_B 1
#define SPRITE_ENEMY_C 2
#define SPRITE_ENEMY_D 3
#define SPRITE_ENEMY_E 3
#define SPRITE_SMILEY  2
#define SPRITE_BONUS   1

///////////
// Types //
///////////
typedef struct
{
   signed char xOffset;
   signed char yOffset;
   unsigned char width;
   unsigned char height;
}
GameSpriteInfo;

typedef struct
{
   signed short xPosition;
   signed short yPosition;
   signed short xDelta;
   signed short yDelta;
}
GameMoveInfo;

typedef struct
{
   enum {INIT_A,HIDE_A,APPEAR_A,MANAGE_A,TRANSFORM_A,MANAGE_B,MANAGE_C,MANAGE_D,INIT_E,MANAGE_E} state;
   unsigned short memory;
   GameMoveInfo move;
}
GameEnemy;

typedef struct
{
   struct
   {
      enum {ALIVE,TOUCHED,DYING,DEAD} state;
      GameMoveInfo move;
   }
   jack;
   unsigned char sparkingId;
   GameEnemy enemy[5];
   struct
   {
      enum {INIT,HIDE,MANAGE_1,MANAGE_2,MANAGE_3,TOUCHED_1} state;
      unsigned short memory;
      GameMoveInfo move;
      unsigned char multiply;
      unsigned char numKills;
   }
   bonus;
}
GameTemporaryData;

typedef struct
{
   unsigned char xToLocation[200-12+1];
   unsigned char yToLocation[160-16+1];
   unsigned char locationToX[9*9];
   unsigned char locationToY[9*9];
}
GameConvert;

typedef struct
{
   unsigned char push;
   unsigned char pop;
   unsigned char count;
   struct
   {
      unsigned char id;
      unsigned char timer;
   }
   bombs[8];
}
GameNotify;

////////////////////////
// Variables globales //
////////////////////////

// Definition des informations relatives aux sprites
const GameSpriteInfo gameSpriteInfo[]=
{
   {-6,-8,12,16}, // SPRITE_JACK & SPRITE_ENEMY_A
   {-7,-7,14,13}, // SPRITE_ENEMY_B & SPRITE_BONUS
   {-7,-8,14,16}, // SPRITE_ENEMY_C & SPRITE_SMILEY
   {-7,-5,14,9}   // SPRITE_ENEMY_D & SPRITE_ENEMY_E
};

// Declaration des structures de jeu
GamePersistentData gamePData;
GameTemporaryData gameTData;
GameConvert gameConvert;
GameNotify gameNotify;

// Definition du "masque" pour les pixels (lecture 32 bits en VRAM => 8 pixels en mode 16 couleurs)
const unsigned long gameMaskPixels[8]={15,15<<4,15<<8,15<<12,15<<16,15<<20,15<<24,15<<28};

// Petite chaine de caractere pour le message de debut de jeu
unsigned char gameStringPlayer[]="PLAYER x";

// Definition des sequences de couleurs
const unsigned char gameInksEnemies[]={7,6,3,0,3,6};
const unsigned char gameInksBonusNormal[]={24,25,26,15};
const unsigned char gameInksBonusEnd[]={0,24,24,0};
const unsigned char gameInksScore[]={26,15,24,25};

CommonCpcColorSequences gameColorSequences=
{
   2,
   {
      {14,gameInksEnemies,sizeof(gameInksEnemies),3},
      {15,gameInksScore,sizeof(gameInksScore),3}
   }
};

// Cheat code
const unsigned short gameCheatCode[]={KEY_UP,KEY_UP,KEY_DOWN,KEY_DOWN,KEY_A,KEY_B,KEY_A,KEY_B};

//////////////
// GameInit //
//////////////
void GameInit(void)
{
   unsigned short* screen;
   unsigned short tile;
   unsigned char x,y;
   unsigned char value,trigger;

   // Creation de la tile de nettoyage du fond de jeu (background 0)
   CommonDmaForce(-1,(void*)CHAR_BASE_BLOCK(0)+511*32,32/4,DMA_32NOW); // Encre #15, tile #511

   // Reglage de la luminosite du fond de jeu (alpha blending sur le background 0)
   REG_BLD_FAD=6;
   REG_BLDMOD=BLEND_BG0|BLEND_BLACK;

   // Nettoyage du foreground (background 1)
   CommonDmaForce(287,(void*)SCREEN_BASE_BLOCK(29),32*20,DMA_16NOW);

   // Mise en place des accolades
   screen=(unsigned short*)SCREEN_BASE_BLOCK(29)+25+(32*0);
   for(tile=263;tile<=267;++tile)
   {
      *(screen+32*5)=tile|(1<<11); // Vertical flip...
      *screen++=tile;
   }

   // Mise en place de la chaine "Player"
   screen=(unsigned short*)SCREEN_BASE_BLOCK(29)+25+(32*1);
   for(tile=268;tile<=271;++tile)
      *screen++=tile;

   // Mise en place du logo "Bomb Jack"
   screen=(unsigned short*)SCREEN_BASE_BLOCK(29)+25+(32*7);
   tile=0;
   for(y=0;y<4;++y)
   {
      for(x=0;x<5;++x)
      {
         *(screen+32*4)=tile+5;
         *(screen+32*8)=tile+10;
         *screen++=tile++;
      }
      screen+=32-5;
      tile+=32-5;
   }

   // Creation des tableaux de conversion (position de BJ <=> position des bombes)
   value=0;
   trigger=5-3;
   for(x=0;x<200-12+1;++x)
   {
      ++trigger;
      if(trigger<=17)
         gameConvert.xToLocation[x]=value; // (x+5)/(3+17+2)
      else
      {
         gameConvert.xToLocation[x]=0xFF;
         if(trigger==22)
         {
            trigger=0;
            ++value;
         }
      }
   }

   value=0;
   trigger=9;
   for(y=0;y<160-16+1;++y)
   {
      gameConvert.yToLocation[y]=value; // ((y+9)/18)*9
      if(++trigger==18)
      {
         trigger=0;
         value+=9;
      }
   }

   value=4;
   for(x=0;x<9;++x)
   {
      for(y=0;y<9*9;y+=9)
         gameConvert.locationToX[x+y]=value; // 4+(location%9)*22
      value+=22;
   }

   value=0;
   for(y=0;y<9*9;y+=9)
   {
      for(x=0;x<9;++x)
         gameConvert.locationToY[x+y]=value; // (location/9)*18
      value+=18;
   }

   // Correction des tiles pour que les plateformes et murs semblent "plats" (OBJ_TILES uniquement)
   ((unsigned long*)OBJ_TILES)[(222<<3)+1]=(0<<0)|(1<<4)|(1<<8)|(1<<12)|(1<<16)|(1<<20)|(1<<24)|(1<<28);
   ((unsigned long*)OBJ_TILES)[(222<<3)+2]=(0<<0)|(1<<4)|(1<<8)|(1<<12)|(1<<16)|(1<<20)|(1<<24)|(1<<28);
   ((unsigned long*)OBJ_TILES)[(223<<3)+1]=(1<<0)|(1<<4)|(1<<8)|(1<<12)|(1<<16)|(1<<20)|(1<<24)|(0<<28);
   ((unsigned long*)OBJ_TILES)[(223<<3)+2]=(1<<0)|(1<<4)|(1<<8)|(1<<12)|(1<<16)|(1<<20)|(1<<24)|(0<<28);
   ((unsigned long*)OBJ_TILES)[(254<<3)+5]=(0<<0)|(1<<4)|(1<<8)|(1<<12)|(1<<16)|(1<<20)|(1<<24)|(1<<28);
   ((unsigned long*)OBJ_TILES)[(254<<3)+6]=(0<<0)|(1<<4)|(1<<8)|(1<<12)|(1<<16)|(1<<20)|(1<<24)|(1<<28);
   ((unsigned long*)OBJ_TILES)[(255<<3)+5]=(1<<0)|(1<<4)|(1<<8)|(1<<12)|(1<<16)|(1<<20)|(1<<24)|(0<<28);
   ((unsigned long*)OBJ_TILES)[(255<<3)+6]=(1<<0)|(1<<4)|(1<<8)|(1<<12)|(1<<16)|(1<<20)|(1<<24)|(0<<28);
   ((unsigned long*)OBJ_TILES)[(256<<3)+1]=(0<<0)|(1<<4)|(1<<8)|(1<<12)|(1<<16)|(1<<20)|(1<<24)|(1<<28);
   ((unsigned long*)OBJ_TILES)[(256<<3)+6]=(0<<0)|(1<<4)|(1<<8)|(1<<12)|(1<<16)|(1<<20)|(1<<24)|(1<<28);
   ((unsigned long*)OBJ_TILES)[(258<<3)+1]=(1<<0)|(1<<4)|(1<<8)|(1<<12)|(1<<16)|(1<<20)|(1<<24)|(0<<28);
   ((unsigned long*)OBJ_TILES)[(258<<3)+6]=(1<<0)|(1<<4)|(1<<8)|(1<<12)|(1<<16)|(1<<20)|(1<<24)|(0<<28);
   ((unsigned long*)OBJ_TILES)[(260<<3)+0]=(0<<0)|(1<<4)|(1<<8)|(1<<12)|(1<<16)|(1<<20)|(1<<24)|(0<<28);
   ((unsigned long*)OBJ_TILES)[(262<<3)+7]=(0<<0)|(1<<4)|(1<<8)|(1<<12)|(1<<16)|(1<<20)|(1<<24)|(0<<28);
}

/////////////////////
// GameUpdateLives //
/////////////////////
static void GameUpdateLives(unsigned char numLives)
{
   unsigned short* screen;

   // Affichage du nombre de vies du joueur
   screen=(unsigned short*)SCREEN_BASE_BLOCK(29)+30+(32*2);
   if(numLives>1)
   {
      *--screen=203;
      *(screen+32*1)=235;
      while(--numLives)
      {
         *--screen=202;
         *(screen+32*1)=234;
      }
   }
   while(screen>(unsigned short*)SCREEN_BASE_BLOCK(29)+25+(32*2))
   {
      *--screen=287;
      *(screen+32*1)=287;
   }
}

/////////////////////
// GameUpdateScore //
/////////////////////
static void GameUpdateScore(GamePlayer* player,unsigned long score)
{
   unsigned char pointer;
   unsigned short x;
   unsigned char digit;

   // Mise a jour du score
   score=player->score+(score*gameTData.bonus.multiply);
   player->score=score;

   // Affichage du score
   pointer=128;
   x=233;
   do
   {
      // Extraction du chiffre des unites
      digit=score%10;

      // Positionnement du sprite correspondant
      --pointer;
      commonSprites[pointer].attribute0=32;
      commonSprites[pointer].attribute1=x;
      commonSprites[pointer].attribute2=digit+274;

      // Chiffre suivant...
      score=(score-digit)/10;
      x-=6;
   }
   while(score && pointer>122);
}

///////////////////
// GameLevelInit //
///////////////////
void GameLevelInit(void)
{
   unsigned char numPlayer;
   GamePlayer* player;

   gamePData.numDeadPlayers=0;
   for(numPlayer=0;numPlayer<gamePData.numPlayers;++numPlayer)
   {
      player=&gamePData.player[numPlayer];

      player->score=0;
      player->numLives=JACK_INIT_LIVES;
      player->level.speed=SPEED_ENEMY_INIT;
      player->level.background=0;
      player->level.layout=0;
      player->bombs.left=0;
   }
}

///////////////////
// GameLevelNext //
///////////////////
void GameLevelNext(GamePlayer* player)
{
   player->level.speed+=SPEED_ENEMY_INCREMENT;
   if(++player->level.background==LEVEL_BACKGROUNDS_NB)
      player->level.background=0;
   if(++player->level.layout==LEVEL_LAYOUTS_NB)
      player->level.layout=0;
   player->bombs.left=0;
}

////////////////////
// GameLevelStart //
////////////////////
static unsigned char GameLevelStart(GamePlayer* player)
{
   unsigned short* screen;
   unsigned char element;
   unsigned char resume;
   unsigned short mapData[32*20];
   unsigned short* map;
   const GameEnemiesPlatformsLocations* enemiesPlatformsLocations;
   unsigned char length;
   const GameBombsLocations* bombsLocations;
   unsigned char id,location;

   // Initialisation des sprites
   CommonSpritesInit();

   // Nettoyage du fond de jeu
   CommonDmaForce(511|(1<<12),(void*)SCREEN_BASE_BLOCK(28),32*20,DMA_16NOW); // Tile #511, palette #1

   // Nettoyage partiel du foreground (= aire de jeu, i.e. les plateformes)
   screen=(unsigned short*)SCREEN_BASE_BLOCK(29);
   for(element=0;element<20;++element)
   {
      CommonDmaForce(287,(void*)screen,25,DMA_16NOW);
      screen+=32;
   }

   // Nettoyage du cache
   CommonCpcMaskCleanAll(0);

   // Mise en place du nombre de vie et du score du joueur
   GameUpdateLives(player->numLives);
   GameUpdateScore(player,0);

   // Initialisation de Jack, des ennemis et du bonus
   resume=CommonSramRead('C',(unsigned char*)&gameTData);
   if(!resume)
   {
      // Positionnement de Jack et declaration de son status initial
      gameTData.jack.state=ALIVE;
      gameTData.jack.move.xPosition=JACK_INIT_X<<FIXED_POINT_SHIFT;
      gameTData.jack.move.yPosition=JACK_INIT_Y<<FIXED_POINT_SHIFT;
      gameTData.jack.move.yDelta=0;

      // Initialisation des ennemis
      for(element=0;element<4;++element)
         gameTData.enemy[element].state=INIT_A;
      gameTData.enemy[element].state=INIT_E;

      // Initialisation du bonus
      gameTData.bonus.state=INIT;
      gameTData.bonus.multiply=1;
   }

   // Initialisation de la sequence de rotation des couleurs de l'encre #14
   if(gameTData.bonus.state!=TOUCHED_1)
   {
      // Pas de bonus...
      gameColorSequences.info[0].inks=gameInksEnemies;
      gameColorSequences.info[0].length=sizeof(gameInksEnemies);
   }
   else
   {
      // Bonus !
      if(gameTData.bonus.memory<TIMER_BONUS_WARNING)
         gameColorSequences.info[0].inks=gameInksBonusNormal;
      else
         gameColorSequences.info[0].inks=gameInksBonusEnd;
      gameColorSequences.info[0].length=sizeof(gameInksBonusNormal);
      gameColorSequences.info[0].count=gameColorSequences.info[1].count;
   }

   // Mise en place de la palette et affichage
   CommonCpcPaletteSet(gameBackground[player->level.background].palette,PALRAM);
   CommonSpritesDisplay();
   REG_DISPCNT=BG0_ENABLE|BG1_ENABLE|BG2_ENABLE|OBJ_ENABLE|OBJ_2D;

   // Affichage progressif du fond
   CommonUncompressInVRAM((void*)gameBackground[player->level.background].tiles,(void*)CHAR_BASE_BLOCK(0));
   CommonUncompressInWRAM((void*)gameBackground[player->level.background].map,(void*)mapData);

   map=mapData;
   screen=(unsigned short*)SCREEN_BASE_BLOCK(28);
   for(element=0;element<20*4;++element)
   {
      // Copie de quelques tiles du fond ; il faut 4 passes par ligne
      if((element&3)!=3)
      {
         // Copie de 6 tiles d'un coup
         CommonDmaCopy((void*)map,(void*)screen,6,DMA_16NOW);
         map+=6;
         screen+=6;
      }
      else
      {
         // Copie de 7 tiles d'un coup, et saut a la ligne suivante
         CommonDmaCopy((void*)map,(void*)screen,7,DMA_16NOW);
         map+=7;
         screen+=14;
      }

      // Rotation des couleurs et attente du retour du balayage vertical
      CommonCpcPaletteRotate(&gameColorSequences,1);
      CommonVwait(1);
   }

   // Affichage des plateformes
   enemiesPlatformsLocations=gameLayout[player->level.layout].enemiesPlatformsLocations;
   for(element=0;element<enemiesPlatformsLocations->elementNb;++element)
   {
      screen=(unsigned short*)SCREEN_BASE_BLOCK(29)+enemiesPlatformsLocations->element[element].firstTile;
      length=enemiesPlatformsLocations->element[element].length;

      if(length&128)
      {
         // Mur (vertical)
         switch(*screen)
         {
            case 256:*screen=222;break;
            case 257:*screen=259;break;
            case 258:*screen=223;break;
            default:*screen=260;break;
         }
         screen+=32;
         for(length-=129;--length;screen+=32)
            *screen=261;
         switch(*screen)
         {
            case 256:*screen=254;break;
            case 258:*screen=255;break;
            default:*screen=262;break;
         }
      }
      else
      {
         // Plateforme (horizontale)
         *screen++=256;
         for(--length;--length;++screen)
            *screen=257;
         *screen=258;
      }
   }

   // Mise en place des bombes
   bombsLocations=gameLayout[player->level.layout].bombsLocations;
   for(id=0;id<24;++id)
   {
      location=(*bombsLocations)[id];
      if(!player->bombs.left)
         player->bombs.id[location]=id;
      else if(player->bombs.id[location]!=id)
         continue;

      commonSprites[id].attribute0=gameConvert.locationToY[location];
      commonSprites[id].attribute1=gameConvert.locationToX[location]|(1<<14); // Les bombes sont des sprites 16x16...
      commonSprites[id].attribute2=208|(2<<10); // Ces sprites sont de priorite 2 (= derriere le background 2)
   }

   if(!resume)
   {
      // Initialisation des variables de jeu relatives aux bombes
      if(!player->bombs.left)
      {
         player->bombs.left=id;
         player->bombs.sparkingNb=0;
         player->bombs.bonusTrigger=0;
      }
      gameTData.sparkingId=0xFF;
   }
   else
   {
      // Mise en place des sprites de Jack, des ennemis et du bonus
      CommonSramRead('D',(unsigned char*)&commonSprites[24].attribute0);
   }

   // Affichage des sprites
   CommonSpritesDisplay();

   // Initialisation du systeme de notification
   gameNotify.push=0;
   gameNotify.pop=0xFF;
   gameNotify.count=TIMER_NOTIFICATION_DISAPPEAR;

   // Indique si oui on non la partie etait deja en cours
   return(resume);
}

/////////////////////
// GameDetectWalls //
/////////////////////
static unsigned char GameDetectWalls(unsigned char x,unsigned char y,unsigned char height)
{
   unsigned short* screen;
   unsigned short tile;
   unsigned long mask;

   // Verifie qu'on est bien dans l'aire de jeu (a la fois a gauche et a droite)
   if(x>=200)
      return(1);

   // Verifie qu'il n'y a pas de mur sur toute la hauteur
   screen=(unsigned short*)SCREEN_BASE_BLOCK(29)+(x>>3);
   mask=gameMaskPixels[x&7];

   --height;
   while(1)
   {
      tile=screen[(y&~7)<<2];
      if(((unsigned long*)OBJ_TILES)[(tile<<3)+(y&7)]&mask)
         return(1);
      if(height>PLATFORM_HEIGHT)
      {
         y+=PLATFORM_HEIGHT;
         height-=PLATFORM_HEIGHT;
      }
      else if(height)
      {
         y+=height;
         height=0;
      }
      else
         break;
   }

   // Pas de collision !
   return(0);
}

/////////////////////////
// GameDetectPlatforms //
/////////////////////////
static unsigned char GameDetectPlatforms(unsigned char x,unsigned char y,unsigned char width)
{
   unsigned short* screen;
   unsigned short tile;

   // Verifie qu'on est bien dans l'aire de jeu (a la fois en haut et en bas)
   if(y>=160)
      return(1);

   // Verifie qu'il n'y a pas de plateforme sur toute la largeur
   screen=(unsigned short*)SCREEN_BASE_BLOCK(29)+((y&~7)<<2);
   y&=7;

   --width;
   while(1)
   {
      tile=screen[x>>3];
      if(((unsigned long*)OBJ_TILES)[(tile<<3)+y]&gameMaskPixels[x&7])
         return(1);
      if(width>WALL_WIDTH)
      {
         x+=WALL_WIDTH;
         width-=WALL_WIDTH;
      }
      else if(width)
      {
         x+=width;
         width=0;
      }
      else
         break;
   }

   // Pas de collision !
   return(0);
}

//////////////////////
// GameDetectGround //
//////////////////////
static inline unsigned char GameDetectGround(GameMoveInfo* move,const GameSpriteInfo* sprite)
{
   unsigned char xPosition;
   unsigned char yPosition;

   xPosition=(move->xPosition>>FIXED_POINT_SHIFT)+sprite->xOffset;
   yPosition=(move->yPosition>>FIXED_POINT_SHIFT)+sprite->yOffset+sprite->height;
   return(GameDetectPlatforms(xPosition,yPosition,sprite->width));
}

/////////////////////
// GameDetectBombs //
/////////////////////
static inline unsigned char GameDetectBombs(GamePlayer* player,unsigned char* id)
{
   unsigned char location;

   // Il ne peut y avoir contact que lorsque Jack est vivant
   if(gameTData.jack.state!=ALIVE)
      return(0);

   // Convertit la position de BJ - attention, on peut parfois etre entre 2 regions (location=0xFF)
   if((location=gameConvert.xToLocation[(gameTData.jack.move.xPosition>>FIXED_POINT_SHIFT)-6])>=9)
      return(0);
   location+=gameConvert.yToLocation[(gameTData.jack.move.yPosition>>FIXED_POINT_SHIFT)-8];

   // Regarde s'il y a une bombe a cet endroit
   if((*id=player->bombs.id[location])>=24)
      return(0);

   // Rompt explicitement le lien entre les 2 tableaux
   player->bombs.id[location]=0xFF;

   // Verifie qu'il y a bien contact avec une bombe (car les id peuvent etre fausses)
   if((*gameLayout[player->level.layout].bombsLocations)[*id]!=location)
      return(0);

   // Ca semble ok !
   return(1);
}

////////////////////
// GameDetectJack //
////////////////////
static unsigned char GameDetectJack(GameMoveInfo* move,const GameSpriteInfo* sprite)
{
   signed short positionJack,positionOther;

   // Il ne peut y avoir collision que lorsque Jack est vivant
   if(gameTData.jack.state!=ALIVE)
      return(0);

   // On verifie s'il y a collision, d'abord sur l'axe x
   // Note : la tolerance est la meme qu'avec les bombes, i.e. 4 pixels de chaque cote
   positionJack=(gameTData.jack.move.xPosition>>FIXED_POINT_SHIFT)+gameSpriteInfo[SPRITE_JACK].xOffset;
   positionOther=(move->xPosition>>FIXED_POINT_SHIFT)+sprite->xOffset;
   if(positionJack>positionOther+sprite->width-4 || positionOther>positionJack+gameSpriteInfo[SPRITE_JACK].width-4)
      return(0);

   // Puis sur l'axe y
   positionJack=(gameTData.jack.move.yPosition>>FIXED_POINT_SHIFT)+gameSpriteInfo[SPRITE_JACK].yOffset;
   positionOther=(move->yPosition>>FIXED_POINT_SHIFT)+sprite->yOffset;
   if(positionJack>positionOther+sprite->height-4 || positionOther>positionJack+gameSpriteInfo[SPRITE_JACK].height-4)
      return(0);

   // Il y a collision !
   return(1);
}

///////////////
// GameMoveX //
///////////////
static unsigned char GameMoveX(GameMoveInfo *move,const GameSpriteInfo* sprite)
{
   unsigned char xPosition,xPositionTarget;
   unsigned char yPosition;
   signed char xDelta;
   signed char xOffset;

   xPosition=move->xPosition>>FIXED_POINT_SHIFT;
   xPositionTarget=(move->xPosition+move->xDelta)>>FIXED_POINT_SHIFT;

   if(xPosition!=xPositionTarget)
   {
      yPosition=(move->yPosition>>FIXED_POINT_SHIFT)+sprite->yOffset;
      if(move->xDelta<0)
      {
         xDelta=-1;
         xOffset=sprite->xOffset-1;
      }
      else
      {
         xDelta=+1;
         xOffset=sprite->xOffset+sprite->width;
      }
      do
      {
         if(GameDetectWalls(xPosition+xOffset,yPosition,sprite->height))
         {
            move->xPosition=xPosition<<FIXED_POINT_SHIFT;
            return(1);
         }
         xPosition+=xDelta;
      }
      while(xPosition!=xPositionTarget);
   }
   move->xPosition+=move->xDelta;
   return(0);
}

///////////////
// GameMoveY //
///////////////
static unsigned char GameMoveY(GameMoveInfo *move,const GameSpriteInfo* sprite)
{
   unsigned char yPosition,yPositionTarget;
   unsigned char xPosition;
   signed char yDelta;
   signed char yOffset;

   yPosition=move->yPosition>>FIXED_POINT_SHIFT;
   yPositionTarget=(move->yPosition+move->yDelta)>>FIXED_POINT_SHIFT;

   if(yPosition!=yPositionTarget)
   {
      xPosition=(move->xPosition>>FIXED_POINT_SHIFT)+sprite->xOffset;
      if(move->yDelta<0)
      {
         yDelta=-1;
         yOffset=sprite->yOffset-1;
      }
      else
      {
         yDelta=+1;
         yOffset=sprite->yOffset+sprite->height;
      }
      do
      {
         if(GameDetectPlatforms(xPosition,yPosition+yOffset,sprite->width))
         {
            move->yPosition=yPosition<<FIXED_POINT_SHIFT;
            return(1);
         }
         yPosition+=yDelta;
      }
      while(yPosition!=yPositionTarget);
   }
   move->yPosition+=move->yDelta;
   return(0);
}

///////////////////////
// GameSpriteDisplay //
///////////////////////
static inline void GameSpriteDisplay(unsigned char index,GameMoveInfo* move,unsigned short sprite)
{
   commonSprites[index].attribute0=((move->yPosition>>FIXED_POINT_SHIFT)-8)&255;
   commonSprites[index].attribute1=(((move->xPosition>>FIXED_POINT_SHIFT)-8)&511)|(1<<14);
   commonSprites[index].attribute2=sprite|(1<<10); // Ce sprite est de priorite 1 (= derriere le background 2)
}

//////////////////////////
// GameManageBrightness //
//////////////////////////
static inline void GameManageBrightness(unsigned short keysChanged)
{
   if(keysChanged&KEY_SELECT)
   {
      if(REG_BLDMOD==BLEND_NO)
         REG_BLDMOD=BLEND_BG0|BLEND_BLACK;
      else
         REG_BLDMOD=BLEND_NO;
   }
}

///////////////
// GameTimer //
///////////////
static void GameTimer(unsigned char timer)
{
   unsigned short keysChanged;

   // Boucle d'attente
   while(1)
   {
      // Rotation des couleurs
      CommonCpcPaletteRotate(&gameColorSequences,1);
      OBJ_PALRAM[14]=PALRAM[14];
      OBJ_PALRAM[15]=PALRAM[15];

      // Gestion des touches (et attente du retour de balayage)
      keysChanged=REG_KEYS;
      CommonVwait(1);
      keysChanged&=~REG_KEYS;

      // Interruption de la pause ?
      if(keysChanged&(KEY_START|KEY_A|KEY_B))
         break;

      // Gestion de la luminosite
      GameManageBrightness(keysChanged);

      // Gestion du timer
      if(timer)
         if(!--timer)
            break;
   }
}

/////////////////////////////
// GameManageCheatAndPause //
/////////////////////////////
static inline unsigned char GameManageCheatAndPause(unsigned short keysChanged)
{
   static unsigned char cheatIndex=0;

   // Verification preliminaire
   if(!keysChanged)
      return(0);

   // Gestion du cheat code
   if(keysChanged!=gameCheatCode[cheatIndex])
      cheatIndex=0;
   else if(++cheatIndex>=sizeof(gameCheatCode)/sizeof(gameCheatCode[0]))
   {
      // Ok ! On reinitialise le cheat et on passe au niveau suivant !
      cheatIndex=0;
      return(1);
   }

   // Gestion de la pause
   if(keysChanged&KEY_START)
   {
      // Sauvegarde de l'etat courant
      CommonSramWrite('B',(unsigned char*)&gamePData,sizeof(gamePData));
      CommonSramWrite('C',(unsigned char*)&gameTData,sizeof(gameTData));
      CommonSramWrite('D',(unsigned char*)&commonSprites[24].attribute0,7*sizeof(CommonSprite));

      // Baisse du volume
      #ifdef ADPCM_ENABLED
      AdpcmSetVolume(0,43);
      #endif // ADPCM_ENABLED

      // Affichage du message "PAUSE!" et attente...
      CommonCpcMaskWriteString(4,2,"PAUSE!",15);
      GameTimer(0);
      CommonCpcMaskCleanAll(0);

      // Remise du volume a la normale
      #ifdef ADPCM_ENABLED
      AdpcmSetVolume(0,128);
      #endif // ADPCM_ENABLED

      // Destruction de la sauvegarde de l'etat courant
      CommonSramClear('B');
      CommonSramClear('C');
      CommonSramClear('D');
   }

   // Rien de particulier n'est arrive...
   return(0);
}

////////////////////
// GameManageJack //
////////////////////
static void GameManageJack(GamePlayer* player,unsigned short keysPressed,unsigned short keysChanged)
{
   unsigned short sprite;

   // Gestion du saut
   if(keysChanged&KEY_A && gameTData.jack.state==ALIVE)
   {
      if(GameDetectGround(&gameTData.jack.move,&gameSpriteInfo[SPRITE_JACK]))
      {
         GameUpdateScore(player,POINTS_JUMP);
         if(gamePData.keyMode || keysPressed&KEY_UP)
            gameTData.jack.move.yDelta=SPEED_JACK_JUMP_TURBO;
         else
            gameTData.jack.move.yDelta=SPEED_JACK_JUMP_NORMAL;
      }
      else
         gameTData.jack.move.yDelta=0;
   }

   // Gestion de la mort et des deplacements lateraux
   if(gameTData.jack.state!=ALIVE)
   {
      sprite=0;
      if(GameDetectGround(&gameTData.jack.move,&gameSpriteInfo[SPRITE_JACK]))
      {
         gameTData.jack.state=DEAD;
         gameTData.jack.move.yDelta=0;
      }
      else if(gameTData.jack.state==TOUCHED)
      {
         gameTData.jack.state=DYING;
         gameTData.jack.move.yDelta=SPEED_JACK_JUMP_DEAD;
      }
   }
   else if(keysPressed&KEY_LEFT)
   {
      sprite=132;
      gameTData.jack.move.xDelta=-FIXED_POINT;
   }
   else if(keysPressed&KEY_RIGHT)
   {
      sprite=140;
      gameTData.jack.move.xDelta=FIXED_POINT;
   }
   else
      sprite=0;

   // Deplacement...
   if(sprite)
      GameMoveX(&gameTData.jack.move,&gameSpriteInfo[SPRITE_JACK]);
   if(GameMoveY(&gameTData.jack.move,&gameSpriteInfo[SPRITE_JACK]))
      gameTData.jack.move.yDelta=0;
   else
      gameTData.jack.move.yDelta+=ACCELERATION_FALL;

   // Choix du sprite en fonction du mouvement
   if(gameTData.jack.state!=ALIVE || GameDetectGround(&gameTData.jack.move,&gameSpriteInfo[SPRITE_JACK]))
   {
      if(sprite)
         sprite+=commonVblCounter&2;
      else
         sprite=commonSprites[24].attribute2&1023; // On garde le sprite courant...
   }
   else if(gameTData.jack.move.yDelta<SPEED_JACK_FALL_QUICK) // On ne change de sprite que lorsque la chute devient rapide
   {
      if(sprite)
         sprite+=4;
      else
         sprite=148;
   }
   else
   {
      if(sprite)
         sprite+=6;
      else
         sprite=150;
   }

   // Mise en place du sprite
   GameSpriteDisplay(24,&gameTData.jack.move,sprite);
}

/////////////////////
// GameManageBombs //
/////////////////////
static unsigned char GameManageBombs(GamePlayer* player)
{
   unsigned char id;

   // Verifie s'il y a contact entre BJ et une bombe
   if(GameDetectBombs(player,&id))
   {
      // Le nombre de points attribues depend du type de bombe (= sparking ?)
      if(id!=gameTData.sparkingId)
      {
         // Mise a jour du score
         GameUpdateScore(player,POINTS_BOMB_NORMAL);

         // Suppression de la bombe (= desactivation du sprite : taille double mais pas de rotation)
         commonSprites[id].attribute0=(1<<9)|(0<<8);
      }
      else
      {
         // Mise a jour du score
         GameUpdateScore(player,POINTS_BOMB_SPARKING);

         // Incrementation du nombre de "sparking bombs"
         ++player->bombs.sparkingNb;
         gameTData.sparkingId=0xFF;

         // Remplacement de la bombe par le sprite de notification du score
         commonSprites[id].attribute2=(212+(gameTData.bonus.multiply<<1))|(2<<10); // Rappel : ces sprites sont de priorite 2

         // Enregistrement de la notification
         if(gameNotify.pop==0xFF)
            gameNotify.pop=gameNotify.push;
         else if(gameNotify.push==gameNotify.pop)
         {
            commonSprites[gameNotify.bombs[gameNotify.pop].id].attribute0=(1<<9)|(0<<8); // Desactivation du sprite
            gameNotify.pop=(gameNotify.pop+1)&7;
            gameNotify.bombs[gameNotify.pop].timer+=gameNotify.bombs[gameNotify.push].timer;
         }
         gameNotify.bombs[gameNotify.push].id=id;
         gameNotify.bombs[gameNotify.push].timer=gameNotify.count;
         gameNotify.count=0;
         gameNotify.push=(gameNotify.push+1)&7;
      }

      // Decrementation et verification du nombre de bombes a supprimer (niveau termine ?)
      if(!--player->bombs.left)
         return(1);

      // Recherche de la prochaine "sparking bomb" (s'il n'y en a pas deja une)
      if(gameTData.sparkingId==0xFF)
      {
         do
         {
            if(++id>=24)
               id=0;
         }
         while(player->bombs.id[(*gameLayout[player->level.layout].bombsLocations)[id]]>=24);
         gameTData.sparkingId=id;
      }
   }

   // Animation de la "sparking bomb"
   if(!(commonVblCounter&3) && gameTData.sparkingId<24)
   {
      if(commonSprites[gameTData.sparkingId].attribute2==(212|(2<<10))) // Attention : ces sprites sont de priorite 2
         commonSprites[gameTData.sparkingId].attribute2=208|(2<<10);
      else
         commonSprites[gameTData.sparkingId].attribute2+=2;
   }

   // Gestion des notifications
   if(gameNotify.pop!=0xFF)
   {
      ++gameNotify.count;
      if(!--gameNotify.bombs[gameNotify.pop].timer)
      {
         commonSprites[gameNotify.bombs[gameNotify.pop].id].attribute0=(1<<9)|(0<<8); // Desactivation du sprite
         gameNotify.pop=(gameNotify.pop+1)&7;
         if(gameNotify.pop==gameNotify.push)
            gameNotify.pop=0xFF;
      }
   }

   // Le niveau n'est pas termine...
   return(0);
}

//////////////////////
// GameManageEnemyA //
//////////////////////
static inline unsigned short GameManageEnemyA(GameEnemy* enemy)
{
   unsigned short sprite;
   unsigned char xPosition,yPosition;

   // Calcul de la position du pixel devant l'ennemi et choix du sprite
   xPosition=enemy->move.xPosition>>FIXED_POINT_SHIFT;
   sprite=xPosition&2;
   if(enemy->move.xDelta<0)
   {
      xPosition+=gameSpriteInfo[SPRITE_ENEMY_A].xOffset-1;
      sprite+=15;
   }
   else
   {
      xPosition+=gameSpriteInfo[SPRITE_ENEMY_A].xOffset+gameSpriteInfo[SPRITE_ENEMY_A].width;
      sprite+=19;
   }

   // On gere d'abord l'eventuelle chute de l'ennemi...
   if(GameMoveY(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_A]) || GameDetectGround(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_A]))
   {
      enemy->move.yDelta=0;

      yPosition=(enemy->move.yPosition>>FIXED_POINT_SHIFT)+gameSpriteInfo[SPRITE_ENEMY_A].yOffset+gameSpriteInfo[SPRITE_ENEMY_A].height;
      if(yPosition==160)
      {
         // S'il atteint le bas de l'ecran, alors l'ennemi se transforme
         enemy->state=TRANSFORM_A;
         enemy->memory=0;
      }

      // S'il ne chute pas, alors l'ennemi se deplace lateralement
      else if(GameMoveX(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_A]) || (enemy->memory && !GameDetectPlatforms(xPosition,yPosition,1)))
      {
         enemy->move.xDelta=-enemy->move.xDelta;
         if(enemy->memory)
            --enemy->memory;
      }
   }
   else
   {
      enemy->move.yDelta+=ACCELERATION_FALL;
      enemy->memory=ENEMY_A_CHANGE_DIR; // Nombre de demi-tours autorises
   }

   // On verifie s'il y a collision avec Jack
   if(GameDetectJack(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_A]))
      gameTData.jack.state=TOUCHED;

   // On retourne le sprite a utiliser
   return(sprite);
}

//////////////////////
// GameManageEnemyB //
//////////////////////
static inline unsigned short GameManageEnemyB(GameEnemy* enemy,signed short speed)
{
   unsigned short sprite;

   // Choix du sprite
   sprite=87+((enemy->move.xPosition>>FIXED_POINT_SHIFT)&6);

   // On gere d'abord les deplacements lateraux de l'ennemi
   if(gameTData.jack.move.xPosition<enemy->move.xPosition)
   {
      if(enemy->move.xDelta>-(speed<<1))
         --enemy->move.xDelta;
   }
   else
   {
      if(enemy->move.xDelta<(speed<<1))
         ++enemy->move.xDelta;
   }
   if(GameMoveX(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_B]))
      enemy->move.xDelta=-enemy->move.xDelta;

   // On gere ensuite les deplacements verticaux de l'ennemi
   if(gameTData.jack.move.yPosition<enemy->move.yPosition)
   {
      if(enemy->move.yDelta>-speed)
         --enemy->move.yDelta;
   }
   else
   {
      if(enemy->move.yDelta<speed)
         ++enemy->move.yDelta;
   }
   if(GameMoveY(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_B]))
      enemy->move.yDelta=-enemy->move.yDelta;

   // On verifie s'il y a collision avec Jack
   if(GameDetectJack(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_B]))
      gameTData.jack.state=TOUCHED;

   // On retourne le sprite a utiliser
   return(sprite);
}

//////////////////////
// GameManageEnemyC //
//////////////////////
static inline unsigned short GameManageEnemyC(GameEnemy* enemy,signed short speed)
{
   unsigned short sprite;

   // On choisit le sprite tout en gerant les deplacements lateraux de l'ennemi
   sprite=(enemy->move.xPosition>>FIXED_POINT_SHIFT)&2;
   if(gameTData.jack.move.xPosition<enemy->move.xPosition)
   {
      sprite+=79;
      if(enemy->move.xDelta>-speed)
         enemy->move.xDelta-=2;
   }
   else
   {
      sprite+=83;
      if(enemy->move.xDelta<speed)
         enemy->move.xDelta+=2;
   }
   if(GameMoveX(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_C]))
      enemy->move.xDelta=-enemy->move.xDelta;

   // On gere ensuite les deplacements verticaux de l'ennemi
   if(gameTData.jack.move.yPosition<enemy->move.yPosition)
   {
      if(enemy->move.yDelta>-speed)
         --enemy->move.yDelta;
   }
   else
   {
      if(enemy->move.yDelta<speed)
         ++enemy->move.yDelta;
   }
   if(GameMoveY(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_C]))
      enemy->move.yDelta=-enemy->move.yDelta;

   // On verifie s'il y a collision avec Jack
   if(GameDetectJack(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_C]))
      gameTData.jack.state=TOUCHED;

   // On retourne le sprite a utiliser
   return(sprite);
}

//////////////////////
// GameManageEnemyD //
//////////////////////
static inline unsigned short GameManageEnemyD(GameEnemy* enemy,signed short speed)
{
   unsigned short sprite;
   unsigned char moveX,moveY;
   signed short delta;

   // Choix du sprite
   sprite=128+((enemy->move.xPosition>>FIXED_POINT_SHIFT)&2);

   // On gere les deplacements de l'ennemi
   moveX=GameMoveX(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_D]);
   moveY=GameMoveY(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_D]);

   if(moveX || moveY)
   {
      delta=gameTData.jack.move.xPosition-enemy->move.xPosition;
      if(moveX && ((delta>0 && enemy->move.xDelta>0) || (delta<0 && enemy->move.xDelta<0)))
         enemy->move.xDelta=-enemy->move.xDelta;
      else
         enemy->move.xDelta=(delta*speed)>>(FIXED_POINT_SHIFT*2-1);

      delta=gameTData.jack.move.yPosition-enemy->move.yPosition;
      if(moveY && ((delta>0 && enemy->move.yDelta>0) || (delta<0 && enemy->move.yDelta<0)))
         enemy->move.yDelta=-enemy->move.yDelta;
      else
         enemy->move.yDelta=(delta*speed)>>(FIXED_POINT_SHIFT*2-1);
   }

   // On verifie s'il y a collision avec Jack
   if(GameDetectJack(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_D]))
      gameTData.jack.state=TOUCHED;

   // On retourne le sprite a utiliser
   return(sprite);
}

//////////////////////
// GameManageEnemyE //
//////////////////////
static inline unsigned short GameManageEnemyE(GameEnemy* enemy,signed short speed)
{
   unsigned short sprite;

   // On modifie la direction de l'ennemi de temps en temps
   if(enemy->memory)
      --enemy->memory;
   else
   {
      enemy->memory=TIMER_ENEMY_E_CHANGE_DIR;
      if(gameTData.jack.move.xPosition<enemy->move.xPosition)
         enemy->move.xDelta=-speed;
      else
         enemy->move.xDelta=speed;
      if(rand()&1)
         enemy->move.yDelta=0;
      else if(gameTData.jack.move.yPosition<enemy->move.yPosition)
         enemy->move.yDelta=-speed;
      else
         enemy->move.yDelta=speed;
   }

   // Choix du sprite
   sprite=(enemy->move.xPosition>>FIXED_POINT_SHIFT)&2;
   if(enemy->move.xDelta<0)
      sprite+=23;
   else
      sprite+=27;

   // On deplace l'ennemi
   if(enemy->move.yDelta)
   {
      if(GameMoveY(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_E]))
         enemy->memory=0;
   }
   else
   {
      if(GameMoveX(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_E]))
         enemy->memory=0;
   }

   // On verifie s'il y a collision avec Jack
   if(GameDetectJack(&enemy->move,&gameSpriteInfo[SPRITE_ENEMY_E]))
      gameTData.jack.state=TOUCHED;

   // On retourne le sprite a utiliser
   return(sprite);
}

/////////////////////
// GameManageEnemy //
/////////////////////
static inline void GameManageEnemy(GamePlayer* player,unsigned char numEnemy)
{
   GameEnemy* enemy;
   unsigned char numOtherEnemy;
   unsigned short sprite;

   // On pointe vers l'ennemi courant
   enemy=&gameTData.enemy[numEnemy];

   // Son comportement depend de son type
   if(enemy->state==INIT_A)
   {
      // Desactivation du sprite
      commonSprites[25+numEnemy].attribute0=(1<<9)|(0<<8);

      // Initialisation de l'ennemi
      enemy->state=HIDE_A;
      enemy->memory=TIMER_ENEMY_A_APPEAR;
      enemy->move.xPosition=gameLayout[player->level.layout].enemiesPlatformsLocations->enemy[numEnemy&1].xPosition<<FIXED_POINT_SHIFT;
      enemy->move.yPosition=gameLayout[player->level.layout].enemiesPlatformsLocations->enemy[numEnemy&1].yPosition<<FIXED_POINT_SHIFT;
      enemy->move.xDelta=player->level.speed<<1;
      enemy->move.yDelta=0;
      return;
   }

   if(enemy->state==HIDE_A)
   {
      // L'ennemi reste cache si Jack a obtenu un bonus permettant de le detruire
      if(gameTData.bonus.state==TOUCHED_1)
         return;

      // L'ennemi reste egalement cache si les ennemis qui le precedent ne sont pas actifs
      for(numOtherEnemy=0;numOtherEnemy<numEnemy;++numOtherEnemy)
         if(gameTData.enemy[numOtherEnemy].state<MANAGE_A)
         {
            // Si besoin est, on modifie les temps d'attente pour garder un rythme constant
            if(gameTData.enemy[numOtherEnemy].memory>enemy->memory)
            {
               gameTData.enemy[numOtherEnemy].memory=enemy->memory;
               enemy->memory=TIMER_ENEMY_A_APPEAR;
            }
            return;
         }

      // Evidemment, l'ennemi reste cache jusqu'a l'expiration de sa temporisation
      if(--enemy->memory)
         return;

      // Finalement l'ennemi apparait !
      enemy->state=APPEAR_A;
   }
   else if(enemy->state==INIT_E)
   {
      // Verifie qu'on peut apparaitre
      if(gameTData.bonus.state==TOUCHED_1)
      {
         commonSprites[25+numEnemy].attribute0=(1<<9)|(0<<8);
         return;
      }

      // Initialisation de l'ennemi
      enemy->state=MANAGE_E;
      enemy->memory=0;
      if(rand()&1)
         enemy->move.xPosition=7<<FIXED_POINT_SHIFT;
      else
         enemy->move.xPosition=(200-7)<<FIXED_POINT_SHIFT;
      if(rand()&1)
         enemy->move.yPosition=5<<FIXED_POINT_SHIFT;
      else
         enemy->move.yPosition=(160-4)<<FIXED_POINT_SHIFT;
   }

   if(gameTData.bonus.state==TOUCHED_1)
   {
      // Si Jack a obtenu un bonus permettant de detruire les ennemis, alors on affiche le smiley
      sprite=200;

      // On verifie s'il y a collision avec Jack
      if(GameDetectJack(&enemy->move,&gameSpriteInfo[SPRITE_SMILEY]))
      {
         // Mise a jour du score
         ++gameTData.bonus.numKills;
         GameUpdateScore(player,POINTS_ENEMY*gameTData.bonus.numKills);

         // Re-initialisation de l'ennemi
         if(enemy->state==MANAGE_E)
            enemy->state=INIT_E;
         else
            enemy->state=INIT_A;
      }
   }
   else if(enemy->state==APPEAR_A || enemy->state==TRANSFORM_A)
   {
      // Lorsqu'il apparait ou se transforme, il y a une petite explosion
      sprite=204+(commonVblCounter&2);
      if(enemy->memory<TIMER_ENEMY_A_TRANSFORM)
         ++enemy->memory;
      else if(enemy->state==APPEAR_A)
         enemy->state=MANAGE_A;
      else
         enemy->state=MANAGE_B+rand()%3;
   }
   else if(enemy->state==MANAGE_A)
      sprite=GameManageEnemyA(enemy);
   else if(enemy->state==MANAGE_B)
      sprite=GameManageEnemyB(enemy,player->level.speed);
   else if(enemy->state==MANAGE_C)
      sprite=GameManageEnemyC(enemy,player->level.speed);
   else if(enemy->state==MANAGE_D)
      sprite=GameManageEnemyD(enemy,player->level.speed);
   else
      sprite=GameManageEnemyE(enemy,player->level.speed);

   // Mise en place du sprite
   GameSpriteDisplay(25+numEnemy,&enemy->move,sprite);
}

///////////////////////
// GameManageEnemies //
///////////////////////
static void GameManageEnemies(GamePlayer* player)
{
   unsigned char numEnemy;

   // Gestion des 5 ennemis
   for(numEnemy=0;numEnemy<5;++numEnemy)
      GameManageEnemy(player,numEnemy);
}

/////////////////////
// GameManageBonus //
/////////////////////
static void GameManageBonus(GamePlayer* player)
{
   unsigned short sprite;

   if(gameTData.bonus.state==TOUCHED_1)
   {
      if(gameTData.bonus.memory==TIMER_BONUS_DISAPPEAR)
      {
         // L'effet du bonus doit disparaitre et le bonus etre reinitialise
         gameColorSequences.info[0].inks=gameInksEnemies;
         gameColorSequences.info[0].length=sizeof(gameInksEnemies);
         gameTData.bonus.state=INIT;
      }
      else
      {
         if(!gameTData.bonus.memory)
         {
            // On vient d'attraper le bonus, il faut donc supprimer le sprite et changer la sequence de rotation des couleurs
            commonSprites[30].attribute0=(1<<9)|(0<<8);
            gameColorSequences.info[0].inks=gameInksBonusNormal;
            gameColorSequences.info[0].length=sizeof(gameInksBonusNormal);
            gameColorSequences.info[0].count=gameColorSequences.info[1].count;
         }
         else if(gameTData.bonus.memory==TIMER_BONUS_WARNING)
         {
            // Le bonus va bientot disparaitre, on change donc encore la sequence de rotation des couleurs
            gameColorSequences.info[0].inks=gameInksBonusEnd;
         }
         ++gameTData.bonus.memory;
         return;
      }
   }

   if(gameTData.bonus.state==INIT)
   {
      // Desactivation du sprite
      commonSprites[30].attribute0=(1<<9)|(0<<8);

      // Initialisation du bonus
      gameTData.bonus.state=HIDE_A;
      gameTData.bonus.memory=TIMER_BONUS_APPEAR;
      gameTData.bonus.move.xPosition=(200-7)<<FIXED_POINT_SHIFT;
      gameTData.bonus.move.yPosition=7<<FIXED_POINT_SHIFT;
      gameTData.bonus.move.xDelta=-SPEED_BONUS;
      gameTData.bonus.move.yDelta=SPEED_BONUS;
      return;
   }

   if(gameTData.bonus.state==HIDE)
   {
      // Le bonus reste cache un certain temps
      if(gameTData.bonus.memory)
         if(--gameTData.bonus.memory)
            return;

      // Lorsque le temps est venu qu'il apparaisse, on verifie d'abord le nombre de "sparking bombs"
      if(player->bombs.sparkingNb<=player->bombs.bonusTrigger)
         return;
      player->bombs.bonusTrigger+=4;

      // On choisit un bonus aleatoirement
      gameTData.bonus.state=MANAGE_1+rand()%3;
   }

   // Gestion des differents bonus
   if(gameTData.bonus.state==MANAGE_1)
   {
      // Choix du sprite
      sprite=152+(commonVblCounter&6);

      // Gestion du deplacement
      if(GameMoveX(&gameTData.bonus.move,&gameSpriteInfo[SPRITE_BONUS]))
         gameTData.bonus.move.xDelta=-gameTData.bonus.move.xDelta;
      if(GameMoveY(&gameTData.bonus.move,&gameSpriteInfo[SPRITE_BONUS]))
         gameTData.bonus.move.yDelta=-gameTData.bonus.move.yDelta;

      // On verifie s'il y a collision avec Jack
      if(GameDetectJack(&gameTData.bonus.move,&gameSpriteInfo[SPRITE_BONUS]))
      {
         // Mise a jour du score
         GameUpdateScore(player,POINTS_BONUS_1);

         // On passe a l'etat "bonus de type 1 touche", sans oublier d'initialiser le compteur de morts
         gameTData.bonus.state=TOUCHED_1;
         gameTData.bonus.numKills=0;
      }
   }
   else
   {
      // Choix du sprite
      sprite=192+(((gameTData.bonus.move.xPosition>>FIXED_POINT_SHIFT)+gameTData.bonus.memory)&6);
      if(sprite==198)
         sprite=194;
      else if(sprite==196 && gameTData.bonus.state==MANAGE_3)
         sprite=198;

      // Gestion du deplacement
      if(GameMoveY(&gameTData.bonus.move,&gameSpriteInfo[SPRITE_BONUS]) ||
         GameDetectGround(&gameTData.bonus.move,&gameSpriteInfo[SPRITE_BONUS]))
      {
         if(GameMoveX(&gameTData.bonus.move,&gameSpriteInfo[SPRITE_BONUS]))
            gameTData.bonus.move.xDelta=-gameTData.bonus.move.xDelta;
      }
      else if(sprite<196)
         ++gameTData.bonus.memory; // On s'assure que le bonus est vu de face lorsqu'il tombe

      // On verifie s'il y a collision avec Jack
      if(GameDetectJack(&gameTData.bonus.move,&gameSpriteInfo[SPRITE_BONUS]))
      {
         if(gameTData.bonus.state==MANAGE_2)
         {
            // Mise a jour du score
            GameUpdateScore(player,POINTS_BONUS_2);

            // Une vie supplementaire !
            if(player->numLives<5)
               GameUpdateLives(++player->numLives);
         }
         else
         {
            // Mise a jour du score
            GameUpdateScore(player,POINTS_BONUS_3);

            // Augmentation du multiplicateur de score !
            if(gameTData.bonus.multiply<4)
               ++gameTData.bonus.multiply;
         }

         // Re-initialisation du bonus
         gameTData.bonus.state=INIT;
      }
   }

   // Mise en place du sprite
   GameSpriteDisplay(30,&gameTData.bonus.move,sprite);
}

//////////////
// GameMain //
//////////////
unsigned char GameMain(GamePlayer* player)
{
   unsigned char resume;
   unsigned short keysPressed,keysChanged;

   // Mise en place du numero du joueur
   *((unsigned short*)SCREEN_BASE_BLOCK(29)+29+(32*1))=272+gamePData.numCurrentPlayer;

   // Mise en place de tous les elements du jeu
   resume=GameLevelStart(player);

   // Affichage du message de debut de jeu
   gameStringPlayer[7]='1'+gamePData.numCurrentPlayer;
   CommonCpcMaskWriteString(3,2,gameStringPlayer,15);
   if(!resume)
   {
      CommonCpcMaskWriteString(4,3,"START!",15);
      GameTimer(TIMER_GAME_START);
   }
   else
   {
      CommonCpcMaskWriteString(0,3,"(GAME RESUMED)",15);
      GameTimer(0);

      // Destruction de la sauvegarde de l'etat courant
      CommonSramClear('B');
      CommonSramClear('C');
      CommonSramClear('D');
   }
   CommonCpcMaskCleanAll(0);

   // Initialisation du generateur de nombres aleatoires
   srand(commonVblCounter);

   // Boucle principale du jeu
   while(gameTData.jack.state!=DEAD)
   {
      // Gestion des touches (et attente du retour de balayage)
      keysChanged=REG_KEYS;
      CommonVwait(1);
      keysPressed=~REG_KEYS;
      keysChanged&=keysPressed;

      // Gestion du cheat code et de la pause
      if(GameManageCheatAndPause(keysChanged))
         return(1);

      // Gestion de la luminosite
      GameManageBrightness(keysChanged);

      // Gestion de Jack
      GameManageJack(player,keysPressed,keysChanged);

      // Gestion des bombes
      if(GameManageBombs(player))
         return(1);

      // Gestion des ennemis
      GameManageEnemies(player);

      // Gestion des bonus
      GameManageBonus(player);

      // Rotation des couleurs
      CommonCpcPaletteRotate(&gameColorSequences,1);
      OBJ_PALRAM[14]=PALRAM[14];
      OBJ_PALRAM[15]=PALRAM[15];

      // Affichage des sprites
      CommonSpritesDisplay();
   }

   // On perd une vie !
   if(!--player->numLives)
   {
      CommonCpcMaskWriteString(2,2,"GAME OVER!",15);
      GameTimer(TIMER_GAME_OVER);
   }
   return(0);
}

////////////////////
// GameDemoRecord //
////////////////////
#ifdef GAME_DEMO_RECORDING
void GameDemoRecord(unsigned char level)
{
   GamePlayer player;
   unsigned char* replay;
   unsigned short randInit;
   unsigned char frameCounter;
   unsigned short keysPressedPrevious,keysPressed,keysChanged;

   // Initialisation des information relative au (faux) joueur
   player.score=0;
   player.numLives=JACK_INIT_LIVES;
   player.level.speed=SPEED_ENEMY_INIT+level*SPEED_ENEMY_INCREMENT;
   player.level.background=level;
   player.level.layout=level;
   player.bombs.left=0;

   // Mise en place du numero du joueur et de tous les elements du jeu
   *((unsigned short*)SCREEN_BASE_BLOCK(29)+29+(32*1))=272;
   GameLevelStart(&player);

   // Affichage du message d'information
   CommonCpcMaskWriteString(5,2,"DEMO",15);
   CommonCpcMaskWriteString(2,3,"RECORDING!",15);

   // Initialisation du pointeur de demonstration
   replay=(unsigned char*)gameDemonstration[level];

   // Initialisation du generateur de nombres aleatoires
   randInit=commonVblCounter;
   *replay++=randInit;
   *replay++=randInit>>8;
   srand(randInit);

   // Sauvegarde du mode courant
   *replay++=gamePData.keyMode;

   // Initialisation des variables de rejeu
   frameCounter=0;
   keysPressedPrevious=0;

   // Boucle principale de la demonstration
   while(gameTData.jack.state!=DEAD)
   {
      // Gestion des touches (et attente du retour de balayage)
      keysChanged=~keysPressedPrevious;
      CommonVwait(1);
      keysPressed=(~REG_KEYS)&(KEY_A|KEY_UP|KEY_LEFT|KEY_RIGHT);
      keysChanged&=keysPressed;

      // Enregistrement de la partie
      if(keysPressedPrevious==keysPressed && frameCounter<255)
         ++frameCounter;
      else
      {
         keysPressedPrevious=keysPressed;
         *replay++=frameCounter;
         *replay++=keysPressed;
         frameCounter=0;
      }

      // Gestion de Jack
      GameManageJack(&player,keysPressed,keysChanged);

      // Gestion des bombes
      if(GameManageBombs(&player))
         break;

      // Gestion des ennemis
      GameManageEnemies(&player);

      // Gestion des bonus
      GameManageBonus(&player);

      // Rotation des couleurs
      CommonCpcPaletteRotate(&gameColorSequences,1);
      OBJ_PALRAM[14]=PALRAM[14];
      OBJ_PALRAM[15]=PALRAM[15];

      // Affichage des sprites
      CommonSpritesDisplay();
   }

   // Termine l'enregistrement de la partie
   *replay=frameCounter;

   // Indique la position et la taille du replay en memoire
   *(const unsigned char**)0x3000000=gameDemonstration[level];
   *(unsigned short*)0x3000004=replay-gameDemonstration[level]+1;
}
#endif // GAME_DEMO_RECORDING

////////////////////
// GameDemoReplay //
////////////////////
void GameDemoReplay(void)
{
   GamePlayer player;
   static unsigned char level=0;
   const unsigned char* replay;
   unsigned short randInit;
   unsigned char keyMode;
   unsigned char frameTrigger,frameCounter;
   unsigned short keysPressed,keysChanged;

   // Enregistrement de la partie
   #ifdef GAME_DEMO_RECORDING
   GameDemoRecord(level);
   #endif // GAME_DEMO_RECORDING

   // Initialisation des information relative au (faux) joueur
   player.score=0;
   player.numLives=JACK_INIT_LIVES;
   player.level.speed=SPEED_ENEMY_INIT+level*SPEED_ENEMY_INCREMENT;
   player.level.background=level;
   player.level.layout=level;
   player.bombs.left=0;

   // Mise en place du numero du joueur et de tous les elements du jeu
   *((unsigned short*)SCREEN_BASE_BLOCK(29)+29+(32*1))=272;
   GameLevelStart(&player);

   // Affichage du message d'information
   CommonCpcMaskWriteString(5,2,"DEMO",15);

   // Initialisation du pointeur de demonstration
   replay=gameDemonstration[level];

   // Initialisation du generateur de nombres aleatoires
   randInit=*replay++;
   randInit+=(*replay++)<<8;
   srand(randInit);

   // Sauvegarde du mode courant et mise en place du mode enregistre
   keyMode=gamePData.keyMode;
   gamePData.keyMode=*replay++;

   // Initialisation des variables de rejeu
   frameTrigger=*replay;
   frameCounter=0;
   keysPressed=0;

   // Boucle principale de la demonstration
   while(gameTData.jack.state!=DEAD)
   {
      // Gestion des touches (et attente du retour de balayage)
      keysChanged=REG_KEYS;
      CommonVwait(1);
      keysChanged&=~REG_KEYS;

      // Interruption de la demonstration ?
      if(keysChanged&(KEY_START|KEY_A|KEY_B))
         break;

      // Gestion de la luminosite
      GameManageBrightness(keysChanged);

      // Lecture de la partie enregistree
      if(frameCounter<frameTrigger)
      {
         ++frameCounter;
         keysChanged=0;
      }
      else
      {
         frameCounter=0;
         keysChanged=~keysPressed;
         keysPressed=*++replay;
         keysChanged&=keysPressed;
         frameTrigger=*++replay;
      }

      // Gestion de Jack
      GameManageJack(&player,keysPressed,keysChanged);

      // Gestion des bombes
      if(GameManageBombs(&player))
         break;

      // Gestion des ennemis
      GameManageEnemies(&player);

      // Gestion des bonus
      GameManageBonus(&player);

      // Rotation des couleurs
      CommonCpcPaletteRotate(&gameColorSequences,1);
      OBJ_PALRAM[14]=PALRAM[14];
      OBJ_PALRAM[15]=PALRAM[15];

      // Affichage des sprites
      CommonSpritesDisplay();
   }

   // Remise en place du mode courant
   gamePData.keyMode=keyMode;

   // Changement du niveau pour la prochaine demonstration
   if(++level>=sizeof(gameDemonstration)/sizeof(gameDemonstration[0]))
      level=0;
}
