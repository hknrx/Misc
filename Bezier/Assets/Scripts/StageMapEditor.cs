/*
 * Controls:
 *
 * 1) Press [space]: toggle between normal mode and edition mode.
 *
 * 2) When in edition mode:
 * - [A] is to "Add" elements;
 * - [D] is to "Delete" elements;
 * - [C] is to "Clean" everything;
 * - [S] is to "Save" everything;
 * - [X] is to destroy everything (to be used with [shift]).
 *
 *   a) Click on a node:
 *   - Single click: change the node's type.
 *   - Click and drag: move the node and its paths (if a path has no control point, then 1 control point is added).
 *   - Press [A] then click and drag: create a new node with a path that links it to the clicked node.
 *   - Drop the node on another node: merge the nodes and their paths (except loops).
 *   - Press [D] then click: delete the node and all its paths.
 *
 *   b) Click a control point:
 *   - Click and drag: move the control point.
 *   - Press [A] then click: create a new control point on the path.
 *   - Press [D] then click: delete the control point.
 *   - Press [D]+[shift] then click: delete the whole path.
 *
 *   c) Click neither on a node nor a control point + press [A]: create a new node.
 *
 *   d) Press [C]: clean up the stage map (remove elements that are outside the stage map boundaries).
 *
 *   e) Press [S]: save the stage map to a data file.
 *
 *   f) Press [X]+[shift]: destroy the stage map (one home node is then automatically created).
 *
 * Note:
 * To edit the nodes (e.g. set their ID), the easiest way is to:
 * - Make the variable "nodeList" public, as well as the classes "Node" and "Path";
 * - Mark the class "Node" as serializable (add "[System.SerializableAttribute]" before its declaration).
 * Then, you can edit the node list directly in the Unity editor, and save the stage map as usual (pressing [S]).
 */
using UnityEngine;
using System.Collections.Generic;
using System.IO;

public class StageMapEditor : StageMap
{
	// Editor mode
	bool enableEdition;

	// Camera
	const float CAMERA_FRICTION = 5.0f;

	// Stage map
	const int NODE_NORMAL_TYPE_COUNT = 5;
	const int NODE_DROP_TYPE = 999;

	// Control points
	struct ControlPointReference
	{
		public Path path;
		public int innerControlPointIndex;
	}
	List<GameObject> lineRendererPool;
	int lineRendererCount;

	// Input management
	const float SCREEN_MARGIN = 10.0f;
	Vector2 touchTranslate;
	Node touchOtherNode;
	int touchNodeType;

	// GUI (variables to be set in the editor)
	const float SAVE_MESSAGE_DISPLAY_DURATION = 3.0f;
	public Rect saveMessagePosition;
	public GUIStyle saveMessageStyle;
	float saveMessageDisplayTime;

	/**
	 * Method called by Unity at every frame.
	 */
	protected override void Update ()
	{
		// Check whether the space bar is pressed and there is no drag & drop being done
		if (Input.GetKeyDown (KeyCode.Space) && touchObject == null) {

			// Toggle the edition mode on/off
			enableEdition = !enableEdition;
			if (enableEdition) {

				// Open all the nodes
				ChangeAllNodesState (Node.State.opened);
			} else {

				// Set the target page of the camera
				cameraPageTarget = GetPageIndicatorCurrent ();
			}

			// Refresh the display
			DisplayStageMap ();
			return;
		}

		// Check whether the edit mode is enable or not
		if (!enableEdition) {

			// Normal behavior
			base.Update ();
			return;
		}

		// Reset the force used to move the camera
		cameraForce = 0.0f;

		// Check the mouse events
		bool refreshDisplay = SetupDisplay ();
		if (Input.GetMouseButtonDown (0)) {
			refreshDisplay |= MouseClickBegin ();
		} else if (Input.GetMouseButton (0)) {
			refreshDisplay |= MouseClickContinue ();
		} else if (Input.GetMouseButtonUp (0)) {
			refreshDisplay |= MouseClickEnd ();
		} else {
			refreshDisplay |= MouseClickNothing ();
		}

		// Refresh the display if needed
		if (refreshDisplay) {
			DisplayStageMap ();
		}

		// Compute the position of the camera
		if (cameraPosition < 0.0f) {
			cameraForce -= cameraPosition * CAMERA_STIFFNESS + cameraSpeed * CAMERA_DAMPING;
		} else if (cameraPosition > cameraPositionMax) {
			cameraForce += (cameraPositionMax - cameraPosition) * CAMERA_STIFFNESS - cameraSpeed * CAMERA_DAMPING;
		} else {
			cameraForce -= cameraSpeed * CAMERA_FRICTION;
		}
		cameraSpeed += cameraForce * Time.deltaTime / CAMERA_MASS;
		cameraPosition += cameraSpeed * Time.deltaTime;

		// Move the camera
		Camera.main.transform.position = new Vector3 (cameraPosition, 0.0f, -1.0f);

		// Update the page indicator display
		UpdatePageIndicators ();
	}

	/**
	 * Method called by Unity to refresh the GUI.
	 */
	void OnGUI ()
	{
		// Display the save message
		if (Time.time < saveMessageDisplayTime) {
			GUI.Label (saveMessagePosition, "STAGE MAP SAVED!", saveMessageStyle);
		}
	}

	/**
	 * Handle the mouse click begin event.
	 *
	 * @return True if the display needs to be refreshed, false otherwise.
	 */
	bool MouseClickBegin ()
	{
		// Get the position of the mouse
		mousePosition = Input.mousePosition;
		Vector2 touchPosition = Camera.main.ScreenToWorldPoint (mousePosition);

		// Check which object is being touched (if any)
		Ray ray = Camera.main.ScreenPointToRay (mousePosition);
		RaycastHit hit;
		if (!Physics.Raycast (ray, out hit, Mathf.Infinity) || !touchReferences.TryGetValue (hit.collider.gameObject, out touchObject)) {
			if (Input.GetKey (KeyCode.A)) {

				// Add a new node
				AddNode (touchPosition);
				return true;
			}

			// There is nothing to do
			return false;
		}

		// Take note of which object has been touched
		touchTime = Time.time;
		touchTranslate = (Vector2)hit.collider.gameObject.transform.position - touchPosition;
		if (touchObject is Node) {
			touchOtherNode = null;
			touchNodeType = ((Node)touchObject).type;
		}

		// Check whether a new object shall be added
		if (Input.GetKey (KeyCode.A)) {
			if (touchObject is Node) {

				// Add a new node
				touchOtherNode = (Node)touchObject;
				Node node = AddNode (touchPosition, touchOtherNode);

				// Modify the target of the drag & drop
				touchObject = node;
				return true;
			}
			if (touchObject is ControlPointReference) {

				// Add a new control point
				AddControlPoint ((ControlPointReference)touchObject);

				// Cancel the drag & drop
				touchObject = null;
				return true;
			}
			return false;
		}

		// Check whether an existing object shall be destroyed
		if (Input.GetKey (KeyCode.D)) {
			bool refreshDisplay = false;
			if (touchObject is Node) {

				// Remove the node and all its paths
				DeleteNode ((Node)touchObject);
				refreshDisplay = true;
			} else if (touchObject is ControlPointReference) {
				ControlPointReference controlPointReference = (ControlPointReference)touchObject;
				if (Input.GetKey (KeyCode.LeftShift) || Input.GetKey (KeyCode.RightShift)) {

					// Delete the path
					DeletePath (controlPointReference.path);
				} else {

					// Delete the control point
					DeleteControlPoint (controlPointReference);
				}
				refreshDisplay = true;
			}

			// Cancel the drag & drop
			touchObject = null;
			return refreshDisplay;
		}

		// There is nothing to do
		return false;
	}

	/**
	 * Handle the mouse click continue event.
	 *
	 * @return True if the display needs to be refreshed, false otherwise.
	 */
	bool MouseClickContinue ()
	{
		// Apply a basic filter on the mouse position
		Vector3 mousePositionFiltered = mousePosition * (1.0f - MOUSE_POSITION_FILTER_COEFFICIENT) + Input.mousePosition * MOUSE_POSITION_FILTER_COEFFICIENT;

		// Compute the force to move the camera
		float cameraMove = touchObject == null ? (mousePosition - mousePositionFiltered).x / cameraScale : 0.0f;
		cameraForce = (cameraMove / Time.deltaTime - cameraSpeed) * CAMERA_MASS / Time.deltaTime;
		mousePosition = mousePositionFiltered;

		// Make sure we don't move too close from the edge of the screen
		if (mousePosition.x < SCREEN_MARGIN
			|| mousePosition.x >= Screen.width - SCREEN_MARGIN
			|| mousePosition.y < SCREEN_MARGIN
			|| mousePosition.y >= Screen.height - SCREEN_MARGIN) {

			// There is nothing to do
			return false;
		}

		// Are we moving a node?
		Vector2 touchPosition = Camera.main.ScreenToWorldPoint (mousePosition);
		if (touchObject is Node) {

			// Check whether another node is being touched
			touchOtherNode = null;
			Ray ray = Camera.main.ScreenPointToRay (mousePosition);
			RaycastHit [] hitList = Physics.RaycastAll (ray, Mathf.Infinity);
			foreach (RaycastHit hit in hitList) {
				System.Object otherTouchObject;
				if (touchReferences.TryGetValue (hit.collider.gameObject, out otherTouchObject)) {
					if (otherTouchObject != touchObject && otherTouchObject is Node) {
						touchOtherNode = (Node)otherTouchObject;
						break;
					}
				}
			}

			// Move the node and set its type
			Node node = (Node)touchObject;
			if (touchOtherNode == null) {
				node.position = ConvertCameraToMap (touchTranslate + touchPosition);
				node.type = touchNodeType;
			} else {
				node.position = ConvertCameraToMap (touchPosition);
				node.type = NODE_DROP_TYPE;
			}
			return true;
		}

		// Are we moving a control point?
		if (touchObject is ControlPointReference) {

			// Move the control point
			ControlPointReference controlPointReference = (ControlPointReference)touchObject;
			controlPointReference.path.innerControlPointList [controlPointReference.innerControlPointIndex] = ConvertCameraToMap (touchTranslate + touchPosition);
			return true;
		}

		// There is nothing to do
		return false;
	}

	/**
	 * Handle the mouse click end event.
	 *
	 * @return True if the display needs to be refreshed, false otherwise.
	 */
	bool MouseClickEnd ()
	{
		// Check whether a node was touched
		bool refreshDisplay = false;
		if (touchObject is Node) {
			Node node = (Node)touchObject;
			if (touchOtherNode != null) {

				// Merge the 2 nodes
				MergeNode (node, touchOtherNode);
				refreshDisplay = true;
			} else if (Time.time < touchTime + SINGLE_CLICK_DURATION) {

				// Change the type of the node
				node.type = (node.type + 1) % NODE_NORMAL_TYPE_COUNT;
				refreshDisplay = true;
			} else {

				// By default, check all the node's paths to make sure they have inner control points
				refreshDisplay = AddControlPoints (node);
			}
		}

		// Reset the touch
		touchObject = null;
		return refreshDisplay;
	}

	/**
	 * Handle the mouse no click event.
	 *
	 * @return True if the display needs to be refreshed, false otherwise.
	 */
	bool MouseClickNothing ()
	{
		// Check whether the stage map shall be cleaned up
		if (Input.GetKeyDown (KeyCode.C)) {
			CleanStageMap ();
			return true;
		}

		// Check whether the stage map shall be saved
		if (Input.GetKeyDown (KeyCode.S)) {
			SaveStageMap ();
			return false;
		}

		// Check whether the stage map shall be destroyed
		if (Input.GetKeyDown (KeyCode.X) && (Input.GetKey (KeyCode.LeftShift) || Input.GetKey (KeyCode.RightShift))) {
			DestroyStageMap ();
			return false;
		}

		// Check whether a node shall be automatically created
		if (nodeList == null || nodeList.Count == 0) {
			AddNode (Camera.main.transform.position);
			return true;
		}

		// There is nothing to do
		return false;
	}

	/**
	 * Add a new node.
	 * If another node is provided, then also add a path to link the 2 nodes together.
	 *
	 * @param touchPosition Position of the touch, where the node shall be created.
	 * @param otherNode Node to which the newly created node shall be linked.
	 * @return Newly created node.
	 */
	Node AddNode (Vector2 touchPosition, Node otherNode = null)
	{
		Vector2 position = ConvertCameraToMap (touchPosition);
		Node node = new Node {position = position, state = Node.State.opened};
		if (otherNode == null) {
			node.type = NODE_HOME_TYPE;
		} else {
			node.type = NODE_DROP_TYPE;
			Path path = new Path {nodeFirst = touchOtherNode, nodeLast = node, innerControlPointList = null};
			if (touchOtherNode.pathList == null) {
				touchOtherNode.pathList = new List<Path> {path};
			} else {
				touchOtherNode.pathList.Add (path);
			}
			node.pathList = new List<Path> {path};
		}
		if (nodeList == null) {
			nodeList = new List<Node> {node};
		} else {
			nodeList.Add (node);
		}
		return node;
	}

	/**
	 * Merge 2 nodes:
	 * - Attach all the first node's paths to the second node (except if it would create a loop);
	 * - Remove the first node.
	 *
	 * @param firstNode First node (which will be removed).
	 * @param secondNode Second node.
	 */
	void MergeNode (Node firstNode, Node secondNode)
	{
		if (firstNode.pathList != null) {
			foreach (Path path in firstNode.pathList) {
				Node pathOtherNode = firstNode == path.nodeFirst ? path.nodeLast : path.nodeFirst;
				if (pathOtherNode == secondNode) {
					secondNode.pathList.Remove (path);
				} else {
					if (firstNode == path.nodeFirst) {
						path.nodeFirst = secondNode;
					} else {
						path.nodeLast = secondNode;
					}
					if (secondNode.pathList == null) {
						secondNode.pathList = new List<Path> {path};
					} else {
						secondNode.pathList.Add (path);
					}
				}
			}
		}
		nodeList.Remove (firstNode);
	}

	/**
	 * Delete a node and all its paths.
	 *
	 * @param node Node to be deleted.
	 */
	void DeleteNode (Node node)
	{
		if (node.pathList != null) {
			foreach (Path path in node.pathList) {
				if (path.nodeFirst != node) {
					path.nodeFirst.pathList.Remove (path);
				} else {
					path.nodeLast.pathList.Remove (path);
				}
			}
		}
		nodeList.Remove (node);
	}

	/**
	 * Add a control point next to another control point.
	 *
	 * @param controlPointReference Reference to the other control point.
	 */
	void AddControlPoint (ControlPointReference controlPointReference)
	{
		Path path = controlPointReference.path;
		int index = controlPointReference.innerControlPointIndex;
		Vector2 positionOld = (path.innerControlPointList [index] + (index < path.innerControlPointList.Count - 1 ? path.innerControlPointList [index + 1] : path.nodeLast.position)) / 2;
		Vector2 positionNew = (path.innerControlPointList [index] + (index > 0 ? path.innerControlPointList [index - 1] : path.nodeFirst.position)) / 2;
		path.innerControlPointList [index] = positionOld;
		path.innerControlPointList.Insert (index, positionNew);
	}

	/**
	 * Add a control point to any path that has no inner control point.
	 *
	 * @param node Node which the paths shall be checked.
	 * @return True if one or more control points have been added, false otherwise.
	 */
	bool AddControlPoints (Node node)
	{
		bool controlPointAdded = false;
		if (node.pathList != null) {
			foreach (Path path in node.pathList) {
				if (path.innerControlPointList == null) {
					path.innerControlPointList = new List<Vector2> {(path.nodeFirst.position + path.nodeLast.position) / 2};
					controlPointAdded = true;
				} else if (path.innerControlPointList.Count == 0) {
					path.innerControlPointList.Add ((path.nodeFirst.position + path.nodeLast.position) / 2);
					controlPointAdded = true;
				}
			}
		}
		return controlPointAdded;
	}

	/**
	 * Delete a control point.
	 *
	 * @param controlPointReference Reference to the control point.
	 */
	void DeleteControlPoint (ControlPointReference controlPointReference)
	{
		controlPointReference.path.innerControlPointList.RemoveAt (controlPointReference.innerControlPointIndex);
	}

	/**
	 * Delete a path.
	 *
	 * @param path Path to be deleted.
	 */
	void DeletePath (Path path)
	{
		path.nodeFirst.pathList.Remove (path);
		path.nodeLast.pathList.Remove (path);
	}

	/**
	 * Display the left boundary of a background sprite.
	 *
	 * @param parent Background sprite which the left boundary shall be displayed.
	 */
	void DisplayBackgroundBoundary (GameObject parent)
	{
		// Display the page boundary, reusing an existing sprite or creating a new one as needed
		GameObject sprite;
		string name = "PageBoundary";
		Vector3 position = new Vector3 (-backgroundSizeMax.x * 0.5f, 0.0f, -0.5f);
		if (spriteCount < spritePool.Count) {
			sprite = spritePool [spriteCount];
			sprite.transform.parent = parent.transform;
			sprite.transform.localPosition = position;
			Sprite.Modify (sprite, name);
			sprite.SetActive (true);

			// These sprites don't need a box collider (we don't control them)
			BoxCollider boxCollider = sprite.GetComponent<BoxCollider> ();
			if (boxCollider != null) {
				boxCollider.enabled = false;
			}
		} else {
			sprite = Sprite.Create (name, position);
			sprite.transform.parent = parent.transform;
			spritePool.Add (sprite);
		}
		sprite.transform.localScale = new Vector3 (1.0f / parent.transform.localScale.x, backgroundSizeMax.y / Sprite.GetSize (name).y, 1.0f);
		++spriteCount;
	}

	/**
	 * Display a background.
	 *
	 * @param backgroundIndex Index of the background to be displayed.
	 */
	protected override void DisplayBackground (int backgroundIndex)
	{
		// Display the background
		base.DisplayBackground (backgroundIndex);

		// Display the background boundary
		if (enableEdition && backgroundIndex > 0) {
			DisplayBackgroundBoundary (spritePool [spriteCount - 1]);
		}
	}

	/**
	 * Display the inner control points of a path, as well as the lines that connect all these control points.
	 *
	 * @param path Path which the control points have to be displayed.
	 */
	void DisplayControlPoints (Path path)
	{
		// Reuse an existing line renderer component or create a new one as needed
		LineRenderer lineRenderer;
		if (lineRendererCount < lineRendererPool.Count) {
			GameObject lineRendererObject = lineRendererPool [lineRendererCount];
			lineRenderer = lineRendererObject.GetComponent<LineRenderer> ();
			lineRendererObject.SetActive (true);
		} else {
			GameObject lineRendererObject = new GameObject ("LineRenderer");
			lineRenderer = lineRendererObject.AddComponent<LineRenderer> ();
			lineRenderer.material = new Material (Shader.Find ("Particles/Additive"));
			int colorIndex = (lineRendererCount % 7) + 1;
			Color color = new Color (colorIndex & 1, (colorIndex >> 1) & 1, (colorIndex >> 2) & 1);
			lineRenderer.SetColors (color, color);
			lineRenderer.SetWidth (3.0f, 3.0f);
			lineRendererPool.Add (lineRendererObject);
		}
		lineRenderer.SetVertexCount (path.innerControlPointList != null ? path.innerControlPointList.Count + 2 : 2);
		++lineRendererCount;

		// Set the first point of the line renderer
		int lineRendererVertexIndex = 0;
		lineRenderer.SetPosition (lineRendererVertexIndex++, ConvertMapToCamera (path.nodeFirst.position));

		// Take each inner control point of the path
		if (path.innerControlPointList != null) {
			string name = "ControlPoint";
			for (int innerControlPointIndex = 0; innerControlPointIndex < path.innerControlPointList.Count; ++innerControlPointIndex) {

				// Display the control point, reusing an existing sprite or creating a new one as needed
				GameObject sprite;
				Vector3 position = ConvertMapToCamera (path.innerControlPointList [innerControlPointIndex]);
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
				RegisterTouch (sprite, new ControlPointReference {path = path, innerControlPointIndex = innerControlPointIndex});

				// Add the point to the line renderer
				lineRenderer.SetPosition (lineRendererVertexIndex++, position);
			}
		}

		// Add the last point of the line renderer
		lineRenderer.SetPosition (lineRendererVertexIndex, ConvertMapToCamera (path.nodeLast.position));
	}

	/**
	 * Display all the dots along a path.
	 *
	 * @param path Path which has to be displayed.
	 */
	protected override void DisplayPath (Path path)
	{
		// Display the path
		base.DisplayPath (path);

		// Display the inner control points
		if (enableEdition) {
			DisplayControlPoints (path);
		}
	}

	/**
	 * Display the stage map.
	 */
	protected override void DisplayStageMap ()
	{
		// Create the pool of line renderers if it doesn't exist already
		if (lineRendererPool == null) {
			lineRendererPool = new List<GameObject> ();
		}
		lineRendererCount = 0;

		// Display the stage map
		base.DisplayStageMap ();

		// Hide line renderers that aren't needed
		for (int lineRendererIndex = lineRendererCount; lineRendererIndex < lineRendererPool.Count; ++lineRendererIndex) {
			lineRendererPool [lineRendererIndex].SetActive (false);
		}
	}

	/**
	 * Clean up the stage map data.
	 */
	void CleanStageMap ()
	{
		// Make sure we have something to clean
		if (nodeList == null) {
			return;
		}

		// Compute the minimum and maximum position for nodes and control points
		float positionMin = -screenWidth * 0.5f;
		float positionMax = cameraPositionMax + screenWidth * 0.5f;

		// Check all the nodes
		int checkID = CheckID.id;
		int nodeIndex = nodeList.Count;
		while (nodeIndex-- > 0) {

			// Delete any node which is outside the stage map limits
			Node node = nodeList [nodeIndex];
			float position = ConvertMapToCamera (node.position).x;
			if (position < positionMin || position > positionMax) {
				DeleteNode (node);
			} else if (node.pathList != null) {

				// Check all the paths
				foreach (Path path in node.pathList) {
					if (path.innerControlPointList == null || path.checkID == checkID) {
						continue;
					}
					path.checkID = checkID;
					int innerControlPointIndex = path.innerControlPointList.Count;
					while (innerControlPointIndex-- > 0) {

						// Delete any inner control point which is outside the stage map limits
						position = ConvertMapToCamera (path.innerControlPointList [innerControlPointIndex]).x;
						if (position < positionMin || position > positionMax) {
							path.innerControlPointList.RemoveAt (innerControlPointIndex);
						}
					}
				}
			}
		}
	}

	/**
	 * Save the stage map data.
	 */
	void SaveStageMap ()
	{
		// Make sure we have something to save
		if (nodeList == null || nodeList.Count == 0) {
			Debug.LogWarning ("There is nothing to save!");
			return;
		}

		// Create a new file
		try {
			string fileName = "SavedStageMaps/StageMapData-" + System.DateTime.Now.ToString ("yyMMdd-HHmmss") + ".bytes";
			using (FileStream fileStream = new FileStream (fileName, FileMode.Create)) {
				BinaryWriter binaryWriter = new BinaryWriter (fileStream);

				// Save the version information
				binaryWriter.Write (DATA_FILE_HEADER);
				binaryWriter.Write (DATA_FILE_VERSION);

				// Save the configuration
				binaryWriter.Write (screenDesignWidth);
				binaryWriter.Write (screenDesignHeight);
				binaryWriter.Write ((int)backgroundSize);
				binaryWriter.Write ((int)spriteSize);
				binaryWriter.Write ((int)spritePosition);
				binaryWriter.Write (dotAppearDelay);
				binaryWriter.Write (dotAnimationPeriod);
				binaryWriter.Write (dotSpacing);
				binaryWriter.Write (bezierStep);

				// Save the background IDs
				if (backgroundIDList == null) {
					binaryWriter.Write (0);
				} else {
					binaryWriter.Write (backgroundIDList.Count);
					foreach (int backgroundID in backgroundIDList) {
						binaryWriter.Write (backgroundID);
					}
				}

				// Save all the nodes
				int checkID = CheckID.id;
				List<Path> pathList = new List<Path> ();
				binaryWriter.Write (nodeList.Count);
				foreach (Node node in nodeList) {
					binaryWriter.Write (node.id);
					binaryWriter.Write (node.type);
					binaryWriter.Write (node.position.x);
					binaryWriter.Write (node.position.y);

					// Take note of the paths
					if (node.pathList != null) {
						foreach (Path path in node.pathList) {
							if (path.checkID != checkID) {
								path.checkID = checkID;
								pathList.Add (path);
							}
						}
					}
				}

				// Save all the paths
				binaryWriter.Write (pathList.Count);
				foreach (Path path in pathList) {
					binaryWriter.Write (nodeList.IndexOf (path.nodeFirst));
					binaryWriter.Write (nodeList.IndexOf (path.nodeLast));
					if (path.innerControlPointList == null) {
						binaryWriter.Write (0);
					} else {
						binaryWriter.Write (path.innerControlPointList.Count);
						foreach (Vector2 position in path.innerControlPointList) {
							binaryWriter.Write (position.x);
							binaryWriter.Write (position.y);
						}
					}
				}
			}
			Debug.Log ("Saved the stage map as \"" + fileName + "\"!");
			saveMessageDisplayTime = Time.time + SAVE_MESSAGE_DISPLAY_DURATION;
		} catch (System.Exception e) {
			Debug.LogError ("Could not save the stage map!\n" + e);
		}
	}

	/**
	 * Destroy the stage map.
	 */
	protected override void DestroyStageMap ()
	{
		// Destroy the stage map
		base.DestroyStageMap ();

		// Destroy the pool of line renderers
		if (lineRendererPool != null) {
			foreach (GameObject lineRenderer in lineRendererPool) {
				Destroy (lineRenderer);
			}
			lineRendererPool = null;
		}
	}
}
