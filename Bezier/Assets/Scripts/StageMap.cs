using UnityEngine;
using System.Collections.Generic;
using System.IO;

public class StageMap : MonoBehaviour
{
	// Data file configuration
	protected const string DATA_FILE_HEADER = "SM";
	protected const int DATA_FILE_VERSION = 1;

	// Signatures to detect changes of the configuration
	int signatureScreen;
	int signaturePath;

	// Screen
	protected int screenDesignWidth = 640;
	protected int screenDesignHeight = 1136;
	protected float screenWidth;

	// Camera
	protected const float CAMERA_MASS = 1.0f;
	protected const float CAMERA_STIFFNESS = 80.0f;
	protected const float CAMERA_DAMPING = 20.0f;
	const float CAMERA_MOVE_NO_CLICK = 2.0f;
	const float CAMERA_DURATION_MOVE = 1.0f;
	protected float cameraScale;
	protected float cameraForce;
	protected float cameraSpeed;
	protected float cameraPosition;
	protected float cameraPositionMax;
	protected int cameraPageTarget;

	// Page indicator
	int pageIndicatorFirstSpriteIndex;
	int pageIndicatorCurrentIndex;

	// Background
	public List<int> backgroundIDList;
	public enum BackgroundSize
	{
		stretch = 0,
		scale,
		original,
	};
	public BackgroundSize backgroundSize;
	protected Vector2 backgroundSizeMax;
	Vector3 backgroundScale;

	// Sprites
	public enum SpriteSize
	{
		scaleXN = 0,
		scale,
		original
	};
	public SpriteSize spriteSize;
	public enum SpritePosition
	{
		stretch = 0,
		scale,
		original,
	};
	public SpritePosition spritePosition;
	Vector2 spritePositionScale;
	protected List<GameObject> spritePool;
	protected int spriteCount;

	// Data structures to represent the stage map
	protected class Node
	{
		public int id;
		public int type;
		public Vector2 position;
		public List<Path> pathList;
		public enum State
		{
			locked = 0,
			unlocked,
			opening,
			opened
		};
		public State state;
	}

	protected class Path
	{
		public Node nodeFirst;
		public Node nodeLast;
		public List<Vector2> innerControlPointList;
		public int spriteIndexFirst;
		public int spriteIndexFirstOpened;
		public int spriteIndexLast;
		public int spriteIndexLastOpened;
		public int checkID;
	}

	// Stage map
	protected const int NODE_HOME_TYPE = 0;
	protected const int NODE_JUNCTION_TYPE = 4;
	const int DOT_MATERIAL_COUNT = 4;
	public float dotAppearDelay = 0.05f;
	public float dotAnimationPeriod = 1.0f;
	const float DOT_SPACING_MINIMUM = 5.0f;
	public float dotSpacing = 30.0f;
	protected List<Node> nodeList;
	float nodeOpeningTime;

	// Control points
	const float BEZIER_STEP_MINIMUM = 0.01f;
	protected float bezierStep = 0.05f;
	Vector2[] controlPointPool;

	// Input management
	protected const float MOUSE_POSITION_FILTER_COEFFICIENT = 0.5f;
	protected const float SINGLE_CLICK_DURATION = 0.2f;
	protected Vector3 mousePosition;
	protected Dictionary<GameObject, System.Object> touchReferences;
	protected System.Object touchObject;
	protected float touchTime;

	// Structure to get unique IDs
	protected struct CheckID
	{
		static int _id;

		public static int id {
			get {
				return ++_id;
			}
		}
	}

	// Structure to convert floats into integers
	struct Convert
	{
		[System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Explicit)]
		struct Union
		{
			[System.Runtime.InteropServices.FieldOffset(0)]
			public int intValue;
			[System.Runtime.InteropServices.FieldOffset(0)]
			public float floatValue;
		}
		static Union union;

		public static int FloatToInt (float floatValue)
		{
			union.floatValue = floatValue;
			return union.intValue;
		}
	}

	/**
	 * Method called by Unity after that the GameObject has been instantiated.
	 * This is the place where we initialize everything.
	 */
	protected virtual void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Load the stage map
		LoadStageMap ("StageMapData");

		// Setup the display
		// Note: this shall only be done once the stage map has been loaded (to get its settings)
		SetupDisplay ();

		// Lock all the nodes (except those which the type is NODE_HOME_TYPE, which will all be unlocked)
		ChangeAllNodesState (Node.State.locked);

		// Display the stage map
		DisplayStageMap ();
	}

	/**
	 * Method called by Unity at every frame.
	 */
	protected virtual void Update ()
	{
		// Refresh the display if needed
		if (SetupDisplay ()) {
			DisplayStageMap ();
		}

		// Animate the stage map
		AnimateStageMap ();

		// Reset the force used to move the camera
		cameraForce = 0.0f;

		// Handle controls
		if (Input.GetMouseButtonDown (0)) {

			// Get the position of the mouse
			mousePosition = Input.mousePosition;

			// Take note of the time
			touchTime = Time.time;

			// Check whether an object has just been touched
			Ray ray = Camera.main.ScreenPointToRay (mousePosition);
			RaycastHit hit;
			if (Physics.Raycast (ray, out hit, Mathf.Infinity)) {
				touchReferences.TryGetValue (hit.collider.gameObject, out touchObject);
			}
		} else if (Input.GetMouseButton (0)) {

			// Apply a basic filter on the mouse position
			Vector3 mousePositionFiltered = mousePosition * (1.0f - MOUSE_POSITION_FILTER_COEFFICIENT) + Input.mousePosition * MOUSE_POSITION_FILTER_COEFFICIENT;

			// Compute the force to move the camera
			float cameraMove = (mousePosition - mousePositionFiltered).x / cameraScale;
			cameraForce += (cameraMove / Time.deltaTime - cameraSpeed) * CAMERA_MASS / Time.deltaTime;
			mousePosition = mousePositionFiltered;

			// Prevent single click detection in case of scrolling
			if (Mathf.Abs (cameraMove) > CAMERA_MOVE_NO_CLICK) {
				touchTime = 0.0f;
			}
		} else if (Input.GetMouseButtonUp (0)) {

			// Check for single clicks
			if (Time.time < touchTime + SINGLE_CLICK_DURATION) {
				if (touchObject == null) {

					// Lock all the nodes
					ChangeAllNodesState (Node.State.locked);
				} else if (touchObject is Node) {

					// Check whether the node is unlocked
					Node node = (Node)touchObject;
					if (node.state == Node.State.unlocked) {

						// Open the node
						node.state = Node.State.opening;
					}
				}
			}

			// Compute the target position of the camera
			float cameraDistanceEstimate = cameraSpeed * CAMERA_DURATION_MOVE;
			if (cameraDistanceEstimate > screenWidth) {
				++cameraPageTarget;
			} else if (cameraDistanceEstimate < -screenWidth) {
				--cameraPageTarget;
			} else {
				cameraPageTarget = Mathf.RoundToInt (cameraPosition / screenWidth);
			}
			cameraPageTarget = Mathf.Clamp (cameraPageTarget, 0, backgroundIDList.Count - 1);

			// Reset the touch
			touchObject = null;
		} else {

			// Compute the force to move the camera
			cameraForce += (cameraPageTarget * screenWidth - cameraPosition) * CAMERA_STIFFNESS - cameraSpeed * CAMERA_DAMPING;
		}

		// Compute the position of the camera
		cameraSpeed += cameraForce * Time.deltaTime / CAMERA_MASS;
		cameraPosition += cameraSpeed * Time.deltaTime;
		if (cameraPosition < 0.0) {
			cameraPosition = 0.0f;
		} else if (cameraPosition > cameraPositionMax) {
			cameraPosition = cameraPositionMax;
		}

		// Move the camera
		Camera.main.transform.position = new Vector3 (cameraPosition, 0.0f, -1.0f);

		// Update the page indicator display
		UpdatePageIndicators ();
	}

	/**
	 * Setup the camera to properly display the stage map, whatever the actual screen resolution.
	 *
	 * @return True if the display needs to be refreshed, false otherwise.
	 */
	protected bool SetupDisplay ()
	{
		// Make sure the parameters are correct
		dotSpacing = Mathf.Max (dotSpacing, DOT_SPACING_MINIMUM);
		bezierStep = Mathf.Max (bezierStep, BEZIER_STEP_MINIMUM);

		// Check whether the configuration has changed
		int signature = Screen.width ^ (Screen.height << 11) ^ screenDesignWidth ^ (screenDesignHeight << 11) ^ backgroundIDList.Count ^ (int)backgroundSize ^ ((int)spriteSize << 2) ^ ((int)spritePosition << 4);
		for (int backgroundIndex = 0; backgroundIndex < backgroundIDList.Count; ++backgroundIndex) {
			signature ^= backgroundIDList [backgroundIndex] << backgroundIndex;
		}
		if (signatureScreen == signature) {

			// Display settings don't need to be modified
			signature = Convert.FloatToInt (dotSpacing) ^ Convert.FloatToInt (bezierStep);
			if (signaturePath == signature) {

				// There is nothing to do
				return false;
			}

			// Just need to refresh the display
			signaturePath = signature;
			return true;
		}
		signatureScreen = signature;

		// Compute some ratio
		float ratioWidth = (float)Screen.width / screenDesignWidth;
		float ratioHeight = (float)Screen.height / screenDesignHeight;
		float ratio = Mathf.Min (ratioWidth, ratioHeight);

		// Compute the size of the screen and some camera parameters
		switch (spriteSize) {
		case  SpriteSize.scaleXN:
			cameraScale = ratio >= 1.0f ? Mathf.RoundToInt (ratio) : 1.0f / Mathf.RoundToInt (1.0f / ratio);
			break;
		case SpriteSize.scale:
			cameraScale = ratio;
			break;
		default:
			cameraScale = 1.0f;
			break;
		}
		screenWidth = Screen.width / cameraScale;
		cameraPosition = Camera.main.transform.position.x / GetComponent<Camera>().orthographicSize;
		GetComponent<Camera>().orthographicSize = Screen.height / (2 * cameraScale);
		cameraPosition *= GetComponent<Camera>().orthographicSize;
		cameraPositionMax = (backgroundIDList.Count - 1) * screenWidth;
		cameraPageTarget = GetPageIndicatorCurrent ();

		// Compute the sprite position scale
		switch (spritePosition) {
		case  SpritePosition.stretch:
			spritePositionScale = new Vector2 (ratioWidth / cameraScale, ratioHeight / cameraScale);
			break;
		case SpritePosition.scale:
			spritePositionScale = new Vector2 (ratio / cameraScale, ratio / cameraScale);
			break;
		default:
			spritePositionScale = new Vector2 (1.0f / cameraScale, 1.0f / cameraScale);
			break;
		}

		// Compute the actual size and scale of the background images
		switch (backgroundSize) {
		case  BackgroundSize.stretch:
			backgroundSizeMax = new Vector2 (screenDesignWidth, screenDesignHeight);
			backgroundScale = new Vector3 (ratioWidth / cameraScale, ratioHeight / cameraScale, 1.0f);
			break;
		case BackgroundSize.scale:
			backgroundSizeMax = new Vector2 (Screen.width / ratio, Screen.height / ratio);
			backgroundScale = new Vector3 (ratio / cameraScale, ratio / cameraScale, 1.0f);
			break;
		default:
			backgroundSizeMax = new Vector2 (Screen.width, Screen.height);
			backgroundScale = new Vector3 (1.0f / cameraScale, 1.0f / cameraScale, 1.0f);
			break;
		}

		// Display settings have changed
		return true;
	}

	/**
	 * Convert a position in the stage map space to the camera space.
	 *
	 * @param position Position in the stage map space.
	 * @return Position in the camera space.
	 */
	protected Vector2 ConvertMapToCamera (Vector2 position)
	{
		int page = Mathf.FloorToInt (position.x / screenDesignWidth + 0.5f);
		float offset = position.x - page * screenDesignWidth;
		return new Vector2 (page * screenWidth + offset * spritePositionScale.x, position.y * spritePositionScale.y);
	}

	/**
	 * Convert a position in the camera space to the stage map space.
	 *
	 * @param position Position in the camera space.
	 * @return Position in the stage map space.
	 */
	protected Vector2 ConvertCameraToMap (Vector2 position)
	{
		int page = Mathf.FloorToInt (position.x / screenWidth + 0.5f);
		float offset = position.x - page * screenWidth;
		return new Vector2 (page * screenDesignWidth + offset / spritePositionScale.x, position.y / spritePositionScale.y);
	}

	/**
	 * Load the stage map data.
	 *
	 * @param fileName Name of the stage map data file.
	 */
	void LoadStageMap (string fileName)
	{
		try {
			// Open the file
			TextAsset textAsset = Resources.Load ("StageMaps/" + fileName) as TextAsset;
			using (Stream stream = new MemoryStream(textAsset.bytes)) {
				BinaryReader binaryReader = new BinaryReader (stream);

				// Load and check the version information
				string dataFileHeader = binaryReader.ReadString ();
				if (dataFileHeader.CompareTo (DATA_FILE_HEADER) != 0) {
					throw new System.ApplicationException ("Invalid data file format (wrong header)!");
				}
				int dataFileVersion = binaryReader.ReadInt32 ();
				if (dataFileVersion != DATA_FILE_VERSION) {
					throw new System.ApplicationException ("Invalid data file version!");
				}

				// Load the configuration
				screenDesignWidth = binaryReader.ReadInt32 ();
				screenDesignHeight = binaryReader.ReadInt32 ();
				backgroundSize = (BackgroundSize)binaryReader.ReadInt32 ();
				spriteSize = (SpriteSize)binaryReader.ReadInt32 ();
				spritePosition = (SpritePosition)binaryReader.ReadInt32 ();
				dotAppearDelay = binaryReader.ReadSingle ();
				dotAnimationPeriod = binaryReader.ReadSingle ();
				dotSpacing = binaryReader.ReadSingle ();
				bezierStep = binaryReader.ReadSingle ();

				// Load the background IDs
				int backgroundIDCount = binaryReader.ReadInt32 ();
				if (backgroundIDCount == 0) {
					backgroundIDList = null;
				} else {
					backgroundIDList = new List<int> (backgroundIDCount);
					while (backgroundIDCount-- > 0) {
						int backgroundID = binaryReader.ReadInt32 ();
						backgroundIDList.Add (backgroundID);
					}
				}

				// Load all the nodes
				int nodeCount = binaryReader.ReadInt32 ();
				nodeList = new List<Node> (nodeCount);
				while (nodeCount-- > 0) {
					int id = binaryReader.ReadInt32 ();
					int type = binaryReader.ReadInt32 ();
					float x = binaryReader.ReadSingle ();
					float y = binaryReader.ReadSingle ();
					nodeList.Add (new Node {id = id, type = type, position = new Vector2 (x, y)});
				}

				// Load all the paths
				int pathCount = binaryReader.ReadInt32 ();
				while (pathCount-- > 0) {
					Node nodeFirst = nodeList [binaryReader.ReadInt32 ()];
					Node nodeLast = nodeList [binaryReader.ReadInt32 ()];
					int innerControlPointCount = binaryReader.ReadInt32 ();
					List<Vector2> innerControlPointList;
					if (innerControlPointCount == 0) {
						innerControlPointList = null;
					} else {
						innerControlPointList = new List<Vector2> (innerControlPointCount);
						while (innerControlPointCount-- > 0) {
							float x = binaryReader.ReadSingle ();
							float y = binaryReader.ReadSingle ();
							innerControlPointList.Add (new Vector2 (x, y));
						}
					}
					Path path = new Path {nodeFirst = nodeFirst, nodeLast = nodeLast, innerControlPointList = innerControlPointList};

					// Assign the path to the nodes
					if (nodeFirst.pathList == null) {
						nodeFirst.pathList = new List<Path> {path};
					} else {
						nodeFirst.pathList.Add (path);
					}
					if (nodeLast.pathList == null) {
						nodeLast.pathList = new List<Path> {path};
					} else {
						nodeLast.pathList.Add (path);
					}
				}
			}
		} catch (System.Exception e) {
			Debug.LogError ("Could not load the stage map!\n" + e);
			nodeList = null;
		}
	}

	/**
	 * Change the state of all the nodes (and show/hide all the paths accordingly).
	 * Note: nodes which the type is 0 will never be locked.
	 *
	 * @param state State to be given to all the nodes.
	 */
	protected void ChangeAllNodesState (Node.State state)
	{
		// Check all the nodes
		if (nodeList != null) {
			int checkID = CheckID.id;
			foreach (Node node in nodeList) {

				// Change the node's state
				if (node.type != NODE_HOME_TYPE || state != Node.State.locked) {
					node.state = state;
				} else {
					node.state = Node.State.unlocked;
				}

				// Check whether paths should be displayed or hidden
				bool visible = state == Node.State.opened;

				// Check all the node's paths
				if (node.pathList != null) {
					foreach (Path path in node.pathList) {

						// Make sure this path hasn't already been checked
						if (path.checkID != checkID) {
							path.checkID = checkID;

							// Display or hide the path
							path.spriteIndexFirstOpened = path.spriteIndexFirst;
							for (int spriteIndex = path.spriteIndexFirst; spriteIndex < path.spriteIndexLast; ++spriteIndex) {
								spritePool [spriteIndex].SetActive (visible);
							}
							path.spriteIndexLastOpened = visible ? path.spriteIndexFirst : path.spriteIndexLast;
						}
					}
				}
			}
		}
	}

	/**
	 * Animate the stage map (change of colors of the materials & opening of the paths).
	 */
	void AnimateStageMap ()
	{
		// Animate the materials
		for (int materialIndex = 1; materialIndex <= DOT_MATERIAL_COUNT; ++materialIndex) {
			float tint = 0.8f + 0.2f * Mathf.Sin (Time.time * 2 * Mathf.PI / dotAnimationPeriod - materialIndex * 2 * Mathf.PI / DOT_MATERIAL_COUNT);
			Sprite.SetMaterialColor (materialIndex, new Color (tint, tint, tint, 1.0f));
		}

		// Animate the node opening
		if (Time.time > nodeOpeningTime && nodeList != null) {
			nodeOpeningTime = Time.time + dotAppearDelay;

			// Check all the nodes that have been registered to be opened
			foreach (Node node in nodeList) {

				// Check whether this node has to be opened
				if (node.state != Node.State.opening) {
					continue;
				}

				// Check all the node's paths
				bool nodeCanBeOpened = true;
				if (node.pathList != null) {
					foreach (Path path in node.pathList) {

						// Check whether the path is fully displayed
						if (path.spriteIndexFirstOpened < path.spriteIndexLastOpened) {

							// Enable the current sprite
							if (node == path.nodeFirst) {
								spritePool [path.spriteIndexFirstOpened++].SetActive (true);
							} else {
								spritePool [--path.spriteIndexLastOpened].SetActive (true);
							}
							nodeCanBeOpened = false;
						} else {

							// Unlock the other node (junctions shall be opened)
							Node otherNode = node == path.nodeFirst ? path.nodeLast : path.nodeFirst;
							if (otherNode.type == NODE_JUNCTION_TYPE && otherNode.state != Node.State.opened) {
								otherNode.state = Node.State.opening;
							} else if (otherNode.state == Node.State.locked) {
								otherNode.state = Node.State.unlocked;
							}
						}
					}
				}

				// Open the node it all its path are fully displayed
				if (nodeCanBeOpened) {
					node.state = Node.State.opened;
				}
			}
		}
	}

	/**
	 * Register a sprite for touch controls.
	 *
	 * @param sprite Sprite which must be controlled.
	 * @param reference Referenced object.
	 */
	protected void RegisterTouch (GameObject sprite, System.Object reference)
	{
		// Give this sprite a box collider so that we can control it
		BoxCollider boxCollider = sprite.GetComponent<BoxCollider> ();
		if (boxCollider == null) {
			sprite.AddComponent<BoxCollider> ();
		} else {
			MeshFilter meshFilter = sprite.GetComponent<MeshFilter> ();
			if (meshFilter != null) {
				boxCollider.size = meshFilter.mesh.bounds.size;
				boxCollider.enabled = true;
			}
		}

		// Register the referenced object
		touchReferences.Add (sprite, reference);
	}

	/**
	 * Display a background.
	 *
	 * @param backgroundIndex Index of the background to be displayed.
	 */
	protected virtual void DisplayBackground (int backgroundIndex)
	{
		// Load the background material
		Material material = Resources.Load ("BackgroundMaterials/Background-" + backgroundIDList [backgroundIndex]) as Material;
		if (material == null) {
			Debug.LogError ("Could not load the background ID #" + backgroundIDList [backgroundIndex] + "!");
			return;
		}

		// Display the background, reusing an existing sprite or creating a new one as needed
		GameObject sprite;
		Vector3 positon = new Vector3 (backgroundSizeMax.x * backgroundScale.x * backgroundIndex, 0.0f, 5.0f);
		if (spriteCount < spritePool.Count) {
			sprite = spritePool [spriteCount];
			sprite.transform.parent = null;
			sprite.transform.localPosition = positon;
			Sprite.Modify (sprite, material, backgroundSizeMax);
			sprite.SetActive (true);

			// These sprites don't need a box collider (we don't control them)
			BoxCollider boxCollider = sprite.GetComponent<BoxCollider> ();
			if (boxCollider != null) {
				boxCollider.enabled = false;
			}
		} else {
			sprite = Sprite.Create (material, positon, backgroundSizeMax);
			spritePool.Add (sprite);
		}
		sprite.transform.localScale = backgroundScale;
		++spriteCount;
	}

	/**
	 * Compute the page index from the actual position of the camera.
	 *
	 * @return Index of the page currently shown by the camera.
	 */
	protected int GetPageIndicatorCurrent ()
	{
		return Mathf.Clamp (Mathf.RoundToInt (cameraPosition / screenWidth), 0, backgroundIDList.Count - 1);
	}

	/**
	 * Display a page indicator.
	 *
	 * @param position Position of the page indicator in the camera space.
	 * @param current True if the page indicator corresponds to the current page, false otherwise.
	 */
	void DisplayPageIndicator (Vector3 position, bool current)
	{
		// Display a page indicator, reusing an existing sprite or creating a new one as needed
		string name = current ? "PageCurrent" : "PageOther";
		if (spriteCount < spritePool.Count) {
			GameObject sprite = spritePool [spriteCount];
			sprite.transform.parent = Camera.main.transform;
			sprite.transform.localPosition = position;
			sprite.transform.localScale = Vector3.one;
			Sprite.Modify (sprite, name);
			sprite.SetActive (true);

			// These sprites don't need a box collider (we don't control them)
			BoxCollider boxCollider = sprite.GetComponent<BoxCollider> ();
			if (boxCollider != null) {
				boxCollider.enabled = false;
			}
		} else {
			GameObject sprite = Sprite.Create (name, position + Camera.main.transform.position);
			sprite.transform.parent = Camera.main.transform;
			spritePool.Add (sprite);
		}
		++spriteCount;
	}

	/**
	 * Update the page indicator display
	 */
	protected void UpdatePageIndicators ()
	{
		int pageCameraCurrentIndex = GetPageIndicatorCurrent ();
		if (pageIndicatorCurrentIndex != pageCameraCurrentIndex) {

			// Get the two sprites that need to be swapped
			int spriteIndexBefore = pageIndicatorFirstSpriteIndex + pageIndicatorCurrentIndex;
			int spriteIndexAfter = pageIndicatorFirstSpriteIndex + pageCameraCurrentIndex;
			GameObject spriteBefore = spritePool [spriteIndexBefore];
			GameObject spriteAfter = spritePool [spriteIndexAfter];

			// Swap their positions
			Vector3 positionBefore = spriteBefore.transform.position;
			spriteBefore.transform.position = spriteAfter.transform.position;
			spriteAfter.transform.position = positionBefore;

			// Swap the sprites
			spritePool [spriteIndexBefore] = spriteAfter;
			spritePool [spriteIndexAfter] = spriteBefore;
			pageIndicatorCurrentIndex = pageCameraCurrentIndex;
		}
	}

	/**
	 * Display a node.
	 *
	 * @param node Node which has to be displayed.
	 */
	void DisplayNode (Node node)
	{
		// Display the node, reusing an existing sprite or creating a new one as needed
		GameObject sprite;
		string name = "Node-" + node.type;
		Vector3 position = ConvertMapToCamera (node.position);
		if (spriteCount < spritePool.Count) {
			sprite = spritePool [spriteCount];
			sprite.transform.parent = null;
			sprite.transform.localPosition = position;
			sprite.transform.localScale = Vector3.one;
			Sprite.Modify (sprite, name);
			sprite.SetActive (true);
		} else {
			sprite = Sprite.Create (name, position);
			spritePool.Add (sprite);
		}
		++spriteCount;

		// Register this sprite for touch controls
		RegisterTouch (sprite, node);
	}

	/**
	 * Compute the position of a point on a path.
	 *
	 * @param path Path on which the point is.
	 * @param t Parameter defining the relative position of the point on the path (between 0 and 1).
	 * @return Position of the point (zero if no path was provided).
	 */
	Vector2 GetPathPoint (Path path, float t)
	{
		// In case there is no path, we must exit
		if (path == null) {
			Debug.LogError ("There is no path!");
			return Vector2.zero;
		}

		// Set the 2 parameters (ratios) used for computations
		float t2 = Mathf.Clamp (t, 0.0f, 1.0f);
		float t1 = 1.0f - t2;

		// In case there is no inner point, we can proceed quickly
		if (path.innerControlPointList == null || path.innerControlPointList.Count == 0) {
			return t1 * path.nodeFirst.position + t2 * path.nodeLast.position;
		}

		// Make sure we have an array to store our intermediate results
		if (controlPointPool == null || controlPointPool.Length < path.innerControlPointList.Count + 1) {
			controlPointPool = new Vector2 [path.innerControlPointList.Count + 1];
		}

		// Compute the results of the 1st step (basically, it's De Casteljau's algorithm)
		int loop = 0;
		controlPointPool [loop] = t1 * path.nodeFirst.position + t2 * path.innerControlPointList [loop];
		while (++loop < path.innerControlPointList.Count) {
			controlPointPool [loop] = t1 * path.innerControlPointList [loop - 1] + t2 * path.innerControlPointList [loop];
		}
		controlPointPool [loop] = t1 * path.innerControlPointList [loop - 1] + t2 * path.nodeLast.position;

		// Iterate until we get the solution
		do {
			for (int index = 0; index < loop; ++index) {
				controlPointPool [index] = t1 * controlPointPool [index] + t2 * controlPointPool [index + 1];
			}
		} while (--loop > 0);
		return controlPointPool [0];
	}

	/**
	 * Display all the dots along a path.
	 *
	 * @param path Path which has to be displayed.
	 */
	protected virtual void DisplayPath (Path path)
	{
		// Take note of the current sprite index
		path.spriteIndexFirst = spriteCount;
		path.spriteIndexFirstOpened = spriteCount;

		// Check whether the path should be displayed or hidden
		bool visible = path.nodeFirst.state == Node.State.opened || path.nodeLast.state == Node.State.opened;

		// Take many points along the Bezier curve
		string spriteName = "Dot";
		float distanceNextDot = dotSpacing;
		Vector3 previousPosition = ConvertMapToCamera (path.nodeFirst.position);
		previousPosition.z = 1.0f;
		for (float t = bezierStep; t < 1.0f + bezierStep; t += bezierStep) {

			// Compute the segment
			Vector3 position = ConvertMapToCamera (GetPathPoint (path, t));
			Vector3 segment = position - previousPosition;
			float length = segment.magnitude;

			// Add some dots, having a constant distance between two successive dots
			while (distanceNextDot <= length) {

				// Display the dot, reusing an existing sprite or creating a new one as needed
				GameObject sprite;
				Vector3 spritePosition = previousPosition + segment * distanceNextDot / length;
				int materialIndex = 1 + (spriteCount) % DOT_MATERIAL_COUNT;
				if (spriteCount < spritePool.Count) {
					sprite = spritePool [spriteCount];
					sprite.transform.parent = null;
					sprite.transform.localPosition = spritePosition;
					sprite.transform.localScale = Vector3.one;
					Sprite.Modify (sprite, spriteName, materialIndex);

					// These sprites don't need a box collider (we don't control them)
					BoxCollider boxCollider = sprite.GetComponent<BoxCollider> ();
					if (boxCollider != null) {
						boxCollider.enabled = false;
					}
				} else {
					sprite = Sprite.Create (spriteName, spritePosition, materialIndex);
					spritePool.Add (sprite);
				}
				sprite.SetActive (visible);
				++spriteCount;
				distanceNextDot += dotSpacing;
			}
			distanceNextDot -= length;
			previousPosition = position;
		}

		// Take note of the current sprite index
		path.spriteIndexLast = spriteCount;
		path.spriteIndexLastOpened = visible ? path.spriteIndexFirst : path.spriteIndexLast;
	}

	/**
	 * Display the stage map.
	 */
	protected virtual void DisplayStageMap ()
	{
		// Set up a dictionary to handle inputs, or clean-up the existing one
		if (touchReferences == null) {
			touchReferences = new Dictionary<GameObject, object> ();
		} else {
			touchReferences.Clear ();
		}

		// Create the pool of sprites if it doesn't exist already
		if (spritePool == null) {
			spritePool = new List<GameObject> ();
		}
		spriteCount = 0;

		// Display the background images
		if (backgroundIDList != null) {
			for (int backgroundIndex = 0; backgroundIndex < backgroundIDList.Count; ++backgroundIndex) {
				DisplayBackground (backgroundIndex);
			}

			// Display the page indicators
			if (backgroundIDList.Count > 1) {
				pageIndicatorFirstSpriteIndex = spriteCount;
				pageIndicatorCurrentIndex = GetPageIndicatorCurrent ();
				Vector2 pageIndicatorSize = Sprite.GetSize ("PageOther");
				Vector3 pageIndicatorPosition = new Vector3 (-pageIndicatorSize.x * (backgroundIDList.Count - 1) / 2, (pageIndicatorSize.y - screenDesignHeight / 2) * spritePositionScale.y, 0.1f);
				for (int backgroundIndex = 0; backgroundIndex < backgroundIDList.Count; ++backgroundIndex) {
					DisplayPageIndicator (pageIndicatorPosition, backgroundIndex == pageIndicatorCurrentIndex);
					pageIndicatorPosition.x += pageIndicatorSize.x;
				}
			}
		}

		// Check all the nodes
		if (nodeList != null) {
			int checkID = CheckID.id;
			foreach (Node node in nodeList) {

				// Display the node
				DisplayNode (node);

				// Check all the node's paths
				if (node.pathList != null) {
					foreach (Path path in node.pathList) {

						// Make sure this path hasn't already been checked
						if (path.checkID != checkID) {
							path.checkID = checkID;

							// Display the path
							DisplayPath (path);
						}
					}
				}
			}
		}

		// Hide sprites that aren't needed
		for (int spriteIndex = spriteCount; spriteIndex < spritePool.Count; ++spriteIndex) {
			spritePool [spriteIndex].SetActive (false);
		}
	}

	/**
	 * Destroy the stage map.
	 */
	protected virtual void DestroyStageMap ()
	{
		// Destroy the pool of sprites
		if (spritePool != null) {
			foreach (GameObject sprite in spritePool) {
				Destroy (sprite);
			}
			spritePool = null;
		}

		// Destroy everything else
		nodeList = null;
		controlPointPool = null;
		touchReferences = null;
	}
}
