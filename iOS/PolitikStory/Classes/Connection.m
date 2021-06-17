#import "Connection.h"

@interface Connection ()
{
	void (^block)(NSData * data);
	NSMutableData * receivedData;
}

@end

@implementation Connection

- (id)initWithRequest:(NSURLRequest *)request withBlock:(void (^)(NSData * data))_block
{
	self = [super initWithRequest:request delegate:self];
	if(self)
	{
		block = _block;
		receivedData = [NSMutableData data];
	}
	return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#ifdef DEBUG
	NSLog(@"Connection error: %@", error.localizedDescription);
#endif

	receivedData = nil;
	if(block)
	{
		block(receivedData);
		block = nil;
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
#ifdef DEBUG
	NSLog(@"Received %d bytes of data: %@", [receivedData length], [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding]);
#endif

	if(block)
	{
		block(receivedData);
		block = nil;
	}
	receivedData = nil;
}

@end
