// Nicolas Robert [Nrx]
using UnityEngine;

public class FullScreen : MonoBehaviour
{
	// Script that handles the actual rendering
	public ColorNrx colorNrx;

	// Method called by Unity after a camera finished rendering the scene
	private void OnPostRender ()
	{
		colorNrx.RenderFullScreen ();
	}
}
