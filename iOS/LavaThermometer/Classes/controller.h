#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "blob.h"

#define SENSOR_BUFFER_SIZE   30
#define SENSOR_UPDATE_PERIOD 4.0

@interface Controller : UIViewController <UIAccelerometerDelegate, CLLocationManagerDelegate>
{
	UIImage* blobTextureLava;
	BlobReference blobTemperature;
	signed long blobGravityForce;
	unsigned char blobGravityAngle;
	signed short blobTimerSwapUnits;

	CLLocationManager* locationManager;
	NSTimer* renderTimer;

	unsigned char sensorIndex;
	unsigned char sensorCount;
	double sensor[SENSOR_BUFFER_SIZE];
	double sensorSum;
	double sensorUpdateTime;

	signed short displayExternalCelsius;
	signed short displayExternalFahrenheit;	
}

- (void)render;

@end
