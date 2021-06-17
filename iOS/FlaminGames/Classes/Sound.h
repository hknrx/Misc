#import <Foundation/Foundation.h>
#import <OpenAL/alc.h>
#import <AVFoundation/AVFoundation.h>

typedef enum {MUSIC_NONE, MUSIC_IPOD, MUSIC_GAME} MusicState;

@interface Sound : NSObject
{
	BOOL soundState;
	ALCdevice* device;
	ALCcontext* context;
	NSMutableArray* buffers;
	NSMutableDictionary* sources;

	AVAudioPlayer* musicPlayer;
	NSString* musicName;
	NSInteger musicNumberOfLoops;
	MusicState musicState;
	BOOL musicMute;
}

@property (nonatomic, readonly) BOOL soundState;
@property (nonatomic, readonly) MusicState musicState;

+ (Sound*)sharedInstance;

- (void)toggleSoundState;
- (BOOL)loadSoundNamed:(NSString*)name withFileNamed:(NSString*)fileName withLoopFlag:(BOOL)loopFlag;
- (void)playSoundNamed:(NSString*)name;
- (void)stopSoundNamed:(NSString*)name;
- (void)toggleMusicState;
- (void)playMusicNamed:(NSString*)name withLoopFlag:(BOOL)loopFlag;
- (void)stopMusic;
- (void)pauseAll;
- (void)resumeAll;

@end
