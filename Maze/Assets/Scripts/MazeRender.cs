// Nicolas Robert [Nrx]
using UnityEngine;

public partial class Maze
{
	// Camera
	private Camera cameraComponent;

	// GUI
	public UnityEngine.UI.Toggle guiToggleHQ;
	public UnityEngine.UI.Toggle guiToggleAA;
	public UnityEngine.UI.Toggle guiToggleVR;
	public UnityEngine.UI.Text guiResolutionFactor;

	// Mix shader
	public Shader shaderMix;

	// Materials
	public Material materialMaze;
	private Material materialMazeCopy;
	private Material materialMix;

	// Render textures
	private RenderTexture renderTextureNormal;
	private RenderTexture renderTextureOffsetted;

	// Anti-aliasing
	private bool AA = true;

	// Resolution factor
	private int resolutionFactor = 0;
	private int resolutionFactorExpected = 4;

	// Toggle the high quality
	public void ToggleHQ (bool high)
	{
		if (high) {
			materialMazeCopy.EnableKeyword ("QUALITY_HIGH");
		} else {
			materialMazeCopy.DisableKeyword ("QUALITY_HIGH");
		}
	}

	// Toggle the anti-aliasing
	public void ToggleAA (bool state)
	{
		AA = state;
		resolutionFactor = 0;
	}

	// Toggle the VR
	public void ToggleVR (bool state)
	{
		materialMazeCopy.SetFloat ("VR", state ? 1.0f : 0.0f);
	}

	// Change the resolution factor
	public void ChangeResolutionFactor (bool increase)
	{
		if (increase) {
			if (resolutionFactorExpected < 9) {
				++resolutionFactorExpected;
			}
		} else {
			if (resolutionFactorExpected > 1) {
				--resolutionFactorExpected;
			}
		}
	}

	// Initialize the rendering
	private void RenderInitialize ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Disable screen dimming
		Screen.sleepTimeout = SleepTimeout.NeverSleep;

		// Get the camera
		cameraComponent = GetComponent <Camera> ();

		// Make a copy of the maze material, to allow updating it freely without modifying the original material
		materialMazeCopy = (Material) Object.Instantiate (materialMaze);

		// Create the mix material
		materialMix = new Material (shaderMix);

		// Initialize the HQ, AA and VR parameters
		ToggleHQ (guiToggleHQ.isOn);
		ToggleAA (guiToggleAA.isOn);
		ToggleVR (guiToggleVR.isOn);
	}

	// Method called by Unity after a camera finished rendering the scene
	private void OnPostRender ()
	{
		// Check whether the resolution factor has to change
		if (resolutionFactor != resolutionFactorExpected) {
			resolutionFactor = resolutionFactorExpected;

			// Update the GUI
			guiResolutionFactor.text = resolutionFactor.ToString ("'x'0");

			// Compute the new resolution
			float factor = 1.0f / Mathf.Sqrt (resolutionFactor);
			int width = (int) (Screen.width * factor);
			int height = (int) (Screen.height * factor);

			// Create a new render texture (with bilinear filtering)
			renderTextureNormal = AA || resolutionFactor != 1 ? new RenderTexture (width, height, 0) : null;
			renderTextureOffsetted = AA ? new RenderTexture (width + 1, height + 1, 0) : null;

			// Update the shaders
			materialMazeCopy.SetVector ("resolution", new Vector2 (width, height));
			materialMix.SetVector ("resolution", new Vector2 (width, height));
			materialMix.SetTexture ("offsettedTexture", renderTextureOffsetted);
		}

		// Update the shader's parameters
		materialMazeCopy.SetFloat ("time", Time.time);
		materialMazeCopy.SetVector ("headOrientation0", head.orientation.GetColumn (0));
		materialMazeCopy.SetVector ("headOrientation1", head.orientation.GetColumn (1));
		materialMazeCopy.SetVector ("headOrientation2", head.orientation.GetColumn (2));
		materialMazeCopy.SetVector ("headPosition", head.position);
		materialMazeCopy.SetVector ("lightPosition", lightBall.position);
		materialMazeCopy.SetFloat ("ambientIntensity", ambientIntensity);

		// Render the scene to the appropriate render texture
		bool offset = AA && (Time.frameCount & 1) != 0;
		materialMazeCopy.SetFloat ("fragOffset", offset ? 0.5f : 0.0f);
		cameraComponent.targetTexture = offset ? renderTextureOffsetted : renderTextureNormal;
		Graphics.Blit (null, cameraComponent.targetTexture, materialMazeCopy);
	}

	// Method to render the scene full screen (to be called from the "OnPostRender" of another camera)
	public void RenderFullScreen ()
	{
		if (AA) {
			Graphics.Blit (renderTextureNormal, (RenderTexture) null, materialMix);
		} else if (cameraComponent.targetTexture) {
			Graphics.Blit (cameraComponent.targetTexture, (RenderTexture) null);
		}
	}
}
