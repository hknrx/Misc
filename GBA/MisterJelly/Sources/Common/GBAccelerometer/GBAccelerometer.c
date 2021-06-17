/*
** Mister Jelly - Sources\Common\GBAccelerometer\GBAccelerometer.c
** Nicolas ROBERT [NRX] - France 2006
**
** Adapted from Kionix's demo source code (http://www.kionix.com/gbaccelerometer)
*/

////////////////
// Inclusions //
////////////////
#include "..\Common.h"

////////////
// Macros //
////////////
#define REG_RCNT *(volatile unsigned short*)0x4000134

#define CLK  1 // Data Bit (SC) => CLK
#define CS   2 // Data Bit (SD) => CS
#define MISO 4 // Data Bit (SI) => MISO
#define MOSI 8 // Data Bit (SO) => MOSI

///////////
// Types //
///////////
typedef struct
{
   unsigned short offsetX;
   unsigned short offsetY;
   unsigned short offsetZ;
   unsigned short scaleX;
   unsigned short scaleY;
   unsigned short scaleZ;
}
GBAccelerometerSensor;

////////////////////////
// Variables globales //
////////////////////////
GBAccelerometerSensor sensor;

///////////////////////////
// GBAccelerometerRWByte //
///////////////////////////
static unsigned char GBAccelerometerRWByte(unsigned char writeByte)
{
   unsigned char mask;
   unsigned char readByte;

   readByte=0;
   for(mask=0x80;mask;mask>>=1)
   {
      // Ecriture
      if(writeByte&mask)
         REG_RCNT|=MOSI;
      else
         REG_RCNT&=~MOSI;
      REG_RCNT|=CLK;

      // Lecture
      if(REG_RCNT&MISO)
         readByte|=mask;
      REG_RCNT&=~CLK;
   }
   return(readByte);
}

/////////////////////////
// GBAccelerometerInit //
/////////////////////////
void GBAccelerometerInit(void)
{
   // Initialisation
   REG_RCNT=(0<<0)|  // Data Bit (SC) => CLK
            (0<<1)|  // Data Bit (SD) => CS
            (0<<2)|  // Data Bit (SI) => MISO
            (0<<3)|  // Data Bit (SO) => MOSI
            (1<<4)|  // Input/Output Selection Flag (SC): Set to Output
            (1<<5)|  // Input/Output Selection Flag (SD): Set to Output
            (0<<6)|  // Input/Output Selection Flag (SI): Set to Input
            (1<<7)|  // Input/Output Selection Flag (SO): Set to Output
            (0<<8)|  // Interrupt Request Enable Flag: Disable
            (2<<14); // Communication Function Set Flag: General Purpose Input/Output Terminal

   GBAccelerometerRWByte(0x04); // Command to write the KXP74 control register
   GBAccelerometerRWByte(0x04); // = enable
   REG_RCNT|=CS;

   // Calibration par defaut
   sensor.offsetX=2048;
   sensor.offsetY=2048;
   sensor.offsetZ=2048;
   sensor.scaleX=819;
   sensor.scaleY=819;
   sensor.scaleZ=819;
}

/////////////////////////
// GBAccelerometerTest //
/////////////////////////
unsigned char GBAccelerometerTest(void)
{
   unsigned char test;

   REG_RCNT&=~CS;
   GBAccelerometerRWByte(0x03); // Command to read the KXP74 control register
   test=GBAccelerometerRWByte(0x00);
   REG_RCNT|=CS;

   return(test);
}

//////////////////////////
// GBAccelerometerReadX //
//////////////////////////
signed long GBAccelerometerReadX(void)
{
   unsigned short X;

   REG_RCNT&=~CS;
   GBAccelerometerRWByte(0x00); // Command to convert X-axis
   X=((GBAccelerometerRWByte(0x00)<<8)|GBAccelerometerRWByte(0x00))>>4; // Read 16 bits, then shift the result to 12 bits
   REG_RCNT|=CS;

   return((((signed long)X-sensor.offsetX)<<FIXED_POINT_SHIFT)/sensor.scaleX);
}

//////////////////////////
// GBAccelerometerReadY //
//////////////////////////
signed long GBAccelerometerReadY(void)
{
   unsigned short Y;

   REG_RCNT&=~CS;
   GBAccelerometerRWByte(0x02); // Command to convert Y-axis
   Y=((GBAccelerometerRWByte(0x00)<<8)|GBAccelerometerRWByte(0x00))>>4; // Read 16 bits, then shift the result to 12 bits
   REG_RCNT|=CS;

   return((((signed long)Y-sensor.offsetY)<<FIXED_POINT_SHIFT)/sensor.scaleY);
}

//////////////////////////
// GBAccelerometerReadZ //
//////////////////////////
signed long GBAccelerometerReadZ(void)
{
   unsigned short Z;

   REG_RCNT&=~CS;
   GBAccelerometerRWByte(0x01); // Command to convert Z-axis
   Z=((GBAccelerometerRWByte(0x00)<<8)|GBAccelerometerRWByte(0x00))>>4; // Read 16 bits, then shift the result to 12 bits
   REG_RCNT|=CS;

   return((((signed long)Z-sensor.offsetZ)<<FIXED_POINT_SHIFT)/sensor.scaleZ);
}

////////////////////////////////
// GBAccelerometerReadAngleXY //
////////////////////////////////
unsigned char GBAccelerometerReadAngleXY(void)
{
   signed long X,Y;
   signed short sin;
   unsigned char angleMin,angle,angleMax;

   // Lecture des accelerations sur X et Y
   X=GBAccelerometerReadX();
   Y=GBAccelerometerReadY();

   if(X==0 && Y==0)
      return(0);

   // Calcul du sinus correspondant
   sin=(Y<<FIXED_POINT_SHIFT)/CommonSqrt(X*X+Y*Y);
   if(sin<0)
      sin=-sin;

   // Recherche dichotomique de l'angle (arcsinus) en utilisant le tableau "commonSineTable"
   angleMin=0;
   angle=SINNB/8;
   angleMax=SINNB/4;
   do
   {
      if(commonSineTable[angle]>=sin)
         angleMax=angle;
      else
         angleMin=angle;
      angle=(angleMin+angleMax)>>1;
   }
   while(angle!=angleMin);

   // Correction de l'angle en fonction du signe de X et Y
   if(X<0)
      angle=(SINNB/2)-angle;
   if(Y<0)
      angle=-angle;

   return(angle);
}
