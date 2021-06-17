// Nicolas Robert [Nrx]
Shader "Custom/VoxelLand" {
	Properties {
		[HideInInspector] resolution ("Resolution", Vector) = (1.0, 1.0, 0.0, 0.0)
		[HideInInspector] fragOffset ("Fragment offset", Float) = 0.0
		FOV ("FOV", Float) = 96.0
		IPD ("IPD", Float) = 0.1
		[HideInInspector] VR ("VR", Float) = 1.0
		headModel ("Head model", Vector) = (0.0, 0.2, 0.1, 0.0)
		[HideInInspector] headOrientation0 ("Head orientation (0)", Vector) = (1.0, 0.0, 0.0, 0.0)
		[HideInInspector] headOrientation1 ("Head orientation (1)", Vector) = (0.0, 1.0, 0.0, 0.0)
		[HideInInspector] headOrientation2 ("Head orientation (2)", Vector) = (0.0, 0.0, 1.0, 0.0)
		[HideInInspector] headPosition ("Head position", Vector) = (0.0, 0.0, 0.0, 0.0)
		[HideInInspector] time ("Time", Float) = 0.0
	}
	SubShader {
		Pass {
			ZWrite Off
			ZTest Always

			GLSLPROGRAM

			// Define multiple shader program variants:
			// - (default): low quality (better performances, higher frame rate)
			// - QUALITY_HIGH: high quality (lower performances)
			#pragma multi_compile __ QUALITY_HIGH

			// Precision setting (shared between the vertex shader and the fragment shader)
			#ifdef GL_ES
			precision highp float;
			#endif

			// Vertex shader: begin
			#ifdef VERTEX

				// Variables shared between the vertex shader and the OpenGL ES environment
				uniform vec3 headOrientation0;
				uniform vec3 headOrientation1;
				uniform vec3 headOrientation2;

				// Variables shared between the vertex shader and the fragment shader
				varying mat3 headRotate;

				// Main function
				void main () {

					// Define the head's rotation matrix
					headRotate = mat3 (headOrientation0, headOrientation1, headOrientation2);

					// Set the position
					gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
				}

			// Vertex shader: end
			#endif

			// Fragment shader: begin
			#ifdef FRAGMENT

				// Variables shared between the fragment shader and the OpenGL ES environment
				uniform vec3 resolution;
				uniform float fragOffset;
				uniform float FOV;
				uniform float IPD;
				uniform float VR;
				uniform vec3 headModel;
				uniform vec3 headPosition;
				uniform float time;

				// Variables shared between the vertex shader and the fragment shader
				varying mat3 headRotate;

// Shader from: https://www.shadertoy.com/view/XtlGRr

// Rendering parameters
#ifdef QUALITY_HIGH
	#define REFLECT_COUNT 			1
	#define REFLECT_INDEX			0.4
	#define VOXEL_STEP_INCIDENT		80.0
	#define VOXEL_STEP_REFLECTED	20.0
#else
	#define REFLECT_COUNT 			0
	#define VOXEL_STEP_INCIDENT		50.0
#endif
#define HSV2RGB_FAST

// Constants
#define PI		3.14159265359
#define SQRT2	1.41421356237
#define DELTA	0.01

// PRNG
float rand (in vec2 seed) {
	seed = fract (seed * vec2 (5.3983, 5.4427));
	seed += dot (seed.yx, seed.xy + vec2 (21.5351, 14.3137));
	return fract (seed.x * seed.y * 95.4337);
}

// HSV to RGB
vec3 hsv2rgb (in vec3 hsv) {
	#ifdef HSV2RGB_SAFE
	hsv.yz = clamp (hsv.yz, 0.0, 1.0);
	#endif
	#ifdef HSV2RGB_FAST
	return hsv.z * (1.0 + 0.5 * hsv.y * (cos (2.0 * PI * (hsv.x + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0))) - 1.0));
	#else
	return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.x + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
	#endif
}

// Main function
void main () {

	// Change the position of the head
	vec3 headPositionModified = headPosition + vec3 (0.0, 4.0, 0.0);

	// Define the ray corresponding to this fragment
	vec2 fragCoord = gl_FragCoord.xy - fragOffset;
	float rayStereo = 0.5 * sign (fragCoord.x - resolution.x * 0.5) * step (0.5, VR);
	vec3 rayOrigin = headPositionModified + headRotate * (headModel + vec3 (rayStereo * IPD, 0.0, 0.0));
	vec3 rayDirection = headRotate * normalize (vec3 ((2.0 * fragCoord.x - (1.0 + rayStereo) * resolution.x), 2.0 * fragCoord.y - resolution.y, 0.5 * resolution.x / tan (FOV * PI / 360.0)));

	// Get the music info
	float soundBass = 0.6 + 0.4 * cos (time * 0.2);
	float soundTreble = 0.5 + 0.5 * cos (time * 1.2);

	// Handle reflections
	vec3 colorMixed = vec3 (0.0);
	float absorb = 1.0;
	float voxelStepStop = VOXEL_STEP_INCIDENT;
	for (int reflectNumber = 0; reflectNumber <= REFLECT_COUNT; ++reflectNumber) {

		// Voxel
		vec2 voxelSign = sign (rayDirection.xz);
		vec2 voxelIncrement = voxelSign / rayDirection.xz;
		float voxelTimeCurrent = 0.0;
		vec2 voxelTimeNext = (0.5 + voxelSign * (0.5 - fract (rayOrigin.xz + 0.5))) * voxelIncrement;
		vec2 voxelPosition = floor (rayOrigin.xz + 0.5);
		float voxelHeight = 0.0;
		bool voxelDone = false;
		vec3 voxelNormal = vec3 (0.0);
		for (float voxelStep = 1.0; voxelStep <= VOXEL_STEP_INCIDENT; ++voxelStep) {

			// Compute the height of this column
			voxelHeight = 4.0 * rand (voxelPosition) * sin (soundTreble * PI * 0.5 + voxelPosition.x * voxelPosition.y);

			// Check whether we hit the side of the column
			if (voxelDone = voxelHeight > rayOrigin.y + voxelTimeCurrent * rayDirection.y) {
				break;
			}

			// Check whether we hit the top of the column
			float timeNext = min (voxelTimeNext.x, voxelTimeNext.y);
			float timeIntersect = (voxelHeight - rayOrigin.y) / rayDirection.y;
			if (voxelDone = timeIntersect > voxelTimeCurrent && timeIntersect < timeNext) {
				voxelTimeCurrent = timeIntersect;
				voxelNormal = vec3 (0.0, 1.0, 0.0);
				break;
			}

			// Next voxel...
			#if REFLECT_COUNT > 0
			if (voxelStep >= voxelStepStop) {
				break;
			}
			#endif
			voxelTimeCurrent = timeNext;
			voxelNormal.xz = step (voxelTimeNext.xy, voxelTimeNext.yx);
			voxelTimeNext += voxelNormal.xz * voxelIncrement;
			voxelPosition += voxelNormal.xz * voxelSign;
		}
		if (!voxelDone) {
			break;
		}
		rayOrigin += voxelTimeCurrent * rayDirection;

		// Compute the local color
		vec3 mapping = rayOrigin;
		mapping.y -= voxelHeight + 0.5;
		mapping *= 1.0 - voxelNormal;
		mapping += 0.5;
		float id = rand (voxelPosition);
		vec3 color = hsv2rgb (vec3 (id + (time + floor (mapping.y)) * 0.05, 1.0, 0.7 + 0.3 * cos (id * time + PI * soundTreble)));
		color *= smoothstep (1.0 - 0.4 * cos (soundBass * PI), 0.1, length (fract (mapping) - 0.5));
		color *= 0.5 + smoothstep (0.5, 0.9, cos (id * 100.0 + time * 0.5));
		color *= 1.0 - voxelTimeCurrent / voxelStepStop * SQRT2;

		// Mix the colors
		#if REFLECT_COUNT == 0
		colorMixed = color;
		#else
		colorMixed += color * absorb;
		absorb *= REFLECT_INDEX;

		// Reflection
		rayDirection = reflect (rayDirection, voxelNormal);
		rayOrigin += rayDirection * DELTA;
		voxelStepStop = VOXEL_STEP_REFLECTED;
		#endif
	}

	// Set the fragment color
	gl_FragColor = vec4 (colorMixed, 1.0);
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
