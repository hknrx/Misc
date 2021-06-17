// Nicolas Robert [Nrx]
using UnityEngine;

public class Init : MonoBehaviour
{
	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Disable screen dimming
		Screen.sleepTimeout = SleepTimeout.NeverSleep;
	}
}
