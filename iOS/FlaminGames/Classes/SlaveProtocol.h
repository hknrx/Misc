@class Master;

@protocol SlaveProtocol <NSObject>

- (unsigned int)frameRate;
- (NSString*)title;
- (NSString*)helpText;
- (id)initWithFrame:(CGRect)frame withMaster:(Master*)master;
- (void)update;
- (void)changeToUser:(NSString*)userId;

@end
