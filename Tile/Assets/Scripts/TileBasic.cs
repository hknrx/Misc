// Nicolas Robert [Nrx]
using UnityEngine;

public class TileBasic : MonoBehaviour
{
	// Material
	public Material material;
	private Material materialCopy;

	// Positioning
	private Vector2 tileMapTransform = Vector2.right;
	private Vector2 tileMapTranslate = Vector2.zero;

	// Inputs
	private Vector2 touchOld0;
	private Vector2 touchOld1;

	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Disable screen dimming
		Screen.sleepTimeout = SleepTimeout.NeverSleep;

		// Copy the material to freely modify it if needed
		materialCopy = (Material)Object.Instantiate (material);

		// Initialize the shader (define the variant to use):
		// - "BASIC" (default): doesn't do any special check on the tile map, so it basically respect the texture's wrap mode
		// - "REPEAT": repeats the tile map (useful when it is a NPOT texture, for which repeat isn't supported on some devices)
		// - "CUT": doesn't display anything outside of the tile map (this is different from clamping, which repeats the border tiles)
		//
		// Warning: the Unity editor keeps keywords that have been previously enabled; one needs to explicitly disable the currently used keyword before changing it
		materialCopy.EnableKeyword ("REPEAT");
		materialCopy.DisableKeyword ("BASIC");
		materialCopy.DisableKeyword ("CUT");
	}

	// Method called by Unity at every frame
	private void Update ()
	{
		// Handle the inputs
		if (Input.touchCount > 1)
		{
			// Multitouch
			Vector2 touchNew0 = Input.touches [0].position;
			Vector2 touchNew1 = Input.touches [1].position;
			if (Input.touches [0].phase != TouchPhase.Began && Input.touches [1].phase != TouchPhase.Began)
			{
				// Translation, rotation and scale
				Vector2 touchOld = touchOld1 - touchOld0;
				Vector2 touchNew = touchNew1 - touchNew0;
				Vector2 k = new Vector2
				(
					touchOld.x * touchNew.x + touchOld.y * touchNew.y,
					touchOld.x * touchNew.y - touchOld.y * touchNew.x
				);
				tileMapTranslate += new Vector2
				(
					tileMapTransform.x * touchOld0.x - tileMapTransform.y * touchOld0.y,
					tileMapTransform.y * touchOld0.x + tileMapTransform.x * touchOld0.y
				);
				tileMapTransform = new Vector2
				(
					tileMapTransform.x * k.x + tileMapTransform.y * k.y,
					tileMapTransform.y * k.x - tileMapTransform.x * k.y
				) / (touchNew.x * touchNew.x + touchNew.y * touchNew.y);
				tileMapTranslate -= new Vector2
				(
					tileMapTransform.x * touchNew0.x - tileMapTransform.y * touchNew0.y,
					tileMapTransform.y * touchNew0.x + tileMapTransform.x * touchNew0.y
				);
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
			Vector2 touchNew0 = Input.touchCount == 1 ? Input.touches [0].position : (Vector2) Input.mousePosition;
			if (Input.touchCount == 1 ? Input.touches [0].phase != TouchPhase.Began : !Input.GetMouseButtonDown (0))
			{
				// Translation
				Vector2 d = touchOld0 - touchNew0;
				tileMapTranslate += new Vector2
				(
					tileMapTransform.x * d.x - tileMapTransform.y * d.y,
					tileMapTransform.y * d.x + tileMapTransform.x * d.y
				);
			}

			// Record the current touch position
			touchOld0 = touchNew0;
		}

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
