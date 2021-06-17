using UnityEngine;
using System.Collections.Generic;

public partial class Sprite
{
	// Constants for the physics
	const float SPRITE_THICKNESS_BASE = 80.0f;
	const float SPRITE_THICKNESS_RANDOM = 40.0f;
	const float SPRITE_MINIMUM_AREA = 50.0f;
	const float SPRITE_DESTROY_DELAY = 3.0f;
	const int SPRITE_SLICEABLE_LAYER = 8;

	// Different types of colliders
	public enum ColliderType
	{
		NoCollider,
		OptimizedCollider,
		ContourCollider,
	}

	// Data structure to define a single sprite
	struct SpriteData
	{
		public int x;
		public int y;
		public int width;
		public int height;
	}

	// Array of materials
	static Material[] spriteMaterials;

	// Pool to store vertex information (needed for the triangulation)
	struct VertexInfo
	{
		public int indexPrevious;
		public int indexNext;
		public float convexIfPositive;
	}
	static VertexInfo[] vertexInfo;

	// Structure to record intersection information
	struct IntersectionInfo
	{
		public Vector2 point;
		public bool enter;
	}

	/**
	 * Static constructor.
	 */
	static Sprite ()
	{
		// Load the sprite materials
		Object[] originalSpriteMaterials = Resources.LoadAll ("SpriteMaterials", typeof(Material));

		// Keep a copy of these materials (so that we can modify them freely without affecting the original ones)
		spriteMaterials = new Material[originalSpriteMaterials.Length];
		for (int materialIndex = 0; materialIndex < originalSpriteMaterials.Length; ++materialIndex) {
			spriteMaterials [materialIndex] = (Material)GameObject.Instantiate (originalSpriteMaterials [materialIndex]);
		}
	}

	/**
	 * Set the mesh of a sprite.
	 *
	 * @param mesh Mesh of the sprite.
	 * @param material Material of the sprite.
	 * @param maxSize Maximum size of the sprite.
	 */
	static void SetMesh (Mesh mesh, Material material, Vector2 maxSize)
	{
		// Get the actual size of the material
		float materialWidth = material.mainTexture.width;
		float materialHeight = material.mainTexture.height;

		// Set the vertices
		float halfWidth = Mathf.Min (materialWidth, maxSize.x) * 0.5f;
		float halfHeight = Mathf.Min (materialHeight, maxSize.y) * 0.5f;
		mesh.vertices = new Vector3[] {
			new Vector3 (-halfWidth, -halfHeight, 0.0f),
			new Vector3 (-halfWidth, halfHeight, 0.0f),
			new Vector3 (halfWidth, halfHeight, 0.0f),
			new Vector3 (halfWidth, -halfHeight, 0.0f)
		};

		// Set the UV
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

		// Set the triangles
		mesh.triangles = new int [] {0, 1, 2, 2, 3, 0};
		mesh.RecalculateNormals ();
	}

	/**
	 * Create or modify a sprite.
	 *
	 * @param sprite Sprite to be modified (a new sprite will be created if this parameter is null).
	 * @param material Material of the sprite.
	 * @param position Position of the sprite.
	 * @param maxSize Maximum size of the sprite.
	 * @return Created game object.
	 */
	public static GameObject CreateOrModify (GameObject sprite, Material material, Vector3 position, Vector2 maxSize)
	{
		// Check whether we have to create a new sprite or modify an existing one
		if (!sprite) {

			// Create a new game object
			sprite = new GameObject (material.name);

			// Create the mesh
			Mesh mesh = new Mesh ();
			SetMesh (mesh, material, maxSize);
			sprite.AddComponent<MeshFilter> ().mesh = mesh;

			// Assign the material
			sprite.AddComponent<MeshRenderer> ().material = material;
		} else {

			// Modify the name of the object
			sprite.name = material.name;

			// Modify the mesh
			Mesh mesh = sprite.GetComponent<MeshFilter> ().mesh;
			mesh.Clear ();
			SetMesh (mesh, material, maxSize);
			mesh.RecalculateBounds ();

			// Modify the material
			sprite.GetComponent<Renderer>().material = material;
		}

		// Set the position of the sprite
		sprite.transform.localPosition = position;

		// Done!
		return sprite;
	}

	/**
	 * Compute the cosine of the angle at a given vertex.
	 *
	 * @param contour List of points that defines the contour of the sprite.
	 * @param indexCurrent Index of a vertex.
	 * @return Cosine of the angle at this vertex.
	 */
	static float CosineAngle (List<Vector2> contour, int indexCurrent)
	{
		int indexPrevious = vertexInfo [indexCurrent].indexPrevious;
		int indexNext = vertexInfo [indexCurrent].indexNext;

		Vector2 vectorPrevious = contour [indexCurrent] - contour [indexPrevious];
		Vector2 vectorNext = contour [indexNext] - contour [indexCurrent];

		return vectorNext.x * vectorPrevious.y - vectorNext.y * vectorPrevious.x;
	}

	/**
	 * Check whether a vertex is an "ear".
	 *
	 * @param contour List of points that defines the contour of the sprite.
	 * @param indexCurrent Index of a vertex.
	 * @return true if this vertex is an "ear", false otherwise.
	 */
	static bool IsEar (List<Vector2> contour, int indexCurrent)
	{
		// Make sure the vertex is convex
		if (vertexInfo [indexCurrent].convexIfPositive < 0) {
			return false;
		}

		// Define the triangle
		int indexPrevious = vertexInfo [indexCurrent].indexPrevious;
		int indexNext = vertexInfo [indexCurrent].indexNext;

		Vector2 vector0 = contour [indexCurrent] - contour [indexPrevious];
		Vector2 vector1 = contour [indexNext] - contour [indexCurrent];
		Vector2 vector2 = contour [indexPrevious] - contour [indexNext];

		// Let's check all other vertices
		int indexOther = vertexInfo [indexNext].indexNext;
		while (indexOther != indexPrevious) {

			// Check whether this vertex is reflex
			if (vertexInfo [indexOther].convexIfPositive < 0) {

				// Check whether it is inside the triangle being tested
				Vector2 vectorEdgePoint = contour [indexOther] - contour [indexPrevious];
				if (vector0.x * vectorEdgePoint.y < vector0.y * vectorEdgePoint.x) {
					vectorEdgePoint = contour [indexOther] - contour [indexCurrent];
					if (vector1.x * vectorEdgePoint.y < vector1.y * vectorEdgePoint.x) {
						vectorEdgePoint = contour [indexOther] - contour [indexNext];
						if (vector2.x * vectorEdgePoint.y < vector2.y * vectorEdgePoint.x) {
							return false;
						}
					}
				}
			}

			// Next vertex
			indexOther = vertexInfo [indexOther].indexNext;
		}
		return true;
	}

	/**
	 * Set the mesh of a sprite.
	 *
	 * @param mesh Mesh of the sprite.
	 * @param spriteData Data of the sprite.
	 * @param contour List of points that defines the contour of the sprite.
	 * @param area Area of the shape defined by the contour.
	 * @param is3D True if the mesh shall be in 3D (to collide with other objects), false otherwise.
	 * @return True if the mesh is convex, false otherwise.
	 */
	static bool SetMesh (Mesh mesh, ref SpriteData spriteData, List<Vector2> contour, out float area, bool is3D = false)
	{
		// Make sure there are enough points
		if (contour.Count < 3) {
			Debug.LogWarning ("The contour doesn't have enough points!");
			area = 0.0f;
			return true;
		}

		// Setup an array to store the vertex information
		if (vertexInfo == null) {
			vertexInfo = new VertexInfo [contour.Count];
		} else if (vertexInfo.Length < contour.Count) {
			System.Array.Resize (ref vertexInfo, contour.Count);
		}

		// Setup arrays to store the vertices and their UV
		int vertexCount = is3D ? contour.Count * 2 : contour.Count;
		Vector3 [] vertices = new Vector3 [vertexCount];
		Vector2 [] uv = new Vector2 [vertexCount];

		// Setup an array to store the triangles
		int triangleCount = is3D ? (contour.Count - 1) * 12 : (contour.Count - 2) * 3;
		int [] triangles = new int [triangleCount];
		int triangleIndex = 0;

		// Define the information of each vertex
		// Note: it is important that each sprite has a different depth, to avoid collision issues
		float halfWidth = spriteData.width * 0.5f;
		float halfHeight = spriteData.height * 0.5f;
		float halfDepth = is3D ? 0.5f * (SPRITE_THICKNESS_BASE + SPRITE_THICKNESS_RANDOM * Random.value) : 0.0f;

		bool convex = true;
		float areaDouble = 0.0f;
		int indexPrevious = contour.Count - 2;
		int indexCurrent = contour.Count - 1;
		for (int indexNext = 0; indexNext < contour.Count; ++indexNext) {

			// Set the index of the previous and next vertices
			vertexInfo [indexCurrent].indexPrevious = indexPrevious;
			vertexInfo [indexCurrent].indexNext = indexNext;

			// Check whether this vertex is convex or concave
			vertexInfo [indexCurrent].convexIfPositive = CosineAngle (contour, indexCurrent);
			convex &= vertexInfo [indexCurrent].convexIfPositive >= 0;

			// Compute the area
			areaDouble += contour [indexNext].x * contour [indexCurrent].y - contour [indexNext].y * contour [indexCurrent].x;

			// Set the actual vertex and UV
			vertices [indexCurrent] = new Vector3 (contour [indexCurrent].x - halfWidth, halfHeight - contour [indexCurrent].y, -halfDepth);
			uv [indexCurrent] = new Vector2 ((float)(spriteData.x + contour [indexCurrent].x) / textureWidth, 1.0f - (float)(spriteData.y + contour [indexCurrent].y) / textureHeight);

			// Let's process the next vertex
			indexPrevious = indexCurrent;
			indexCurrent = indexNext;
		}

		// Check whether the polygon is defined in the wrong direction
		if (areaDouble < 0) {
			Debug.LogWarning ("This contour is defined in the wrong direction!");

			areaDouble = -areaDouble;
			convex = true;
			for (indexCurrent = 0; indexCurrent < contour.Count; ++indexCurrent) {
				int indexSwap = vertexInfo [indexCurrent].indexPrevious;
				vertexInfo [indexCurrent].indexPrevious = vertexInfo [indexCurrent].indexNext;
				vertexInfo [indexCurrent].indexNext = indexSwap;
				vertexInfo [indexCurrent].convexIfPositive = -vertexInfo [indexCurrent].convexIfPositive;
				convex &= vertexInfo [indexCurrent].convexIfPositive >= 0;
			}
		}
		area = areaDouble / 2;

		// Create the side triangles
		if (is3D) {
			indexCurrent = 0;
			do {
				indexPrevious = vertexInfo [indexCurrent].indexPrevious;
				int indexPreviousBack = indexPrevious + contour.Count;
				int indexCurrentBack = indexCurrent + contour.Count;

				vertices [indexCurrentBack] = new Vector3 (vertices [indexCurrent].x, vertices [indexCurrent].y, halfDepth);
				uv [indexCurrentBack] = uv [indexCurrent];

				triangles [triangleIndex++] = indexPreviousBack;
				triangles [triangleIndex++] = indexPrevious;
				triangles [triangleIndex++] = indexCurrent;

				triangles [triangleIndex++] = indexPreviousBack;
				triangles [triangleIndex++] = indexCurrent;
				triangles [triangleIndex++] = indexCurrentBack;

				indexCurrent = vertexInfo [indexCurrent].indexNext;
			} while (indexCurrent != 0);
		}

		// Perform the triangulation of the face of the sprite
		indexCurrent = 0;
		int indexGiveUp = vertexInfo [indexCurrent].indexPrevious;
		while (triangleIndex < triangleCount && indexCurrent != indexGiveUp) {
			int indexNext = vertexInfo [indexCurrent].indexNext;
			if (IsEar (contour, indexCurrent)) {

				// Create a triangle
				indexPrevious = vertexInfo [indexCurrent].indexPrevious;
				triangles [triangleIndex++] = indexNext;
				triangles [triangleIndex++] = indexCurrent;
				triangles [triangleIndex++] = indexPrevious;

				// Create another triangle (opposite face of the mesh)
				if (is3D) {
					triangles [triangleIndex++] = indexNext + contour.Count;
					triangles [triangleIndex++] = indexPrevious + contour.Count;
					triangles [triangleIndex++] = indexCurrent + contour.Count;
				}

				// Remove this vertex
				vertexInfo [indexPrevious].indexNext = indexNext;
				vertexInfo [indexNext].indexPrevious = indexPrevious;

				// Update its neighbors
				vertexInfo [indexPrevious].convexIfPositive = vertexInfo [indexPrevious].convexIfPositive >= 0 ? 0 : CosineAngle (contour, indexPrevious);
				vertexInfo [indexNext].convexIfPositive = vertexInfo [indexNext].convexIfPositive >= 0 ? 0 : CosineAngle (contour, indexNext);

				// Update the "give up" index
				indexGiveUp = indexPrevious;
			}
			indexCurrent = indexNext;
		}

		// Done!
		mesh.vertices = vertices;
		mesh.uv = uv;
		mesh.triangles = triangles;
		mesh.RecalculateNormals ();
		return convex;
	}

	/**
	 * Create or modify a sprite.
	 *
	 * @param sprite Sprite to be modified (a new sprite will be created if this parameter is null).
	 * @param name Name of the sprite.
	 * @param position Position of the sprite.
	 * @param materialIndex Index of the material.
	 * @param colliderType Type of collider (if different from ColliderType.NoCollider, then a collider will be attached).
	 * @param density Density of the sprite (if the density is greater than 0, then a rigid body will be attached).
	 * @return Created game object.
	 */
	public static GameObject CreateOrModify (GameObject sprite, string name, Vector3 position, int materialIndex = 0, ColliderType colliderType = ColliderType.NoCollider, float density = 0.0f)
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

		// Get the contour of the sprite
		List <Vector2> spriteContour;
		bool hasContour = spritesContour.TryGetValue (name, out spriteContour);
		if (!hasContour) {

			// Without a predefined contour, we use a simple quad
			spriteContour = new List<Vector2> {
				new Vector2 (0, 0),
				new Vector2 (0, spriteData.height),
				new Vector2 (spriteData.width, spriteData.height),
				new Vector2 (spriteData.width, 0),
			};
		}

		// Check the properties of the sprite
		bool is3D = (hasContour && colliderType != ColliderType.NoCollider) || (!hasContour && colliderType == ColliderType.ContourCollider);
		bool hasRigidBody = colliderType != ColliderType.NoCollider && density > 0;

		// Check whether we have to create a new sprite or modify an existing one
		Mesh mesh;
		float area;
		bool convex;
		if (!sprite) {

			// Create a new game object
			sprite = new GameObject (name);

			// Create the mesh
			mesh = new Mesh ();
			convex = SetMesh (mesh, ref spriteData, spriteContour, out area, is3D);
			sprite.AddComponent<MeshFilter> ().mesh = mesh;

			// Assign the material
			sprite.AddComponent<MeshRenderer> ().material = spriteMaterials [materialIndex];
		} else {

			// Modify the name of the object
			sprite.name = name;

			// Modify the mesh
			mesh = sprite.GetComponent<MeshFilter> ().mesh;
			mesh.Clear ();
			convex = SetMesh (mesh, ref spriteData, spriteContour, out area, is3D);
			mesh.RecalculateBounds ();

			// Modify the material
			sprite.GetComponent<Renderer>().material = spriteMaterials [materialIndex];
		}

		// Set the position of the sprite
		sprite.transform.localPosition = position;

		// Check whether the sprite shall have a collider
		if (colliderType == ColliderType.NoCollider) {

			// Disable any existing collider
			sprite.layer = 0;
			if (sprite.GetComponent<Collider>()) {
				sprite.GetComponent<Collider>().enabled = false;
			}
		} else if (is3D) {

			// Setup a mesh collider
			sprite.layer = SPRITE_SLICEABLE_LAYER;
			MeshCollider meshCollider;
			if (sprite.GetComponent<Collider>() is MeshCollider) {
				meshCollider = sprite.GetComponent<Collider>() as MeshCollider;
				meshCollider.enabled = true;
			} else {
				GameObject.Destroy (sprite.GetComponent<Collider>());
				meshCollider = sprite.AddComponent<MeshCollider> ();
			}
			meshCollider.sharedMesh = mesh;
			meshCollider.convex = convex;
			meshCollider.isTrigger = !hasRigidBody;
		} else {

			// Setup a box collider
			sprite.layer = 0;
			BoxCollider boxCollider;
			if (sprite.GetComponent<Collider>() is BoxCollider) {
				boxCollider = sprite.GetComponent<Collider>() as BoxCollider;
				boxCollider.enabled = true;
			} else {
				GameObject.Destroy (sprite.GetComponent<Collider>());
				boxCollider = sprite.AddComponent<BoxCollider> ();
			}
			boxCollider.size = new Vector3 (mesh.bounds.size.x, mesh.bounds.size.y, SPRITE_THICKNESS_BASE + SPRITE_THICKNESS_RANDOM * Random.value);
			boxCollider.isTrigger = !hasRigidBody;
		}

		// Check whether the sprite shall have a rigid body
		if (hasRigidBody) {

			// Setup a rigid body
			Rigidbody rigidbody = sprite.GetComponent<Rigidbody>() ? sprite.GetComponent<Rigidbody>() : sprite.AddComponent<Rigidbody> ();
			rigidbody.constraints = RigidbodyConstraints.FreezePositionZ | RigidbodyConstraints.FreezeRotationX | RigidbodyConstraints.FreezeRotationY;
			rigidbody.mass = density * area;
		} else {

			// Destroy any existing rigid body
			GameObject.Destroy (sprite.GetComponent<Rigidbody>());
		}

		// Done!
		return sprite;
	}

	/**
	 * Check whether 2 segments intersect.
	 *
	 * @param pointA1 One end of the first segment.
	 * @param pointB1 Other end of the first segment.
	 * @param pointA2 One end of the second segment.
	 * @param pointB2 Other end of the second segment.
	 * @param distanceFromPointA1 Relative distance between the intersection and the first end of the first segment.
	 * @param isA1OnLeftOfA2B2 True if the point A1 is on the left side of the segment A2-B2.
	 * @return True if the segment intersects the line, false otherwise.
	 */
	static bool SegmentsIntersect (Vector2 pointA1, Vector2 pointB1, Vector2 pointA2, Vector2 pointB2, out float distanceFromPointA1, out bool isA1OnLeftOfA2B2)
	{
		Vector2 segment1 = pointB1 - pointA1;
		Vector2 segment2 = pointB2 - pointA2;
		Vector2 deltaOrigin = pointA1 - pointA2;

		float denominator = segment2.x * segment1.y - segment2.y * segment1.x;
		isA1OnLeftOfA2B2 = denominator > 0.0f;
		if (denominator == 0.0f) {
			distanceFromPointA1 = 0.0f;
			return false;
		}

		float distanceFromPointA2 = (segment1.y * deltaOrigin.x - segment1.x * deltaOrigin.y) / denominator;
		if (distanceFromPointA2 < 0.0f || distanceFromPointA2 > 1.0f) {
			distanceFromPointA1 = 0.0f;
			return false;
		}

		distanceFromPointA1 = (segment2.y * deltaOrigin.x - segment2.x * deltaOrigin.y) / denominator;
		return distanceFromPointA1 >= 0.0f && distanceFromPointA1 <= 1.0f;
	}

	/**
	 * Slice a sprite.
	 *
	 * @param collider Collider which must be sliced.
	 * @param pointA One end of the segment.
	 * @param pointB One end of the segment.
	 * @param acceleration Acceleration used to push pieces apart.
	 * @return Number of sprites created.
	 */
	static int Slice (Collider collider, Vector2 pointA, Vector2 pointB, float acceleration = 0.0f)
	{
		// Get the mesh of the sprite
		MeshCollider meshCollider = collider as MeshCollider;
		if (!meshCollider || !meshCollider.sharedMesh) {
			return 0;
		}
		Mesh mesh = meshCollider.sharedMesh;

		// Get the sprite information
		GameObject sprite = collider.gameObject;
		SpriteData spriteData;
		if (!spritesData.TryGetValue (sprite.name, out spriteData)) {
			return 0;
		}
		float halfWidth = spriteData.width * 0.5f;
		float halfHeight = spriteData.height * 0.5f;

		// Transform the slice points from the world space to the sprite local space
		Vector2 pointALocal = meshCollider.transform.InverseTransformPoint (pointA);
		Vector2 pointBLocal = meshCollider.transform.InverseTransformPoint (pointB);
		Vector2 segmentLocal = pointBLocal - pointALocal;

		// Search for intersections
		SortedList<float, int> intersectionIndexes = new SortedList<float, int> (2);
		Dictionary<int, IntersectionInfo> intersectionPoints = new Dictionary<int, IntersectionInfo> (2);
		float areaDouble = 0.0f;
		int vertexCount = mesh.vertexCount / 2;
		int indexCurrent = vertexCount - 1;
		for (int indexNext = 0; indexNext < vertexCount; ++indexNext) {
			float distanceFromPointA;
			bool isA1OnLeftOfA2B2;
			if (SegmentsIntersect (pointALocal, pointBLocal, mesh.vertices [indexCurrent], mesh.vertices [indexNext], out distanceFromPointA, out isA1OnLeftOfA2B2)) {
				intersectionIndexes.Add (distanceFromPointA, indexCurrent);
				intersectionPoints.Add (indexCurrent, new IntersectionInfo {point = pointALocal + segmentLocal * distanceFromPointA, enter = isA1OnLeftOfA2B2});
			}
			areaDouble += mesh.vertices [indexCurrent].x * mesh.vertices [indexNext].y - mesh.vertices [indexCurrent].y * mesh.vertices [indexNext].x;
			indexCurrent = indexNext;
		}

		// Make sure we have at least 2 intersections
		if (intersectionPoints.Count < 2) {
			return 0;
		}

		// Compute the area of the mesh and check whether it is inverted
		float areaTotal = areaDouble / 2;
		bool invertedMesh = false;
		if (areaTotal < 0) {
			areaTotal = -areaTotal;
			invertedMesh = true;
		}

		// If the first intersection is done from inside the shape, then remove it
		int indexFirstIntersection = intersectionIndexes.Values [0];
		if (!intersectionPoints [indexFirstIntersection].enter ^ invertedMesh) {
			intersectionIndexes.RemoveAt (0);
			intersectionPoints.Remove (indexFirstIntersection);
		}

		// If the last intersection is done from outside the shape, then remove it
		int indexLastIntersection = intersectionIndexes.Values [intersectionIndexes.Count - 1];
		if (intersectionPoints [indexLastIntersection].enter ^ invertedMesh) {
			intersectionIndexes.RemoveAt (intersectionIndexes.Count - 1);
			intersectionPoints.Remove (indexLastIntersection);
		}

		// Make sure we have an even number of intersections
		if (intersectionPoints.Count < 2 || (intersectionPoints.Count & 1) != 0) {
			return 0;
		}

		// Setup a list of contours, as well as a list to remember which contour is associated to which pair of intersections
		List<List<Vector2>> contours = new List<List<Vector2>> (2);
		List<Vector2> [] intersectionContours = new List<Vector2> [intersectionPoints.Count / 2];

		// Split the original mesh in different parts
		List<Vector2> contourCurrent = new List<Vector2> ();
		contours.Add (contourCurrent);
		for (indexCurrent = 0; indexCurrent < vertexCount; ++indexCurrent) {

			// Record the current vertex
			Vector2 vertex = mesh.vertices [indexCurrent];
			Vector2 contourPoint = new Vector3 (vertex.x + halfWidth, halfHeight - vertex.y);
			contourCurrent.Add (contourPoint);

			// Check whether we have an intersection here
			IntersectionInfo intersectionInfo;
			if (intersectionPoints.TryGetValue (indexCurrent, out intersectionInfo)) {

				// Record the intersection point
				contourPoint = new Vector3 (intersectionInfo.point.x + halfWidth, halfHeight - intersectionInfo.point.y);
				contourCurrent.Add (contourPoint);

				// Check what shall be the next contour (new one or existing one)
				int intersectionPairIndex = intersectionIndexes.IndexOfValue (indexCurrent) / 2;
				if (intersectionContours [intersectionPairIndex] == null) {
					intersectionContours [intersectionPairIndex] = contourCurrent;
					contourCurrent = new List<Vector2> ();
					contours.Add (contourCurrent);
				} else {
					contourCurrent = intersectionContours [intersectionPairIndex];
				}

				// Record the intersection point
				contourCurrent.Add (contourPoint);
			}
		}

		// Take note of the mass and compute the acceleration to push the sprites apart
		float mass;
		Vector2 accelerationVector;
		if (sprite.GetComponent<Rigidbody>()) {
			mass = sprite.GetComponent<Rigidbody>().mass;
			Vector2 segment = pointB - pointA;
			segment.Normalize ();
			accelerationVector = new Vector2 (-segment.y, segment.x) * acceleration;
		} else {
			mass = 0.0f;
			accelerationVector = Vector2.zero;
		}

		// Take care of each piece
		string name = sprite.name;
		for (int contourIndex = 0; contourIndex < contours.Count; ++contourIndex) {
			if (contourIndex > 0) {

				// Copy the existing sprite
				sprite = (GameObject)GameObject.Instantiate (sprite);
				sprite.name = name;
			}

			// Set the new mesh of the sprite
			mesh = new Mesh ();
			float area;
			bool convex = SetMesh (mesh, ref spriteData, contours [contourIndex], out area, true);
			sprite.GetComponent<MeshFilter> ().mesh = mesh;

			// Set the new mesh collider (we can assume the sprite has a collider as it is being sliced)
			meshCollider = sprite.GetComponent<MeshCollider> ();
			meshCollider.sharedMesh = mesh;
			meshCollider.convex = convex;

			// Check whether the sprite has a rigid body attached
			if (sprite.GetComponent<Rigidbody>()) {

				// Set the mass of the sprite
				sprite.GetComponent<Rigidbody>().mass = mass * area / areaTotal;

				// Push the sprite
				Vector2 centerOfMass = (Vector2)sprite.GetComponent<Rigidbody>().worldCenterOfMass - pointA;
				if (Vector2.Dot (accelerationVector, centerOfMass) < 0) {
					accelerationVector = -accelerationVector;
				}
				sprite.GetComponent<Rigidbody>().AddForce (accelerationVector, ForceMode.VelocityChange);
			}

			// Automatically delete sprites that are too small after a certain delay
			if (area < SPRITE_MINIMUM_AREA) {
				GameObject.Destroy (sprite, SPRITE_DESTROY_DELAY);
			}
		}

		// Done!
		return contours.Count - 1;
	}

	/**
	 * Slice some sprites.
	 *
	 * @param pointA One end of the segment.
	 * @param pointB Other end of the segment.
	 * @param acceleration Acceleration used to push pieces apart.
	 * @return Number of sprites created.
	 */
	public static int Slice (Vector2 pointA, Vector2 pointB, float acceleration = 0.0f)
	{
		// Search for all the sprites that collide with the segment
		int createdSpriteCount = 0;
		Vector2 direction = pointB - pointA;
		RaycastHit [] raycastHits = Physics.RaycastAll (pointA, direction, direction.magnitude, 1 << SPRITE_SLICEABLE_LAYER);
		foreach (RaycastHit raycastHit in raycastHits) {

			// Slice the sprite
			createdSpriteCount += Slice (raycastHit.collider, pointA, pointB, acceleration);
		}
		return createdSpriteCount;
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
