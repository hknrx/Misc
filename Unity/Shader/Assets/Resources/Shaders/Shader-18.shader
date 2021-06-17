// Nicolas Robert [Nrx]
Shader "Custom/Shader-18" {
	Properties {
		[HideInInspector] iResolution ("Resolution", Vector) = (1.0, 1.0, 0.0, 0.0)
		[HideInInspector] iGlobalTime ("Time", Float) = 0.0
		[HideInInspector] iMouse ("Mouse", Vector) = (0.0, 0.0, 0.0, 0.0)
		[HideInInspector] iDate ("Date", Vector) = (0.0, 0.0, 0.0, 0.0)
	}
	SubShader {
		Pass {
			ZWrite Off
			ZTest Always

			GLSLPROGRAM

			// Precision setting (shared between the vertex shader and the fragment shader)
			#ifdef GL_ES
			precision highp float;
			#endif

			// Vertex shader: begin
			#ifdef VERTEX

				// Main function
				void main () {

					// Set the position
					gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
				}

			// Vertex shader: end
			#endif

			// Fragment shader: begin
			#ifdef FRAGMENT

				// Variables shared between the fragment shader and the OpenGL ES environment (= Shadertoy inputs)
				uniform vec3 iResolution;
				uniform float iGlobalTime;
				uniform vec4 iMouse;
				uniform vec4 iDate;

// Shader from: https://www.shadertoy.com/view/XlfGR4

// Parameters
#define CAMERA_FOCAL_LENGTH	1.5
#define VOXEL_STEP			50.0
//#define SOUND
#define MOUSE

// Constants
#define PI		3.14159265359
#define SQRT2	1.41421356237

// PRNG
// From https://www.shadertoy.com/view/4djSRW
float rand (in vec2 seed) {
	seed = fract (seed * vec2 (5.3983, 5.4427));
	seed += dot (seed.yx, seed.xy + vec2 (21.5351, 14.3137));
	return fract (seed.x * seed.y * 95.4337);
}

// HSV to RGB
vec3 rgb (in vec3 hsv) {
	hsv.yz = clamp (hsv.yz, 0.0, 1.0);
	return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.xxx + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
}

// Main function
void main () {

	// Define the ray corresponding to this fragment
	vec3 ray = normalize (vec3 ((2.0 * gl_FragCoord.xy - iResolution.xy) / iResolution.y, CAMERA_FOCAL_LENGTH));

	// Get the music info
	#ifdef SOUND
	float soundBass = texture2D (iChannel0, vec2 (0.0)).x;
	float soundTreble = texture2D (iChannel0, vec2 (0.9, 0.0)).x;
	#else
	float soundBass = 0.6 + 0.4 * cos (iGlobalTime * 0.2);
	float soundTreble = 0.5 + 0.5 * cos (iGlobalTime * 1.2);
	#endif

	// Set the camera
	vec3 origin = vec3 (0.0, 6.0 - 3.0 * cos (iGlobalTime * 0.3), iGlobalTime * 2.0 + 700.0 * (0.5 + 0.5 * sin (iGlobalTime * 0.1)));
	float cameraAngle = iGlobalTime * 0.1;
	#ifdef MOUSE
	cameraAngle += 2.0 * PI * iMouse.x / iResolution.x;
	#endif
	vec3 cameraForward = vec3 (cos (cameraAngle), cos (iGlobalTime * 0.3) - 1.5, sin (cameraAngle));
	vec3 cameraUp = vec3 (0.2 * cos (iGlobalTime * 0.7), 1.0, 0.0);
	mat3 cameraRotation;
	cameraRotation [2] = normalize (cameraForward);
	cameraRotation [0] = normalize (cross (cameraUp, cameraForward));
	cameraRotation [1] = cross (cameraRotation [2], cameraRotation [0]);
	ray = cameraRotation * ray;

	// Voxel
	vec3 color = vec3 (0.0);

    vec2 voxelSign = sign (ray.xz);
	vec2 voxelIncrement = voxelSign / ray.xz;
	float voxelTimeCurrent = 0.0;
	vec2 voxelTimeNext = (0.5 + voxelSign * (0.5 - fract (origin.xz + 0.5))) * voxelIncrement;
	vec2 voxelPosition = floor (origin.xz + 0.5);
	float voxelHeight = 0.0;
	bool voxelDone = false;
	vec3 voxelNormal = vec3 (0.0);
	for (float voxelStep = 1.0; voxelStep <= VOXEL_STEP; ++voxelStep) {

		// Compute the height of this column
		voxelHeight = 2.0 * rand (voxelPosition) * smoothstep (0.2, 0.5, soundBass) * sin (soundBass * 8.0 + voxelPosition.x * voxelPosition.y) - 5.0 * (0.5 + 0.5 * cos (voxelPosition.y * 0.15));

		// Check whether we hit the side of the column
		if (voxelDone = voxelHeight > origin.y + voxelTimeCurrent * ray.y) {
			break;
		}

		// Check whether we hit the top of the column
		float timeNext = min (voxelTimeNext.x, voxelTimeNext.y);
		float timeIntersect = (voxelHeight - origin.y) / ray.y;
		if (voxelDone = timeIntersect > voxelTimeCurrent && timeIntersect < timeNext) {
			voxelTimeCurrent = timeIntersect;
			voxelNormal = vec3 (0.0, 1.0, 0.0);
			break;
		}

		// Next voxel...
		voxelTimeCurrent = timeNext;
		voxelNormal.xz = step (voxelTimeNext.xy, voxelTimeNext.yx);
		voxelTimeNext += voxelNormal.xz * voxelIncrement;
		voxelPosition += voxelNormal.xz * voxelSign;
	}
	if (voxelDone) {
		origin += voxelTimeCurrent * ray;

		// Compute the local color
		vec3 mapping = origin;
		mapping.y -= voxelHeight + 0.5;
		mapping *= 1.0 - voxelNormal;
		mapping += 0.5;
		float id = rand (voxelPosition);
		color = rgb (vec3 ((iGlobalTime + floor (mapping.y)) * 0.05 + voxelPosition.x * 0.01, smoothstep (0.2, 0.4, soundBass), 0.7 + 0.3 * cos (id * iGlobalTime + PI * soundTreble)));
		color *= smoothstep (0.8 - 0.6 * cos (soundBass * PI), 0.1, length (fract (mapping) - 0.5));
		color *= 0.5 + smoothstep (0.90, 0.95, cos (id * 100.0 + soundTreble * PI * 0.5 + iGlobalTime * 0.5));
		color *= 1.0 - voxelTimeCurrent / VOXEL_STEP * SQRT2;
	}

	// Set the fragment color
	gl_FragColor = vec4 (color, 1.0);
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
