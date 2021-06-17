/*
** Mario Balls - Sources\Boules\Boules.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include "Boules.h"

////////////
// Macros //
////////////
#define XM XM4
#define YM YM4
#define XO (XM/2)
#define YO (YM/2)

#define VITESSE_BOULE  1
#define VITESSE_LBOULE 3
#define VROT_N_LBOULE  (SINNB>>6)
#define VROT_L_LBOULE  (SINNB>>8)
#define TIMER_NOTIF    60

#define BOULES_PERDU     10
#define BOULES_MOREBALLS 10
#define CHRONO_START     100
#define CHRONO_NIVEAU    30
#define CHRONO_GIFT      30
#define CHRONO_HURRY     15
#define CHRONO_BONUS     5
#define CHRONO_BOULES    9
#define POINTS_NIVEAU    1000

#define LB_INIT      0
#define LB_REPOS     1
#define LB_TIR       2
#define LB_COLLISION 3

#define LB_SLOW    1
#define LB_REVERSE 2
#define LB_NORAY   4
#define LB_GRAY    8
#define LB_CRAZY   16
#define LB_TWISTER 32

#define ECART_POINTS 6

#define BOULE_GRISE 5
#define BOULE_NOIRE 6

#define PIXEL_BLANC 254
#define PIXEL_NOIR  255

///////////
// Types //
///////////
typedef void (*MalusBonus)(void);

////////////////////////
// Variables globales //
////////////////////////
extern const Sound ADPCM_EffetBombeContact;
extern const Sound ADPCM_EffetBombeDispersion;
extern const Sound ADPCM_EffetChronoGift;
extern const Sound ADPCM_EffetGagne;
extern const Sound ADPCM_EffetHeureux;
extern const Sound ADPCM_EffetMalheureux;
extern const Sound ADPCM_EffetNiveau01;
extern const Sound ADPCM_EffetNiveau02;
extern const Sound ADPCM_EffetPause;
extern const Sound ADPCM_EffetPoints;
extern const Sound ADPCM_EffetTir;
extern const Sound ADPCM_EffetTwister;
extern const Sound ADPCM_MusiqueGagne;
extern const Sound ADPCM_MusiqueJeu;
extern const Sound ADPCM_MusiquePerdu;

extern const unsigned char Police_Bitmap[];
extern const unsigned char SpritesJeu_Bitmap[];
extern const unsigned short SpritesJeu_Palette[];
extern const unsigned short FondVictoire_Palette[];
extern const unsigned char FondVictoire_Tiles[];
extern const unsigned short FondVictoire_Map[];

extern const Fonds fondsMario;
extern const Fonds fondsPA;

Boules* boules=NULL;

LanceBoule lanceBoule;
const Fonds* fonds;
signed short chrono;
unsigned short score;

// Cheat code
const unsigned short CHEAT[]={TOUCHE_HAUT,TOUCHE_HAUT,TOUCHE_A,TOUCHE_BAS,TOUCHE_BAS,TOUCHE_R};

// Points
const struct
{
   unsigned short points;
   unsigned short tile;
   unsigned char demiLargeur;
}
POINTS[]=
{
   {1,72,4},
   {2,74,4},
   {5,76,4},
   {10,78,4},
   {20,80,8},
   {50,84,8},
   {100,88,8},
   {200,92,8},
   {500,96,8}
};

// Notifications
struct
{
   unsigned char pointeur;
   unsigned char timer[125-BOULES_MAX];
}
notifications;

////////////////
// chargeInfo //
////////////////
void chargeInfo(void)
{
   // Recupere les informations enregistrees
   if(litSRAM((unsigned char*)&info,sizeof(info)))
   {
      // Le "magic" est incorrect, le hi-score et le hi-level valent 0 pour l'instant
      info.hiScore=0;
      info.hiLevel=0;
   }
}

///////////////
// sauveInfo //
///////////////
void sauveInfo(void)
{
   // Met a jour le hi-score et le hi-level
   if(score>info.hiScore)
      info.hiScore=score;
   if(niveaux.courant>info.hiLevel)
      info.hiLevel=niveaux.courant;

   // Sauvegarde les informations
   ecritSRAM((unsigned char*)&info,sizeof(info));
}

///////////////////
// affChaineTile //
///////////////////
void CODE_IN_IWRAM affChaineTile(unsigned char xmin,unsigned char xmax,unsigned char y,const unsigned char* chaine)
{
   unsigned short* ecran;
   unsigned char charactere;

   // Organisation de la police :
   // 0     : espace
   // 1-8   : "Continue"
   // 9-12  : "Quit"
   // 13    : etoile pour la selection
   // 14-28 : codes ASCII 44-58 (",", "-", ".", "/", chiffres de 0 a 9, ":")
   // 29-54 : lettres de A a Z
   // 55    : point d'exclamation

   // Affichage de la chaine sur le background 1 (score & chrono)
   ecran=(unsigned short*)SCREEN_BASE_BLOCK(22)+xmin+(y<<5);
   while(*chaine!='\0' && xmin++<=xmax)
   {
      charactere=88;
      if(*chaine>=',' && *chaine<=':')
         charactere=*chaine-','+88+14;
      else if(*chaine>='A' && *chaine<='Z')
         charactere=*chaine-'A'+88+29;
      else if(*chaine=='!')
         charactere=88+55;
      *ecran++=charactere;
      ++chaine;
   }
   while(xmin++<=xmax)
      *ecran++=88;
}

///////////////////
// affNombreTile //
///////////////////
void CODE_IN_IWRAM affNombreTile(unsigned char xmin,unsigned char xmax,unsigned char y,unsigned short nombre)
{
   unsigned short* ecran;
   unsigned char chiffre;

   // Affichage du nombre sur le background 1 (score & chrono)
   ecran=(unsigned short*)SCREEN_BASE_BLOCK(22)+xmax+(y<<5);
   do
   {
      chiffre=nombre%10;
      *ecran--=chiffre+88+18;
      nombre=(nombre-chiffre)/10;
   }
   while(xmin++<xmax && nombre);
   while(xmin++<=xmax)
      *ecran--=88;
}

////////////////
// initBoules //
////////////////
void CODE_IN_IWRAM initBoules(void)
{
   unsigned short n,x,y;

   // Organisation de la memoire video :
   //     0 - 38400 : BG0/CHAR(0)    - tiles support de jeu (600 tiles)
   // 38400 - 43008 : BG1/CHAR(2)    - tiles score & chrono (72 tiles max ; 1ere = #88)
   // 43008 - 45056 : BG0/SCREEN(21) - map support de jeu
   // 45056 - 47104 : BG1/SCREEN(22) - map score & chrono
   // 47104 - 49152 : BG2/SCREEN(23) - map image de fond
   // 49152 - 65536 : BG2/CHAR(3)    - tiles image de fond (256 tiles max)

   // Priorites des backgrounds :
   // - Le fond est derriere tout le reste : priorite 3
   // - Le support de jeu est juste devant le fond : priorite 2
   // - Le score & chrono sont devant tout le reste : priorite 0

   // Priorites des sprites :
   // - Les sprites sont sur le support de jeu : priorite<=2
   // - Les sprites sont sous le score & chrono : priorite>0
   // => Les sprites sont donc de priorite 1 ou 2
   // - Le lance boule est derriere tous les autres sprites : priorite 2 et dernier de la liste
   // - La bombe est juste au dessus du LB : priorite 2 et avant derniere de la liste
   // - Les boules sont par dessus le LB et la bombe, mais sous les notifications : priorite 2 et premieres de la liste
   // - Les notifications sont devant tous les autres sprites : priorite 1 (...au milieu de la liste)

   // Ordre des sprites :
   // - Lance boule : 127, priorite 2
   // - Bombe : 126, priorite 2
   // - Boule tiree : 125, priorite 2
   // - Notifications : de BOULES_MAX a 124, priorite 1
   // - Boules sur la trajectoire : de 0 a BOULES_MAX-1, priorite 2

   // Lance la musique du jeu...
   AdpcmStart(&ADPCM_MusiqueJeu,-1,0);

   // Preparation des backgrounds
   REG_BG0CNT=BG_COLORS_256|TXTBG_SIZE_256x256|(0<<CHAR_SHIFT)|(21<<SCREEN_SHIFT)|2; // Support de jeu
   REG_BG1CNT=BG_COLORS_256|TXTBG_SIZE_256x256|(2<<CHAR_SHIFT)|(22<<SCREEN_SHIFT)|0; // Score & chrono
   REG_BG2CNT=BG_COLORS_256|ROTBG_SIZE_128x128|(3<<CHAR_SHIFT)|(23<<SCREEN_SHIFT)|3; // Fond

   // Chargement des tiles de score et chrono
   copieDMA((void*)Police_Bitmap,(void*)CHAR_BASE_BLOCK(0)+38400,3584/4,DMA_32NOW);

   // Mise en place des tiles du support de jeu
   forceDMA(600,(void*)SCREEN_BASE_BLOCK(21),32*32,DMA_16NOW); // On utilise la tile #88 de score et chrono !
   n=0;
   for(x=0;x<30;++x)
      for(y=0;y<20;++y)
         *((unsigned short*)SCREEN_BASE_BLOCK(21)+x+(y<<5))=n++;

   // Mise en place du background 1 (score & chrono)
   forceDMA(88,(void*)SCREEN_BASE_BLOCK(22),32*32,DMA_16NOW);
   affChaineTile(0,5,0,"SCORE:");
   affChaineTile(22,26,0,"TIME:");
   affChaineTile(0,5,19,"LEVEL:");

   // Termine l'initialisation de SIN (si besoin est)
   while(initSIN_VBL(1));

   // Reserve de la memoire pour les boules
   if(!boules)
      boules=(Boules*)malloc(sizeof(Boules));

   // Chargement des sprites
   copieDMA((void*)SpritesJeu_Bitmap,(void*)OBJ_TILES,10240/4,DMA_32NOW);
   copieDMA((void*)SpritesJeu_Palette,(void*)OBJ_PALRAM,256/2,DMA_32NOW);

   // Affectation du type de fond
   if(REG_TOUCHES&TOUCHE_SELECT && compteVBL&31)
      fonds=&fondsMario;
   else
      fonds=&fondsPA;

   // Mise en place du chrono, du score et du niveau
   chrono=CHRONO_START;
   score=0;
   niveaux.courant=0;

   // Initialisation du generateur de nombres aleatoires
   srand(compteVBL);
}

/////////////////
// affPixelMap //
/////////////////
void CODE_IN_IWRAM affPixelMap(signed short x,signed short y,unsigned char couleur)
{
   void* adresse;
   unsigned short pixels;

   // On est dans l'ecran ?
   if((unsigned short)x<XM && (unsigned short)y<YM)
   {
      // Calcul de l'adresse dans la map
      adresse=(void*)CHAR_BASE_BLOCK(0)+(x&6)+(y<<3)+(x&~7)*(20<<3);

      // Attention, access memoire 16 bits (2 pixels a la fois)...
      pixels=*(unsigned short*)adresse;
      if(x&1)
         pixels=(pixels&0x00ff)|(couleur<<8);
      else
         pixels=(pixels&0xff00)|couleur;
      *(unsigned short*)adresse=pixels;
   }
}

//////////////
// affRayon //
//////////////
void CODE_IN_IWRAM affRayon(unsigned char offset)
{
   signed long x,y;
   signed long dx,dy;
   signed short pixelX,pixelY;
   void* adresse;
   unsigned char couleur;

   // Le rayon est actif ?
   if(lanceBoule.malus&LB_NORAY)
      return;

   // Retrouve les informations relatives au lance boule
   x=niveaux.niveaux[niveaux.courant].parcours->xLanceBoule<<VIRGULE_;
   y=niveaux.niveaux[niveaux.courant].parcours->yLanceBoule<<VIRGULE_;

   // Calcul de la trajectoire
   dx=COS(lanceBoule.angle);
   dy=-SIN(lanceBoule.angle);

   x+=dx*(offset&7);
   y+=dy*(offset&7);

   dx<<=3;
   dy<<=3;

   // Choix de la couleur initiale
   if(offset&8)
      couleur=PIXEL_BLANC;
   else
      couleur=PIXEL_NOIR;

   // Trace le rayon
   while((unsigned long)x<(XM<<VIRGULE_) && (unsigned long)y<(YM<<VIRGULE_))
   {
      // Calcul de l'adresse dans la map
      pixelX=x>>VIRGULE_;
      pixelY=y>>VIRGULE_;

      adresse=(void*)CHAR_BASE_BLOCK(0)+(pixelX&6)+(pixelY<<3)+(pixelX&~7)*(20<<3);

      // Change le pixel correspondant (ou exclusif)
      if(pixelX&1)
         *(unsigned short*)adresse^=couleur<<8;
      else
         *(unsigned short*)adresse^=couleur;

      // Inversion de la couleur
      if(couleur==PIXEL_NOIR)
         couleur=PIXEL_BLANC;
      else
         couleur=PIXEL_NOIR;

      // Point suivant...
      x+=dx;
      y+=dy;
   }
}

//////////////////
// affGrosPoint //
//////////////////
inline void CODE_IN_IWRAM affGrosPoint(signed short x,signed short y)
{
   affPixelMap(x,y,PIXEL_BLANC);
   affPixelMap(x+1,y,PIXEL_NOIR);
   affPixelMap(x-1,y,PIXEL_NOIR);
   affPixelMap(x,y+1,PIXEL_NOIR);
   affPixelMap(x,y-1,PIXEL_NOIR);
}

//////////////
// affBoule //
//////////////
void CODE_IN_IWRAM affBoule(unsigned char pointeur,signed short x,signed short y,unsigned char couleur)
{
   sprites[pointeur].attribut1=((y-RAYON)&255)|(1<<13); // Sprite 256 couleurs
   sprites[pointeur].attribut2=((x-RAYON)&511)|(1<<14); // Sprite de 16x16
   sprites[pointeur].attribut3=(couleur<<3)|(2<<10); // Les sprites des boules sont de priorite 2
}

////////////////
// coordBoule //
////////////////
void CODE_IN_IWRAM coordBoule(unsigned char pointeur,signed short* x,signed short* y)
{
   *x=sprites[pointeur].attribut2&511;
   if(*x<XM)
      *x+=RAYON;
   else
      *x-=512-RAYON;

   *y=sprites[pointeur].attribut1&255;
   if(*y<YM)
      *y+=RAYON;
   else
      *y-=256-RAYON;
}

///////////////////
// affLanceBoule //
///////////////////
inline void affLanceBoule(void)
{
   Parcours* parcours;

   parcours=niveaux.niveaux[niveaux.courant].parcours;
   sprites[127].attribut1=(parcours->yLanceBoule-16)|(1<<14)|(1<<13)|(1<<8)|(1<<9); // Sprite "wide", 256 couleurs, avec rotation et taille double
   sprites[127].attribut2=(parcours->xLanceBoule-32)|(2<<14); // Sprite de 32x16
   sprites[127].attribut3=56|(2<<10); // Le lance boule commence a la 28eme tile, et est de priorite 2
}

////////////////////
// changeRotation //
////////////////////
void CODE_IN_IWRAM changeRotation(unsigned short pointeur,signed short angle,signed short echelleX,signed short echelleY)
{
   pointeur<<=2;
   sprites[pointeur].attribut4=(COS(angle)*echelleX)>>(VIRGULE_*2-8);
   sprites[++pointeur].attribut4=(-SIN(angle)*echelleX)>>(VIRGULE_*2-8);
   sprites[++pointeur].attribut4=(SIN(angle)*echelleY)>>(VIRGULE_*2-8);
   sprites[++pointeur].attribut4=(COS(angle)*echelleY)>>(VIRGULE_*2-8);
}

////////////////////
// gereLanceBoule //
////////////////////
void CODE_IN_IWRAM gereLanceBoule(void)
{
   signed short da;
   Niveau* niveau;

   // Malus "twister" ?
   if(lanceBoule.malus&LB_TWISTER)
      lanceBoule.angle+=SINNB>>4;
   else
   {
      // Definit la vitesse de rotation du lance boule
      if(~REG_TOUCHES&(TOUCHE_L|TOUCHE_R))
         da=VROT_L_LBOULE;
      else
         da=VROT_N_LBOULE;

      // Malus "crazy control" ?
      if(lanceBoule.malus&LB_CRAZY)
         da=-da;

      // Change l'angle de rotation du lance boule
      if(!(REG_TOUCHES&TOUCHE_GAUCHE))
         lanceBoule.angle+=da;
      if(!(REG_TOUCHES&TOUCHE_DROITE))
         lanceBoule.angle-=da;
   }
   changeRotation(0,lanceBoule.angle,VIRGULE,VIRGULE);

   // Gestion du tir
   switch(lanceBoule.phase)
   {
      case LB_INIT:
         // Est-on bien au repos ?
         if(REG_TOUCHES&TOUCHE_A)
         {
            // Arme le lance boule
            niveau=&niveaux.niveaux[niveaux.courant];
            lanceBoule.xBoule=niveau->parcours->xLanceBoule<<VIRGULE_;
            lanceBoule.yBoule=niveau->parcours->yLanceBoule<<VIRGULE_;
            lanceBoule.phase=LB_REPOS;

            if(lanceBoule.malus&LB_GRAY)
               lanceBoule.couleur=BOULE_GRISE;
            else if(!(rand()&15))
               lanceBoule.couleur=BOULE_NOIRE;
            else if(boules->premiere!=BOULES_MAX && compteVBL&1)
               do
               {
                  if(++lanceBoule.couleur>=niveau->couleurs)
                     lanceBoule.couleur=0;
               }
               while(!boules->compteCouleurs[lanceBoule.couleur]);
            else
               lanceBoule.couleur=rand()%niveau->couleurs;
         }
         else
         {
            // Cache la boule !
            lanceBoule.xBoule=-RAYON<<VIRGULE_;
            lanceBoule.yBoule=-RAYON<<VIRGULE_;
         }
         break;

      case LB_REPOS:
         // On tir ?
         if(!(REG_TOUCHES&TOUCHE_A))
         {
            // Bruit de tir
            AdpcmStart(&ADPCM_EffetTir,1,1);

            // Initialisation du tir
            lanceBoule.dxBoule=COS(lanceBoule.angle)*VITESSE_LBOULE;
            lanceBoule.dyBoule=-SIN(lanceBoule.angle)*VITESSE_LBOULE;
            lanceBoule.phase=LB_TIR;

            // Malus "reverse shoot" ?
            if(lanceBoule.malus&LB_REVERSE)
            {
               lanceBoule.dxBoule=-lanceBoule.dxBoule;
               lanceBoule.dyBoule=-lanceBoule.dyBoule;
               lanceBoule.malus&=~LB_REVERSE;
            }

            // Malus "slow motion" ?
            if(lanceBoule.malus&LB_SLOW)
            {
               lanceBoule.dxBoule>>=1;
               lanceBoule.dyBoule>>=1;
            }

            // Supprime le "twister"
            lanceBoule.malus&=~LB_TWISTER;
         }
         break;

      case LB_COLLISION:
         // Oh ! La collision n'a pas ete geree !
         lanceBoule.phase=LB_TIR;

      case LB_TIR:
         // La boule tiree avance...
         lanceBoule.xBoule+=lanceBoule.dxBoule;
         lanceBoule.yBoule+=lanceBoule.dyBoule;

         // Sort-elle de l'ecran ?
         if((unsigned long)(lanceBoule.xBoule+(RAYON<<VIRGULE_))>(XM+DIAMETRE)<<VIRGULE_ ||
            (unsigned long)(lanceBoule.yBoule+(RAYON<<VIRGULE_))>(YM+DIAMETRE)<<VIRGULE_)
            lanceBoule.phase=LB_INIT;
         break;
   }

   // Affiche la boule tiree (la boule tiree est notre avant avant dernier sprite, le 126eme)
   affBoule(125,lanceBoule.xBoule>>VIRGULE_,lanceBoule.yBoule>>VIRGULE_,lanceBoule.couleur);
}

////////////////////
// affSpritesFond //
////////////////////
void CODE_IN_IWRAM affSpritesFond(signed short x,signed short y)
{
   unsigned short angle,deformeX,deformeY;
   signed short PA,PB,PC,PD;

   // Animation de la bombe
   sprites[126].attribut3=(104+(compteVBL&8))|(2<<10); // La bombe commence a la 52eme tile, et est de priorite 2

   // Affiches les sprites (mise a jour de l'OAM)
   affSprites();

   // Animation du fond : zoom et deformation "shear" (pas de scaling)
   angle=SIN(compteVBL)>>(VIRGULE_-SINNB_+3);
   deformeX=((128<<8)/YM)+(SIN(compteVBL)>>(VIRGULE_-8+2));
   deformeY=((128<<8)/YM)+(COS(compteVBL)>>(VIRGULE_-8+2));

   PA=(COS(angle)*deformeX)>>VIRGULE_;
   PB=(-SIN(angle)*deformeY)>>VIRGULE_;
   PC=(SIN(angle)*deformeX)>>VIRGULE_;
   PD=(COS(angle)*deformeY)>>VIRGULE_;

   x-=XO;
   y-=YO;

   REG_BG2X=(64<<8)+x*PA+y*PB;
   REG_BG2Y=(64<<8)+x*PC+y*PD;
   REG_BG2PA=PA;
   REG_BG2PB=PB;
   REG_BG2PC=PC;
   REG_BG2PD=PD;
}

///////////////
// gerePause //
///////////////
unsigned char CODE_IN_IWRAM gerePause(void)
{
   unsigned short* ecran;
   unsigned char charactere;
   unsigned short noStartA;
   unsigned char choix=0,ancienChoix=0,noSelect=0;
   unsigned short VBLcourant;

   // On joue le petit jingle annoncant la mise en pause du jeu
   AdpcmStart(&ADPCM_EffetPause,1,1);

   // Assombrit le fond (backgrounds 0 et 2) et les sprites
   REG_BLDMOD=BLEND_BG0|BLEND_BG2|BLEND_OBJ|BLEND_BD|BLEND_BLACK;
   REG_BLD_FAD=8;

   // Suppression du nom du niveau (s'il est encore la)
   affChaineTile(0,29,9,"");

   // Affichage du petit menu "continue" ou "quit" sur le background 1
   affChaineTile(12,17,8,"PAUSE!");
   ecran=(unsigned short*)SCREEN_BASE_BLOCK(22)+12+(10<<5);
   for(charactere=89;charactere<97;++charactere) // Ecrase l'eventuel "HURRY!"
      *ecran++=charactere;
   ecran=(unsigned short*)SCREEN_BASE_BLOCK(22)+12+(11<<5);
   for(charactere=97;charactere<101;++charactere)
      *ecran++=charactere;

   // Affiche la petite etoile
   ecran=(unsigned short*)SCREEN_BASE_BLOCK(22)+10+(10<<5);
   *ecran=101;

   // Attend qu'on ait relache les touches start et A...
   // (on verifie plusieurs fois de suite car il y a visiblement un probleme de "rebond", en particulier sur la GBA classique !)
   for(noStartA=0;noStartA<100;++noStartA)
      if(~REG_TOUCHES&(TOUCHE_START|TOUCHE_A))
         noStartA=0;

   // Propose le choix jusqu'a ce qu'on appuie sur les touches start ou A
   do
   {
      // Modifie le choix en fonction des touches
      if(!(REG_TOUCHES&TOUCHE_HAUT))
         choix=0;
      else if(!(REG_TOUCHES&TOUCHE_BAS))
         choix=1<<5;
      else if(REG_TOUCHES&TOUCHE_SELECT)
         noSelect=1;
      else if(noSelect)
      {
         choix^=1<<5;
         noSelect=0;
      }

      // Bouge la petite etoile
      if(ancienChoix!=choix)
      {
         *(ecran+choix)=101;
         *(ecran+ancienChoix)=88;
         ancienChoix=choix;
      }
   }
   while((REG_TOUCHES&(TOUCHE_START|TOUCHE_A))==(TOUCHE_START|TOUCHE_A));

   // Si on continue alors on joue le petit jingle annoncant la remise en route du jeu
   if(!choix)
      AdpcmStart(&ADPCM_EffetPause,1,1);

   // On attend que les touches start et A soient relachees
   while(~REG_TOUCHES&(TOUCHE_START|TOUCHE_A));

   // Attente du retour du balayage vertical
   VBLcourant=compteVBL;
   while(VBLcourant==compteVBL);

   // Efface la petite etoile
   *(ecran+choix)=88;

   // Efface le menu
   affChaineTile(12,17,8,"");
   ecran=(unsigned short*)SCREEN_BASE_BLOCK(22)+12+(10<<5);
   for(charactere=0;charactere<8;++charactere)
      *ecran++=88;
   ecran=(unsigned short*)SCREEN_BASE_BLOCK(22)+12+(11<<5);
   for(charactere=0;charactere<4;++charactere)
      *ecran++=88;

   // Force l'ecran au noir si on quitte le jeu
   if(choix)
   {
      PALRAM[0]=0;
      REG_DISPCNT=0;
   }

   // Supprime le fading
   REG_BLDMOD=BLEND_NO;

   // Retourne le choix
   return(choix);
}

/////////////////
// gereTimeOut //
/////////////////
inline void CODE_IN_IWRAM gereTimeOut(void)
{
   unsigned char compteur,pointeur;
   unsigned short vibration;
   unsigned short VBLcible;

   // On joue le jingle annoncant la defaite
   AdpcmStart(&ADPCM_MusiquePerdu,1,0);
   AdpcmStart(&ADPCM_EffetBombeDispersion,1,1);

   // Affichage du chrono (a zero !)
   affNombreTile(27,29,0,0);

   // Suppression du nom du niveau (s'il est encore la)
   affChaineTile(0,29,9,"");

   // Suppression du message "HURRY!" (s'il est la)
   affChaineTile(12,17,10,"");

   // Vibration de l'ecran
   vibration=0;
   for(compteur=0;compteur<60;++compteur) // Attention, il faut un nombre pair pour recaler les backgrounds !
   {
      // Attente du retour du balayage vertical
      VBLcible=compteVBL+2;
      while(compteVBL!=VBLcible);

      // Vibration des backgrounds 0 et 1
      vibration^=4;
      REG_BG0HOFS=vibration;
      REG_BG1VOFS=vibration;

      // Vibration de tous les sprites
      for(pointeur=0;pointeur<128;++pointeur)
      {
         sprites[pointeur].attribut1^=2;
         sprites[pointeur].attribut2^=2;
      }

      // Affichage des sprites et du fond, avec vibration du background 2
      affSpritesFond(vibration,vibration);
   }

   // Assombrit le fond (backgrounds 0 et 2) et les sprites
   REG_BLDMOD=BLEND_BG0|BLEND_BG2|BLEND_OBJ|BLEND_BD|BLEND_BLACK;
   for(compteur=0;compteur<=8;++compteur)
   {
      REG_BLD_FAD=compteur;
      VBLcible=compteVBL+3;
      while(compteVBL!=VBLcible);
   }

   // Affiche le message "GAME OVER..."
   affChaineTile(9,20,10,"GAME OVER...");

   // Verifie que les touches start et A sont bien relachees
   while(~REG_TOUCHES&(TOUCHE_START|TOUCHE_A));

   // Attend qu'on appuie sur les touches start ou A, puis qu'on les relache
   while((REG_TOUCHES&(TOUCHE_START|TOUCHE_A))==(TOUCHE_START|TOUCHE_A));
   while(~REG_TOUCHES&(TOUCHE_START|TOUCHE_A));

   // Attente du retour du balayage vertical
   VBLcible=compteVBL;
   while(VBLcible==compteVBL);

   // Supprime le fading, mais force d'abord l'ecran au noir
   PALRAM[0]=0;
   REG_DISPCNT=0;
   REG_BLDMOD=BLEND_NO;
}

///////////////
// gereFrame //
///////////////
unsigned char CODE_IN_IWRAM gereFrame(void)
{
   unsigned short VBLcourant;
   static unsigned char compteFrames=0;
   static unsigned char cheatEtat=0,cheatIndex=0;
   unsigned char pointeur;

   // On gere le lance boule a chaque frame
   gereLanceBoule();

   // Affichage du rayon et attente du retour du balayage vertical
   VBLcourant=compteVBL;
   affRayon(VBLcourant);
   while(VBLcourant==compteVBL);

   // Affichage des sprites et du fond
   affSpritesFond(0,0);

   // Mise a jour de l'affichage du score
   affNombreTile(6,10,0,score);

   // Gestion du chrono
   if(++compteFrames>=60)
   {
      compteFrames=0;
      --chrono;
   }
   if(chrono>0)
   {
      // Mise a jour de l'affichage du chrono (qui est positif)
      affNombreTile(27,29,0,chrono);
   }
   else
   {
      // Time out, c'est perdu !!
      gereTimeOut();
      return(ETAT_PERDU);
   }

   // Pause ?
   if(!(REG_TOUCHES&TOUCHE_START))
   {
      // Gere la pause
      if(gerePause())
         return(ETAT_ABANDON);

      // On repositionne le compteur de VBL pour ne pas affecter le chrono, le fond et le rayon
      compteVBL=VBLcourant;
   }

   // Suppression du rayon
   affRayon(VBLcourant);

   // Suppression du nom du niveau au bout d'un certain temps
   if(compteVBL>>2==20) // On se laisse 4 frames pour faire le boulot...
      affChaineTile(0,29,9,"");

   // Gestion du message "HURRY!"
   if(!(compteVBL&15))
   {
      if(chrono<=CHRONO_HURRY && compteVBL&16)
         affChaineTile(12,17,10,"HURRY!");
      else
         affChaineTile(12,17,10,"");
   }

   // Gestion du cheat code
   if((REG_TOUCHES&TOUCHES)==TOUCHES)
      cheatEtat=1;
   else if(cheatEtat)
   {
      cheatEtat=0;
      if((~REG_TOUCHES&TOUCHES)^CHEAT[cheatIndex])
      {
         // Erreur !
         cheatIndex=0;
      }
      else if(++cheatIndex>=sizeof(CHEAT)/sizeof(CHEAT[0]))
      {
         // Ok ! On reinitialise le cheat et on passe au niveau suivant !
         cheatIndex=0;
         ++niveaux.courant;
         return(ETAT_CONTINUE);
      }
   }

   // Gestion des notifications
   for(pointeur=0;pointeur<125-BOULES_MAX;++pointeur)
   {
      if(notifications.timer[pointeur])
      {
         --notifications.timer[pointeur];
         if(compteVBL&2)
         {
            // Fait monter le sprite d'un pixel
            --*(unsigned char*)&sprites[pointeur+BOULES_MAX].attribut1;
         }
      }
      else
      {
         // Le timer a expire, on cache ce sprite
         sprites[pointeur+BOULES_MAX].attribut1=YM4;
      }
   }

   // Rien de special...
   return(ETAT_RIEN);
}

/////////////////
// insertBoule //
/////////////////
unsigned char CODE_IN_IWRAM insertBoule(unsigned char pointeurAvant,unsigned char couleur,signed short L)
{
   unsigned char pointeur;
   Boule* boule;

   // Alloue de la memoire (enfin... trouve de la place dans le tableau de boules)
   if(boules->alloc==boules->free && boules->premiere!=BOULES_MAX)
      return(0);
   if(boules->alloc>=BOULES_MAX)
      boules->alloc=0;
   pointeur=boules->pointeurs[boules->alloc++];

   // Cree la nouvelle boule
   boule=&boules->boules[pointeur];
   boule->couleur=couleur;
   boule->L=L;

   // Insert la boule parmis les autres
   boule->avant=pointeurAvant;
   if(pointeurAvant==BOULES_MAX)
   {
      boule->apres=boules->premiere;
      boules->premiere=pointeur;
   }
   else
   {
      boule->apres=boules->boules[pointeurAvant].apres;
      boules->boules[pointeurAvant].apres=pointeur;
   }
   if(boule->apres!=BOULES_MAX)
      boules->boules[boule->apres].avant=pointeur;

   // Mise a jour du compte des couleurs
   ++boules->compteCouleurs[couleur];

   // L'insertion a ete faite !
   return(1);
}

///////////////////
// supprimeBoule //
///////////////////
void CODE_IN_IWRAM supprimeBoule(unsigned char pointeur)
{
   Boule* boule;

   // Cache le sprite
   sprites[pointeur].attribut1=YM4;

   // Supprime la boule de la liste
   boule=&boules->boules[pointeur];

   if(boule->avant!=BOULES_MAX)
      boules->boules[boule->avant].apres=boule->apres;
   else
      boules->premiere=boule->apres;
   if(boule->apres!=BOULES_MAX)
      boules->boules[boule->apres].avant=boule->avant;

   // Mise a jour du compte des couleurs
   --boules->compteCouleurs[boule->couleur];

   // Libere la memoire (enfin... la place reservee dans le tableau de boules)
   if(boules->free>=BOULES_MAX)
      boules->free=0;
   boules->pointeurs[boules->free++]=pointeur;
}

//////////////////
// gereVictoire //
//////////////////
inline void CODE_IN_IWRAM gereVictoire(void)
{
   signed char fade;
   unsigned short VBLcible;

   // On annonce la victoire en musique !
   AdpcmStart(&ADPCM_MusiqueGagne,1,0);
   AdpcmStart(&ADPCM_EffetGagne,1,1);

   // Suppression du nom du niveau (s'il est encore la)
   affChaineTile(0,29,9,"");

   // Suppression du message "HURRY!" (s'il est la)
   affChaineTile(12,17,10,"");

   // Signale qu'on a termine
   affChaineTile(6,8,19,"END");

   // Chargement de l'image de victoire (remplace le support de jeu)
   copieDMA((void*)FondVictoire_Tiles,(void*)CHAR_BASE_BLOCK(0),28928/4,DMA_32NOW);
   copieDMA((void*)FondVictoire_Map,(void*)SCREEN_BASE_BLOCK(21),32*32/2,DMA_32NOW);
   copieDMA((void*)FondVictoire_Palette,(void*)PALRAM,256/2,DMA_32NOW);

   // On n'affiche que les backgrounds 0 et 1
   REG_DISPCNT=1|BG0_ENABLE|BG1_ENABLE;

   // Fade-in pour l'image (le score & chrono sont normalement deja affiches)
   REG_BLDMOD=BLEND_BG0|BLEND_BD|BLEND_WHITE;
   for(fade=16;fade>=0;--fade)
   {
      REG_BLD_FAD=fade;
      VBLcible=compteVBL+3;
      while(compteVBL!=VBLcible);
   }

   // Verifie que les touches start et A sont bien relachees
   while(~REG_TOUCHES&(TOUCHE_START|TOUCHE_A));

   // Attend qu'on appuie sur les touches start ou A, puis qu'on les relache
   while((REG_TOUCHES&(TOUCHE_START|TOUCHE_A))==(TOUCHE_START|TOUCHE_A));
   while(~REG_TOUCHES&(TOUCHE_START|TOUCHE_A));

   // Fade-out
   REG_BLDMOD=BLEND_BG0|BLEND_BG1|BLEND_BD|BLEND_BLACK;
   for(fade=0;fade<=16;++fade)
   {
      REG_BLD_FAD=fade;
      VBLcible=compteVBL+3;
      while(compteVBL!=VBLcible);
   }

   // Supprime le fading, mais force d'abord l'ecran au noir
   PALRAM[0]=0;
   REG_DISPCNT=0;
   REG_BLDMOD=BLEND_NO;
}

///////////////
// affNiveau //
///////////////
unsigned char CODE_IN_IWRAM affNiveau(void)
{
   const InfoFond* infoFond;
   Parcours* parcours;
   unsigned char pointeur;
   Element* element;
   signed short x,x1,y,y1,a,a1,r;
   signed long vx,vy,va;
   unsigned short L,l;

   // Ce niveau est-il valide ?
   if(niveaux.courant>=niveaux.nombre)
   {
      // Victoire !!
      gereVictoire();
      return(ETAT_GAGNE);
   }

   // Nettoie le support de jeu (background 0)
   forceDMA(0,(void*)CHAR_BASE_BLOCK(0),XM*YM/4,DMA_32NOW);

   // Parcourt tous les elements de ce niveau
   parcours=niveaux.niveaux[niveaux.courant].parcours;

   L=0;
   l=0;
   for(pointeur=parcours->debut;pointeur<=parcours->fin;++pointeur)
   {
      // On prend l'element courant
      element=&niveaux.elements[pointeur];

      // On trace en fonction du type de l'element
      l-=L;
      switch(element->type)
      {
         case LIGNE:
            // Initialise la structure de donnee
            x1=element->info.ligne.x1;
            y1=element->info.ligne.y1;

            vx=element->info.ligne.x2-x1;
            if(vx<0)
               --vx;
            vy=element->info.ligne.y2-y1;
            if(vy>0)
               ++vy;

            L=mySqrt(vx*vx+vy*vy);
            vx=(vx<<VIRGULE_)/(signed long)L;
            vy=(vy<<VIRGULE_)/(signed long)L;

            element->L=L;
            element->info.ligne.vx=vx;
            element->info.ligne.vy=vy;

            // Trace cette ligne
            while(l<=L)
            {
               // Calcul des coordonnees
               x=x1+((l*vx)>>VIRGULE_);
               y=y1+((l*vy)>>VIRGULE_);

               // Affichage
               affGrosPoint(x,y);

               // On avance un peu...
               l+=ECART_POINTS;
            }
            break;

         case ARC:
            // Initialise la structure de donnee
            x1=element->info.arc.x;
            y1=element->info.arc.y;
            r=element->info.arc.r;
            a1=element->info.arc.a1;

            va=element->info.arc.a2-a1;
            if(va>0)
               ++va;

            if(va>0)
               L=(unsigned long)(2*PI*r*va)>>SINNB_;
            else
               L=(unsigned long)(-2*PI*r*va)>>SINNB_;
            va=(va<<VIRGULE_)/(signed long)L;

            element->L=L;
            element->info.arc.va=va;

            // Trace cet arc
            while(l<=L)
            {
               // Calcul des coordonnees
               a=a1+((l*va)>>VIRGULE_);
               x=x1+((r*COS(a))>>VIRGULE_);
               y=y1-((r*SIN(a))>>VIRGULE_);

               // Affichage
               affGrosPoint(x,y);

               // On avance un peu...
               l+=ECART_POINTS;
            }
            break;

         default:
            // Erreur !
            return(ETAT_PERDU);
      }
   }

   // Retrouve les coordonnees exactes du bout de la trajectoire
   element=&niveaux.elements[parcours->fin];
   switch(element->type)
   {
      case LIGNE:
         x=element->info.ligne.x2;
         y=element->info.ligne.y2;
         break;

      case ARC:
         r=element->info.arc.r;
         a=element->info.arc.a2;
         x=element->info.arc.x+((r*COS(a))>>VIRGULE_);
         y=element->info.arc.y-((r*SIN(a))>>VIRGULE_);
         break;

      default:
         return(ETAT_PERDU);
   }

   // Raccourcit le chemin pour que les boules ne chevauchent pas la bombe
   element->L-=RAYON+4;

   // Initialisation de la liste de sprites
   initSprites();

   // Mise en place de la bombe
   sprites[126].attribut1=((y-11)&255)|(1<<13); // Sprite 256 couleurs
   sprites[126].attribut2=((x-4)&511)|(1<<14); // Sprite de 16x16

   // Initialisation de la liste de boules
   boules->premiere=BOULES_MAX;
   boules->nombre=0;
   boules->alloc=0;
   boules->free=BOULES_MAX;

   for(pointeur=0;pointeur<BOULES_MAX;++pointeur)
      boules->pointeurs[pointeur]=pointeur;

   for(pointeur=0;pointeur<5;++pointeur)
      boules->compteCouleurs[pointeur]=0;

   // Mise en place du lance boule
   lanceBoule.phase=LB_INIT;
   lanceBoule.malus=0;
   lanceBoule.angle=parcours->aLanceBoule;
   affLanceBoule();

   // Affiche le nom et le numero du niveau
   for(pointeur=0;parcours->nom[pointeur]!='\0';++pointeur);
   pointeur>>=1;
   affChaineTile(0,14-pointeur,9,"");
   affChaineTile(15-pointeur,29,9,parcours->nom);
   affNombreTile(6,7,19,niveaux.courant+1);

   // Initialisation des notifications
   notifications.pointeur=BOULES_MAX;
   for(pointeur=0;pointeur<125-BOULES_MAX;++pointeur)
      notifications.timer[pointeur]=0;

   // Chargement de l'image de fond (background 2)
   infoFond=&fonds->infoFonds[niveaux.courant%fonds->nombre];

   copieDMA((void*)infoFond->tiles,(void*)CHAR_BASE_BLOCK(3),infoFond->tilesSize,DMA_32NOW);
   copieDMA((void*)infoFond->map,(void*)SCREEN_BASE_BLOCK(23),16*16/4,DMA_32NOW);
   copieDMA((void*)infoFond->palette,(void*)PALRAM,256/2,DMA_32NOW);

   // Premier affichage des sprites et du fond
   compteVBL=0;
   affSpritesFond(0,0);

   // Passe en mode 1, et autorise l'affichage :
   // - du support de jeu (BG0)
   // - du chrono et du score (BG1)
   // - du fond (BG2)
   // - des sprites
   REG_DISPCNT=1|BG0_ENABLE|BG1_ENABLE|BG2_ENABLE|OBJ_ENABLE|OBJ_1D;

   // Termine !
   return(ETAT_RIEN);
}

///////////
// gagne //
///////////
inline unsigned char CODE_IN_IWRAM gagne(void)
{
   unsigned char fade,tempo;
   unsigned char etat;

   // Petit jingle...
   if(compteVBL&1)
      AdpcmStart(&ADPCM_EffetNiveau01,1,1);
   else
      AdpcmStart(&ADPCM_EffetNiveau02,1,1);

   // Bonus de temps et de points
   chrono+=CHRONO_NIVEAU;
   score+=POINTS_NIVEAU;

   // Fade-out
   for(fade=0;fade<=16;++fade)
   {
      REG_BLDMOD=BLEND_BG0|BLEND_BG2|BLEND_OBJ|BLEND_BD|BLEND_WHITE;
      REG_BLD_FAD=fade;

      // Petite tempo...
      for(tempo=0;tempo<3;++tempo)
      {
         etat=gereFrame();
         if(etat!=ETAT_RIEN)
            return(etat);
      }
   }

   // Supprime le fading, mais vide d'abord l'ecran (ecran blanc, sauf pour le background 1)
   PALRAM[0]=0x7FFF;
   REG_DISPCNT=1|BG1_ENABLE;
   REG_BLDMOD=BLEND_NO;

   // Niveau suivant
   ++niveaux.courant;
   return(ETAT_CONTINUE);
}

///////////
// perdu //
///////////
unsigned char CODE_IN_IWRAM perdu(unsigned char pointeur)
{
   signed short x,y,angle;
   unsigned char nombre;
   unsigned char etat;
   struct
   {
      signed long x,y;
      signed short dx,dy;
   }
   coord[BOULES_MAX];

   // La bombe explose...
   AdpcmStart(&ADPCM_EffetBombeContact,1,1);

   // Le lanceur envoie des boules grises desormais
   lanceBoule.malus|=LB_GRAY;
   lanceBoule.couleur=BOULE_GRISE;

   // Trouve la toute derniere boule de la liste (ce n'est pas forcement le pointeur courant !)
   while(boules->boules[pointeur].apres!=BOULES_MAX)
      pointeur=boules->boules[pointeur].apres;

   // Toutes les boules deviennent grises
   do
   {
      // On force directement la couleur de la boule a "gris", sans changer son attribut "couleur"
      sprites[pointeur].attribut3=(BOULE_GRISE<<3)|(2<<10); // Les sprites des boules sont de priorite 2

      // Recupere les coordonnees de la boule
      coordBoule(pointeur,&x,&y);
      coord[pointeur].x=x<<VIRGULE_;
      coord[pointeur].y=y<<VIRGULE_;

      // Stocke la future direction de la boule
      angle=rand();
      coord[pointeur].dx=COS(angle)*VITESSE_LBOULE;
      coord[pointeur].dy=SIN(angle)*VITESSE_LBOULE;

      // Affiche les boules (avec une petite tempo)
      for(nombre=0;nombre<3;++nombre)
      {
         etat=gereFrame();
         if(etat!=ETAT_RIEN)
            return(etat);
      }

      // Boule suivante !
      pointeur=boules->boules[pointeur].avant;
   }
   while(pointeur!=BOULES_MAX);

   // Les boules se dispersent...
   AdpcmStart(&ADPCM_EffetBombeDispersion,1,1);

   // Supprime toutes les boules
   nombre=BOULES_PERDU;
   while(boules->premiere!=BOULES_MAX)
   {
      for(pointeur=boules->premiere;pointeur!=BOULES_MAX;pointeur=boules->boules[pointeur].apres)
      {
         // La boule bouge...
         coord[pointeur].x+=coord[pointeur].dx;
         coord[pointeur].y+=coord[pointeur].dy;
         x=coord[pointeur].x>>VIRGULE_;
         y=coord[pointeur].y>>VIRGULE_;

         // Cette boule est-elle encore a l'ecran ?
         if((unsigned short)(x+RAYON)>XM+DIAMETRE || (unsigned short)(y+RAYON)>YM+DIAMETRE)
         {
            // Elle est sortie, on la supprime
            supprimeBoule(pointeur);
            ++nombre;
         }
         else
         {
            // Elle est encore la, on l'affiche
            affBoule(pointeur,x,y,BOULE_GRISE);
         }
      }

      // Affiche toutes les boules
      etat=gereFrame();
      if(etat!=ETAT_RIEN)
         return(etat);
   }

   // Rajoute quelques boules en guise de malus
   if(boules->nombre>nombre)
      boules->nombre-=nombre;
   else
      boules->nombre=0;

   // Reinitialise le lance boule
   lanceBoule.malus&=~LB_GRAY;
   if(lanceBoule.phase==LB_REPOS)
   {
      // Selection d'un nouvelle couleur
      lanceBoule.phase=LB_INIT;
   }
   else
   {
      // Attend que la boule tiree sorte de l'ecran
      while(lanceBoule.phase!=LB_INIT)
      {
         etat=gereFrame();
         if(etat!=ETAT_RIEN)
            return(etat);
      }
   }

   // On recommence comme si de rien n'etait
   return(ETAT_RIEN);
}

//////////////////
// notification //
//////////////////
void CODE_IN_IWRAM notification(unsigned short tile,unsigned char demiLargeur,signed short x,signed short y)
{
   unsigned short demiHauteur,forme,taille;

   // Retrouve les caracteristiques du sprite
   switch(demiLargeur)
   {
      case 4:
         demiHauteur=4;
         forme=0; // Square
         taille=0; // 8x8
         break;

      case 8:
         demiHauteur=4;
         forme=1<<14; // Wide
         taille=0<<14; // 16x8
         break;

      case 16:
         demiHauteur=8;
         forme=1<<14; // Wide
         taille=2<<14; // 32x16
         break;

      case 168:
         demiLargeur=16;
         demiHauteur=4;
         forme=1<<14; // Wide
         taille=1<<14; // 32x8
         break;

      default:
         return;
   }

   // Affiche le sprite
   sprites[notifications.pointeur].attribut1=((y-demiHauteur)&255)|(1<<13)|forme; // Sprite 256 couleurs
   sprites[notifications.pointeur].attribut2=((x-demiLargeur)&511)|taille;
   sprites[notifications.pointeur].attribut3=tile|(1<<10); // Priorite 1

   // Initialise le timer de ce sprite
   notifications.timer[notifications.pointeur-BOULES_MAX]=TIMER_NOTIF;

   // On prendra un autre sprite pour la prochaine notification
   if(notifications.pointeur<124)
      ++notifications.pointeur;
   else
      notifications.pointeur=BOULES_MAX;
}

/////////////////////
// malusDisableRay //
/////////////////////
void malusDisableRay(void)
{
   lanceBoule.malus|=LB_NORAY;
}

///////////////////////
// malusReverseShoot //
///////////////////////
void malusReverseShoot(void)
{
   lanceBoule.malus|=LB_REVERSE;
}

/////////////////////
// malusSlowMotion //
/////////////////////
void malusSlowMotion(void)
{
   lanceBoule.malus|=LB_SLOW;
}

///////////////////////
// malusCrazyControl //
///////////////////////
void malusCrazyControl(void)
{
   lanceBoule.malus|=LB_CRAZY;
}

///////////////////
// malusHidePath //
///////////////////
void malusHidePath(void)
{
   forceDMA(0,(void*)CHAR_BASE_BLOCK(0),XM*YM/4,DMA_32NOW);
}

/////////////////////
// malusColorPanic //
/////////////////////
void CODE_IN_IWRAM malusColorPanic(void)
{
   unsigned char pointeur;
   unsigned char couleur;

   // Reinitialise les compteurs de couleurs
   for(couleur=0;couleur<5;++couleur)
      boules->compteCouleurs[couleur]=0;

   // On change la couleur de toutes les boules !
   couleur=0;
   for(pointeur=boules->premiere;pointeur!=BOULES_MAX;pointeur=boules->boules[pointeur].apres)
   {
      boules->boules[pointeur].couleur=couleur;
      ++boules->compteCouleurs[couleur];
      if(++couleur>=niveaux.niveaux[niveaux.courant].couleurs)
         couleur=0;
   }
}

//////////////////
// malusTwister //
//////////////////
void malusTwister(void)
{
   lanceBoule.malus|=LB_TWISTER;
}

///////////////////
// bonusTimeGift //
///////////////////
void bonusTimeGift(void)
{
   chrono+=CHRONO_GIFT;
}

////////////////////
// bonusSortBalls //
////////////////////
void CODE_IN_IWRAM bonusSortBalls(void)
{
   unsigned char compte;
   unsigned char couleur;
   unsigned char pointeur;

   // On trie les boules selon leurs couleurs !
   compte=0;
   couleur=niveaux.niveaux[niveaux.courant].couleurs;
   for(pointeur=boules->premiere;pointeur!=BOULES_MAX;pointeur=boules->boules[pointeur].apres)
   {
      while(!compte)
         compte=boules->compteCouleurs[--couleur];
      --compte;
      boules->boules[pointeur].couleur=couleur;
   }
}

////////////////////
// bonusKillColor //
////////////////////
void CODE_IN_IWRAM bonusKillColor(void)
{
   unsigned char couleur;
   unsigned char pointeur;

   // Choisit une couleur existante
   couleur=rand()%niveaux.niveaux[niveaux.courant].couleurs;
   while(!boules->compteCouleurs[couleur])
      if(++couleur>=niveaux.niveaux[niveaux.courant].couleurs)
         couleur=0;

   // Supprime les boules de cette couleur !
   for(pointeur=boules->premiere;pointeur!=BOULES_MAX;pointeur=boules->boules[pointeur].apres)
      if(boules->boules[pointeur].couleur==couleur)
         supprimeBoule(pointeur);
}

///////////////////////
// bonusBasicControl //
///////////////////////
void bonusBasicControl(void)
{
   lanceBoule.malus=0;
}

///////////////////
// bonusWarpZone //
///////////////////
void bonusWarpZone(void)
{
   boules->nombre=niveaux.niveaux[niveaux.courant].nombreBoules;
   boules->premiere=BOULES_MAX;
}

////////////////////
// malusMoreBalls //
////////////////////
void malusMoreBalls(void)
{
   if(boules->nombre>BOULES_MOREBALLS)
      boules->nombre-=BOULES_MOREBALLS;
   else
      boules->nombre=0;
}

////////////////
// MALUSBONUS //
////////////////
const struct
{
   MalusBonus fonction;
   unsigned short tile;
   unsigned char demiLargeur;
   const Sound* son;
}
MALUSBONUS[]=
{
   {malusDisableRay,120,16,&ADPCM_EffetMalheureux},
   {malusReverseShoot,136,16,&ADPCM_EffetMalheureux},
   {malusSlowMotion,152,16,&ADPCM_EffetMalheureux},
   {malusCrazyControl,168,16,&ADPCM_EffetMalheureux},
   {malusHidePath,184,16,&ADPCM_EffetMalheureux},
   {(MalusBonus)malusColorPanic,200,16,&ADPCM_EffetMalheureux},
   {malusTwister,216,168,&ADPCM_EffetTwister},
   {bonusTimeGift,224,16,&ADPCM_EffetChronoGift},
   {(MalusBonus)bonusSortBalls,240,16,&ADPCM_EffetHeureux},
   {(MalusBonus)bonusKillColor,256,16,&ADPCM_EffetHeureux},
   {bonusBasicControl,272,16,&ADPCM_EffetHeureux},
   {bonusWarpZone,288,16,&ADPCM_EffetHeureux},
   {malusMoreBalls,304,16,&ADPCM_EffetMalheureux}
};

///////////////
// collision //
///////////////
void CODE_IN_IWRAM collision(unsigned char pointeur,signed long sens)
{
   unsigned char malusBonus;
   unsigned char premiere,derniere;
   unsigned char total;
   unsigned short L;
   signed short x,y;

   // Recupere les coordonnees de la boule touchee
   coordBoule(pointeur,&x,&y);

   // Collision avec une boule noire ?
   if(lanceBoule.couleur==BOULE_NOIRE)
   {
      // Petite surprise !
      malusBonus=rand()%(sizeof(MALUSBONUS)/sizeof(MALUSBONUS[0]));
      MALUSBONUS[malusBonus].fonction();
      AdpcmStart(MALUSBONUS[malusBonus].son,1,1);
      notification(MALUSBONUS[malusBonus].tile,MALUSBONUS[malusBonus].demiLargeur,x,y);
      return;
   }

   // Memorise la position de la boule touchee
   L=boules->boules[pointeur].L;

   // L'effet n'est pas le meme si on a tape devant ou derriere la boule !
   if(sens<0)
   {
      derniere=pointeur;
      pointeur=boules->boules[pointeur].avant;
      premiere=pointeur;
   }
   else
   {
      premiere=pointeur;
      derniere=boules->boules[pointeur].apres;
   }

   // Comptons le nombre de boules de la bonne couleur situees avant et apres
   total=1;
   while(premiere!=BOULES_MAX && boules->boules[premiere].couleur==lanceBoule.couleur)
   {
      premiere=boules->boules[premiere].avant;
      ++total;
   }
   while(derniere!=BOULES_MAX && boules->boules[derniere].couleur==lanceBoule.couleur)
   {
      derniere=boules->boules[derniere].apres;
      ++total;
   }

   // "total" est le nombre de boules de couleur identique (y compris la nouvelle boule)
   if(total>=3)
   {
      // On supprime la suite de boules
      if(premiere==BOULES_MAX)
         premiere=boules->premiere;
      else
         premiere=boules->boules[premiere].apres;
      do
      {
         supprimeBoule(premiere);
         premiere=boules->boules[premiere].apres;
      }
      while(premiere!=derniere);

      // Mise a jour du score
      if(total<3+(sizeof(POINTS)/sizeof(POINTS[0])))
         total-=3;
      else
         total=(sizeof(POINTS)/sizeof(POINTS[0]))-1;

      score+=POINTS[total].points;
      notification(POINTS[total].tile,POINTS[total].demiLargeur,x,y);

      // Bonus de temps ?
      if(total>=CHRONO_BOULES-3)
      {
         chrono+=CHRONO_BONUS;
         notification(100,8,x,y+8);
         AdpcmStart(&ADPCM_EffetChronoGift,1,1);
      }
      else
         AdpcmStart(&ADPCM_EffetPoints,1,1);
   }
   else
   {
      // On insert la nouvelle boule et on la colle a la boule touchee
      insertBoule(pointeur,lanceBoule.couleur,L);
   }
}

////////////////
// gereBoules //
////////////////
unsigned char CODE_IN_IWRAM gereBoules(void)
{
   Niveau* niveau;
   Element* element;
   unsigned char ptrElement;
   unsigned char ptrBoule,ptrCollision=BOULES_MAX;
   unsigned char couleur;
   signed short x,dx,y,dy,a=0;
   signed short vitesseN,vitesseR;
   signed short L=0,l=0;
   signed long sens=0;

   // On prend les elements du niveau courant
   niveau=&niveaux.niveaux[niveaux.courant];
   ptrElement=niveau->parcours->debut;

   // Doit-on ajouter une boule ?
   if(boules->nombre<niveau->nombreBoules && (boules->premiere==BOULES_MAX || boules->boules[boules->premiere].L>DIAMETRE))
   {
      // On choisit une couleur (on ne change pas trop souvent quand meme)...
      if(boules->premiere!=BOULES_MAX && rand()&1)
         couleur=boules->boules[boules->premiere].couleur;
      else
         couleur=rand()%niveau->couleurs;

      // On ajoute une boule
      if(insertBoule(BOULES_MAX,couleur,0))
         ++boules->nombre;
   }
   else if(boules->premiere==BOULES_MAX)
   {
      // On a termine le niveau !
      return(gagne());
   }

   // Acceleration ?
   if(REG_TOUCHES&TOUCHE_B)
      vitesseN=VITESSE_BOULE;
   else
      vitesseN=VITESSE_BOULE*2;
   vitesseR=vitesseN+VITESSE_BOULE;

   // On affiche toutes les boules existantes
   for(ptrBoule=boules->premiere;ptrBoule!=BOULES_MAX;ptrBoule=boules->boules[ptrBoule].apres)
   {
      // Les boules bougent !
      if(ptrBoule==boules->premiere)
      {
         // La 1ere boule avance...
         L=boules->boules[ptrBoule].L+vitesseN;
         l=L;
      }
      else
      {
         // Les autres boules sont poussees...
         l-=L;
         L+=DIAMETRE;
         if(L<boules->boules[ptrBoule].L)
         {
            // Cette boule-ci recule !
            L=boules->boules[ptrBoule].L-VITESSE_BOULE;
         }
         else if(L>boules->boules[ptrBoule].L+vitesseR)
         {
            // Cette boule-ci avance...
            L=boules->boules[ptrBoule].L+vitesseR;
         }
         l+=L;
      }
      boules->boules[ptrBoule].L=L;

      // On cherche l'element sur lequel on est
      element=&niveaux.elements[ptrElement];
      while(l>element->L)
      {
         if(ptrElement==niveau->parcours->fin)
         {
            // Perdu !
            return(perdu(ptrBoule));
         }
         l-=element->L;
         element=&niveaux.elements[++ptrElement];
      }

      // Calcul des coordonnees
      switch(element->type)
      {
         case LIGNE:
            x=element->info.ligne.x1+((l*element->info.ligne.vx)>>VIRGULE_);
            y=element->info.ligne.y1+((l*element->info.ligne.vy)>>VIRGULE_);
            break;

         case ARC:
            a=element->info.arc.a1+((l*element->info.arc.va)>>VIRGULE_);
            x=element->info.arc.x+((element->info.arc.r*COS(a))>>VIRGULE_);
            y=element->info.arc.y-((element->info.arc.r*SIN(a))>>VIRGULE_);
            break;

         default:
            x=XM;
            y=YM;
      }

      // Deplacement du sprite
      affBoule(ptrBoule,x,y,boules->boules[ptrBoule].couleur);

      // Verifions s'il y a collision...
      if(lanceBoule.phase==LB_TIR)
      {
         dx=(lanceBoule.xBoule>>VIRGULE_)-x;
         dy=(lanceBoule.yBoule>>VIRGULE_)-y;

         if(dx*dx+dy*dy<=DIAMETRE*DIAMETRE)
         {
            // On passe en mode "collision" !
            lanceBoule.phase=LB_COLLISION;
            ptrCollision=ptrBoule;

            // Regarde si on a touche l'avant ou l'arriere de la boule
            switch(element->type)
            {
               case LIGNE:
                  sens=dx*element->info.ligne.vx+dy*element->info.ligne.vy;
                  break;

               case ARC:
                  sens=dx*SIN(a)+dy*COS(a);
                  if(element->info.arc.va>0)
                     sens=-sens;
                  break;
            }
         }
      }
   }

   // Gestion de la collision
   if(lanceBoule.phase==LB_COLLISION)
   {
      collision(ptrCollision,sens);
      lanceBoule.phase=LB_INIT;
   }

   // Gestion du lance boule et affichage de toutes les boules
   return(gereFrame());
}
