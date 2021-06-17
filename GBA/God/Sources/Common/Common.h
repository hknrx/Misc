/*
** God - Sources\Common\Common.h
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

#ifndef COMMON_H
#define COMMON_H

////////////////
// Inclusions //
////////////////
#include <stdlib.h>
#include "Adpcm\Decoder\Adpcm.h"

////////////
// Macros //
////////////

// DMA
#define REG_DMA0CNT_H *(volatile unsigned short*)0x40000BA
#define REG_DMA1CNT_H *(volatile unsigned short*)0x40000C6
#define REG_DMA2CNT_H *(volatile unsigned short*)0x40000D2
#define REG_DMA3CNT_H *(volatile unsigned short*)0x40000DE
#define REG_DMA3SAD   *(volatile unsigned long*)0x40000D4
#define REG_DMA3DAD   *(volatile unsigned long*)0x40000D8
#define REG_DMA3CNT_L *(volatile unsigned short*)0x40000DC
#define DMA_SRC_FIXED 0x0100
#define DMA_ENABLE    0x8000
#define DMA_16        0x0000
#define DMA_32        0x0400
#define DMA_16NOW     (DMA_ENABLE|DMA_16)
#define DMA_32NOW     (DMA_ENABLE|DMA_32)

// Ecran
#define BACKVRAM   0xA000
#define BACKBUFFER 0x10

#define FORCE_BLANK 0x80

#define BG0_ENABLE 0x100
#define BG1_ENABLE 0x200
#define BG2_ENABLE 0x400
#define BG3_ENABLE 0x800

#define BG_COLORS_16  0x0
#define BG_COLORS_256 0x80

#define REG_MOSAIC  *(unsigned long*)0x400004C
#define REG_BLDMOD  *(unsigned short*)0x4000050
#define REG_BLD_AB  *(unsigned short*)0x4000052
#define REG_BLD_FAD *(unsigned short*)0x4000054
#define BLEND_BG0   0x01
#define BLEND_BG1   0x02
#define BLEND_BG2   0x04
#define BLEND_BG3   0x08
#define BLEND_OBJ   0x10
#define BLEND_BD    0x20
#define BLEND_NO    0x00
#define BLEND_ALPHA 0x40
#define BLEND_WHITE 0x80
#define BLEND_BLACK 0xC0

#define REG_DISPCNT  *(volatile unsigned long*)0x4000000
#define REG_DISPSTAT *(volatile unsigned short*)0x4000004
#define REG_DISPVCNT *(volatile unsigned short*)0x4000006

#define REG_BG0CNT *(volatile unsigned short*)0x4000008
#define REG_BG1CNT *(volatile unsigned short*)0x400000A
#define REG_BG2CNT *(volatile unsigned short*)0x400000C
#define REG_BG3CNT *(volatile unsigned short*)0x400000E

#define TXTBG_SIZE_256x256 0x0
#define TXTBG_SIZE_512x256 0x4000
#define TXTBG_SIZE_256x512 0x8000
#define TXTBG_SIZE_512x512 0xC000

#define ROTBG_SIZE_128x128   0x0
#define ROTBG_SIZE_256x256   0x4000
#define ROTBG_SIZE_512x512   0x8000
#define ROTBG_SIZE_1024x1024 0xc000

#define REG_BG0HOFS *(volatile unsigned short*)0x4000010
#define REG_BG0VOFS *(volatile unsigned short*)0x4000012
#define REG_BG1HOFS *(volatile unsigned short*)0x4000014
#define REG_BG1VOFS *(volatile unsigned short*)0x4000016
#define REG_BG2HOFS *(volatile unsigned short*)0x4000018
#define REG_BG2VOFS *(volatile unsigned short*)0x400001A
#define REG_BG3HOFS *(volatile unsigned short*)0x400001C
#define REG_BG3VOFS *(volatile unsigned short*)0x400001E

#define REG_BG2PA *(volatile unsigned short*)0x4000020
#define REG_BG2PB *(volatile unsigned short*)0x4000022
#define REG_BG2PC *(volatile unsigned short*)0x4000024
#define REG_BG2PD *(volatile unsigned short*)0x4000026
#define REG_BG2X  *(volatile unsigned long*)0x4000028
#define REG_BG2Y  *(volatile unsigned long*)0x400002C

#define REG_BG3PA *(volatile unsigned short*)0x4000030
#define REG_BG3PB *(volatile unsigned short*)0x4000032
#define REG_BG3PC *(volatile unsigned short*)0x4000034
#define REG_BG3PD *(volatile unsigned short*)0x4000036
#define REG_BG3X  *(volatile unsigned long*)0x4000038
#define REG_BG3Y  *(volatile unsigned long*)0x400003C

#define REG_WIN0H   *(volatile unsigned short*)0x4000040
#define REG_WIN1H   *(volatile unsigned short*)0x4000042
#define REG_WIN0V   *(volatile unsigned short*)0x4000044
#define REG_WIN1V   *(volatile unsigned short*)0x4000046
#define REG_WININ   *(volatile unsigned short*)0x4000048
#define REG_WINOUT  *(volatile unsigned short*)0x400004A
#define WIN0_ENABLE 0x2000
#define WIN1_ENABLE 0x4000

#define CHAR_BASE_BLOCK(n)   (0x6000000|((n)*0x4000))
#define SCREEN_BASE_BLOCK(n) (0x6000000|((n)*0x800))
#define CHAR_SHIFT           2
#define SCREEN_SHIFT         8

#define RGB(r,g,b) ((r)|((g)<<5)|((b)<<10))

#define XM4 240
#define YM4 160
#define XO4 (XM4/2)
#define YO4 (YM4/2)

#define XM5 160
#define YM5 128
#define XO5 (XM5/2)
#define YO5 (YM5/2)

// Sprites
#define OBJ_ENABLE     0x1000
#define OBJ_WIN_ENABLE 0x8000
#define OBJ_PALRAM     ((volatile unsigned short*)0x05000200)
#define OBJ_TILES      ((volatile unsigned short*)0x06010000)
#define OBJ_1D         0x40
#define OBJ_2D         0x00

// Memoire
#define MULTIBOOT volatile const short __gba_multiboot=1;

#define EWRAM  ((volatile unsigned char*)0x02000000)  // 256Ko
#define IWRAM  ((volatile unsigned char*)0x03000000)  // 32Ko (rapide)
#define IORAM  ((volatile unsigned char*)0x04000000)  // 1Ko
#define PALRAM ((volatile unsigned short*)0x05000000) // 0x200 mots
#define VRAM   ((volatile unsigned short*)0x06000000) // 0xC000 mots
#define OAM    ((volatile unsigned short*)0x07000000) //
#define ROM    ((volatile unsigned char*)0x08000000)  // 32Mo
#define SRAM   ((volatile unsigned char*)0x0E000000)  // 64Ko

#define DATA_IN_EWRAM __attribute__ ((section(".ewram")))
#define DATA_IN_IWRAM __attribute__ ((section(".iwram")))
#define CODE_IN_IWRAM __attribute__ ((section(".iwram"),long_call))

// Math
#define FIXED_POINT_SHIFT 8 // Doit etre a 8 (valeur interne a la GBA)
#define FIXED_POINT       (1<<FIXED_POINT_SHIFT)

#define SINNB_SHIFT 8
#define SINNB       (1<<SINNB_SHIFT)
#define PI          3.14159265359
#define SIN(a)      SINE_TABLE[(a)&(SINNB-1)]
#define COS(a)      SINE_TABLE[((a)+(SINNB/4))&(SINNB-1)]
#define SQRT2       1.41421356237

#define INVNB                 (4*FIXED_POINT)
#define INV(n)                ((n)>0?INVERSE_TABLE[(n)]:-INVERSE_TABLE[-(n)])
#define FIXED_POINT_INV_SHIFT 15
#define FIXED_POINT_INV       (1<<FIXED_POINT_INV_SHIFT)

// Touches
#define REG_KEYS   *(volatile unsigned short*)0x4000130
#define KEY_A      1
#define KEY_B      2
#define KEY_SELECT 4
#define KEY_START  8
#define KEY_RIGHT  16
#define KEY_LEFT   32
#define KEY_UP     64
#define KEY_DOWN   128
#define KEY_R      256
#define KEY_L      512
#define KEYS       1023

// Interruptions
#define REG_IE       *(unsigned short*)0x4000200
#define REG_IF       *(unsigned short*)0x4000202
#define REG_WSCNT    *(unsigned short*)0x4000204
#define REG_IME      *(unsigned short*)0x4000208
#define REG_INTERUPT *(unsigned long*)0x3007FFC

#define IT_VBLANK 0x1
#define IT_HBLANK 0x2
#define IT_YTRIG  0x4
#define IT_TIMER0 0x8
#define IT_TIMER1 0x10
#define IT_TIMER2 0x20
#define IT_TIMER3 0x40
#define IT_COMMS  0x80
#define IT_DMA0   0x100
#define IT_DMA1   0x200
#define IT_DMA2   0x400
#define IT_DMA3   0x800
#define IT_KEYPAD 0x1000
#define IT_CART   0x2000

#define E_VBLANK  0x8
#define E_HBLANK  0x10
#define E_YTRIG   0x20
#define YTRIG_VAL 0xFF00

#define REG_TM0D   *(volatile unsigned short*)0x4000100
#define REG_TM0CNT *(volatile unsigned short*)0x4000102
#define REG_TM1D   *(volatile unsigned short*)0x4000104
#define REG_TM1CNT *(volatile unsigned short*)0x4000106
#define REG_TM2D   *(volatile unsigned short*)0x4000108
#define REG_TM2CNT *(volatile unsigned short*)0x400010A
#define REG_TM3D   *(volatile unsigned short*)0x400010C
#define REG_TM3CNT *(volatile unsigned short*)0x400010E

#define BEST_WSCNT 0x4317

///////////
// Types //
///////////
typedef void (*IntrFunction)(void*);

typedef struct
{
   unsigned short attribute0;
   unsigned short attribute1;
   unsigned short attribute2;
   unsigned short attribute3;
}
Sprite;

////////////////////////
// Variables globales //
////////////////////////
volatile unsigned short vblCounter;
extern signed short* SINE_TABLE;
extern unsigned short* INVERSE_TABLE;
extern Sprite* sprites;

////////////////
// Prototypes //
////////////////
inline void CommonVwait(void);

signed short CommonInterruptSet(unsigned short interrupt,IntrFunction* function);
void CommonInterruptSetYTrig(unsigned char line,IntrFunction* function);
inline signed short CommonInterruptEnable(unsigned short interrupt);
void CommonInterruptDisable(unsigned short interrupt);
void CommonInterruptBasicVbl(void);

unsigned char CODE_IN_IWRAM CommonSineInitVbl(unsigned char wait);
unsigned char CODE_IN_IWRAM CommonInverseInitVbl(unsigned char wait);
unsigned short CODE_IN_IWRAM CommonSqrt(unsigned short x);

void CommonSpritesInit(void);
inline void CommonSpritesDisplay(void);

void CommonDmaCopy(void* source,void* dest,unsigned short size,unsigned short type);
void CommonDmaForce(unsigned long value,void* dest,unsigned short size,unsigned short type);

inline void CommonUncompressInWRAM(void* source,void* dest);
inline void CommonUncompressInVRAM(void* source,void* dest);
inline unsigned long CommonUncompressSize(void* source);

unsigned char CommonSramRead(unsigned char* dest,unsigned short size);
void CommonSramWrite(unsigned char* source,unsigned short size);

#endif // COMMON_H
