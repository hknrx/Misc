#import <iAd/iAd.h>

@interface ViewController : UIViewController <ADBannerViewDelegate>

- (void)displayVoteScreen;
- (void)displayResultsScreen;
- (void)updateResultsWithBlock:(void (^)(BOOL error))block;
- (void)voteWithData:(NSDictionary *)data withBlock:(void (^)(BOOL error))block;

@end
