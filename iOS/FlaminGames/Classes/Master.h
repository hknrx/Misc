#import <UIKit/UIKit.h>

#ifdef FLAMIN_GIANT
	#define screenWidth  768.0f
	#define screenHeight 1024.0f
	#define topBarHeight 110.0f
#else
	#define screenWidth  320.0f
	#define screenHeight 480.0f
	#define topBarHeight 44.0f
#endif

@class Label;
@class MenuLoading;
@class MenuHelp;

@protocol SlaveProtocol;

@interface Master : UIViewController
{
	CGRect viewFrame;
	Label* barLabelCoins;
	unsigned int barLabelCoinsTimer;
	UIView<SlaveProtocol>* slave;
	BOOL slaveRestarting;
	MenuLoading* menuLoading;
	MenuHelp* menuHelp;
	NSString* savingUserId;
	NSString* savingKeyCoins;
	NSString* savingKeyGames;
}

+ (vm_size_t)memoryUsage;
+ (void)animateView:(UIView const*const)view setHidden:(BOOL)hidden;
- (void)restartSlave;
- (unsigned int)frameRate;
- (void)update;
- (void)resume;
- (NSInteger)addCoins:(NSInteger)amount;
- (NSInteger)playGameWithCoins:(NSInteger)amount;
- (void)changeToUser:(NSString*)userId;

@end
