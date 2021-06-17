/*
** Mario Balls - Sources\Boules\Niveaux.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include "Boules.h"

////////////////////////
// Variables globales //
////////////////////////
extern const unsigned short Boo_Palette[];
extern const unsigned char Boo_Tiles[];
extern const unsigned char Boo_Map[];

extern const unsigned short DK_Palette[];
extern const unsigned char DK_Tiles[];
extern const unsigned char DK_Map[];

extern const unsigned short Daisy_Palette[];
extern const unsigned char Daisy_Tiles[];
extern const unsigned char Daisy_Map[];

extern const unsigned short Mario_Palette[];
extern const unsigned char Mario_Tiles[];
extern const unsigned char Mario_Map[];

extern const unsigned short Peach_Palette[];
extern const unsigned char Peach_Tiles[];
extern const unsigned char Peach_Map[];

extern const unsigned short SmsButler_Palette[];
extern const unsigned char SmsButler_Tiles[];
extern const unsigned char SmsButler_Map[];

extern const unsigned short Toad_Palette[];
extern const unsigned char Toad_Tiles[];
extern const unsigned char Toad_Map[];

extern const unsigned short Waluigi_Palette[];
extern const unsigned char Waluigi_Tiles[];
extern const unsigned char Waluigi_Map[];

extern const unsigned short Wario_Palette[];
extern const unsigned char Wario_Tiles[];
extern const unsigned char Wario_Map[];

extern const unsigned short Arcadia_Palette[];
extern const unsigned char Arcadia_Tiles[];
extern const unsigned char Arcadia_Map[];

extern const unsigned short CLon_Palette[];
extern const unsigned char CLon_Tiles[];
extern const unsigned char CLon_Map[];

extern const unsigned short Foxy_Palette[];
extern const unsigned char Foxy_Tiles[];
extern const unsigned char Foxy_Map[];

extern const unsigned short JuyLe_Palette[];
extern const unsigned char JuyLe_Tiles[];
extern const unsigned char JuyLe_Map[];

extern const unsigned short Kartapus_Palette[];
extern const unsigned char Kartapus_Tiles[];
extern const unsigned char Kartapus_Map[];

extern const unsigned short LaBoule_Palette[];
extern const unsigned char LaBoule_Tiles[];
extern const unsigned char LaBoule_Map[];

extern const unsigned short Lanza_Palette[];
extern const unsigned char Lanza_Tiles[];
extern const unsigned char Lanza_Map[];

extern const unsigned short Legendaryboy_Palette[];
extern const unsigned char Legendaryboy_Tiles[];
extern const unsigned char Legendaryboy_Map[];

extern const unsigned short MrSlip_Palette[];
extern const unsigned char MrSlip_Tiles[];
extern const unsigned char MrSlip_Map[];

extern const unsigned short NMaster_Palette[];
extern const unsigned char NMaster_Tiles[];
extern const unsigned char NMaster_Map[];

extern const unsigned short Nrx_Palette[];
extern const unsigned char Nrx_Tiles[];
extern const unsigned char Nrx_Map[];

extern const unsigned short Phantom_Palette[];
extern const unsigned char Phantom_Tiles[];
extern const unsigned char Phantom_Map[];

extern const unsigned short Poppu_Palette[];
extern const unsigned char Poppu_Tiles[];
extern const unsigned char Poppu_Map[];

extern const unsigned short Sanctuaire_Palette[];
extern const unsigned char Sanctuaire_Tiles[];
extern const unsigned char Sanctuaire_Map[];

extern const unsigned short ShivaEden_Palette[];
extern const unsigned char ShivaEden_Tiles[];
extern const unsigned char ShivaEden_Map[];

extern const unsigned short ShockTheDarkMage_Palette[];
extern const unsigned char ShockTheDarkMage_Tiles[];
extern const unsigned char ShockTheDarkMage_Map[];

extern const unsigned short TeHashiX_Palette[];
extern const unsigned char TeHashiX_Tiles[];
extern const unsigned char TeHashiX_Map[];

extern const unsigned short YannOuxix_Palette[];
extern const unsigned char YannOuxix_Tiles[];
extern const unsigned char YannOuxix_Map[];

extern const unsigned short Yodajr_Palette[];
extern const unsigned char Yodajr_Tiles[];
extern const unsigned char Yodajr_Map[];

extern const unsigned short ZiapaT_Palette[];
extern const unsigned char ZiapaT_Tiles[];
extern const unsigned char ZiapaT_Map[];

extern const unsigned short decamail_Palette[];
extern const unsigned char decamail_Tiles[];
extern const unsigned char decamail_Map[];

extern const unsigned short dragonir_Palette[];
extern const unsigned char dragonir_Tiles[];
extern const unsigned char dragonir_Map[];

extern const unsigned short geogeo_Palette[];
extern const unsigned char geogeo_Tiles[];
extern const unsigned char geogeo_Map[];

extern const unsigned short greeeg_Palette[];
extern const unsigned char greeeg_Tiles[];
extern const unsigned char greeeg_Map[];

extern const unsigned short lomig_Palette[];
extern const unsigned char lomig_Tiles[];
extern const unsigned char lomig_Map[];

extern const unsigned short lord_pingui_Palette[];
extern const unsigned char lord_pingui_Tiles[];
extern const unsigned char lord_pingui_Map[];

extern const unsigned short nes_Palette[];
extern const unsigned char nes_Tiles[];
extern const unsigned char nes_Map[];

extern const unsigned short tsZele_Palette[];
extern const unsigned char tsZele_Tiles[];
extern const unsigned char tsZele_Map[];

extern const unsigned short gus_Palette[];
extern const unsigned char gus_Tiles[];
extern const unsigned char gus_Map[];

extern const unsigned short Lestat_Palette[];
extern const unsigned char Lestat_Tiles[];
extern const unsigned char Lestat_Map[];

extern const unsigned short maxlebourrin_Palette[];
extern const unsigned char maxlebourrin_Tiles[];
extern const unsigned char maxlebourrin_Map[];

extern const unsigned short jackachi_Palette[];
extern const unsigned char jackachi_Tiles[];
extern const unsigned char jackachi_Map[];

extern const unsigned short kinski_Palette[];
extern const unsigned char kinski_Tiles[];
extern const unsigned char kinski_Map[];

extern const unsigned short Mirada2000_Palette[];
extern const unsigned char Mirada2000_Tiles[];
extern const unsigned char Mirada2000_Map[];

// Description des differents fonds
const Fonds fondsMario=
{
   9,
   {
      {(unsigned short*)Boo_Palette,(unsigned char*)Boo_Tiles,10816/4,(unsigned char*)Boo_Map},
      {(unsigned short*)Toad_Palette,(unsigned char*)Toad_Tiles,6528/4,(unsigned char*)Toad_Map},
      {(unsigned short*)DK_Palette,(unsigned char*)DK_Tiles,9600/4,(unsigned char*)DK_Map},
      {(unsigned short*)Daisy_Palette,(unsigned char*)Daisy_Tiles,7424/4,(unsigned char*)Daisy_Map},
      {(unsigned short*)Waluigi_Palette,(unsigned char*)Waluigi_Tiles,5568/4,(unsigned char*)Waluigi_Map},
      {(unsigned short*)Peach_Palette,(unsigned char*)Peach_Tiles,6976/4,(unsigned char*)Peach_Map},
      {(unsigned short*)Mario_Palette,(unsigned char*)Mario_Tiles,7552/4,(unsigned char*)Mario_Map},
      {(unsigned short*)SmsButler_Palette,(unsigned char*)SmsButler_Tiles,8576/4,(unsigned char*)SmsButler_Map},
      {(unsigned short*)Wario_Palette,(unsigned char*)Wario_Tiles,9216/4,(unsigned char*)Wario_Map}
   }
};

const Fonds fondsPA=
{
   34,
   {
      {(unsigned short*)Nrx_Palette,(unsigned char*)Nrx_Tiles,9536/4,(unsigned char*)Nrx_Map},
      {(unsigned short*)jackachi_Palette,(unsigned char*)jackachi_Tiles,14080/4,(unsigned char*)jackachi_Map},
      {(unsigned short*)Arcadia_Palette,(unsigned char*)Arcadia_Tiles,11904/4,(unsigned char*)Arcadia_Map},
      {(unsigned short*)Yodajr_Palette,(unsigned char*)Yodajr_Tiles,6720/4,(unsigned char*)Yodajr_Map},
      {(unsigned short*)greeeg_Palette,(unsigned char*)greeeg_Tiles,12416/4,(unsigned char*)greeeg_Map},
      {(unsigned short*)ZiapaT_Palette,(unsigned char*)ZiapaT_Tiles,15168/4,(unsigned char*)ZiapaT_Map},
      {(unsigned short*)lord_pingui_Palette,(unsigned char*)lord_pingui_Tiles,10432/4,(unsigned char*)lord_pingui_Map},
      {(unsigned short*)nes_Palette,(unsigned char*)nes_Tiles,12480/4,(unsigned char*)nes_Map},
      {(unsigned short*)tsZele_Palette,(unsigned char*)tsZele_Tiles,16384/4,(unsigned char*)tsZele_Map},
      {(unsigned short*)Lestat_Palette,(unsigned char*)Lestat_Tiles,16064/4,(unsigned char*)Lestat_Map},
      {(unsigned short*)maxlebourrin_Palette,(unsigned char*)maxlebourrin_Tiles,11904/4,(unsigned char*)maxlebourrin_Map},
      {(unsigned short*)Foxy_Palette,(unsigned char*)Foxy_Tiles,8128/4,(unsigned char*)Foxy_Map},
      {(unsigned short*)dragonir_Palette,(unsigned char*)dragonir_Tiles,16384/4,(unsigned char*)dragonir_Map},
      {(unsigned short*)JuyLe_Palette,(unsigned char*)JuyLe_Tiles,12352/4,(unsigned char*)JuyLe_Map},
      {(unsigned short*)ShockTheDarkMage_Palette,(unsigned char*)ShockTheDarkMage_Tiles,12352/4,(unsigned char*)ShockTheDarkMage_Map},
      {(unsigned short*)Phantom_Palette,(unsigned char*)Phantom_Tiles,11392/4,(unsigned char*)Phantom_Map},
      {(unsigned short*)Kartapus_Palette,(unsigned char*)Kartapus_Tiles,15488/4,(unsigned char*)Kartapus_Map},
      {(unsigned short*)LaBoule_Palette,(unsigned char*)LaBoule_Tiles,14336/4,(unsigned char*)LaBoule_Map},
      {(unsigned short*)Legendaryboy_Palette,(unsigned char*)Legendaryboy_Tiles,8960/4,(unsigned char*)Legendaryboy_Map},
      {(unsigned short*)MrSlip_Palette,(unsigned char*)MrSlip_Tiles,14336/4,(unsigned char*)MrSlip_Map},
      {(unsigned short*)NMaster_Palette,(unsigned char*)NMaster_Tiles,12160/4,(unsigned char*)NMaster_Map},
      {(unsigned short*)CLon_Palette,(unsigned char*)CLon_Tiles,14912/4,(unsigned char*)CLon_Map},
      {(unsigned short*)Poppu_Palette,(unsigned char*)Poppu_Tiles,14336/4,(unsigned char*)Poppu_Map},
      {(unsigned short*)Sanctuaire_Palette,(unsigned char*)Sanctuaire_Tiles,7232/4,(unsigned char*)Sanctuaire_Map},
      {(unsigned short*)geogeo_Palette,(unsigned char*)geogeo_Tiles,14592/4,(unsigned char*)geogeo_Map},
      {(unsigned short*)kinski_Palette,(unsigned char*)kinski_Tiles,12352/4,(unsigned char*)kinski_Map},
      {(unsigned short*)Lanza_Palette,(unsigned char*)Lanza_Tiles,11520/4,(unsigned char*)Lanza_Map},
      {(unsigned short*)ShivaEden_Palette,(unsigned char*)ShivaEden_Tiles,10240/4,(unsigned char*)ShivaEden_Map},
      {(unsigned short*)TeHashiX_Palette,(unsigned char*)TeHashiX_Tiles,12352/4,(unsigned char*)TeHashiX_Map},
      {(unsigned short*)YannOuxix_Palette,(unsigned char*)YannOuxix_Tiles,10176/4,(unsigned char*)YannOuxix_Map},
      {(unsigned short*)decamail_Palette,(unsigned char*)decamail_Tiles,16256/4,(unsigned char*)decamail_Map},
      {(unsigned short*)gus_Palette,(unsigned char*)gus_Tiles,11328/4,(unsigned char*)gus_Map},
      {(unsigned short*)lomig_Palette,(unsigned char*)lomig_Tiles,16384/4,(unsigned char*)lomig_Map},
      {(unsigned short*)Mirada2000_Palette,(unsigned char*)Mirada2000_Tiles,9088/4,(unsigned char*)Mirada2000_Map}
   }
};

// Description des differents niveaux
Element e[]=
{
   // SNAIL
   {LIGNE,{{220,160+RAYON,220,30}}},
   {ARC,{{200,30,20,0,SINNB/2}}},
   {LIGNE,{{180,30,180,65}}},
   {ARC,{{100,65,80,0,-SINNB/4}}},
   {LIGNE,{{100,145,50,145}}},
   {ARC,{{50,115,30,-SINNB/4,-SINNB/2}}},
   {LIGNE,{{20,115,20,45}}},
   {ARC,{{50,45,30,SINNB/2,SINNB/4}}},
   {LIGNE,{{50,15,100,15}}},
   {ARC,{{100,65,50,SINNB/4,-SINNB/2}}},

   // SNAKE
   {LIGNE,{{220,-RAYON,220,20}}},
   {ARC,{{200,20,20,0,-SINNB/4}}},
   {LIGNE,{{200,40,70,40}}},
   {ARC,{{70,60,20,SINNB/4,3*SINNB/4}}},
   {LIGNE,{{70,80,190,80}}},
   {ARC,{{190,110,30,SINNB/4,-SINNB/4}}},
   {LIGNE,{{190,140,40,140}}},
   {ARC,{{40,120,20,-SINNB/4,-SINNB/2}}},
   {LIGNE,{{20,120,20,20}}},

   // ARROBAS
   {LIGNE,{{120,-RAYON,120,80}}},
   {ARC,{{100,80,20,0,-SINNB/2}}},
   {ARC,{{120,80,40,SINNB/2,0}}},
   {ARC,{{100,80,60,0,-SINNB/4}}},
   {LIGNE,{{100,140,50,140}}},
   {ARC,{{50,110,30,-SINNB/4,-SINNB/2}}},
   {LIGNE,{{20,110,20,50}}},
   {ARC,{{50,50,30,SINNB/2,SINNB/4}}},
   {LIGNE,{{50,20,190,20}}},
   {ARC,{{190,50,30,SINNB/4,0}}},
   {LIGNE,{{220,50,220,140}}},

   // NO EXIT
   {LIGNE,{{140,-RAYON,140,75}}},
   {ARC,{{120,75,20,0,-SINNB/2}}},
   {ARC,{{130,75,30,SINNB/2,0}}},
   {ARC,{{120,75,40,0,-SINNB/2}}},
   {ARC,{{130,75,50,SINNB/2,0}}},
   {ARC,{{120,75,60,0,-SINNB/2}}},
   {ARC,{{130,75,70,SINNB/2,0}}},
   {ARC,{{120,75,80,0,-SINNB/2}}},
   {LIGNE,{{40,75,40,20}}},

   // IN-OUT
   {ARC,{{240,0,50,-SINNB/8,-SINNB/2}}},
   {ARC,{{175,0,15,0,SINNB/2}}},
   {ARC,{{120,0,40,0,-SINNB/2}}},
   {ARC,{{65,0,15,0,SINNB/2}}},
   {ARC,{{0,0,50,0,-SINNB/4}}},
   {ARC,{{0,80,30,SINNB/4,3*SINNB/4}}},
   {ARC,{{0,160,50,SINNB/4,0}}},
   {ARC,{{65,160,15,-SINNB/2,0}}},
   {ARC,{{120,160,40,SINNB/2,0}}},
   {ARC,{{175,160,15,-SINNB/2,0}}},
   {ARC,{{240,160,50,SINNB/2,SINNB/4}}},
   {ARC,{{240,95,15,-SINNB/4,SINNB/4}}},
   {LIGNE,{{240,80,150,80}}},

   // RIVER
   {LIGNE,{{-RAYON,10,105,10}}},
   {ARC,{{105,135,125,SINNB/4,0}}},
   {ARC,{{215,135,15,0,-SINNB/2}}},
   {ARC,{{105,135,95,0,SINNB/4}}},
   {LIGNE,{{105,40,25,40}}},
   {ARC,{{25,55,15,SINNB/4,3*SINNB/4}}},
   {LIGNE,{{25,70,105,70}}},
   {ARC,{{105,135,65,SINNB/4,0}}},
   {ARC,{{155,135,15,0,-SINNB/2}}},
   {ARC,{{105,135,35,0,SINNB/4}}},
   {LIGNE,{{105,100,25,100}}},

   // JUMP
   {LIGNE,{{-RAYON,12,211,12}}},
   {ARC,{{211,29,17,SINNB/4,-SINNB/4}}},
   {LIGNE,{{211,46,29,46}}},
   {ARC,{{29,63,17,SINNB/4,3*SINNB/4}}},
   {LIGNE,{{29,80,90,80}}},
   {LIGNE,{{150,80,211,80}}},
   {ARC,{{211,97,17,SINNB/4,-SINNB/4}}},
   {LIGNE,{{211,114,29,114}}},
   {ARC,{{29,131,17,SINNB/4,3*SINNB/4}}},
   {LIGNE,{{29,148,211,148}}},

   // WAVES
   {ARC,{{0,44,24,3*SINNB/8,0}}},
   {ARC,{{48,44,24,-SINNB/2,0}}},
   {ARC,{{96,44,24,SINNB/2,0}}},
   {ARC,{{144,44,24,-SINNB/2,0}}},
   {ARC,{{192,44,24,SINNB/2,0}}},
   {ARC,{{240,44,24,-SINNB/2,-SINNB/4}}},
   {ARC,{{240,80,12,SINNB/4,-SINNB/4}}},
   {ARC,{{240,116,24,SINNB/4,SINNB/2}}},
   {ARC,{{192,116,24,0,-SINNB/2}}},
   {ARC,{{144,116,24,0,SINNB/2}}},
   {ARC,{{96,116,24,0,-SINNB/2}}},
   {ARC,{{48,116,24,0,SINNB/2}}},

   // LITTLE FLOWER
   {ARC,{{120,-5,15,SINNB/8,-SINNB/4}}},
   {ARC,{{120,30,20,90*SINNB/360,216*SINNB/360}}},
   {ARC,{{94,49,12,36*SINNB/360,-144*SINNB/360}}},
   {ARC,{{68,68,20,36*SINNB/360,288*SINNB/360}}},
   {ARC,{{78,98,12,108*SINNB/360,-72*SINNB/360}}},
   {ARC,{{88,129,20,-252*SINNB/360,0*SINNB/360}}},
   {ARC,{{120,129,12,180*SINNB/360,0*SINNB/360}}},
   {ARC,{{152,129,20,-180*SINNB/360,72*SINNB/360}}},
   {ARC,{{162,98,12,252*SINNB/360,72*SINNB/360}}},
   {ARC,{{172,68,20,-108*SINNB/360,144*SINNB/360}}},
   {ARC,{{146,49,12,-36*SINNB/360,-216*SINNB/360}}},

   // HEART
   {LIGNE,{{110+RAYON*1.34,160+RAYON,35,104}}},
   {ARC,{{60,60,50,240*SINNB/360,0*SINNB/360}}},
   {ARC,{{120,60,10,-180*SINNB/360,0*SINNB/360}}},
   {ARC,{{180,60,50,180*SINNB/360,-60*SINNB/360}}},
   {LIGNE,{{205,104,130+RAYON*1.34,160-RAYON}}},

   // MTR
   {LIGNE,{{80,-RAYON,80,0}}},
   {ARC,{{120,0,40,-SINNB/2,0}}},
   {ARC,{{170,0,10,SINNB/2,0}}},
   {ARC,{{120,0,60,0,-SINNB/2}}},
   {LIGNE,{{60,0,60,-RAYON}}},
   {LIGNE,{{120,-RAYON,120,160+RAYON}}},
   {LIGNE,{{60,160+RAYON,60,160}}},
   {ARC,{{120,160,60,SINNB/2,0}}},
   {ARC,{{170,160,10,0,-SINNB/2}}},
   {ARC,{{120,160,40,0,3*SINNB/8}}},

   // HIGHWAY
   {LIGNE,{{180,-RAYON,180,160+RAYON}}},
   {LIGNE,{{30,160+RAYON,30,-RAYON}}},
   {LIGNE,{{90,160+RAYON,90,-RAYON}}},
   {LIGNE,{{150,-RAYON,150,160+RAYON}}},
   {LIGNE,{{60,160+RAYON,60,-RAYON}}},
   {LIGNE,{{210,-RAYON,210,150}}},

   // HILLS
   {LIGNE,{{10+RAYON,160+RAYON,10+RAYON,60}}},
   {ARC,{{55,60,45-RAYON,SINNB/2,0}}},
   {LIGNE,{{100-RAYON,60,100-RAYON,160+RAYON}}},
   {LIGNE,{{100+RAYON,160+RAYON,100+RAYON,100}}},
   {ARC,{{130,100,30-RAYON,SINNB/2,0}}},
   {LIGNE,{{160-RAYON,100,160-RAYON,160+RAYON}}},
   {LIGNE,{{160+RAYON,160+RAYON,160+RAYON,120}}},
   {ARC,{{180,120,20-RAYON,SINNB/2,0}}},
   {LIGNE,{{200-RAYON,120,200-RAYON,160+RAYON}}},
   {LIGNE,{{200+RAYON,160+RAYON,200+RAYON,140}}},
   {ARC,{{215,140,15-RAYON,SINNB/2,SINNB/8}}},

   // ESCALATOR
   {LIGNE,{{-RAYON,10,8,10}}},
   {ARC,{{8,24,14,SINNB/4,0}}},
   {ARC,{{36,24,14,-SINNB/2,-SINNB/4}}},
   {LIGNE,{{36,38,60,38}}},
   {ARC,{{60,52,14,SINNB/4,0}}},
   {ARC,{{88,52,14,-SINNB/2,-SINNB/4}}},
   {LIGNE,{{88,66,112,66}}},
   {ARC,{{112,80,14,SINNB/4,0}}},
   {ARC,{{140,80,14,-SINNB/2,-SINNB/4}}},
   {LIGNE,{{140,94,164,94}}},
   {ARC,{{164,108,14,SINNB/4,0}}},
   {ARC,{{192,108,14,-SINNB/2,-SINNB/4}}},
   {LIGNE,{{192,122,216,122}}},
   {ARC,{{216,136,14,SINNB/4,-SINNB/4}}},
   {LIGNE,{{216,150,192,150}}},
   {ARC,{{192,136,14,-SINNB/4,-123*SINNB/360}}},
   {LIGNE,{{184,148,10,54}}},

   // MUSHROOM
   {LIGNE,{{-RAYON,140,72,140}}},
   {ARC,{{72,112,28,-SINNB/4,0}}},
   {ARC,{{80,112,20,0,SINNB/4}}},
   {LIGNE,{{80,92,50,92}}},
   {ARC,{{50,62,30,3*SINNB/4,109.5*SINNB/360}}},
   {ARC,{{120,260,240,109.5*SINNB/360,70.5*SINNB/360}}},
   {ARC,{{190,62,30,70.5*SINNB/360,-SINNB/4}}},
   {LIGNE,{{190,92,160,92}}},
   {ARC,{{160,112,20,SINNB/4,SINNB/2}}},
   {ARC,{{168,112,28,SINNB/2,3*SINNB/4}}},
   {LIGNE,{{168,140,220,140}}},

   // BIG DICK
   {LIGNE,{{-RAYON,20,210,20}}},
   {ARC,{{210,40,20,SINNB/4,-SINNB/4}}},
   {LIGNE,{{210,60,78,60}}},
   {ARC,{{78,72,12,SINNB/4,5*SINNB/8}}},
   {ARC,{{45,105,35,SINNB/8,-5*SINNB/8}}},

   // WWW.PLAYERADVANCE.ORG
   {LIGNE,{{-RAYON,90,75,90}}},
   {ARC,{{75,55,35,-SINNB/4,SINNB/4}}},
   {LIGNE,{{75,20,40,20}}},
   {ARC,{{40,40,20,SINNB/4,SINNB/2}}},
   {LIGNE,{{20,40,20,160+RAYON}}},
   {LIGNE,{{130,160+RAYON,130,50}}},
   {ARC,{{160,50,30,SINNB/2,SINNB/4}}},
   {LIGNE,{{160,20,190,20}}},
   {ARC,{{190,50,30,SINNB/4,0}}},
   {LIGNE,{{220,50,220,160+RAYON}}},
   {LIGNE,{{240+RAYON,90,145,90}}}
};

Parcours p[]=
{
   {0,9,100,65,0,"SNAIL"},                            // 0
   {10,18,120,110,SINNB/4,"SNAKE"},                   // 1
   {19,29,180,140,3*SINNB/8,"ARROBAS"},               // 2
   {30,38,120,75,SINNB/4,"NO EXIT"},                  // 3
   {39,51,120,80,SINNB/8,"IN-OUT"},                   // 4
   {52,62,65,135,SINNB/4,"RIVER"},                    // 5
   {63,72,120,80,3*SINNB/8,"JUMP"},                   // 6
   {73,84,96,80,3*SINNB/8,"WAVES"},                   // 7
   {85,95,120,80,SINNB/4,"LITTLE FLOWER"},            // 8
   {96,100,120,110,-3*SINNB/8,"HEART"},               // 9
   {101,110,50,80,SINNB/8,"MTR"},                     // 10
   {111,116,120,80,SINNB/8,"HIGHWAY"},                // 11
   {117,127,160,30,SINNB/2,"HILLS"},                  // 12
   {128,144,180,40,SINNB/2,"ESCALATOR"},              // 13
   {145,155,120,60,5*SINNB/8,"MUSHROOM"},             // 14
   {156,160,180,120,3*SINNB/8,"BIG DICK"},            // 15
   {161,171,90,130,3*SINNB/8,"WWW.PLAYERADVANCE.ORG"} // 16
};

Niveau n[]=
{
   // 2 couleurs
   {&p[0],2,20},
   {&p[16],2,20},
   {&p[1],2,20},
   {&p[2],2,20},
   {&p[11],2,30},
   {&p[4],2,20},
   {&p[14],2,40},
   {&p[7],2,20},
   {&p[12],2,30},

   // 3 couleurs
   {&p[6],3,30},
   {&p[5],3,40},
   {&p[8],3,30},
   {&p[9],3,30},
   {&p[0],3,30},
   {&p[3],3,30},
   {&p[1],3,30},
   {&p[2],3,30},
   {&p[15],3,40},

   // 4 couleurs
   {&p[4],4,30},
   {&p[10],4,30},
   {&p[7],4,30},
   {&p[14],4,50},
   {&p[5],4,40},
   {&p[9],4,30},
   {&p[16],4,40},
   {&p[3],4,40},
   {&p[13],4,50},

   // 5 couleurs
   {&p[2],5,40},
   {&p[11],5,50},
   {&p[4],5,40},
   {&p[10],5,40},
   {&p[7],5,40},
   {&p[12],5,50},
   {&p[6],5,50},
   {&p[5],5,50},
   {&p[15],5,60}
};

Niveaux niveaux={0,36,e,n};
