/*
** Bomb Jack - Sources\Intro\Intro.c
** Nicolas ROBERT [NRX] - Hong Kong 2005 / France 2006
*/

////////////////
// Inclusions //
////////////////
#include "..\Common\Common.h"

///////////
// Types //
///////////
typedef struct
{
   signed char timer;
   unsigned char x;
   unsigned char dy;
   const unsigned char* string;
}
IntroBootSequence;

////////////////////////
// Variables globales //
////////////////////////
const unsigned char introPaletteTitle[]={0,1,2,10,11,20,3,5,13,6,8,15,16,24,26,26};

const IntroBootSequence introBootSequence[]=
{
   {0,1,1,"Amstrad 64K Microcomputer v1"},
   {0,1,2,"\xa4""1984 Amstrad Consumer Elec-"},
   {0,1,1,"tronics plc and Locomotive"},
   {0,1,1,"Software Ltd."},
   {0,1,2,"BASIC 1.0"},
   {20,0,2,"Ready"},
   {-60,0,1,"print nrx$"},
   {0,0,1,"NRX - Hong Kong 2005"},
   {0,0,1,"Ready"},
   {-90,0,1,""},
   {-40,0,1,"print www$"},
   {0,0,1,"www.playeradvance.org"},
   {0,0,1,"Ready"},
   {-90,0,1,"cat"},
   {60,0,2,"Drive A: user  0"},
   {0,0,2,"BJCODE  .BIN  35K"},
   {0,0,1,"BOMBJACK.BAS   1K"},
   {0,0,1,"BOMBJACK.COM   7K"},
   {0,0,2,"135K free"},
   {0,0,2,"Ready"},
   {-60,0,1,"run\"bombjack"},
   {90,12,0,""}
};

extern const unsigned char IntroFontCpc_Bitmap[];
extern const unsigned char IntroTitle_Tiles[];
extern const unsigned short IntroTitle_Map[];

//////////////
// IntroCpc //
//////////////
void IntroCpc(void)
{
   unsigned short sequence;
   const unsigned char* string;
   unsigned char y;
   unsigned short* screen;
   signed char timer;
   unsigned char typing;
   unsigned char repeat;
   unsigned short keys;

   // Chargement de la police CPC
   CommonUncompressInVRAM((void*)IntroFontCpc_Bitmap,(void*)CHAR_BASE_BLOCK(0));

   // Nettoyage du background
   CommonDmaForce(0,(void*)SCREEN_BASE_BLOCK(28),32*32/2,DMA_32NOW);

   // Mise en place de la palette et affichage
   CommonCpcPenSet(0,1,PALRAM);
   CommonCpcPenSet(1,24,PALRAM);
   REG_DISPCNT=BG0_ENABLE;

   // Simulation du demarrage du CPC
   sequence=0;
   string=NULL;
   y=0;
   screen=0;
   timer=0;
   typing=0;
   while(sequence<sizeof(introBootSequence)/sizeof(IntroBootSequence))
   {
      // Gestion des chaines de caracteres
      if(!string)
      {
         // Recupere le pointeur vers la chaine a afficher
         string=introBootSequence[sequence].string;

         // Positionne la chaine sur l'ecran
         y+=introBootSequence[sequence].dy;
         if(y<=19)
            REG_BG0VOFS=0;
         else
            REG_BG0VOFS=(y-19)<<3;
         screen=(unsigned short*)SCREEN_BASE_BLOCK(28)+introBootSequence[sequence].x+(y<<5);

         // Recupere le timer et le type d'affichage (normal / entree utilisateur)
         timer=introBootSequence[sequence].timer;
         if(timer<0)
         {
            timer=-timer;
            typing=1;
            *screen='\x8f'-' ';
         }
         else
            typing=0;
      }

      // Gere d'abord le timer
      if(timer)
         --timer;
      else if(typing)
      {
         // La chaine est entree par l'utilisateur
         if(*string=='\0')
         {
            *screen=0;
            ++sequence;
            string=NULL;
         }
         else
         {
            *screen++=*string++-' ';
            *screen='\x8f'-' ';
            timer=8+(rand()&7); // Note : ici on utilise "rand" sans se soucier de l'initialisation du generateur de nombres aleatoires
         }
      }
      else
      {
         // La chaine est directement affichee par le CPC
         for(repeat=0;repeat<4;++repeat)
         {
            if(*string=='\0')
            {
               ++sequence;
               string=NULL;
               break;
            }
            *screen++=*string++-' ';
         }
      }

      // Gestion des touches
      keys=REG_KEYS;
      CommonVwait(1);
      keys&=~REG_KEYS;
      if(keys&(KEY_START|KEY_A|KEY_B))
         break;
   }

   // Repositionne le background...
   REG_BG0VOFS=0;
}

/////////////
// IntroBj //
/////////////
void IntroBj(void)
{
   unsigned short line;
   unsigned char timer;
   unsigned short keys;

   // Force l'ecran au noir (le chargement de l'ecran titre prend du temps...)
   PALRAM[0]=0;
   REG_DISPCNT=0;

   // Chargement de l'ecran titre
   CommonUncompressInVRAM((void*)IntroTitle_Tiles,(void*)CHAR_BASE_BLOCK(0));
   CommonUncompressInVRAM((void*)IntroTitle_Map,(void*)SCREEN_BASE_BLOCK(28));

   // Mise en place du cache
   CommonDmaForce(-1,(void*)CHAR_BASE_BLOCK(1)+511*32,32/4,DMA_32NOW); // Encre #15, tile #511
   CommonDmaForce(511|(1<<12),(void*)SCREEN_BASE_BLOCK(29),32*20,DMA_16NOW); // Tile #511, palette #1

   // Mise en place de la palette et affichage
   CommonCpcPaletteSet(introPaletteTitle,PALRAM);
   REG_DISPCNT=BG0_ENABLE|BG1_ENABLE;

   // Boucle d'attente
   line=0;
   timer=0;
   while(1)
   {
      if(line<8)
      {
         // Suppression du cache de l'ecran titre
         *((unsigned long*)CHAR_BASE_BLOCK(1)+(511*32/4)+line++)=0;
      }
      else if(++timer==60)
         break;
      #ifdef ADPCM_ENABLED
      else if(timer==8)
      {
         // Affichage de la mention "Music Edition"
         REG_DISPCNT|=BG2_ENABLE;
         CommonCpcMaskCleanAll(0);
         CommonCpcMaskWriteString(0,9,"Music",11);
         CommonCpcMaskWriteString(0,10,"Edition",11);
      }
      #endif // ADPCM_ENABLED

      // Gestion des touches
      keys=REG_KEYS;
      CommonVwait(6);
      keys&=~REG_KEYS;
      if(keys&(KEY_START|KEY_A|KEY_B))
         break;
   }
}
