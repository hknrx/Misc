// Nicolas Robert [Nrx]
using UnityEngine;
using UnityEngine.UI;

public class DisplayFullScreen : MonoBehaviour
{
	// Script that renders everything
	public RenderScene renderScene;

	// Frame rate measurement
	public Text frameRateGui;
	private const float frameRateMeasureDuration = 2.0f;
	private float frameTimer = 0.0f;
	private int frameCount;

	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Disable screen dimming
		Screen.sleepTimeout = SleepTimeout.NeverSleep;
	}

	// Method called by Unity at every frame
	private void Update ()
	{
		// Measure the frame rate
		if (Time.realtimeSinceStartup < frameTimer) {
			++frameCount;
		} else {
			frameRateGui.text = (frameCount / frameRateMeasureDuration).ToString ("0.0 'fps'");
			frameTimer = Time.realtimeSinceStartup + frameRateMeasureDuration;
			frameCount = 0;
		}
	}

	// Method called by Unity after a camera finished rendering the scene
	private void OnPostRender ()
	{
		renderScene.RenderFullScreen ();
	}
}
