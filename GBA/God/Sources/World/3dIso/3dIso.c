/*
** God - Sources\World\3dIso\3dIso.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include "3dIso.h"

////////////
// Macros //
////////////
#define CORRECTION_HEIGHT // Flag pour activer la correction sur "height"

///////////
// Types //
///////////
typedef struct
{
   signed short xMin;
   signed short xMax;
   signed short yMin;
   signed short yMax;

   signed long x;
   signed long z;

   unsigned short maskAttr1;
   unsigned short maskAttr2;
   unsigned short maskAttr3;
}
InfoSprite;

typedef struct
{
   unsigned char (*mapIsGround)(signed short);
   unsigned char (*mapIsWall)(signed short);
   unsigned short mapWidthShift;
   unsigned short mapWidth;
   unsigned short mapWidthMask;
   unsigned short mapHeightShift;
   unsigned short mapHeight;

   InfoSprite infoSprite[2];

   unsigned short splitTimer;
   signed short splitValue;
   signed short ym;
   unsigned char menuTile;
}
Iso;

typedef struct
{
   unsigned short addressSprite;
   unsigned short dx;
   unsigned short dy;
   unsigned short maskAttr2;
}
InfoPointer;

////////////////////////
// Variables globales //
////////////////////////
Iso iso;

extern const unsigned char Tiles3dIso_Bitmap[];
extern const unsigned short Tiles3dIso_Palette[];
extern const unsigned char Sprites3dIso_Bitmap[];
extern const unsigned short Sprites3dIso_Palette[];
extern const unsigned char Font_Bitmap[];
extern const unsigned char TilesMenu_Bitmap[];

const unsigned short addressSprite[]={0,14,                                        // Type 1 (1&2)
                                      32*6+0,32*6+14,                              // Type 1 (3&4)
                                      32*12+0,32*12+6,32*12+12,32*12+18,32*12+24,  // Type 2 (5~9)
                                      32*14+0,32*14+6,32*14+12,32*14+18,32*14+24}; // Type 2 (10~14)

const InfoPointer infoPointer[]={{28+0*64,0,0,1<<14},                     // Normal pointer
                                 {28+0*64,15,0,(1<<12)|(1<<14)},          // Normal pointer (H flipped)
                                 {28+0*64,0,15,(1<<13)|(1<<14)},          // Normal pointer (V flipped)
                                 {28+0*64,15,15,(1<<12)|(1<<13)|(1<<14)}, // Normal pointer (H&V flipped)
                                 {28+1*64,0,0,1<<14},                     // Build pointer
                                 {28+1*64,15,0,(1<<12)|(1<<14)},          // Build pointer (H flipped)
                                 {28+2*64,0,15,1<<14},                    // Build pointer (V flipped)
                                 {28+2*64,15,15,(1<<12)|(1<<14)},         // Build pointer (H&V flipped)
                                 {28+3*64,0,0,1<<14},                     // Forbidden pointer
                                 {28+3*64,15,0,(1<<12)|(1<<14)},          // Forbidden pointer (H flipped)
                                 {28+3*64,0,15,(1<<13)|(1<<14)},          // Forbidden pointer (V flipped)
                                 {28+3*64,15,15,(1<<12)|(1<<13)|(1<<14)}, // Forbidden pointer (H&V flipped)
                                 {28+4*64,4,0,1<<14},                     // Move up
                                 {28+4*64,4,15,(1<<13)|(1<<14)},          // Move down
                                 {28+5*64,0,4,1<<14},                     // Move left
                                 {28+5*64,15,4,(1<<12)|(1<<14)},          // Move right
                                 {28+6*64,0,0,1<<14},                     // Move up+left
                                 {28+6*64,15,0,(1<<12)|(1<<14)},          // Move up+right
                                 {28+6*64,0,15,(1<<13)|(1<<14)},          // Move down+left
                                 {28+6*64,15,15,(1<<12)|(1<<13)|(1<<14)}, // Move down+right
                                 {24+6*64,7,7,1<<14},                     // Translations
                                 {24+7*64,7,7,1<<14},                     // Rotation (Ry) & zoom
                                 {28+7*64,7,7,1<<14}};                    // Rotations (Ry & Rx)

////////////////////
// IsoInterruptUp //
////////////////////
void CODE_IN_IWRAM IsoInterruptUp(void)
{
   // Passe en mode 2, et autorise l'affichage :
   // - du sol (BG2)
   // - du plafond (BG3)
   // - des murs (sprites)
   // Note importante : il faut egalement activer des backgrounds 0 et 1 (meme s'ils ne sont pas
   // affiches en mode 2) afin de correctement afficher le menu en mode 0 ! En effet la GBA
   // n'affiche rien pendant 3 lignes lorsqu'on passe un BG de "off" a "on" pendant l'affichage
   REG_DISPCNT&=WIN0_ENABLE;
   REG_DISPCNT|=2|BG0_ENABLE|BG1_ENABLE|BG2_ENABLE|BG3_ENABLE|OBJ_ENABLE|OBJ_2D;

   // On fait egalement ce que fait le "basicVblInterrupt" !
   AdpcmDecodeVbl(0);
   AdpcmDecodeVbl(1);
   ++vblCounter;
}

//////////////////////
// IsoInterruptDown //
//////////////////////
void CODE_IN_IWRAM IsoInterruptDown(void)
{
   // Verifie qu'on est encore bien dans la zone affichable
   if(REG_DISPVCNT<YM)
   {
      // Passe en mode 0, et autorise l'affichage :
      // - du fond du menu (BG0)
      // - du texte du menu (BG1)
      // Note : on passe en mode 0 mais les backgrounds 0 et 1 sont normalement deja actives, la GBA
      // doit donc pouvoir switcher instantanement (pas de periode avec "3 lignes noires")
      REG_DISPCNT&=WIN0_ENABLE;
      REG_DISPCNT|=0|BG0_ENABLE|BG1_ENABLE;
   }
}

/////////////
// IsoInit //
/////////////
void IsoInit(unsigned char (*mapIsGround)(signed short),unsigned char (*mapIsWall)(signed short),
             unsigned short mapWidthShift,unsigned short mapHeightShift)
{
   unsigned short rotBgSize;

   // Recupere les donnees de la carte
   iso.mapIsGround=mapIsGround;
   iso.mapIsWall=mapIsWall;

   iso.mapWidthShift=mapWidthShift;
   iso.mapWidth=1<<mapWidthShift;
   iso.mapWidthMask=iso.mapWidth-1;
   iso.mapHeightShift=mapHeightShift;
   iso.mapHeight=1<<mapHeightShift;

   // Organisation de la memoire video :
   //     0 - 16383 : BG2/SCREEN(0)   - map du sol (128x128 tiles / 1024x1024 pixels)
   // 16384 - 32767 : BG3/SCREEN(8)   - map du plafond (128x128 tiles / 1024x1024 pixels)
   // 32768 - 49151 : BG2&BG3/CHAR(2) - tiles du sol & du plafond (256 tiles max)
   // 49152 - 61439 : BG0&BG1/CHAR(3) - tiles du menu (192 tiles max)
   // 61440 - 63487 : BG0/SCREEN(30)  - map du fond du menu (32x32 tiles / 256x256 pixels)
   // 63488 - 65535 : BG1/SCREEN(31)  - map du texte du menu (32x32 tiles / 256x256 pixels)

   // Preparation des backgrounds
   switch(mapWidthShift)
   {
      case 6:
         rotBgSize=ROTBG_SIZE_1024x1024;
         break;
      case 5:
         rotBgSize=ROTBG_SIZE_512x512;
         break;
      case 4:
         rotBgSize=ROTBG_SIZE_256x256;
         break;
      default:
         rotBgSize=ROTBG_SIZE_128x128;
         break;
   }

   REG_BG0CNT=BG_COLORS_256|TXTBG_SIZE_256x256|(3<<CHAR_SHIFT)|(30<<SCREEN_SHIFT)|1; // Menu (fond)
   REG_BG1CNT=BG_COLORS_256|TXTBG_SIZE_256x256|(3<<CHAR_SHIFT)|(31<<SCREEN_SHIFT)|0; // Menu (texte)
   REG_BG2CNT=BG_COLORS_256|rotBgSize|(2<<CHAR_SHIFT)|(0<<SCREEN_SHIFT)|3; // Sol
   REG_BG3CNT=BG_COLORS_256|rotBgSize|(2<<CHAR_SHIFT)|(8<<SCREEN_SHIFT)|1; // Plafond

   // Pre-positionne les backgrounds du menu
   REG_BG0HOFS=0;
   REG_BG1HOFS=0;

   // Chargement des tiles du sol et du plafond
   CommonDmaForce(0,(void*)CHAR_BASE_BLOCK(2),4*64/4,DMA_32NOW);
   CommonUncompressInVRAM((void*)Tiles3dIso_Bitmap,(void*)CHAR_BASE_BLOCK(2)+4*64);
   CommonDmaCopy((void*)Tiles3dIso_Palette,(void*)PALRAM,256/2,DMA_32NOW);

   // Chargement des tiles du menu
   CommonUncompressInVRAM((void*)Font_Bitmap,(void*)CHAR_BASE_BLOCK(3));
   CommonDmaCopy((void*)TilesMenu_Bitmap,(void*)CHAR_BASE_BLOCK(3)+3968,128/4,DMA_32NOW);

   // Chargement des sprites
   CommonUncompressInVRAM((void*)Sprites3dIso_Bitmap,(void*)OBJ_TILES);
   CommonDmaCopy((void*)Sprites3dIso_Palette,(void*)OBJ_PALRAM,256/2,DMA_32NOW);

   // Termine l'initialisation de SINE_TABLE (si besoin est)
   while(CommonSineInitVbl(0));

   // Termine l'initialisation de INVERSE_TABLE (si besoin est)
   while(CommonInverseInitVbl(0));

   // Initialisation de la liste de sprites
   CommonSpritesInit();
   CommonSpritesDisplay();

   // Mise en place du menu
   CommonDmaForce(63|(63<<16),(void*)SCREEN_BASE_BLOCK(30),32*32/2,DMA_32NOW);
   CommonDmaForce(62|(62<<16),(void*)SCREEN_BASE_BLOCK(31),32/2,DMA_32NOW);

   iso.splitValue=YM;
   iso.ym=YM;
   iso.menuTile=0;

   // Mise en place de l'interruption VBL (modification dynamique du mode graphique)
   CommonInterruptSet(IT_VBLANK,(IntrFunction*)&IsoInterruptUp);
}

////////////////
// IsoDestroy //
////////////////
void IsoDestroy(void)
{
   // Desactive l'interruption sur YTRIG et remet en place celle sur VBL
   CommonInterruptDisable(IT_YTRIG);
   CommonInterruptSet(IT_VBLANK,(IntrFunction*)&CommonInterruptBasicVbl);
}

//////////////////
// IsoMenuClean //
//////////////////
inline void IsoMenuClean(unsigned char ymin,unsigned char ymax)
{
   CommonDmaForce(0,(void*)SCREEN_BASE_BLOCK(31)+(ymin<<6),(ymax+1-ymin)<<4,DMA_32NOW);
}

/////////////////////
// IsoMenuChangeBg //
/////////////////////
inline void IsoMenuChangeBg(unsigned char tile)
{
   if(tile!=iso.menuTile)
   {
      CommonDmaCopy((void*)TilesMenu_Bitmap+64+(tile<<6),(void*)CHAR_BASE_BLOCK(3)+3968+64,64/4,DMA_32NOW);
      iso.menuTile=tile;
   }
}

////////////////////////
// IsoMenuWriteString //
////////////////////////
void IsoMenuWriteString(unsigned char x,unsigned char y,const unsigned char* string)
{
   unsigned short* screen;
   unsigned short character;

   // Affichage de la chaine
   screen=(unsigned short*)SCREEN_BASE_BLOCK(31)+x+(y<<5);
   while(*string!='\0')
   {
      if(*string>=' ' && *string<=']')
         character=*string-' ';
      else
         character=0;
      *screen++=character;
      ++string;
   }
}

////////////////////////
// IsoMenuWriteNumber //
////////////////////////
void IsoMenuWriteNumber(unsigned char xmin,unsigned char xmax,unsigned char y,unsigned short number)
{
   unsigned short* screen;
   unsigned short digit;

   // Affichage du nombre
   screen=(unsigned short*)SCREEN_BASE_BLOCK(31)+xmax+(y<<5);
   do
   {
      digit=number%10;
      *screen--=digit+'0'-' ';
      number=(number-digit)/10;
   }
   while(xmin++<xmax && number);
   while(xmin++<=xmax)
      *screen--=0;
}

///////////////
// IsoMapSet //
///////////////
void IsoMapSet(void)
{
   unsigned short mapIdx;
   unsigned short* screenIdxSol;
   unsigned short* screenIdxPlafond;
   unsigned short x,y;
   unsigned short tilesSol,tilesPlafond;

   mapIdx=0;
   screenIdxSol=(unsigned short*)SCREEN_BASE_BLOCK(0);
   screenIdxPlafond=(unsigned short*)SCREEN_BASE_BLOCK(8);

   // Mise en place des tiles du sol et du plafond...
   for(y=0;y<iso.mapHeight;++y)
   {
      for(x=0;x<iso.mapWidth;++x)
      {
         // On trouve la 1ere tile a afficher (celle d'en haut a gauche), puis on affiche les tiles
         // 2 par 2 (d'abord celles du haut, puis celles du bas)
         tilesSol=iso.mapIsGround(mapIdx);
         if(tilesSol)
         {
            tilesSol<<=2;
            tilesSol|=(tilesSol+1)<<8;
            tilesPlafond=0;
         }
         else
         {
            tilesSol=iso.mapIsWall(mapIdx)<<2;
            tilesSol|=(tilesSol+1)<<8;
            tilesPlafond=tilesSol;
         }

         // On met a jour la map du sol...
         *screenIdxSol=tilesSol;
         *(screenIdxSol+iso.mapWidth)=tilesSol+(2|(2<<8));

         // ...puis celle du plafond
         *screenIdxPlafond=tilesPlafond;
         *(screenIdxPlafond+iso.mapWidth)=tilesPlafond+(2|(2<<8));

         // On continue pour couvrir toute la carte
         ++mapIdx;
         ++screenIdxSol;
         ++screenIdxPlafond;
      }
      screenIdxSol+=iso.mapWidth;
      screenIdxPlafond+=iso.mapWidth;
   }

   // Si la carte est rectangulaire alors il faut nettoyer la partie non-utilisee
   if(y<iso.mapWidth)
   {
      y=(iso.mapWidth-y)<<iso.mapWidthShift;
      CommonDmaForce(0,(void*)screenIdxSol,y,DMA_32NOW);
      CommonDmaForce(0,(void*)screenIdxPlafond,y,DMA_32NOW);
   }
}

//////////////////
// IsoMapModify //
//////////////////
void IsoMapModify(signed short mapIdx)
{
   unsigned short screenIdx;
   unsigned short tilesSol,tilesPlafond;

   // Retrouve la postion de la tile
   screenIdx=(mapIdx&iso.mapWidthMask)|((mapIdx&~iso.mapWidthMask)<<1);

   // On trouve la 1ere tile a afficher (celle d'en haut a gauche), puis on affiche les tiles
   // 2 par 2 (d'abord celles du haut, puis celles du bas)
   tilesSol=iso.mapIsGround(mapIdx);
   if(tilesSol)
   {
      tilesSol<<=2;
      tilesSol|=(tilesSol+1)<<8;
      tilesPlafond=0;
   }
   else
   {
      tilesSol=iso.mapIsWall(mapIdx)<<2;
      tilesSol|=(tilesSol+1)<<8;
      tilesPlafond=tilesSol;
   }

   // On met a jour la map du sol...
   *((unsigned short*)SCREEN_BASE_BLOCK(0)+screenIdx)=tilesSol;
   *((unsigned short*)SCREEN_BASE_BLOCK(0)+screenIdx+iso.mapWidth)=tilesSol+(2|(2<<8));

   // ...puis celle du plafond
   *((unsigned short*)SCREEN_BASE_BLOCK(8)+screenIdx)=tilesPlafond;
   *((unsigned short*)SCREEN_BASE_BLOCK(8)+screenIdx+iso.mapWidth)=tilesPlafond+(2|(2<<8));
}

/////////////////
// IsoSplitSet //
/////////////////
void IsoSplitSet(unsigned short timer,signed short value)
{
   iso.splitTimer=timer;

   if(value>YM)
      iso.splitValue=YM;
   else if(value<0)
      iso.splitValue=0;
   else
      iso.splitValue=value;
}

//////////////////////
// IsoSplitGetValue //
//////////////////////
signed short IsoSplitGetValue(void)
{
   return(iso.ym);
}

//////////////////////
// IsoSpritePrepare //
//////////////////////
void CODE_IN_IWRAM IsoSpritePrepare(unsigned char Rx,unsigned char Ry,signed long zoom,
                                    signed long PA_SP,signed long PC_SP,signed long height,
                                    unsigned short axis)
{
   signed long PA,PC,PD;
   signed long realSize;
   signed short spriteSize;
   unsigned char L,H;
   unsigned short maskAttr1,maskAttr2,maskAttr3;

   // Calcul de la matrice de deformation
   // Notes :
   // - On multiplie le zoom par 2 (on se place dans un repere ou les sprites font 32x32 pixels au
   //   lieu de 16x16),
   // - On ajuste egalement PA pour supprimer les espaces entre sprites !
   PA=COS(Ry);

   if(!PA)
      return;

   PA=(zoom*INV(PA))>>(FIXED_POINT_INV_SHIFT-FIXED_POINT_SHIFT-1);
   PD=INVERSE_TABLE[COS(Rx)];
   PC=(((SIN(Ry)*PA)>>FIXED_POINT_SHIFT)*(SIN(Rx)*PD)>>(FIXED_POINT_INV_SHIFT-FIXED_POINT_SHIFT))>>FIXED_POINT_SHIFT;
   PD=(zoom*PD)>>(FIXED_POINT_INV_SHIFT-FIXED_POINT_SHIFT-1);

   if(PA<0)
      PA=-PA;
   if(PA<WALL_WIDTH*2*FIXED_POINT/8)
      PA=(PA*INVERSE_TABLE[(PA>>(WALL_WIDTH_SHIFT+1))+FIXED_POINT])>>(FIXED_POINT_INV_SHIFT-FIXED_POINT_SHIFT);
   else
      PA=(PA*INVERSE_TABLE[FIXED_POINT/8+FIXED_POINT])>>(FIXED_POINT_INV_SHIFT-FIXED_POINT_SHIFT);

   // Preparation des masques
   maskAttr1=(1<<13)|(1<<9)|(1<<8); // 256 colors, double size, rotation & scaling
   maskAttr2=(axis<<9); // Rotation & scaling matrix "axis"
   maskAttr3=(2<<10); // Priority 2

   // Calcul de la largeur reelle
   if(PA_SP>0)
      realSize=PA_SP;
   else
      realSize=-PA_SP;

   // Choix de la largeur du sprite
   if(realSize>2*WALL_WIDTH*FIXED_POINT)
   {
      L=2;
      maskAttr3|=6;
      spriteSize=WALL_WIDTH<<1;
   }
   else if(realSize>WALL_WIDTH*FIXED_POINT)
   {
      L=1;
      maskAttr3|=2;
      spriteSize=WALL_WIDTH;
      PA>>=1;
   }
   else
   {
      L=0;
      spriteSize=WALL_WIDTH>>1;
      PA>>=2;
   }

   // Calcul des limites ecran horizontales
   realSize>>=FIXED_POINT_SHIFT+1;
   iso.infoSprite[axis].xMin=-realSize-spriteSize;
   iso.infoSprite[axis].xMax=XM+realSize-spriteSize;

   // Repositionnement des sprites en x (decalage d'un demi-mur)
   // Note : on ajoute 0.5 pour qu'au final la position du sprite soit arrondie au pixel le plus
   // proche plutot que celui de gauche
   iso.infoSprite[axis].x=(PA_SP>>1)-(spriteSize<<FIXED_POINT_SHIFT)+(FIXED_POINT/2);

   // Calcul de la hauteur reelle
   realSize=height;
   if(PC_SP>0)
      realSize+=PC_SP;
   else
      realSize-=PC_SP;

   // Choix de la hauteur du sprite
   if(realSize>2*WALL_HEIGHT*FIXED_POINT)
   {
      H=2;
      maskAttr3|=64;
      spriteSize=WALL_HEIGHT<<1;
   }
   else
   {
      H=1;
      spriteSize=WALL_HEIGHT;
      PC>>=1;
      PD>>=1;
   }

   // Calcul des limites ecran verticales
   realSize>>=FIXED_POINT_SHIFT+1;
   iso.infoSprite[axis].yMin=-realSize-spriteSize;
   iso.infoSprite[axis].yMax=iso.ym+realSize-spriteSize;

   // Repositionnement des sprites en z (decalage d'un demi-mur)
   iso.infoSprite[axis].z=(PC_SP>>1)-(spriteSize<<FIXED_POINT_SHIFT);

   // Choix du type de sprite en fonction de la deformation
   if(L==H)
   {
      maskAttr1|=0<<14; // Square
      maskAttr2|=L<<14; // Size 16x16 or 32x32
   }
   else if(L<H)
   {
      maskAttr1|=2<<14; // Vertical rectangle
      maskAttr2|=(H+L-1)<<14; // Size 8x16, 8x32 or 16x32
   }
   else
   {
      maskAttr1|=1<<14; // Horizontal rectangle
      maskAttr2|=L<<14; // Size 32x16
   }

   // Sauvegarde des masques
   iso.infoSprite[axis].maskAttr1=maskAttr1;
   iso.infoSprite[axis].maskAttr2=maskAttr2;
   iso.infoSprite[axis].maskAttr3=maskAttr3;

   // Mise en place de la matrice de deformation
   axis<<=2;
   sprites[axis].attribute3=PA;
   sprites[axis+1].attribute3=0;
   sprites[axis+2].attribute3=PC;
   sprites[axis+3].attribute3=PD;
}

//////////////////
// IsoSpritePut //
//////////////////
void CODE_IN_IWRAM IsoSpritePut(unsigned char* pointer,unsigned char charData,signed long x,signed long z,unsigned short axis)
{
   InfoSprite* isoAxis;
   signed short xScreen,yScreen;

   isoAxis=&iso.infoSprite[axis];
   xScreen=(x+isoAxis->x)>>FIXED_POINT_SHIFT;
   yScreen=(z+isoAxis->z)>>FIXED_POINT_SHIFT;
   if(xScreen>=isoAxis->xMin && xScreen<isoAxis->xMax && yScreen>=isoAxis->yMin && yScreen<isoAxis->yMax && *pointer)
   {
      --*pointer;
      sprites[*pointer].attribute0=(yScreen&255)|isoAxis->maskAttr1;
      sprites[*pointer].attribute1=(xScreen&511)|isoAxis->maskAttr2;
      sprites[*pointer].attribute2=addressSprite[charData-1]+isoAxis->maskAttr3;
   }
}

////////////////////
// IsoZoomRxModif //
////////////////////
inline void CODE_IN_IWRAM IsoZoomRxModif(signed long* zoom,unsigned char* Rx)
{
   // On limite d'abord le zoom pour eviter les "depassements" de sprites
   if(*zoom<ZOOM_MIN)
      *zoom=ZOOM_MIN;

   // On va appliquer une deformation a Rx en considerant que la valeur passee en parametre n'est
   // valable que pour le zoom "bas" :
   // a)            zoom<ZOOM_LOW   =>  Rx=RX_MIN
   // b)  ZOOM_LOW<=zoom<ZOOM_HIGH  =>  Rx=progression lineaire de RX_MIN a RX_MAX
   // c) ZOOM_HIGH<=zoom            =>  Rx=RX_MAX
   if(*Rx>=RX_MAX || *zoom>=ZOOM_HIGH)
      *Rx=RX_MAX;
   else
   {
      if(*Rx<RX_MIN)
         *Rx=RX_MIN;
      if(*zoom>ZOOM_LOW)
         *Rx=RX_MAX-((RX_MAX-*Rx)*(ZOOM_HIGH-*zoom))/(ZOOM_HIGH-ZOOM_LOW);
   }
}

////////////////
// IsoDisplay //
////////////////
signed short CODE_IN_IWRAM IsoDisplay(signed long x,signed long z,unsigned char Rx,unsigned char Ry,signed long zoom,
                                      signed short xPointer,signed short yPointer,signed short pointer)
{
   signed long sinRx,cosRx,sinRy,cosRy;
   signed long PA_BG,PB_BG,PC_BG,PD_BG;
   signed long PA_SP,PB_SP,PC_SP,PD_SP;
   signed long xO,zO,xx,zz,height;
   signed short yo;
   signed short mapLeft,mapRight,mapWidth;
   signed short mapTop,mapBottom,mapHeight;
   signed short mapIdx,mapIdxWidthInc,mapIdxHeightInc,mapIdxRealHeightInc;
   unsigned char spritePointer,spriteCharData;

   // Modifier la zone ecran
   if(iso.ym<iso.splitValue)
      ++iso.ym;
   else if(iso.ym>iso.splitValue)
      --iso.ym;
   else if(!--iso.splitTimer)
      iso.splitValue=YM;

   if(iso.ym<YM)
   {
      // Repositionne les 2 backgrounds du menu
      REG_BG0VOFS=-iso.ym;
      REG_BG1VOFS=-iso.ym;

      // (Re-)mise en place de l'interruption YTRIG
      CommonInterruptSetYTrig(iso.ym,(IntrFunction*)&IsoInterruptDown);
   }
   else
   {
      // Desactive l'interruption sur YTRIG
      CommonInterruptDisable(IT_YTRIG);
   }

   yo=iso.ym>>1;

   // Verification du zoom et limitation de Rx en fonction du zoom
   IsoZoomRxModif(&zoom,&Rx);

   // Recupere les valeurs des sinus et cosinus pour Rx et Ry
   sinRx=SIN(Rx);
   cosRx=COS(Rx);
   sinRy=SIN(Ry);
   cosRy=COS(Ry);

   // Calcul de la matrice de deformation pour le sol et le plafond
   PA_BG=(zoom*cosRy)>>FIXED_POINT_SHIFT;
   PC_BG=(zoom*sinRy)>>FIXED_POINT_SHIFT;
   PB_BG=-(PC_BG*INV(sinRx))>>(FIXED_POINT_INV_SHIFT-FIXED_POINT_SHIFT);
   PD_BG=(PA_BG*INV(sinRx))>>(FIXED_POINT_INV_SHIFT-FIXED_POINT_SHIFT);

   // Calcul de la hauteur entre sol et plafond
   height=(cosRx*INVERSE_TABLE[zoom])>>(FIXED_POINT_INV_SHIFT-FIXED_POINT_SHIFT-WALL_HEIGHT_SHIFT);

   // Initialisation du pointeur de sprite
   spritePointer=128;

   // Les murs ne sont affiches que lorsqu'on n'est pas a la verticale
   if(cosRx)
   {
      // Calcul de la zone a parcourir (largueur)
      if(PA_BG>0)
         xx=XO*PA_BG;
      else
         xx=-XO*PA_BG;
      if(PB_BG>0)
         xx+=(((iso.ym<<FIXED_POINT_SHIFT)+height)*PB_BG)>>(FIXED_POINT_SHIFT+1);
      else
         xx-=(((iso.ym<<FIXED_POINT_SHIFT)+height)*PB_BG)>>(FIXED_POINT_SHIFT+1);

      mapLeft=(x-xx)>>(FIXED_POINT_SHIFT+WALL_WIDTH_SHIFT);
      if(mapLeft<1)
         mapLeft=1;

      mapRight=(x+xx)>>(FIXED_POINT_SHIFT+WALL_WIDTH_SHIFT);
      if(mapRight>iso.mapWidth-2)
         mapRight=iso.mapWidth-2;

      // Calcul de la zone a parcourir (hauteur)
      if(PC_BG>0)
         zz=XO*PC_BG;
      else
         zz=-XO*PC_BG;
      if(PD_BG>0)
         zz+=(((iso.ym<<FIXED_POINT_SHIFT)+height)*PD_BG)>>(FIXED_POINT_SHIFT+1);
      else
         zz-=(((iso.ym<<FIXED_POINT_SHIFT)+height)*PD_BG)>>(FIXED_POINT_SHIFT+1);

      mapTop=(z-zz)>>(FIXED_POINT_SHIFT+WALL_WIDTH_SHIFT);
      if(mapTop<1)
         mapTop=1;

      mapBottom=(z+zz)>>(FIXED_POINT_SHIFT+WALL_WIDTH_SHIFT);
      if(mapBottom>iso.mapHeight-2)
         mapBottom=iso.mapHeight-2;

      // Pour le positionnement des murs on utilise la matrice inverse de celle des backgrounds
      xx=(FIXED_POINT*FIXED_POINT*FIXED_POINT)/(PA_BG*PD_BG-PB_BG*PC_BG);
      PA_SP=(PD_BG*xx)>>FIXED_POINT_SHIFT;
      PB_SP=-(PB_BG*xx)>>FIXED_POINT_SHIFT;
      PC_SP=-(PC_BG*xx)>>FIXED_POINT_SHIFT;
      PD_SP=(PA_BG*xx)>>FIXED_POINT_SHIFT;

      // Calcul des coordonnees du point de depart
      xO=(XO<<FIXED_POINT_SHIFT)-((x*PA_SP+z*PB_SP)>>FIXED_POINT_SHIFT);
      zO=(yo<<FIXED_POINT_SHIFT)-((x*PC_SP+z*PD_SP)>>FIXED_POINT_SHIFT);

      // On va se deplacer de mur en mur...
      PA_SP<<=WALL_WIDTH_SHIFT;
      PB_SP<<=WALL_WIDTH_SHIFT;
      PC_SP<<=WALL_WIDTH_SHIFT;
      PD_SP<<=WALL_WIDTH_SHIFT;

      // Calcul des matrices de deformation pour les murs et du clipping ecran
      IsoSpritePrepare(Rx,Ry,zoom,PA_SP,PC_SP,height,0);
      IsoSpritePrepare(Rx,Ry+(SINNB/4),zoom,PB_SP,PD_SP,height,1);

      // Calcul des valeurs initiales et des modifications a apporter a chaque increment
      if(sinRy<0)
      {
         mapIdx=mapLeft;
         mapIdxWidthInc=1;
         xO+=PA_SP*mapLeft;
         zO+=PC_SP*mapLeft;
         iso.infoSprite[1].x+=PA_SP;
         iso.infoSprite[1].z+=PC_SP;
      }
      else
      {
         mapIdx=mapRight;
         mapIdxWidthInc=-1;
         xO+=PA_SP*mapRight;
         zO+=PC_SP*mapRight;
         PA_SP=-PA_SP;
         PC_SP=-PC_SP;
      }

      if(cosRy>0)
      {
         mapIdx+=mapTop<<iso.mapWidthShift;
         mapIdxHeightInc=iso.mapWidth;
         xO+=PB_SP*mapTop;
         zO+=PD_SP*mapTop;
         iso.infoSprite[0].x+=PB_SP;
         iso.infoSprite[0].z+=PD_SP;
      }
      else
      {
         mapIdx+=mapBottom<<iso.mapWidthShift;
         mapIdxHeightInc=-iso.mapWidth;
         xO+=PB_SP*mapBottom;
         zO+=PD_SP*mapBottom;
         PB_SP=-PB_SP;
         PD_SP=-PD_SP;
      }

      // Modification des increments de la boucle "height" pour annuler les effets de la boucle "width"
      mapWidth=mapRight-mapLeft+1;

      mapIdxRealHeightInc=mapIdxHeightInc-mapIdxWidthInc*mapWidth;
      PB_SP-=PA_SP*mapWidth;
      PD_SP-=PC_SP*mapWidth;

      // Parcours de la carte, de mur en mur
      for(mapHeight=mapTop;mapHeight<=mapBottom;++mapHeight)
      {
         for(mapWidth=mapLeft;mapWidth<=mapRight;++mapWidth)
         {
            // Que y a t-il ici ?
            spriteCharData=iso.mapIsWall(mapIdx);
            if(spriteCharData)
            {
               // Murs de l'axe x
               if(!iso.mapIsWall(mapIdx+mapIdxHeightInc) && cosRy)
                  IsoSpritePut(&spritePointer,spriteCharData,xO,zO,0);

               // Murs de l'axe z
               if(!iso.mapIsWall(mapIdx+mapIdxWidthInc) && sinRy)
                  IsoSpritePut(&spritePointer,spriteCharData,xO,zO,1);
            }

            // Mur suivant...
            mapIdx+=mapIdxWidthInc;
            xO+=PA_SP;
            zO+=PC_SP;
         }
         mapIdx+=mapIdxRealHeightInc;
         xO+=PB_SP;
         zO+=PD_SP;
      }
   }

   // Cache les sprites inutiles
   while(spritePointer>1)
      sprites[--spritePointer].attribute0=(1<<9)|(0<<8); // Taille double mais pas de rotation : sprite "desactive"

   // Mise en place du pointeur ecran
   yPointer=(yPointer*iso.ym)/YM;

   sprites[0].attribute0=((yPointer-infoPointer[pointer].dy)&255)|(1<<13)|(0<<14); // 256 colors, square
   sprites[0].attribute1=((xPointer-infoPointer[pointer].dx)&511)|infoPointer[pointer].maskAttr2;
   sprites[0].attribute2=infoPointer[pointer].addressSprite|(0<<10); // Priority 0

   // Calcul de la position du sol et du plafond
   // Note : on diminue un peu la hauteur pour que les backgrounds soient plus proches l'un de
   // l'autre (et donc limiter les espaces entre BG et sprites)
   xO=x-(XO*PA_BG+yo*PB_BG);
   zO=z-(XO*PC_BG+yo*PD_BG);

   #ifdef CORRECTION_HEIGHT
   height-=height>>WALL_HEIGHT_SHIFT;
   #endif

   xx=(height*PB_BG)>>(FIXED_POINT_SHIFT+1);
   zz=(height*PD_BG)>>(FIXED_POINT_SHIFT+1);

   // Attente du retour du balayage vertical
   CommonVwait();

   // Mise en place du sol et du plafond
   REG_BG2PA=PA_BG;
   REG_BG2PB=PB_BG;
   REG_BG2PC=PC_BG;
   REG_BG2PD=PD_BG;

   REG_BG2X=xO-xx;
   REG_BG2Y=zO-zz;

   REG_BG3PA=PA_BG;
   REG_BG3PB=PB_BG;
   REG_BG3PC=PC_BG;
   REG_BG3PD=PD_BG;

   REG_BG3X=xO+xx;
   REG_BG3Y=zO+zz;

   // Mise a jour de l'OAM
   CommonSpritesDisplay();

   // Trouve l'element sur lequel pointe le pointeur ecran
   xPointer-=XO;
   yPointer-=yo;

   x+=xPointer*PA_BG+yPointer*PB_BG;
   z+=xPointer*PC_BG+yPointer*PD_BG;

   xO=x+xx;
   zO=z+zz;
   do
   {
      mapWidth=xO>>(FIXED_POINT_SHIFT+WALL_WIDTH_SHIFT);
      mapHeight=zO>>(FIXED_POINT_SHIFT+WALL_WIDTH_SHIFT);
      if((unsigned short)mapWidth>=iso.mapWidth || (unsigned short)mapHeight>=iso.mapHeight)
         break;
      mapIdx=mapWidth|(mapHeight<<iso.mapWidthShift);
      if(iso.mapIsWall(mapIdx))
         return(mapIdx);
      xO-=PB_BG;
      zO-=PD_BG;
      height-=FIXED_POINT;
   }
   while(height>0);

   mapWidth=(x-xx)>>(FIXED_POINT_SHIFT+WALL_WIDTH_SHIFT);
   mapHeight=(z-zz)>>(FIXED_POINT_SHIFT+WALL_WIDTH_SHIFT);
   if((unsigned short)mapWidth>=iso.mapWidth || (unsigned short)mapHeight>=iso.mapHeight)
      return(-1);
   return(mapWidth|(mapHeight<<iso.mapWidthShift));
}
