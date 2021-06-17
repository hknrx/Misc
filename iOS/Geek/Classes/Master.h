#import <UIKit/UIKit.h>
#import "Slave.h"
#import "FBConnect/FBConnect.h"

@class Label;
@class Info;

@interface Master : UIView <FBSessionDelegate>
{
	enum {FACEBOOK_DONE, FACEBOOK_PUBLISH_GENERAL, FACEBOOK_PUBLISH_FUNFAIR, FACEBOOK_PUBLISH_NERD_TEST} facebookPublish;
	FBSession* facebookSession;

	Label* barLabelCoins;
	UIBarButtonItem* barButtonItemHelp;
	UIBarButtonItem* barButtonItemBack;
	UIBarButtonItem* barButtonItemCoins;
	UIBarButtonItem* barButtonItemFacebook;
	UIBarButtonItem* barButtonItemInfo;
	UIBarButtonItem* barButtonItemSpace;
	UIToolbar* barView;
	NSMutableArray* slaveViewHistory;
	NSTimeInterval slaveViewTimestamp;
	UIView<Slave>* slaveView;
	UIView* infoViewContainer;
	BOOL infoViewAutomatic;
	Info* infoView;
}

- (void)infoViewToggle;
- (BOOL)slaveViewHistoryContainsClass:(Class<Slave>)viewClass;
- (void)slaveViewUpdateUptime;
- (Class<Slave>)slaveViewFavoriteClassAndTotalUptime:(float*)uptimeTotal;
- (void)slaveViewSwap:(Class)viewClass;
- (void)cashAdd:(NSInteger)amount increaseKey:(NSString*)key;

@end
