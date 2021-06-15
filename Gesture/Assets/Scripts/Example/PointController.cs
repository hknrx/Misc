#define DEBUG
using UnityEngine;

public class PointController : MonoBehaviour
{
	// Constants
	const float MAXIMUM_SCORE_SQUARED_ERROR = 0.3f;
	const float MAXIMUM_SCORE_ABS_ERROR = 0.4f;
	const int ESCAPE_GESTURE_INDEX = 0;
	const float ESCAPE_TIMER_DO = 1.0f;
	const float ESCAPE_TIMER_DISPLAY = 2.0f;

	// Classes
	class NamedClass : GestureRecognitonClass
	{
		public string name;
	}
	static readonly NamedClass[] namedClasses = new NamedClass [] {
		new NamedClass {name = "Escape", features = new float [] {1f, 0f, 0f, 0f, 0.5f, 0f, -1f, 0f, -0.5f, 0f, -1f, 0f, 0f}},
		new NamedClass {name = "Fire 1-2-3", features = new float [] {1.75f, -1.570796f, 1.570796f, 2.467401f, 0.5892857f, 0.2857143f, -1f, 0f, -0.1607143f, -0.7142857f, 0f, -1f, 0.9272952f}},
		new NamedClass {name = "Fire 4-5-6", features = new float [] {3f, -4.068888f, 4.068888f, 8.707862f, 0.5f, 0.375f, -1f, 0f, 0.5f, 0.375f, 0.6f, 0.8f, 0.9272952f}},
		new NamedClass {name = "Fire 7-8-9", features = new float [] {3.901388f, -6.871188f, 6.871188f, 16.56075f, 0.4711196f, 0.3461196f, -1f, 0f, -0.2788804f, -0.1538804f, -0.8320503f, -0.5547002f, 0.9272952f}},
		new NamedClass {name = "Fire 10-11-12", features = new float [] {4.651388f, -9.424778f, 9.424778f, 23.08157f, 0.4556211f, 0.3709316f, -1f, 0f, 0.4556211f, -0.1290684f, 1f, 0f, 0.9272952f}},
		new NamedClass {name = "Water 1-2-3", features = new float [] {2.07353f, -2.247765f, 3.611016f, 5.771661f, 0.5221376f, 0.3860117f, -0.8998141f, -0.4362735f, 0.4498662f, -0.3514514f, 0.9037378f, -0.4280863f, 0.6354291f}},
		new NamedClass {name = "Water 4-5-6", features = new float [] {3.162278f, -2.498091f, 7.494274f, 18.72138f, 0.375f, 0.5f, -0.9486833f, -0.3162278f, 0.375f, -0.5f, 0.9486833f, -0.3162278f, 0.9272952f}},
		new NamedClass {name = "Water 7-8-9", features = new float [] {4.162278f, -4.390638f, 9.386821f, 22.30312f, 0.2849051f, 0.5f, -0.9486833f, -0.3162278f, 0.2849051f, 0.5f, 0f, 1f, 0.9272952f}},
		new NamedClass {name = "Water 10-11-12", features = new float [] {4.912278f, -5.961435f, 10.95762f, 24.77052f, 0.2986607f, 0.4236607f, -0.9486833f, -0.3162278f, -0.4513393f, 0.4236607f, -1f, 0f, 0.9272952f}},
		new NamedClass {name = "Air 1-2-3", features = new float [] {2.136001f, 2.424051f, 2.424051f, 5.876025f, -0.375f, -0.5f, 0.3511235f, 0.9363292f, 0.375f, -0.5f, 0.3511235f, -0.9363292f, 0.9272952f}},
		new NamedClass {name = "Air 4-5-6", features = new float [] {2.886001f, 4.353618f, 4.353618f, 9.599254f, -0.375f, -0.3700624f, 0.3511235f, 0.9363292f, -0.375f, -0.3700624f, -1f, 0f, 0.9272952f}},
		new NamedClass {name = "Air 7-8-9", features = new float [] {3.787389f, 6.907208f, 6.907208f, 16.12008f, -0.375f, -0.3414879f, 0.3511235f, 0.9363292f, 0.375f, 0.1585121f, 0.8320503f, 0.5547002f, 0.9272952f}},
		new NamedClass {name = "Air 10-11-12", features = new float [] {4.537389f, 4.353619f, 9.460798f, 22.6409f, -0.375f, -0.3676889f, 0.3511235f, 0.9363292f, -0.375f, 0.1323111f, -1f, 0f, 0.9272952f}},
		new NamedClass {name = "Earth 1-2-3", features = new float [] {1.75f, 1.570796f, 1.570796f, 2.467401f, 0.5892857f, -0.2857143f, -1f, 0f, -0.1607143f, 0.7142857f, 0f, 1f, 0.9272952f}},
		new NamedClass {name = "Earth 4-5-6", features = new float [] {2.5f, 3.141593f, 3.141593f, 4.934803f, 0.525f, -0.5f, -1f, 0f, 0.525f, 0.5f, 1f, 0f, 0.9272952f}},
		new NamedClass {name = "Earth 7-8-9", features = new float [] {3.401388f, 5.695183f, 5.695183f, 11.45562f, 0.4852491f, -0.5662515f, -1f, 0f, -0.2647509f, -0.06625152f, -0.8320503f, -0.5547002f, 0.9272952f}},
		new NamedClass {name = "Earth 10-11-12", features = new float [] {4.151388f, 3.141593f, 8.248773f, 17.97645f, 0.4653312f, -0.5542824f, -1f, 0f, 0.4653312f, -0.05428237f, 1f, 0f, 0.9272952f}},
		new NamedClass {name = "Light 1-2-3", features = new float [] {1.75f, -1.570796f, 1.570796f, 2.467401f, -0.1607143f, 0.7142857f, 0f, -1f, 0.5892857f, -0.2857143f, 1f, 0f, 0.9272952f}},
		new NamedClass {name = "Light 4-5-6", features = new float [] {2.231102f, -4.30608f, 6.232559f, 4.22608f, -0.1721415f, 0.6864292f, 0.03331483f, -0.9994449f, -0.132459f, 0.1213499f, -0.9312428f, 0.3643994f, 1.053447f}},
		new NamedClass {name = "Light 7-8-9", features = new float [] {3.401388f, -1.570796f, 6.677977f, 15.50905f, -0.2647509f, 0.6765006f, 0f, -1f, 0.4852491f, 0.1765006f, 1f, 0f, 0.9272952f}},
		new NamedClass {name = "Light 10-11-12", features = new float [] {4.302775f, 0.9827938f, 9.231566f, 22.02987f, -0.287847f, 0.691898f, 0f, -1f, -0.287847f, -0.308102f, -0.8320503f, -0.5547002f, 0.9272952f}},
		new NamedClass {name = "Dark 1-2-3", features = new float [] {1.901388f, -2.158799f, 2.158799f, 4.660413f, -0.1777757f, 0.6185171f, 0f, -1f, 0.5722244f, 0.1185171f, 0.8320503f, 0.5547002f, 0.9272952f}},
		new NamedClass {name = "Dark 4-5-6", features = new float [] {2.456108f, -4.018606f, 5.697764f, 5.11403f, -0.1912099f, 0.536687f, 0.05872202f, -0.9982744f, -0.1196652f, 0.4269309f, -0.8050559f, 0.593199f, 1.022642f}},
		new NamedClass {name = "Dark 7-8-9", features = new float [] {3.552776f, -1.570796f, 6.677977f, 15.04477f, -0.2694487f, 0.3944488f, 0f, -1f, 0.4805513f, 0.3944488f, 1f, 0f, 0.9272952f}},
		new NamedClass {name = "Dark 10-11-12", features = new float [] {4.052775f, 1.192093E-07f, 8.248773f, 17.51217f, -0.3287354f, 0.3766277f, 0f, -1f, 0.4212646f, -0.1233723f, 0f, -1f, 0.9272952f}},
		new NamedClass {name = "None 1-2-3", features = new float [] {2.25f, -2.498091f, 2.498091f, 6.240461f, -0.5416667f, 0.5f, 0.6f, -0.8f, 0.2083333f, 0.5f, 0f, 1f, 0.9272952f}},
		new NamedClass {name = "None 4-5-6", features = new float [] {3.5f, -4.996183f, 4.996183f, 12.48092f, -0.4821429f, 0.5f, 0.6f, -0.8f, -0.4821429f, -0.5f, -0.6f, -0.8f, 0.9272952f}},
		new NamedClass {name = "None 7-8-9", features = new float [] {4.5f, -2.498091f, 7.494274f, 18.72138f, -0.375f, 0.5f, 0.6f, -0.8f, -0.375f, 0.5f, 0f, 1f, 0.9272952f}},
		new NamedClass {name = "None 10-11-12", features = new float [] {5.25f, -0.9272951f, 9.06507f, 21.18878f, -0.375f, 0.4285714f, 0.6f, -0.8f, 0.375f, 0.4285714f, 1f, 0f, 0.9272952f}},
	};

	// GUI (public instance variables to be set in the editor)
	public Rect resultBoxPosition;
	public GUIStyle resultBoxStyle;
	public Rect escapeBoxPosition;
	public GUIStyle escapeBoxStyle;

	// Touch events
	enum TouchState
	{
		nothing,
		begin,
		move,
		stationary,
		end,
		cancel
	};
	TouchState touchState;
	Vector2 touchPosition;

	// Gesture recognition
	GestureRecognition gestureRecognition;
	GestureRecognitionResults gestureRecognitionResult;
	string gestureRecognitionNameSquaredError;
	string gestureRecognitionNameAbsError;
	enum GestureEscapeState
	{
		idle,
		ready,
		escape
	};
	GestureEscapeState gestureEscapeState;
	float gestureEscapeTimer;

	/**
	 * Method called by Unity after that the GameObject has been instantiated.
	 * This is the place where we initialize everything.
	 */
	void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Generate the array "namedClasses" (uncomment the next line when needed)
//		NamedClassesGenerator.GenerateNamedClasses (); // Uncomment this to generate the array "namedClasses"

		// Initialize the gesture recognition library
		gestureRecognition = new GestureRecognition (namedClasses);
		gestureEscapeState = GestureEscapeState.idle;
	}

	/**
	 * Handle the touch events.
	 */
	void UpdateTouch ()
	{
#if UNITY_IPHONE || UNITY_ANDROID
		if (Input.touchCount == 0) {
			touchState = TouchState.nothing;
		} else {
			Touch touch = Input.GetTouch (0);
			touchPosition = touch.position;
			switch (touch.phase) {
			case TouchPhase.Began:
				touchState = TouchState.begin;
				break;
			case TouchPhase.Moved:
				touchState = TouchState.move;
				break;
			case TouchPhase.Stationary:
				touchState = TouchState.stationary;
				break;
			case TouchPhase.Ended:
				touchState = TouchState.end;
				break;
			case TouchPhase.Canceled:
				touchState = TouchState.cancel;
				break;
			}
		}
#else
		Vector2 touchPositionPrevious = touchPosition;
		touchPosition = Input.mousePosition;
		switch (touchState) {
		case TouchState.begin:
		case TouchState.move:
		case TouchState.stationary:
			if (touchPosition.x < 0 || touchPosition.x >= Screen.width || touchPosition.y < 0 || touchPosition.y >= Screen.height) {
				touchState = TouchState.cancel;
			} else if (Input.GetMouseButtonUp (0)) {
				touchState = TouchState.end;
			} else if (touchPosition == touchPositionPrevious) {
				touchState = TouchState.stationary;
			} else {
				touchState = TouchState.move;
			}
			break;
		default:
			if (Input.GetMouseButtonDown (0) && touchPosition.x >= 0 && touchPosition.x < Screen.width && touchPosition.y >= 0 && touchPosition.y < Screen.height) {
				touchState = TouchState.begin;
			} else {
				touchState = TouchState.nothing;
			}
			break;
		}
#endif
	}

	/**
	 * Method called by Unity at every frame.
	 */
	void Update ()
	{
		// Update the "escape" mechanism
		if (gestureEscapeState != GestureEscapeState.idle && Time.time > gestureEscapeTimer) {
			gestureEscapeState = GestureEscapeState.idle;
		}

		// Handle the user inputs
		UpdateTouch ();
		if (touchState == TouchState.begin || touchState == TouchState.move) {

			// Move the gesture point
			transform.position = Camera.main.ScreenToWorldPoint (new Vector3 (touchPosition.x, touchPosition.y, 1.0f));

			// Add the point to the gesture
			gestureRecognition.AddPoint (touchPosition);
		} else if (touchState == TouchState.end) {

			// Classify the gesture
			gestureRecognitionResult = gestureRecognition.Classify ();

#if DEBUG
			// Debug
			System.Text.StringBuilder debug = new System.Text.StringBuilder ();
			float [] features = gestureRecognition.GetLastFeatures ();
			if (features != null && features.Length > 0) {
				debug.Append ("features = new float [] {");
				int featureIndex = 0;
				while (featureIndex < features.Length - 1) {
					debug.Append (features [featureIndex++] + "f, ");
				}
				debug.Append (features [featureIndex] + "f}");
			}
			Debug.Log (debug);
#endif

			// Check the results of the classification
			gestureRecognitionNameSquaredError = (gestureRecognitionResult.squaredError.reference != null && gestureRecognitionResult.squaredError.score < MAXIMUM_SCORE_SQUARED_ERROR) ? ((NamedClass)gestureRecognitionResult.squaredError.reference).name : "UNKNOWN";
			gestureRecognitionNameAbsError = (gestureRecognitionResult.absError.reference != null && gestureRecognitionResult.absError.score < MAXIMUM_SCORE_ABS_ERROR) ? ((NamedClass)gestureRecognitionResult.absError.reference).name : "UNKNOWN";

			// Take special care of the "escape" gesture
			if (gestureRecognitionResult.squaredError.reference != namedClasses [ESCAPE_GESTURE_INDEX] && gestureRecognitionResult.absError.reference != namedClasses [ESCAPE_GESTURE_INDEX]) {
				gestureEscapeState = GestureEscapeState.idle;
			} else if (gestureEscapeState == GestureEscapeState.idle) {
				gestureEscapeState = GestureEscapeState.ready;
				gestureEscapeTimer = Time.time + ESCAPE_TIMER_DO;
			} else if (gestureEscapeState == GestureEscapeState.ready) {
				gestureEscapeState = GestureEscapeState.escape;
				gestureEscapeTimer = Time.time + ESCAPE_TIMER_DISPLAY;
			}
		} else if (touchState == TouchState.cancel) {

			// Reset the gesture
			gestureRecognition.Reset ();
		}
	}

	/**
	 * Method called by Unity to refresh the GUI.
	 */
	void OnGUI ()
	{
		// Display the results of the classification
		GUI.Label (resultBoxPosition, "Result 1: " + gestureRecognitionNameSquaredError + " (" + gestureRecognitionResult.squaredError.score + ")"
			+ "\nResult 2: " + gestureRecognitionNameAbsError + " (" + gestureRecognitionResult.absError.score + ")", resultBoxStyle);

		// Display the escape message
		if (gestureEscapeState == GestureEscapeState.escape) {
			GUI.Label (escapeBoxPosition, "ESCAPE!", escapeBoxStyle);
		}
	}
}
