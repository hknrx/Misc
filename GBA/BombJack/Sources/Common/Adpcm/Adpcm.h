/*
** Bomb Jack - Sources\Common\Adpcm\Adpcm.h
** Nicolas ROBERT [NRX] - Hong Kong 2005 / France 2006
*/

#ifndef ADPCM_H
#define ADPCM_H

////////////
// Macros //
////////////
#define ADPCM_MAGIC "ADPCM v1.0"

///////////
// Types //
///////////
typedef struct
{
   unsigned char magic[sizeof(ADPCM_MAGIC)];
   unsigned char noCompress;
   unsigned long sampleRate;
   unsigned long length;
   unsigned char __attribute__ ((aligned(4))) data[];
}
AdpcmSound;

////////////////
// Prototypes //
////////////////
#ifdef ADPCM_ENABLED
unsigned char AdpcmInit(unsigned char numberChannels);
void AdpcmDestroy(void);

unsigned char AdpcmStart(unsigned char channel,const AdpcmSound* sound,signed char repeat);
unsigned char AdpcmStop(unsigned char channel);
const AdpcmSound* AdpcmGetSound(unsigned char channel);
signed char AdpcmGetRepeat(unsigned char channel);
unsigned char AdpcmSetVolume(unsigned char channel,unsigned char volume);
unsigned char AdpcmGetVolume(unsigned char channel);

void __attribute__ ((section(".iwram"),long_call)) AdpcmDecodeVbl(unsigned char channel);
#endif // ADPCM_ENABLED

#endif // ADPCM_H
