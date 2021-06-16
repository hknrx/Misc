// Nicolas Robert [Nrx]
using UnityEngine;
using UnityEngine.UI;

public class TilePhysics : MonoBehaviour
{
	// Material
	public Material material;
	private Material materialCopy;

	// Positioning
	private Vector2 tileMapTransform = Vector2.right;
	private Vector2 tileMapTranslate = Vector2.zero;

	// Physics (public)
	public Rect tileMapLimits = new Rect (0.0f, 0.0f, 0.0f, 0.0f);
	public float tileMapMass = 1.0f;
	public float tileMapMoment = 1.0f;
	public float tileMapFriction = 1.0f;
	public float tileMapSpringStiffness = 1.0f;
	public float tileMapSpringDamping = 1.0f;
	public float tileMapScale = 1.0f;
	public float tileMapScaleMin = 1.0f;
	public float tileMapScaleMax = 1.0f;
	public float tileMapScaleFriction = 1.0f;
	public float tileMapScaleImpulse = 0.0f;
	public enum TileMapModeScaling {FREE, BOUNDED, LOCKED, COUNT};
	public enum TileMapModeRotation {FREE, SNAP90, LOCKED, COUNT};
	public enum TileMapModeTranslation {FREE, BOUNDED, COUNT};
	public enum TileMapModeShader {BASIC, REPEAT, CUT, COUNT};
	public TileMapModeScaling tileMapModeScaling = TileMapModeScaling.BOUNDED;
	public TileMapModeRotation tileMapModeRotation = TileMapModeRotation.FREE;
	public TileMapModeTranslation tileMapModeTranslation = TileMapModeTranslation.BOUNDED;
	public TileMapModeShader tileMapModeShader = TileMapModeShader.CUT;

	// Physics (private)
	private const float TILE_MAP_SCALE_ERROR_FACTOR = 0.05f;
	private float? tileMapScaleTarget = null;
	private float tileMapScaleSpeed = 0.0f;
	private float tileMapAngle = 0.0f;
	private float tileMapAngleSpeed = 0.0f;
	private Vector2 tileMapOrigin = Vector2.zero;
	private Vector2 tileMapSpeed = Vector2.zero;

	// Inputs
	private const float TOUCH_FILTER = 0.5f;
	private const float TOUCH_DOUBLE_DURATION = 0.33f;
	private Vector2 touchOld0;
	private Vector2 touchOld1;
	private enum TouchType {NO_TOUCH, SINGLE_TOUCH, MULTI_TOUCH};
	private float touchTime;

	// GUI
	public GameObject guiPanel;
	private Text guiButtonTextScaling;
	private Text guiButtonTextRotation;
	private Text guiButtonTextTranslation;
	private Text guiButtonTextShader;

	// Initialize the shader (define the variant to use)
	// - "BASIC" (default): doesn't do any special check on the tile map, so it basically respect the texture's wrap mode
	// - "REPEAT": repeats the tile map (useful when it is a NPOT texture, for which repeat isn't supported on some devices)
	// - "CUT": doesn't display anything outside of the tile map (this is different from clamping, which repeats the border tiles)
	//
	// Warning: the Unity editor keeps keywords that have been previously enabled; one needs to explicitly disable the currently used keyword before changing it
	private void ShaderInitialize ()
	{
		switch (tileMapModeShader)
		{
			case TileMapModeShader.BASIC:
				materialCopy.EnableKeyword ("BASIC");
				materialCopy.DisableKeyword ("REPEAT");
				materialCopy.DisableKeyword ("CUT");
				break;
			case TileMapModeShader.REPEAT:
				materialCopy.DisableKeyword ("BASIC");
				materialCopy.EnableKeyword ("REPEAT");
				materialCopy.DisableKeyword ("CUT");
				break;
			case TileMapModeShader.CUT:
				materialCopy.DisableKeyword ("BASIC");
				materialCopy.DisableKeyword ("REPEAT");
				materialCopy.EnableKeyword ("CUT");
				break;
		}
	}

	// Initialize the GUI
	private void GuiInitialize ()
	{
		foreach (Button button in guiPanel.GetComponentsInChildren <Button> ())
		{
			switch (button.name)
			{
				case "tileMapModeScaling":
					guiButtonTextScaling = button.GetComponentInChildren <Text> ();
					guiButtonTextScaling.text = tileMapModeScaling.ToString ();
					break;
				case "tileMapModeRotation":
					guiButtonTextRotation = button.GetComponentInChildren <Text> ();
					guiButtonTextRotation.text = tileMapModeRotation.ToString ();
					break;
				case "tileMapModeTranslation":
					guiButtonTextTranslation = button.GetComponentInChildren <Text> ();
					guiButtonTextTranslation.text = tileMapModeTranslation.ToString ();
					break;
				case "tileMapShader":
					guiButtonTextShader = button.GetComponentInChildren <Text> ();
					guiButtonTextShader.text = tileMapModeShader.ToString ();
					break;
			}
		}
	}

	// Handle the scaling button taps
	public void GuiButtonTapScaling ()
	{
		tileMapModeScaling = (TileMapModeScaling)(((int)tileMapModeScaling + 1) % (int)TileMapModeScaling.COUNT);
		guiButtonTextScaling.text = tileMapModeScaling.ToString ();
		tileMapScaleTarget = null;
		tileMapScaleSpeed = 0.0f;
	}

	// Handle the rotation button taps
	public void GuiButtonTapRotation ()
	{
		tileMapModeRotation = (TileMapModeRotation)(((int)tileMapModeRotation + 1) % (int)TileMapModeRotation.COUNT);
		guiButtonTextRotation.text = tileMapModeRotation.ToString ();
		tileMapAngleSpeed = 0.0f;
	}

	// Handle the translation button taps
	public void GuiButtonTapTranslation ()
	{
		tileMapModeTranslation = (TileMapModeTranslation)(((int)tileMapModeTranslation + 1) % (int)TileMapModeTranslation.COUNT);
		guiButtonTextTranslation.text = tileMapModeTranslation.ToString ();
		tileMapSpeed = Vector2.zero;
	}

	// Handle the shader button taps
	public void GuiButtonTapShader ()
	{
		tileMapModeShader = (TileMapModeShader)(((int)tileMapModeShader + 1) % (int)TileMapModeShader.COUNT);
		guiButtonTextShader.text = tileMapModeShader.ToString ();
		ShaderInitialize ();
	}

	// Toggle the display of the control panel
	public void GuiPanelToggle ()
	{
		guiPanel.SetActive (!guiPanel.activeSelf);
	}

	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Disable screen dimming
		Screen.sleepTimeout = SleepTimeout.NeverSleep;

		// Copy the material to freely modify it if needed
		materialCopy = (Material)Object.Instantiate (material);

		// Initialize the GUI
		GuiInitialize ();

		// Initialize the shader (define the variant to use)
		ShaderInitialize ();
	}

	// Compute the force needed to constrain the scale factor
	private float ComputeScalingForce (TouchType touchType)
	{
		// Check whether the scale factor has a target value
		if (tileMapScaleTarget.HasValue)
		{
			// Check whether the target value is reached
			float error = tileMapScaleTarget.Value - tileMapScale;
			if (Mathf.Abs (error) > tileMapScale * TILE_MAP_SCALE_ERROR_FACTOR)
			{
				// Spring force
				return error * tileMapSpringStiffness - tileMapScaleSpeed * tileMapSpringDamping;
			}
			tileMapScaleTarget = null;
		}

		// Check whether the scale factor shall be bounded
		if (tileMapModeScaling == TileMapModeScaling.BOUNDED)
		{
			// Check whether the scale factor is within the allowed range
			if (tileMapScale < tileMapScaleMin)
			{
				// Spring force
				return (tileMapScaleMin - tileMapScale) * tileMapSpringStiffness - tileMapScaleSpeed * tileMapSpringDamping;
			}
			if (tileMapScale > tileMapScaleMax)
			{
				// Spring force
				return (tileMapScaleMax - tileMapScale) * tileMapSpringStiffness - tileMapScaleSpeed * tileMapSpringDamping;
			}
		}

		// Check whether the system is under control
		if (touchType == TouchType.MULTI_TOUCH)
		{
			// No constrain
			return 0.0f;
		}

		// Apply a friction force
		return -tileMapScaleSpeed * tileMapScaleFriction;
	}

	// Compute the torque needed to constrain the rotation
	private float ComputeTorque (TouchType touchType)
	{
		// Check whether the system is under control
		if (touchType == TouchType.MULTI_TOUCH)
		{
			// No constrain
			return 0.0f;
		}

		// Check whether the rotation shall be constrained
		if (tileMapModeRotation == TileMapModeRotation.SNAP90)
		{
			// Apply a spring force so that the angle is a multiple of 90 degrees
			float tileMapAngleTarget = (Mathf.PI * 0.5f) * Mathf.Floor (tileMapAngle / (Mathf.PI * 0.5f) + 0.5f);
			return (tileMapAngleTarget - tileMapAngle) * tileMapSpringStiffness - tileMapAngleSpeed * tileMapSpringDamping;
		}

		// Apply a friction force
		return -tileMapAngleSpeed * tileMapFriction;
	}

	// Compute the force needed to constrain the translation
	private Vector2 ComputeTranslationalForce (TouchType touchType)
	{
		// Check whether the translation shall be bounded
		if (tileMapModeTranslation == TileMapModeTranslation.BOUNDED)
		{
			// Get the position of the center of the screen in the tile map space
			Vector2 size = new Vector2 (Screen.width, Screen.height);
			Vector2 error = new Vector2
			(
				(tileMapTransform.x * size.x - tileMapTransform.y * size.y) * 0.5f + tileMapTranslate.x,
				(tileMapTransform.y * size.x + tileMapTransform.x * size.y) * 0.5f + tileMapTranslate.y
			);

			// Compute the bounds of the tile map area in which the center of the screen shall stay
			// The goal here is to avoid seeing parts outside the tile map
			Vector2 absTransform = new Vector2 (Mathf.Abs (tileMapTransform.x), Mathf.Abs (tileMapTransform.y));
			size = new Vector2
			(
				Mathf.Min (absTransform.x * size.x + absTransform.y * size.y, tileMapLimits.width),
				Mathf.Min (absTransform.y * size.x + absTransform.x * size.y, tileMapLimits.height)
			);
			Rect bounds = new Rect
			(
				tileMapLimits.x + size.x * 0.5f,
				tileMapLimits.y + size.y * 0.5f,
				tileMapLimits.width - size.x,
				tileMapLimits.height - size.y
			);

			// Check whether the center of the screen is within the defined area
			bool spring = false;
			if (error.x < bounds.xMin)
			{
				spring = true;
				error.x -= bounds.xMin;
			}
			else if (error.x > bounds.xMax)
			{
				spring = true;
				error.x -= bounds.xMax;
			}
			else
			{
				error.x = 0.0f;
			}
			if (error.y < bounds.yMin)
			{
				spring = true;
				error.y -= bounds.yMin;
			}
			else if (error.y > bounds.yMax)
			{
				spring = true;
				error.y -= bounds.yMax;
			}
			else
			{
				error.y = 0.0f;
			}

			// In case the center of the screen is outside the defined area, apply a spring force to pull it back
			if (spring)
			{
				// Transform the error to be in the screen space
				error = new Vector2
				(
					tileMapTransform.x * error.x + tileMapTransform.y * error.y,
					tileMapTransform.x * error.y - tileMapTransform.y * error.x
				) / tileMapTransform.sqrMagnitude;

				// Spring force
				return error * tileMapSpringStiffness - tileMapSpeed * tileMapSpringDamping;
			}
		}

		// Check whether the system is under control
		if (touchType == TouchType.NO_TOUCH)
		{
			// Apply a friction force
			return -tileMapSpeed * tileMapFriction;
		}

		// No constrain
		return Vector2.zero;
	}

	// Method called by Unity at every frame
	private void Update ()
	{
		// Handle the inputs
		TouchType touchType;
		if (Input.touchCount > 1)
		{
			// Multitouch
			touchType = TouchType.MULTI_TOUCH;
			Vector2 touchNew0 = Input.touches [0].position;
			Vector2 touchNew1 = Input.touches [1].position;
			if (Input.touches [0].phase != TouchPhase.Began && Input.touches [1].phase != TouchPhase.Began)
			{
				// Apply a basic filter on the inputs
				touchNew0 = touchOld0 + (touchNew0 - touchOld0) * TOUCH_FILTER;
				touchNew1 = touchOld1 + (touchNew1 - touchOld1) * TOUCH_FILTER;

				// Set the origin
				tileMapOrigin = (touchOld0 + touchOld1) * 0.5f;

				// Compute the scaling, rotational and translational speeds
				Vector2 touchOld = touchOld1 - touchOld0;
				Vector2 touchNew = touchNew1 - touchNew0;
				tileMapScaleSpeed = (tileMapScale * Mathf.Sqrt ((touchOld.x * touchOld.x + touchOld.y * touchOld.y) / (touchNew.x * touchNew.x + touchNew.y * touchNew.y)) - tileMapScale) / Time.deltaTime;
				tileMapAngleSpeed = Mathf.Atan2 (touchNew.x * touchOld.y - touchNew.y * touchOld.x, touchNew.x * touchOld.x + touchNew.y * touchOld.y) / Time.deltaTime;
				tileMapSpeed = ((touchNew0 + touchNew1) * 0.5f - tileMapOrigin) / Time.deltaTime;
			}

			// Record the current touch positions
			if (Input.touches [0].phase != TouchPhase.Ended && Input.touches [0].phase != TouchPhase.Canceled)
			{
				touchOld0 = touchNew0;
				touchOld1 = touchNew1;
			}
			else
			{
				touchOld0 = touchNew1;
			}
		}
		else if (Input.touchCount == 1 || Input.GetMouseButton (0))
		{
			// Single touch
			touchType = TouchType.SINGLE_TOUCH;
			Vector2 touchNew0 = Input.touchCount == 1 ? Input.touches [0].position : (Vector2) Input.mousePosition;
			if (Input.touchCount == 1 ? Input.touches [0].phase != TouchPhase.Began : !Input.GetMouseButtonDown (0))
			{
				// Apply a basic filter on the input
				touchNew0 = touchOld0 + (touchNew0 - touchOld0) * TOUCH_FILTER;

				// Set the origin
				tileMapOrigin = touchOld0;

				// Compute the translational speed
				tileMapSpeed = (touchNew0 - tileMapOrigin) / Time.deltaTime;
			}
			else
			{
				// Double touch?
				if (Time.time < touchTime + TOUCH_DOUBLE_DURATION)
				{
					// Set the origin
					tileMapOrigin = touchNew0;

					// Check the scale factor
					if (tileMapScale > tileMapScaleMin * (1.0f + TILE_MAP_SCALE_ERROR_FACTOR))
					{
						// Update the scaling speed (apply an impulse that depends on the current scale factor)
						tileMapScaleSpeed -= tileMapScale * tileMapScaleImpulse / tileMapMass;
					}
					else
					{
						// Reset the scale target
						tileMapScaleTarget = 1.0f;
					}
				}
				touchTime = Time.time;
			}

			// Record the current touch position
			touchOld0 = touchNew0;
		}
		else
		{
			// No control
			touchType = TouchType.NO_TOUCH;
		}

		// Prepare the correction of the translation vector
		Vector2 tileMapTranslateCorrection = new Vector2
		(
			tileMapTransform.x * tileMapOrigin.x - tileMapTransform.y * tileMapOrigin.y,
			tileMapTransform.y * tileMapOrigin.x + tileMapTransform.x * tileMapOrigin.y
		);

		// Update speeds and positions
		if (tileMapModeScaling != TileMapModeScaling.LOCKED)
		{
			tileMapScaleSpeed += ComputeScalingForce (touchType) * Time.deltaTime / tileMapMass;
			tileMapScale += tileMapScaleSpeed * Time.deltaTime;
		}
		if (tileMapModeRotation != TileMapModeRotation.LOCKED)
		{
			tileMapAngleSpeed += ComputeTorque (touchType) * Time.deltaTime / tileMapMoment;
			tileMapAngle += tileMapAngleSpeed * Time.deltaTime;
		}
		tileMapSpeed += ComputeTranslationalForce (touchType) * Time.deltaTime / tileMapMass;
		tileMapOrigin += tileMapSpeed * Time.deltaTime;

		// Update the transformation matrix and translation vector
		tileMapTransform = new Vector2 (tileMapScale * Mathf.Cos (tileMapAngle), tileMapScale * Mathf.Sin (tileMapAngle));
		tileMapTranslate += tileMapTranslateCorrection - new Vector2
		(
			tileMapTransform.x * tileMapOrigin.x - tileMapTransform.y * tileMapOrigin.y,
			tileMapTransform.y * tileMapOrigin.x + tileMapTransform.x * tileMapOrigin.y
		);

		// Update the shader (set the transformation matrix and translation vector)
		materialCopy.SetVector ("transform", new Vector4 (tileMapTransform.x, tileMapTransform.y, -tileMapTransform.y, tileMapTransform.x));
		materialCopy.SetVector ("translate", tileMapTranslate);
	}

	// Method called by Unity after a camera finished rendering the scene
	private void OnPostRender ()
	{
		Graphics.Blit (null, null, materialCopy);
	}
}
