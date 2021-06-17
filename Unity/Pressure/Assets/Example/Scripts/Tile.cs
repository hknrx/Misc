// Nicolas Robert [Nrx]
using UnityEngine;

public class Tile : MonoBehaviour
{
	// Material
	public Material material;
	private Material materialCopy;

	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Initialize the shader (define the variant to use)
		materialCopy = (Material)Object.Instantiate (material);
		materialCopy.EnableKeyword ("REPEAT");
	}

	// Method called by Unity at every frame
	private void Update ()
	{
		// Move the tile map
		float angle = Mathf.PI * 0.125f * Mathf.Sin (Time.time * 1.5f);
		Vector2 tileMapTransform = new Vector2 (Mathf.Cos (angle), Mathf.Sin (angle));
		Vector2 tileMapTranslate = new Vector2 (50.0f * Time.time, 50.0f * Mathf.Cos (Time.time));

		Vector2 tileMapOrigin = new Vector2 (Screen.width * 0.5f, Screen.height * 0.5f);
		tileMapTranslate += tileMapOrigin - new Vector2 (tileMapTransform.x * tileMapOrigin.x - tileMapTransform.y * tileMapOrigin.y, tileMapTransform.y * tileMapOrigin.x + tileMapTransform.x * tileMapOrigin.y);

		// Update the shader (set the transformation matrix and translation vector)
		materialCopy.SetVector ("transform", new Vector4 (tileMapTransform.x, tileMapTransform.y, -tileMapTransform.y, tileMapTransform.x));
		materialCopy.SetVector ("translate", tileMapTranslate);
	}

	// Method called by Unity after a camera finished rendering the scene
	private void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
		Graphics.Blit (source, destination);
		Graphics.Blit (null, destination, materialCopy);
	}
}
