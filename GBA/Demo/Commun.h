#ifndef COMMUN_H
#define COMMUN_H

// DMA
#define REG_DMA3SAD *(volatile unsigned int*)0x40000D4
#define REG_DMA3DAD *(volatile unsigned int*)0x40000D8
#define REG_DMA3CNT *(volatile unsigned int*)0x40000DC
#define DMA_ENABLE  0x80000000
#define DMA_32      0x04000000

// Ecran
#define REG_DISPCNT  *(volatile unsigned long*)0x4000000
#define REG_DISPSTAT *(volatile unsigned short*)0x4000004
#define REG_DISPVCNT	*(volatile unsigned short*)0x4000006

#define BACKVRAM   0xA000
#define BACKBUFFER 0x10

#define BG2_ENABLE 0x400
#define REG_BG2CNT *(volatile unsigned short*)0x400000C
#define REG_BG2X   *(volatile unsigned long*)0x4000028
#define REG_BG2Y   *(volatile unsigned long*)0x400002C
#define REG_BG2PA  *(volatile unsigned short*)0x4000020
#define REG_BG2PB  *(volatile unsigned short*)0x4000022
#define REG_BG2PC  *(volatile unsigned short*)0x4000024
#define REG_BG2PD  *(volatile unsigned short*)0x4000026

#define RGB(r,g,b) ((r)|((g)<<5)|((b)<<10))

#define XM4 240
#define YM4 160
#define XO4 (XM4/2)
#define YO4 (YM4/2)

#define XM5 160
#define YM5 128
#define XO5 (XM5/2)
#define YO5 (YM5/2)

// Memoire
#define REG_WSCNT  *(unsigned short*)0x4000204
#define BEST_WSCNT 0x4317

#define MULTIBOOT volatile const short __gba_multiboot=1;

#define EWRAM  ((volatile unsigned char*)0x02000000)  // 256KB
#define IWRAM  ((volatile unsigned char*)0x03000000)  // 32KB (rapide)
#define IORAM  ((volatile unsigned char*)0x04000000)  // 1KB
#define PALRAM ((volatile unsigned short*)0x05000000) // 0x200 mots
#define VRAM   ((volatile unsigned short*)0x06000000) // 0xC000 mots
#define ROM    ((volatile unsigned char*)0x08000000)  // 32MB

#define DATA_IN_EWRAM __attribute__ ((section(".ewram")))
#define DATA_IN_IWRAM __attribute__ ((section(".iwram")))
#define CODE_IN_IWRAM __attribute__ ((section(".iwram"),long_call))

// Math
#define PI       3.14159265
#define VIRGULE_ 13
#define VIRGULE  (1<<VIRGULE_)
#define SINNB    256
#define INVNB    2048

// Touches
#define REG_TOUCHES   *(volatile unsigned long*)0x4000130
#define TOUCHE_A      1
#define TOUCHE_B      2
#define TOUCHE_SELECT 4
#define TOUCHE_START  8
#define TOUCHE_DROITE 16
#define TOUCHE_GAUCHE 32
#define TOUCHE_HAUT   64
#define TOUCHE_BAS    128
#define TOUCHE_R      256
#define TOUCHE_L      512

// Variables globales publiques
volatile unsigned short* ecran;
signed short*            SINUS;
signed short*            INV;

// Fonctions publiques
void initCommun(void);
void afficheCommun(void);

#endif // COMMUN_H
