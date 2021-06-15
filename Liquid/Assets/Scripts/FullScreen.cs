// Nicolas Robert [Nrx]

using UnityEngine;

public class FullScreen : MonoBehaviour
{
	// Reference to the instance that handles the rendering
	public Demo demo;

	// Method called by Unity after a camera finished rendering the scene
	private void OnPostRender ()
	{
		demo.RenderFullScreen ();
	}
}
