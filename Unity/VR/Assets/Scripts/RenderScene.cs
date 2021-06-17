// Nicolas Robert [Nrx]
using UnityEngine;

public class RenderScene : MonoBehaviour
{
	// Camera
	private Camera cameraComponent;

	// Mix shader
	public Shader shaderMix;

	// Materials
	private int materialId = 0;
	public Material [] materials;
	private Material materialScene;
	private Material materialMix;

	// Render textures
	private RenderTexture renderTextureNormal;
	private RenderTexture renderTextureOffsetted;

	// Resolution factor
	private int resolutionFactor = 0;
	private int resolutionFactorExpected = 4;
	public UnityEngine.UI.Text resolutionFactorGui;

	// Quality
	public UnityEngine.UI.Toggle qualityGui;

	// Anti-aliasing
	private bool antiAliasing = true;
	public UnityEngine.UI.Toggle antiAliasingGui;

	// VR
	public UnityEngine.UI.Toggle VRGui;

	// Head
	private Vector3 headPosition = Vector3.zero;

	// Time & pause
	private float time = 0.0f;
	private bool pause = false;
	public UnityEngine.UI.Text pauseGui;

	// Change the scene
	public void ChangeScene ()
	{
		// Check whether a scene material exists already
		Material materialScenePrevious = materialScene;
		if (materialScenePrevious) {
			materialId = ++materialId % materials.Length;
		}

		// Make a copy of the new scene material (in order to update its shader parameters freely, without
		// modifying the original material)
		materialScene = (Material) Object.Instantiate (materials [materialId]);

		// Copy some properties of the previous material
		if (materialScenePrevious) {
			materialScene.SetVector ("resolution", materialScenePrevious.GetVector ("resolution"));
			materialScene.SetFloat ("VR", materialScenePrevious.GetFloat ("VR"));
			ChangeQuality (materialScenePrevious.IsKeywordEnabled ("QUALITY_HIGH"));

			// Destroy the previous material
			Object.Destroy (materialScenePrevious);
		}

		// Reset the position of the head and the time
		headPosition = Vector3.zero;
		time = 0.0f;
	}

	// Change the resolution factor
	public void ChangeResolutionFactor (bool increase)
	{
		if (increase) {
			if (resolutionFactorExpected < 9) {
				++resolutionFactorExpected;
			}
		} else {
			if (resolutionFactorExpected > 1) {
				--resolutionFactorExpected;
			}
		}
	}

	// Toggle the quality
	public void ChangeQuality (bool high)
	{
		if (high) {
			materialScene.EnableKeyword ("QUALITY_HIGH");
		} else {
			materialScene.DisableKeyword ("QUALITY_HIGH");
		}
	}

	// Toggle the anti-aliasing
	public void ChangeAntiAliasing (bool state)
	{
		antiAliasing = state;
		resolutionFactor = 0;
	}

	// Toggle the VR
	public void ChangeVR (bool state)
	{
		materialScene.SetFloat ("VR", state ? 1.0f : 0.0f);
	}

	// Toggle the pause
	public void ChangePause (bool change)
	{
		// Toggle the pause
		if (change) {
			pause = !pause;
		}

		// Update the GUI
		pauseGui.text = (pause ? ">" : "II");
	}

	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Get the camera
		cameraComponent = GetComponent <Camera> ();

		// Create the mix material
		materialMix = new Material (shaderMix);

		// Initialize the scene
		ChangeScene ();

		// Initialize the quality, antialiasing, VR and pause
		ChangeQuality (qualityGui.isOn);
		ChangeAntiAliasing (antiAliasingGui.isOn);
		ChangeVR (VRGui.isOn);
		ChangePause (false);
	}

	// Method called by Unity after a camera finished rendering the scene
	private void OnPostRender ()
	{
		// Check whether the resolution factor has to change
		if (resolutionFactor != resolutionFactorExpected) {
			resolutionFactor = resolutionFactorExpected;

			// Update the GUI
			resolutionFactorGui.text = resolutionFactor.ToString ("'x'0");

			// Compute the new resolution
			float factor = 1.0f / Mathf.Sqrt (resolutionFactor);
			int width = (int) (Screen.width * factor);
			int height = (int) (Screen.height * factor);

			// Create a new render texture (with bilinear filtering)
			renderTextureNormal = antiAliasing || resolutionFactor != 1 ? new RenderTexture (width, height, 0) : null;
			renderTextureOffsetted = antiAliasing ? new RenderTexture (width + 1, height + 1, 0) : null;

			// Update the scene shader: resolution
			materialScene.SetVector ("resolution", new Vector3 (width, height, 0.0f));

			// Update the mix shader: resolution & second render texture
			materialMix.SetVector ("resolution", new Vector2 (width, height));
			materialMix.SetTexture ("offsettedTexture", renderTextureOffsetted);
		}

		// Get the orientation of the head
		Vector3 [] headOrientation = new Vector3 [3];
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

			headOrientation [0] = new Vector3 (1.0f - 2.0f * (qyy + qzz), 2.0f * (qxz - qyw), 2.0f * (qxy + qzw));
			headOrientation [1] = new Vector3 (2.0f * (qxy - qzw), 2.0f * (qxw + qyz), 1.0f - 2.0f * (qxx + qzz));
			headOrientation [2] = new Vector3 (-2.0f * (qxz + qyw), 2.0f * (qxx + qyy) - 1.0f, 2.0f * (qxw - qyz));
		} else {

			// Get the position of the mouse
			float yawAngle = -2.0f * Mathf.PI * (Input.mousePosition.x / Screen.width - 0.5f);
			float pitchAngle = Mathf.PI * (Input.mousePosition.y / Screen.height - 0.5f);

			float cosYaw = Mathf.Cos (yawAngle);
			float sinYaw = Mathf.Sin (yawAngle);
			float cosPitch = Mathf.Cos (pitchAngle);
			float sinPitch = Mathf.Sin (pitchAngle);

			headOrientation [0] = new Vector3 (cosYaw, 0.0f, -sinYaw);
			headOrientation [1] = new Vector3 (sinYaw * sinPitch, cosPitch, cosYaw * sinPitch);
			headOrientation [2] = new Vector3 (sinYaw * cosPitch, -sinPitch, cosYaw * cosPitch);
		}

		// Check whether the game is paused
		if (!pause) {

			// Update the time
			time += Time.deltaTime;
		}

		// Update the scene shader: time & head
		materialScene.SetFloat ("time", time);
		materialScene.SetVector ("headOrientation0", headOrientation [0]);
		materialScene.SetVector ("headOrientation1", headOrientation [1]);
		materialScene.SetVector ("headOrientation2", headOrientation [2]);
		materialScene.SetVector ("headPosition", headPosition);

		// Assign the target texture (swap the render textures)
		bool offset = antiAliasing && (Time.frameCount & 1) != 0;
		cameraComponent.targetTexture = offset ? renderTextureOffsetted : renderTextureNormal;

		// Update the scene shader: fragment offset
		materialScene.SetFloat ("fragOffset", offset ? 0.5f : 0.0f);

		// Render the scene to the appropriate render texture
		Graphics.Blit (null, cameraComponent.targetTexture, materialScene);
	}

	// Method to render the scene full screen (to be called from the "OnPostRender" of another camera)
	public void RenderFullScreen ()
	{
		if (antiAliasing) {
			Graphics.Blit (renderTextureNormal, (RenderTexture) null, materialMix);
		} else if (cameraComponent.targetTexture) {
			Graphics.Blit (cameraComponent.targetTexture, (RenderTexture) null);
		}
	}
}
