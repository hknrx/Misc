// Nicolas Robert [Nrx]
Shader "Custom/Shader-0" {
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

// (Shader not available on Shadertoy)

#define RADIUS_CYLINDER	100.0
#define RADIUS_CAMERA	30.0
//#define RAY_STEP_MAX	5
//#define TEXTURE_SCALE	50.0

void main () {

	// Define the ray corresponding to this fragment
	vec2 frag = (2.0 * gl_FragCoord.xy - iResolution.xy) / iResolution.y;
	vec3 direction = vec3 (frag, 2.0);

	// Set the camera
	vec3 origin = RADIUS_CAMERA * vec3 (cos (iGlobalTime * 0.2), sin (iGlobalTime * 0.5), sin (iGlobalTime * 0.2));
	mat3 rotation;
	rotation [2] = normalize (-origin);
	rotation [0] = normalize (vec3 (-origin.z, 0.0, origin.x));
	rotation [1] = cross (rotation [2], rotation [0]);
	direction = rotation * direction;

	#ifndef RAY_STEP_MAX
	// Directly compute the intersection point
	float a = direction.x * direction.x + direction.z * direction.z;
	float b = origin.x * direction.x + origin.z * direction.z;
	float c = origin.x * origin.x + origin.z * origin.z - RADIUS_CYLINDER * RADIUS_CYLINDER;
	float dist = (sqrt (b * b - a * c) - b) / a;
	origin += direction * dist;
	#else
	// Ray marching
	direction = normalize (direction);
	for (int rayStep = 0; rayStep < RAY_STEP_MAX; ++rayStep) {
		float dist = RADIUS_CYLINDER - length (origin.xz);
		if (dist < 0.01) {
			break;
		}
		origin += direction * dist;
	}
	#endif

	// Compute the fragment color
	#ifdef TEXTURE_SCALE
	vec2 uv = vec2 (atan (origin.z, origin.x) * RADIUS_CYLINDER, origin.y);
	gl_FragColor = texture2D (iChannel0, uv / TEXTURE_SCALE);
	#else
	vec2 uv = vec2 (atan (origin.z, origin.x), origin.y / RADIUS_CYLINDER) * 32.0;
	gl_FragColor = vec4 (0.5 + sin (uv.y) * 0.5, 0.5 + sin (uv.x) * 0.5, 0.5 + sin (uv.x * 0.5) * sin (uv.y * 0.5) * 0.5, 1.0);
	#endif
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
