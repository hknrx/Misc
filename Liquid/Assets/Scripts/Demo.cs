// Nicolas Robert [Nrx]
//
// Demonstration of the little physics engine "LiquidNrx" (C plugin).
//
// TODO:
// - Add new methods to the library (not to "Demo.cs") to make it possible to create various colliders (point, line,
//   rounded box, etc., with both an outer and inner radius in each case), as well as blocks and flows of particles.
//   A solution might be to create colliders in a shader, using distance functions, then update the buffer using the
//   texture? Note: Once new methods will be available, all templates should be updated accordingly.
// - Port all the GLSL code to Unity shader code, then enable Metal for iOS.
// - Don't always animate the background, but just render it to a static texture? (= option to disable the animation?)
// - Implement a Temporal AA to improve the quality?
// - Add a button to open/close the sources? (Just tap on the fill rate label?)
// - Replace the edit checkbox by 3 buttons: an eraser (big), and two pens (small + big).

using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Runtime.InteropServices;

public class Demo : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
{
	// Camera
	private Camera localCamera;

	// Rendering (colliders)
	public Material colliderMaterial;
	private Material colliderMaterialCopy;
	private Texture2D colliderTexture;
	private GCHandle colliderPixelsHandle;
	private float colliderScaleX;

	// Rendering (particles)
	public Material particleMaterial;
	private Material particleMaterialCopy;
	private GameObject particleObject;
	private Mesh particleMesh;
	private Liquid.ParticleData[] particleData;
	private GCHandle particleDataHandle;
	private const float PARTICLE_VELOCITY_COLOR_FACTOR = 0.01f;

	// Simulation parameters
	private const uint GRID_SIZE = 110;
	private const float GRAVITY_ACCELERATION = 9.8f * 8.0f;
	private const float PARTICLE_PACKING_FACTOR = 0.8f;
	private const float PARTICLE_RANDOM_FACTOR = 0.05f;
	private const float SIMULATION_LOAD_MAX = 0.5f;
	public Liquid.PhysicsParameters physicsParameters = new Liquid.PhysicsParameters {
		particleBufferSize = 1400,
		sourceCount = 2,
		timeStep = 0.004f,
		particleRadius = 0.7f,
		particleDensityRest = 0.5f,
		particlePressureFactor = 3000.0f,
		particleViscosityFactor = 30.0f,
		colliderSpringStiffness = 16000.0f,
		colliderSpringDamping = 60.0f,
	};

	// Collider path system
	private Vector2 colliderPosition;
	private bool colliderSet;

	// List of all available templates
	private static readonly Template[] TEMPLATES = new Template [] {
		new TemplateSimpleContainer (),
		new TemplateFountain (),
		new TemplateSandglass (),
		new TemplateCommunicatingVessels (),
		new TemplateRain (),
		new TemplatePressureCooker (),
		new TemplateWaterFlow (),
		new TemplatePachinko (),
		new TemplateCircle (),
		new TemplateEmpty ()
	};
	private int template = 0;

	// Allow to dynamically enable/disable the debug mode
	public Toggle debugToggle;

	// Allow to dynamically edit the colliders
	public Toggle editToggle;

	// Allow to dynamically change the resolution
	public Toggle resolutionToggle;

	// Allow to dynamically pause the simulation
	public Text pauseLabel;
	private bool pauseToggle = true;

	// Allow to display the fill rate
	public Text fillRateLabel;

	// Frame rate measurement
	public Text frameRateLabel;
	private float frameTimer = 0.0f;
	private int frameCount;

	// Time
	private float time = 0.0f;

	// Touch
	private Vector3 touch = Vector3.zero;

	// Set the touch variable
	private void TouchUpdate (PointerEventData eventData, float z)
	{
		touch.x = ((eventData.position.x / Screen.width - 0.5f) * colliderScaleX + 0.5f) * physicsParameters.gridWidth;
		touch.y = eventData.position.y * physicsParameters.gridHeight / Screen.height;
		touch.z = z;
	}

	// Reset the touch
	private void TouchReset ()
	{
		touch.z = 0.0f;
	}

	// Start the path of colliders
	public void ColliderPathStart (Vector2 position, bool set = true)
	{
		// Register the start position and edit the collider at this position
		colliderPosition = new Vector2 (Mathf.Floor (position.x) + 0.5f, Mathf.Floor (position.y) + 0.5f);
		colliderSet = set;
		Liquid.ColliderSet (colliderPosition, colliderSet);
	}

	// Continue the path of colliders
	public void ColliderPathContinue (Vector2 position)
	{
		// Edit colliders along a segment from the previous to the new position
		position = new Vector2 (Mathf.Floor (position.x) + 0.5f, Mathf.Floor (position.y) + 0.5f);
		Vector2 deltaPosition = position - colliderPosition;
		float deltaMax = Mathf.Max (Mathf.Abs (deltaPosition.x), Mathf.Abs (deltaPosition.y));
		deltaPosition /= deltaMax;
		for (int step = Mathf.RoundToInt (deltaMax); step --> 0;) {
			colliderPosition += deltaPosition;
			Liquid.ColliderSet (colliderPosition, colliderSet);
		}
	}

	// Refresh the texture used to render the colliders
	private void ColliderTextureRefresh ()
	{
		byte[] colliderPixels = (byte[])colliderPixelsHandle.Target;
		Liquid.ColliderTextureSet (colliderPixelsHandle.AddrOfPinnedObject (), (uint)colliderPixels.Length);
		colliderTexture.LoadRawTextureData (colliderPixels);
		colliderTexture.Apply ();
	}

	// Create a block of particles
	public void ParticleBlockCreate (Vector2 positionCorner, Vector2 positionOppositeCorner)
	{
		float left = Mathf.Floor (Mathf.Min (positionCorner.x, positionOppositeCorner.x)) + 0.5f;
		float right = Mathf.Floor (Mathf.Max (positionCorner.x, positionOppositeCorner.x)) + 0.5f;
		float bottom = Mathf.Floor (Mathf.Min (positionCorner.y, positionOppositeCorner.y)) + 0.5f;
		float top = Mathf.Floor (Mathf.Max (positionCorner.y, positionOppositeCorner.y)) + 0.5f;

		float radius = physicsParameters.particleRadius * PARTICLE_PACKING_FACTOR;

		float delta = top - bottom - radius * 2.0f;
		float dy = Mathf.Max (radius, delta / Mathf.Floor (delta / radius));
		bottom += radius;
		top -= radius * 0.99f;

		delta = right - left - radius * 2.0f;
		float dx = Mathf.Max (radius * 2.0f * 1.732f, 2.0f * delta / Mathf.Floor (delta / (radius * 1.732f)));
		left += radius;
		right -= radius * 0.99f;

		Vector2 velocityNull = new Vector2 (0.0f, 0.0f);
		delta = 0.0f;
		for (float y = bottom; y <= top; y += dy) {
			for (float x = left + delta; x <= right; x += dx) {
				Liquid.ParticleCreate (new Vector2 (x, y) + Random.insideUnitCircle * PARTICLE_RANDOM_FACTOR, velocityNull);
			}
			delta = delta > 0.0f ? 0.0f : dx * 0.5f;
		}
	}

	// Setup the simulation
	private void SimulationSetup ()
	{
		// Reset the touch
		TouchReset ();

		// Initialize the physics engine
		if (!Liquid.PhysicsInitialize (ref physicsParameters)) {
			Debug.LogError ("The physics engine couldn't be initialized...");
			return;
		}

		// Setup the template
		TEMPLATES [template].Setup (this);

		// Refresh the texture used to render the colliders
		ColliderTextureRefresh ();
	}

	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Disable screen dimming
		Screen.sleepTimeout = SleepTimeout.NeverSleep;

		// Get the camera
		localCamera = GetComponent <Camera> ();

		// Set the resolution
		DelegateResolutionToggle (!resolutionToggle || resolutionToggle.isOn);

		// Define the size of the grid of cells
		if (localCamera.aspect > 1.0f) {
			physicsParameters.gridWidth = GRID_SIZE;
			colliderScaleX = GRID_SIZE / localCamera.aspect;
			physicsParameters.gridHeight = (uint)(colliderScaleX + 0.5f);
			colliderScaleX = physicsParameters.gridHeight / colliderScaleX;
		} else {
			colliderScaleX = GRID_SIZE * localCamera.aspect;
			physicsParameters.gridWidth = (uint)(colliderScaleX + 0.5f);
			colliderScaleX /= physicsParameters.gridWidth;
			physicsParameters.gridHeight = GRID_SIZE;
		}

		// Set the size of the camera
		localCamera.orthographicSize = 0.5f * physicsParameters.gridHeight;

		// Set the size of the box collider used to catch touch events
		BoxCollider2D boxCollider2D = GetComponent <BoxCollider2D> ();
		if (boxCollider2D) {
			boxCollider2D.size = new Vector2 (physicsParameters.gridWidth, physicsParameters.gridHeight);
		} else {
			Debug.LogErrorFormat ("A BoxCollider2D component needs to be added to {0}...", name);
		}

		// Create a texture to render the colliders
		colliderTexture = new Texture2D ((int)physicsParameters.gridWidth, (int)physicsParameters.gridHeight, TextureFormat.Alpha8, false);
		colliderTexture.filterMode = FilterMode.Point;
		colliderTexture.wrapMode = TextureWrapMode.Clamp;
		byte[] colliderPixels = new byte [physicsParameters.gridWidth * physicsParameters.gridHeight];
		colliderPixelsHandle = GCHandle.Alloc (colliderPixels, GCHandleType.Pinned);
		if (colliderMaterial) {
			colliderMaterialCopy = (Material)Object.Instantiate (colliderMaterial);
			colliderMaterialCopy.SetTexture ("colliders", colliderTexture);
			colliderMaterialCopy.SetVector ("gridSize", new Vector2 (physicsParameters.gridWidth, physicsParameters.gridHeight));
			colliderMaterialCopy.SetFloat ("scaleX", colliderScaleX);
		} else {
			Debug.LogError ("The collider material hasn't been assigned in the Unity editor...");
		}

		// Create a game object to render all the particles
		particleObject = new GameObject ("Particles");
		particleObject.isStatic = true;
		particleObject.transform.position = new Vector2 (-0.5f * physicsParameters.gridWidth, -0.5f * physicsParameters.gridHeight);
		particleObject.layer = 8;

		// Create a mesh filter and its mesh
		particleMesh = new Mesh ();
		MeshFilter meshFilter = particleObject.AddComponent <MeshFilter> ();
		meshFilter.mesh = particleMesh;

		// Create a mesh renderer
		MeshRenderer meshRenderer = particleObject.AddComponent <MeshRenderer> ();
		meshRenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
		meshRenderer.receiveShadows = false;
		if (particleMaterial) {
			particleMaterialCopy = (Material)Object.Instantiate (particleMaterial);
			meshRenderer.sharedMaterial = particleMaterialCopy;
		} else {
			Debug.LogError ("The particle material hasn't been assigned in the Unity editor...");
		}
		meshRenderer.useLightProbes = false;
		meshRenderer.reflectionProbeUsage = UnityEngine.Rendering.ReflectionProbeUsage.Off;

		// Create an array to store the position and velocity of all existing particles
		if (particleData == null) {
			particleData = new Liquid.ParticleData [physicsParameters.particleBufferSize];
			particleDataHandle = GCHandle.Alloc (particleData, GCHandleType.Pinned);
		}

		// Initialize the simulation
		SimulationSetup ();

		// Initialize the GUI (pause button)
		DelegatePauseToggle ();
	}

	// Method called by Unity at every frame
	private void Update ()
	{
		// Measure the frame rate
		if (Time.realtimeSinceStartup < frameTimer) {
			++frameCount;
		} else {
			frameRateLabel.text = frameCount.ToString ("0.0 'fps'");
			frameTimer = Time.realtimeSinceStartup + 1.0f;
			frameCount = 0;
		}

		// Check the pause state
		if (!pauseToggle) {

			// Update the time
			time += Time.deltaTime;

			// Update the collider material to animate it
			if (colliderMaterialCopy) {
				colliderMaterialCopy.SetFloat ("time", time);
			}

			// Update the template
			TEMPLATES [template].Update (this, time);

			// Set the direction of the gravitational acceleration
			Vector2 gravityDirection;
			if (SystemInfo.supportsAccelerometer) {
				gravityDirection.x = Input.acceleration.x;
				gravityDirection.y = Input.acceleration.y;
			} else {
				gravityDirection.x = Input.mousePosition.x - Screen.width * 0.5f;
				gravityDirection.y = Input.mousePosition.y - Screen.height * 0.5f;
			}

			// Update the physics
			if (!Liquid.PhysicsUpdate (GRAVITY_ACCELERATION * gravityDirection.normalized, Time.deltaTime, SIMULATION_LOAD_MAX / Application.targetFrameRate) && debugToggle && debugToggle.isOn) {
				Debug.LogWarning ("The physics engine takes too long...");
			}
		}
	}

	// Delegate to handle the template button events
	public void DelegateTemplateButton ()
	{
		// Change the template
		template = (template + 1) % TEMPLATES.Length;

		// Initialize the simulation again
		SimulationSetup ();
	}

	// Delegate to handle the debug toggle events
	public void DelegateDebugToggle (bool toggle)
	{
		// Update the materials to reflect the current debug state
		if (colliderMaterialCopy) {
			if (toggle) {
				colliderMaterialCopy.EnableKeyword ("DEBUG");
			} else {
				colliderMaterialCopy.DisableKeyword ("DEBUG");
			}
		}
		if (particleMaterialCopy) {
			if (toggle) {
				particleMaterialCopy.EnableKeyword ("DEBUG");
			} else {
				particleMaterialCopy.DisableKeyword ("DEBUG");
			}
		}
	}

	// Delegate to handle the pause toggle events
	public void DelegatePauseToggle ()
	{
		// Toggle the pause state
		pauseToggle = !pauseToggle;

		// Update the label
		pauseLabel.text = (pauseToggle ? ">" : "II");
	}

	// Delegate to handle the resolution toggle events
	public void DelegateResolutionToggle (bool toggle)
	{
		// Either create a new render texture which the size is a quarter of the screen size, or destroy the existing one
		// Note: the filtering mode of this render texture needs to be "bilinear" (which is the default value, normally)
		if (localCamera) {
			localCamera.targetTexture = toggle ? new RenderTexture (Screen.width >> 1, Screen.height >> 1, 0) : null;
		}
	}

	// Handle the pointer down event
	public void OnPointerDown (PointerEventData eventData)
	{
		if (touch.z < 0.5f) {
			TouchUpdate (eventData, 2.0f);
			ColliderPathStart (touch, !editToggle || editToggle.isOn);
			ColliderTextureRefresh ();
		}
	}

	// Handle the drag event
	public void OnDrag (PointerEventData eventData)
	{
		if (touch.z > 0.5f) {
			TouchUpdate (eventData, 1.0f);
			ColliderPathContinue (touch);
			ColliderTextureRefresh ();
		}
	}

	// Handle the pointer up event
	public void OnPointerUp (PointerEventData eventData)
	{
		TouchReset ();
	}

	// Method called by Unity before a camera starts rendering the scene
	private void OnPreRender ()
	{
		// Display the colliders
		if (colliderMaterialCopy) {
			Graphics.Blit (null, localCamera.targetTexture, colliderMaterialCopy);
		}

		// Get the particle information
		ushort particleId = Liquid.ParticleCount (particleDataHandle.AddrOfPinnedObject (), (ushort)particleData.Length);

		// Update the fill rate label
		fillRateLabel.text = (100 * particleId / physicsParameters.particleBufferSize).ToString ("0'%'");

		// Display all the particles
		if (particleMesh) {

			// Prepare the mesh (1 quad per particle)
			int vertexId = particleId * 4;
			Vector3 [] vertices = new Vector3 [vertexId];
			Vector2 [] uvs = new Vector2 [vertexId];
			Color [] colors = new Color [vertexId];

			// Define the radius of a particle
			float particleRadius = physicsParameters.particleRadius * (debugToggle && debugToggle.isOn ? PARTICLE_PACKING_FACTOR : 2.2f);

			// Add all the particles
			int indiceId = particleId * 6;
			int [] indices = new int [indiceId];
			while (particleId --> 0) {

				// Define the position
				Vector2 position = particleData [particleId].position;
				float x1 = position.x - particleRadius;
				float y1 = position.y - particleRadius;
				float x2 = position.x + particleRadius;
				float y2 = position.y + particleRadius;

				// Define the color
				Color color = Color.Lerp (Color.blue, Color.white, particleData [particleId].velocity * PARTICLE_VELOCITY_COLOR_FACTOR);

				// Define 2 triangles
				vertices [--vertexId] = new Vector3 (x1, y1, 1.0f);
				uvs [vertexId] = new Vector2 (0.0f, 0.0f);
				colors [vertexId] = color;
				indices [--indiceId] = vertexId;

				vertices [--vertexId] = new Vector3 (x2, y1, 1.0f);
				uvs [vertexId] = new Vector2 (1.0f, 0.0f);
				colors [vertexId] = color;
				indices [--indiceId] = vertexId;

				vertices [--vertexId] = new Vector3 (x2, y2, 1.0f);
				uvs [vertexId] = new Vector2 (1.0f, 1.0f);
				colors [vertexId] = color;
				indices [--indiceId] = vertexId;

				vertices [--vertexId] = new Vector3 (x1, y2, 1.0f);
				uvs [vertexId] = new Vector2 (0.0f, 1.0f);
				colors [vertexId] = color;
				indices [--indiceId] = vertexId;
				indices [--indiceId] = vertexId + 3;
				indices [--indiceId] = vertexId + 1;
			}

			// Update the mesh
			particleMesh.Clear ();
			particleMesh.vertices = vertices;
			particleMesh.uv = uvs;
			particleMesh.colors = colors;
			particleMesh.SetTriangles (indices, 0);
		}
	}

	// Method called by Unity when the MonoBehaviour will be destroyed
	private void OnDestroy ()
	{
		// Free the handle to the particle data array
		particleDataHandle.Free ();

		// Free the handle to the collider texture
		colliderPixelsHandle.Free ();

		// Finalize the physics engine
		Liquid.PhysicsFinalize ();
	}

	// Method to render the scene full screen (to be called from the "OnPostRender" of another camera)
	public void RenderFullScreen ()
	{
		if (localCamera.targetTexture) {
			Graphics.Blit (localCamera.targetTexture, (RenderTexture) null);
		}
	}
}
