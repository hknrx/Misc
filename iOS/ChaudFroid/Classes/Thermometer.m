/*
 TODO:
 - Detect whether the iPhone is being charged, in which case a special scaling shall be applied (=> UIDevice class, methods "batteryMonitoringEnabled" and "batteryState, value "UIDeviceBatteryStateUnplugged").

 Notes:
 - This program uses the iPhone 3GS magnetometer (AK8973) to read the internal temperature. See http://www.alldatasheet.com/datasheet-pdf/pdf/219477/AKM/AK8973.html
 */

#import "ApplicationDelegate.h"
#import "Thermometer.h"

#define screenWidth  320.0f
#define screenHeight (480.0f - 20.0f)
#define screenMargin 20.0f

#define thermometerWidth         80.0f
#define thermometerHeight        (screenHeight - screenMargin * 2)
#define thermometerThickness     5.0f
#define thermometerRadiusBottom  ((thermometerWidth - thermometerThickness) / 2)
#define thermometerRadiusTop     (thermometerRadiusBottom / 2)
#define thermometerCenterX       (screenWidth - screenMargin - thermometerWidth / 2)
#define thermometerCenterYBottom ((screenHeight + thermometerHeight - thermometerThickness) / 2 - thermometerRadiusBottom)
#define thermometerCenterYTop    ((screenHeight - thermometerHeight + thermometerThickness) / 2 + thermometerRadiusTop)

#define thermometerTankGap    6.0f
#define thermometerTankRadius (thermometerRadiusBottom - thermometerThickness / 2 - thermometerTankGap)

#define thermometerMarkLeft           (thermometerCenterX - thermometerRadiusTop + thermometerThickness / 2)
#define thermometerMarkLengthMinor    4.0f
#define thermometerMarkLengthMajor    6.0f
#define thermometerMarkThicknessMinor 1.0f
#define thermometerMarkThicknessMajor 3.0f
#define thermometerMarkMargin         20.0f
#define thermometerMarkHeight40       (thermometerCenterYTop + thermometerMarkMargin)
#define thermometerMarkHeight0        (thermometerCenterYBottom - thermometerRadiusBottom - thermometerThickness / 2 - thermometerMarkMargin)

#define thermometerLabelWidth  30.0f
#define thermometerLabelHeight 16.0f
#define thermometerLabelLeft   (thermometerCenterX - thermometerRadiusTop - 3 * thermometerThickness / 2 - thermometerLabelWidth)

#define thermometerBarWidth  ((thermometerRadiusTop - thermometerTankGap) * 2 - thermometerThickness)
#define thermometerBarBottom (thermometerCenterYBottom - thermometerTankRadius * 0.9f)

#define thermometerValueLeft   screenMargin
#define thermometerValueWidth  (thermometerLabelLeft - screenMargin - thermometerValueLeft)
#define thermometerValueHeight 70.0f
#define thermometerValueTop    (screenHeight / 3 - thermometerValueHeight / 2)

@implementation Thermometer

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

static CGFloat const colorsBackground[8] = {0.2f, 0.5f, 0.5f, 1.0f, 0.7f, 1.0f, 1.0f, 1.0f};
static CGFloat const colorsThermometer[8] = {1.0f, 1.0f, 1.0f, 1.0f, 0.6f, 0.6f, 1.0f, 1.0f};
static CGFloat const colorsBar[8] = {1.0f, 0.7f, 0.0f, 1.0f, 1.0f, 0.0f, 0.0f, 1.0f};

+ (double)convertToExternalFromInternal:(double)value
{
	// Linear interpolation with the following settings:
	// - 24°C internal => 17°C external
	// - 40°C internal => 29°C external
	return 17.0 + (29.0 - 17.0) * (value - 24.0) / (40.0 - 24.0);
}

+ (double)convertToHeightFromCelsius:(double)value
{
	return thermometerMarkHeight0 + (thermometerMarkHeight40 - thermometerMarkHeight0) * (value - 0.0) / (40.0 - 0.0);
}

- (void)setBarHeight:(double)value
{
	CGAffineTransform const transform = {thermometerBarWidth, 0.0f, 0.0f, (thermometerBarBottom - value) / 100.0f, thermometerCenterX, (thermometerBarBottom + value - 100.0f) / 2};
	temperatureBar.transform = transform;
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Define the color gradients
		CGColorSpaceRef const colorSpace = CGColorSpaceCreateDeviceRGB();
		gradientBackground = CGGradientCreateWithColorComponents(colorSpace, colorsBackground, NULL, 2);
		gradientThermometer = CGGradientCreateWithColorComponents(colorSpace, colorsThermometer, NULL, 2);
		CGGradientRef gradientBar = CGGradientCreateWithColorComponents(colorSpace, colorsBar, NULL, 2);
		CGColorSpaceRelease(colorSpace);

		// Define the temperature bar
		UIGraphicsBeginImageContext(CGSizeMake(1.0f, 100.0f));
		CGContextRef const context = UIGraphicsGetCurrentContext();
		CGContextDrawLinearGradient(context, gradientBar, CGPointZero, CGPointMake(0.0, 100.0f), 0);
		temperatureBar = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
		[self setBarHeight:[Thermometer convertToHeightFromCelsius:0.0]];
		[self addSubview:temperatureBar];
		[temperatureBar release];
		UIGraphicsEndImageContext();
		CGGradientRelease(gradientBar);

		// Define the temperature label
		temperatureLabel = [[UILabel alloc] initWithFrame:CGRectMake(thermometerValueLeft, thermometerValueTop, thermometerValueWidth, thermometerValueHeight)];
		temperatureLabel.backgroundColor = [UIColor clearColor];
		temperatureLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:64.0f];
		temperatureLabel.text = @"?";
		temperatureLabel.textColor = [UIColor whiteColor];
		temperatureLabel.textAlignment = UITextAlignmentCenter;
		[self addSubview:temperatureLabel];
		[temperatureLabel release];

		// Initialize the sensor
		sensorIndex = 0;
		sensorCount = 0;
		sensorSum = 0.0;
		sensorUpdateTime = 0.0;

		// Initialize the location manager
		if([ApplicationDelegate device3GS])
		{
			locationManager = [[CLLocationManager alloc] init];
			if(locationManager.headingAvailable)
			{
				locationManager.delegate = self;
				[locationManager startUpdatingHeading];
			}
		}
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef const context = UIGraphicsGetCurrentContext();

	// Draw the background
	CGContextDrawLinearGradient(context, gradientBackground, CGPointZero, CGPointMake(0.0f, screenHeight), 0);

	// Define the thermometer's body
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddArc(path, NULL, thermometerCenterX, thermometerCenterYTop, thermometerRadiusTop, M_PI, 0.0f, 0);
	CGPathAddArc(path, NULL, thermometerCenterX, thermometerCenterYBottom, thermometerRadiusBottom, -M_PI / 3, -2 * M_PI / 3, 0);
	CGPathAddLineToPoint(path, NULL, thermometerCenterX - thermometerRadiusTop, thermometerCenterYTop);

	// Fill the thermometer's body
	CGContextSaveGState(context);
	CGContextAddPath(context, path);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, gradientThermometer, CGPointMake(thermometerCenterX, thermometerCenterYTop), CGPointMake(thermometerCenterX, thermometerCenterYBottom), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);

	// Draw the thermometer's body
	CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 0.0f, 1.0f);
	CGContextAddPath(context, path);
	CGContextSetLineWidth(context, thermometerThickness);
	CGContextStrokePath(context);

	// Release the thermometer's body
	CGPathRelease(path);

	// Draw the liquid tank
	CGContextSetRGBFillColor(context, 1.0f, 0.0f, 0.0f, 1.0f);
	CGContextAddArc(context, thermometerCenterX, thermometerCenterYBottom, thermometerTankRadius, 0.0f, 2 * M_PI, 0);
	CGContextFillPath(context);

	// Draw the marks
	CGContextSetRGBFillColor(context, 0.0f, 0.0f, 0.5f, 1.0f);
	UIFont *const font = [UIFont systemFontOfSize:12.0f];
	unsigned char minorMark = 0;
	for(double temperature = 0.0; temperature <= 40.0; temperature += 2.0)
	{
		// Compute the position of the mark
		CGFloat const y = [Thermometer convertToHeightFromCelsius:temperature];

		// Check whether this mark is a minor or a major one
		CGFloat length;
		if(minorMark)
		{
			--minorMark;
			length = thermometerMarkLengthMinor;
			CGContextSetLineWidth(context, thermometerMarkThicknessMinor);
		}
		else
		{
			minorMark = 4;
			length = thermometerMarkLengthMajor;
			CGContextSetLineWidth(context, thermometerMarkThicknessMajor);

			NSString const*const label = [NSString stringWithFormat:@"%.0f°C", temperature];
			[label drawInRect:CGRectMake(thermometerLabelLeft, y - thermometerLabelHeight / 2, thermometerLabelWidth, thermometerLabelHeight) withFont:font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];
		}

		// Draw the mark
		CGContextMoveToPoint(context, thermometerMarkLeft, y);
		CGContextAddLineToPoint(context, thermometerMarkLeft + length, y);
		CGContextStrokePath(context);
	}
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
	double const measureInternal = sensorSum / sensorCount;

	// Estimare the external (ambient) temperature
	double const measureExternal = [Thermometer convertToExternalFromInternal:measureInternal];

	// Refresh the display
	[UIView beginAnimations:@"bar" context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[UIView setAnimationDuration:1.0f];
	[UIView setAnimationRepeatCount:0.0f];
	[self setBarHeight:[Thermometer convertToHeightFromCelsius:measureExternal]];
	[UIView commitAnimations];
	temperatureLabel.text = [NSString stringWithFormat:@"%d°C", lround(measureExternal)];
}

- (void)dealloc
{
	// Destroy the location manager
	[locationManager release];

	// Release the color gradients
	CGGradientRelease(gradientThermometer);
	CGGradientRelease(gradientBackground);

	// Destroy everything else
	[super dealloc];
}

@end
