using UnityEngine;
using System.Collections.Generic;

public class ControllerMix : MonoBehaviour
{
	// Screen
	const float CAMERA_MOVE_FACTOR = 0.1f;
	const float SCREEN_SHUTTER_DURATION = 1.0f;
	public Material screenBackgroundMaterial;
	Texture2D screenShutterTexture;
	float screenShutterAlpha;

	// Physics
	const float PHYSICS_SCALE_FACTOR = 100.0f;
	const float GRAVITY_NORMAL = 9.8f * 100;
	const float GRAVITY_MIX = 2.0f * 100;
	const float FRUIT_DENSITY = 0.001f;
	const float MIX_MOVEMENT = 10.0f;
	const float SLICE_ACCELERATION = 200.0f;

	// Game logic
	const float CONTAINER_THICKNESS = 50.0f;
	static readonly string[] FRUIT_NAMES = {"Apple", "Banana", "Strawberry"};
	const string FRUIT_TAG = "FRUIT";
	const int FRUIT_PIECES_MAX = 40;
	const int FRUIT_PIXEL_SIZE = 100;
	const int FRUIT_PIXEL_GAP = 5;
	GameObject container;
	int fruitPieceCount;
	bool mix;

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

		// Setup the display
		float width = Screen.width;
		float height = Screen.height;
		float zoom = Mathf.Min (height / (FRUIT_PIXEL_SIZE * 2 + FRUIT_PIXEL_GAP * 3), width / (FRUIT_PIXEL_SIZE + FRUIT_PIXEL_GAP * 2));
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

				// Switch-off the mixer
				mix = false;

				// Create 2 new fruits
				Vector3 position = new Vector3 (0, (FRUIT_PIXEL_SIZE + FRUIT_PIXEL_GAP), 0);
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

		// Handle the mixer
		if (mix) {

			// Set the gravity
			Physics.gravity = Vector3.down * GRAVITY_MIX / PHYSICS_SCALE_FACTOR;

			// Move the container
			container.GetComponent<Rigidbody>().MovePosition ((Vector3.left * Mathf.Cos (Time.frameCount) + Vector3.up * Random.value) * MIX_MOVEMENT / PHYSICS_SCALE_FACTOR);

			// Slice the fruits
			if ((Time.frameCount & 31) == 0) {
				fruitPieceCount += Sprite.Slice (new Vector2 (0, -100), new Vector2 (0, 100), SLICE_ACCELERATION / PHYSICS_SCALE_FACTOR);
			}
		} else {

			// Reset the gravity
			Physics.gravity = Vector3.down * GRAVITY_NORMAL / PHYSICS_SCALE_FACTOR;

			// Put back the container to its default position
			container.GetComponent<Rigidbody>().MovePosition (Vector3.zero);
		}

		// Move the camera
		GetComponent<Camera>().transform.position = new Vector3 (container.GetComponent<Rigidbody>().transform.position.x * CAMERA_MOVE_FACTOR, container.GetComponent<Rigidbody>().transform.position.y * CAMERA_MOVE_FACTOR, GetComponent<Camera>().transform.position.z);

		// Switch the mixer on/off
		if (Input.GetMouseButtonDown (0)) {
			mix = !mix;
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
