// Nicolas Robert [Nrx]
//
// This is a basic physics engine to simulate water, based on particles.
//
// Physics:
// - m = mass
// - A = quantity
// - d = density
// - p = pressure
// - K1 = pressure factor (stiffness)
// - K2 = viscosity factor (damping)
// - W = kernel function
// - h = smoothing length
// - G = gravity
// - a = acceleration
// - v = velocity
// - r = position
//
// SPH basics:
// Ai = SUM { mj * Aj * W(ij) / dj } = m * SUM { Aj * W(ij) / dj }
//
// Kernel:
// Wij = W (length (ri - rj), h) = (1 - length (ri - rj) / h)^3
// dWij = -3 * (1 - length (ri - rj) / h)^2
//
// Density and pressure:
// di = m * SUM { Wij }
// pi = K1 * (di - d0)
//
// Acceleration due to the gravity:
// agi = G
//
// Acceleration due to the pressure:
// api = -SUM { mj * (pi / di^2 + pj / dj^2) * dWij } = -m * K1 * SUM { ((di - d0) / di^2 + (dj - d0) / dj^2) * dWij }
//
// Acceleration due to the viscosity:
// avi = -SUM { mj * TTij * dWij } = -m * SUM { TTij * dWij }
// TTij = -K2 * cij * uij/ dij
// cij = sqrt (dp / dd) = sqrt (K1 * (di - dj) / (di - dj)) = sqrt (K1)
// uij = h * min (0, dot (vi - vj, ri - rj)) / |ri - rj|^2 = min (0, dot (vj - vi, direction)) / (length (ri - rj) / h)
// dij = (di + dj) / 2
// TTij = (K2 * sqrt (K1) * 2) * max (0, dot (vi - vj, direction)) / ((di + dj) * length (ri - rj) / h)
//
// Final acceleration
// ai = G - m * SUM { (K1 * ((di - d0) / di^2 + (dj - d0) / dj^2)) + TTij) * dWij }
//
// Integration:
// vi += ai * dt
// ri += vi * dt

// C libraries
#include <stdlib.h>
#include <math.h>
#include <time.h>

// Basic types
typedef unsigned char bool;
#define false 0
#define true 1
typedef unsigned char byte;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef struct {
	float x;
	float y;
} Vector2;

// Colliders (static elements with which fluid particles collide)
#define COLLIDER_BIT 0x8000

// Particles that represent the fluid
typedef struct {
	Vector2 position;
	Vector2 velocity;
	Vector2 acceleration;
	float density;
	float densityPrevious;
	float densityFactor;
	uint gridCellId;
	ushort nextParticleId;
} Particle;
static Particle* particles = NULL;
static ushort particleCount = 0;
static ushort particleBufferSize = 0;
typedef struct {
	Vector2 position;
	float velocity;
} ParticleData;
#define PARTICLE_DISTANCE_MINIMUM 0.1f

// Grid of cells used for collision detection
static ushort* gridCells = NULL;
static uint gridWidth = 0;
static uint gridHeight = 0;
static uint gridSize = 0;

// Sources of particles
typedef struct {
	Vector2 position;
	float velocity;
	float direction;
	float timer;
} Source;
static Source* sources = NULL;
static byte sourceCount = 0;

// Physics parameters (initialization)
typedef struct {
	ushort particleBufferSize;
	uint gridWidth;
	uint gridHeight;
	byte sourceCount;
	float timeStep;
	float particleRadius;
	float particleDensityRest;
	float particlePressureFactor;
	float particleViscosityFactor;
	float colliderSpringStiffness;
	float colliderSpringDamping;
} PhysicsParameters;

// Physics parameters (internal)
static float timeStep;
static float particleRadius;
static float particleRadiusSquared;
static float particleDensityRest;
static float particlePressureFactor;
static float particleViscosityFactor;
static float colliderSpringStiffness;
static float colliderSpringDamping;

// Approximate the norm of a 2D vector using the Coquin-Bolon's chamfer distance
inline static float Norm (Vector2* vector) {
	static const float d10 = 0.9604f;
	static const float d01 = 0.3978f; // = d10 * (sqrt (2.0f) - 1.0f)

	Vector2 absVector;
	absVector.x = vector->x > 0.0f ? vector->x : -vector->x;
	absVector.y = vector->y > 0.0f ? vector->y : -vector->y;

	return absVector.x > absVector.y ? absVector.x * d10 + absVector.y * d01 : absVector.x * d01 + absVector.y * d10;
}

// Finalize the physics engine
extern void PhysicsFinalize () {

	// Destroy the particles
	free (particles);
	particles = NULL;
	particleCount = 0;
	particleBufferSize = 0;

	// Destroy the grid of cells
	free (gridCells);
	gridCells = NULL;
	gridWidth = 0;
	gridHeight = 0;
	gridSize = 0;

	// Destroy the sources
	free (sources);
	sources = NULL;
	sourceCount = 0;
}

// Initialize the physics engine
extern bool PhysicsInitialize (PhysicsParameters* parameters) {

	// Make sure the physics engine isn't initialized already
	PhysicsFinalize ();

	// Make sure the size of the particle buffer isn't too large
	// Note: we need the highest bit of the particle identifier to store the collider information
	if (parameters->particleBufferSize & COLLIDER_BIT) {
		return false;
	}

	// Allocate the particle buffer
	particles = malloc (sizeof (Particle) * parameters->particleBufferSize);
	if (particles) {

		// Allocate (and clear) the grid of cells
		// Note: we need the collider bit to be reset in every cell
		uint gridSizeToAllocate = parameters->gridWidth * parameters->gridHeight;
		gridCells = calloc (gridSizeToAllocate, sizeof (ushort));
		if (gridCells) {

			// Allocate the source buffer
			sources = malloc (sizeof (Source) * parameters->sourceCount);
			if (sources) {

				// Initialize the particles
				particleBufferSize = parameters->particleBufferSize;

				// Initialize the grid of cells
				gridWidth = parameters->gridWidth;
				gridHeight = parameters->gridHeight;
				gridSize = gridSizeToAllocate;

				// Initialize the sources
				sourceCount = parameters->sourceCount;
				for (byte sourceId = 0; sourceId < sourceCount; ++sourceId) {
					sources [sourceId].velocity = -1.0f;
				}

				// Initialize the physics parameters
				timeStep = parameters->timeStep;
				particleRadius = parameters->particleRadius;
				particleRadiusSquared = particleRadius * particleRadius;
				particleDensityRest = parameters->particleDensityRest;
				particlePressureFactor = parameters->particlePressureFactor;
				particleViscosityFactor = parameters->particleViscosityFactor;
				colliderSpringStiffness = parameters->colliderSpringStiffness;
				colliderSpringDamping = parameters->colliderSpringDamping;

				// Initialization done
				return true;
			}

			// Destroy the grid of cells
			free (gridCells);
			gridCells = NULL;
		}

		// Destroy the particles
		free (particles);
		particles = NULL;
	}

	// Initialization failed
	return false;
}

// Handle collisions of particles within a cell
static void PhysicsCollisionInCell (ushort particleId, uint offset) {

	// Get the grid cell in which collisions have to be checked
	Particle* particle = &particles [particleId];
	uint gridCellId = particle->gridCellId + offset;
	if (gridCellId >= gridSize) {
		return;
	}

	// Check whether this grid cell is a collider
	ushort otherParticleId = gridCells [gridCellId];
	ushort colliderBit = otherParticleId & COLLIDER_BIT;
	if (colliderBit) {

		// Compute the signed distance between the center of the particle (circle) and the border of the collider (square)
		Vector2 direction;
		direction.x = (float)(gridCellId % gridWidth) + 0.5f - particle->position.x;
		direction.y = (float)(gridCellId / gridWidth) + 0.5f - particle->position.y;

		Vector2 distanceCollider;
		distanceCollider.x = (direction.x > 0.0f ? direction.x : -direction.x) - 0.5f;
		distanceCollider.y = (direction.y > 0.0f ? direction.y : -direction.y) - 0.5f;

		float distance;
		if (distanceCollider.x > 0.0f && distanceCollider.y > 0.0f) {
			float distanceSquared = distanceCollider.x * distanceCollider.x + distanceCollider.y * distanceCollider.y;
			if (distanceSquared < particleRadiusSquared) {

				// Normalize the direction
				distance = sqrt (distanceSquared);
				direction.x = (direction.x > 0.0f ? distanceCollider.x : -distanceCollider.x) / distance;
				direction.y = (direction.y > 0.0f ? distanceCollider.y : -distanceCollider.y) / distance;
			} else {
				distance = distanceCollider.x + distanceCollider.y;
			}
		} else if (distanceCollider.x > distanceCollider.y) {
			direction.x = direction.x > 0.0f ? 1.0f : -1.0f;
			direction.y = 0.0f;
			distance = distanceCollider.x;
		} else {
			direction.x = 0.0f;
			direction.y = direction.y > 0.0f ? 1.0f : -1.0f;
			distance = distanceCollider.y;
		}

		// Check whether the particle touches the collider
		if (distance < particleRadius) {

			// Apply the collision force (spring)
			float compression = 1.0f - (distance + 0.5f) / (particleRadius + 0.5f);
			float velocity = particle->velocity.x * direction.x + particle->velocity.y * direction.y;
			float acceleration = colliderSpringStiffness * compression + colliderSpringDamping * velocity;
			particle->acceleration.x -= direction.x * acceleration;
			particle->acceleration.y -= direction.y * acceleration;
		}

		// Remove the collider bit from the particle identifier
		otherParticleId &= ~COLLIDER_BIT;
	}

	// Check whether this grid cell has already been visited or not
	if (otherParticleId >= particleId || particles [otherParticleId].gridCellId != gridCellId) {

		// Check whether this particle shall be stored in this grid cell
		if (!offset) {
			gridCells [gridCellId] = particleId | colliderBit;
		}

		// This grid cell did not contain a particle, there cannot be any other collision
		return;
	}

	// Let's check collisions with all particles already stored in this grid cell
	Particle* otherParticle;
	do {
		otherParticle = &particles [otherParticleId];

		// Compute the distance between these 2 particles
		Vector2 direction;
		direction.x = otherParticle->position.x - particle->position.x;
		direction.y = otherParticle->position.y - particle->position.y;
		float distanceSquared = direction.x * direction.x + direction.y * direction.y;

		// Check whether these 2 particles touch each other
		if (distanceSquared < 4.0f * particleRadiusSquared) {

			// Make sure the 2 particles are not too close
			if (distanceSquared < PARTICLE_DISTANCE_MINIMUM * PARTICLE_DISTANCE_MINIMUM * particleRadiusSquared) {

				// Invalidate the density of this particle so that it will eventually be destroyed
				particle->density = -particleBufferSize;
				continue;
			}

			// Normalize the direction
			float distance = sqrt (distanceSquared);
			direction.x = direction.x / distance;
			direction.y = direction.y / distance;

			// Compute the density
			distance /= particleRadius + particleRadius;
			float compression = 1.0f - distance;
			float compressionSquared = compression * compression;
			float compressionCubed = compression * compressionSquared;
			particle->density += compressionCubed;
			otherParticle->density += compressionCubed;

			// Apply the pressure and viscosity forces (SPH)
			float pressure = particlePressureFactor * (particle->densityFactor + otherParticle->densityFactor);
			float velocity = (particle->velocity.x - otherParticle->velocity.x) * direction.x + (particle->velocity.y - otherParticle->velocity.y) * direction.y;
			float viscosity = velocity > 0.0f ? particleViscosityFactor * velocity / ((particle->densityPrevious + otherParticle->densityPrevious) * distance) : 0.0f;
			float acceleration = (pressure + viscosity) * 3.0f * compressionSquared;
			direction.x *= acceleration;
			direction.y *= acceleration;
			particle->acceleration.x -= direction.x;
			particle->acceleration.y -= direction.y;
			otherParticle->acceleration.x += direction.x;
			otherParticle->acceleration.y += direction.y;
		}

	// Next particle in the grid cell...
	} while ((otherParticleId = otherParticle->nextParticleId) < particleId);

	// Check whether this particle shall be stored in this grid cell
	if (!offset) {
		otherParticle->nextParticleId = particleId;
	}
}

// Update the physics engine (single step)
inline static void PhysicsUpdateStep (Vector2 externalAcceleration) {

	// Update all the sources
	for (byte sourceId = 0; sourceId < sourceCount && particleCount < particleBufferSize; ++sourceId) {

		// Make sure the source is active
		Source* source = &sources [sourceId];
		if (source->velocity <= 0.0f) {
			continue;
		}

		// Check whether it is time to create a new particle
		if (source->timer > 0.0f) {
			source->timer -= timeStep;
			continue;
		}

		// Check the position of the particle to create
		uint x = (int)source->position.x;
		uint y = (int)source->position.y;
		if (x >= gridWidth || y >= gridHeight || (gridCells [x + y * gridWidth] & COLLIDER_BIT)) {
			continue;
		}

		// Create a particle
		Particle* particle = &particles [particleCount++];
		particle->position.x = source->position.x;
		particle->position.y = source->position.y;
		particle->velocity.x = source->velocity * cos (source->direction);
		particle->velocity.y = source->velocity * sin (source->direction);
		particle->acceleration.x = 0.0f;
		particle->acceleration.y = 0.0f;
		particle->density = 1.0f;

		// Schedule the creation of the next particle
		source->timer = 2.0f * particleRadius / source->velocity;
	}

	// Update all the particles
	for (ushort particleId = 0; particleId < particleCount; ++particleId) {

		// Clear the list of particles linked to this one
		Particle* particle = &particles [particleId];
		particle->nextParticleId = particleBufferSize;

		// Update the velocity of the particle using the acceleration computed at the last update
		particle->velocity.x += particle->acceleration.x * timeStep;
		particle->velocity.y += particle->acceleration.y * timeStep;

		// Update the position of the particle using its current velocity
		particle->position.x += particle->velocity.x * timeStep;
		particle->position.y += particle->velocity.y * timeStep;

		// Check the new position of this particle in the grid of cells (also check its density...)
		uint x = (int)particle->position.x;
		uint y = (int)particle->position.y;
		if (x >= gridWidth || y >= gridHeight || particle->density < 1.0f) {

			// Destroy this particle (replace it by the last one of the list)
			--particleCount;
			Particle* otherParticle = &particles [particleCount];
			particle->position.x = otherParticle->position.x;
			particle->position.y = otherParticle->position.y;
			particle->velocity.x = otherParticle->velocity.x;
			particle->velocity.y = otherParticle->velocity.y;
			particle->acceleration.x = otherParticle->acceleration.x;
			particle->acceleration.y = otherParticle->acceleration.y;
			particle->density = otherParticle->density;

			// Let's process this particle again...
			--particleId;
			continue;
		}
		particle->gridCellId = x + y * gridWidth;

		// Initialize the acceleration using the external acceleration
		particle->acceleration.x = externalAcceleration.x;
		particle->acceleration.y = externalAcceleration.y;

		// Initialize the density of the particle
		particle->densityPrevious = particle->density;
		particle->densityFactor = (particle->density - particleDensityRest) / (particle->density * particle->density);
		particle->density = 1.0f;

		// Check for collisions with other particles (both in the current grid cell and its neighbors)
		// Note: we don't care about useless collision tests due to horizontal wrapping
		int collisionRadius = (int)ceil (particleRadius + particleRadius);
		for (int y = -collisionRadius; y <= collisionRadius; ++y) {
			for (int x = -collisionRadius; x <= collisionRadius; ++x) {
				PhysicsCollisionInCell (particleId, x + y * gridWidth);
			}
		}
	}
}

// Update the physics engine
extern bool PhysicsUpdate (Vector2 gravityAcceleration, float dt, float durationMax) {

	// Set a time limit
	clock_t timeLimit = clock () + durationMax * CLOCKS_PER_SEC;

	// Update the physics, using a constant (small) time step
	static float time = 0.0f;
	for (time += dt; time >= timeStep; time -= timeStep) {

		// Do a single step of the physics update
		PhysicsUpdateStep (gravityAcceleration);

		// Make sure we aren't too slow
		if (clock () > timeLimit) {

			// Abort the update
			time = 0.0f;
			return false;
		}
	}

	// Update completed successfully
	return true;
}

// Set a collider (create or remove it)
extern bool ColliderSet (Vector2 position, bool set) {

	// Make sure the position is inside the grid of cells
	uint x = (int)position.x;
	uint y = (int)position.y;
	if (x >= gridWidth || y >= gridHeight) {
		return false;
	}

	// Check whether this cell shall be a collider
	uint gridCellId = x + y * gridWidth;
	ushort particleId = gridCells [gridCellId] & ~COLLIDER_BIT;
	if (set) {

		// Check whether this cell has some particles
		Particle* particle;
		while (particleId < particleCount && (particle = &particles [particleId])->gridCellId == gridCellId) {

			// Reset the density of the particle so that it will be destroyed
			particle->density = 0.0f;

			// Next particle in this grid cell...
			particleId = particle->nextParticleId;
		}

		// Add the collider bit
		particleId |= COLLIDER_BIT;
	}

	// Set this collider
	gridCells [gridCellId] = particleId;

	// The collider has been set successfully
	return true;
}

// Check whether there is a collider at a given position
extern bool ColliderCheck (Vector2 position) {

	// Make sure the position is inside the grid of cells
	uint x = (int)position.x;
	uint y = (int)position.y;
	if (x >= gridWidth || y >= gridHeight) {
		return false;
	}

	// Check whether this cell is a collider
	return gridCells [x + y * gridWidth] & COLLIDER_BIT ? true : false;
}

// Set the collider texture
extern void ColliderTextureSet (byte* texture, uint textureSize) {
	if (textureSize > gridSize) {
		textureSize = gridSize;
	}
	for (uint gridCellId = 0; gridCellId < textureSize; ++gridCellId) {
		texture [gridCellId] = gridCells [gridCellId] & COLLIDER_BIT ? -1 : 0;
	}
}

// Create a particle
extern bool ParticleCreate (Vector2 position, Vector2 velocity) {

	// Make sure we still have room for a new particle
	if (particleCount >= particleBufferSize) {

		// The particle cannot be stored in the buffer
		return false;
	}

	// Check the initial position of this particle in the grid of cells
	uint x = (int)position.x;
	uint y = (int)position.y;
	if (x >= gridWidth || y >= gridHeight || gridCells [x + y * gridWidth] & COLLIDER_BIT) {

		// The particle is outside the grid of cells or inside a collider
		return false;
	}

	// Complete the initialization of the particle
	Particle* particle = &particles [particleCount];
	particle->position.x = position.x;
	particle->position.y = position.y;
	particle->velocity.x = velocity.x;
	particle->velocity.y = velocity.y;
	particle->acceleration.x = 0.0f;
	particle->acceleration.y = 0.0f;
	particle->density = 1.0f;

	// The particle has been created successfully
	++particleCount;
	return true;
}

// Check whether there is a particle at a given position
// Note: this function only checks whether there is at least one particle in the corresponding grid cell; if we wanted to be
// more precise, then we would need to check the actual distance to each particle of the cell, as well as to particles in the
// adjacent cells (although we could return "true" as soon as there is a match)
extern bool ParticleCheck (Vector2 position) {

	// Make sure the position is inside the grid of cells
	uint x = (int)position.x;
	uint y = (int)position.y;
	if (x >= gridWidth || y >= gridHeight) {
		return false;
	}

	// Check whether this cell has some particles
	uint gridCellId = x + y * gridWidth;
	ushort particleId = gridCells [gridCellId] & ~COLLIDER_BIT;
	return particleId < particleCount && particles [particleId].gridCellId == gridCellId;
}

// Return the current number of particles, as well as -optionally- the position and velocity of all existing particles
extern ushort ParticleCount (ParticleData* particleData, ushort particleDataSize) {

	// Check whether there is an array to store the particles data
	if (particleData) {

		// Store the position and velocity of all existing particles
		if (particleDataSize > particleCount) {
			particleDataSize = particleCount;
		}
		for (ushort particleId = 0; particleId < particleDataSize; ++particleId) {
			Particle* particle = &particles [particleId];
			particleData->position.x = particle->position.x;
			particleData->position.y = particle->position.y;
			particleData->velocity = Norm (&particle->velocity);
			++particleData;
		}
	}

	// Return the current number of particles
	return particleCount;
}

// Return the position and velocity of a given particle (negative velocity if the particle doesn't exist)
extern float ParticleInfo (ushort particleId, Vector2* position) {

	// Make sure the particle exists
	if (particleId >= particleCount) {
		return -1.0f;
	}

	// Get the position of the particle
	Particle* particle = &particles [particleId];
	position->x = particle->position.x;
	position->y = particle->position.y;

	// Return the velocity of the particle
	return Norm (&particle->velocity);
}

// Create a source
extern bool SourceCreate (byte sourceId, Vector2 position, float velocity, float direction) {

	// Make sure the source identifier is valid
	if (sourceId >= sourceCount) {
		return false;
	}

	// Check the position of the source
	uint x = (int)position.x;
	uint y = (int)position.y;
	if (x >= gridWidth || y >= gridHeight) {

		// The source is outside the grid of cells
		return false;
	}

	// Register this source
	Source* source = &sources [sourceId];
	source->position.x = position.x;
	source->position.y = position.y;
	source->velocity = velocity;
	source->direction = direction;
	source->timer = 0.0f;

	// The source has been created successfully
	return true;
}

// Update the velocity and direction of a source
// Note: one can set the velocity to a negative value to stop the source
extern bool SourceUpdate (byte sourceId, float velocity, float direction) {

	// Make sure the source identifier is valid
	if (sourceId >= sourceCount) {
		return false;
	}

	// Udpate the velocity and direction of the source
	sources [sourceId].velocity = velocity;
	sources [sourceId].direction = direction;
	return true;
}
