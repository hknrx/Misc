using UnityEngine;
using System.Collections.Generic;

public class Controller : MonoBehaviour
{
	// Screen
	const float SCREEN_DESIGN_WIDTH = 1136.0f;
	const float SCREEN_DESIGN_HEIGHT = 640.0f;
	public Material backgroundMaterial;
	float horizontalZoomFactor;

	// Belt conveyor
	const float ITEM_WAGON_LENGTH = 40.0f;
	const float LINK_WAGON_LENGTH = 20.0f;
	const float CONNECTOR_WAGON_LENGTH = 120.0f;
	const float ITEM_SHIFT_Y = 20.0f;
	static readonly Vector2[] conveyorBelt = new Vector2 []
	{
		new Vector2 (0, 215),
		new Vector2 (140, 215),
		new Vector2 (140, 450),
		new Vector2 (996, 450),
		new Vector2 (996, 190),
		new Vector2 (1136, 190),
	};
	static readonly Vector3 connectorScale = new Vector3 (1.0f, 30.0f, 1.0f);
	public float conveyorSpeed = 1.0f;
	float conveyorBeltOffset;

	// Sprites
	List<GameObject> itemSpritePool;
	int itemSpriteCount;
	List<GameObject> connectorSpritePool;
	int connectorSpriteCount;

	/**
	 * Method called by Unity after that the GameObject has been instantiated.
	 * This is the place where we initialize everything.
	 */
	void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Setup the display
		GetComponent<Camera>().orthographicSize = SCREEN_DESIGN_HEIGHT * 0.5f;
		horizontalZoomFactor = (Screen.width * SCREEN_DESIGN_HEIGHT) / (SCREEN_DESIGN_WIDTH * Screen.height);

		// Fix the conveyor belt end positions to make sure sprites are displayed properly
		// Note: Here we assume that the 1st point is on the left side of the screen, and the last on the right...
		float itemWidth = Sprite.GetSize ("Item0").x / horizontalZoomFactor;
		float itemBound = (itemWidth + ITEM_WAGON_LENGTH) / 2;

		float connectorWidth = Sprite.GetSize ("BeltConnector").x / horizontalZoomFactor;
		float connectorBound = (connectorWidth + CONNECTOR_WAGON_LENGTH) / 2;

		float boundLeft = Mathf.Max (itemBound, connectorBound + ITEM_WAGON_LENGTH + LINK_WAGON_LENGTH);
		float boundRight = Mathf.Max (itemBound, connectorBound);

		conveyorBelt [0].x = -boundLeft;
		conveyorBelt [conveyorBelt.Length - 1].x = SCREEN_DESIGN_WIDTH + boundRight;

		// Create the background
		Sprite.CreateOrModify (null, backgroundMaterial, Vector3.zero, new Vector2 (SCREEN_DESIGN_WIDTH, SCREEN_DESIGN_HEIGHT)).transform.localScale = new Vector3 (horizontalZoomFactor, 1, 1);

		// Create the pools of sprites
		itemSpritePool = new List<GameObject> ();
		connectorSpritePool = new List<GameObject> ();
	}

	/**
	 * Convert a position in the stage space to the camera space.
	 *
	 * @param position Position in the stage space.
	 * @param distance Distance to the camera.
	 * @return Position in the camera space.
	 */
	Vector3 ConvertStageToCamera (Vector2 position, float distance)
	{
		return new Vector3 (horizontalZoomFactor * (position.x - SCREEN_DESIGN_WIDTH * 0.5f), SCREEN_DESIGN_HEIGHT * 0.5f - position.y, distance);
	}

	/**
	 * Get the name of an item sprite using the index of the item.
	 * Note: this method should implement the actual game logic...
	 *
	 * @param itemIndex Index of the item.
	 * @return Name of the sprite, or null if there is no item at this index.
	 */
	string GetSpriteName (int itemIndex)
	{
		if ((itemIndex & 3) == 3) {
			return null;
		}
		if ((itemIndex & 12) != 12) {
			return "Item" + ((itemIndex & 12) >> 2);
		}
		return "Item" + (itemIndex & 3);
	}

	/**
	 * Method called by Unity at every update step of the display.
	 */
	void Update ()
	{
		// Reset the sprite pools
		itemSpriteCount = 0;
		connectorSpriteCount = 0;

		// Make the conveyor belt move
		conveyorBeltOffset += conveyorSpeed;

		// Display the conveyor belt
		int itemIndex = -Mathf.FloorToInt (conveyorBeltOffset / (ITEM_WAGON_LENGTH + LINK_WAGON_LENGTH * 2 + CONNECTOR_WAGON_LENGTH));
		float distanceNextWheel = conveyorBeltOffset + itemIndex * (ITEM_WAGON_LENGTH + LINK_WAGON_LENGTH * 2 + CONNECTOR_WAGON_LENGTH);
		int wagonType = 0;
		Vector2 previousBeltPosition = conveyorBelt [0];
		Vector2 previousWheelPosition = previousBeltPosition;
		for (int conveyorBeltIndex = 1; conveyorBeltIndex < conveyorBelt.Length; ++conveyorBeltIndex) {

			// Compute the belt segment
			Vector2 beltPosition = conveyorBelt [conveyorBeltIndex];
			Vector2 beltSegment = beltPosition - previousBeltPosition;
			float beltLength = beltSegment.magnitude;

			// Put some items, having a constant distance between two successive items
			while (distanceNextWheel <= beltLength) {

				// Compute the position of the wheel
				Vector2 wheelPosition = previousBeltPosition + beltSegment * distanceNextWheel / beltLength;
				if ((wagonType & 1) == 0) {

					// Compute the distance to the next wheel
					if ((wagonType & 2) == 0) {
						distanceNextWheel += ITEM_WAGON_LENGTH;
					} else {
						distanceNextWheel += CONNECTOR_WAGON_LENGTH;
					}
				} else {

					// Display the item or connector, reusing an existing sprite or creating a new one as needed
					GameObject sprite;
					if ((wagonType & 2) == 0) {

						// Display an item
						string spriteName = GetSpriteName (itemIndex);
						if (spriteName != null) {
							Vector2 wagonPosition = (wheelPosition + previousWheelPosition) / 2;
							Vector3 spritePosition = ConvertStageToCamera (wagonPosition, -1.0f);
							spritePosition.y += ITEM_SHIFT_Y;
							spritePosition.z += spritePosition.y * 0.001f;
							if (itemSpriteCount < itemSpritePool.Count) {
								sprite = itemSpritePool [itemSpriteCount];
								Sprite.CreateOrModify (sprite, spriteName, spritePosition);
								sprite.SetActive (true);
							} else {
								sprite = Sprite.CreateOrModify (null, spriteName, spritePosition);
								itemSpritePool.Add (sprite);
							}
							++itemSpriteCount;
						}

						// Next item...
						++itemIndex;
					} else {

						// Display a connector
						Vector2 wagonPosition = (wheelPosition + previousWheelPosition) / 2;
						Vector3 spritePosition = ConvertStageToCamera (wagonPosition, 1.0f);
						if (connectorSpriteCount < connectorSpritePool.Count) {
							sprite = connectorSpritePool [connectorSpriteCount];
							sprite.transform.position = spritePosition;
							sprite.SetActive (true);
						} else {
							sprite = Sprite.CreateOrModify (null, "BeltConnector", spritePosition);
							sprite.transform.localScale = connectorScale;
							connectorSpritePool.Add (sprite);
						}
						sprite.transform.localRotation = Quaternion.Euler (0.0f, 0.0f, Mathf.Atan2 (previousWheelPosition.y - wheelPosition.y, wheelPosition.x - previousWheelPosition.x) * Mathf.Rad2Deg);
						++connectorSpriteCount;
					}

					// Compute the distance to the next wheel
					distanceNextWheel += LINK_WAGON_LENGTH;
				}

				// Record the position of the current wheel
				previousWheelPosition = wheelPosition;

				// Next wagon...
				++wagonType;
			}

			// Handle the next belt
			distanceNextWheel -= beltLength;
			previousBeltPosition = beltPosition;
		}

		// Hide sprites that aren't needed
		for (int spriteIndex = itemSpriteCount; spriteIndex < itemSpritePool.Count; ++spriteIndex) {
			itemSpritePool [spriteIndex].SetActive (false);
		}
		for (int spriteIndex = connectorSpriteCount; spriteIndex < connectorSpritePool.Count; ++spriteIndex) {
			connectorSpritePool [spriteIndex].SetActive (false);
		}
	}
}
