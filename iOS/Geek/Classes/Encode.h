#import <Foundation/Foundation.h>

@interface Encode : NSObject
{
}

+ (NSString*)md5EncodeString:(NSString*)string;
+ (NSString*)base64EncodeString:(NSString*)string;
+ (NSString*)rot13EncodeString:(NSString*)string;
+ (NSString*)urlEncodeString:(NSString*)string;

@end
