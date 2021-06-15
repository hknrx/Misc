// Nicolas Robert [Nrx]
using UnityEngine;

public class ColorNrx : MonoBehaviour
{
	// Resolution factor
	public int resolutionFactor = 4;

	// Camera
	#pragma warning disable 108
	private Camera camera;
	#pragma warning restore 108

	// Shader
	public Shader shader;

	// Material
	private Material material;

	// Video texture
	private WebCamTexture video;

	// UI text
	public UnityEngine.UI.Text ui;

	// Game states
	private enum State {
		Init,
		Play,
		Result,
		Restart
	}
	private State state;
	private float stateTime;

	// Game parameters
	private float videoError;
	private float goal;
	private const float goalSpeed = 0.3f;
	private float result;

	// Smooth Hermite interpolation between two values (like GLSL's smoothstep function)
	private static float SmoothStep (float edge0, float edge1, float x)
	{
		float t = Mathf.Clamp01 ((x - edge0) / (edge1 - edge0));
		return t * t * (3.0f - 2.0f * t);
	}

	// RGB to HSV
	private static Vector3 Rgb2Hsv (Color rgb)
	{
		float max = Mathf.Max (rgb.r, Mathf.Max (rgb.g, rgb.b));
		float min = Mathf.Min (rgb.r, Mathf.Min (rgb.g, rgb.b));
		if (max == min) {
			return new Vector3 (0.0f, 0.0f, max);
		}
		float chroma = max - min;
		float hue;
		if (max == rgb.r) {
			hue = (rgb.g - rgb.b) / chroma;
		} else if (max == rgb.g) {
			hue = (rgb.b - rgb.r) / chroma + 2.0f;
		} else {
			hue = (rgb.r - rgb.g) / chroma + 4.0f;
		}
		return new Vector3 (hue * Mathf.PI / 3.0f, chroma / max, max);
	}

	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 30;

		// Disable the screen dimming
		Screen.sleepTimeout = SleepTimeout.NeverSleep;

		// Get the camera
		camera = GetComponent <Camera> ();

		// Create the  material
		material = new Material (shader);

		// Get the video stream
		video = new WebCamTexture ();
		video.Play ();
		material.SetTexture ("video", video);

		// Start the game
		StartCoroutine (GameLoop ());
	}

	// Game loop
	private System.Collections.IEnumerator GameLoop ()
	{
		// Initialize the goal
		goal = Random.value * 2.0f * Mathf.PI;

		// Game loop
		while (true) {

			// Init
			state = State.Init;
			material.SetFloat ("videoDisplay", 0.0f);
			ui.text = "Ready?";
			yield return new WaitForSeconds (2);
			ui.text = "Set...";
			yield return new WaitForSeconds (2);

			// Play
			state = State.Play;
			stateTime = Time.time;
			ui.text = "GO!";
			yield return new WaitForSeconds (1);
			ui.text = "";
			yield return new WaitForSeconds (1);
			for (int time = 3; time > 0; --time) {
				ui.text = time.ToString ();
				yield return new WaitForSeconds (0.25f);
				ui.text = "";
				yield return new WaitForSeconds (0.75f);
			}

			// Result
			state = State.Result;
			ui.text = "STOP!";
			yield return new WaitForSeconds (1);
			ui.text = "";
			yield return new WaitForSeconds (1);
			float success = ((goal - result) / Mathf.PI) % 2.0f;
			success = 100.0f * (success < 1.0f ? 1.0f - success : success - 1.0f) * (1.0f - videoError);
			ui.text = success.ToString ("0'%'");
			yield return new WaitForSeconds (3);

			// Restart
			state = State.Restart;
			stateTime = Time.time;
			ui.text = "";
			yield return new WaitForSeconds (1);
		}
	}

	// Method called by Unity at every frame
	private void Update ()
	{
		// Update the game
		switch (state) {

			// Init
			case State.Init:
			{
				goal += goalSpeed;
				material.SetFloat ("goal", goal);
				break;
			}

			// Play
			case State.Play:
			{
				float time = Mathf.Min (1.0F, Time.time - stateTime);
				goal += goalSpeed * (1.0f - time);
				Vector3 hsvResult = HsvFromVideo ();
				videoError = SmoothStep (0.3f, 0.0f, Mathf.Min (hsvResult.y, hsvResult.z));
				result = hsvResult.x;
				material.SetFloat ("videoDisplay", time);
				material.SetFloat ("videoError", videoError);
				material.SetFloat ("goal", goal);
				material.SetFloat ("result", result);
				break;
			}

			// Restart
			case State.Restart:
			{
				float time = Mathf.Min (1.0F, Time.time - stateTime);
				goal += goalSpeed * time;
				material.SetFloat ("videoDisplay", 1.0f - time);
				material.SetFloat ("goal", goal);
				break;
			}
		}
	}

	// Get the HSV from the video stream
	private Vector3 HsvFromVideo ()
	{
		// Compute the size of the center part of the video (one third of the smallest displayed side)
		int widthHeight = video.width * Screen.height;
		int heightWidth = video.height * Screen.width;
		int size;
		if (widthHeight > heightWidth) {
			size = Mathf.Min (heightWidth / Screen.height, video.height);
		} else {
			size = Mathf.Min (video.width, widthHeight / Screen.width);
		}
		size /= 3;

		// Compute the average RGB color from the center part of the video
		Color [] colors = video.GetPixels ((video.width - size) / 2, (video.height - size) / 2, size, size);
		Color colorAverage = Color.black;
		foreach (Color color in colors) {
			colorAverage += color;
		}
		colorAverage /= colors.Length;

		// Return the HSV of the averaged color
		return Rgb2Hsv (colorAverage);
	}

	// Method called by Unity after a camera finished rendering the scene
	private void OnPostRender ()
	{
		// Compute the rendering resolution
		float factor = 1.0f / Mathf.Sqrt (resolutionFactor);
		int width = (int) (Screen.width * factor);
		int height = (int) (Screen.height * factor);

		// Create a render texture (with bilinear filtering)
		if (resolutionFactor == 1) {
			camera.targetTexture = null;
		} else if (!camera.targetTexture || camera.targetTexture.width != width || camera.targetTexture.height != height) {
			camera.targetTexture = new RenderTexture (width, height, 0);
		}

		// Check the video orientation
		Vector2 videoResolution;
		Vector4 videoRotation;
		float videoY = video.videoVerticallyMirrored ? -1.0f : 1.0f;
		switch (video.videoRotationAngle) {
			case 90:
				videoResolution = new Vector2 (video.height, video.width);
				videoRotation = new Vector4 (0.0f, videoY, -1.0f, 0.0f);
				break;
			case 180:
				videoResolution = new Vector2 (video.width, video.height);
				videoRotation = new Vector4 (-1.0f, 0.0f, 0.0f, -videoY);
				break;
			case 270:
				videoResolution = new Vector2 (video.height, video.width);
				videoRotation = new Vector4 (0.0f, -videoY, 1.0f, 0.0f);
				break;
			default:
				videoResolution = new Vector2 (video.width, video.height);
				videoRotation = new Vector4 (1.0f, 0.0f, 0.0f, videoY);
				break;
		}

		// Update the shader
		material.SetVector ("resolution", new Vector2 (width, height));
		material.SetFloat ("time", Time.time);
		material.SetVector ("videoResolution", videoResolution);
		material.SetVector ("videoRotation", videoRotation);

		// Render the scene
		Graphics.Blit (null, camera.targetTexture, material);
	}

	// Method to render the scene full screen (to be called from the "OnPostRender" of another camera)
	public void RenderFullScreen ()
	{
		if (camera.targetTexture) {
			Graphics.Blit (camera.targetTexture, (RenderTexture) null);
		}
	}
}
