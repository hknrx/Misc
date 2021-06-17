#include <stdio.h>

void FftInitialize(unsigned short const sizeLog, float const gain);
void FftFinalize();
void FftGainSet(float const gain);
void FftForward(short const*const bufferIn);
void FftInverse(short *const bufferOut);
void SpectrumPartGet(float *const bufferOut, unsigned short const begin, unsigned short end);
void SpectrumHalfScale(float const scale);
void SpectrumHalfShift(float const shift);
void SpectrumHalfSave(FILE *const file);
unsigned char SpectrumHalfLoad(FILE *const file);
unsigned int SpectrumHalfCount(FILE *const file);
void SpectrumHalfCreate();
