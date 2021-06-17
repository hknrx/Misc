/**
 * Initialize the beat engine.
 *
 * @param sampleRate Sampling rate of the sound (in Hertz).
 */
void BeatInitialize(float const sampleRate);

/**
 * Finalize the beat engine.
 */
void BeatFinalize();

/**
 * Process a sound sample.
 *
 * @param sampleValue Value of the sound sample.
 * @param onsetFactor Pointer to the onset factor variable (NULL if the information isn't needed). The variable is set to a value between 0.0 (no onset) and 1.0 (onset on all the bands).
 * @return True if there is a beat, false otherwise.
 */
unsigned char BeatProcess(float const sampleValue, float *const onsetFactor);

/**
 * Get the current beat rate.
 *
 * @return Current beat rate, in BPM (beats per minute).
 */
float BeatGet();
