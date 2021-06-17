// Nicolas Robert [Nrx]
Shader "Custom/Shader-16" {
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

// Shader from: https://www.shadertoy.com/view/XdSSWV

#define HACK // Hack to speed up the voxel (= reuse the raymarching position)

#define CAMERA_FOCAL_LENGTH	1.5
#define DELTA				0.01
#define RAY_STEP_MAX		80
#define SQRT3				1.73205080757
#define PI					3.14159265359

float scene (in vec3 p) {

	// Just a sphere cropped by smaller spheres, into a big sphere
	float r1 = length (p);
	float r2 = length (abs (p) - 5.0);
	return min (max (r1 - 8.5, 3.0 - r2), 32.0 - r1);
}

vec3 mapping (in vec3 position, in vec3 normal) {
	position = cos (position * 2.0 * PI);
	return (0.8 + 0.2 * position.x * position.y * position.z) * (0.4 + 0.6 * normal);
}

void main () {

	// Define the ray corresponding to this fragment
	vec3 ray = normalize (vec3 ((2.0 * gl_FragCoord.xy - iResolution.xy) / iResolution.y, CAMERA_FOCAL_LENGTH));

	// Set the camera
	vec3 origin = vec3 (20.0 * cos (iGlobalTime), 12.0 * sin (iGlobalTime * 0.5), 20.0 * sin (iGlobalTime));
	vec3 forward = -origin;
	vec3 up = vec3 (cos (iGlobalTime), 1.0, 0.0);
	mat3 rotation;
	rotation [2] = normalize (forward);
	rotation [0] = normalize (cross (up, forward));
	rotation [1] = cross (rotation [2], rotation [0]);
	ray = rotation * ray;

	// Raymarching
	#ifdef HACK
	float hack = 1.0 / 0.0;
	#endif
	vec3 rayPosition = origin;
	for (int rayStep = 0; rayStep < RAY_STEP_MAX; ++rayStep) {
		float dist = scene (rayPosition);
		if (dist < DELTA) {
			break;
		}
		rayPosition += dist * ray;

		#ifdef HACK
		hack = min (hack, dist);
		origin = mix (origin, rayPosition, step (SQRT3, hack));
		#endif
	}
	vec2 h = vec2 (DELTA, 0.0);
	vec3 normal = normalize (vec3 (
		scene (rayPosition + h.xyy) - scene (rayPosition - h.xyy),
		scene (rayPosition + h.yxy) - scene (rayPosition - h.yxy),
		scene (rayPosition + h.yyx) - scene (rayPosition - h.yyx)));
	vec3 colorRaymarching = mapping (rayPosition, normal);

	// Voxel
	#ifdef HACK
	origin -= SQRT3 * ray;
	#endif
	vec3 raySign = sign (ray);
	vec3 rayIncrement = raySign / ray;
	vec3 rayTime = (0.5 + raySign * (0.5 - fract (origin + 0.5))) * rayIncrement;
	rayPosition = floor (origin + 0.5);
	vec3 rayAxis = vec3 (0.0);
	for (int rayStep = 0; rayStep < RAY_STEP_MAX; ++rayStep) {
		rayAxis = step (rayTime.xyz, rayTime.yzx) * step (rayTime.xyz, rayTime.zxy);
		rayPosition += rayAxis * raySign;
		if (scene (rayPosition) < DELTA) {
			break;
		}
		rayTime += rayAxis * rayIncrement;
	}
	vec3 colorVoxel = mapping (origin + ray * min (rayTime.x, min (rayTime.y , rayTime.z)), -rayAxis * raySign);

	// Set the fragment color
	gl_FragColor = vec4 (mix (colorRaymarching, colorVoxel, smoothstep (-0.2, 0.2, cos (iGlobalTime * 0.8))), 1.0);
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
