// Nicolas Robert [Nrx]
using UnityEngine;

public partial class Maze
{
	// Element
	[System.Serializable]
	public class Element {
		public Vector3 position;
		[System.NonSerialized]
		public Vector3 speed;
		[System.NonSerialized]
		public Vector3 force;
		public float friction;
		public float radius;
		public float elasticity;
	}

	// Head
	[System.Serializable]
	public class Head : Element {
		[System.NonSerialized]
		public Matrix4x4 orientation;
		[System.Serializable]
		public struct Tweaking {
			public float friction;
			public float elasticity;
			public float forceOrientation;
		}
		public Tweaking pinballOff;
		public Tweaking pinballOn;
		public UnityEngine.UI.Toggle pinballToggle;
	}

	// Light ball
	[System.Serializable]
	public class LightBall : Element {
		public float aheadDistance;
		public float movementAmplitude;
		public float forceSpringStiffness;
		public float forceMaxSqr;
		public float collisionTimer;
		public float collisionTimerMax;
	}

	// GLSL fract function
	private static float Fract (float x) {
		return x - Mathf.Floor (x);
	}

	// PRNG (predictable)
	// Note: it's important to have the *exact* same results as the GLSL version!
	private static float RandPredictable (int seedX, int seedY, int seedZ) {
		return Fract (11.0f * Mathf.Sin (3.0f * seedX + 5.0f * seedY + 7.0f * seedZ));
	}

	// Check whether there is a block at a given position
	// Note: it's important to have the *exact* same results as the GLSL version!
	private static bool Block (int blockX, int blockY, int blockZ) {
		int blockSum = (blockX & 1) + (blockY & 1) + (blockZ & 1);
		return ((blockSum < 2) || (blockSum < 3) && (RandPredictable (blockX, blockY, blockZ) >= 0.5f)) &&
			((blockX & 31) > 4) &&
			((blockY & 15) > 2) &&
			((blockZ & 31) > 4);
	}

	// React to collisions
	private static void CollisionReact (Element element, Vector3 positionRelative)
	{
		// Compute the position relative to the actual hit point
		if (positionRelative.x < 0.0f) {
			positionRelative.x += 0.5f;
		} else if (positionRelative.x > 0.0f) {
			positionRelative.x -= 0.5f;
		}
		if (positionRelative.y < 0.0f) {
			positionRelative.y += 0.5f;
		} else if (positionRelative.y > 0.0f) {
			positionRelative.y -= 0.5f;
		}
		if (positionRelative.z < 0.0f) {
			positionRelative.z += 0.5f;
		} else if (positionRelative.z > 0.0f) {
			positionRelative.z -= 0.5f;
		}

		// Make sure there is a hit
		float distance = positionRelative.magnitude;
		if (distance < element.radius) {

			// Compute the normalized direction of the hit
			positionRelative /= distance;

			// Upate the position
			distance -= element.radius;
			element.position -= positionRelative * distance;

			// Update the speed
			element.speed -= (1.0f + element.elasticity) * Vector3.Dot (element.speed, positionRelative) * positionRelative;
		}
	}

	// Detect collisions
	// Note: here, the "element" is a ball, and the environment is made of cubes ("blocks")
	private static void CollisionDetect (Element element)
	{
		// Get the position of the current block
		int positionBlockX = Mathf.FloorToInt (element.position.x + 0.5f);
		int positionBlockY = Mathf.FloorToInt (element.position.y + 0.5f);
		int positionBlockZ = Mathf.FloorToInt (element.position.z + 0.5f);

		// There is no collision if we are inside a block already
		if (Block (positionBlockX, positionBlockY, positionBlockZ)) {
			return;
		}

		// Compute the relative position within the block
		Vector3 positionRelative;
		positionRelative.x = element.position.x - positionBlockX;
		positionRelative.y = element.position.y - positionBlockY;
		positionRelative.z = element.position.z - positionBlockZ;

		// Check whether we are close to a side of the current block
		float limit = 0.5f - element.radius;
		bool checkX = Mathf.Abs (positionRelative.x) > limit;
		bool checkY = Mathf.Abs (positionRelative.y) > limit;
		bool checkZ = Mathf.Abs (positionRelative.z) > limit;
		if (!(checkX || checkY || checkZ)) {
			return;
		}

		// Prepare to check nearby blocks
		int positionBlockNextX = positionRelative.x < 0.0f ? positionBlockX - 1 : positionBlockX + 1;
		int positionBlockNextY = positionRelative.y < 0.0f ? positionBlockY - 1 : positionBlockY + 1;
		int positionBlockNextZ = positionRelative.z < 0.0f ? positionBlockZ - 1 : positionBlockZ + 1;

		// Handle collisions with the sides
		// Note: we could call "CollisionReact" here, but let's optimize a bit and directly compute the position & speed...
		if (checkX && Block (positionBlockNextX, positionBlockY, positionBlockZ)) {
			checkX = false;
			element.position.x = positionRelative.x < 0.0f ? positionBlockX - limit : positionBlockX + limit;
			element.speed.x *= -element.elasticity;
		}
		if (checkY && Block (positionBlockX, positionBlockNextY, positionBlockZ)) {
			checkY = false;
			element.position.y = positionRelative.y < 0.0f ? positionBlockY - limit : positionBlockY + limit;
			element.speed.y *= -element.elasticity;
		}
		if (checkZ && Block (positionBlockX, positionBlockY, positionBlockNextZ)) {
			checkZ = false;
			element.position.z = positionRelative.z < 0.0f ? positionBlockZ - limit : positionBlockZ + limit;
			element.speed.z *= -element.elasticity;
		}

		// Take note of whether we have to check the collision with the corner
		bool checkXYZ = checkX && checkY && checkZ;

		// Handle collisions with the edges
		if (checkX && checkY && Block (positionBlockNextX, positionBlockNextY, positionBlockZ)) {
			checkXYZ = false;
			CollisionReact (element, new Vector3 (positionRelative.x, positionRelative.y, 0.0f));
		}
		if (checkY && checkZ && Block (positionBlockX, positionBlockNextY, positionBlockNextZ)) {
			checkXYZ = false;
			CollisionReact (element, new Vector3 (0.0f, positionRelative.y, positionRelative.z));
		}
		if (checkZ && checkX && Block (positionBlockNextX, positionBlockY, positionBlockNextZ)) {
			checkXYZ = false;
			CollisionReact (element, new Vector3 (positionRelative.x, 0.0f, positionRelative.z));
		}

		// Handle the collision with the corner
		if (checkXYZ && Block (positionBlockNextX, positionBlockNextY, positionBlockNextZ)) {
			CollisionReact (element, positionRelative);
		}
	}

	// Handle movements
	private static void Move (Element element, bool collide)
	{
		// Handle the friction
		element.force -= element.speed * element.friction;

		// Update the speed
		element.speed += element.force * Time.deltaTime;

		// Compute the movement
		float speed = element.speed.magnitude;
		float movementLength = speed * Time.deltaTime;
		Vector3 movementDirection = element.speed / speed;

		// Move towards the destination by small increments, to make sure we detect all collisions
		// Note: we could optimize this by going faster when within the inner part of a block, far from the sides
		// ...but this isn't really needed, so let's keep it simple
		if (collide && element.radius > 0.0f) {
			while (movementLength > element.radius) {
				element.position += element.radius * movementDirection;
				movementLength -= element.radius;
				CollisionDetect (element);
			}
		}
		element.position += movementLength * movementDirection;
		if (collide) {
			CollisionDetect (element);
		}
	}

	// Set the orientation (either from the gyroscope, or using the mouse coordinates)
	private static void OrientationSet (ref Matrix4x4 orientation)
	{
		if (Input.gyro.enabled) {

			// Get the attitude (orientation in space) of the device
			// Note: here, when building the matrix, we invert q.z and q.w and also apply a rotation of 90 degrees on the X axis
			Quaternion q = Input.gyro.attitude;
			float qxx = q.x * q.x;
			float qxy = q.x * q.y;
			float qxz = q.x * q.z;
			float qxw = q.x * q.w;
			float qyy = q.y * q.y;
			float qyz = q.y * q.z;
			float qyw = q.y * q.w;
			float qzz = q.z * q.z;
			float qzw = q.z * q.w;

			orientation [0, 0] = 1.0f - 2.0f * (qyy + qzz);
			orientation [1, 0] = 2.0f * (qxz - qyw);
			orientation [2, 0] = 2.0f * (qxy + qzw);
			orientation [0, 1] = 2.0f * (qxy - qzw);
			orientation [1, 1] = 2.0f * (qxw + qyz);
			orientation [2, 1] = 1.0f - 2.0f * (qxx + qzz);
			orientation [0, 2] = -2.0f * (qxz + qyw);
			orientation [1, 2] = 2.0f * (qxx + qyy) - 1.0f;
			orientation [2, 2] = 2.0f * (qxw - qyz);
		} else {

			// Get the position of the mouse
			float yawAngle = -2.0f * Mathf.PI * (Input.mousePosition.x / Screen.width - 0.5f);
			float pitchAngle = Mathf.PI * (Input.mousePosition.y / Screen.height - 0.5f);

			float cosYaw = Mathf.Cos (yawAngle);
			float sinYaw = Mathf.Sin (yawAngle);
			float cosPitch = Mathf.Cos (pitchAngle);
			float sinPitch = Mathf.Sin (pitchAngle);

			orientation [0, 0] = cosYaw;
			orientation [1, 0] = 0.0f;
			orientation [2, 0] = -sinYaw;
			orientation [0, 1] = sinYaw * sinPitch;
			orientation [1, 1] = cosPitch;
			orientation [2, 1] = cosYaw * sinPitch;
			orientation [0, 2] = sinYaw * cosPitch;
			orientation [1, 2] = -sinPitch;
			orientation [2, 2] = cosYaw * cosPitch;
		}
	}
}
