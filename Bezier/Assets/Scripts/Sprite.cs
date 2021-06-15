using UnityEngine;

public partial class Sprite : MonoBehaviour
{
	// Data structure to define a single sprite
	struct SpriteData
	{
		public int x;
		public int y;
		public int width;
		public int height;
	}

	// Private members
	static Material[] spriteMaterials = null;
	static readonly int[] triangles = {0, 1, 2, 2, 3, 0};

	/**
	 * Static constructor.
	 */
	static Sprite ()
	{
		// Load the sprite materials
		Object[] originalSpriteMaterials = Resources.LoadAll ("SpriteMaterials", typeof(Material));

		// Keep a copy of the these materials (so that we can modify them freely without affecting the original ones)
		spriteMaterials = new Material[originalSpriteMaterials.Length];
		for (int materialIndex = 0; materialIndex < originalSpriteMaterials.Length; ++materialIndex) {
			spriteMaterials [materialIndex] = (Material)Instantiate (originalSpriteMaterials [materialIndex]);
		}
	}

	/**
	 * Set the vertices and UV of a sprite.
	 *
	 * @param mesh Mesh of the sprite.
	 * @param spriteData Data of the sprite.
	 */
	static void SetVerticesUV (Mesh mesh, ref SpriteData spriteData)
	{
		// Modify the vertices
		float halfWidth = spriteData.width * 0.5f;
		float halfHeight = spriteData.height * 0.5f;
		mesh.vertices = new Vector3[] {
			new Vector3 (-halfWidth, -halfHeight, 0.0f),
			new Vector3 (-halfWidth, halfHeight, 0.0f),
			new Vector3 (halfWidth, halfHeight, 0.0f),
			new Vector3 (halfWidth, -halfHeight, 0.0f)
		};

		// Modify the UV
		float left = (float)spriteData.x / textureWidth;
		float right = (float)(spriteData.x + spriteData.width) / textureWidth;
		float top = 1.0f - (float)spriteData.y / textureHeight;
		float bottom = 1.0f - (float)(spriteData.y + spriteData.height) / textureHeight;
		mesh.uv = new Vector2[] {
			new Vector2 (left, bottom),
			new Vector2 (left, top),
			new Vector2 (right, top),
			new Vector2 (right, bottom)
		};
	}

	/**
	 * Set the vertices and UV of a sprite.
	 *
	 * @param mesh Mesh of the sprite.
	 * @param material Material of the sprite.
	 * @param maxSize Maximum size of the sprite.
	 */
	static void SetVerticesUV (Mesh mesh, Material material, Vector2 maxSize)
	{
		// Get the actual size of the material
		float materialWidth = material.mainTexture.width;
		float materialHeight = material.mainTexture.height;

		// Modify the vertices
		float halfWidth = Mathf.Min (materialWidth, maxSize.x) * 0.5f;
		float halfHeight = Mathf.Min (materialHeight, maxSize.y) * 0.5f;
		mesh.vertices = new Vector3[] {
			new Vector3 (-halfWidth, -halfHeight, 0.0f),
			new Vector3 (-halfWidth, halfHeight, 0.0f),
			new Vector3 (halfWidth, halfHeight, 0.0f),
			new Vector3 (halfWidth, -halfHeight, 0.0f)
		};

		// Modify the UV
		float left = Mathf.Max (materialWidth - maxSize.x, 0.0f) / (materialWidth * 2);
		float right = 1.0f - left;
		float bottom = Mathf.Max (materialHeight - maxSize.y, 0.0f) / (materialHeight * 2);
		float top = 1.0f - bottom;
		mesh.uv = new Vector2[] {
			new Vector2 (left, bottom),
			new Vector2 (left, top),
			new Vector2 (right, top),
			new Vector2 (right, bottom)
		};
	}

	/**
	 * Create a sprite.
	 *
	 * @param position Position of the sprite.
	 * @param mesh Mesh of the sprite.
	 * @param material Material of the sprite.
	 * @param name Name of the sprite.
	 * @return Created game object.
	 */
	static GameObject Create (Vector3 position, Mesh mesh, Material material, string name = null)
	{
		// Create a new game object
		GameObject sprite = new GameObject (name != null ? name : material.name);
		sprite.transform.localPosition = position;

		// Set the triangles
		mesh.triangles = triangles;
		mesh.RecalculateNormals ();

		// Assign the mesh and material to the new game object
		sprite.AddComponent<MeshFilter> ().mesh = mesh;
		sprite.AddComponent<MeshRenderer> ().material = material;

		// Return the newly created sprite
		return sprite;
	}

	/**
	 * Create a sprite.
	 *
	 * @param name Name of the sprite.
	 * @param position Position of the sprite.
	 * @param materialIndex Index of the material.
	 * @return Created game object.
	 */
	public static GameObject Create (string name, Vector3 position, int materialIndex = 0)
	{
		// Get the sprite information
		SpriteData spriteData;
		if (!spritesData.TryGetValue (name, out spriteData)) {
			Debug.LogWarning ("Couldn't find a sprite named \"" + name + "\"!");
			return null;
		}

		// Check the material index
		if (materialIndex < 0 || materialIndex >= spriteMaterials.Length) {
			Debug.LogWarning ("The sprite's material index is not valid!");
			return null;
		}

		// Create a mesh
		Mesh mesh = new Mesh ();

		// Set the vertices and UV
		SetVerticesUV (mesh, ref spriteData);

		// Create the sprite
		return Create (position, mesh, spriteMaterials [materialIndex], name);
	}

	/**
	 * Create a sprite.
	 *
	 * @param material Material of the sprite.
	 * @param position Position of the sprite.
	 * @param maxSize Maximum size of the sprite.
	 * @return Created game object.
	 */
	public static GameObject Create (Material material, Vector3 position, Vector2 maxSize)
	{
		// Create a mesh
		Mesh mesh = new Mesh ();

		// Set the vertices and UV
		SetVerticesUV (mesh, material, maxSize);

		// Create the sprite
		return Create (position, mesh, material);
	}

	/**
	 * Modify an existing sprite (replaced its texture by another one).
	 *
	 * @param sprite Sprite to be modified.
	 * @param name Name of the sprite.
	 * @param materialIndex Index of the material.
	 */
	public static void Modify (GameObject sprite, string name, int materialIndex = 0)
	{
		// Get the sprite information
		SpriteData spriteData;
		if (!spritesData.TryGetValue (name, out spriteData)) {
			Debug.LogWarning ("Couldn't find a sprite named \"" + name + "\"!");
			return;
		}

		// Check the material index
		if (materialIndex < 0 || materialIndex >= spriteMaterials.Length) {
			Debug.LogWarning ("The sprite's material index is not valid!");
			return;
		}

		// Get the mesh filter component
		MeshFilter meshFilter = sprite.GetComponent<MeshFilter> ();
		if (meshFilter == null) {
			Debug.LogWarning ("This sprite doesn't have a mesh filter!");
			return;
		}

		// Modify the material
		sprite.GetComponent<Renderer>().material = spriteMaterials [materialIndex];

		// Modify the vertices and UV
		SetVerticesUV (meshFilter.mesh, ref spriteData);
		meshFilter.mesh.RecalculateBounds ();

		// Modify the name of the object
		sprite.name = name;
	}

	/**
	 * Modify an existing sprite.
	 *
	 * @param sprite Sprite to be modified.
	 * @param material Material of the sprite.
	 * @param maxSize Maximum size of the sprite.
	 */
	public static void Modify (GameObject sprite, Material material, Vector2 maxSize)
	{
		// Get the mesh filter component
		MeshFilter meshFilter = sprite.GetComponent<MeshFilter> ();
		if (meshFilter == null) {
			Debug.LogWarning ("This sprite doesn't have a mesh filter!");
			return;
		}

		// Modify the material
		sprite.GetComponent<Renderer>().material = material;

		// Modify the vertices and UV
		SetVerticesUV (meshFilter.mesh, material, maxSize);
		meshFilter.mesh.RecalculateBounds ();

		// Modify the name of the object
		sprite.name = material.name;
	}

	/**
	 * Set the material of a sprite.
	 *
	 * @param sprite Game object.
	 * @param materialIndex Index of the material.
	 */
	public static void SetSpriteMaterial (GameObject sprite, int materialIndex)
	{
		if (materialIndex >= 0 && materialIndex < spriteMaterials.Length) {
			sprite.GetComponent<Renderer>().material = spriteMaterials [materialIndex];
		} else {
			Debug.LogWarning ("Couldn't set the sprite's material (index isn't valid)!");
		}
	}

	/**
	 * Set the color of a material.
	 *
	 * @param materialIndex Index of the material.
	 * @param color Color of the material.
	 */
	public static void SetMaterialColor (int materialIndex, Color color)
	{
		if (materialIndex >= 0 && materialIndex < spriteMaterials.Length) {
			spriteMaterials [materialIndex].color = color;
		} else {
			Debug.LogWarning ("Couldn't set the material's color (index isn't valid)!");
		}
	}

	/**
	 * Get the size of a sprite.
	 *
	 * @param name Name of the sprite.
	 * @return Size of the sprite.
	 */
	public static Vector2 GetSize (string name)
	{
		SpriteData spriteData;
		if (!spritesData.TryGetValue (name, out spriteData)) {
			Debug.LogWarning ("Couldn't find a sprite named \"" + name + "\"!");
			return Vector2.zero;
		}
		return new Vector2 (spriteData.width, spriteData.height);
	}
}
