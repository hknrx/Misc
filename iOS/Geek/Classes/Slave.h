@protocol Slave <NSObject>

typedef enum {BAR_NOTHING, BAR_COINS, BAR_FACEBOOK} BarContent;

@property (nonatomic, readonly) NSString* helpText;
@property (nonatomic, readonly) NSString* infoText;

+ (NSString*)menuName;
+ (BarContent)barContent;

@end
