@interface Connection : NSURLConnection <NSURLConnectionDelegate>

- (id)initWithRequest:(NSURLRequest *)request withBlock:(void (^)(NSData * data))block;

@end
