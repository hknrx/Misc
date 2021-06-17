// Nicolas Robert [Nrx]
Shader "Custom/Cylinder" {
	Properties {
		[HideInInspector] iResolution ("Resolution", Vector) = (1.0, 1.0, 0.0, 0.0)
		[HideInInspector] iGlobalTime ("Time", Float) = 0.0
		[HideInInspector] iMouse ("Mouse", Vector) = (0.0, 0.0, 0.0, 0.0)
		[HideInInspector] fragOffset ("Fragment offset", Float) = 0.0
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

				// Variables shared between the fragment shader and the OpenGL ES environment
				uniform vec3 iResolution;	// Shadertoy input
				uniform float iGlobalTime;	// Shadertoy input
				uniform vec4 iMouse;		// Shadertoy input
				uniform float fragOffset;	// To perform the anti-aliasing

// Shader from: https://www.shadertoy.com/view/lsjSDd

// Parameters
#define CAMERA_FOCAL_LENGTH	1.2
#define DOT_COUNT			100.0
//#define SOUND
#define MOUSE

// Constants
#define PI 3.1415926535897932384626433832795

// PRNG
float rand (in vec2 seed) {
	return fract (sin (dot (seed, vec2 (12.9898, 78.233))) * 137.5453);
}

// HSV to RGB
vec3 rgb (in vec3 hsv) {
	hsv.yz = clamp (hsv.yz, 0.0, 1.0);
	return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.xxx + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
}

// Main function
void main () {

	// Define the ray corresponding to this fragment
	vec3 ray = vec3 ((2.0 * (gl_FragCoord.xy - fragOffset) - iResolution.xy) / iResolution.y, CAMERA_FOCAL_LENGTH);

	// Get the music info
	#ifdef SOUND
	float soundBass = texture2D (iChannel0, vec2 (0.0)).x;
	float soundTreble = texture2D (iChannel0, vec2 (0.9, 0.0)).x;
	#else
	float soundBass = 0.6 + 0.4 * cos (iGlobalTime * 0.2);
	float soundTreble = 0.5 + 0.5 * cos (iGlobalTime * 1.2);
	#endif

	// Define the number of rows
	float dotRowCount = floor (20.0 + 60.0 * soundTreble * soundBass) * 2.0;

	// Compute the orientation of the camera
	float yawAngle = cos (iGlobalTime * 2.0);
	float pitchAngle = 2.0 * PI * cos (iGlobalTime * 0.2 + soundTreble * 0.4);
	#ifdef MOUSE
	yawAngle += 2.0 * PI * iMouse.x / iResolution.x;
	pitchAngle += PI * (1.0 - iMouse.y / iResolution.y);
	#endif

	float cosYaw = cos (yawAngle);
	float sinYaw = sin (yawAngle);
	float cosPitch = cos (pitchAngle);
	float sinPitch = sin (pitchAngle);

	mat3 cameraOrientation;
	cameraOrientation [0] = vec3 (cosYaw, 0.0, -sinYaw);
	cameraOrientation [1] = vec3 (sinYaw * sinPitch, cosPitch, cosYaw * sinPitch);
	cameraOrientation [2] = vec3 (sinYaw * cosPitch, -sinPitch, cosYaw * cosPitch);

	ray = cameraOrientation * ray;

	// Compute the position of the camera
	float cameraDist = -2.0 * (cos (iGlobalTime) * cos (iGlobalTime * 3.5) + soundBass);
	vec3 cameraPosition = cameraOrientation [2] * cameraDist;

	// Compute the intersection point (ray / cylinder)
	float a = dot (ray.xz, ray.xz);
	float b = dot (cameraPosition.xz, ray.xz);
	float c = b * b - a * (dot (cameraPosition.xz, cameraPosition.xz) - 1.0);
	float ok = step (0.0, c);
	c = sqrt (c);
	vec3 hit;
	if (b < -c) {
		hit = cameraPosition - ray * (b + c) / a;
		if (abs (hit.y * DOT_COUNT / PI + 1.0) > dotRowCount) {
			hit = cameraPosition - ray * (b - c) / a;
		}
	} else {
		hit = cameraPosition - ray * (b - c) / a;
	}
	vec2 frag = vec2 ((atan (hit.z, hit.x) + PI) * DOT_COUNT, hit.y * DOT_COUNT + PI) / (2.0 * PI);

	// Compute the fragment color
	vec2 id = floor (frag);
	float random = rand (id);
	vec3 color = rgb (vec3 (iGlobalTime * 0.05 + id.y * 0.005, 1.0, 1.0));
	color += 0.5 * cos (random * vec3 (1.0, 2.0, 3.0));
	color *= smoothstep (0.5, 0.1, length (fract (frag) - 0.5));
	color *= 0.5 + 1.5 * step (0.9, cos (random * iGlobalTime * 5.0));
	color *= 0.5 + 0.5 * cos (random * iGlobalTime + PI * 0.5 * soundTreble);
	color *= smoothstep (dotRowCount, 0.0, (abs (id.y + 0.5) - 1.0) * 2.0);
	gl_FragColor = vec4 (color * ok, 1.0);
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
