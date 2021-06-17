// Nicolas Robert [Nrx]
using UnityEngine;
using UnityEngine.UI;

public class FrameRate : MonoBehaviour
{
	// Variables to measure the frame rate
	public Text frameRateText;
	private const float frameRateMeasureDuration = 2.0f;
	private float frameRateTimer;
	private int frameRateCounter;

	// Method called by Unity at every frame
	private void Update ()
	{
		if (Time.realtimeSinceStartup < frameRateTimer)
		{
			++frameRateCounter;
		}
		else
		{
			frameRateText.text = (frameRateCounter / frameRateMeasureDuration).ToString ("0.0 'fps'");
			frameRateTimer = Time.realtimeSinceStartup + frameRateMeasureDuration;
			frameRateCounter = 0;
		}
	}
}
