// Nicolas Robert [Nrx]

using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

public class RenderScene : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler
{
	// Camera
	private Camera localCamera;

	// Shaders
	private int shaderSceneId = 0;
	public Shader [] shaderScene;
	public Shader shaderMix;

	// Materials
	private Material materialScene;
	private Material materialMix;

	// Render textures
	private RenderTexture renderTextureNormal;
	private RenderTexture renderTextureOffset;

	// Anti-aliasing
	public bool antiAliasing = true;
	private const int renderTextureSizeIncrement = 1; // must be 1 (for fragOffset to be half a pixel)
	private const float fragOffset = 0.5f * (float) renderTextureSizeIncrement;

	// Resolution factor
	private int resolutionFactor = 0;
	private int resolutionFactorExpected = 4;

	// GUI
	public Text guiResolutionFactor;
	public Text guiPause;

	// Time & pause
	private float time = 0.0f;
	private bool pause = false;
	private const int refreshTimes = 2; // should be 2 (to refresh both render textures)
	private int refreshCount = refreshTimes;

	// Mouse (touch)
	private Vector3 mouse = Vector3.zero;

	// Toggle the anti-aliasing
	public void AntiAliasingToggle (bool state)
	{
		antiAliasing = state;
		refreshCount = refreshTimes;
	}

	// Change the scene shader
	public void ShaderSceneChange ()
	{
		materialScene.shader = shaderScene [++shaderSceneId % shaderScene.Length];
		refreshCount = refreshTimes;
	}

	// Change the resolution factor
	public void ResolutionFactorChange (bool increase)
	{
		if (increase) {
			++resolutionFactorExpected;
		} else if (resolutionFactorExpected > 1) {
			--resolutionFactorExpected;
		}
	}

	// Toggle the pause
	public void PauseToggle (bool change)
	{
		// Change the state
		if (change) {
			pause = !pause;
		}

		// Update the GUI
		guiPause.text = (pause ? ">" : "II");
	}

	// Handle the begin drag event
	public void OnBeginDrag (PointerEventData eventData)
	{
		mouse.z = 1.0f;
	}

	// Handle the drag event
	public void OnDrag (PointerEventData eventData)
	{
		mouse.x = eventData.position.x;
		mouse.y = eventData.position.y;
		refreshCount = refreshTimes;
	}

	// Handle the end drag event
	public void OnEndDrag (PointerEventData eventData)
	{
		mouse.z = 0.0f;
	}

	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Get the camera
		localCamera = GetComponent <Camera> ();

		// Set the materials
		materialScene = new Material (shaderScene [shaderSceneId]);
		materialMix = new Material (shaderMix);

		// Initialize the mix shader: fragment offset
		materialMix.SetFloat ("fragOffset", fragOffset);

		// Initialize the GUI (pause button)
		PauseToggle (false);
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
			int width = Screen.width / resolutionFactor;
			int height = Screen.height / resolutionFactor;

			// Create new render textures
			// Note: the filtering mode of these render textures needs to be "bilinear" (which is the default value, normally)
			renderTextureNormal = new RenderTexture (width, height, 0);
			renderTextureOffset = new RenderTexture (width + renderTextureSizeIncrement, height + renderTextureSizeIncrement, 0);

			// Update both the scene and mix shaders: resolution
			materialScene.SetVector ("iResolution", new Vector3 (width, height, 0.0f));
			materialMix.SetVector ("resolution", new Vector2 (width, height));

			// Update the mix shader: second render texture
			materialMix.SetTexture ("otherTexture", renderTextureOffset);

			// Make sure to render the scene
			refreshCount = refreshTimes;
		}

		// Update the scene shader: time
		if (!pause) {
			time += Time.deltaTime;
			refreshCount = refreshTimes;
		}
		materialScene.SetFloat ("iGlobalTime", time);

		// Update the scene shader: mouse (touch) position
		materialScene.SetVector ("iMouse", new Vector4 (mouse.x / resolutionFactor, mouse.y / resolutionFactor, mouse.z, 0.0f));

		// Check whether the scene needs to be rendered
		if (refreshCount > 0) {
			--refreshCount;

			// Assign the target texture (swap the render textures)
			bool offset = antiAliasing && (Time.frameCount & 1) != 0;
			localCamera.targetTexture = offset ? renderTextureOffset : renderTextureNormal;

			// Update the scene shader: fragment offset
			materialScene.SetFloat ("fragOffset", offset ? fragOffset : 0.0f);

			// Render the scene to the appropriate render texture
			Graphics.Blit (null, localCamera.targetTexture, materialScene);
		}
	}

	// Method to render the scene full screen (to be called from the "OnPostRender" of another camera)
	public void RenderFullScreen ()
	{
		if (antiAliasing) {
			Graphics.Blit (renderTextureNormal, (RenderTexture) null, materialMix);
		} else {
			Graphics.Blit (renderTextureNormal, (RenderTexture) null);
		}
	}
}
