#import "ViewController.h"
#import "Results.h"
#import "Vote.h"
#import "Connection.h"
#import "JSONKit.h"
#import <CommonCrypto/CommonHMAC.h>

@interface ViewController ()
{
	NSString * userAgent;
	UIView * mainView;
	ADBannerView * adBannerView;
}

@end

@implementation ViewController

static NSString *const baseUri = @"http://api.majormode.com/poll";
static NSString *const apiKey = @"a6086733548a11e1a67a109adda98fe0";
static NSString *const secretKey = @"OTc2ZDZjYjUyZmRiNDFiNGE5MWYxYTg3M2M4YjhiMDQ=";
static NSString *const pollId = @"9f31ad74-556b-11e1-8c45-60eb699b8d73";

+ (NSString *)signText:(NSString *)input withSecret:(NSString *)secret
{
	NSData * inputData = [input dataUsingEncoding:NSUTF8StringEncoding];
	NSData * secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
	unsigned char digest[CC_SHA1_DIGEST_LENGTH];
	CCHmac(kCCHmacAlgSHA1, [secretData bytes], [secretData length], [inputData bytes], [inputData length], digest);
	NSMutableString * output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
	for(int byte = 0; byte < CC_SHA1_DIGEST_LENGTH; ++byte)
	{
		[output appendFormat:@"%02x", digest[byte]];
	}
	return output;
}

- (id)init
{
	self = [super init];
	if(self)
	{
		NSBundle * bundle = [NSBundle mainBundle];
		UIDevice * device = [UIDevice currentDevice];
		userAgent = [NSString stringWithFormat:@"%@/%@ (%@/%@; %@)", [bundle objectForInfoDictionaryKey:@"CFBundleName"], [bundle objectForInfoDictionaryKey:@"CFBundleVersion"], [device systemName], [device systemVersion], [device model]];
	}
	return self;
}

- (void)addAdBanner
{
	if(!adBannerView && [[NSUserDefaults standardUserDefaults] objectForKey:@"vote"])
	{
		adBannerView = [[ADBannerView alloc] init];
		adBannerView.requiredContentSizeIdentifiers = [NSSet setWithObject:ADBannerContentSizeIdentifier480x32];
		adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier480x32;
		adBannerView.frame = CGRectOffset(adBannerView.bounds, 0.0f, self.view.bounds.size.height);
		[self.view addSubview:adBannerView];
		adBannerView.delegate = self;
	}
}

- (void)loadView
{
	self.view = [[UIView alloc] init];

	mainView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Default" ofType:@"png"]]];
	CGFloat const fixPosition = (mainView.frame.size.height - mainView.frame.size.width) / 2;
	mainView.transform = CGAffineTransformMake(0.0f, 1.0f, -1.0f, 0.0f, fixPosition, -fixPosition);
	mainView.tag = -1;
	[self.view addSubview:mainView];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	if(mainView.tag < 0)
	{
		[self updateResultsWithBlock:^(BOOL error){
			UIView * oldView = mainView;
			mainView = [[Results alloc] initWithViewController:self];
			[self.view insertSubview:mainView atIndex:0];
			[UIView animateWithDuration:0.5
							 animations:^{
								 oldView.alpha = 0.0f;
							 }
							 completion:^(BOOL error){
								 [oldView removeFromSuperview];
								 [self addAdBanner];
							 }];
		}];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)switchToView:(UIView *)newView fromRight:(BOOL)fromRight
{
	CGPoint oldCenter = mainView.center;
	CGPoint newCenter = newView.center;
	if(fromRight)
	{
		oldCenter.x -= mainView.frame.size.width;
		newView.center = CGPointMake(newView.center.x + newView.frame.size.width, newView.center.y);
	}
	else
	{
		oldCenter.x += mainView.frame.size.width;
		newView.center = CGPointMake(newView.center.x - newView.frame.size.width, newView.center.y);
	}
	[self.view insertSubview:newView atIndex:0];

	[UIView animateWithDuration:0.5
					 animations:^{
						 mainView.center = oldCenter;
						 newView.center = newCenter;
					 }
					 completion:^(BOOL finished){
						 [mainView removeFromSuperview];
						 mainView = newView;
					 }];
}

- (void)displayVoteScreen
{
	[self switchToView:[[Vote alloc] initWithViewController:self] fromRight:YES];
}

- (void)displayResultsScreen
{
	[self switchToView:[[Results alloc] initWithViewController:self] fromRight:NO];
	[self addAdBanner];
}

- (void)sendRequest:(NSMutableURLRequest *)request withSignature:(NSString *)signature withBlock:(void (^)(BOOL error))block
{
	[request setValue:apiKey forHTTPHeaderField:@"X-API-Key"];
	[request setValue:signature forHTTPHeaderField:@"X-API-Sig"];
	[request setValue:userAgent forHTTPHeaderField:@"User-Agent"];

	void (^processingBlock)(NSData * data) = ^(NSData * data)
	{
//		NSString * stringData = @"{\"vote_count\": 21337, \"votes\": [{\"item_id\": 1, \"value\": 15}, {\"item_id\": 0, \"value\": 10}, {\"item_id\": 2, \"value\": 20}, {\"item_id\": 3, \"value\": 30}, {\"item_id\": 4, \"value\": 22}, {\"item_id\": 5, \"value\": 28}]}";
//		data = [stringData dataUsingEncoding:NSUTF8StringEncoding];

		id dictionary;
		id array;
		NSNumber * countObject;
		if(!(dictionary = [data objectFromJSONData])
		   || ![dictionary isKindOfClass:[NSDictionary class]]
		   || ![(countObject = [dictionary valueForKey:@"vote_count"]) isKindOfClass:[NSNumber class]]
		   || ![(array = [dictionary valueForKey:@"votes"]) isKindOfClass:[NSArray class]])
		{
			block(YES);
			return;
		}
		NSMutableDictionary * results = [NSMutableDictionary dictionaryWithCapacity:CANDIDATES_COUNT];
		for(dictionary in array)
		{
			id itemObject;
			id valueObject;
			if(![dictionary isKindOfClass:[NSDictionary class]]
			   || ![(itemObject = [dictionary valueForKey:@"item_id"]) isKindOfClass:[NSNumber class]]
			   || ![(valueObject = [dictionary valueForKey:@"value"]) isKindOfClass:[NSNumber class]])
			{
				block(YES);
				return;
			}
			if([[dictionary valueForKey:@"is_wiped_out"] boolValue])
			{
				valueObject = [NSNumber numberWithInt:-1];
			}
			[results setValue:valueObject forKey:[NSString stringWithFormat:@"candidate_%@", itemObject]];
		}
		[results setValue:countObject forKey:@"count"];
		[[NSUserDefaults standardUserDefaults] setValue:results forKey:@"results"];
		block(NO);
	};

	if(![[Connection alloc] initWithRequest:request withBlock:processingBlock])
	{
		block(YES);
	}
}

- (void)updateResultsWithBlock:(void (^)(BOOL error))block
{
	NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/result?poll_id=%@", baseUri, pollId]];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];

	NSString * signature = [ViewController signText:[NSString stringWithFormat:@"%@?%@", url.path, url.query] withSecret:secretKey];
	[self sendRequest:request withSignature:signature withBlock:block];
}

- (NSString *)voteCreateBodyWithData:(NSDictionary *)data
{
	int candidatesPlungersCount[CANDIDATES_COUNT] = {0, 0, 0, 0, 0, 0};
	for(int plungerId = 0; plungerId < PLUNGERS_COUNT; ++plungerId)
	{
		id plungerData;
		id candidateIdObject;
		unsigned int candidateId;
		if([(plungerData = [data objectForKey:[NSString stringWithFormat:@"plunger_%d", plungerId]]) isKindOfClass:[NSDictionary class]]
		   && [(candidateIdObject = [plungerData valueForKey:@"candidate_id"]) isKindOfClass:[NSNumber class]]
		   && (candidateId = [candidateIdObject intValue]) < CANDIDATES_COUNT)
		{
			++candidatesPlungersCount[candidateId];
		}
	}

	NSMutableArray * candidates = [NSMutableArray arrayWithCapacity:CANDIDATES_COUNT];
	for(int candidateId = 0; candidateId < CANDIDATES_COUNT; ++candidateId)
	{
		[candidates addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:candidateId], @"item_id", [NSNumber numberWithInt:candidatesPlungersCount[candidateId]], @"value", nil]];
	}

	NSDictionary * vote = [NSDictionary dictionaryWithObjectsAndKeys:pollId, @"poll_id", [[UIDevice currentDevice] uniqueIdentifier], @"device_id", candidates, @"votes", nil];
	return [vote JSONString];
}

- (void)voteWithData:(NSDictionary *)data withBlock:(void (^)(BOOL error))block;
{
	NSString * body = [self voteCreateBodyWithData:data];

	NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/vote", baseUri]];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
	[request setHTTPMethod:@"POST"];
	[request setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];

	NSString * signature = [ViewController signText:[url.path stringByAppendingString:body] withSecret:secretKey];
	[self sendRequest:request withSignature:signature withBlock:^(BOOL error){
		if(!error)
		{
			[[NSUserDefaults standardUserDefaults] setValue:data forKey:@"vote"];
		}
		block(error);
	}];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
	return YES;
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
	if(adBannerView.center.y > self.view.bounds.size.height)
	{
		[UIView animateWithDuration:0.5
						 animations:^{
							 adBannerView.frame = CGRectOffset(adBannerView.bounds, 0.0f, self.view.bounds.size.height - adBannerView.frame.size.height);
						 }];
	}
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	if(adBannerView.center.y < self.view.bounds.size.height)
	{
		[UIView animateWithDuration:0.5
						 animations:^{
							 adBannerView.frame = CGRectOffset(adBannerView.bounds, 0.0f, self.view.bounds.size.height);
						 }];
	}
}

- (void)dealloc
{
	adBannerView.delegate = nil;
}

@end
