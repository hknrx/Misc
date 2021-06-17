#import <CommonCrypto/CommonDigest.h>
#import "Encode.h"

@implementation Encode

static unsigned char const base64Encode[64] =
{
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
	'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
	'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
	'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
	'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
	'w', 'x', 'y', 'z', '0', '1', '2', '3',
	'4', '5', '6', '7', '8', '9', '+', '/',
};

+ (NSString*)md5EncodeString:(NSString*)string
{
	char const*const data = [string UTF8String];
	unsigned char md5[CC_MD5_DIGEST_LENGTH];
	CC_MD5(data, strlen(data), md5);
	return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", md5[0], md5[1], md5[2], md5[3], md5[4], md5[5], md5[6], md5[7], md5[8], md5[9], md5[10], md5[11], md5[12], md5[13], md5[14], md5[15]];
}

+ (NSString*)base64EncodeString:(NSString*)string
{
	char const* dataIn = [string UTF8String];
	unsigned int size = strlen(dataIn);
	char *const dataOut = (char*)malloc((((size + 2) / 3) << 2) + 1);
	unsigned int index = 0;
	while(size >= 3)
	{
		unsigned int threeBytes = (dataIn[0] << 16) | (dataIn[1] << 8) | dataIn[2];
		dataOut[index++] = base64Encode[threeBytes >> 18];
		dataOut[index++] = base64Encode[(threeBytes >> 12) & 63];
		dataOut[index++] = base64Encode[(threeBytes >> 6) & 63];
		dataOut[index++] = base64Encode[threeBytes & 63];
		dataIn += 3;
		size -= 3;
	}
	if(size == 2)
	{
		unsigned int threeBytes = (dataIn[0] << 16) | (dataIn[1] << 8);
		dataOut[index++] = base64Encode[threeBytes >> 18];
		dataOut[index++] = base64Encode[(threeBytes >> 12) & 63];
		dataOut[index++] = base64Encode[(threeBytes >> 6) & 63];
		dataOut[index++] = '=';
	}
	else if(size == 1)
	{
		unsigned int threeBytes = dataIn[0] << 16;
		dataOut[index++] = base64Encode[threeBytes >> 18];
		dataOut[index++] = base64Encode[(threeBytes >> 12) & 63];
		dataOut[index++] = '=';
		dataOut[index++] = '=';
	}
	dataOut[index] = '\0';
	string = [NSString stringWithUTF8String:dataOut];
	free(dataOut);
	return string;
}

+ (NSString*)rot13EncodeString:(NSString*)string
{
	char const*const dataIn = [string UTF8String];
	unsigned int size = strlen(dataIn);
	char *const dataOut = (char*)malloc(size + 1);
	dataOut[size] = '\0';
	while(size--)
	{
		char byte = dataIn[size];
		if(('A' <= byte && byte <= 'M') || ('a' <= byte && byte <= 'm'))
		{
			byte += 13;
		}
		else if(('N' <= byte && byte <= 'Z') || ('n' <= byte && byte <= 'z'))
		{
			byte -= 13;
		}
		dataOut[size] = byte;
	}
	string = [NSString stringWithUTF8String:dataOut];
	free(dataOut);
	return string;
}

+ (NSString*)urlEncodeString:(NSString*)string
{
	return [(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)string, NULL, CFSTR("￼=,!$&'()*+;@?\n\"<>#\t :/"), kCFStringEncodingUTF8) autorelease];
}

@end
