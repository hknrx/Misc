// Nicolas Robert [Nrx]
Shader "Custom/Cylinder" {
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

// Shader from: https://www.shadertoy.com/view/lsjSDd

// Rendering parameters
#ifdef QUALITY_HIGH
	#define DOT_COUNT	60.0
#else
	#define DOT_COUNT	20.0
	#define HSV2RGB_FAST
#endif

// Constants
#define PI	3.14159265359

// PRNG
float rand (in vec2 seed) {
	return fract (sin (dot (seed, vec2 (12.9898, 78.233))) * 137.5453);
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

	// Get the music info
	float soundBass = 0.6 + 0.4 * cos (time * 0.2);
	float soundTreble = 0.5 + 0.5 * cos (time * 1.2);

	// Define the number of rows
	float dotRowCount = floor (20.0 + 60.0 * soundTreble * soundBass) * 2.0;

	// Compute the intersection point (ray / cylinder)
	float a = dot (rayDirection.xz, rayDirection.xz);
	float b = dot (rayOrigin.xz, rayDirection.xz);
	float c = b * b - a * (dot (rayOrigin.xz, rayOrigin.xz) - 1.0);
	float ok = step (0.0, c);
	c = sqrt (c);
	vec3 hit;
	if (b < -c) {
		hit = rayOrigin - rayDirection * (b + c) / a;
		if (abs (hit.y * DOT_COUNT / PI + 1.0) > dotRowCount) {
			hit = rayOrigin - rayDirection * (b - c) / a;
		}
	} else {
		hit = rayOrigin - rayDirection * (b - c) / a;
	}
	vec2 frag = vec2 ((atan (hit.z, hit.x) + PI) * DOT_COUNT, hit.y * DOT_COUNT + PI) / (2.0 * PI);

	// Compute the fragment color
	vec2 id = floor (frag);
	float random = rand (id);
	vec3 color = hsv2rgb (vec3 (time * 0.05 + id.y * 0.005, 1.0, 1.0));
	color += 0.5 * cos (random * vec3 (1.0, 2.0, 3.0));
	color *= smoothstep (0.5, 0.1, length (fract (frag) - 0.5));
	color *= 0.5 + 1.5 * step (0.9, cos (random * time * 5.0));
	color *= 0.5 + 0.5 * cos (random * time + PI * 0.5 * soundTreble);
	color *= smoothstep (dotRowCount, 0.0, (abs (id.y + 0.5) - 1.0) * 2.0);
	gl_FragColor = vec4 (color * ok, 1.0);
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
