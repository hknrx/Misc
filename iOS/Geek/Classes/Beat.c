#include <stdlib.h>
#include <math.h>

#define BIQUAD_BAND_SHIFT          6
#define ENVELOPPE_COUNT_PER_SECOND 24
#define ENVELOPPE_MEAN_DURATION    2.0f
#define ENVELOPPE_MEAN_FACTOR      0.8f
#define BEAT_PER_MINUTE_MIN        30
#define BEAT_PER_MINUTE_MAX        300
#define BEAT_IOI_FACTOR            1.6f
#define BEAT_POSITION_COEFFICIENT  0.05f

typedef struct
{
	float b0;
	float a1;
	float a2;
	float output1;
	float output2;
	float enveloppeValue;
	float* enveloppeHistory;
	float enveloppeSum;
}
BiQuadParameters;

static unsigned short enveloppeSize;
static unsigned short enveloppeCount;
static unsigned short enveloppeHistorySize;
static unsigned short enveloppeHistoryCount;
static unsigned short enveloppeHistoryCurrent;
static unsigned short bandCount;
static float biQuadInput1;
static float biQuadInput2;
static BiQuadParameters* biQuadParameters = NULL;
static unsigned short ioiHistoryMin;
static unsigned short ioiHistoryMax;
static float* ioiHistory;
static unsigned short onsetHistorySize;
static unsigned short onsetHistoryCurrent;
static float* onsetHistory;
static unsigned short beatTimer;
static float beatPositionFiltered;
static float beatRate;

/**
 * Initialize the beat engine.
 *
 * @param sampleRate Sampling rate of the sound (in Hertz).
 */
void BeatInitialize(float const sampleRate)
{
	// Make sure the engine isn't initialize yet
	if(biQuadParameters)
	{
		return;
	}

	// Initialize the enveloppe
	enveloppeSize = floorf(sampleRate / ENVELOPPE_COUNT_PER_SECOND);
	enveloppeCount = 0;
	enveloppeHistorySize = ENVELOPPE_MEAN_DURATION * ENVELOPPE_COUNT_PER_SECOND;
	enveloppeHistoryCount = 0;
	enveloppeHistoryCurrent = 0;

	// Compute the number of bands
	bandCount = floorf(log2f(sampleRate)) - BIQUAD_BAND_SHIFT;

	// Initialize the bi-quad filters for each band
	biQuadInput1 = 0.0f;
	biQuadInput2 = 0.0f;
	biQuadParameters = (BiQuadParameters*)malloc(bandCount * sizeof(BiQuadParameters));
	for(unsigned short bandIndex = 0; bandIndex < bandCount; ++bandIndex)
	{
		BiQuadParameters *const biQuad = &biQuadParameters[bandIndex];
		float const frequency = 1 << (bandIndex + BIQUAD_BAND_SHIFT);
		float const omega = 2.0f * M_PI * frequency / sampleRate;
		float const alpha = sinf(omega) * sinhf(M_LN2 * 0.5f * omega / sinf(omega));
		float const a0 = 1.0f + alpha;

		biQuad->b0 = alpha / a0;
		biQuad->a1 = -2.0f * cosf(omega) / a0;
		biQuad->a2 = (1.0f - alpha) / a0;

		biQuad->output1 = 0.0f;
		biQuad->output2 = 0.0f;

		biQuad->enveloppeValue = 0.0f;
		biQuad->enveloppeHistory = (float*)malloc(enveloppeHistorySize * sizeof(float));
		biQuad->enveloppeHistory[enveloppeHistoryCurrent] = 0.0f;
		biQuad->enveloppeSum = 0.0f;
	}

	// Initialize the IOI (inter-onset intervals)
	ioiHistoryMin = floorf(ENVELOPPE_COUNT_PER_SECOND * 60.0f / BEAT_PER_MINUTE_MAX);
	ioiHistoryMax = ceilf(ENVELOPPE_COUNT_PER_SECOND * 60.0f / BEAT_PER_MINUTE_MIN);
	ioiHistory = (float*)malloc((ioiHistoryMax - ioiHistoryMin) * sizeof(float));

	// Initialize the onsets
	onsetHistorySize = ioiHistoryMax * 2;
	onsetHistoryCurrent = 0;
	onsetHistory = (float*)malloc(onsetHistorySize * sizeof(float));
	for(unsigned short onsetIndex = 0; onsetIndex < onsetHistorySize; ++onsetIndex)
	{
		onsetHistory[onsetIndex] = 0.0f;
	}

	// Initialize the beat data
	beatTimer = 0;
	beatPositionFiltered = 0.0f;
	beatRate = INFINITY;
}

/**
 * Finalize the beat engine.
 */
void BeatFinalize()
{
	free(onsetHistory);
	free(ioiHistory);
	if(biQuadParameters)
	{
		for(unsigned short bandIndex = 0; bandIndex < bandCount; ++bandIndex)
		{
			free(biQuadParameters[bandIndex].enveloppeHistory);
		}
		free(biQuadParameters);
		biQuadParameters = NULL;
	}
}

/**
 * Process a sound sample.
 *
 * @param sampleValue Value of the sound sample.
 * @param onsetFactor Pointer to the onset factor variable (NULL if the information isn't needed). The variable is set to a value between 0.0 (no onset) and 1.0 (onset on all the bands).
 * @return True if there is a beat, false otherwise.
 */
unsigned char BeatProcess(float const sampleValue, float *const onsetFactor)
{
	// Make sure the engine is initialized
	if(!biQuadParameters)
	{
		return 0;
	}

	// Apply the bi-quad filter defined for each band
	for(unsigned short bandIndex = 0; bandIndex < bandCount; ++bandIndex)
	{
		BiQuadParameters *const biQuad = &biQuadParameters[bandIndex];
		float const filteredValue = biQuad->b0 * (sampleValue - biQuadInput2) - biQuad->a1 * biQuad->output1 - biQuad->a2 * biQuad->output2;
		biQuad->output2 = biQuad->output1;
		biQuad->output1 = filteredValue;

		// Take note of the enveloppe value
		if(biQuad->enveloppeValue < filteredValue)
		{
			biQuad->enveloppeValue = filteredValue;
		}
		else if(biQuad->enveloppeValue < -filteredValue)
		{
			biQuad->enveloppeValue = -filteredValue;
		}
	}
	biQuadInput2 = biQuadInput1;
	biQuadInput1 = sampleValue;

	// Check whether we have enough data to consolidate the current enveloppe values
	if(++enveloppeCount < enveloppeSize)
	{
		if(onsetFactor)
		{
			*onsetFactor = 0.0f;
		}
		return 0;
	}

	// Reset the enveloppe data counter
	enveloppeCount = 0;

	// Handle the enveloppe history indexes
	unsigned char const enveloppeHistoryFull = enveloppeHistoryCount >= enveloppeHistorySize;
	if(!enveloppeHistoryFull)
	{
		++enveloppeHistoryCount;
	}
	unsigned short const enveloppeHistoryPrevious = enveloppeHistoryCurrent;
	if(++enveloppeHistoryCurrent >= enveloppeHistorySize)
	{
		enveloppeHistoryCurrent = 0;
	}

	// Check each band for onsets
	unsigned char onsetCount = 0;
	float onsetValue = 0.0f;
	for(unsigned short bandIndex = 0; bandIndex < bandCount; ++bandIndex)
	{
		BiQuadParameters *const biQuad = &biQuadParameters[bandIndex];

		// Update the sum of enveloppe values (sliding window)
		if(enveloppeHistoryFull)
		{
			biQuad->enveloppeSum -= biQuad->enveloppeHistory[enveloppeHistoryCurrent];
		}
		biQuad->enveloppeHistory[enveloppeHistoryCurrent] = biQuad->enveloppeValue;
		biQuad->enveloppeSum += biQuad->enveloppeValue;

		// Compare the derivative of the enveloppe to its mean
		float const enveloppeMean = biQuad->enveloppeSum / enveloppeHistoryCount;
		float const enveloppeDerivative = biQuad->enveloppeValue - biQuad->enveloppeHistory[enveloppeHistoryPrevious];
		if(enveloppeDerivative > ENVELOPPE_MEAN_FACTOR * enveloppeMean)
		{
			++onsetCount;
			onsetValue += biQuad->enveloppeValue;
		}

		// Reset the current enveloppe value for this band
		biQuad->enveloppeValue = 0.0f;
	}

	// Update the onset history
	onsetHistory[onsetHistoryCurrent] = onsetValue;

	// Create the IOI (inter-onset intervals) histogram
	for(unsigned short ioiIndex1 = ioiHistoryMin; ioiIndex1 < ioiHistoryMax; ++ioiIndex1)
	{
		float ioiValue = 0.0f;
		for(unsigned short ioiIndex2 = 0; ioiIndex2 < ioiHistoryMax; ++ioiIndex2)
		{
			signed short onsetIndex1 = onsetHistoryCurrent - ioiIndex2;
			if(onsetIndex1 < 0)
			{
				onsetIndex1 += onsetHistorySize;
			}
			signed short onsetIndex2 = onsetIndex1 - ioiIndex1;
			if(onsetIndex2 < 0)
			{
				onsetIndex2 += onsetHistorySize;
			}
			ioiValue += onsetHistory[onsetIndex1] * onsetHistory[onsetIndex2];
		}
		ioiHistory[ioiIndex1 - ioiHistoryMin] = ioiValue;
	}

	// Handle the onset history index
	if(++onsetHistoryCurrent >= onsetHistorySize)
	{
		onsetHistoryCurrent = 0;
	}

	// Update the beat position
	float ioiThreshold = 0.0f;
	unsigned short beatPosition = -1;
	for(unsigned short ioiIndex = ioiHistoryMin; ioiIndex < ioiHistoryMax; ++ioiIndex)
	{
		float const ioiValue = ioiHistory[ioiIndex - ioiHistoryMin];
		if(ioiValue > ioiThreshold)
		{
			ioiThreshold = ioiValue * BEAT_IOI_FACTOR;
			beatPosition = ioiIndex;
		}
	}
	beatPositionFiltered = BEAT_POSITION_COEFFICIENT * beatPosition + (1.0f - BEAT_POSITION_COEFFICIENT) * beatPositionFiltered;

	// Compute the onset factor
	if(onsetFactor)
	{
		*onsetFactor = (float)onsetCount / bandCount;
	}

	// Update the beat rate
	beatRate = ENVELOPPE_COUNT_PER_SECOND * 60.0f / beatPositionFiltered;

	// Update the beat timer
	if(++beatTimer > beatPositionFiltered)
	{
		beatTimer = 0;
		return 1;
	}
	return 0;
}

/**
 * Get the current beat rate.
 *
 * @return Current beat rate, in BPM (beats per minute).
 */
float BeatGet()
{
	// Make sure the engine is initialized
	if(biQuadParameters)
	{
		return beatRate;
	}
	return INFINITY;
}