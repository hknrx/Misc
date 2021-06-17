#import <AudioToolbox/AudioToolbox.h>
#import "Dance.h"
#import "Beat.h"

#define soundBufferCount 3
#define soundBufferSize  512
#define tileWidth        (320.0f / 4)
#define tileHeight       ((480.0f - 44.0f) / 4)

@interface Dancer : UIView
{
	signed char legControl[4];
	CGPoint legPosition[5];
	signed char armControl[4];
	CGPoint armPosition[5];
	unsigned int frameCounter;
}

- (void)animate;

@end

@implementation Dancer

- (void)setPosition
{
	// Set the position of the legs
	legPosition[2].x = tileWidth;
	legPosition[2].y = tileHeight * 2 - tileWidth * 0.5f * (1.0f + M_SQRT1_2);
	legPosition[1].x = legPosition[2].x + tileWidth * 0.5f * cosf(legControl[0] * M_PI_4);
	legPosition[1].y = legPosition[2].y + tileWidth * 0.5f * sinf(legControl[0] * M_PI_4);
	legPosition[0].x = legPosition[1].x + tileWidth * 0.5f * cosf(legControl[1] * M_PI_4);
	legPosition[0].y = legPosition[1].y + tileWidth * 0.5f * sinf(legControl[1] * M_PI_4);
	legPosition[3].x = legPosition[2].x + tileWidth * 0.5f * cosf(legControl[2] * M_PI_4);
	legPosition[3].y = legPosition[2].y + tileWidth * 0.5f * sinf(legControl[2] * M_PI_4);
	legPosition[4].x = legPosition[3].x + tileWidth * 0.5f * cosf(legControl[3] * M_PI_4);
	legPosition[4].y = legPosition[3].y + tileWidth * 0.5f * sinf(legControl[3] * M_PI_4);

	// Set the position of the arms
	armPosition[2].x = tileWidth;
	armPosition[2].y = 90.0f;
	armPosition[1].x = armPosition[2].x + tileWidth * 0.7f * cosf(armControl[0] * M_PI_4);
	armPosition[1].y = armPosition[2].y + tileWidth * 0.7f * sinf(armControl[0] * M_PI_4);
	armPosition[0].x = armPosition[1].x + tileWidth * 0.3f * cosf(armControl[1] * M_PI_4);
	armPosition[0].y = armPosition[1].y + tileWidth * 0.3f * sinf(armControl[1] * M_PI_4);
	armPosition[3].x = armPosition[2].x + tileWidth * 0.7f * cosf(armControl[2] * M_PI_4);
	armPosition[3].y = armPosition[2].y + tileWidth * 0.7f * sinf(armControl[2] * M_PI_4);
	armPosition[4].x = armPosition[3].x + tileWidth * 0.3f * cosf(armControl[3] * M_PI_4);
	armPosition[4].y = armPosition[3].y + tileWidth * 0.3f * sinf(armControl[3] * M_PI_4);
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Define the default state of the dancer
		legControl[0] = 3;
		legControl[1] = 2;
		legControl[2] = 1;
		legControl[3] = 2;

		armControl[0] = 3;
		armControl[1] = 3;
		armControl[2] = 1;
		armControl[3] = 1;

		// Set the position of the legs and arms
		[self setPosition];
	}
	return self;
}

- (void)animate
{
	// Make sure to move one of the legs (at least)
	unsigned short control = (rand() % 3) + 1;
	if(control & 1)
	{
		legControl[0] = 7 - legControl[0];
	}
	legControl[1] = (rand() & 1) + 2;
	if(control & 2)
	{
		legControl[2] = 1 - legControl[2];
	}
	legControl[3] = (rand() & 1) + 1;

	// Make sure to move one of the arms (at least)
	control = (rand() % 3) + 1;
	if(control & 1)
	{
		armControl[0] = ((armControl[0] - 3 + 1 + (rand() & 1)) % 3) + 3;
	}
	armControl[1] = (rand() % 3) - 1 + armControl[0];
	if(control & 2)
	{
		armControl[2] = ((armControl[2] + 1 + 1 + (rand() & 1)) % 3) - 1;
	}
	armControl[3] = (rand() % 3) - 1 + armControl[2];

	// Set the position of the legs and arms
	[self setPosition];
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Clear the view
	CGContextClearRect(context, rect);

	// Display the geek dancer
	float const R = 0.75f + cosf(frameCounter * M_PI / 19) * 0.25f;
	float const G = 0.75f + cosf(frameCounter * M_PI / 23) * 0.25f;
	float const B = 0.75f + cosf(frameCounter * M_PI / 29) * 0.25f;
	++frameCounter;

	CGContextSetRGBStrokeColor(context, R, G, B, 1.0f);
	CGContextSetLineWidth(context, 6.0f);
	CGContextAddArc(context, tileWidth, 40.0f, 30.0f, M_PI_2, 5 * M_PI_2, 0);
	CGContextAddLineToPoint(context, tileWidth, tileHeight * 2 - tileWidth * 0.5f * (1.0f + M_SQRT1_2));
	CGContextAddLines(context, legPosition, 5);
	CGContextAddLines(context, armPosition, 5);
	CGContextStrokePath(context);
}

@end

typedef struct
{
	AudioStreamBasicDescription dataFormat;
	AudioQueueRef               queue;
	AudioQueueBufferRef         buffers[soundBufferCount];
}
SoundState;

static SoundState soundState;
static UIImageView* tiles[16];
static Dancer* dancer;

@implementation Dance

static void RecordCallback(void * userData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, AudioTimeStamp const* inStartTime, UInt32 inNumPackets, AudioStreamPacketDescription const* inPacketDesc)
{
	if(userData == &soundState)
	{
		// Process the sound buffer
		unsigned char beat = 0;
		float onsetfactorMax = 0.0f;
		for(unsigned short index = 0; index < soundBufferSize; ++index)
		{
			float onsetFactor;
			beat |= BeatProcess(((short*)inBuffer->mAudioData)[index], &onsetFactor);
			if(onsetFactor > onsetfactorMax)
			{
				onsetfactorMax = onsetFactor;
			}
		}

		// Check whether there is a beat
		if(beat)
		{
			// Animate the geek dancer
			[dancer animate];
		}

		// Update the dance floor
		unsigned char tileCount = onsetfactorMax * 11;
		if(tileCount)
		{
			unsigned char indexTile = rand() & 15;
			unsigned char const indexTileIncrement = 1 + ((rand() & 7) << 1);
			do
			{
				tiles[indexTile].alpha = 1.0f;
				indexTile = (indexTile + indexTileIncrement) & 15;
			}
			while(--tileCount);
		}

		// Enqueue the sound buffer
		AudioQueueEnqueueBuffer(soundState.queue, inBuffer, 0, NULL);
	}
}

- (NSString*)helpText
{
	return @"Just bring your iPhone close enough to a music source then enjoy watching Mister Sticky Geek dance!";
}

- (NSString*)infoText
{
	return @"Because real Geeks rarely go clubbing and never ever dance in public, they need a virtual dance floor to safely enjoy moving their hot body at home!";
}

+ (NSString*)menuName
{
	return @"Dance Floor";
}

+ (BarContent)barContent
{
	return BAR_NOTHING;
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Set the sound format
		soundState.dataFormat.mSampleRate       = 11025.0;
		soundState.dataFormat.mFormatID         = kAudioFormatLinearPCM;
		soundState.dataFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
		soundState.dataFormat.mFramesPerPacket  = 1;
		soundState.dataFormat.mChannelsPerFrame = 1;
		soundState.dataFormat.mBitsPerChannel   = 16;
		soundState.dataFormat.mBytesPerFrame    = soundState.dataFormat.mChannelsPerFrame * (soundState.dataFormat.mBitsPerChannel >> 3);
		soundState.dataFormat.mBytesPerPacket   = soundState.dataFormat.mBytesPerFrame * soundState.dataFormat.mFramesPerPacket;

		// Initialize the beat detection
		BeatInitialize(soundState.dataFormat.mSampleRate);

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

		// Define the tiles
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGFloat colors[8];
		colors[3] = 1.0f;
		colors[4] = 0.0f;
		colors[5] = 0.0f;
		colors[6] = 0.0f;
		colors[7] = 1.0f;

		UIImage* tileImages[6];
		UIGraphicsBeginImageContext(CGSizeMake(tileWidth, tileHeight));
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGPoint center = CGPointMake(tileWidth / 2, tileHeight / 2);
		for(unsigned char indexColor = 1; indexColor <= 6; ++indexColor)
		{
			for(unsigned char indexComponent = 0; indexComponent < 3; ++indexComponent)
			{
				colors[indexComponent] = indexColor & (1 << indexComponent) ? 1.0f : 0.5f;
			}
			CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
			CGContextClearRect(context, CGRectInfinite);
			CGContextDrawRadialGradient(context, gradient, center, tileHeight / 4, center, tileHeight / 2, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
			tileImages[indexColor - 1] = UIGraphicsGetImageFromCurrentImageContext();
			CGGradientRelease(gradient);
		}
		UIGraphicsEndImageContext();
		CGColorSpaceRelease(colorSpace);

		// Initialize the dance floor
		center.y = tileHeight / 2;
		unsigned char indexTile = 0;
		for(unsigned int y = 0; y < 4; ++y)
		{
			center.x = tileWidth / 2;
			for(unsigned int x = 0; x < 4; ++x)
			{
				tiles[indexTile] = [[UIImageView alloc] initWithImage:tileImages[rand() % 6]];
				tiles[indexTile].center = center;
				tiles[indexTile].alpha = 0.0f;
				[self addSubview:tiles[indexTile]];
				[tiles[indexTile] release];
				++indexTile;
				center.x += tileWidth;
			}
			center.y += tileHeight;
		}

		// Initialize the geek dancer
		dancer = [[Dancer alloc] initWithFrame:CGRectMake(tileWidth, tileHeight, tileWidth * 2, tileHeight * 2)];
		dancer.backgroundColor = [UIColor clearColor];
		[self addSubview:dancer];
		[dancer release];
	}
	return self;
}

- (void)willMoveToSuperview:(UIView*)superView
{
	if(superView)
	{
		// Launch a timer to refresh the display
		timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 30) target:self selector:@selector(update) userInfo:nil repeats:YES];
	}
	else
	{
		// Invalidate the timer
		[timer invalidate];
	}
}

- (void)update
{
	// Update the dance floor
	for(unsigned char indexTile = 0; indexTile < 16; ++indexTile)
	{
		tiles[indexTile].alpha -= 0.2f;
	}

	// Update the geek dancer
	[dancer setNeedsDisplay];
}

- (void)dealloc
{
	// Disable the audio session
	AudioSessionSetActive(false);

	// Finalize the audio queue
	AudioQueueDispose(soundState.queue, true);

	// Finalize the beat detection
	BeatFinalize();

	// Destroy everything else
	[super dealloc];
}

@end
