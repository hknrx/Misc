/*
** God - Sources\World\World.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include "..\Common\Common.h"
#include "3dIso\3dIso.h"
#include "AStar\AStar.h"

////////////
// Macros //
////////////
#define TIME_OUT_FADE 6

#define MAP_WIDTH_SHIFT 6
#define MAP_WIDTH       (1<<MAP_WIDTH_SHIFT)
#define MAP_WIDTH_MASK  (MAP_WIDTH-1)

#define MAP_HEIGHT_SHIFT 6
#define MAP_HEIGHT       (1<<MAP_HEIGHT_SHIFT)

#define MAP_WALL_SOFT_A      1
#define MAP_WALL_SOFT_B      6
#define MAP_WALL_HARD        5
#define MAP_CASTLE_DOOR      2
#define MAP_CASTLE_WINDOW    3
#define MAP_CASTLE_WALL      4
#define MAP_EMPTY            0
#define MAP_GROUND_NOTHING_A -1
#define MAP_GROUND_NOTHING_B -2
#define MAP_GROUND_START     -3
#define MAP_GROUND_GOAL      -4
#define MAP_GROUND_PATH_A    -5
#define MAP_GROUND_PATH_B    -6

#define NUMBER_TILES_CEILING 6

///////////
// Types //
///////////
typedef struct
{
   signed char* map;
   Path* path;
   signed short closeCounter;
}
World;

typedef struct
{
   unsigned char nbPhases;
   struct
   {
      unsigned short timeOut;
      unsigned char nbStrings;
   }
   phase[];
}
Presentation;

////////////////////////
// Variables globales //
////////////////////////
extern const Sound ADPCM_EffectAmbiant01;
extern const Sound ADPCM_EffectAmbiant02;
extern const Sound ADPCM_EffectAmbiant03;
extern const Sound ADPCM_EffectPutBloc;
extern const Sound ADPCM_EffectRemoveBloc;
extern const Sound ADPCM_EffectStartGame;
extern const Sound ADPCM_MusicAmbiant01;
extern const Sound ADPCM_MusicAmbiant02;
extern const Sound ADPCM_MusicAmbiant03;
extern const Sound ADPCM_MusicAmbiant04;

const Sound* musicAmbiant[]={&ADPCM_MusicAmbiant01,
                             &ADPCM_MusicAmbiant02,
                             &ADPCM_MusicAmbiant03,
                             &ADPCM_MusicAmbiant04};

const Sound* effectAmbiant[]={&ADPCM_EffectAmbiant01,
                              &ADPCM_EffectAmbiant02,
                              &ADPCM_EffectAmbiant03};

World world;

const unsigned char* presentationString[]={"WELCOME TO THE ORDINARY",
                                           "DUNGEON, ANGEL.",

                                           "THIS IS THE PLACE WHERE YOU",
                                           "WILL BE TRAINED TO BECOME A",
                                           "GOD AND EVENTUALLY RULE A",
                                           "WORLD...",

                                           "BEST STUDENTS MAY ACCESS THE",
                                           "ADVANCED DUNGEON AND BE",
                                           "RESPONSIBLE OF IMPORTANT",
                                           "PLANETS SUCH AS KRAGLOS OR",
                                           "PWALINIZ,",

                                           "IDIOTS WILL DIRECTLY BE",
                                           "AFFECTED TO MINOR WORLDS",
                                           "SUCH AS THE EARTH OR MARS!",

                                           "GOOD LUCK, ANGEL...",

                                           "MAY I REMIND YOU THAT THE",
                                           "[L] AND [R] KEYS CAN BE USED",
                                           "TOGETHER WITH THE ARROWS TO",
                                           "CONTROL THE CAMERA?",

                                           "YOU PROBABLY ALREADY KNOW",
                                           "THAT [A] SHALL BE PRESSED TO",
                                           "PUT OR REMOVE A BLOCK, DON'T",
                                           "YOU?",

                                           "HOPEFULLY THE [START] KEY",
                                           "WILL POP UP A MENU TO LET",
                                           "YOU GO HAVE A REST... (USE",
                                           "[SELECT] TO MAKE YOUR",
                                           "CHOICE)"};

const Presentation presentation={8,{{80,2},{20,4},{20,5},{20,3},{20,1},{300,4},{600,4},{600,5}}};

///////////////////
// WorldIsGround //
///////////////////
unsigned char CODE_IN_IWRAM WorldIsGround(signed short mapIdx)
{
   signed char mapValue;

   // Is that a piece of the ground?
   mapValue=world.map[mapIdx];
   if(mapValue<0)
      return(NUMBER_TILES_CEILING-mapValue);

   // It's a wall...
   return(0);
}

/////////////////
// WorldIsWall //
/////////////////
unsigned char CODE_IN_IWRAM WorldIsWall(signed short mapIdx)
{
   signed char mapValue;

   // Is that a wall?
   mapValue=world.map[mapIdx];
   if(mapValue>0)
      return(mapValue);

   // No wall here...
   return(0);
}

///////////////
// WorldInit //
///////////////
void WorldInit(void)
{
   world.map=(signed char*)malloc((MAP_HEIGHT<<MAP_WIDTH_SHIFT)*sizeof(signed char));
   IsoInit((unsigned char (*)(signed short))WorldIsGround,(unsigned char (*)(signed short))WorldIsWall,MAP_WIDTH_SHIFT,MAP_HEIGHT_SHIFT);
   AStarInit((unsigned char (*)(signed short))WorldIsGround,MAP_WIDTH_SHIFT,MAP_HEIGHT);
   world.path=AStarPathInit(256);
}

//////////////////
// WorldDestroy //
//////////////////
void WorldDestroy(void)
{
   AStarPathDestroy(world.path);
   AStarDestroy();
   IsoDestroy();
   free(world.map);
}

////////////////////
// WorldCreateMap //
////////////////////
void WorldCreateMap(void)
{
   signed short idx;
   unsigned short x,y;

   // Initialize the random numbers generator
   srand(vblCounter);

   // Create the map
   idx=2+(2<<MAP_WIDTH_SHIFT);
   for(y=2;y<MAP_HEIGHT-2;++y)
   {
      for(x=2;x<MAP_WIDTH-2;++x)
      {
         if((x&y&1) || (((x^y)&1) && (rand()&3)<2))
            world.map[idx]=MAP_WALL_SOFT_A;
         else
            world.map[idx]=MAP_GROUND_NOTHING_A;
         ++idx;
      }
      idx+=4;
   }

   // Put the castle in the middle of the map
   idx=(MAP_WIDTH/2)+((MAP_HEIGHT/2)<<MAP_WIDTH_SHIFT);
   world.map[idx-1]=MAP_CASTLE_DOOR;
   world.map[idx]=MAP_CASTLE_WALL;
   world.map[idx+1]=MAP_CASTLE_WINDOW;
   world.map[idx-MAP_WIDTH]=MAP_CASTLE_WINDOW;
   world.map[idx+MAP_WIDTH]=MAP_CASTLE_WINDOW;
   world.map[idx-MAP_WIDTH-1]=MAP_CASTLE_WALL;
   world.map[idx-MAP_WIDTH+1]=MAP_CASTLE_WALL;
   world.map[idx+MAP_WIDTH-1]=MAP_CASTLE_WALL;
   world.map[idx+MAP_WIDTH+1]=MAP_CASTLE_WALL;

   // Add some walls (left and right)
   idx=0+(0<<MAP_WIDTH_SHIFT);
   for(y=0;y<MAP_HEIGHT-0;++y)
   {
      world.map[idx]=MAP_EMPTY;
      world.map[idx+1]=MAP_WALL_HARD;
      world.map[idx+MAP_WIDTH-2]=MAP_WALL_HARD;
      world.map[idx+MAP_WIDTH-1]=MAP_EMPTY;
      idx+=MAP_WIDTH;
   }

   // Add some walls (top and bottom)
   idx=1+(0<<MAP_WIDTH_SHIFT);
   for(x=1;x<MAP_WIDTH-1;++x)
   {
      world.map[idx]=MAP_EMPTY;
      world.map[idx+(1<<MAP_WIDTH_SHIFT)]=MAP_WALL_HARD;
      world.map[idx+((MAP_HEIGHT-2)<<MAP_WIDTH_SHIFT)]=MAP_WALL_HARD;
      world.map[idx+((MAP_HEIGHT-1)<<MAP_WIDTH_SHIFT)]=MAP_EMPTY;
      ++idx;
   }
}

//////////////////////////
// WorldCircleInterrupt //
//////////////////////////
void CODE_IN_IWRAM WorldCircleInterrupt(void)
{
   static unsigned short x;
   unsigned short y;
   signed short sin;
   unsigned char min,max,arcsin;

   // Modification des coordonnees horizontales de la fenetre pour la ligne suivante
   // Attention : il ne faut modifier ce parametre que durant le HBLANK !
   REG_WIN0H=((XO-x)<<8)|(XO+x);

   // Recupere l'ordonnee de la ligne courante et effectue le changement de repere necessaire
   // Note : on calcule les parametres de la fenetre 2 lignes en avance
   y=REG_DISPVCNT;

   if(y<YO-2)
      y=YO-1-2-y;
   else if(y<YM-2)
      y-=YO-2;
   else if(y>=228-2)
      y=YO-1+228-2-y;
   else
      return;

   // Calcul des coordonnees horizontales de la fenetre...
   if(y>=world.closeCounter)
      x=0;
   else
   {
      // Equations de base du cercle : x=r*COS(angle) et y=r*SIN(angle)
      // On obtient donc x : x=r*COS(ARCSIN(y/r))
      sin=((unsigned long)y*INVERSE_TABLE[world.closeCounter])>>(FIXED_POINT_INV_SHIFT-FIXED_POINT_SHIFT);

      // Recherche dichotomique de ARCSIN en utilisant le tableau SINE_TABLE
      min=0;
      arcsin=SINNB/8;
      max=SINNB/4;
      do
      {
         if(SINE_TABLE[arcsin]>=sin)
            max=arcsin;
         else
            min=arcsin;
         arcsin=(min+max)>>1;
      }
      while(arcsin!=min);
      x=(world.closeCounter*COS(arcsin))>>FIXED_POINT_SHIFT;

      // On limite la largeur a celle de l'ecran
      if(x>XO)
         x=XO;
   }
}

////////////////
// WorldClose //
////////////////
void WorldClose(void)
{
   // Prepare la fenetre 0
   REG_WININ=1|2|4|8|16; // Interieur de la fenetre 0 : BG0+BG1+BG2+BG3+OBJ (rien pour la fenetre 1)
   REG_WINOUT=0; // On n'affiche rien en dehors des fenetres 0 et 1 (ni rien pour l'interieur de la fenetre OBJ)
   REG_WIN0V=(0<<8)|YM; // Pas de contrainte verticale

   // On fixe le rayon avant la mise en place de l'interruption
   // Note : on doit commencer a "SQRT(XO*XO+YO*YO)", valeur du rayon pour laquelle le cercle
   // entoure parfaitement l'ecran ; avec XO=120 et YO=80 on obtient 144...
   world.closeCounter=144;

   // Mise en place l'interruption sur le retour de balayage horizontal (HBL)
   CommonInterruptSet(IT_HBLANK,(IntrFunction*)&WorldCircleInterrupt);

   // Active la fenetre 0
   REG_DISPCNT|=WIN0_ENABLE;

   // On affiche un cercle qui se retrecit (world.closeCounter represente son rayon)
   do
   {
      // Attente du retour du balayage vertical
      CommonVwait();

      // Le cercle retrecit...
      world.closeCounter-=2;
   }
   while(world.closeCounter>=0);

   // Desactive l'interruption sur HBL
   CommonInterruptDisable(IT_HBLANK);

   // Force l'ecran au noir avant de sortir (et desactive le fenetrage)
   REG_DISPCNT=0;
}

///////////////////////
// WorldTestFindPath //
///////////////////////
signed short WorldTestFindPath(signed short mapIdx,Goal* goal)
{
   signed short cost;
   signed short newMapIdx;

   if((cost=AStarPathFind(mapIdx,goal,world.path))>0)
   {
      while((newMapIdx=AStarPathMove(world.path,mapIdx))!=-1)
      {
         mapIdx=newMapIdx;
         if(world.map[mapIdx]==MAP_GROUND_NOTHING_A)
            world.map[mapIdx]=MAP_GROUND_PATH_A;
         else
            world.map[mapIdx]=MAP_GROUND_PATH_B;
         IsoMapModify(mapIdx);
      }
      world.map[mapIdx]=MAP_GROUND_GOAL;
      IsoMapModify(mapIdx);
   }
   return(cost);
}

/////////////////////////
// WorldTestRemovePath //
/////////////////////////
void WorldTestRemovePath(signed short mapIdx,Goal* goal)
{
   signed short newMapIdx;

   AStarPathRestore(world.path);
   while((newMapIdx=AStarPathMove(world.path,mapIdx))!=-1)
   {
      mapIdx=newMapIdx;
      if(world.map[mapIdx]==MAP_GROUND_PATH_A)
         world.map[mapIdx]=MAP_GROUND_NOTHING_A;
      else
         world.map[mapIdx]=MAP_GROUND_NOTHING_B;
      IsoMapModify(mapIdx);
   }
   world.map[mapIdx]=MAP_GROUND_GOAL;
   IsoMapModify(mapIdx);
}

//////////////////////////////
// WorldDisplayPresentation //
//////////////////////////////
void WorldDisplayPresentation(unsigned short* timeOut,unsigned char* phase,unsigned char* stringNumber)
{
   unsigned char nbStrings,line;

   // Gere le timer
   if(++(*timeOut)<presentation.phase[*phase].timeOut)
      return;
   *timeOut=0;

   // Recupere le nombre de chaines a afficher et change de phase
   nbStrings=presentation.phase[(*phase)++].nbStrings;

   // Efface le menu
   IsoMenuChangeBg(0);
   IsoMenuClean(1,nbStrings+1);

   // Affiche les chaines
   for(line=1;line<=nbStrings;++line)
      IsoMenuWriteString(1,line,presentationString[(*stringNumber)++]);

   // Met en place le partage ecran (note : le timer est proportionnel au nombre de lignes)
   IsoSplitSet(line<<6,YM-4-(line<<3));
}

////////////////
// WorldSound //
////////////////
inline void WorldSound(void)
{
   if(!AdpcmStatus(0))
      AdpcmStart(musicAmbiant[rand()%(sizeof(musicAmbiant)/sizeof(musicAmbiant[0]))],1,0);
   if(!(vblCounter&1023) && !AdpcmStatus(1))
      AdpcmStart(effectAmbiant[rand()%(sizeof(effectAmbiant)/sizeof(effectAmbiant[0]))],1,1);
}

///////////////
// WorldMain //
///////////////
void WorldMain(void)
{
   signed long x,dx,z,dz;
   signed long zoom;
   unsigned char Rx,Ry;
   signed char phase;
   unsigned char fadeValue,fadeTimeOut;
   unsigned short presentationTimeOut;
   unsigned char presentationPhase,presentationStringNumber;
   unsigned short keys;
   Goal* goal;
   signed short mapIdx,startMapIdx;
   signed short cost;
   signed short xPointer,yPointer,pointer;
   unsigned char modifRy,modifZoom;

   // Preparation du fading
   REG_BLDMOD=BLEND_BG0|BLEND_BG1|BLEND_BG2|BLEND_BG3|BLEND_OBJ|BLEND_BD|BLEND_BLACK;
   fadeValue=16;
   REG_BLD_FAD=fadeValue;

   // Initialisation du moteur
   WorldInit();

   // Generation et mise en place d'une nouvelle carte
   WorldCreateMap();
   IsoMapSet();

   // Sequence de presentation
   x=(MAP_WIDTH+1)<<(FIXED_POINT_SHIFT+WALL_WIDTH_SHIFT-1);
   z=(MAP_HEIGHT+1)<<(FIXED_POINT_SHIFT+WALL_WIDTH_SHIFT-1);

   Rx=RX_MIN;
   Ry=0;
   zoom=ZOOM_HIGH;

   phase=0;
   fadeTimeOut=0;
   presentationTimeOut=0;
   presentationPhase=0;
   presentationStringNumber=0;
   do
   {
      // Gestion de la musique et des effets d'ambiance
      WorldSound();

      // Affichage de la vue en 3D isometrique
      keys=REG_KEYS;
      IsoDisplay(x,z,Rx,Ry,zoom,0,YM,0);
      keys&=~REG_KEYS;

      // Rotation (automatique)
      ++Ry;

      // Gestion du fading et du zoom
      switch(phase)
      {
         case 0:
            // Fade in
            if(++fadeTimeOut>=TIME_OUT_FADE)
            {
               if(--fadeValue)
               {
                  REG_BLD_FAD=fadeValue;
                  fadeTimeOut=0;
               }
               else
               {
                  REG_BLDMOD=BLEND_NO;
                  phase=1;
               }
            }

         case 1:
            // Zoom in
            if(zoom>ZOOM_MIN+0.004*FIXED_POINT)
               zoom-=0.004*FIXED_POINT;
            else if(phase==1)
               phase=2;
            break;

         case 2:
            // Gestion du menu (presentation)
            if(keys&KEY_START)
            {
               while(presentationPhase<5)
                  presentationStringNumber+=presentation.phase[presentationPhase++].nbStrings;
               IsoSplitSet(0,YM);
               phase=3;
            }
            else if(IsoSplitGetValue()==YM)
            {
               if(presentationPhase==5)
                  phase=3;
               else
                  WorldDisplayPresentation(&presentationTimeOut,&presentationPhase,&presentationStringNumber);
            }
            else if(keys&KEY_A)
               IsoSplitSet(0,YM);
            break;

         case 3:
            // Effet pour le debut du jeu...
            AdpcmStart(&ADPCM_EffectStartGame,1,1);
            phase=4;

         case 4:
            // Zoom out
            if(zoom<ZOOM_LOW)
               zoom+=0.01*FIXED_POINT;
            else
               phase=-1;
            break;
      }
   }
   while(phase!=-1);

   // Testons un peu notre AStar... On definit d'abord les cibles
   goal=AStarGoalInit(4);

   mapIdx=2+(2<<MAP_WIDTH_SHIFT);
   world.map[mapIdx]=MAP_GROUND_GOAL;
   AStarGoalAdd(goal,mapIdx);
   IsoMapModify(mapIdx);

   mapIdx=(MAP_WIDTH-4)+(2<<MAP_WIDTH_SHIFT);
   world.map[mapIdx]=MAP_GROUND_GOAL;
   AStarGoalAdd(goal,mapIdx);
   IsoMapModify(mapIdx);

   mapIdx=2+((MAP_HEIGHT-4)<<MAP_WIDTH_SHIFT);
   world.map[mapIdx]=MAP_GROUND_GOAL;
   AStarGoalAdd(goal,mapIdx);
   IsoMapModify(mapIdx);

   mapIdx=(MAP_WIDTH-4)+((MAP_HEIGHT-4)<<MAP_WIDTH_SHIFT);
   world.map[mapIdx]=MAP_GROUND_GOAL;
   AStarGoalAdd(goal,mapIdx);
   IsoMapModify(mapIdx);

   // On definit ensuite le point de depart (on se place juste devant la porte du chateau)
   startMapIdx=((MAP_WIDTH/2)-2)|((MAP_HEIGHT/2)<<MAP_WIDTH_SHIFT);
   world.map[startMapIdx]=MAP_GROUND_START;
   IsoMapModify(startMapIdx);

   // Recherche du chemin...
   cost=WorldTestFindPath(startMapIdx,goal);

   // On donne le control au joueur...
   xPointer=XO;
   yPointer=YO;
   pointer=0;

   modifRy=0;
   modifZoom=0;

   phase=0;
   do
   {
      // Gestion de la musique et des effets d'ambiance
      WorldSound();

      // Gestion du menu (arret du jeu)
      if(!phase)
      {
         if(IsoSplitGetValue()==YM)
         {
            if(keys&KEY_START)
            {
               IsoMenuChangeBg(1);
               IsoMenuClean(1,4);
               IsoMenuWriteString(1,1,"ARE YOU TIRED ANGEL?");
               IsoMenuWriteString(1,2,"@ NO, I'M FINE (CONTINUE)");
               IsoMenuWriteString(3,3,"PLEASE LET ME GO!");
               IsoSplitSet(4<<6,YM-4-(4<<3));
               phase=1;
            }
            else if(presentationPhase<presentation.nbPhases)
               WorldDisplayPresentation(&presentationTimeOut,&presentationPhase,&presentationStringNumber);
         }
         else if(keys&KEY_START)
            IsoSplitSet(0,YM);
      }
      else if(IsoSplitGetValue()==YM)
         phase=0;
      else if(keys&KEY_SELECT)
      {
         IsoSplitSet(4<<6,YM-4-(4<<3));
         IsoMenuWriteString(1,phase+1," ");
         phase=3-phase;
         IsoMenuWriteString(1,phase+1,"@");
      }
      else if(keys&KEY_START)
      {
         if(phase==1)
            IsoSplitSet(0,YM);
         else
            phase=-1;
      }

      // Deplacement
      switch((~REG_KEYS)&(KEY_R|KEY_L))
      {
         // Touches L et R relachees : deplacement du pointeur
         case 0:
            pointer=0;

            // On peut bouger le pointeur... ou la camera si on touche le bord de l'ecran
            if(!(REG_KEYS&KEY_LEFT))
            {
               if(xPointer>=2)
                  xPointer-=2;
               else
                  pointer=14;
            }
            else if(!(REG_KEYS&KEY_RIGHT))
            {
               if(xPointer<XM-2)
                  xPointer+=2;
               else
                  pointer=15;
            }
            if(!(REG_KEYS&KEY_UP))
            {
               if(yPointer>=2)
                  yPointer-=2;
               else if(pointer)
                  pointer+=2;
               else
                  pointer=12;
            }
            else if(!(REG_KEYS&KEY_DOWN))
            {
               if(yPointer<YM-2)
                  yPointer+=2;
               else if(pointer)
                  pointer+=4;
               else
                  pointer=13;
            }

            // Dans certains cas on doit faire une translation, dans d'autres on a (presque) termine
            if(!pointer)
            {
               // Par defaut on prend un des pointeurs "normaux"
               if(xPointer>3*XM/4)
                  pointer=1;
               if(yPointer>3*YM/4)
                  pointer|=2;

               // On verifie ce qu'il se trouve a cet endroit
               if(mapIdx==-1)
                  pointer+=8;
               else
                  switch(world.map[mapIdx])
                  {
                     case MAP_GROUND_NOTHING_A:
                     case MAP_GROUND_NOTHING_B:
                     case MAP_GROUND_PATH_A:
                     case MAP_GROUND_PATH_B:
                     case MAP_WALL_SOFT_A:
                        break;

                     case MAP_WALL_SOFT_B:
                        // On verifie si oui ou non on peut construire a cet endroit...
                        if(1)
                           pointer+=4;
                        break;

                     default:
                        pointer+=8;
                        break;
                  }

               // On en a termine avec les deplacements
               break;
            }

         // Touche R : translations
         case KEY_R:
            if(!(REG_KEYS&KEY_R))
               pointer=20;

            // Translations horizontales
            if(pointer==12 || pointer==13 || (REG_KEYS&(KEY_LEFT|KEY_RIGHT))==(KEY_LEFT|KEY_RIGHT))
            {
               dx=0;
               dz=0;
            }
            else if(!(REG_KEYS&KEY_LEFT))
            {
               dx=COS(Ry);
               dz=SIN(Ry);
            }
            else
            {
               dx=-COS(Ry);
               dz=-SIN(Ry);
            }

            // Translations verticales
            if(pointer!=14 && pointer!=15)
            {
               if(!(REG_KEYS&KEY_UP))
               {
                  dx-=SIN(Ry);
                  dz+=COS(Ry);
               }
               else if(!(REG_KEYS&KEY_DOWN))
               {
                  dx+=SIN(Ry);
                  dz-=COS(Ry);
               }
            }

            // Effectue le deplacement
            if((x>=3<<(FIXED_POINT_SHIFT+WALL_WIDTH_SHIFT) && dx>0) || (x<(MAP_WIDTH-3)<<(FIXED_POINT_SHIFT+WALL_WIDTH_SHIFT) && dx<0))
               x-=(dx*zoom)>>(FIXED_POINT_SHIFT-1);
            if((z>=3<<(FIXED_POINT_SHIFT+WALL_WIDTH_SHIFT) && dz>0) || (z<(MAP_HEIGHT-3)<<(FIXED_POINT_SHIFT+WALL_WIDTH_SHIFT) && dz<0))
               z-=(dz*zoom)>>(FIXED_POINT_SHIFT-1);
            break;

         // Touche L : rotation Ry et zoom
         case KEY_L:
            pointer=21;

            if(!(REG_KEYS&KEY_LEFT))
               --Ry;
            else if(!(REG_KEYS&KEY_RIGHT))
               ++Ry;
            if(!(REG_KEYS&KEY_UP) && zoom>ZOOM_LOW+0.02*FIXED_POINT)
               zoom-=0.02*FIXED_POINT;
            else if(!(REG_KEYS&KEY_DOWN) && zoom<ZOOM_MAX)
               zoom+=0.02*FIXED_POINT;
            break;

         // Touches L et R : rotations Rx & Ry
         default:
            pointer=22;

            if(!(REG_KEYS&KEY_LEFT))
               --Ry;
            else if(!(REG_KEYS&KEY_RIGHT))
               ++Ry;
            if(!(REG_KEYS&KEY_UP) && Rx>RX_MIN)
               --Rx;
            else if(!(REG_KEYS&KEY_DOWN) && Rx<RX_MAX)
               ++Rx;
            break;
      }

      // Affichage de la vue en 3D isometrique (et du pointeur ecran)
      keys=REG_KEYS;
      if(modifRy)
      {
         mapIdx=IsoDisplay(x,z,Rx,Ry+(modifRy&3),zoom,xPointer,yPointer,pointer);
         --modifRy;
      }
      else if(modifZoom)
      {
         mapIdx=IsoDisplay(x,z,Rx,Ry,zoom+(SIN(modifZoom)>>5),xPointer,yPointer,pointer);
         modifZoom-=SINNB/16;
      }
      else
      {
         // Tout d'abord on gere l'ajout et la suppression de bloc
         if(!(REG_KEYS&KEY_A) && pointer<8)
         {
            // On supprime d'abord le chemin existant
            if(cost>0)
               WorldTestRemovePath(startMapIdx,goal);

            // On modifie la carte en fonction de ce qu'il se trouve a cet endroit
            if(world.map[mapIdx]<0)
            {
               world.map[mapIdx]=MAP_WALL_SOFT_B;
               modifZoom=SINNB/2;

               AdpcmStart(&ADPCM_EffectPutBloc,1,1);
            }
            else
            {
               if(world.map[mapIdx]==MAP_WALL_SOFT_A)
                  world.map[mapIdx]=MAP_GROUND_NOTHING_A;
               else
                  world.map[mapIdx]=MAP_GROUND_NOTHING_B;
               modifRy=8;

               AdpcmStart(&ADPCM_EffectRemoveBloc,1,1);
            }

            // On recherche un nouveau chemin...
            cost=WorldTestFindPath(startMapIdx,goal);

            // Maintenant on met a jour la map affichee
            IsoMapModify(mapIdx);
         }

         // Affichage normal
         mapIdx=IsoDisplay(x,z,Rx,Ry,zoom,xPointer,yPointer,pointer);
      }
      keys&=~REG_KEYS;
   }
   while(phase!=-1);

   // Sequence de fin (cercle qui se ferme)
   WorldClose();

   // Arret de la musique et des sons
   AdpcmStop(0);
   AdpcmStop(1);

   // Liberations memoire
   AStarGoalDestroy(goal);
   WorldDestroy();
}
