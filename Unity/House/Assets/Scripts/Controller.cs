/*
 * TODO:
 * - In EditMode.BuildDrag, do not allow to drop an object if it collides with another object (just put it back to
 *   its original location).
 * - In EditMode.BuildDrag, allow to rotate an object by tapping it (rotate by 45º every time the object is touched).
 * - Propose a totally different control scheme? (e.g. zoom gesture to better see an object, rotation gesture to rotate
 *   an object, scrolling by dragging the floor, etc.)
 */
using UnityEngine;
using System.Collections.Generic;

public class Controller : MonoBehaviour
{
	// Screen
	const float SCREEN_SHUTTER_DURATION = 1.0f;
	Texture2D screenShutterTexture;
	float screenShutterAlpha;

	// Camera
	const float CAMERA_POSITION_FILTER_COEFFICIENT = 0.05f;
	const float CAMERA_BUILD_ZOOM_FACTOR = 0.7f;
	const float CAMERA_DESTROY_MOVE_FACTOR = 0.2f;
	Vector3 cameraPositionDefault;

	// Physics
	const int DRAGGABLE_OBJECTS_LAYER = 8;
	const int DRAGGABLE_OBJECTS_MASK = 1 << DRAGGABLE_OBJECTS_LAYER;
	const int DRAGGABLE_WALLS_LAYER = 9;
	const int DRAGGABLE_WALLS_MASK = 1 << DRAGGABLE_WALLS_LAYER;
	const string DRAGGABLE_OBJECTS_TAG = "DRAGGABLE";
	const float DRAG_SPEED_MAX = 4.0f;
	const float DRAG_ACCELERATION_MAX = 400.0f;
	const float DRAG_FORCE_MAX = 1000.0f;
	const float DRAG_IMPULSE_DURATION_FACTOR = 0.5f;
	const float GRAVITY = 9.8f * 2;

	// Edition modes
	enum EditMode
	{
		BuildPullUnlocked = 0,
		BuildPullLocked,
		BuildDrag,
		Destroy
	};
	EditMode editModeCurrent;
	EditMode editModeNext;
	static readonly Rect editModeButtonRect = new Rect (0.0f, 0.0f, 120.0f, 32.0f);
	static readonly Rect buildModeButtonRect = new Rect (0.0f, 40.0f, 120.0f, 32.0f);
	static readonly string[] buildModeNames = {"PULL", "PULL [LOCKED]", "DRAG&DROP"};
	EditMode buildModePrevious;
	struct Position
	{
		public Vector3 translation;
		public Quaternion rotation;
	}
	Dictionary<GameObject, Position> objectPositions;

	// Input management
	const float MOUSE_POSITION_FILTER_COEFFICIENT = 0.5f;
	Vector3 mousePosition;
	Rigidbody touchRigidBody;
	Vector3 touchCurrent;
	Vector3 touchOriginLocal;
	Plane touchPlane;
	Vector3 touchCameraOffset;
	LineRenderer cord;

	/**
	 * Method called by Unity after that the GameObject has been instantiated.
	 * This is the place where we initialize everything.
	 */
	void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Setup the physics
		Physics.gravity = Vector3.down * GRAVITY;
		Physics.defaultContactOffset = 0.01f;

		// Create a cord to pull objects
		GameObject gameObject = new GameObject ("Cord");
		cord = gameObject.AddComponent<LineRenderer> ();
		cord.SetVertexCount (2);
		cord.material = new Material (Shader.Find ("Particles/Additive"));
		cord.SetWidth (0.05f, 0.05f);
		cord.enabled = false;

		// Create a dictionary to record the position of the objects
		objectPositions = new Dictionary<GameObject, Position> ();

		// Create a screen shutter
		screenShutterAlpha = 1.0f;
		screenShutterTexture = new Texture2D (1, 1);
		screenShutterTexture.SetPixel (0, 0, Color.black);
		screenShutterTexture.Apply ();

		// Take note of the position of the camera
		cameraPositionDefault = Camera.main.transform.localPosition;
	}

	/**
	 * Method called by Unity at every update step of the physics.
	 */
	void FixedUpdate ()
	{
		// Drag the object (if any)
		if (touchRigidBody) {

			// Compute the position of the point to pull
			Vector3 touchOrigin = touchRigidBody.transform.TransformPoint (touchOriginLocal);

			// Compute the speed
			Vector3 speed = (touchCurrent - touchOrigin) / Time.fixedDeltaTime;
			if (editModeCurrent == EditMode.BuildPullLocked || editModeCurrent == EditMode.BuildPullUnlocked) {
				float speedMagnitude = speed.magnitude;
				if (speedMagnitude > DRAG_SPEED_MAX) {
					speed *= DRAG_SPEED_MAX / speedMagnitude;
				}
			}

			// Compute the acceleration
			Vector3 acceleration = (speed - touchRigidBody.velocity) / Time.fixedDeltaTime;
			if (editModeCurrent == EditMode.BuildDrag) {

				// Limit the acceleration
				float accelerationMagnitude = acceleration.magnitude;
				if (accelerationMagnitude > DRAG_ACCELERATION_MAX) {
					acceleration *= DRAG_ACCELERATION_MAX / accelerationMagnitude;
				}

				// Apply a change of velocity
				touchRigidBody.AddForce (acceleration * Time.fixedDeltaTime * DRAG_IMPULSE_DURATION_FACTOR, ForceMode.VelocityChange);
			} else {

				// Compute the force
				Vector3 force = touchRigidBody.mass * acceleration;
				float forceMagnitude = force.magnitude;
				if (forceMagnitude > DRAG_FORCE_MAX) {
					force *= DRAG_FORCE_MAX / forceMagnitude;
				}

				// Apply an impulse
				if (editModeCurrent != EditMode.Destroy) {
					touchOrigin.y = touchRigidBody.worldCenterOfMass.y;
				}
				touchRigidBody.AddForceAtPosition (force * Time.fixedDeltaTime * DRAG_IMPULSE_DURATION_FACTOR, touchOrigin, ForceMode.Impulse);
			}
		}
	}

	/**
	 * Method called by Unity at every update step of the display.
	 */
	void Update ()
	{
		// Check whether we shall go back to the building mode
		if (editModeCurrent == EditMode.Destroy && editModeNext != EditMode.Destroy) {
			if (screenShutterAlpha < 1.0f) {

				// Fade out...
				screenShutterAlpha += Time.deltaTime / SCREEN_SHUTTER_DURATION;
			} else {

				// Restore the position of all the objects, and set back their constraints
				bool isKinematic = editModeNext == EditMode.BuildPullLocked;
				foreach (GameObject gameObject in GameObject.FindGameObjectsWithTag (DRAGGABLE_OBJECTS_TAG)) {
					Position position;
					if (objectPositions.TryGetValue (gameObject, out position)) {
						gameObject.transform.localPosition = position.translation;
						gameObject.transform.localRotation = position.rotation;
					}
					gameObject.GetComponent<Rigidbody>().constraints = RigidbodyConstraints.FreezeRotationX | RigidbodyConstraints.FreezeRotationZ;
					gameObject.GetComponent<Rigidbody>().isKinematic = isKinematic;
					if (!isKinematic) {
						gameObject.GetComponent<Rigidbody>().velocity = Vector3.zero;
						gameObject.GetComponent<Rigidbody>().angularVelocity = Vector3.zero;
					}
				}

				// Reset the objects collision status
				Physics.IgnoreLayerCollision (DRAGGABLE_OBJECTS_LAYER, DRAGGABLE_OBJECTS_LAYER, editModeNext == EditMode.BuildDrag);

				// Change the edition mode back to build
				editModeCurrent = editModeNext;
			}
		} else {
			if (screenShutterAlpha > 0.0f) {

				// Fade in...
				screenShutterAlpha -= Time.deltaTime / SCREEN_SHUTTER_DURATION;
			}
		}

		// Handle controls
		if (Input.GetMouseButtonDown (0)) {

			// Get the position of the mouse
			mousePosition = Input.mousePosition;

			// Check whether an object or a wall has just been touched
			Ray ray = Camera.main.ScreenPointToRay (mousePosition);
			RaycastHit raycastHit;
			if (Physics.Raycast (ray, out raycastHit, Mathf.Infinity, DRAGGABLE_OBJECTS_MASK | DRAGGABLE_WALLS_MASK)) {

				// Take note of some coordinates
				touchCurrent = raycastHit.point;
				touchPlane = new Plane (Vector3.up, touchCurrent);
				touchCameraOffset = touchCurrent;

				// Is that an object?
				touchRigidBody = raycastHit.rigidbody;
				if (touchRigidBody) {

					// Allow the object to be controlled
					touchRigidBody.isKinematic = false;

					// Take note of some more coordinates
					touchOriginLocal = touchRigidBody.transform.InverseTransformPoint (touchCurrent);
					touchCameraOffset -= (ray.direction * cameraPositionDefault.magnitude + touchRigidBody.transform.position) * CAMERA_BUILD_ZOOM_FACTOR;

					// Don't allow the object to rotate when in drag&drop mode
					if (editModeCurrent == EditMode.BuildDrag) {
						touchRigidBody.constraints |= RigidbodyConstraints.FreezeRotationY;
					}
				}
			}
		} else if (Input.GetMouseButton (0)) {

			// Apply a basic filter on the mouse position
			mousePosition = mousePosition * (1.0f - MOUSE_POSITION_FILTER_COEFFICIENT) + Input.mousePosition * MOUSE_POSITION_FILTER_COEFFICIENT;

			// Compute the corresponding position in 3D
			Ray ray = Camera.main.ScreenPointToRay (mousePosition);
			float distance;
			if (touchPlane.Raycast (ray, out distance)) {
				touchCurrent = ray.GetPoint (distance);

				// Check whether an object is being dragged
				if (touchRigidBody && editModeCurrent != EditMode.BuildDrag) {

					// Display the cord used to pull objects
					cord.SetPosition (0, touchRigidBody.transform.TransformPoint (touchOriginLocal));
					cord.SetPosition (1, touchCurrent);
					cord.enabled = true;
				}
			}
		} else if (Input.GetMouseButtonUp (0)) {

			// Check whether an object was touched
			if (touchRigidBody) {

				// Allow the object to rotate again
				touchRigidBody.constraints &= ~RigidbodyConstraints.FreezeRotationY;

				// Lock the object as needed
				touchRigidBody.isKinematic = editModeCurrent == EditMode.BuildPullLocked;
				if (editModeCurrent == EditMode.BuildDrag) {
					touchRigidBody.velocity = Vector3.zero;
				}

				// Reset the touch
				touchRigidBody = null;

				// Hide the cord used to pull objects
				cord.enabled = false;
			}
		}

		// Define the target position of the camera
		Vector3 cameraPositionTarget;
		if (editModeCurrent == EditMode.Destroy) {
			cameraPositionTarget = cameraPositionDefault + CAMERA_DESTROY_MOVE_FACTOR * new Vector3 (Mathf.Sin (Time.time * 7), Mathf.Sin (Time.time * 11), 0.0f);
		} else if (touchRigidBody) {
			cameraPositionTarget = touchCameraOffset + touchRigidBody.transform.position * CAMERA_BUILD_ZOOM_FACTOR;
		} else if (Input.GetMouseButton (0)) {
			cameraPositionTarget = Camera.main.transform.localPosition + (touchCameraOffset - touchCurrent) / CAMERA_POSITION_FILTER_COEFFICIENT;
		} else {
			cameraPositionTarget = cameraPositionDefault;
		}

		// Apply a basic filter to move the camera to its target position
		Camera.main.transform.localPosition = Camera.main.transform.localPosition * (1.0f - CAMERA_POSITION_FILTER_COEFFICIENT) + cameraPositionTarget * CAMERA_POSITION_FILTER_COEFFICIENT;
	}

	/**
	 * Method called by Unity to refresh the GUI.
	 */
	void OnGUI ()
	{
		// Display a button to toggle the edition mode
		if (editModeCurrent != EditMode.Destroy) {
			if (GUI.Button (editModeButtonRect, "DESTROY")) {

				// Record the position of all the objects, and remove their constraints
				objectPositions.Clear ();
				foreach (GameObject gameObject in GameObject.FindGameObjectsWithTag (DRAGGABLE_OBJECTS_TAG)) {
					Position position = new Position {translation = gameObject.transform.localPosition, rotation = gameObject.transform.localRotation};
					objectPositions.Add (gameObject, position);
					gameObject.GetComponent<Rigidbody>().constraints = RigidbodyConstraints.None;
					gameObject.GetComponent<Rigidbody>().isKinematic = false;
				}

				// Enable collisions between objects
				Physics.IgnoreLayerCollision (DRAGGABLE_OBJECTS_LAYER, DRAGGABLE_OBJECTS_LAYER, false);

				// We are now in the destroy mode
				buildModePrevious = editModeCurrent;
				editModeCurrent = editModeNext = EditMode.Destroy;
			} else {

				// Display a button to toggle the control mode
				if (GUI.Button (buildModeButtonRect, buildModeNames [(int)editModeCurrent])) {

					// Change the control mode
					editModeCurrent = editModeNext = (EditMode)(((int)editModeCurrent + 1) % (int)EditMode.Destroy);

					// Reset the objects collision status
					Physics.IgnoreLayerCollision (DRAGGABLE_OBJECTS_LAYER, DRAGGABLE_OBJECTS_LAYER, editModeCurrent == EditMode.BuildDrag);

					// Lock/unlock all the objects
					bool isKinematic = editModeCurrent == EditMode.BuildPullLocked;
					foreach (GameObject gameObject in GameObject.FindGameObjectsWithTag (DRAGGABLE_OBJECTS_TAG)) {
						gameObject.GetComponent<Rigidbody>().isKinematic = isKinematic;
					}
				}
			}
		} else {
			if (GUI.Button (editModeButtonRect, "BUILD")) {

				// Request to change to the building mode
				editModeNext = buildModePrevious;
			}
		}

		// Display the screen shutter
		if (screenShutterAlpha > 0.0f) {
			GUI.color = new Color (1, 1, 1, screenShutterAlpha);
			GUI.DrawTexture (new Rect (0, 0, Screen.width, Screen.height), screenShutterTexture);
		}
	}
}
