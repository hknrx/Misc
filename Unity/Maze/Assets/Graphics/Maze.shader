// Nicolas Robert [Nrx]
Shader "Custom/Maze" {
	Properties {
		[HideInInspector] resolution ("Resolution", Vector) = (1.0, 1.0, 0.0, 0.0)
		[HideInInspector] fragOffset ("Fragment offset", Float) = 0.0
		FOV ("FOV", Float) = 96.0
		IPD ("IPD", Float) = 0.01
		[HideInInspector] VR ("VR", Float) = 1.0
		[HideInInspector] time ("Time", Float) = 0.0
		headModel ("Head model", Vector) = (0.0, 0.02, 0.01, 0.0)
		[HideInInspector] headOrientation0 ("Head orientation (0)", Vector) = (1.0, 0.0, 0.0, 0.0)
		[HideInInspector] headOrientation1 ("Head orientation (1)", Vector) = (0.0, 1.0, 0.0, 0.0)
		[HideInInspector] headOrientation2 ("Head orientation (2)", Vector) = (0.0, 0.0, 1.0, 0.0)
		[HideInInspector] headPosition ("Head position", Vector) = (0.0, 0.0, 0.0, 0.0)
		[HideInInspector] lightPosition ("Light position", Vector) = (0.0, 0.0, 0.0, 0.0)
		[HideInInspector] ambientIntensity ("Ambient intensity", Float) = 1.0
		textureData ("Texture", 2D) = "white" {}
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
				uniform vec2 resolution;
				uniform float fragOffset;
				uniform float FOV;
				uniform float IPD;
				uniform float VR;
				uniform float time;
				uniform vec3 headModel;
				uniform vec3 headPosition;
				uniform vec3 lightPosition;
				uniform float ambientIntensity;
				uniform sampler2D textureData;

				// Variables shared between the vertex shader and the fragment shader
				varying mat3 headRotate;

// Shader from: https://www.shadertoy.com/view/llB3WW

// Rendering parameters
#define RAY_STEP_MAX		20.0
#define RAY_LENGTH_MAX		10.0
#define EDGE_LENGTH			0.1
#ifdef QUALITY_HIGH
	#define EDGE_FULL
	#define TEXTURE
	#define SHADOW
#endif
#define BUMP_RESOLUTION		500.0
#define BUMP_INTENSITY		0.3
#define AMBIENT_NORMAL		0.2
#define AMBIENT_HIGHLIGHT	2.5
#define SPECULAR_POWER		2.0
#define SPECULAR_INTENSITY	0.3
#define FADE_POWER			1.5
#define GAMMA				0.8
#define HSV2RGB_FAST

// Math constants
#define DELTA	0.002
#define PI		3.14159265359

// PRNG (unpredictable)
float randUnpredictable (in vec3 seed) {
	seed = fract (seed * vec3 (5.6789, 5.4321, 6.7890));
	seed += dot (seed.yzx, seed.zxy + vec3 (21.0987, 12.3456, 15.1273));
	return fract (seed.x * seed.y * seed.z * 5.1337);
}

// PRNG (predictable)
float randPredictable (in vec3 seed) {
	return fract (11.0 * sin (3.0 * seed.x + 5.0 * seed.y + 7.0 * seed.z));
}

// Check whether there is a block at a given voxel edge
float block (in vec3 p, in vec3 n) {
	vec3 block = floor (p + 0.5 + n * 0.5);
	vec3 blockEven = mod (block, 2.0);
	float blockSum = blockEven.x + blockEven.y + blockEven.z;
	return max (step (blockSum, 1.5), step (blockSum, 2.5) * step (0.5, randPredictable (block))) *
		step (4.5, mod (block.x, 32.0)) *
		step (2.5, mod (block.y, 16.0)) *
		step (4.5, mod (block.z, 32.0));
}

// Cast a ray
vec3 hit (in vec3 rayOrigin, in vec3 rayDirection, in float rayLengthMax, out float rayLength, out vec3 hitNormal) {

	// Launch the ray
	vec3 hitPosition = rayOrigin;
	vec3 raySign = sign (rayDirection);
	vec3 rayInv = 1.0 / rayDirection;
	vec3 rayLengthNext = (0.5 * raySign - fract (rayOrigin + 0.5) + 0.5) * rayInv;
	for (float rayStep = 0.0; rayStep < RAY_STEP_MAX; ++rayStep) {

		// Reach the edge of the voxel
		rayLength = min (rayLengthNext.x, min (rayLengthNext.y, rayLengthNext.z));
		hitNormal = step (rayLengthNext.xyz, rayLengthNext.yzx) * step (rayLengthNext.xyz, rayLengthNext.zxy) * raySign;
		hitPosition = rayOrigin + rayLength * rayDirection;

		// Check whether we hit a block
		if (block (hitPosition, hitNormal) > 0.5 || rayLength > rayLengthMax) {
			break;
		}

		// Next voxel
		rayLengthNext += hitNormal * rayInv;
	}

	// Return the hit point
	return hitPosition;
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

	// Define the ray corresponding to this fragment
	vec2 fragCoord = gl_FragCoord.xy - fragOffset;
	float rayStereo = 0.5 * sign (fragCoord.x - resolution.x * 0.5) * step (0.5, VR);
	vec3 rayOrigin = headPosition + headRotate * (headModel + vec3 (rayStereo * IPD, 0.0, 0.0));
	vec3 rayDirection = headRotate * normalize (vec3 ((2.0 * fragCoord.x - (1.0 + rayStereo) * resolution.x), 2.0 * fragCoord.y - resolution.y, 0.5 * resolution.x / tan (FOV * PI / 360.0)));

	// Cast a ray
	float hitDistance;
	vec3 hitNormal;
	vec3 hitPosition = hit (rayOrigin, rayDirection, RAY_LENGTH_MAX, hitDistance, hitNormal);
	vec3 hitUV = hitPosition * abs (hitNormal.yzx + hitNormal.zxy);

	// Basic edge detection
	vec3 edgeDistance = fract (hitUV + 0.5) - 0.5;
	vec3 edgeDirection = sign (edgeDistance);
	edgeDistance = abs (edgeDistance);

	#ifdef EDGE_FULL
	vec3 hitNormalAbs = abs (hitNormal);
	vec2 edgeSmooth = vec2 (dot (edgeDistance, hitNormalAbs.yzx), dot (edgeDistance, hitNormalAbs.zxy));
	float highlightIntensity = (1.0 - block (hitPosition + edgeDirection * hitNormalAbs.yzx, hitNormal)) * smoothstep (0.5 - EDGE_LENGTH, 0.5 - EDGE_LENGTH * 0.5, edgeSmooth.x);
	highlightIntensity = max (highlightIntensity, (1.0 - block (hitPosition + edgeDirection * hitNormalAbs.zxy, hitNormal)) * smoothstep (0.5 - EDGE_LENGTH, 0.5 - EDGE_LENGTH * 0.5, edgeSmooth.y));
	highlightIntensity = max (highlightIntensity, (1.0 - block (hitPosition + edgeDirection, hitNormal)) * smoothstep (0.5 - EDGE_LENGTH, 0.5 - EDGE_LENGTH * 0.5, min (edgeSmooth.x, edgeSmooth.y)));
	#else
	float highlightIntensity = 1.0 - block (hitPosition + step (edgeDistance.yzx, edgeDistance.xyz) * step (edgeDistance.zxy, edgeDistance.xyz) * edgeDirection, hitNormal);
	highlightIntensity *= smoothstep (0.5 - EDGE_LENGTH, 0.5 - EDGE_LENGTH * 0.5, max (edgeDistance.x, max (edgeDistance.y, edgeDistance.z)));
	#endif

	// Texture
	#ifdef TEXTURE
	vec2 textureUV = vec2 (dot (hitUV, hitNormal.yzx), dot (hitUV, hitNormal.zxy)) + 0.5;
	float textureIntensity = 1.0 - texture2D (textureData, textureUV).a;
	float texturePhase = 2.0 * PI * randUnpredictable (floor (hitPosition + 0.5 + hitNormal * 1.5));
	textureIntensity *= smoothstep (0.8, 1.0, cos (time * 0.2 + texturePhase));
	highlightIntensity = max (highlightIntensity, textureIntensity);
	#endif

	// Set the object color
	vec3 color = cos ((hitPosition + hitNormal * 0.5) * 0.05);
	color = hsv2rgb (vec3 (color.x + color.y + color.z + highlightIntensity * 0.05, 1.0, 1.0));

	// Lighting
	vec3 lightDirection = hitPosition - lightPosition;
	float lightDistance = length (lightDirection);
	lightDirection /= lightDistance;

	float lightIntensity = min (1.0, 1.0 / lightDistance);
	#ifdef SHADOW
	float lightHitDistance;
	vec3 lightHitNormal;
	hit (hitPosition - hitNormal * DELTA, -lightDirection, lightDistance, lightHitDistance, lightHitNormal);
	lightIntensity *= step (lightDistance, lightHitDistance);
	#endif

	// Bump mapping
	vec3 bumpUV = floor (hitUV * BUMP_RESOLUTION) / BUMP_RESOLUTION;
	hitNormal = normalize (hitNormal + (1.0 - highlightIntensity) * BUMP_INTENSITY * (hitNormal.yzx * (randUnpredictable (bumpUV) - 0.5) + hitNormal.zxy * (randUnpredictable (bumpUV + 1.0) - 0.5)));

	// Shading
	float ambient = mix (AMBIENT_NORMAL, AMBIENT_HIGHLIGHT, highlightIntensity) * ambientIntensity;
	float diffuse = max (0.0, dot (hitNormal, lightDirection));
	float specular = pow (max (0.0, dot (reflect (rayDirection, hitNormal), lightDirection)), SPECULAR_POWER) * SPECULAR_INTENSITY;
	color = (ambient + diffuse * lightIntensity) * color + specular * lightIntensity;
	color *= pow (max (0.0, 1.0 - hitDistance / RAY_LENGTH_MAX), FADE_POWER);

	// Light source
	lightDirection = lightPosition - rayOrigin;
	if (dot (rayDirection, lightDirection) > 0.0) {
		lightDistance = length (lightDirection);
		if (lightDistance < hitDistance) {
			vec3 lightNormal = cross (rayDirection, lightDirection);
			color += smoothstep (0.001, 0.0, dot (lightNormal, lightNormal));
		}
	}

	// Adjust the gamma
	color = pow (color, vec3 (GAMMA));

	// Set the fragment color
	gl_FragColor = vec4 (color, 1.0);
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
