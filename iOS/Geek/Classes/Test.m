#import "Test.h"
#import "Encode.h"

#define screenWidth  320.0f
#define screenHeight (480.0f - 44.0f)

#define sheetWidth        280.0f
#define sheetHeight       400.0f
#define sheetLeft         ((screenWidth - sheetWidth) / 2)
#define sheetRight        (sheetLeft + sheetWidth)
#define sheetTop          ((screenHeight - sheetHeight) / 2)
#define sheetBottom       (sheetTop + sheetHeight)
#define sheetCornerRadius 30.0f

#define sheetHoleRadius 10.0f
#define sheetHoleMargin 15.0f
#define sheetHoleLeft   (sheetLeft + sheetHoleMargin + sheetHoleRadius)
#define sheetHoleTop    (sheetTop + 1 * sheetHeight / 4)
#define sheetHoleBottom (sheetTop + 3 * sheetHeight / 4)

#define sheetLinesGap 20.0f

#define sheetTextMarginH 5.0f
#define sheetTextMarginV 30.0f
#define sheetTextLeft    (sheetHoleLeft + sheetHoleRadius + sheetTextMarginH)
#define sheetTextRight   (sheetRight - sheetTextMarginH)
#define sheetTextTop     (sheetTop + sheetTextMarginV)
#define sheetTextBottom  (sheetBottom - sheetTextMarginV)

#define sheetQuestionCount      8
#define sheetQuestionTop        sheetTextTop
#define sheetQuestionHeight     80.0f
#define sheetQuestionLabelLeft  sheetTextLeft
#define sheetQuestionLabelWidth 40.0f
#define sheetQuestionTextLeft   (sheetQuestionLabelLeft + sheetQuestionLabelWidth + sheetTextMarginH)
#define sheetQuestionTextWidth  (sheetTextRight - sheetQuestionTextLeft)

#define sheetAnswerLabelLeft   sheetTextLeft
#define sheetAnswerLabelWidth  25.0f
#define sheetAnswerButtonLeft  (sheetTextLeft + sheetAnswerLabelWidth)
#define sheetAnswerButtonWidth (sheetTextRight - sheetAnswerButtonLeft)
#define sheetAnswerHeight      36.0f
#define sheetAnswerGap         ((sheetTextBottom - sheetQuestionTop - sheetQuestionHeight - sheetAnswerHeight * answerCount) / (answerCount + 1))
#define sheetAnswerTop         (sheetQuestionTop + sheetQuestionHeight + sheetAnswerGap)

#define sheetValidationCenterX   ((sheetTextRight + sheetTextLeft) / 2)
#define sheetValidationCenterY   ((sheetAnswerTop + sheetTextBottom) / 2)
#define sheetValidationRadius    120.0f
#define sheetValidationThickness 40.0f

#define sheetTitleWidth  180.0f
#define sheetTitleHeight 60.0f
#define sheetTitleLeft   (sheetTextLeft + (sheetTextRight - sheetTextLeft - sheetTitleWidth) / 2)
#define sheetTitleTop    sheetTextTop

#define sheetButtonWidth  100.0f
#define sheetButtonHeight 20.0f
#define sheetButtonLeft   (sheetTextRight - sheetButtonWidth)
#define sheetButtonTop    (sheetTextBottom - sheetButtonHeight)

#define sheetHintsWidth  200.0f
#define sheetHintsHeight 18.0f
#define sheetHintsLeft   sheetLeft
#define sheetHintsTop    (sheetBottom - sheetHintsHeight)

#define sheetStatisticsWidth  160.0f
#define sheetStatisticsHeight 100.0f
#define sheetStatisticsLeft   (sheetLeft + (sheetWidth - sheetStatisticsWidth) / 2)
#define sheetStatisticsTop    (sheetTop + sheetHeight / 2)
#define sheetStatisticsAngle  (-M_PI / 12)

#define sheetResultsQuestionWidth 110.0f
#define sheetResultsQuestionLeft  (sheetTextLeft + sheetLinesGap)
#define sheetResultsAnswerWidth   60.0f
#define sheetResultsAnswerLeft    (sheetTextRight - sheetLinesGap - sheetResultsAnswerWidth)
#define sheetResultsTop           (sheetTop + 6 * sheetLinesGap)

#define sheetScoreAngle (-M_PI / 12)

@implementation Test

static NSString *const sheetScore[] = {@"N/A", @"A+", @"B-", @"F"};

- (NSString*)helpText
{
	switch(sheetState)
	{
		case FRONT_PAGE:
			return @"Tap the START label to start testing your Nerd skills!";
		case LAST_PAGE:
			return @"Tap the DONE label to close this summary.";
		default:
			return @"Just read the question then tap the answer that you think is correct, you will eventually know whether you're a healthy Nerd!";
	}
}

- (NSString*)infoText
{
	return @"Because Geeks who love computers (aka \"Nerds\") sometimes need to check their abilities, Geek System proposes them a nice test book!";
}

+ (NSString*)menuName
{
	return @"Nerd Test";
}

+ (BarContent)barContent
{
	return BAR_NOTHING;
}

+ (NSInteger)questionCountForTestCount:(NSInteger)testCount
{
	if(testCount <= 0)
	{
		return 0;
	}
	return testCount * sheetQuestionCount;
}

+ (NSInteger)scoreIndexForCorrectAnswerCount:(NSInteger)correctAnswerCount inTestCount:(NSInteger)testCount
{
	if(testCount <= 0)
	{
		return 0;
	}
	if(correctAnswerCount > testCount * (sheetQuestionCount - 1))
	{
		return 1;
	}
	if(correctAnswerCount > testCount * (sheetQuestionCount - 2))
	{
		return 2;
	}
	return 3;
}

+ (NSString*)scoreForCorrectAnswerCount:(NSInteger)correctAnswerCount inTestCount:(NSInteger)testCount
{
	return sheetScore[[Test scoreIndexForCorrectAnswerCount:correctAnswerCount inTestCount:testCount]];
}

- (void)questionPrime
{
	static unsigned short const primeNumbers[] = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401};
	static unsigned short const primeCount = sizeof(primeNumbers) / sizeof(unsigned short);

	unsigned short const fakeFactor1 = primeNumbers[rand() % (primeCount >> 2) + 3];
	unsigned short const fakeFactor2 = (rand() % (primeNumbers[primeCount - 1] / fakeFactor1 - 3) + 3) | 1;
	unsigned short const fake = fakeFactor1 * (fakeFactor2 != 5 ? fakeFactor2 : 3);

	unsigned short const primeIndex1 = rand() % primeCount;
	unsigned short const prime1 = primeNumbers[primeIndex1];

	unsigned short const primeIndex2 = rand() % (primeCount - 1);
	unsigned short const prime2 = primeNumbers[primeIndex2 < primeIndex1 ? primeIndex2 : primeIndex2 + 1];

	questionText.text = @"Which of the following numbers isn't a prime number?";
	[answer[0] setTitle:[NSString stringWithFormat:@"%d", fake] forState:UIControlStateNormal];
	[answer[1] setTitle:[NSString stringWithFormat:@"%d", prime1] forState:UIControlStateNormal];
	[answer[2] setTitle:[NSString stringWithFormat:@"%d", prime2] forState:UIControlStateNormal];
}

- (void)questionTaxicab
{
	questionText.text = @"What is the 2nd taxicab number \"Ta(2)\"?";
	[answer[0] setTitle:@"1729" forState:UIControlStateNormal];
	[answer[1] setTitle:@"91" forState:UIControlStateNormal];
	[answer[2] setTitle:@"1927" forState:UIControlStateNormal];
}

- (void)questionHyperbolic
{
	static NSString* const namesFull[] = {@"sine", @"cosine", @"tangent"};
	static NSString* const namesShort[] = {@"sinh", @"cosh", @"tanh"};
	static NSString* const expressions[] = {@"(exp(x) - exp(-x)) / 2", @"(exp(x) + exp(-x)) / 2", @"exp(2x - 1) / exp(2x + 1)"};

	unsigned char const functionOk = rand() % 3;
	unsigned char functionBad1 = (functionOk + 1) % 3;
	unsigned char functionBad2 = (functionOk + 2) % 3;

	questionText.text = [NSString stringWithFormat:@"What is the hyperbolic %@ function \"%@(x)\"?", namesFull[functionOk], namesShort[functionOk]];
	[answer[0] setTitle:expressions[functionOk] forState:UIControlStateNormal];
	[answer[1] setTitle:expressions[functionBad1] forState:UIControlStateNormal];
	[answer[2] setTitle:expressions[functionBad2] forState:UIControlStateNormal];
}

- (void)questionSqrtPower2
{
	unsigned short const powerOk = rand() % 9 + 2;
	unsigned short const powerBad1 = rand() & 1 ? powerOk + 1 : powerOk - 1;
	unsigned short const powerBad2 = rand() & 1 ? (powerOk > powerBad1 ? powerOk : powerBad1) + 1 : (powerOk < powerBad1 ? powerOk : powerBad1) - 1;

	questionText.text = [NSString stringWithFormat:@"What is the square root of %d?", 1 << (powerOk << 1)];
	[answer[0] setTitle:[NSString stringWithFormat:@"1 << %d", powerOk] forState:UIControlStateNormal];
	[answer[1] setTitle:[NSString stringWithFormat:@"1 << %d", powerBad1] forState:UIControlStateNormal];
	[answer[2] setTitle:[NSString stringWithFormat:@"1 << %d", powerBad2] forState:UIControlStateNormal];
}

- (void)questionTrigonometric
{
	static NSString* const expressions[][2] =
	{
		{@"sin(x)", @"cos(PI / 2 - x)"},
		{@"sin(-x)", @"cos(PI / 2 + x)"},
		{@"cos(x)", @"sin(PI / 2 - x)"},
		{@"-cos(x)", @"cos(PI + x)"},
		{@"sin(2 * x)", @"2 * sin(x) * cos(x)"},
		{@"cos(2 * x)", @"cos(x) ^ 2 - sin(x) ^ 2"},
	};
	static unsigned char const expressionCount = sizeof(expressions) / sizeof(*expressions);

	unsigned char const expressionOk = rand() % expressionCount;
	unsigned char expressionBad1 = rand() % (expressionCount - 1);
	unsigned char expressionBad2 = rand() % (expressionCount - 2);
	if(expressionBad1 >= expressionOk)
	{
		++expressionBad1;
		if(expressionBad2 >= expressionOk)
		{
			++expressionBad2;
		}
		if(expressionBad2 >= expressionBad1)
		{
			++expressionBad2;
		}
	}
	else
	{
		if(expressionBad2 >= expressionBad1)
		{
			++expressionBad2;
		}
		if(expressionBad2 >= expressionOk)
		{
			++expressionBad2;
		}
	}

	questionText.text = [NSString stringWithFormat:@"Which statement is equivalent to\n\"%@\"?", expressions[expressionOk][0]];
	[answer[0] setTitle:expressions[expressionOk][1] forState:UIControlStateNormal];
	[answer[1] setTitle:expressions[expressionBad1][1] forState:UIControlStateNormal];
	[answer[2] setTitle:expressions[expressionBad2][1] forState:UIControlStateNormal];
}

- (void)questionAscii
{
	unsigned short const error = rand() % 10 + 1;
	unsigned char const asciiOk = rand() % ('Z' - 'A' + 1) + 'A';
	unsigned short const asciiBad1 = rand() & 1 ? asciiOk + error : asciiOk - error;
	unsigned short const asciiBad2 = rand() & 1 ? (asciiOk > asciiBad1 ? asciiOk : asciiBad1) + error : (asciiOk < asciiBad1 ? asciiOk : asciiBad1) - error;

	questionText.text = [NSString stringWithFormat:@"What is the ASCII code of \'%c\'?", asciiOk];
	[answer[0] setTitle:[NSString stringWithFormat:@"%d", asciiOk] forState:UIControlStateNormal];
	[answer[1] setTitle:[NSString stringWithFormat:@"%d", asciiBad1] forState:UIControlStateNormal];
	[answer[2] setTitle:[NSString stringWithFormat:@"%d", asciiBad2] forState:UIControlStateNormal];
}

- (void)questionPi
{
	static double const PI = 3.141592653589;

	double const error = (double)(rand() % 5 + 1) / (pow(10, rand() % 8 + 3));
	double const numberBad1 = rand() & 1 ? PI + error : PI - error;
	double const numberBad2 = rand() & 1 ? (PI > numberBad1 ? PI : numberBad1) + error : (PI < numberBad1 ? PI : numberBad1) - error;

	questionText.text = @"What is the value the closest to PI?";
	[answer[0] setTitle:[NSString stringWithFormat:@"%.12f", PI] forState:UIControlStateNormal];
	[answer[1] setTitle:[NSString stringWithFormat:@"%.12f", numberBad1] forState:UIControlStateNormal];
	[answer[2] setTitle:[NSString stringWithFormat:@"%.12f", numberBad2] forState:UIControlStateNormal];
}

- (void)questionRGB
{
	static struct
	{
		unsigned int code;
		NSString* name;
	}
	const colors[] =
	{
		{0x000000, @"BLACK"},
		{0xFFFFFF, @"WHITE"},
		{0x808080, @"GRAY"},
		{0xFF0000, @"RED"},
		{0x00FF00, @"LIME"},
		{0xFFFF00, @"YELLOW"},
		{0xFF00FF, @"FUCHSIA"},
		{0x0000FF, @"BLUE"},
		{0x00FFFF, @"AQUA"},
	};
	static unsigned char const colorCount = sizeof(colors) / sizeof(*colors);

	unsigned char const colorOk = rand() % colorCount;
	unsigned char colorBad1 = rand() % (colorCount - 1);
	unsigned char colorBad2 = rand() % (colorCount - 2);
	if(colorBad1 >= colorOk)
	{
		++colorBad1;
		if(colorBad2 >= colorOk)
		{
			++colorBad2;
		}
		if(colorBad2 >= colorBad1)
		{
			++colorBad2;
		}
	}
	else
	{
		if(colorBad2 >= colorBad1)
		{
			++colorBad2;
		}
		if(colorBad2 >= colorOk)
		{
			++colorBad2;
		}
	}

	questionText.text = [NSString stringWithFormat:@"Which color corresponds to the RGB code 0x%06X?", colors[colorOk].code];
	[answer[0] setTitle:colors[colorOk].name forState:UIControlStateNormal];
	[answer[1] setTitle:colors[colorBad1].name forState:UIControlStateNormal];
	[answer[2] setTitle:colors[colorBad2].name forState:UIControlStateNormal];
}

- (void)questionHexadecimal
{
	unsigned short const error = (rand() & 31) + 1;
	unsigned short const numberOk = rand() % (256 - 2 * error) + 2 * error;
	unsigned short const numberBad1 = rand() & 1 ? numberOk + error : numberOk - error;
	unsigned short const numberBad2 = rand() & 1 ? (numberOk > numberBad1 ? numberOk : numberBad1) + error : (numberOk < numberBad1 ? numberOk : numberBad1) - error;

	questionText.text = [NSString stringWithFormat:@"What is the hexadecimal representation of %d?", numberOk];
	[answer[0] setTitle:[NSString stringWithFormat:@"0x%X", numberOk] forState:UIControlStateNormal];
	[answer[1] setTitle:[NSString stringWithFormat:@"0x%X", numberBad1] forState:UIControlStateNormal];
	[answer[2] setTitle:[NSString stringWithFormat:@"0x%X", numberBad2] forState:UIControlStateNormal];
}

- (void)questionMultiple
{
	static unsigned short const multiples[] = {3, 7, 9, 11, 13};
	static unsigned short const multipleCount = sizeof(multiples) / sizeof(unsigned short);

	unsigned short const multiple = multiples[rand() % multipleCount];
	unsigned short const error = rand() % ((multiple - 1) / 2) + 1;
	unsigned short const numberOk = multiple * (20 + rand() % 1000);
	unsigned short const numberBad1 = rand() & 1 ? numberOk + error : numberOk - error;
	unsigned short const numberBad2 = rand() & 1 ? (numberOk > numberBad1 ? numberOk : numberBad1) + error : (numberOk < numberBad1 ? numberOk : numberBad1) - error;

	questionText.text = [NSString stringWithFormat:@"Which number is a multiple of %d?", multiple];
	[answer[0] setTitle:[NSString stringWithFormat:@"%d", numberOk] forState:UIControlStateNormal];
	[answer[1] setTitle:[NSString stringWithFormat:@"%d", numberBad1] forState:UIControlStateNormal];
	[answer[2] setTitle:[NSString stringWithFormat:@"%d", numberBad2] forState:UIControlStateNormal];
}

- (void)questionEncode
{
	static NSString* const words[] = {@"BASIC", @"BYTES", @"GAMES", @"PRINT", @"PIXEL", @"GEEKS", @"ASCII", @"ERROR"};
	static unsigned char const wordCount = sizeof(words) / sizeof(NSString*);

	unsigned char const wordOk = rand() % wordCount;
	unsigned char wordBad1 = rand() % (wordCount - 1);
	unsigned char wordBad2 = rand() % (wordCount - 2);
	if(wordBad1 >= wordOk)
	{
		++wordBad1;
		if(wordBad2 >= wordOk)
		{
			++wordBad2;
		}
		if(wordBad2 >= wordBad1)
		{
			++wordBad2;
		}
	}
	else
	{
		if(wordBad2 >= wordBad1)
		{
			++wordBad2;
		}
		if(wordBad2 >= wordOk)
		{
			++wordBad2;
		}
	}

	if(rand() & 1)
	{
		questionText.text = [NSString stringWithFormat:@"Which ASCII string corresponds to rot13(\"%@\")?", [Encode rot13EncodeString:words[wordOk]]];
	}
	else
	{
		questionText.text = [NSString stringWithFormat:@"Which ASCII string gives \"%@\" when base64 encoded?", [Encode base64EncodeString:words[wordOk]]];
	}
	[answer[0] setTitle:words[wordOk] forState:UIControlStateNormal];
	[answer[1] setTitle:words[wordBad1] forState:UIControlStateNormal];
	[answer[2] setTitle:words[wordBad2] forState:UIControlStateNormal];
}

- (void)questionUltimate
{
	static NSString* const badAnswers[] = {@"1729", @"UNIX", @"-1", @"PI", @"R2-D2", @"Sarah Connor", @"Abracadabra", @"1.618033989...", @"Nrx"};
	static unsigned char const badAnswerCount = sizeof(badAnswers) / sizeof(NSString*);

	unsigned char const badAnswer1 = rand() % badAnswerCount;
	unsigned char badAnswer2 = rand() % (badAnswerCount - 1);
	if(badAnswer2 >= badAnswer1)
	{
		++badAnswer2;
	}

	questionText.text = @"What is the answer to the Ultimate Question of Life, the Universe, and Everything?";
	[answer[0] setTitle:@"42" forState:UIControlStateNormal];
	[answer[1] setTitle:badAnswers[badAnswer1] forState:UIControlStateNormal];
	[answer[2] setTitle:badAnswers[badAnswer2] forState:UIControlStateNormal];
}

- (void)questioPhotoBubble
{
	questionText.text = @"Which great App should all Geeks purchase?";
	[answer[0] setTitle:@"Photo Bubble" forState:UIControlStateNormal];
	[answer[1] setTitle:@"@&#%$£!#" forState:UIControlStateNormal];
	[answer[2] setTitle:@"%§!!@€#$" forState:UIControlStateNormal];
}

- (void)sheetHintsOpen
{
	// Open the web browser
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://hknrx.free.fr/geekSystem/hints.htm"]];
}

- (void)sheetFrontPrepare
{
	// Set the state of the sheet
	sheetState = FRONT_PAGE;

	// Create the front page label
	UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(sheetTitleLeft, sheetTitleTop, sheetTitleWidth, sheetTitleHeight)];
	label.backgroundColor = [UIColor colorWithRed:1.0f green:0.8f blue:0.8f alpha:0.8f];
	label.text = @"NERD TEST";
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor redColor];
	label.font = [UIFont fontWithName:@"Courier-Bold" size:28.0f];
	[self addSubview:label];
	[label release];

	// Create the START button
	UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setFrame:CGRectMake(sheetButtonLeft, sheetButtonTop, sheetButtonWidth, sheetButtonHeight)];
	[button setTitle:@"START ➔" forState:UIControlStateNormal];
	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
	[button addTarget:self action:@selector(sheetStart:) forControlEvents:UIControlEventTouchDown];
	[self addSubview:button];

	// Create the hints button
	button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setFrame:CGRectMake(sheetHintsLeft, sheetHintsTop, sheetHintsWidth, sheetHintsHeight)];
	[button setTitle:@"hints: http://hknrx.free.fr" forState:UIControlStateNormal];
	[button setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	button.titleLabel.font = [UIFont fontWithName:@"Courier" size:12.0f];
	[button addTarget:self action:@selector(sheetHintsOpen) forControlEvents:UIControlEventTouchDown];
	[self addSubview:button];

	// Get the statistics
	NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
	NSInteger const testNumber = [userDefaults integerForKey:@"TEST_NUMBER"];
	NSInteger const testCorrect = [userDefaults integerForKey:@"TEST_CORRECT"];
	NSInteger const testLast = [userDefaults integerForKey:@"TEST_LAST"];
	NSInteger const testAverage = [Test scoreIndexForCorrectAnswerCount:testCorrect inTestCount:testNumber];

	// Create the statistics sticker
	label = [[UILabel alloc] initWithFrame:CGRectMake(sheetStatisticsLeft, sheetStatisticsTop, sheetStatisticsWidth, sheetStatisticsHeight)];
	label.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:0.6f alpha:0.8f];
	label.text = [NSString stringWithFormat:@" Test #%d\n\n Last score: %@\n Average score: %@", testNumber + 1, sheetScore[testLast], sheetScore[testAverage]];
	label.numberOfLines = 0;
	label.font = [UIFont fontWithName:@"Arial-BoldMT" size:16.0f];
	label.transform = CGAffineTransformMakeRotation(sheetStatisticsAngle);
	[self addSubview:label];
	[label release];
}

- (void)sheetQuestionPrepareLayout
{
	// Reset the question number and the answer state
	questionNumber = 0;
	answerState = 0;

	// Create the question label
	questionLabel = [[UILabel alloc] initWithFrame:CGRectMake(sheetQuestionLabelLeft, sheetQuestionTop, sheetQuestionLabelWidth, sheetQuestionHeight)];
	questionLabel.backgroundColor = [UIColor colorWithRed:1.0f green:0.8f blue:0.8f alpha:0.8f];
	questionLabel.textAlignment = UITextAlignmentCenter;
	questionLabel.textColor = [UIColor redColor];
	questionLabel.font = [UIFont fontWithName:@"Courier-Bold" size:28.0f];
	[self addSubview:questionLabel];
	[questionLabel release];

	// Create the question text
	questionText = [[UILabel alloc] initWithFrame:CGRectMake(sheetQuestionTextLeft, sheetQuestionTop, sheetQuestionTextWidth, sheetQuestionHeight)];
	questionText.backgroundColor = [UIColor clearColor];
	questionText.font = [UIFont fontWithName:@"Courier-BoldOblique" size:14.0f];
	questionText.numberOfLines = 0;
	[self addSubview:questionText];
	[questionText release];

	// Create the answer labels and buttons
	CGRect labelFrame = CGRectMake(sheetAnswerLabelLeft, sheetAnswerTop, sheetAnswerLabelWidth, sheetAnswerHeight);
	CGRect buttonFrame = CGRectMake(sheetAnswerButtonLeft, sheetAnswerTop, sheetAnswerButtonWidth, sheetAnswerHeight);
	for(unsigned char answerIndex = 0; answerIndex < answerCount; ++answerIndex)
	{
		UILabel* label = [[UILabel alloc] initWithFrame:labelFrame];
		label.backgroundColor = [UIColor clearColor];
		label.text = @"➔";
		[self addSubview:label];
		[label release];
		labelFrame.origin.y += sheetAnswerHeight + sheetAnswerGap;

		UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
		[button setFrame:buttonFrame];
		[button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
		button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
		button.tag = answerIndex;
		[button addTarget:self action:@selector(sheetAnswer:) forControlEvents:UIControlEventTouchDown];
		[self addSubview:button];
		buttonFrame.origin.y += sheetAnswerHeight + sheetAnswerGap;
		answer[answerIndex] = button;
	}
}

- (void)sheetQuestionPrepareContent
{
	// Set the state of the sheet
	sheetState = QUESTION;

	// Set the question text
	static NSString* const questionNames[] =
	{
		@"questionPrime",
		@"questionTaxicab",
		@"questionHyperbolic",
		@"questionSqrtPower2",
		@"questionTrigonometric",
		@"questionAscii",
		@"questionPi",
		@"questionRGB",
		@"questionHexadecimal",
		@"questionMultiple",
		@"questionEncode",
		@"questionUltimate",
		@"questioPhotoBubble",
	};
	static unsigned short const questionCount = sizeof(questionNames) / sizeof(NSString*);
	static unsigned short const questionSelection[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}; // = list of numbers that do not divide "questionCount"
	static unsigned short const questionSelectionCount = sizeof(questionSelection) / sizeof(unsigned short);

	if(questionNumber)
	{
		questionIndex += questionIncrement;
		if(questionIndex >= questionCount)
		{
			questionIndex -= questionCount;
		}
	}
	else
	{
		questionIndex = rand() % questionCount;
		questionIncrement = questionSelection[rand() % questionSelectionCount];
	}
	++questionNumber;
	[self performSelector:NSSelectorFromString(questionNames[questionIndex])];

	// Set the question label
	questionLabel.text = [NSString stringWithFormat:@"Q%d", questionNumber];

	// Shuffle the answers
	answerCorrectNumber = rand() % answerCount;
	if(answerCorrectNumber)
	{
		NSString* answerSwapped = answer[0].currentTitle;
		[answer[0] setTitle:answer[answerCorrectNumber].currentTitle forState:UIControlStateNormal];
		[answer[answerCorrectNumber] setTitle:answerSwapped forState:UIControlStateNormal];
	}
}

- (void)sheetLastPrepare
{
	// Set the state of the sheet
	sheetState = LAST_PAGE;

	// Create the last page label
	UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(sheetTitleLeft, sheetTitleTop, sheetTitleWidth, sheetTitleHeight)];
	label.backgroundColor = [UIColor clearColor];
	label.text = @"RESULTS";
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor redColor];
	label.font = [UIFont fontWithName:@"Courier-Bold" size:28.0f];
	[self addSubview:label];
	[label release];

	// Create the DONE button
	UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setFrame:CGRectMake(sheetButtonLeft, sheetButtonTop, sheetButtonWidth, sheetButtonHeight)];
	[button setTitle:@"➔ DONE" forState:UIControlStateNormal];
	[button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
	[button addTarget:self action:@selector(sheetOk:) forControlEvents:UIControlEventTouchDown];
	[self addSubview:button];

	// Display the results
	CGRect questionFrame = CGRectMake(sheetResultsQuestionLeft, sheetResultsTop, sheetResultsQuestionWidth, sheetLinesGap);
	CGRect answerFrame = CGRectMake(sheetResultsAnswerLeft, sheetResultsTop, sheetResultsAnswerWidth, sheetLinesGap);
	NSInteger answerCorrect = 0;
	for(unsigned char answerIndex = 1; answerIndex <= sheetQuestionCount; ++answerIndex)
	{
		label = [[UILabel alloc] initWithFrame:questionFrame];
		label.backgroundColor = [UIColor clearColor];
		label.text = [NSString stringWithFormat:@"Question #%d:", answerIndex];
		label.font = [UIFont fontWithName:@"Courier-BoldOblique" size:14.0f];
		[self addSubview:label];
		[label release];
		questionFrame.origin.y += sheetLinesGap;

		label = [[UILabel alloc] initWithFrame:answerFrame];
		label.backgroundColor = [UIColor clearColor];
		if(answerState & (1 << answerIndex))
		{
			label.text = @"PASSED";
			label.textColor = [UIColor colorWithRed:0.0f green:0.5f blue:0.0f alpha:1.0f];
			++answerCorrect;
		}
		else
		{
			label.text = @"FAILED";
			label.textColor = [UIColor redColor];
		}
		label.textAlignment = UITextAlignmentRight;
		label.font = [UIFont fontWithName:@"Courier-BoldOblique" size:14.0f];
		[self addSubview:label];
		[label release];
		answerFrame.origin.y += sheetLinesGap;
	}

	// Display the score
	NSInteger testLast = [Test scoreIndexForCorrectAnswerCount:answerCorrect inTestCount:1];
	label = [[UILabel alloc] initWithFrame:CGRectMake(sheetTextLeft, sheetTextBottom - 60.0f, 90.0f, 60.0f)];
	label.backgroundColor = [UIColor clearColor];
	label.text = sheetScore[testLast];
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor redColor];
	label.font = [UIFont fontWithName:@"Arial-BoldMT" size:60.0f];
	label.transform = CGAffineTransformMakeRotation(sheetScoreAngle);
	[self addSubview:label];
	[label release];

	// Update the statistics
	NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
	NSInteger const testCorrect = [userDefaults integerForKey:@"TEST_CORRECT"] + answerCorrect;
	[userDefaults setInteger:testCorrect forKey:@"TEST_CORRECT"];
	[userDefaults setInteger:testLast forKey:@"TEST_LAST"];
}

- (void)sheetEnable
{
	// Enable the buttons
	self.userInteractionEnabled = YES;
}

- (void)sheetSwap
{
	// Check whether the test is completed
	if(questionNumber < sheetQuestionCount)
	{
		// Prepare the question
		[self sheetQuestionPrepareContent];
	}
	else
	{
		// Remove the test elements
		for(UIView* subView in [self subviews])
		{
			[subView removeFromSuperview];
		}

		// Prepare the last page
		[self sheetLastPrepare];
	}

	// Refresh the display (e.g. clear the answer mark)
	[self setNeedsDisplay];

	// Animate the sheet swapping
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self cache:YES];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(sheetEnable)];
	[UIView commitAnimations];
}

- (void)sheetStart:(UIButton*)sender
{
	// Disable the button
	self.userInteractionEnabled = NO;

	// Remove the front page elements
	for(UIView* subView in [self subviews])
	{
		[subView removeFromSuperview];
	}

	// Update the statistics
	NSUserDefaults const*const userDefaults = [NSUserDefaults standardUserDefaults];
	NSInteger const testNumber = [userDefaults integerForKey:@"TEST_NUMBER"] + 1;
	[userDefaults setInteger:testNumber forKey:@"TEST_NUMBER"];
	[userDefaults setInteger:3 forKey:@"TEST_LAST"];

	// Prepare the first question
	[self sheetQuestionPrepareLayout];
	[self sheetSwap];
}

- (void)sheetAnswer:(UIButton*)sender
{
	// Disable the buttons
	self.userInteractionEnabled = NO;

	// Check the answer
	if(sender.tag == answerCorrectNumber)
	{
		sheetState = ANSWER_OK;
		answerState |= 1 << questionNumber;
	}
	else
	{
		sheetState = ANSWER_ERROR;
	}

	// Refresh the display (e.g. set the answer mark)
	[self setNeedsDisplay];

	// Launch a timer to swap the sheet
	[NSTimer scheduledTimerWithTimeInterval:(0.3) target:self selector:@selector(sheetSwap) userInfo:nil repeats:NO];
}

- (void)sheetOk:(UIButton*)sender
{
	// Disable the button
	self.userInteractionEnabled = NO;

	// Remove the last page elements
	for(UIView* subView in [self subviews])
	{
		[subView removeFromSuperview];
	}

	// Prepare the front page
	[self sheetFrontPrepare];

	// Refresh the display
	[self setNeedsDisplay];

	// Animate the sheet swapping
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self cache:YES];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(sheetEnable)];
	[UIView commitAnimations];
}

- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		// Make sure the view is transparent
		self.backgroundColor = [UIColor clearColor];

		// Define the sheet
		sheetPath = CGPathCreateMutable();
		CGPathMoveToPoint(sheetPath, NULL, sheetLeft, sheetTop);
		CGPathAddArcToPoint(sheetPath, NULL, sheetRight, sheetTop, sheetRight, sheetBottom, sheetCornerRadius);
		CGPathAddArcToPoint(sheetPath, NULL, sheetRight, sheetBottom, sheetLeft, sheetBottom, sheetCornerRadius);
		CGPathAddLineToPoint(sheetPath, NULL, sheetLeft, sheetBottom);
		CGPathCloseSubpath(sheetPath);

		// Define the holes
		holesPath = CGPathCreateMutable();
		CGPathAddArc(holesPath, NULL, sheetHoleLeft, sheetHoleTop, sheetHoleRadius, 0.0f, 2 * M_PI, 0);
		CGPathAddArc(holesPath, NULL, sheetHoleLeft, sheetHoleBottom, sheetHoleRadius, 0.0f, 2 * M_PI, 0);

		// Define the lines
		linesPath = CGPathCreateMutable();
		for(float x = sheetLeft; x < sheetRight; x += sheetLinesGap)
		{
			CGPathMoveToPoint(linesPath, NULL, x, sheetTop);
			CGPathAddLineToPoint(linesPath, NULL, x, sheetBottom);
		}
		for(float y = sheetTop; y < sheetBottom; y += sheetLinesGap)
		{
			CGPathMoveToPoint(linesPath, NULL, sheetLeft, y);
			CGPathAddLineToPoint(linesPath, NULL, sheetRight, y);
		}

		// Define the "ok" mark
		okPath = CGPathCreateMutable();
		CGPathAddArc(okPath, NULL, sheetValidationCenterX, sheetValidationCenterY, sheetValidationRadius, 0.0f, 2 * M_PI, 0);
		CGPathAddArc(okPath, NULL, sheetValidationCenterX, sheetValidationCenterY, sheetValidationRadius - sheetValidationThickness, 0.0f, 2 * M_PI, 0);

		// Define the "error" mark
		errorPath = CGPathCreateMutable();
		CGAffineTransform errorTransform = {M_SQRT2 / 2, -M_SQRT2 / 2, M_SQRT2 / 2, M_SQRT2 / 2, sheetValidationCenterX, sheetValidationCenterY};
		CGRect const errorRect = {{-sheetValidationRadius, -sheetValidationThickness / 2}, {sheetValidationRadius * 2, sheetValidationThickness}};
		CGPathAddRect(errorPath, &errorTransform, errorRect);
		errorTransform.b = M_SQRT2 / 2;
		errorTransform.c = -M_SQRT2 / 2;
		CGPathAddRect(errorPath, &errorTransform, errorRect);

		// Prepare the front page
		[self sheetFrontPrepare];
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	// Get the context
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Check the state of the sheet
	if(sheetState == FRONT_PAGE)
	{
		// Display the front page
		CGContextSetRGBFillColor(context, 1.0f, 0.2f, 0.2f, 1.0f);
		CGContextAddPath(context, holesPath);
		CGContextAddPath(context, sheetPath);
		CGContextDrawPath(context, kCGPathEOFill);
		return;
	}

	// Display the sheet
	CGContextSaveGState(context);
	CGContextAddPath(context, holesPath);
	CGContextAddPath(context, sheetPath);
	CGContextEOClip(context);
	CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
	CGContextAddPath(context, sheetPath);
	CGContextFillPath(context);
	CGContextSetLineWidth(context, 1.0f);
	CGContextSetRGBStrokeColor(context, 0.8f, 0.8f, 1.0f, 1.0f);
	CGContextAddPath(context, linesPath);
	CGContextStrokePath(context);
	CGContextRestoreGState(context);

	// Check the state of the sheet
	if(sheetState == LAST_PAGE)
	{
		return;
	}

	// Display the frame around the question label
	CGContextAddRect(context, CGRectMake(sheetQuestionLabelLeft, sheetQuestionTop, sheetQuestionLabelWidth, sheetQuestionHeight));
	CGContextSetRGBStrokeColor(context, 1.0f, 0.0f, 0.0f, 1.0f);
	CGContextStrokePath(context);

	// Check the state of the sheet
	if(sheetState == ANSWER_OK)
	{
		CGContextAddPath(context, okPath);
		CGContextSetRGBFillColor(context, 0.0f, 1.0f, 0.0f, 0.5f);
		CGContextDrawPath(context, kCGPathEOFill);
	}
	else if(sheetState == ANSWER_ERROR)
	{
		CGContextAddPath(context, errorPath);
		CGContextSetRGBFillColor(context, 1.0f, 0.0f, 0.0f, 0.5f);
		CGContextDrawPath(context, kCGPathFill);
	}
}

- (void)dealloc
{
	// Release the paths
	CGPathRelease(errorPath);
	CGPathRelease(okPath);
	CGPathRelease(linesPath);
	CGPathRelease(holesPath);
	CGPathRelease(sheetPath);

	// Destroy everything else
	[super dealloc];
}

@end
