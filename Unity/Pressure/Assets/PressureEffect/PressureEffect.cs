// Nicolas Robert [Nrx]
using UnityEngine;

public class PressureEffect : MonoBehaviour
{
	// Material
	public Material material;
	private Material materialCopy;

	// Timing and colors
	public float timePressed;
	public Color colorTime0;
	public float time1;
	public Color colorTime1;
	public float time2;
	public Color colorTime2;
	private float timerColor;
	private float timerPressed;

	// Parameters
	public bool smoothing;
	public bool lighting;
	private int hash;

	// Check whether a parameter has changed (e.g. when playing with the Unity editor)
	private void ParametersCheck ()
	{
		// Compute a simple hash to check all values at once
		int hashCurrent = Screen.width + Screen.height * 37 + (smoothing ? 41 : 0) + (lighting ? 43 : 0);
		if (hash == hashCurrent)
		{
			return;
		}
		hash = hashCurrent;

		// Set the shader
		materialCopy.SetVector ("screenResolution", new Vector2 (Screen.width, Screen.height));
		if (smoothing)
		{
			materialCopy.EnableKeyword ("SMOOTH_ON");
		}
		else
		{
			materialCopy.DisableKeyword ("SMOOTH_ON");
		}
		if (lighting)
		{
			materialCopy.EnableKeyword ("LIGHT_ON");
		}
		else
		{
			materialCopy.DisableKeyword ("LIGHT_ON");
		}
	}

	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Initialize the shader
		materialCopy = (Material)Object.Instantiate (material);
		ParametersCheck ();
	}

	// Define the color to use at a given time
	private Color ColorAtTime (float t)
	{
		return Color.Lerp (Color.Lerp (colorTime0, colorTime1, t / time1), colorTime2, (t - time1) / (time2 - time1));
	}

	// Method called by Unity at every frame
	private void Update ()
	{
		// Check whether a parameter has changed
		ParametersCheck ();

		// Process the inputs and update the shader
		// Note: we should better check the touch events... but to use the mouse API is ok in this case
		if (Input.GetMouseButtonDown (0))
		{
			timerColor = 0.0f;
			materialCopy.SetVector ("touchOrigin", Input.mousePosition);
		}
		else if (Input.GetMouseButton (0))
		{
			timerColor += Time.deltaTime;
			timerPressed = Mathf.Min (timePressed, timerPressed + Time.deltaTime);
			materialCopy.SetVector ("touchCurrent", Input.mousePosition);
		}
		else
		{
			timerPressed = Mathf.Max (0.0f, timerPressed - Time.deltaTime);
		}
		materialCopy.SetFloat ("touchControl", timerPressed / timePressed);
		materialCopy.SetVector ("gridColorCenter", ColorAtTime (timerColor));
		materialCopy.SetVector ("gridColorBorder", ColorAtTime (timerColor - time1));
	}

	// Method called by Unity after all rendering is complete to render image
	// TODO: Check how to process just part of the screen (using something equivalent to "glScissor"), the idea being
	// to solely modify the touched area, as nothing else changes on the screen... For now, we simply disable the effect
	// when it doesn't do anything.
	private void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
		if (lighting || timerPressed > 0.0f)
		{
			Graphics.Blit (source, destination, materialCopy);
		}
		else
		{
			Graphics.Blit (source, destination);
		}
	}
}
