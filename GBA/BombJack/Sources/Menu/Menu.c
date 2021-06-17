/*
** Bomb Jack - Sources\Menu\Menu.c
** Nicolas ROBERT [NRX] - Hong Kong 2005 / France 2006
*/

////////////////
// Inclusions //
////////////////
#include "Menu.h"

///////////
// Types //
///////////
typedef struct
{
   unsigned char name[8];
   unsigned long score;
}
MenuHiScore;

////////////////////////
// Variables globales //
////////////////////////
MenuHiScore menuHiScore[8];
const MenuHiScore menuHiScoreDefault[8]=
{
   {"DICK",11410},
   {"TOM",15980},
   {"WENDY",22200},
   {"KAREN",28520},
   {"MANDY",32250},
   {"HELEN",59400},
   {"TEZ",72000},
   {"ANDY W",82160}
};

unsigned char menuStringWellDone[]="WELL DONE PLAYERx";
unsigned char menuStringHiScore[]="1)Abcdefg1234567";
unsigned char menuStringSparkingBombs[]="xx";
unsigned char menuStringBonus[]="BONUS x0000";

const unsigned char menuInksPen10[]={1,4,17,8,7,6,15,24,25,26,19,21,20,10,2};
const unsigned char menuInksPen14[]={26,0};
const unsigned char menuInksPen15[]={2,6,8};

CommonCpcColorSequences colorSequencesMenu=
{
   3,
   {
      {10,menuInksPen10,sizeof(menuInksPen10),2},
      {14,menuInksPen14,sizeof(menuInksPen14),2},
      {15,menuInksPen15,sizeof(menuInksPen15),1}
   }
};

const CommonSprite menuSpritesTitre[]=
{

   // Mise en place du "BOMB"
   {
      8|(2<<10)|(1<<9)|(1<<8),         // OBJ window, Double size, Rotation & scaling
      20|(2<<14)|(0<<9),               // 32x32, Rotation/Scaling Parameter #0
      0,                               // Character name=0
      128                              // Rotation/Scaling Parameter #0 (PA)
   },
   {
      8|(2<<10)|(2<<14)|(1<<9)|(1<<8), // OBJ window, Vertical Rectangle, Double size, Rotation & scaling
      84|(1<<14)|(0<<9),               // 8x32, Rotation/Scaling Parameter #0
      4,                               // Character name=3
      0                                // Rotation/Scaling Parameter #0 (PB)
   },

   // Mise en place du portrait
   {
      24|(2<<10),                      // OBJ window
      100|(2<<14),                     // 32x32
      5,                               // Character name=5
      0                                // Rotation/Scaling Parameter #0 (PC)
   },
   {
      24|(2<<10)|(2<<14),              // OBJ window, Vertical Rectangle
      132|(1<<14),                     // 8x32
      9,                               // Character name=9
      256                              // Rotation/Scaling Parameter #0 (PD)
   },

   // Mise en place du "JACK"
   {
      8|(2<<10)|(1<<9)|(1<<8),         // OBJ window, Double size, Rotation & scaling
      140|(2<<14)|(0<<9),              // 32x32, Rotation/Scaling Parameter #0
      10,                              // Character name=10
      0                                // Rotation/Scaling Parameter #1 (PA)
   },
   {
      8|(2<<10)|(2<<14)|(1<<9)|(1<<8), // OBJ window, Vertical Rectangle, Double size, Rotation & scaling
      204|(1<<14)|(0<<9),              // 8x32, Rotation/Scaling Parameter #0
      14,                              // Character name=14
      0                                // Rotation/Scaling Parameter #1 (PB)
   }
};

//////////////
// MenuInit //
//////////////
static void MenuInit(void)
{
   unsigned char pen;

   // Initialisation de la palette
   for(pen=0;pen<16;++pen)
      PALRAM[pen]=0;

   // Mise en place des sprites (titre "Bomb Jack")
   CommonSpritesInit();
   CommonDmaCopy((void*)menuSpritesTitre,(void*)commonSprites,sizeof(menuSpritesTitre)/4,DMA_32NOW);

   // Affichage
   CommonSpritesDisplay();
   REG_WINOUT=(1<<11)|(1<<3)|(1<<2); // On n'affiche pas le BG2 a l'interieur de la fenetre OBJ
   REG_DISPCNT=BG2_ENABLE|BG3_ENABLE|OBJ_ENABLE|OBJ_WIN_ENABLE|OBJ_2D;
}

///////////////////////
// MenuPaletteUpdate //
///////////////////////
static unsigned short MenuPaletteUpdate(unsigned char* timer,unsigned short* keys)
{
   unsigned char pen;
   unsigned short color,synthesis;

   // Memorise la valeur courante du registre des touches
   *keys=REG_KEYS;

   // Rotation des couleurs de 1 a 9
   synthesis=0;
   for(pen=1;pen<10;++pen)
   {
      color=PALRAM[pen+1];
      PALRAM[pen]=color;
      synthesis|=color;
   }

   // Modification des couleurs 10, 14 et 15
   CommonCpcPaletteRotate(&colorSequencesMenu,*timer);
   synthesis|=PALRAM[10];

   // Attente du retour du balayage vertical
   CommonVwait(3);

   // Retrouve les touches qui viennent d'etre pressees
   *keys&=~REG_KEYS;

   // Gestion du timer
   if(*timer)
      --*timer;

   // Retourne la synthese des couleurs de 1 a 10
   return(synthesis);
}

/////////////////////
// MenuHiScoreInit //
/////////////////////
void MenuHiScoreInit(void)
{
   if(!(REG_KEYS&(KEY_A|KEY_B)) || !CommonSramRead('A',(unsigned char*)&menuHiScore))
   {
      CommonDmaCopy((void*)menuHiScoreDefault,(void*)menuHiScore,sizeof(menuHiScoreDefault)/4,DMA_32NOW);
      CommonSramWrite('A',(unsigned char*)&menuHiScore,sizeof(menuHiScore));
   }
}

//////////////////////
// MenuHiScoreWrite //
//////////////////////
static void MenuHiScoreWrite(unsigned char* destAddress,unsigned long score)
{
   unsigned char* sourceAddress;
   unsigned char digit;

   sourceAddress=menuStringHiScore+sizeof(menuStringHiScore)-2;
   do
   {
      digit=score%10;
      *sourceAddress--=digit+'0';
      score=(score-digit)/10;
   }
   while(score && destAddress<=sourceAddress);
   while(destAddress<=sourceAddress)
      *destAddress++=' ';
}

//////////////////////
// MenuHiScoreInput //
//////////////////////
static void MenuHiScoreInput(signed char rank,unsigned char numPlayer)
{
   unsigned char character,oldCharacter;
   unsigned char position,oldPosition;
   unsigned char timer;
   unsigned short keys;

   // Deplacement de toutes les entrees dont le score est moins bon
   if(rank>0)
      CommonDmaCopy((void*)&menuHiScore[1],(void*)&menuHiScore[0],rank*(sizeof(MenuHiScore)/4),DMA_32NOW);

   // Memorisation du score
   menuHiScore[rank].score=gamePData.player[numPlayer].score;

   // Affichage de l'ecran d'entree du nom
   menuStringWellDone[16]='1'+numPlayer;
   MenuHiScoreWrite(&menuStringHiScore[9],menuHiScore[rank].score);

   CommonCpcMaskCleanAll(11);
   CommonCpcMaskWriteString(0,1,menuStringWellDone,0);
   CommonCpcMaskWriteString(0,3,"Your great score",0);
   CommonCpcMaskWriteString(0,4,"of",0);
   CommonCpcMaskWriteString(3,4,&menuStringHiScore[9],15);
   CommonCpcMaskWriteString(11,4,"means",0);
   CommonCpcMaskWriteString(0,5,"you are in with",0);
   CommonCpcMaskWriteString(0,6,"the Best Bombers.",0);
   CommonCpcMaskWriteString(1,8,"Enter your name",0);

   // Initialisation du nom
   oldCharacter=' ';
   for(oldPosition=0;oldPosition<=6;++oldPosition)
      menuHiScore[rank].name[oldPosition]=oldCharacter;

   character='A';
   position=0;

   // Boucle principale du dialogue d'entree du nom
   timer=200;
   while(MenuPaletteUpdate(&timer,&keys))
   {
      // Termine ?
      if((keys&KEY_START) || ((keys&KEY_A) && position==6))
         timer=0;
      else if(keys)
         timer=200;

      // Choix d'un nouveau caractere ?
      if(keys&(KEY_UP|KEY_SELECT))
      {
         if(character>='A' && character<'Z')
            ++character;
         else if(character==' ' || !position)
            character='A';
         else
            character=' ';
      }
      else if(keys&KEY_DOWN)
      {
         if(character>'A')
            --character;
         else if(character==' ' || !position)
            character='Z';
         else
            character=' ';
      }

      if(character!=oldCharacter)
      {
         // Affichage du nouveau caractere
         oldCharacter=character;
         menuHiScore[rank].name[position]=character;
         CommonCpcMaskCleanChar(5+position,9,11);
         CommonCpcMaskWriteString(5,9,menuHiScore[rank].name,15);
      }

      // Changement de la position du curseur ?
      if((keys&(KEY_LEFT|KEY_B)) && position>0)
         --position;
      else if((keys&(KEY_RIGHT|KEY_A)) && position<6)
         ++position;

      if(position!=oldPosition)
      {
         // Affichage du curseur de position
         CommonCpcMaskCleanChar(5+oldPosition,10,11);
         oldPosition=position;
         CommonCpcMaskWriteString(5+position,10,"\x5e",14);
         character=menuHiScore[rank].name[position];
         oldCharacter=character;
      }
   }

   // Optimisation de la chaine de caracteres
   for(position=6;menuHiScore[rank].name[position]==' ';--position);
   menuHiScore[rank].name[++position]='\0';

   // Sauvegarde des nouvelles donnees
   CommonSramWrite('A',(unsigned char*)&menuHiScore,sizeof(menuHiScore));
}

////////////////////////
// MenuHiScoreDisplay //
////////////////////////
static inline void MenuHiScoreDisplay(unsigned char rankFlags)
{
   unsigned char entry,counter;
   unsigned char* destAddress;
   unsigned char* sourceAddress;
   unsigned char pen;

   CommonCpcMaskWriteString(3,1,"BEST BOMBERS",0);
   for(entry=0;entry<8;++entry)
   {
      destAddress=menuStringHiScore;

      // Rang
      *destAddress='8'-entry;
      destAddress+=2;

      // Nom
      sourceAddress=menuHiScore[entry].name;
      for(counter=0;*sourceAddress!='\0';++counter)
         *destAddress++=*sourceAddress++;

      // Score
      MenuHiScoreWrite(destAddress,menuHiScore[entry].score);

      // Affichage de la chaine
      if(rankFlags&(1<<entry))
         pen=14;
      else
         pen=0;
      CommonCpcMaskWriteString(0,10-entry,menuStringHiScore,pen);
   }
}

//////////////
// MenuMain //
//////////////
void MenuMain(void)
{
   static unsigned char rankFlags=0;
   unsigned char numPlayer;
   signed char rank;
   unsigned char phase,timer;
   unsigned short keys;

   // Mise en place du menu
   MenuInit();

   // Verification du score de chaque joueur
   if(gamePData.numPlayers)
   {
      rankFlags=0;
      for(numPlayer=0;numPlayer<gamePData.numPlayers;++numPlayer)
         for(rank=7;rank>=0;--rank)
            if(menuHiScore[rank].score<=gamePData.player[numPlayer].score)
            {
               // Ajout de cette nouvelle entree
               MenuHiScoreInput(rank,numPlayer);

               // Memorisation du rang pour affichage du tableau des high scores
               if(rankFlags<=(1<<rank))
                  rankFlags>>=1;
               rankFlags|=1<<rank;
               break;
            }
      gamePData.numPlayers=0;
      phase=1;
   }
   else
      phase=0;

   // Boucle principale du menu
   timer=0;
   while(1)
   {
      // Modification des couleurs
      if(!MenuPaletteUpdate(&timer,&keys))
      {
         // On sort du menu ?
         if(phase>=5)
            return;

         // Reset du timer
         timer=120;

         // Nettoyage du cache
         CommonCpcMaskCleanAll(11);

         // Affichage du menu principal / du tableau des high scores
         if(++phase&1)
         {
            CommonCpcMaskWriteString(2,0,"Licensed From",0);
            CommonCpcMaskWriteString(1,1,"Tekhan (C) 1985",0);
            CommonCpcMaskWriteString(1,3,"PRESS:",0);
            CommonCpcMaskWriteString(1,4,"A - One Player",0);
            CommonCpcMaskWriteString(1,5,"B - Two Players",0);
            CommonCpcMaskWriteString(1,7,"SELECT OPTION:",0);
            CommonCpcMaskWriteString(2,8,"- Normal",15-gamePData.keyMode);
            CommonCpcMaskWriteString(2,9,"- Turbo",gamePData.keyMode);
         }
         else
            MenuHiScoreDisplay(rankFlags);
      }

      // Gestion des touches
      if(keys&(KEY_START|KEY_A|KEY_B))
      {
         timer=0;
         if(phase&1)
         {
            if(keys&KEY_B)
               gamePData.numPlayers=2;
            else
               gamePData.numPlayers=1;
            phase=5;
         }
      }
      else if(phase&1 && keys&(KEY_UP|KEY_DOWN|KEY_SELECT))
      {
         if(keys&KEY_UP)
            gamePData.keyMode=0;
         else if(keys&KEY_DOWN)
            gamePData.keyMode=15;
         else
            gamePData.keyMode^=15;
         CommonCpcMaskWriteString(2,8,"- Normal",15-gamePData.keyMode);
         CommonCpcMaskWriteString(2,9,"- Turbo",gamePData.keyMode);
      }
   }
}

///////////////
// MenuBonus //
///////////////
void MenuBonus(GamePlayer* player)
{
   unsigned char timer;
   unsigned short keys;

   // Verification du nombre de "sparking bombs"
   if(player->bombs.sparkingNb<20)
      return;

   // Affichage de l'ecran bonus
   menuStringSparkingBombs[0]='0'+(player->bombs.sparkingNb/10);
   menuStringSparkingBombs[1]='0'+(player->bombs.sparkingNb%10);

   if(player->bombs.sparkingNb>=23)
   {
      player->score+=50000;
      menuStringBonus[6]='5';
   }
   else if(player->bombs.sparkingNb==22)
   {
      player->score+=30000;
      menuStringBonus[6]='3';
   }
   else if(player->bombs.sparkingNb==21)
   {
      player->score+=20000;
      menuStringBonus[6]='2';
   }
   else
   {
      player->score+=10000;
      menuStringBonus[6]='1';
   }

   CommonCpcMaskCleanAll(11);
   CommonCpcMaskWriteString(1,2,"Well done ! You",0);
   CommonCpcMaskWriteString(1,3,"got",0);
   CommonCpcMaskWriteString(5,3,menuStringSparkingBombs,15);
   CommonCpcMaskWriteString(8,3,"sparking",0);
   CommonCpcMaskWriteString(1,4,"bombs.",0);
   CommonCpcMaskWriteString(3,7,menuStringBonus,15);

   // Mise en place du menu
   MenuInit();

   // Boucle d'attente
   timer=80;
   while(MenuPaletteUpdate(&timer,&keys))
      if(keys&(KEY_START|KEY_A|KEY_B))
         timer=0;
}
