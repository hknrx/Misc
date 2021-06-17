/*
** Bomb Jack - MusicJack\Sources\MusicJack.c
** Nicolas ROBERT [NRX] - Hong Kong 2005 / France 2006
*/

////////////////
// Inclusions //
////////////////
#include <stdio.h>
#include <string.h>
#include "..\Generated\MusicJack.h"
#include "..\..\Sources\Common\Adpcm\Adpcm.h"
#include "..\..\Sources\Common\Adpcm\AdpcmTables.h"

////////////
// Macros //
////////////
#define TAG_COMPRESS    "-compress"
#define TAG_NO_COMPRESS "-nocompress"
#define ADPCM_SAMPLES   32
#define WAVE_SAMPLES    (ADPCM_SAMPLES*2)

///////////
// Types //
///////////
typedef struct
{
   FILE* file;
   struct
   {
      unsigned short audioFormat;
      unsigned short numberChannels;
      unsigned long sampleRate;
      unsigned long byteRate;
      unsigned short blockAlign;
      unsigned short bitsPerSample;
   }
   format;
   unsigned char bytesPerSample;
   unsigned long numberSamples;
}
Wave;

typedef struct
{
   signed long lastSample;
   signed short lastIndex;
}
AdpcmChannel;

//////////////
// WaveInit //
//////////////
static unsigned char WaveInit(Wave* wave)
{
   unsigned char buffer[12];
   unsigned char formatOk;
   unsigned long length;

   // Read the header
   if(fread(buffer,sizeof(unsigned char),12,wave->file)<12)
      return(1);

   // Check for the RIFF & WAVE signatures
   if(memcmp("RIFF",buffer,4)||memcmp("WAVE",buffer+8,4))
      return(1);

   // Parse the chunks
   formatOk=0;
   while(fread(buffer,sizeof(unsigned char),4,wave->file))
   {
      fread(&length,sizeof(unsigned long),1,wave->file);
      if(!memcmp("fmt ",buffer,4))
      {
         // Read the format
         if(length<16)
            return(1);

         fread(&wave->format,sizeof(wave->format),1,wave->file);
         fseek(wave->file,length-sizeof(wave->format),SEEK_CUR);
         formatOk=1;

         // Compute the "bytesPerSample" from the "bitsPerSample"
         wave->bytesPerSample=(wave->format.bitsPerSample+7)>>3;
      }
      else if(!memcmp("data",buffer,4))
      {
         // We now have some data; first check we got the format
         if(!formatOk)
            return(1);

         // Compute the actual number of samples
         wave->numberSamples=length/(wave->format.numberChannels*wave->bytesPerSample);

         // Everything seems ok!
         return(0);
      }
      else
      {
         // Skip unrecognized chunk types
         fseek(wave->file,length,SEEK_CUR);
      }
   }

   // We haven't found the data!
   return(1);
}

/////////////////
// AdpcmEncode //
/////////////////
static void AdpcmEncode(AdpcmChannel* channel,signed short* source,unsigned char* dest,unsigned short length)
{
   signed long sample;
   signed short index;
   signed short step;
   unsigned char byte;
   unsigned char code;
   unsigned char sign;
   signed short diff;

   // Retrieve the previous data
   sample=channel->lastSample;
   index=channel->lastIndex;

   // Process the samples
   byte=0;
   while(length)
   {
      // Get the step
      step=adpcmStep[index];

      // Compute the code
      diff=(*source++)-sample;
      if(diff<0)
      {
         diff=-diff;
         sign=8;
      }
      else
         sign=0;
      code=(diff<<2)/step;
      if(code>7)
         code=7;

      // Modify the previous sample
      diff=step>>3;
      if(code&1)
         diff+=step>>2;
      if(code&2)
         diff+=step>>1;
      if(code&4)
         diff+=step;
      if(sign)
      {
         sample-=diff;
         if(sample<-32768)
            sample=-32768;
      }
      else
      {
         sample+=diff;
         if(sample>32767)
            sample=32767;
      }

      // Compute the next index
      index+=adpcmModifyIndex[code];
      if(index<0)
         index=0;
      else if(index>88)
         index=88;

      // Store the sample
      code|=sign;
      if(length&1)
         *dest++=(code<<4)|byte;
      else
         byte=code;

      // Next sample...
      --length;
   }

   // Store the current data
   channel->lastSample=sample;
   channel->lastIndex=index;
}

/////////////
// Process //
/////////////
static void Process(FILE* adpcmFile,AdpcmSound* adpcmSound,unsigned char* waveFileName)
{
   Wave wave;
   unsigned char waveShiftValue;
   unsigned char waveCounter;
   unsigned short waveChannel;
   signed long waveSumSamples;
   signed long waveLongSample;
   signed short waveSamples[WAVE_SAMPLES];

   AdpcmChannel adpcmChannel;
   unsigned char adpcmCounter;
   unsigned char adpcmSamples[ADPCM_SAMPLES];

   // Open and check the wave file
   wave.file=fopen(waveFileName,"rb");
   if(!wave.file)
   {
      fprintf(stderr,"Error: couldn't open \"%s\" for reading\n",waveFileName);
      return;
   }
   if(WaveInit(&wave))
   {
      fprintf(stderr,"Error: \"%s\" is not a wave file\n",waveFileName);
      return;
   }
   if(!adpcmSound->noCompress && wave.format.sampleRate>MAX_WAVE_FREQUENCY)
   {
      fprintf(stderr,"Error: the sample rate of \"%s\" is greater than %dHz\n",waveFileName,MAX_WAVE_FREQUENCY);
      return;
   }
   fprintf(stdout,"Adding \"%s\"...\n",waveFileName);

   // Pad the file to the size where the sound data shall be saved
   fwrite(&bombJackRom,sizeof(unsigned char),-ftell(adpcmFile)&3,adpcmFile);

   // Compute the number of data in our adpcm file
   if(adpcmSound->noCompress)
      adpcmSound->length=wave.numberSamples;
   else
   {
      adpcmSound->length=(wave.numberSamples+1)>>1;

      // Also, initialize the adpcm
      adpcmChannel.lastSample=0;
      adpcmChannel.lastIndex=0;
   }

   // Compute the number of bits the value will need to be shifted to fit on 16 bits
   waveShiftValue=(wave.bytesPerSample-2)<<3;

   // Write the header of the adpcm structure
   adpcmSound->sampleRate=wave.format.sampleRate;
   fwrite(adpcmSound,sizeof(AdpcmSound),1,adpcmFile);

   // Process the wave file...
   while(wave.numberSamples)
   {
      // Read some samples
      for(waveCounter=0;waveCounter<WAVE_SAMPLES && wave.numberSamples;++waveCounter,--wave.numberSamples)
      {
         // We compute the average of all the channels and put the result on 16 bits
         waveSumSamples=0;
         for(waveChannel=wave.format.numberChannels;waveChannel;--waveChannel)
         {
            if(wave.bytesPerSample==1)
               waveSumSamples+=(signed short)((fgetc(wave.file)<<8)-32768);
            else
            {
               fread(&waveLongSample,wave.bytesPerSample,1,wave.file);
               waveSumSamples+=(signed short)(waveLongSample>>waveShiftValue);
            }
         }
         waveSamples[waveCounter]=waveSumSamples/wave.format.numberChannels;
      }

      if(adpcmSound->noCompress)
      {
         // No need to compress the data, simply convert them to 8 bits
         for(adpcmCounter=0;adpcmCounter<waveCounter;++adpcmCounter)
            adpcmSamples[adpcmCounter]=waveSamples[adpcmCounter]>>8;
      }
      else
      {
         // Be sure we have an event number of data
         if(waveCounter&1)
            waveSamples[waveCounter++]=0;

         // Encoding...
         AdpcmEncode(&adpcmChannel,waveSamples,adpcmSamples,waveCounter);
         waveCounter>>=1;
      }

      // Save the data into the output file
      fwrite(adpcmSamples,sizeof(unsigned char),waveCounter,adpcmFile);

      // Update the "adpcmLength" to later check everything was ok...
      adpcmSound->length-=waveCounter;
   }

   // Just a final little check!
   if(adpcmSound->length)
      fprintf(stdout,"Warning: %lu bytes missing\n",adpcmSound->length);

   // Close the wave file
   fclose(wave.file);
}

//////////
// main //
//////////
int main(int argc,char** argv)
{
   signed char stringLength;
   unsigned char numArgument;

   unsigned char adpcmFileName[256];
   FILE* adpcmFile;
   AdpcmSound adpcmSound={ADPCM_MAGIC};

   // Display the usage when there is no argument
   if(argc<2)
      fprintf(stderr,"Usage: %s [%s | %s] [waveFileName] ...\n",argv[0],TAG_COMPRESS,TAG_NO_COMPRESS);

   // Set the name of the output file
   stringLength=strlen(argv[0])-4;
   if(stringLength>0 && !strcmp(".exe",argv[0]+stringLength))
      argv[0][stringLength]=0;
   sprintf(adpcmFileName,"%s.gba",argv[0]);

   // Open the output file
   adpcmFile=fopen(adpcmFileName,"wb");
   if(!adpcmFile)
   {
      fprintf(stderr,"Error: couldn't open \"%s\" for writing\n",adpcmFileName);
      return(1);
   }
   fprintf(stdout,"Creating \"%s\"...\n",adpcmFileName);

   // Write the ROM data
   fwrite(&bombJackRom,sizeof(bombJackRom),1,adpcmFile);

   // The data will be compressed by default
   adpcmSound.noCompress=0;

   // Check all the arguments
   for(numArgument=1;numArgument<argc;++numArgument)
   {
      // Check whether there is an option to enable or disable the compression
      if(!strcmp(argv[numArgument],TAG_COMPRESS))
      {
         adpcmSound.noCompress=0;
         continue;
      }
      else if(!strcmp(argv[numArgument],TAG_NO_COMPRESS))
      {
         adpcmSound.noCompress=1;
         continue;
      }

      // Process the wave file
      Process(adpcmFile,&adpcmSound,argv[numArgument]);
   }

   // There is no more wave file, we're done!
   fclose(adpcmFile);
   fputs("Done.\n",stdout);
   return(0);
}
