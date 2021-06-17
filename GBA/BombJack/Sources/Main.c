/*
** Bomb Jack - Sources\Main.c
** Nicolas ROBERT [NRX] - Hong Kong 2005 / France 2006
*/

////////////////
// Inclusions //
////////////////
#include "Common\Common.h"
#include "Game\Game.h"
#include "Intro\Intro.h"
#include "Menu\Menu.h"

////////////////////////
// Variables globales //
////////////////////////
const unsigned char mainPaletteSprites[]={0,0,0,0,0,0,0,0,0,26,24,6,0,13,0,0};

extern const unsigned char CommonSprites_Bitmap[];
extern const unsigned char CommonFontBj_Bitmap[];
extern const unsigned char MenuBackground_Tiles[];
extern const unsigned short MenuBackground_Map[];

//////////
// main //
//////////
int main(void)
{
   unsigned char resume;
   GamePlayer* player;

   // Force l'ecran au noir
   PALRAM[0]=0;
   REG_DISPCNT=0;

   // Optimisation du "Wait State Control"
   REG_WSCNT=BEST_WSCNT;

   // Mise en place l'interruption sur le retour de balayage (VBL)
   CommonInterruptSet(IT_VBLANK,(IntrFunction*)&CommonInterruptBasicVbl);

   // Initialisation de la palette CPC
   CommonCpcPaletteInit();
   CommonCpcPenSet(1*16+15,0,PALRAM); // Couleur #0 (= noire) pour l'encre #15 de la palette #1

   // Chargement des sprites
   CommonUncompressInVRAM((void*)CommonSprites_Bitmap,(void*)OBJ_TILES);
   CommonDmaCopy((void*)OBJ_TILES,(void*)CHAR_BASE_BLOCK(1),CommonUncompressSize((void*)CommonSprites_Bitmap)>>2,DMA_32NOW);
   CommonCpcPaletteSet(mainPaletteSprites,OBJ_PALRAM);

   // Chargement de la police Bomb Jack
   CommonUncompressInVRAM((void*)CommonFontBj_Bitmap,(void*)CHAR_BASE_BLOCK(2)+(2+26*11)*32);

   // Chargement du fond colore
   CommonUncompressInVRAM((void*)MenuBackground_Tiles,(void*)CHAR_BASE_BLOCK(3));
   CommonUncompressInVRAM((void*)MenuBackground_Map,(void*)SCREEN_BASE_BLOCK(31));

   // Mise en place des backgrounds
   // Note : il ne faut pas initialiser les backgrounds avant de charger les sprites, sinon le jeu
   // ne fonctionne pas sur Super Card (!?)
   REG_BG0CNT=BG_COLORS_16|TXTBG_SIZE_256x256|(0<<CHAR_SHIFT)|(28<<SCREEN_SHIFT)|3;
   REG_BG1CNT=BG_COLORS_16|TXTBG_SIZE_256x256|(1<<CHAR_SHIFT)|(29<<SCREEN_SHIFT)|2;
   REG_BG2CNT=BG_COLORS_16|TXTBG_SIZE_256x256|(2<<CHAR_SHIFT)|(30<<SCREEN_SHIFT)|0;
   REG_BG3CNT=BG_COLORS_16|TXTBG_SIZE_256x256|(3<<CHAR_SHIFT)|(31<<SCREEN_SHIFT)|2;

   // Creation du masque pour le texte
   CommonCpcMaskInit();

   // Recupere les informations enregistrees
   MenuHiScoreInit();

   // Une partie etait-elle en cours ?
   resume=CommonSramRead('B',(unsigned char*)&gamePData);
   if(!resume)
   {
      // Intro "CPC"
      IntroCpc();

      // Intro "Bomb Jack"
      IntroBj();
   }

   // Initialisation du decodeur ADPCM (lance la musique !)
   #ifdef ADPCM_ENABLED
   AdpcmInit(1);
   #endif // ADPCM_ENABLED

   // Initialisation du jeu
   GameInit();
   if(resume)
      goto RESUME;

   // Initialisation de la structure persistante
   gamePData.keyMode=0;
   gamePData.numPlayers=0;

   // Boucle principale du jeu
   while(1)
   {
      // Menu
      MenuMain();

      // Demonstration ?
      if(!gamePData.numPlayers)
      {
         GameDemoReplay();
         continue;
      }

      // Jeu
      GameLevelInit();
      while(gamePData.numDeadPlayers<gamePData.numPlayers)
         for(gamePData.numCurrentPlayer=0;gamePData.numCurrentPlayer<gamePData.numPlayers;++gamePData.numCurrentPlayer)
         {
            RESUME:
            player=&gamePData.player[gamePData.numCurrentPlayer];
            if(player->numLives)
            {
               while(GameMain(player))
               {
                  MenuBonus(player);
                  GameLevelNext(player);
               }
               if(!player->numLives)
                  ++gamePData.numDeadPlayers;
            }
         }
   }
}
