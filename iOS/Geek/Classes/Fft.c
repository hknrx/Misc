/*
 TODO:
 - Optimize the processing (the input being a pure real signal!).
*/

#include <stdlib.h>
#include <math.h>
#include "Fft.h"

typedef struct
{
	float re;
	float im;
}
Complex;

static unsigned short fftSize = 0;
static unsigned short fftHalfSize = 0;
static Complex* fftData = NULL;
static float fftScale = 0.0f;
static unsigned short* fftBitReversal = NULL;
static float* fftSin = NULL;
static unsigned short fftSinHalfPi = 0;
static unsigned short fftSinMask = 0;

void FftInitialize(unsigned short const sizeLog, float const gain)
{
	// Allocate the FFT buffer
	fftSize = 1 << sizeLog;
	fftHalfSize = fftSize >> 1;
	fftData = (Complex*)malloc(sizeof(Complex) << sizeLog);

	// Initialize the scaling factor
	FftGainSet(gain);

	// Initialize the bit reversal look up table
	// See: http://www3.interscience.wiley.com/cgi-bin/fulltext/101520473/PDFSTART
	fftBitReversal = (unsigned short*)malloc(sizeof(unsigned short) << sizeLog);
	fftBitReversal[0] = 0;
	fftBitReversal[1] = 1 << (sizeLog - 1);
	fftBitReversal[2] = 1 << (sizeLog - 2);
	fftBitReversal[3] = 3 << (sizeLog - 2);
	unsigned short maskPrevious = 3;
	for(unsigned short indexLog = 3; indexLog <= sizeLog; ++indexLog)
	{
		unsigned short maskCurrent = (1 << indexLog) - 1;
		fftBitReversal[maskCurrent] = fftBitReversal[maskPrevious] + (1 << (sizeLog - indexLog));
		for(unsigned short index = 1; index <= maskPrevious; ++index)
		{
			fftBitReversal[maskCurrent - index] = fftBitReversal[maskCurrent] - fftBitReversal[index];
		}
		maskPrevious = maskCurrent;
	}

	// Initialize the twiddle factors
	fftSin = (float*)malloc(sizeof(float) << sizeLog);
	fftSinHalfPi = fftSize >> 2;
	fftSinMask = fftSize - 1;
	for(unsigned short index = 0; index < fftSize; ++index)
	{
		fftSin[index] = sinf(2 * M_PI * index / fftSize);
	}
}

void FftFinalize()
{
	free(fftSin);
	fftSin = NULL;
	free(fftBitReversal);
	fftBitReversal = NULL;
	free(fftData);
	fftData = NULL;
}

void FftGainSet(float const gain)
{
	fftScale = gain / fftSize;
}

void FftForward(short const*const bufferIn)
{
	// Bit reversal
	for(unsigned short index = 0; index < fftSize; ++index)
	{
		unsigned short const indexReverse = fftBitReversal[index];
		fftData[indexReverse].re = bufferIn[index];
		fftData[indexReverse].im = 0.0f;
	}

	// DIT
	unsigned short n = 1;
	unsigned short e = fftHalfSize;
	while(n < fftSize)
	{
		unsigned short const n2 = n << 1;
		unsigned short angle = fftSize;
		for(unsigned short k = 0; k < fftSize; k += n2)
		{
			unsigned short const kn = k + n;
			float const re = fftData[kn].re;
			float const im = fftData[kn].im;
			fftData[kn].re = fftData[k].re - re;
			fftData[kn].im = fftData[k].im - im;
			fftData[k].re += re;
			fftData[k].im += im;
		}
		for(unsigned short j = 1; j < n; j++)
		{
			angle -= e;
			float const cosAngle = fftSin[(angle + fftSinHalfPi) & fftSinMask];
			float const sinAngle = fftSin[angle];

			for(unsigned short k = j; k < fftSize; k += n2)
			{
				unsigned short const kn = k + n;
				float const re = cosAngle * fftData[kn].re - sinAngle * fftData[kn].im;
				float const im = sinAngle * fftData[kn].re + cosAngle * fftData[kn].im;
				fftData[kn].re = fftData[k].re - re;
				fftData[kn].im = fftData[k].im - im;
				fftData[k].re += re;
				fftData[k].im += im;
			}
		}
		n = n2;
		e >>= 1;
	}
}

void FftInverse(short *const bufferOut)
{
	// DIF
	unsigned short n = fftSize;
	unsigned short e = 1;
	while(n)
	{
		unsigned short const n2 = n >> 1;
		unsigned short angle = 0;
		for(unsigned short k = 0; k < fftSize; k += n)
		{
			unsigned short const kn = k + n2;
			float const re = fftData[kn].re;
			float const im = fftData[kn].im;
			fftData[kn].re = fftData[k].re - re;
			fftData[kn].im = fftData[k].im - im;
			fftData[k].re += re;
			fftData[k].im += im;
		}
		for(unsigned short j = 1; j < n2; j++)
		{
			angle += e;
			float const cosAngle = fftSin[(angle + fftSinHalfPi) & fftSinMask];
			float const sinAngle = fftSin[angle];

			for(unsigned short k = j; k < fftSize; k += n)
			{
				unsigned short const kn = k + n2;
				float const re = fftData[k].re - fftData[kn].re;
				float const im = fftData[k].im - fftData[kn].im;
				fftData[k].re += fftData[kn].re;
				fftData[k].im += fftData[kn].im;
				fftData[kn].re = cosAngle * re - sinAngle * im;
				fftData[kn].im = sinAngle * re + cosAngle * im;
			}
		}
		n = n2;
		e <<= 1;
	}

	// Bit reversal and scaling
	for(unsigned short index = 0; index < fftSize; ++index)
	{
		bufferOut[fftBitReversal[index]] = fftData[index].re * fftScale;
	}
}

void SpectrumPartGet(float *const bufferOut, unsigned short const begin, unsigned short end)
{
	if(begin >= fftSize)
	{
		end -= begin;
		for(unsigned short index = 0; index < end; ++index)
		{
			bufferOut[index] = 0.0f;
		}
		return;
	}
	if(end > fftSize)
	{
		for(unsigned short index = fftSize; index < end; ++index)
		{
			bufferOut[index - begin] = 0.0f;
		}
		end = fftSize;
	}
	for(unsigned short index = begin; index < end; ++index)
	{
		bufferOut[index - begin] = fftData[index].re * fftData[index].re + fftData[index].im * fftData[index].im;
	}
}

void SpectrumHalfScale(float const scale)
{
	if(scale == 1.0f || scale < 0.0f)
	{
		return;
	}
	if(scale < 1.0f)
	{
		for(short index = fftHalfSize; index >= 0; --index)
		{
			short const indexScaled = index * scale;
			fftData[index].re = fftData[indexScaled].re;
			fftData[index].im = fftData[indexScaled].im;
		}
	}
	else
	{
		short const limit = fftHalfSize / scale;
		for(short index = 0; index <= limit; ++index)
		{
			short const indexScaled = index * scale;
			fftData[index].re = fftData[indexScaled].re;
			fftData[index].im = fftData[indexScaled].im;
		}
		for(short index = limit + 1; index <= fftHalfSize; ++index)
		{
			fftData[index].re = 0.0f;
			fftData[index].im = 0.0f;
		}
	}
}

void SpectrumHalfShift(float const shift)
{
	short shiftIndex = shift * fftHalfSize;
	if(!shiftIndex)
	{
		return;
	}
	if(shiftIndex > 0)
	{
		if(shiftIndex > fftHalfSize)
		{
			shiftIndex = fftHalfSize;
		}
		for(short index = fftHalfSize; index >= shiftIndex; --index)
		{
			short const indexShifted = index - shiftIndex;
			fftData[index].re = fftData[indexShifted].re;
			fftData[index].im = fftData[indexShifted].im;
		}
		for(short index = 0; index < shiftIndex; ++index)
		{
			fftData[index].re = 0.0f;
			fftData[index].im = 0.0f;
		}
	}
	else
	{
		if(shiftIndex < -fftHalfSize)
		{
			shiftIndex = -fftHalfSize;
		}
		short const limit = fftHalfSize + shiftIndex;
		for(short index = 0; index <= limit; ++index)
		{
			short const indexShifted = index - shiftIndex;
			fftData[index].re = fftData[indexShifted].re;
			fftData[index].im = fftData[indexShifted].im;
		}
		for(short index = limit + 1; index <= fftHalfSize; ++index)
		{
			fftData[index].re = 0.0f;
			fftData[index].im = 0.0f;
		}
	}
}

void SpectrumHalfSave(FILE *const file)
{
	fwrite(fftData, sizeof(Complex), fftHalfSize + 1, file);
}

unsigned char SpectrumHalfLoad(FILE *const file)
{
	return fread(fftData, sizeof(Complex), fftHalfSize + 1, file) == fftHalfSize + 1;
}

unsigned int SpectrumHalfCount(FILE *const file)
{
	long const position = ftell(file);
	fseek(file, 0, SEEK_END);
	long const size = ftell(file);
	fseek(file, position, SEEK_SET);
	return size / ((fftHalfSize + 1) * sizeof(Complex));
}

void SpectrumHalfCreate()
{
	for(short index = 1; index < fftHalfSize; ++index)
	{
		fftData[fftSize - index].re = fftData[index].re;
		fftData[fftSize - index].im = -fftData[index].im;
	}
}
