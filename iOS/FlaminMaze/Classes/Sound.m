#import <AudioToolbox/AudioToolbox.h>
#import <OpenAL/al.h>
#import "Sound.h"

#define soundVolume 1.0f
#define musicVolume 1.0f

@implementation Sound

static Sound* sharedInstance = nil;

+ (Sound*)sharedInstance
{
	@synchronized(self)
	{
		if(!sharedInstance)
		{
			sharedInstance = [[Sound alloc] init];
		}
	}
	return sharedInstance;
}

+ (id)allocWithZone:(NSZone*)zone
{
	@synchronized(self)
	{
		if(!sharedInstance)
		{
			sharedInstance = [super allocWithZone:zone];
			return sharedInstance;
		}
	}
	return nil;
}

@synthesize soundState;
@synthesize musicState;

- (id)copyWithZone:(NSZone*)zone
{
	return self;
}

- (id)retain
{
	return self;
}

- (unsigned)retainCount
{
	return UINT_MAX;
}

- (void)release
{
}

- (id)autorelease
{
	return self;
}

static void AudioSessionInitializeHardwareDecoding()
{
	UInt32 property = kAudioSessionCategory_MediaPlayback;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(property), &property);
	AudioSessionSetActive(TRUE);

	property = kAudioSessionCategory_SoloAmbientSound;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(property), &property);
	AudioSessionSetActive(TRUE);
}

- (void)audioSessionInterruptionHandler:(UInt32)interruptionState
{
	if(interruptionState == kAudioSessionBeginInterruption)
	{
		alcMakeContextCurrent(NULL);
		alcSuspendContext(context);
		if(musicState == MUSIC_GAME)
		{
			[musicPlayer pause];
		}
	}
	else if(interruptionState == kAudioSessionEndInterruption)
	{
		if(musicState == MUSIC_GAME)
		{
			AudioSessionInitializeHardwareDecoding();
			[musicPlayer play];
		}
		alcMakeContextCurrent(context);
		alcProcessContext(context);
	}
}

static void AudioSessionInterruptionHandler(void* userData, UInt32 interruptionState)
{
	[(Sound*)userData audioSessionInterruptionHandler:interruptionState];
}

- (id)init
{
	if(self = [super init])
	{
		// Initialise the audio session and set the initial state of the music
		AudioSessionInitialize(NULL, NULL, AudioSessionInterruptionHandler, self);
		UInt32 property;
		UInt32 propertySize = sizeof(property);
		AudioSessionGetProperty (kAudioSessionProperty_OtherAudioIsPlaying, &propertySize, &property);
		if(property)
		{
			musicState = MUSIC_IPOD;
			property = kAudioSessionCategory_AmbientSound;
			AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(property), &property);
			AudioSessionSetActive(TRUE);
		}
		else
		{
			musicState = MUSIC_GAME;
			AudioSessionInitializeHardwareDecoding();
		}

		// Initialize OpenAL
		device = alcOpenDevice(NULL);
		if(device)
		{
			context = alcCreateContext(device, NULL);
			alcMakeContextCurrent(context);
			alDistanceModel(AL_NONE);
			alListenerf(AL_GAIN, soundVolume);
			buffers = [[NSMutableArray alloc]init];
			sources = [[NSMutableDictionary alloc]init];
		}

		// Complete the initialization
		soundState = YES;
		musicPlayer = nil;
		musicName = nil;
	}
	return self;
}

- (void)toggleSoundState
{
	soundState = !soundState;
	if(soundState)
	{
		alListenerf(AL_GAIN, soundVolume);
	}
	else
	{
		alListenerf(AL_GAIN, 0.0f);
	}
}

- (BOOL)loadSoundNamed:(NSString*)name withFileNamed:(NSString*)fileName withLoopFlag:(BOOL)loopFlag;
{
	// Get the path of the file
	NSString *const path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"wav"];
	if(!path)
	{
		return NO;
	}

	// Open the file
	ExtAudioFileRef extRef;
	if(ExtAudioFileOpenURL((CFURLRef)[NSURL fileURLWithPath:path], &extRef))
	{
		return NO;
	}

	// Get the format of the file
	AudioStreamBasicDescription fileFormat;
	UInt32 propertySize = sizeof(fileFormat);
	if(ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileDataFormat, &propertySize, &fileFormat) || fileFormat.mChannelsPerFrame > 2)
	{
		ExtAudioFileDispose(extRef);
		return NO;
	}

	// Set the output format
	AudioStreamBasicDescription outputFormat;
	outputFormat.mFormatID = kAudioFormatLinearPCM;
	outputFormat.mSampleRate = fileFormat.mSampleRate;
	outputFormat.mBitsPerChannel = 16;
	outputFormat.mChannelsPerFrame = fileFormat.mChannelsPerFrame;
	outputFormat.mBytesPerFrame = (outputFormat.mBitsPerChannel * outputFormat.mChannelsPerFrame) >> 3;
	outputFormat.mFramesPerPacket = 1;
	outputFormat.mBytesPerPacket = outputFormat.mBytesPerFrame * outputFormat.mFramesPerPacket;
	outputFormat.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
	if(ExtAudioFileSetProperty(extRef, kExtAudioFileProperty_ClientDataFormat, sizeof(outputFormat), &outputFormat))
	{
		ExtAudioFileDispose(extRef);
		return NO;
	}

	// Compute the size of the data
	SInt64 frameCount;
	propertySize = sizeof(frameCount);
	if(ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileLengthFrames, &propertySize, &frameCount))
	{
		ExtAudioFileDispose(extRef);
		return NO;
	}
	UInt32 const dataSize = frameCount * outputFormat.mBytesPerFrame;

	// Read the data
	void *const data = malloc(dataSize);
	if(!data)
	{
		ExtAudioFileDispose(extRef);
		return NO;
	}
	AudioBufferList dataBuffer;
	dataBuffer.mNumberBuffers = 1;
	dataBuffer.mBuffers[0].mDataByteSize = dataSize;
	dataBuffer.mBuffers[0].mNumberChannels = outputFormat.mChannelsPerFrame;
	dataBuffer.mBuffers[0].mData = data;
	if(ExtAudioFileRead(extRef, (UInt32*)&frameCount, &dataBuffer))
	{
		free(data);
		ExtAudioFileDispose(extRef);
		return NO;
	}
	ExtAudioFileDispose(extRef);

	// Load the data into an openAL buffer
	ALuint buffer;
	alGenBuffers(1, &buffer);
	alBufferData(buffer, (outputFormat.mChannelsPerFrame > 1) ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16, data, dataSize, outputFormat.mSampleRate);
	free(data);
	[buffers addObject:[NSNumber numberWithUnsignedInteger:buffer]];

	// Attach the buffer to a source
	ALuint source;
	alGenSources(1, &source);
	alSourcei(source, AL_BUFFER, buffer);
	alSourcef(source, AL_PITCH, 1.0f);
	alSourcef(source, AL_GAIN, 1.0f);
	if(loopFlag)
	{
		alSourcei(source, AL_LOOPING, AL_TRUE);
	}
	[sources setObject:[NSNumber numberWithUnsignedInt:source] forKey:name];
	return YES;
}

- (void)playSoundNamed:(NSString*)name
{
	NSNumber* sourceNumber = [sources objectForKey:name];
	if(sourceNumber)
	{
		ALenum state;
		NSUInteger const source = [sourceNumber unsignedIntegerValue];
		alGetSourcei(source, AL_SOURCE_STATE, &state);
		if(state != AL_PLAYING)
		{
			alSourcePlay(source);
		}
	}
}

- (void)stopSoundNamed:(NSString*)name
{
	if(name)
	{
		NSNumber* sourceNumber = [sources objectForKey:name];
		if(sourceNumber)
		{
			alSourceStop([sourceNumber unsignedIntegerValue]);
		}
	}
	else
	{
		for(NSNumber* sourceNumber in [sources allValues])
		{
			alSourceStop([sourceNumber unsignedIntegerValue]);
		}
	}
}

- (void)createMusicPlayer
{
	// Release the current music player (if any)
	[musicPlayer release];

	// Check whether there is a music to play
	if(musicName)
	{
		// Initialize a new music player
		musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:musicName ofType:@"mp3"]] error:nil];
		musicPlayer.numberOfLoops = musicNumberOfLoops;
		musicPlayer.volume = musicMute ? 0.0f : musicVolume;
	}
	else
	{
		// No need to have a music player at the moment
		musicPlayer = nil;
	}
}

- (void)toggleMusicState
{
	// Check whether music shall be turned-on
	if(musicState == MUSIC_NONE)
	{
		// Play the music
		[musicPlayer play];
		musicState = MUSIC_GAME;
		return;
	}

	// Check whether the iPod is currently playing
	if(musicState == MUSIC_IPOD)
	{
		// Change the audio session
		AudioSessionInitializeHardwareDecoding();

		// Initialize the music player
		[self createMusicPlayer];
	}
	else
	{
		// Stop the music
		[musicPlayer stop];
	}
	musicState = MUSIC_NONE;
}

- (void)playMusicNamed:(NSString*)name withLoopFlag:(BOOL)loopFlag
{
	// Check whether the new music name is different from the one that is currently registered
	if(![name isEqualToString:musicName])
	{
		// Take note of the new music name and expected number of loops
		[musicName release];
		musicName = [[NSString alloc] initWithString:name];
		if(loopFlag)
		{
			musicNumberOfLoops = -1;
		}
		else
		{
			musicNumberOfLoops = 0;
		}

		// Enable the music (in case it was muted)
		musicMute = NO;

		// Make sure the iPod music isn't playing
		if(musicState == MUSIC_IPOD)
		{
			return;
		}

		// Initialize a new music player
		[self createMusicPlayer];
	}

	// Start the music as needed
	if(musicState == MUSIC_GAME && !musicPlayer.playing)
	{
		[musicPlayer play];
	}
}

- (void)stopMusic
{
	// Stop the music
	[musicPlayer stop];
}

- (void)pauseAll
{
	ALenum state;
	for(NSNumber* sourceNumber in [sources allValues])
	{
		NSUInteger source = [sourceNumber unsignedIntegerValue];
		alGetSourcei(source, AL_SOURCE_STATE, &state);
		if(state == AL_PLAYING)
		{
			alSourcePause(source);
		}
	}
	musicPlayer.volume = 0.0f;
	musicMute = YES;
}

- (void)resumeAll
{
	ALenum state;
	for(NSNumber* sourceNumber in [sources allValues])
	{
		NSUInteger source = [sourceNumber unsignedIntegerValue];
		alGetSourcei(source, AL_SOURCE_STATE, &state);
		if(state == AL_PAUSED)
		{
			alSourcePlay(source);
		}
	}
	musicPlayer.volume = musicVolume;
	musicMute = NO;
}

- (void)dealloc
{
	// Release the current music player and name (if any)
	[musicName release];
	[musicPlayer release];

	// Release the sources
	for(NSNumber* sourceNumber in [sources allValues])
	{
		NSUInteger source = [sourceNumber unsignedIntegerValue];
		alDeleteSources(1, &source);
	}
	[sources release];

	// Release the buffers
	for(NSNumber* bufferNumber in buffers)
	{
		NSUInteger buffer = [bufferNumber unsignedIntegerValue];
		alDeleteBuffers(1, &buffer);
	}
	[buffers release];

	// Destroy the context and close the device
	alcDestroyContext(context);
	alcCloseDevice(device);

	// Destroy everything else
	sharedInstance = nil;
	[super dealloc];
}

@end
