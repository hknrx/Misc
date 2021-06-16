// Nicolas Robert [Nrx]
// TODO:
// - Add a music track & some sound effects (e.g. from Flamin Stack).
// - Implement some Parallax Mapping (can it be fast enough on mobile?).
// - Allow toggling options in-game using the device microphone (e.g. tap the device => toggle the gravity).
using UnityEngine;

public partial class Maze : MonoBehaviour
{
	// Gravity
	public Vector3 gravity = new Vector3 (0.0f, -3.0f, 0.0f);
	public UnityEngine.UI.Toggle gravityToggle;

	// Head
	public Head head = new Head {
		position = new Vector3 (13.0f, 1.5f, 13.0f),
		radius = 0.1f,
		pinballOff = new Head.Tweaking {friction = 1.0f, elasticity = 0.5f, forceOrientation = 2.0f},
		pinballOn = new Head.Tweaking {friction = 0.5f, elasticity = 1.0f, forceOrientation = 5.0f}
	};

	// Light ball
	public LightBall lightBall = new LightBall {
		friction = 1.0f,
		radius = 0.03f,
		elasticity = 0.5f,
		aheadDistance = 0.5f,
		movementAmplitude = 0.1f,
		forceSpringStiffness = 15.0f,
		forceMaxSqr = 900.0f,
		collisionTimerMax = 5.0f
	};

	// Ambient lighting
	private float ambientIntensity;

	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Initialize the rendering
		RenderInitialize ();

		// Enable the gyroscope
		Input.gyro.enabled = true;

		// Initialize the position of the light ball
		lightBall.position = head.position;
	}

	// Method called by Unity at every frame
	private void Update ()
	{
		// Move the head
		OrientationSet (ref head.orientation);
		head.force = head.orientation.GetColumn (2);
		if (head.pinballToggle.isOn) {
			head.friction = head.pinballOn.friction;
			head.elasticity = head.pinballOn.elasticity;
			head.force *= head.pinballOn.forceOrientation;
		} else {
			head.friction = head.pinballOff.friction;
			head.elasticity = head.pinballOff.elasticity;
			head.force *= head.pinballOff.forceOrientation;
		}
		if (gravityToggle.isOn) {
			head.force += (1.0f - Vector3.Dot (head.force, gravity) / gravity.sqrMagnitude) * gravity;
		}
		Move (head, true);

		// Move the light ball (using a spring force)
		Vector3 lightBallPositionTarget = lightBall.movementAmplitude * new Vector3 (Mathf.Sin (Time.time * 2.0f), Mathf.Sin (Time.time * 3.0f), Mathf.Sin (Time.time));
		lightBallPositionTarget.z += lightBall.aheadDistance;
		lightBallPositionTarget = head.position + head.orientation.MultiplyVector (lightBallPositionTarget);
		lightBall.force = (lightBallPositionTarget - lightBall.position) * lightBall.forceSpringStiffness;
		if (lightBall.force.sqrMagnitude < lightBall.forceMaxSqr) {
			lightBall.collisionTimer = 0.0f;
		} else {
			lightBall.collisionTimer += Time.deltaTime;
		}
		Move (lightBall, lightBall.collisionTimer < lightBall.collisionTimerMax);

		// Animate the ambient lighting
		ambientIntensity = (Time.time % 10.0f > 1.0f || Random.value > 0.25f) ? 1.0f : 0.0f;
	}
}
