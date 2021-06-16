using UnityEngine;
using System.Collections.Generic;

public class ControllerSlice : MonoBehaviour
{
	// Screen
	const float SCREEN_SHUTTER_DURATION = 1.0f;
	public Material screenBackgroundMaterial;
	Texture2D screenShutterTexture;
	float screenShutterAlpha;

	// Physics
	const float PHYSICS_SCALE_FACTOR = 100.0f;
	const float GRAVITY = 9.8f * 100;
	const float GRAVITY_WAKE_UP_FACTOR = 0.4f;
	const float FRUIT_DENSITY = 0.001f;
	Vector3 gravityLastWakeUp;
	Vector3 deviceAcceleration;

	// Input management
	const float MOUSE_POSITION_FILTER_COEFFICIENT = 0.5f;
	const float DRAG_ACCELERATION_MAX = 50000.0f;
	const float DRAG_IMPULSE_DURATION_FACTOR = 0.5f;
	const float JITTER_FACTOR = 5.0f;
	Vector3 mousePosition;
	Rigidbody touchRigidBody;
	Vector3 touchTranslate;

	// Slicing
	const float SLICE_ACCELERATION = 200.0f;
	const float SLICE_LINE_ADD_LENGTH = 25.0f;
	public Material sliceLineMaterial;
	float sliceLineMaterialScaleFactor;
	LineRenderer sliceLineRenderer;
	float sliceLineExtend;

	// Game logic
	const float CONTAINER_THICKNESS = 50.0f;
	static readonly string[] FRUIT_NAMES = {"Apple", "Banana", "Strawberry"};
	const string FRUIT_TAG = "FRUIT";
	const int FRUIT_PIECES_MAX = 20;
	const int FRUIT_PIXEL_SIZE = 100;
	const int FRUIT_PIXEL_GAP = 30;
	GameObject container;
	int fruitPieceCount;

	/**
	 * Create a fruit.
	 *
	 * @param name Name of the sprite.
	 * @param position Position where the sprite shall be created.
	 */
	void CreateFruit (string name, Vector3 position)
	{
		GameObject sprite = Sprite.CreateOrModify (null, name, position / PHYSICS_SCALE_FACTOR, 0, Sprite.ColliderType.ContourCollider, FRUIT_DENSITY);
		sprite.transform.localScale = Vector3.one / PHYSICS_SCALE_FACTOR;
		sprite.GetComponent<Rigidbody>().angularDrag = 1.0f;
		sprite.tag = FRUIT_TAG;
	}

	/**
	 * Create a border.
	 *
	 * @param position Position of the border's center.
	 * @param size Size of the border.
	 */
	void CreateBorder (Vector3 position, Vector3 size)
	{
		GameObject border = new GameObject ("Border");
		border.transform.position = position;
		border.transform.parent = container.transform;

		BoxCollider boxCollider = border.AddComponent<BoxCollider> ();
		boxCollider.size = size;
	}

	/**
	 * Method called by Unity after that the GameObject has been instantiated.
	 * This is the place where we initialize everything.
	 */
	void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Setup the physics
		Time.fixedDeltaTime = 0.01f;
		Physics.defaultContactOffset = 0.5f / PHYSICS_SCALE_FACTOR;
		if (!SystemInfo.supportsAccelerometer) {
			Physics.gravity = Vector3.down * GRAVITY / PHYSICS_SCALE_FACTOR;
		}

		// Setup the display
		float width = Screen.width;
		float height = Screen.height;
		float zoom = Mathf.Min (width / (FRUIT_PIXEL_SIZE * 2 + FRUIT_PIXEL_GAP * 3), height / (FRUIT_PIXEL_SIZE + FRUIT_PIXEL_GAP * 2));
		width /= zoom;
		height /= zoom;
		GetComponent<Camera>().orthographicSize = height * 0.5f / PHYSICS_SCALE_FACTOR;

		// Create the background
		Sprite.CreateOrModify (null, screenBackgroundMaterial, Camera.main.transform.position + Vector3.forward * Camera.main.far, new Vector2 (Screen.width, Screen.height)).transform.localScale = Vector3.one / (zoom * PHYSICS_SCALE_FACTOR);

		// Create a screen shutter
		screenShutterAlpha = 1.0f;
		screenShutterTexture = new Texture2D (1, 1);
		screenShutterTexture.SetPixel (0, 0, Color.black);
		screenShutterTexture.Apply ();

		// Create a big container
		container = new GameObject ("Container");
		CreateBorder (new Vector3 (-(width + CONTAINER_THICKNESS) * 0.5f, 0, 0.0f), new Vector3 (CONTAINER_THICKNESS, height + 2 * CONTAINER_THICKNESS, CONTAINER_THICKNESS));
		CreateBorder (new Vector3 ((width + CONTAINER_THICKNESS) * 0.5f, 0, 0.0f), new Vector3 (CONTAINER_THICKNESS, height + 2 * CONTAINER_THICKNESS, CONTAINER_THICKNESS));
		CreateBorder (new Vector3 (0, -(height + CONTAINER_THICKNESS) * 0.5f, 0.0f), new Vector3 (width + 2 * CONTAINER_THICKNESS, CONTAINER_THICKNESS, CONTAINER_THICKNESS));
		CreateBorder (new Vector3 (0, (height + CONTAINER_THICKNESS) * 0.5f, 0.0f), new Vector3 (width + 2 * CONTAINER_THICKNESS, CONTAINER_THICKNESS, CONTAINER_THICKNESS));
		container.transform.localScale = Vector3.one / PHYSICS_SCALE_FACTOR;
		container.AddComponent<Rigidbody> ().isKinematic = true;

		// Create a line renderer to display the slice line
		// Note: make a copy of the material (so that we can modify it freely without affecting the original one)
		GameObject sliceLineRendererObject = new GameObject ("LineRenderer");
		sliceLineRendererObject.transform.position = Vector3.forward * Camera.main.near;

		sliceLineRenderer = sliceLineRendererObject.AddComponent<LineRenderer> ();
		sliceLineRenderer.enabled = false;
		sliceLineRenderer.useWorldSpace = false;
		sliceLineRenderer.SetVertexCount (2);

		sliceLineMaterial = (Material)Instantiate (sliceLineMaterial);
		sliceLineRenderer.material = sliceLineMaterial;
		sliceLineMaterialScaleFactor = sliceLineMaterial.mainTexture.height / (zoom * PHYSICS_SCALE_FACTOR);
		sliceLineRenderer.SetWidth (sliceLineMaterialScaleFactor, sliceLineMaterialScaleFactor);
		sliceLineMaterialScaleFactor = sliceLineMaterial.mainTexture.width / (zoom * PHYSICS_SCALE_FACTOR);
		sliceLineExtend = SLICE_LINE_ADD_LENGTH / (zoom * PHYSICS_SCALE_FACTOR);
	}

	/**
	 * Method called by Unity at every update step of the physics.
	 */
	void FixedUpdate ()
	{
		// Drag the object (if any)
		if (touchRigidBody) {

			// Compute the current and expected position of the point to drag
			Vector3 position = Camera.main.ScreenToWorldPoint (mousePosition);
			Vector3 touchPosition = touchRigidBody.transform.TransformPoint (touchTranslate);

			// Compute the speed
			Vector3 speed = (position - touchPosition) / Time.fixedDeltaTime;

			// Compute the acceleration
			Vector3 acceleration = (speed - touchRigidBody.velocity) / Time.fixedDeltaTime;
			float accelerationMagnitude = acceleration.magnitude;
			if (accelerationMagnitude > DRAG_ACCELERATION_MAX / PHYSICS_SCALE_FACTOR) {
				acceleration *= (DRAG_ACCELERATION_MAX / PHYSICS_SCALE_FACTOR) / accelerationMagnitude;
			}

			// Apply an impulse
			touchPosition.z = touchRigidBody.worldCenterOfMass.z;
			touchRigidBody.AddForceAtPosition (acceleration * touchRigidBody.mass * Time.fixedDeltaTime * DRAG_IMPULSE_DURATION_FACTOR, touchPosition, ForceMode.Impulse);
		}
	}

	/**
	 * Method called by Unity at every update step of the display.
	 */
	void Update ()
	{
		// Check whether there is no fruit or too many fruit pieces have been created
		if (fruitPieceCount == 0 || fruitPieceCount > FRUIT_PIECES_MAX) {
			if (screenShutterAlpha < 1.0f) {

				// Fade out...
				screenShutterAlpha += Time.deltaTime / SCREEN_SHUTTER_DURATION;
			} else {

				// Destroy all the existing fruit pieces
				foreach (GameObject gameObject in GameObject.FindGameObjectsWithTag (FRUIT_TAG)) {
					Destroy (gameObject);
				}

				// Create 2 new fruits
				Vector3 position = new Vector3 ((FRUIT_PIXEL_SIZE + FRUIT_PIXEL_GAP) / 2, 0, 0);
				CreateFruit (FRUIT_NAMES [Random.Range (0, FRUIT_NAMES.Length)], position);
				CreateFruit (FRUIT_NAMES [Random.Range (0, FRUIT_NAMES.Length)], -position);
				fruitPieceCount = 2;
			}
		} else {
			if (screenShutterAlpha > 0.0f) {

				// Fade in...
				screenShutterAlpha -= Time.deltaTime / SCREEN_SHUTTER_DURATION;
			}
		}

		// Check whether the device has an accelerometer
		if (SystemInfo.supportsAccelerometer) {

			// Compute the actual change of acceleration
			Vector3 jitter = Input.acceleration - deviceAcceleration;
			deviceAcceleration = Input.acceleration;

			// Move the container
			if (jitter.sqrMagnitude < 1.0f) {
				container.GetComponent<Rigidbody>().MovePosition (Vector3.zero);
			} else {
				container.GetComponent<Rigidbody>().MovePosition (-jitter * JITTER_FACTOR / PHYSICS_SCALE_FACTOR);
			}

			// Set the gravity
			Vector3 deviceGravity = deviceAcceleration.normalized;
			Physics.gravity = new Vector3 (deviceGravity.x, -Mathf.Sqrt (1.0f - deviceGravity.x * deviceGravity.x), 0.0f) * GRAVITY / PHYSICS_SCALE_FACTOR;

			// If the gravity has varied a lot, then wake up all our sprites
			Vector3 gravityChange = Physics.gravity - gravityLastWakeUp;
			if (gravityChange.magnitude > GRAVITY_WAKE_UP_FACTOR * GRAVITY / PHYSICS_SCALE_FACTOR) {
				gravityLastWakeUp = Physics.gravity;
				foreach (GameObject gameObject in GameObject.FindGameObjectsWithTag (FRUIT_TAG)) {
					gameObject.GetComponent<Rigidbody>().WakeUp ();
				}
			}
		}

		// Handle controls
		if (Input.GetMouseButtonDown (0)) {

			// Get the position of the mouse
			mousePosition = Input.mousePosition;
			touchTranslate = Camera.main.ScreenToWorldPoint (mousePosition);

			// Check whether an object has just been touched
			Ray ray = Camera.main.ScreenPointToRay (mousePosition);
			RaycastHit hit;
			if (Physics.Raycast (ray, out hit, Mathf.Infinity)) {
				touchRigidBody = hit.collider.GetComponent<Rigidbody>();
				if (touchRigidBody) {
					touchTranslate = touchRigidBody.transform.InverseTransformPoint (touchTranslate);
				}
			}
		} else if (Input.GetMouseButton (0)) {

			// Apply a basic filter on the mouse position
			mousePosition = mousePosition * (1.0f - MOUSE_POSITION_FILTER_COEFFICIENT) + Input.mousePosition * MOUSE_POSITION_FILTER_COEFFICIENT;

			// Check whether an object is being dragged
			if (!touchRigidBody) {

				// Compute the extended length of the slice line
				Vector3 touchEnd = Camera.main.ScreenToWorldPoint (mousePosition);
				Vector3 direction = touchEnd - touchTranslate;
				float length = direction.magnitude;
				direction /= length;
				length += sliceLineExtend;
				touchEnd += direction * sliceLineExtend;

				// Display the slice line
				sliceLineRenderer.SetPosition (0, touchTranslate);
				sliceLineRenderer.SetPosition (1, touchEnd);
				sliceLineMaterial.mainTextureScale = new Vector2 (length / sliceLineMaterialScaleFactor, 1.0f);
				sliceLineRenderer.enabled = true;
			}
		} else if (Input.GetMouseButtonUp (0)) {
			if (touchRigidBody) {

				// Reset the touch
				touchRigidBody = null;
			} else {

				// Hide the line renderer
				sliceLineRenderer.enabled = false;

				// Slice the sprites
				Vector3 touchEnd = Camera.main.ScreenToWorldPoint (mousePosition);
				touchEnd += (touchEnd - touchTranslate).normalized * sliceLineExtend;
				fruitPieceCount += Sprite.Slice (touchTranslate, touchEnd, SLICE_ACCELERATION / PHYSICS_SCALE_FACTOR);
			}
		}
	}

	/**
	 * Method called by Unity to refresh the GUI.
	 */
	void OnGUI ()
	{
		// Display the screen shutter
		if (screenShutterAlpha > 0.0f) {
			GUI.color = new Color (1, 1, 1, screenShutterAlpha);
			GUI.DrawTexture (new Rect (0, 0, Screen.width, Screen.height), screenShutterTexture);
		}
	}
}
