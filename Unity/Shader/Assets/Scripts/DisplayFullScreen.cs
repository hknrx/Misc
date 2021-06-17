// Nicolas Robert [Nrx]
using UnityEngine;

public class DisplayFullScreen : MonoBehaviour
{
	// Reference to the instance that handles the rendering
	public RenderShader renderShader;

	// Method called by Unity after a camera finished rendering the scene
	private void OnPostRender ()
	{
		renderShader.RenderFullScreen ();
	}
}
