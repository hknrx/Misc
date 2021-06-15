// Nicolas Robert [Nrx]
using UnityEngine;

public class Convert : MonoBehaviour
{
	// Textures
	public Texture2D tileMapOld;
	public Texture2D tileMapNew;

	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Define the conversion array
		int [] C = new int [64] {12, 13, 3, 3, 3, 14, 15, 10, 8, 9, 3, 3, 3, 3, 3, 3, 4, 5, 6, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 1, 3, 3, 3, 3, 3, 3, 3, 11, 3, 3, 3, 3, 3, 3, 3, 7, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3};

		// Modify the tile map
		Color [] pixels = tileMapOld.GetPixels ();
		int xy = tileMapOld.width * tileMapOld.height;
		while (xy --> 0)
		{
			int index = pixels [xy].r == 1.0f ? 3 : C [(int)(256 * (pixels [xy].r + pixels [xy].g * 8))];
			pixels [xy].a = (index + 0.5f) / 16;
		}
		tileMapNew.SetPixels (pixels);
		tileMapNew.Apply ();

		// Save the texture
		System.IO.File.WriteAllBytes (Application.persistentDataPath + "/TileMapNew.png", tileMapNew.EncodeToPNG ());
		Debug.Log (Application.persistentDataPath);
	}
}
