using UnityEngine;
using System.Collections.Generic;

public class ControllerPanFry : MonoBehaviour
{
	// Physics
	const float PHYSICS_SCALE_FACTOR = 100.0f;
	const float GRAVITY = 9.8f * 100;
	const float FRUIT_DENSITY = 0.001f;
	Vector3 deviceAcceleration;

	// Game logic
	static readonly string[] FRUIT_NAMES = {"Apple", "Banana", "Strawberry"};
	const int FRUIT_PIXEL_SIZE = 100;
	const int FRUIT_COUNT = 10;
	const float PAN_FRY_LENGTH = 3 * FRUIT_PIXEL_SIZE;
	const float PAN_FRY_THICKNESS = 15.0f;
	const float PAN_FRY_DEPTH = 80.0f;
	const float PAN_FRY_MOVE_DURATION = 0.5f;
	const float PAN_FRY_MOVE_X = 2.0f;
	const float PAN_FRY_MOVE_Y = 15.0f;
	const float PAN_FRY_MOVE_Z = 25.0f;
	const float PAN_FRY_ROTATE_X = 10.0f;
	const float CAMERA_HEIGHT = 500.0f;
	GameObject panFry;
	float flipTimer;

	/**
	 * Create a fruit.
	 *
	 * @param name Name of the sprite.
	 * @param position Position where the sprite shall be created.
	 */
	void CreateFruit (string name, Vector3 position)
	{
		// Create a 3D sprite
		GameObject sprite = Sprite.CreateOrModify (null, name, position / PHYSICS_SCALE_FACTOR, 0, Sprite.ColliderType.ContourCollider, FRUIT_DENSITY);
		sprite.transform.localScale = new Vector3 (1.0f / PHYSICS_SCALE_FACTOR, 1.0f / PHYSICS_SCALE_FACTOR, 0.1f / PHYSICS_SCALE_FACTOR);

		// Make sure it can rotate freely
		sprite.GetComponent<Rigidbody>().constraints = RigidbodyConstraints.None;

		// Change the position of its center of mass, so that the fruits always lie flat in the fry pan and rotate in the air
		sprite.GetComponent<Rigidbody>().centerOfMass += new Vector3 (0.0f, 0.0f, sprite.GetComponent<Renderer>().bounds.size.z * 0.5f);
	}

	/**
	 * Create a border.
	 *
	 * @param position Position of the border's center.
	 * @param size Size of the border.
	 * @param border True if the border is really a border, false if it is the bottom of the fry pan.
	 */
	void CreateBorder (Vector3 position, Vector3 size, bool border)
	{
		GameObject cube = GameObject.CreatePrimitive (PrimitiveType.Cube);
		cube.transform.position = position;
		cube.transform.localScale = size;
		cube.transform.parent = panFry.transform;

		if (border) {
			BoxCollider collider = cube.GetComponent<BoxCollider> ();
			collider.center = new Vector3 (0.0f, 0.0f, -(CAMERA_HEIGHT - PAN_FRY_DEPTH) * 0.5f / cube.transform.localScale.z);
			collider.size = new Vector3 (1.0f, 1.0f, CAMERA_HEIGHT / cube.transform.localScale.z);
		}
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
		Physics.gravity = Vector3.forward * GRAVITY / PHYSICS_SCALE_FACTOR;

		// Setup the display
		Camera.main.transform.position = CAMERA_HEIGHT * Vector3.back / PHYSICS_SCALE_FACTOR;
		const float cameraWidth = PAN_FRY_LENGTH + PAN_FRY_THICKNESS * 2;
		const float cameraWidthAtDistance = CAMERA_HEIGHT - PAN_FRY_DEPTH;
		Camera.main.fieldOfView = Mathf.Atan (cameraWidth / (2 * cameraWidthAtDistance * Mathf.Min (1.0f, Camera.main.aspect))) / (0.5f * Mathf.Deg2Rad);
		Camera.main.farClipPlane = (CAMERA_HEIGHT + PAN_FRY_THICKNESS) / PHYSICS_SCALE_FACTOR;

		// Create the pan fry
		panFry = new GameObject ("PanFry");
		CreateBorder (new Vector3 (-(PAN_FRY_LENGTH + PAN_FRY_THICKNESS) * 0.5f, 0.0f, -PAN_FRY_DEPTH * 0.5f), new Vector3 (PAN_FRY_THICKNESS, PAN_FRY_LENGTH + 2 * PAN_FRY_THICKNESS, PAN_FRY_DEPTH), true);
		CreateBorder (new Vector3 ((PAN_FRY_LENGTH + PAN_FRY_THICKNESS) * 0.5f, 0.0f, -PAN_FRY_DEPTH * 0.5f), new Vector3 (PAN_FRY_THICKNESS, PAN_FRY_LENGTH + 2 * PAN_FRY_THICKNESS, PAN_FRY_DEPTH), true);
		CreateBorder (new Vector3 (0.0f, -(PAN_FRY_LENGTH + PAN_FRY_THICKNESS) * 0.5f, -PAN_FRY_DEPTH * 0.5f), new Vector3 (PAN_FRY_LENGTH + 2 * PAN_FRY_THICKNESS, PAN_FRY_THICKNESS, PAN_FRY_DEPTH), true);
		CreateBorder (new Vector3 (0.0f, (PAN_FRY_LENGTH + PAN_FRY_THICKNESS) * 0.5f, -PAN_FRY_DEPTH * 0.5f), new Vector3 (PAN_FRY_LENGTH + 2 * PAN_FRY_THICKNESS, PAN_FRY_THICKNESS, PAN_FRY_DEPTH), true);
		CreateBorder (new Vector3 (0.0f, 0.0f, -PAN_FRY_THICKNESS * 0.5f), new Vector3 (PAN_FRY_LENGTH + 2 * PAN_FRY_THICKNESS, PAN_FRY_LENGTH + 2 * PAN_FRY_THICKNESS, PAN_FRY_THICKNESS), false);
		panFry.transform.localScale = Vector3.one / PHYSICS_SCALE_FACTOR;
		Rigidbody rigidbody = panFry.AddComponent <Rigidbody> ();
		rigidbody.isKinematic = true;

		// Create some fruits
		for (int fruitIndex = 0; fruitIndex < FRUIT_COUNT; ++fruitIndex) {
			Vector3 position = Random.onUnitSphere * FRUIT_PIXEL_SIZE;
			position.z = -PAN_FRY_DEPTH - fruitIndex * FRUIT_PIXEL_SIZE * 0.1f;
			CreateFruit (FRUIT_NAMES [Random.Range (0, FRUIT_NAMES.Length)], position);
		}
	}


	/**
	 * Method called by Unity at every update step of the physics.
	 */
	void FixedUpdate ()
	{
		// Set the position of the pan fry
		float angle;
		if (flipTimer < Time.time) {
			angle = 0;
		} else {
			angle = (flipTimer - Time.time) * Mathf.PI * 2 / PAN_FRY_MOVE_DURATION;
		}
		panFry.GetComponent<Rigidbody>().MovePosition (new Vector3 (Mathf.Sin (angle * 2) * PAN_FRY_MOVE_X / PHYSICS_SCALE_FACTOR, Mathf.Sin (angle) * PAN_FRY_MOVE_Y / PHYSICS_SCALE_FACTOR, (Mathf.Cos (angle) - 1.0f) * PAN_FRY_MOVE_Z / PHYSICS_SCALE_FACTOR));
		panFry.GetComponent<Rigidbody>().MoveRotation (Quaternion.Euler (Mathf.Sin (angle) * PAN_FRY_ROTATE_X, 0.0f, 0.0f));
	}

	/**
	 * Method called by Unity at every update step of the display.
	 */
	void Update ()
	{
		// Make sure the pan fry is idle
		if (flipTimer < Time.time) {

			// Check the inputs
			bool flip;
			if (SystemInfo.supportsAccelerometer) {

				// Compute the actual change of acceleration
				Vector3 jitter = Input.acceleration - deviceAcceleration;
				deviceAcceleration = Input.acceleration;

				// Check whether the fruits should be flipped
				flip = jitter.sqrMagnitude > 1.0f;
			} else {
				flip = Input.GetMouseButtonDown (0);
			}

			// Register the pan fry move request
			if (flip) {
				flipTimer = Time.time + PAN_FRY_MOVE_DURATION;
			}
		}
	}
}
