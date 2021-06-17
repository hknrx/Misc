#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#define SENSOR_BUFFER_SIZE   30
#define SENSOR_UPDATE_PERIOD 4.0

@interface ThermometerViewController : UIViewController <CLLocationManagerDelegate>
{
	unsigned char sensorIndex;
	unsigned char sensorCount;
	double sensor[SENSOR_BUFFER_SIZE];
	double sensorSum;
	double sensorUpdateTime;

	double measureInternalCelsius;
	double measureInternalFahrenheit;
	double measureExternalCelsius;
	double measureExternalFahrenheit;

	BOOL displayFahrenheit;
	IBOutlet UILabel* displayInternal;
	IBOutlet UILabel* displayExternal;
	NSTimer* displaySwapTimer;

	IBOutlet UILabel* noteInternal;
}

@property (nonatomic,retain) IBOutlet UILabel* displayInternal;
@property (nonatomic,retain) IBOutlet UILabel* displayExternal;
@property (nonatomic,retain) IBOutlet UILabel* noteInternal;

+ (double)convertToCelsiusFromFahrenheit:(double)value;

@end

