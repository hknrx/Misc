#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#define SENSOR_BUFFER_SIZE   30
#define SENSOR_UPDATE_PERIOD 4.0

@class CLLocationManager;

@interface Thermometer : UIView <CLLocationManagerDelegate>
{
	CGGradientRef gradientBackground;
	CGGradientRef gradientThermometer;

	UIImageView* temperatureBar;
	UILabel* temperatureLabel;

	unsigned char sensorIndex;
	unsigned char sensorCount;
	double sensor[SENSOR_BUFFER_SIZE];
	double sensorSum;
	double sensorUpdateTime;

	CLLocationManager* locationManager;
}

@end
