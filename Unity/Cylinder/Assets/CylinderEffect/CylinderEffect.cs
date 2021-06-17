// Nicolas Robert [Nrx]
using UnityEngine;

public class CylinderEffect : MonoBehaviour
{
	// Control of the camera
	// - If cameraDist = 0 then the camera is right in the center of the cylinder
	// - If cameraDist = 1.0 then the camera is pushed forward to the border of the cylinder
	// - If cameraDist > 1.0 then you can't see anything anymore (the cylinder is behind the camera)
	// - If cameraDist = -1.0 then the camera is pulled backward to the border of the cylinder
	// - If cameraDist < -1.0 then you can see the exterior of the cylinder
	// - If the camera is always inside the cylinder (i.e. cameraDist is between -1.0 and 1.0), then you should enable "CAMERA_ALWAYS_IN" to optimize the rendering
	public float cameraDist1 = 0.0f;
	public float cameraDist2 = 0.0f;
	public float cameraYawAngle = 0.0f;
	public float cameraPitchAngle = 0.0f;

	// Camera ratio
	private float cameraRatio = 1.0f;

	// Flag to optimize the rendering when the camera is always inside the cylinder
	public bool cameraAlwaysIn = false;

	// Flag to select the coloring mode
	public bool colorAlpha = false;

	// Material
	private Material materialCopy;

	// Method called by Unity after that the GameObject has been instantiated
	private void Start ()
	{
		// Initialize the shader
		Renderer renderer = GetComponent <Renderer> ();
		materialCopy = (Material)Object.Instantiate (renderer.material);
		if (!cameraAlwaysIn)
		{
			materialCopy.EnableKeyword ("CAMERA_SOMETIMES_OUT");
		}
		if (colorAlpha)
		{
			materialCopy.EnableKeyword ("COLOR_ALPHA");
		}
		renderer.material = materialCopy;

		// Record the camera ratio
		cameraRatio = (float) renderer.bounds.size.x / renderer.bounds.size.y;
	}

	// Method called by Unity at every frame
	private void Update ()
	{
		// Compute the orientation of the camera
		float yawAngle = cameraYawAngle + Mathf.PI * (1.0f - 2.0f * Input.mousePosition.x / Screen.width);
		float pitchAngle = cameraPitchAngle + Mathf.PI * (Input.mousePosition.y / Screen.height - 0.5f);

		float cosYaw = Mathf.Cos (yawAngle);
		float sinYaw = Mathf.Sin (yawAngle);
		float cosPitch = Mathf.Cos (pitchAngle);
		float sinPitch = Mathf.Sin (pitchAngle);

		Vector3 [] cameraOrientation = new Vector3 [3];
		cameraOrientation [0] = new Vector3 (cosYaw, 0.0f, -sinYaw);
		cameraOrientation [1] = new Vector3 (sinYaw * sinPitch, cosPitch, cosYaw * sinPitch);
		cameraOrientation [2] = new Vector3 (sinYaw * cosPitch, -sinPitch, cosYaw * cosPitch);

		// Compute the position of the camera
		float dist = Mathf.Lerp (cameraDist1, cameraDist2, 0.5f + 0.5f * Mathf.Cos (Time.time));
		Vector3 cameraPosition = cameraOrientation [2] * dist;

		// Update the shader
		materialCopy.SetFloat ("time", Time.time * 10.0f);
		materialCopy.SetVector ("cameraOrientation0", cameraOrientation [0] * cameraRatio);
		materialCopy.SetVector ("cameraOrientation1", cameraOrientation [1]);
		materialCopy.SetVector ("cameraOrientation2", cameraOrientation [2]);
		materialCopy.SetVector ("cameraPosition", cameraPosition);
	}
}
