#import <AudioToolbox/AudioToolbox.h>
#import "Voice.h"
#import "Fft.h"

#define soundBufferCount   3
#define soundBufferSizeLog 10
#define soundBufferSize    (1 << soundBufferSizeLog)
#define soundMaxDuration   10

@implementation Voice

typedef struct
{
	AudioStreamBasicDescription dataFormat;
	AudioQueueRef               queue;
	AudioQueueBufferRef         buffers[soundBufferCount];
}
SoundState;

static UIButton* activeButton = nil;
static UIProgressView* progressBar = nil;

static char* soundFile = NULL;
static FILE* soundHandle = NULL;
static SoundState soundState;
static float soundScale = 1.0f;
static int soundSampleCurrent = 0;
static int soundSampleCount = 0;

static CGFloat const colors[12] = {0.3f, 0.3f, 0.4f, 1.0f, 0.6f, 0.6f, 0.8f, 1.0f, 0.3f, 0.3f, 0.4f, 1.0f};

static void SoundStop();

static void RecordCallback(void * userData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, AudioTimeStamp const* inStartTime, UInt32 inNumPackets, AudioStreamPacketDescription const* inPacketDesc)
{
	if(userData == &soundState)
	{
		// Compute the FFT
		FftForward(inBuffer->mAudioData);

		// Save half of the spectrum
		SpectrumHalfSave(soundHandle);

		// Update the progress bar
		++soundSampleCurrent;
		progressBar.progress = (float)soundSampleCurrent / soundSampleCount;
		if(soundSampleCurrent >= soundSampleCount)
		{
			SoundStop();
			return;
		}

		// Enqueue the sound buffer
		AudioQueueEnqueueBuffer(soundState.queue, inBuffer, 0, NULL);
	}
}

static void PlaybackCallback(void * userData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
	if(userData == &soundState)
	{
		// Update the progress bar
		++soundSampleCurrent;
		progressBar.progress = (float)soundSampleCurrent / soundSampleCount;

		// Load half of the spectrum
		if(!SpectrumHalfLoad(soundHandle))
		{
			SoundStop();
			return;
		}

		// Scale half of the spectrum then generate its second half
		SpectrumHalfScale(soundScale);
		SpectrumHalfCreate();

		// Compute the iFFT
		FftInverse(inBuffer->mAudioData);

		// Enqueue the sound buffer
		AudioQueueEnqueueBuffer(soundState.queue, inBuffer, 0, NULL);
	}
}

static BOOL SoundRecord(char const*const soundFile)
{
	// Make sure there isn't a sound started
	if(soundHandle)
	{
		return NO;
	}

	// Initialize the sound file
	soundHandle = fopen(soundFile, "wb");
	if(!soundHandle)
	{
		return NO;
	}

	// Initialize the count of samples
	soundSampleCurrent = 0;
	soundSampleCount = soundMaxDuration * soundState.dataFormat.mSampleRate / soundBufferSize;

	// Enable the audio session
	UInt32 const propertyData = kAudioSessionCategory_RecordAudio;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(propertyData), &propertyData);
	AudioSessionSetActive(true);

	// Initialize the audio queue
	AudioQueueNewInput(&soundState.dataFormat, RecordCallback, &soundState, NULL, kCFRunLoopCommonModes, 0, &soundState.queue);
	for(unsigned int index = 0; index < soundBufferCount; ++index)
	{
		AudioQueueAllocateBuffer(soundState.queue, soundBufferSize * soundState.dataFormat.mBytesPerPacket, &soundState.buffers[index]);
		AudioQueueEnqueueBuffer(soundState.queue, soundState.buffers[index], 0, NULL);
	}
	AudioQueueStart(soundState.queue, NULL);
	return YES;
}

static BOOL SoundPlay(char const*const soundFile)
{
	// Make sure there isn't a sound started
	if(soundHandle)
	{
		return NO;
	}

	// Initialize the sound file
	soundHandle = fopen(soundFile, "rb");
	if(!soundHandle)
	{
		return NO;
	}

	// Initialize the count of samples
	soundSampleCurrent = -soundBufferCount;
	soundSampleCount = SpectrumHalfCount(soundHandle) - soundBufferCount;

	// Enable the audio session
	UInt32 const propertyData = kAudioSessionCategory_AmbientSound;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(propertyData), &propertyData);
	AudioSessionSetActive(true);

	// Initialize the audio queue
	AudioQueueNewOutput(&soundState.dataFormat, PlaybackCallback, &soundState, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &soundState.queue);
	for(unsigned int index = 0; index < soundBufferCount; ++index)
	{
		AudioQueueAllocateBuffer(soundState.queue, soundBufferSize * soundState.dataFormat.mBytesPerPacket, &soundState.buffers[index]);
		soundState.buffers[index]->mAudioDataByteSize = soundBufferSize * soundState.dataFormat.mBytesPerPacket;
		PlaybackCallback(&soundState, soundState.queue, soundState.buffers[index]);
	}
	AudioQueueStart(soundState.queue, NULL);
	return YES;
}

static void SoundStop()
{
	// Make sure a sound was started
	if(soundHandle)
	{
		// Disable the audio session
		AudioSessionSetActive(false);

		// Finalize the audio queue
		AudioQueueDispose(soundState.queue, true);

		// Close the sound file
		fclose(soundHandle);
		soundHandle = NULL;
	}

	// There shouldn't be any active button anymore
	if(activeButton)
	{
		[activeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		activeButton = nil;
	}
}

- (NSString*)helpText
{
	return @"Tap the robot's left eye to start recording a short sentence, then tap it again to stop (note: be sure to speak close enough to the iPhone microphone).\n\nAdjust the pitch using the robot's belly button, then tap its right eye to listen to the transformed voice!";
}

- (NSString*)infoText
{
	return @"Because Geeks are too shy to talk to anyone, they find it necessary to disguise their voice when they are forced to enter a discussion... Here comes \"Pitch Robot\"!";
}

+ (NSString*)menuName
{
	return @"Pitch Robot";
}

+ (BarContent)barContent
{
	return BAR_NOTHING;
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Create the buttons
		recordingButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[recordingButton setFrame:CGRectMake(60.0f, 160.0f, 80.0f, 30.0f)];
		[recordingButton setTitle:@"RECORD" forState:UIControlStateNormal];
		[recordingButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[recordingButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
		[self addSubview:recordingButton];

		playingButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[playingButton setFrame:CGRectMake(180.0f, 160.0f, 80.0f, 30.0f)];
		[playingButton setTitle:@"PLAY" forState:UIControlStateNormal];
		[playingButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[playingButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
		[self addSubview:playingButton];

		progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
		[progressBar setFrame:CGRectMake(60.0f, 271.0f, 200.0f, 9.0f)];
		[self addSubview:progressBar];

		UISlider* sliderBar = [[UISlider alloc] initWithFrame:CGRectMake(40.0f, 366.0f, 240.0f, 23.0f)];
		[sliderBar setMinimumValue:0.5f];
		[sliderBar setMaximumValue:1.5f];
		[sliderBar setValue:soundScale];
		[sliderBar addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];
		[self addSubview:sliderBar];
		[sliderBar release];

		// Initialize the FFT
		FftInitialize(soundBufferSizeLog, 4.0f);

		// Define the sound file name
		soundFile = (char*)malloc(FILENAME_MAX);
		[[NSTemporaryDirectory() stringByAppendingPathComponent:@"voice.bin"] getCString:soundFile maxLength:FILENAME_MAX encoding:NSASCIIStringEncoding];

		// Set the sound format
		soundState.dataFormat.mSampleRate       = 11025.0;
		soundState.dataFormat.mFormatID         = kAudioFormatLinearPCM;
		soundState.dataFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
		soundState.dataFormat.mFramesPerPacket  = 1;
		soundState.dataFormat.mChannelsPerFrame = 1;
		soundState.dataFormat.mBitsPerChannel   = 16;
		soundState.dataFormat.mBytesPerFrame    = soundState.dataFormat.mChannelsPerFrame * (soundState.dataFormat.mBitsPerChannel >> 3);
		soundState.dataFormat.mBytesPerPacket   = soundState.dataFormat.mBytesPerFrame * soundState.dataFormat.mFramesPerPacket;
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	// Define the path (shape) of the robot
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 40.0f, 140.0f);
	CGPathAddArc(path, NULL, 160.0f, 140.0f, 120.0f, M_PI, 2 * M_PI, 0);
	CGPathAddLineToPoint(path, NULL, 280.0f, 300.0f);
	CGPathAddLineToPoint(path, NULL, 40.0f, 300.0f);
	CGPathCloseSubpath(path);
	CGPathMoveToPoint(path, NULL, 10.0f, 350.0f);
	CGPathAddArc(path, NULL, 40.0f, 350.0f, 30.0f, M_PI, 3 * M_PI_2, 0);
	CGPathAddArc(path, NULL, 280.0f, 350.0f, 30.0f, 3 * M_PI_2, 2 * M_PI, 0);
	CGPathAddLineToPoint(path, NULL, 310.0f, 440.0f);
	CGPathAddLineToPoint(path, NULL, 10.0f, 440.0f);
	CGPathCloseSubpath(path);

	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Draw the robot
	CGContextSetRGBFillColor(context, 0.2f, 0.2f, 0.4f, 1.0f);
	CGContextAddRect(context, CGRectMake(50.0f, 110.0f, 220.0f, 45.0f));
	CGContextAddRect(context, CGRectMake(80.0f, 300.0f, 160.0f, 20.0f));
	CGContextFillPath(context);

	CGContextSaveGState(context);
	CGContextAddArc(context, 100.0f, 160.0f, 50.0f, 0.0f, 2 * M_PI, 0);
	CGContextAddArc(context, 220.0f, 160.0f, 50.0f, 0.0f, 2 * M_PI, 0);
	CGContextAddPath(context, path);
	CGContextEOClip(context);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 3);
	CGContextDrawLinearGradient(context, gradient, CGPointMake(0.0f, 0.0f), CGPointMake(320.0f, 0.0f), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorSpace);
	CGContextRestoreGState(context);

	CGContextSetLineWidth(context, 4.0f);
	CGContextSetRGBStrokeColor(context, 0.2f, 0.2f, 0.4f, 1.0f);
	CGContextAddPath(context, path);
	CGContextStrokePath(context);

	// Release the path
	CGPathRelease(path);

	// Display the labels
	static NSString const*const labelHelium = @"HELIUM";
	static NSString const*const labelManiac = @"MANIAC";

	UIFont *const font = [UIFont fontWithName:@"Arial" size:15.0f];
	CGContextSetRGBFillColor(context, 1.0f, 0.5f, 0.1f, 1.0f);

	CGSize size = [labelHelium sizeWithFont:font];
	CGContextSaveGState(context);
	CGContextConcatCTM(context, (CGAffineTransform){0.0f, -1.0f, 1.0f, 0.0f, 27.0f - size.height / 2, 378.0f + size.width / 2});
	[labelHelium drawAtPoint:CGPointZero withFont:font];
	CGContextRestoreGState(context);

	size = [labelManiac sizeWithFont:font];
	CGContextSaveGState(context);
	CGContextConcatCTM(context, (CGAffineTransform){0.0f, 1.0f, -1.0f, 0.0f, 293.0f + size.height / 2, 378.0f - size.width / 2});
	[labelManiac drawAtPoint:CGPointZero withFont:font];
	CGContextRestoreGState(context);
}

- (void)buttonPressed:(id)sender
{
	// Was a button active?
	if(activeButton)
	{
		// Check whether the button being pressed was active
		BOOL const done = activeButton == sender;

		// Stop the sound
		SoundStop();

		// If the button being pressed was active, then leave
		if(done)
		{
			return;
		}
	}

	// Check whether it is time to record or playback the sound
	BOOL ok;
	if(sender == recordingButton)
	{
		// Record the sound
		ok = SoundRecord(soundFile);
	}
	else
	{
		// Play the sound
		ok = SoundPlay(soundFile);
	}

	// Change the button color if the action has been successfull
	if(ok)
	{
		[sender setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
		activeButton = sender;
	}
}

- (void)sliderMoved:(id)sender
{
	soundScale = ((UISlider*)sender).value;
}

- (void)dealloc
{
	// Stop the sound (if any)
	SoundStop();

	// Destroy the string that defined the sound file name
	free(soundFile);

	// Finalize the FFT
	FftFinalize();

	// Destroy the progress bar
	[progressBar release];

	// Destroy everything else
	[super dealloc];
}

@end
