// Nicolas Robert [Nrx]
//
// C# interface of the little physics engine "LiquidNrx" (C plugin).

using UnityEngine;
using System.Runtime.InteropServices;

public class Liquid
{
	// Initialize the physics engine
	public struct PhysicsParameters
	{
		public ushort particleBufferSize;
		public uint gridWidth;
		public uint gridHeight;
		public byte sourceCount;
		public float timeStep;
		public float particleRadius;
		public float particleDensityRest;
		public float particlePressureFactor;
		public float particleViscosityFactor;
		public float colliderSpringStiffness;
		public float colliderSpringDamping;
	}
	#if UNITY_IPHONE
	[DllImport ("__Internal")]
	#else
	[DllImport ("Liquid")]
	#endif
	public static extern bool PhysicsInitialize (ref PhysicsParameters parameters);

	// Finalize the physics engine
	#if UNITY_IPHONE
	[DllImport ("__Internal")]
	#else
	[DllImport ("Liquid")]
	#endif
	public static extern void PhysicsFinalize ();

	// Update the physics engine
	#if UNITY_IPHONE
	[DllImport ("__Internal")]
	#else
	[DllImport ("Liquid")]
	#endif
	public static extern bool PhysicsUpdate (Vector2 gravityAcceleration, float dt, float durationMax);

	// Set a collider (create or remove it)
	#if UNITY_IPHONE
	[DllImport ("__Internal")]
	#else
	[DllImport ("Liquid")]
	#endif
	public static extern bool ColliderSet (Vector2 position, bool set);

	// Check whether there is a collider at a given position
	#if UNITY_IPHONE
	[DllImport ("__Internal")]
	#else
	[DllImport ("Liquid")]
	#endif
	public static extern bool ColliderCheck (Vector2 position);

	// Set the collider texture
	#if UNITY_IPHONE
	[DllImport ("__Internal")]
	#else
	[DllImport ("Liquid")]
	#endif
	public static extern void ColliderTextureSet (System.IntPtr texture, uint textureSize);

	// Create a particle
	#if UNITY_IPHONE
	[DllImport ("__Internal")]
	#else
	[DllImport ("Liquid")]
	#endif
	public static extern bool ParticleCreate (Vector2 position, Vector2 velocity);

	// Check whether there is a particle at a given position
	// Note: this function only checks whether there is at least one particle in the corresponding grid cell; if we wanted to be
	// more precise, then we would need to check the actual distance to each particle of the cell, as well as to particles in the
	// adjacent cells (although we could return "true" as soon as there is a match)
	#if UNITY_IPHONE
	[DllImport ("__Internal")]
	#else
	[DllImport ("Liquid")]
	#endif
	public static extern bool ParticleCheck (Vector2 position);

	// Return the current number of particles, as well as -optionally- the position and velocity of all existing particles
	public struct ParticleData
	{
		public Vector2 position;
		public float velocity;
	}
	#if UNITY_IPHONE
	[DllImport ("__Internal")]
	#else
	[DllImport ("Liquid")]
	#endif
	public static extern ushort ParticleCount (System.IntPtr particleData = default (System.IntPtr), ushort particleDataSize = 0);

	// Return the position and velocity of a given particle (negative velocity if the particle doesn't exist)
	#if UNITY_IPHONE
	[DllImport ("__Internal")]
	#else
	[DllImport ("Liquid")]
	#endif
	public static extern float ParticleInfo (ushort particleId, out Vector2 position);

	// Create a source
	#if UNITY_IPHONE
	[DllImport ("__Internal")]
	#else
	[DllImport ("Liquid")]
	#endif
	public static extern bool SourceCreate (byte sourceId, Vector2 position, float velocity = -1.0f, float direction = 0.0f);

	// Update the velocity and direction of a source
	// Note: one can set the velocity to a negative value to stop the source
	#if UNITY_IPHONE
	[DllImport ("__Internal")]
	#else
	[DllImport ("Liquid")]
	#endif
	public static extern bool SourceUpdate (byte sourceId, float velocity, float direction);
}
