// Nicolas Robert [Nrx]
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

public class RenderShader : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler
{
	// Camera
	private Camera localCamera;

	// Material
	private Material material;

	// Resolution factor
	private int resolutionFactor = 0;
	private int resolutionFactorMin;
	private int resolutionFactorMax;

	// Frame rate control
	private const float frameRateMeasureDuration = 2.0f;
	private const int frameRateMinimum = 29;
	private float frameTimer;
	private int frameCount;

	// Shader index
	private const int shaderCount = 26;
	private int shaderIndex = 18;

	// GUI
	public Text guiFps;
	public Text guiResolutionFactor;
	public Text guiShaderNumber;
	public Text guiPause;

	// State
	private enum State {RUN, WANT_TO_SLEEP, CAN_SLEEP, SLEEP};
	private State state = State.RUN;

	// Time
	private float time = 0.0f;
	private System.DateTime date = System.DateTime.Now;

	// Mouse (touch)
	private Vector3 mouse = Vector3.zero;

	// Reset the resolution factor
	private void ResolutionFactorReset ()
	{
		// Check the state
		if (state == State.SLEEP) {
			state = State.WANT_TO_SLEEP;
		}

		// Reset the resolution factor
		resolutionFactorMin = 1;
		resolutionFactorMax = 11;
		frameTimer = Time.realtimeSinceStartup + frameRateMeasureDuration;
		frameCount = 0;
	}

	// Change the resolution factor
	public void ResolutionFactorChange (bool increase)
	{
		// Check the state
		if (state != State.RUN) {
			return;
		}

		// Change the expected resolution factor
		resolutionFactorMin = (resolutionFactorMin + resolutionFactorMax) >> 1;
		if (increase) {
			++resolutionFactorMin;
		} else if (resolutionFactorMin > 1) {
			--resolutionFactorMin;
		}
		resolutionFactorMax = resolutionFactorMin;
	}

	// Get the shader
	private Shader ShaderGet ()
	{
		// Get the shader index
		int index = shaderIndex % shaderCount;
		if (index < 0) {
			index += shaderCount;
		}

		// Update the GUI
		guiShaderNumber.text = index.ToString ("'#'0");

		// Return the shader
		return UnityEngine.Shader.Find ("Custom/Shader-" + index);
	}

	// Change the shader
	public void ShaderChange (bool increase)
	{
		// Change the shader
		if (increase) {
			++shaderIndex;
		} else {
			--shaderIndex;
		}
		material.shader = ShaderGet ();

		// Reset the resolution factor
		ResolutionFactorReset ();
	}

	// Toggle the pause
	public void PauseToggle (bool change)
	{
		// Change the state
		if (change) {
			state = (state == State.RUN ? State.WANT_TO_SLEEP : State.RUN);
		}

		// Update the GUI
		guiPause.text = (state == State.RUN ? "II" : ">");
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
	}

	// Handle the end drag events
	public void OnEndDrag (PointerEventData eventData)
	{
		mouse.z = 0.0f;
	}

	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Get the camera
		localCamera = GetComponent <Camera> ();

		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Disable screen dimming
		Screen.sleepTimeout = SleepTimeout.NeverSleep;

		// Set the material
		material = new Material (ShaderGet ());

		// Reset the resolution factor
		ResolutionFactorReset ();

		// Initialize the GUI (pause button)
		PauseToggle (false);
	}

	// Method called by Unity at every frame
	private void Update ()
	{
		// Measure the frame rate
		if (Time.realtimeSinceStartup < frameTimer) {
			++frameCount;
		} else {

			// Update the GUI
			guiFps.text = (frameCount / frameRateMeasureDuration).ToString ("0.0 'fps'");

			// Attempt to automatically set the resolution factor
			if (state == State.RUN && resolutionFactorMin < resolutionFactorMax) {
				if (frameCount < frameRateMinimum * frameRateMeasureDuration) {
					resolutionFactorMin = resolutionFactor + 1;
				} else {
					resolutionFactorMax = resolutionFactor;
				}
			}

			// Reset the frame rate measurement
			frameTimer = Time.realtimeSinceStartup + frameRateMeasureDuration;
			frameCount = 0;
		}

		// Define the expected resolution factor (also update the time and state as needed)
		int resolutionFactorExpected;
		if (state == State.RUN || mouse.z > 0.5f) {
			resolutionFactorExpected = (resolutionFactorMin + resolutionFactorMax) >> 1;
			if (state == State.RUN) {
				time += Time.deltaTime;
				date = System.DateTime.Now;
			} else {
				state = State.WANT_TO_SLEEP;
			}
		} else {
			resolutionFactorExpected = -1;
			if (state == State.WANT_TO_SLEEP) {
				state = State.CAN_SLEEP;
			}
		}
		int divisor = Mathf.Abs (resolutionFactorExpected);

		// Check whether the resolution factor has to change
		if (resolutionFactor != resolutionFactorExpected) {
			resolutionFactor = resolutionFactorExpected;

			// Update the GUI
			guiResolutionFactor.text = resolutionFactor.ToString ("'x'0;('x'0)");

			// Compute the new resolution
			int width = Screen.width / divisor;
			int height = Screen.height / divisor;

			// Either create a new render texture or destroy the existing one
			localCamera.targetTexture = resolutionFactor != 1 ? new RenderTexture (width, height, 0) : null;

			// Update the shader: resolution
			material.SetVector ("iResolution", new Vector3 (width, height, 0.0f));
		}

		// Update the shader: time
		material.SetFloat ("iGlobalTime", time);

		// Update the shader: date
		// Warning: the actual precision of these values has an impact on the shader (at least, in all calculations
		// that use these variables); also, one cannot use "date" in place of "time", because results wouldn't be
		// precise enough...
		material.SetVector ("iDate", new Vector4 ((float) date.Year, (float) date.Month, (float) date.Day, (float) (date.TimeOfDay.TotalMilliseconds / 1000.0)));

		// Update the shader: mouse (touch) position
		material.SetVector ("iMouse", new Vector4 (mouse.x / divisor, mouse.y / divisor, mouse.z, 0.0f));
	}

	// Method called by Unity after a camera finished rendering the scene
	private void OnPostRender ()
	{
		// Check whether the scene needs to be rendered
		if (state != State.SLEEP || !localCamera.targetTexture) {
			Graphics.Blit (null, localCamera.targetTexture, material);
			if (state == State.CAN_SLEEP) {
				state = State.SLEEP;
			}
		}
	}

	// Method to render the scene full screen (to be called from the "OnPostRender" of another camera)
	public void RenderFullScreen ()
	{
		if (localCamera.targetTexture) {
			Graphics.Blit (localCamera.targetTexture, (RenderTexture) null);
		}
	}
}
