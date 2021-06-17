/*
** Mister Jelly - Sources\Game\Game.c
** Nicolas ROBERT [NRX] - France 2006
*/

////////////////
// Inclusions //
////////////////
#include "..\Common\Common.h"
#include "Blob\Blob.h"

////////////
// Macros //
////////////
#define GAME_CAMERA_MOVE_SHIFT   2
#define GAME_CAMERA_CENTER_SHIFT 4

#define GAME_BLOB_STIFFNESS (signed long)(FIXED_POINT*0.40)
#define GAME_BLOB_DAMPING   (signed long)(FIXED_POINT*0.08)
#define GAME_BLOB_LENGTH    (signed long)(FIXED_POINT*6.00)
#define GAME_BLOB_MASS      (signed long)(FIXED_POINT*1.00)
#define GAME_BLOB_PRESSION  (signed long)(FIXED_POINT*20.00)

#define GAME_FORCE_GRAVITY (signed long)(FIXED_POINT*0.10)
#define GAME_FORCE_JUMP    (signed long)(-FIXED_POINT*4.00)

////////////////////////
// Variables globales //
////////////////////////
extern const unsigned char Sprites_Bitmap[];
extern const unsigned short Sprites_Palette[];
extern const unsigned char Background_Tiles[];
extern const unsigned char Background_Map[];
extern const unsigned short Background_Palette[];

//////////////
// GameInit //
//////////////
void GameInit(void)
{
   // Chargement des sprites
   CommonUncompressInVRAM((void*)Sprites_Bitmap,(void*)OBJ_TILES);
   CommonDmaCopy((void*)Sprites_Palette,(void*)OBJ_PALRAM,256/2,DMA_32NOW);

   // Mise en place du background
   REG_BG2CNT=BG_COLORS_256|ROTBG_SIZE_256x256|(0<<CHAR_SHIFT)|(31<<SCREEN_SHIFT)|3;

   CommonUncompressInVRAM((void*)Background_Tiles,(void*)CHAR_BASE_BLOCK(0));
   CommonUncompressInVRAM((void*)Background_Map,(void*)SCREEN_BASE_BLOCK(31));
   CommonDmaCopy((void*)Background_Palette,(void*)PALRAM,256/2,DMA_32NOW);

   // Initialisation des tables (sinus & racines carrees)
   while(CommonSineInitVbl(1));
   while(CommonSqrtInitVbl(1));

   // Mise en place de la transparence
   REG_BLDMOD=(BLEND_BG2<<8)|BLEND_ALPHA;
   REG_BLD_AB=(4<<8)|16;

   // Passe en mode 1, et autorise l'affichage :
   // - du fond
   // - des sprites
   REG_DISPCNT=1|BG2_ENABLE|OBJ_ENABLE|OBJ_1D;
}

///////////////////////////
// GameBackgroundDisplay //
///////////////////////////
static void GameBackgroundDisplay(BlobVector* camPosition,unsigned char camAngle)
{
   signed long cos,sin;

   cos=COS(camAngle);
   sin=SIN(camAngle);

   REG_BG2X=camPosition->x+(128<<FIXED_POINT_SHIFT)-XO4*cos-YO4*sin;
   REG_BG2Y=camPosition->y+(128<<FIXED_POINT_SHIFT)+XO4*sin-YO4*cos;

   REG_BG2PA=cos;
   REG_BG2PB=sin;
   REG_BG2PC=-sin;
   REG_BG2PD=cos;
}

//////////////
// GameMain //
//////////////
void GameMain(void)
{
   static unsigned char blobType=0;
   unsigned short keysPressed,keysChanged;
   Blob* blob;
   BlobVector camPosition,gravity;
   unsigned char camAngle,gbaAngle;
   signed long cos,sin;

   // Positionnement par defaut de la camera et du blob
   camPosition.x=0;
   camPosition.y=0;

   // Creation du blob
   if(++blobType&1)
      blob=BlobCreateSnail(GAME_BLOB_STIFFNESS,GAME_BLOB_DAMPING,FIXED_POINT*8.0,GAME_BLOB_MASS,GAME_BLOB_PRESSION,10,&camPosition);
   else
      blob=BlobCreateBalloon(GAME_BLOB_STIFFNESS,GAME_BLOB_DAMPING,GAME_BLOB_LENGTH,GAME_BLOB_MASS,GAME_BLOB_PRESSION,9,&camPosition);
   if(!blob)
      return;

   // Boucle principale
   camAngle=0;
   do
   {
      // Lecture des touches (et attente du retour de balayage)
      keysChanged=REG_KEYS;
      CommonVwait(1);
      keysPressed=~REG_KEYS;
      keysChanged&=keysPressed;

      // Affichage du blob
      CommonSpritesInit();
      BlobDisplay(blob,&camPosition,camAngle,blobType&2);
      CommonSpritesDisplay();

      // Affichage du fond
      GameBackgroundDisplay(&camPosition,camAngle);

      // Modification de la pesanteur (gravite)
      // Note : on prend comme reference l'angle de la camera... et celui de la gba !
      if(0) // GBAccelerometerTest())
         gbaAngle=GBAccelerometerReadAngleXY()-(SINNB/4);
      else
         gbaAngle=0;

      cos=COS(camAngle+gbaAngle);
      sin=SIN(camAngle+gbaAngle);

      if((keysPressed&(KEY_L|KEY_R))==(KEY_L|KEY_R) && (keysChanged&(KEY_L|KEY_R)))
      {
         gravity.x=(sin*GAME_FORCE_JUMP)>>FIXED_POINT_SHIFT;
         gravity.y=(cos*GAME_FORCE_JUMP)>>FIXED_POINT_SHIFT;
      }
      else
      {
         gravity.x=(sin*GAME_FORCE_GRAVITY)>>FIXED_POINT_SHIFT;
         gravity.y=(cos*GAME_FORCE_GRAVITY)>>FIXED_POINT_SHIFT;
      }

      // Calcul du cosinus et du sinus correspondant a l'angle de la camera
      cos=COS(camAngle);
      sin=SIN(camAngle);

      // Modification des proprietes du blob
      if((keysPressed&(KEY_A|KEY_B))==KEY_A)
         blob->pression=GAME_BLOB_PRESSION>>2;
      else if((keysPressed&(KEY_A|KEY_B))==KEY_B)
         blob->pression=GAME_BLOB_PRESSION<<1;
      else
         blob->pression=GAME_BLOB_PRESSION;

      // Modification de la position de la camera : deplacement lateraux
      if((keysPressed&(KEY_LEFT|KEY_RIGHT))==KEY_LEFT)
      {
         camPosition.x-=cos<<GAME_CAMERA_MOVE_SHIFT;
         camPosition.y+=sin<<GAME_CAMERA_MOVE_SHIFT;
      }
      else if((keysPressed&(KEY_LEFT|KEY_RIGHT))==KEY_RIGHT)
      {
         camPosition.x+=cos<<GAME_CAMERA_MOVE_SHIFT;
         camPosition.y-=sin<<GAME_CAMERA_MOVE_SHIFT;
      }

      // Modification de la position de la camera : deplacement verticaux
      if((keysPressed&(KEY_UP|KEY_DOWN))==KEY_UP)
      {
         camPosition.x-=sin<<GAME_CAMERA_MOVE_SHIFT;
         camPosition.y-=cos<<GAME_CAMERA_MOVE_SHIFT;
      }
      else if((keysPressed&(KEY_UP|KEY_DOWN))==KEY_DOWN)
      {
         camPosition.x+=sin<<GAME_CAMERA_MOVE_SHIFT;
         camPosition.y+=cos<<GAME_CAMERA_MOVE_SHIFT;
      }

      // Modification de la position de la camera : recentrage automatique
      if(!(keysPressed&(KEY_LEFT|KEY_RIGHT|KEY_UP|KEY_DOWN)))
      {
         camPosition.x+=(blob->element[0].position.x-camPosition.x)>>GAME_CAMERA_CENTER_SHIFT;
         camPosition.y+=(blob->element[0].position.y-camPosition.y)>>GAME_CAMERA_CENTER_SHIFT;
      }

      // Modification de l'angle de la camera
      if((keysPressed&(KEY_L|KEY_R))==KEY_L)
         --camAngle;
      else if((keysPressed&(KEY_L|KEY_R))==KEY_R)
         ++camAngle;

      // Deplacement du blob
      BlobMove(blob,&gravity);
   }
   while(!(keysChanged&KEY_START));

   // Destruction du blob
   BlobDestroy(blob);
}
