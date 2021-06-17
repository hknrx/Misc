// Nicolas Robert [Nrx]
using UnityEngine;
using UnityEngine.EventSystems;

public class DisplayFullScreen : MonoBehaviour, IPointerClickHandler
{
	// GUI
	public GameObject gui;

	// Script that renders everything
	public RenderScene renderScene;

	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Disable screen dimming
		Screen.sleepTimeout = SleepTimeout.NeverSleep;

		// Enable the gyroscope
		Input.gyro.enabled = true;
	}

	// Toggle the GUI
	public void OnPointerClick (PointerEventData eventData)
	{
		gui.SetActive (!gui.activeSelf);
	}

	// Method called by Unity after a camera finished rendering the scene
	private void OnPostRender ()
	{
		renderScene.RenderFullScreen ();
	}
}
