/*
 TODO (blocking):
 - (N/A).

 TODO (optionnal):
 - Propose a little menu like the one shown on "maps" (page tearing): "calibration" (or "options"), with a description "iPhone usage in the past 5mn" and a scale button with "on rest" on the left and "intensive use" on the right. The position "on rest" shall correspond to no transformation at all, while the right position shall correspond to the transformation computed for an heavy use (TrH = KaH * Ti + KbH). There could be a system to automatically modify the calibration over time: if the iPhone is being charged, then move towards the right, or else move towards the "stable" position (to be measured precisely).
 - The little menu could allow to change the display units: "°F and °C", "°F only" and "°C only".
 - Detect whether the iPhone is being charged, in which case "high" is automatically applied. (=> UIDevice class, methods "batteryMonitoringEnabled" and "batteryState, value "UIDeviceBatteryStateUnplugged")
*/

/*
 * This program uses the iPhone 3GS magnetometer (AK8973) to read the internal temperature.
 * See http://www.alldatasheet.com/datasheet-pdf/pdf/219477/AKM/AK8973.html
 */

#import "ThermometerViewController.h"
#import "ThermometerView.h"

@implementation ThermometerViewController

@synthesize displayInternal, displayExternal, noteInternal;

typedef struct
{
	Class class;
	char dummy[28];
	double x;
	double y;
	double z;
	double temperature;
}
HeadingData;

typedef struct
{
	Class class;
	HeadingData* headingData;
}
HeadingPointer;

- (void)viewDidLoad
{
	[super viewDidLoad];

	sensorIndex = 0;
	sensorCount = 0;
	sensorSum = 0.0;
	sensorUpdateTime = 0.0;

	displayFahrenheit = NO;
	displaySwapTimer = [NSTimer scheduledTimerWithTimeInterval:(4.0) target:self selector:@selector(swapUnits) userInfo:nil repeats:YES];

	CGAffineTransform rotate = {0.0, -1.0, 1.0, 0.0, 0.0, 0.0};
	noteInternal.transform = rotate;
}

+ (double)convertToFahrenheitFromCelsius:(double)value
{
	return 1.8 * value + 32.0;
}

+ (double)convertToCelsiusFromFahrenheit:(double)value
{
	return (value - 32.0) / 1.8;
}

+ (double)convertToExternalFromCelsius:(double)value
{
	// Linear interpolation with the following settings:
	// - 24°C internal => 18°C external
	// - 40°C internal => 30°C external
	return 18.0 + (30.0 - 18.0) * (value - 24.0) / (40.0 - 24.0);
}

- (void)updateDisplay
{
	// Make sure there is data
	if(!sensorCount)
	{
		return;
	}

	// Update the display
	if(displayFahrenheit)
	{
		displayInternal.text = [NSString stringWithFormat:@"%.1lf°F", measureInternalFahrenheit];
		displayExternal.text = [NSString stringWithFormat:@"%.1lf°F", measureExternalFahrenheit];
	}
	else
	{
		displayInternal.text = [NSString stringWithFormat:@"%.1lf°C", measureInternalCelsius];
		displayExternal.text = [NSString stringWithFormat:@"%.1lf°C", measureExternalCelsius];
	}
}

- (void)swapUnits
{
	// Swap the units (Celsius / Fahrenheit)
	displayFahrenheit = !displayFahrenheit;
	
	// Update the display
	[self updateDisplay];
}

- (void)locationManager:(CLLocationManager*)manager didUpdateHeading:(CLHeading*)newHeading
{
	// Make sure the data aren't too fresh
	double time = [NSDate timeIntervalSinceReferenceDate];
	if(time < sensorUpdateTime)
	{
		return;
	}
	sensorUpdateTime = time + SENSOR_UPDATE_PERIOD;

	// Get the temperature measured by the magnetometer
	double temperature = ((HeadingPointer*)newHeading)->headingData->temperature;

	// Handle the buffer in which measures are stored (allowing to compute the average of the temperature over several samples)
	if(sensorCount < SENSOR_BUFFER_SIZE)
	{
		++sensorCount;
	}
	else
	{
		sensorSum -= sensor[sensorIndex];
	}
	sensor[sensorIndex] = temperature;
	sensorSum += temperature;
	if(sensorIndex)
	{
		--sensorIndex;
	}
	else
	{
		sensorIndex = SENSOR_BUFFER_SIZE - 1;
	}

	// Compute the actual internal temperature (average of all the samples)
	measureInternalCelsius = sensorSum / sensorCount;
	measureInternalFahrenheit = [ThermometerViewController convertToFahrenheitFromCelsius:measureInternalCelsius];

	// Estimare the external (ambient) temperature
	measureExternalCelsius = [ThermometerViewController convertToExternalFromCelsius:measureInternalCelsius];
	measureExternalFahrenheit = [ThermometerViewController convertToFahrenheitFromCelsius:measureExternalCelsius];

	// Inform the thermometer view of the change of temperature
	[(ThermometerView*)self.view.superview setTemperatureCelsiusExpected:measureExternalCelsius];

	// Update the display
	[self updateDisplay];
}

- (void)dealloc
{
	[displaySwapTimer invalidate];
	[super dealloc];
}

@end
