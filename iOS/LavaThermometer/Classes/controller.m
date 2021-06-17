#import "controller.h"
#import "view.h"
#import "math.h"

#define SCREEN_WIDTH         320
#define SCREEN_HEIGHT        480
#define SCREEN_CENTER_X      (SCREEN_WIDTH / 2)
#define SCREEN_CENTER_Y      (SCREEN_HEIGHT / 2)
#define SCREEN_CONVERT_SHIFT 2

#define BLOB_GRAVITY_SHIFT    6
#define BLOB_TEXTURE_SIZE     64
#define BLOB_TIMER_SWAP_UNITS 90

#define BLOB_SCREEN_WIDTH  (SCREEN_WIDTH << (FIXED_POINT_SHIFT - SCREEN_CONVERT_SHIFT))
#define BLOB_SCREEN_HEIGHT (SCREEN_HEIGHT << (FIXED_POINT_SHIFT - SCREEN_CONVERT_SHIFT))
#define BLOB_SCREEN_XMIN   (-BLOB_SCREEN_WIDTH / 2)
#define BLOB_SCREEN_XMAX   (BLOB_SCREEN_WIDTH / 2)
#define BLOB_SCREEN_YMIN   (-BLOB_SCREEN_HEIGHT / 2)
#define BLOB_SCREEN_YMAX   (BLOB_SCREEN_HEIGHT / 2)

#define BLOB_CONTAINER_THICKNESS (signed long)(FIXED_POINT * 10.00)
#define BLOB_CONTAINER_WIDTH     (BLOB_SCREEN_WIDTH - BLOB_CONTAINER_THICKNESS)
#define BLOB_CONTAINER_XMIN      (-BLOB_CONTAINER_WIDTH / 2)
#define BLOB_CONTAINER_XMAX      (BLOB_CONTAINER_WIDTH / 2)

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

@implementation Controller

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super init])
	{
		// Initialize the view
		self.view = [[View alloc] initWithFrame:frame];

		// Initialize the blob engine
		BlobInitialize(BLOB_SCREEN_XMIN, BLOB_SCREEN_XMAX, BLOB_SCREEN_YMIN, BLOB_SCREEN_YMAX, 0);

		// Load the textures
		blobTextureLava = [UIImage imageNamed:@"Lava.png"];
		BlobLoadTexture(blobTextureLava.CGImage, 0, BLOB_TEXTURE_SIZE, NULL);
		BlobLoadTexture(blobTextureLava.CGImage, 1, BLOB_TEXTURE_SIZE, "?");
		BlobLoadTexture(blobTextureLava.CGImage, 2, BLOB_TEXTURE_SIZE, "?");
		BlobLoadTexture([UIImage imageNamed:@"Background.png"].CGImage, 3, BLOB_TEXTURE_SIZE, NULL);

		// Set the lava lamp background
		BlobBackgroundTextureIdSet(0);
		BlobBackgroundColorIdSet(0);

		// Create the container
		BlobCharacteristics blobCharacteristics;
		blobCharacteristics.elasticity = (signed long)(FIXED_POINT * 0.10);
		blobCharacteristics.friction =   (signed long)(FIXED_POINT * 0.10);
		blobCharacteristics.special.staticTransformation = NULL;
		blobCharacteristics.collisionMask = 1;

		BlobShapeReference blobShape = BlobShapeCreateBox();
		blobCharacteristics.type = BLOB_TYPE_STATIC_HIDDEN;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0, BLOB_SCREEN_YMIN - (BLOB_CONTAINER_THICKNESS / 2), BLOB_CONTAINER_THICKNESS + BLOB_SCREEN_WIDTH + BLOB_CONTAINER_THICKNESS, BLOB_CONTAINER_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0, BLOB_SCREEN_YMAX + (BLOB_CONTAINER_THICKNESS / 2), BLOB_CONTAINER_THICKNESS + BLOB_SCREEN_WIDTH + BLOB_CONTAINER_THICKNESS, BLOB_CONTAINER_THICKNESS);
		blobCharacteristics.type = BLOB_TYPE_STATIC_VISIBLE;
		blobCharacteristics.textureId = 3;
		blobCharacteristics.textureRepeat = 1;
		blobCharacteristics.colorId = 1;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_CONTAINER_XMIN - (BLOB_CONTAINER_THICKNESS / 2), 0, BLOB_CONTAINER_THICKNESS, BLOB_CONTAINER_THICKNESS + BLOB_SCREEN_HEIGHT + BLOB_CONTAINER_THICKNESS);
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, BLOB_CONTAINER_XMAX + (BLOB_CONTAINER_THICKNESS / 2), 0, BLOB_CONTAINER_THICKNESS, BLOB_CONTAINER_THICKNESS + BLOB_SCREEN_HEIGHT + BLOB_CONTAINER_THICKNESS);
		BlobShapeRelease(blobShape);

		// Create several dynamic blobs
		blobCharacteristics.type = BLOB_TYPE_DYNAMIC;
		blobCharacteristics.textureRepeat = 0;
		blobCharacteristics.elasticity =                (signed long)(FIXED_POINT * 0.10);
		blobCharacteristics.friction =                  (signed long)(FIXED_POINT * 0.50);
		blobCharacteristics.special.dynamic.mass =      (signed long)(FIXED_POINT * 0.50);
		blobCharacteristics.special.dynamic.stiffness = (signed long)(FIXED_POINT * 0.40);
		blobCharacteristics.special.dynamic.damping =   (signed long)(FIXED_POINT * 0.30);

		blobShape = BlobShapeCreateBalloon(28);
		blobCharacteristics.textureId = 1;
		blobCharacteristics.colorId = 1;
		blobCharacteristics.special.dynamic.pressure = (signed long)(FIXED_POINT * 40.00);
		blobCharacteristics.timer = rand();
		blobTemperature = BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0 << FIXED_POINT_SHIFT, 0 << FIXED_POINT_SHIFT, 20 << FIXED_POINT_SHIFT, 20 << FIXED_POINT_SHIFT);
		BlobShapeRelease(blobShape);

		blobShape = BlobShapeCreateBalloon(24);
		blobCharacteristics.textureId = 0;
		blobCharacteristics.special.dynamic.pressure = (signed long)(FIXED_POINT * 25.00);
		blobCharacteristics.colorId = 3;
		blobCharacteristics.timer = rand();
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0 << FIXED_POINT_SHIFT, -20 << FIXED_POINT_SHIFT, 16 << FIXED_POINT_SHIFT, 16 << FIXED_POINT_SHIFT);
		blobCharacteristics.colorId = 1;
		blobCharacteristics.timer = rand();
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, 0 << FIXED_POINT_SHIFT,  20 << FIXED_POINT_SHIFT, 16 << FIXED_POINT_SHIFT, 16 << FIXED_POINT_SHIFT);
		BlobShapeRelease(blobShape);

		blobShape = BlobShapeCreateBalloon(20);
		blobCharacteristics.special.dynamic.pressure = (signed long)(FIXED_POINT * 10.00);
		blobCharacteristics.colorId = 5;
		blobCharacteristics.timer = rand();
		BlobObjectCreateEasy(&blobCharacteristics, blobShape,   0 << FIXED_POINT_SHIFT, -40 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT);
		blobCharacteristics.colorId = 3;
		blobCharacteristics.timer = rand();
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, -20 << FIXED_POINT_SHIFT,  30 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT);
		blobCharacteristics.colorId = 1;
		BlobObjectCreateEasy(&blobCharacteristics, blobShape,  20 << FIXED_POINT_SHIFT,  30 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT);
		blobCharacteristics.colorId = 5;
		blobCharacteristics.timer = rand();
		BlobObjectCreateEasy(&blobCharacteristics, blobShape, -20 << FIXED_POINT_SHIFT, -30 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT);
		blobCharacteristics.colorId = 3;
		blobCharacteristics.timer = rand();
		BlobObjectCreateEasy(&blobCharacteristics, blobShape,  20 << FIXED_POINT_SHIFT, -30 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT, 12 << FIXED_POINT_SHIFT);
		BlobShapeRelease(blobShape);

		// Initialize the gravity
		#if TARGET_IPHONE_SIMULATOR
			blobGravityForce = FIXED_POINT >> BLOB_GRAVITY_SHIFT;
			blobGravityAngle = -PI / 2;
		#else
			blobGravityForce = 0;
			blobGravityAngle = 0;
		#endif

		// Initialize the timer used to swap the units
		blobTimerSwapUnits = 0;

		// Setup the accelerometer
		[[UIAccelerometer sharedAccelerometer] setDelegate:self];
		[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / 30.0)];

		// Initialize the temperature sensor
		sensorIndex = 0;
		sensorCount = 0;
		sensorSum = 0.0;
		sensorUpdateTime = 0.0;
		displayExternalCelsius = 0;
		displayExternalFahrenheit = 0;

		// Initiliaze the location manager
		locationManager = [[CLLocationManager alloc] init];
		if(locationManager.headingAvailable)
		{
			locationManager.delegate = self;
			[locationManager startUpdatingHeading];
		}

		// Render the view once immediately
		[self render];
	}
	return self;
}

- (void)viewDidAppear:(BOOL)animated
{
	// Launch a timer to periodically refresh the screen
	renderTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 30.0) target:self selector:@selector(render) userInfo:nil repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
	// Cancel the timer
	[renderTimer invalidate];
}

- (void)render
{
	// Display the blobs
	BlobDisplay();

	// Render everything
	[(View*)self.view render];

	// Update the physics of the blobs
	BlobUpdate((blobGravityForce * COS(blobGravityAngle)) >> FIXED_POINT_SHIFT, -FIXED_POINT >> BLOB_GRAVITY_SHIFT);

	// Swap the units
	if(blobTimerSwapUnits < BLOB_TIMER_SWAP_UNITS)
	{
		++blobTimerSwapUnits;
	}
	else
	{
		blobTimerSwapUnits = 0;
		BlobTextureIdSet(blobTemperature, BlobTextureIdGet(blobTemperature) ^ 3);
	}
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
	signed long x = acceleration.x * FIXED_POINT;
	signed long y = acceleration.y * FIXED_POINT;
	blobGravityForce = MathNormFast(x, y) >> BLOB_GRAVITY_SHIFT;
	blobGravityAngle = MathAngleFast(x, y);
}

+ (double)convertToFahrenheitFromCelsius:(double)value
{
	return 1.8 * value + 32.0;
}

+ (double)convertToExternalFromCelsius:(double)value
{
	// Linear interpolation with the following settings:
	// - 24°C internal => 16°C external
	// - 40°C internal => 27°C external
	return 16.0 + (27.0 - 16.0) * (value - 24.0) / (40.0 - 24.0);
}

- (void)locationManager:(CLLocationManager*)manager didUpdateHeading:(CLHeading*)newHeading
{
	// Make sure the data aren't too fresh
	double const time = [NSDate timeIntervalSinceReferenceDate];
	if(time < sensorUpdateTime)
	{
		return;
	}
	sensorUpdateTime = time + SENSOR_UPDATE_PERIOD;
	
	// Get the temperature measured by the magnetometer
	double const temperature = ((HeadingPointer*)newHeading)->headingData->temperature;
	
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
	double const measureInternalCelsius = sensorSum / sensorCount;
	
	// Estimare the external (ambient) temperature
	double const measureExternalCelsius = [Controller convertToExternalFromCelsius:measureInternalCelsius];
	double const measureExternalFahrenheit = [Controller convertToFahrenheitFromCelsius:measureExternalCelsius];

	// Update the Celsius texture
	signed short displayExternal = lroundf(measureExternalCelsius * 10);
	if(displayExternal != displayExternalCelsius)
	{
		displayExternalCelsius = displayExternal;
		BlobLoadTexture(blobTextureLava.CGImage, 1, BLOB_TEXTURE_SIZE, [[NSString stringWithFormat:@"%0.1f°C", measureExternalCelsius] cStringUsingEncoding:NSMacOSRomanStringEncoding]);
	}

	// Update the Fahrenheit texture
	displayExternal = lroundf(measureExternalFahrenheit * 10);
	if(displayExternal != displayExternalCelsius)
	{
		displayExternalFahrenheit = displayExternal;
		BlobLoadTexture(blobTextureLava.CGImage, 2, BLOB_TEXTURE_SIZE, [[NSString stringWithFormat:@"%0.1f°F", measureExternalFahrenheit] cStringUsingEncoding:NSMacOSRomanStringEncoding]);
	}
}

- (void)dealloc
{
	// Finalize the location manager
	[locationManager release];

	// Finalize the blob engine
	BlobFinalize();

	// Release the view
	[self.view release];

	// Complete the deallocation of the object
	[super dealloc];
}

@end
