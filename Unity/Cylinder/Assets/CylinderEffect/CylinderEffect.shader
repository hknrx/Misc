// Nicolas Robert [Nrx]

// - What you see is a cylinder of radius 1.0 on which light dots are mapped
// - The number of dots mapped on the cylinder depends on dotCount
// - dotCount shall be an integer value if you don't want some dots to be cut off
// - The curvature and the number of dots you actually see depend on:
//   * The position of the camera (cameraPosition)
//   * The focal length of the camera (cameraFocalLength), which modifies the actual field of view
// - The shape of the dots is defined by dotRadiusOn and dotRadiusOff
//   * dotRadiusOn is the radius of the part of the dot that is very bright ("on")
//   * dotRadiusOn should be greater than 0.0, and probably lower than 0.5
//   * dotRadiusOff is the radius of the area in which the brightness fades out
//   * dotRadiusOff shall be strictly greater than dotRadiusOn
// - The color of the dots is defined by dotColorBase, and modified dynamically using dotColorChange
// - The number of rows is defined by dotRowCount (it should be an integer multiple of 2)

Shader "Custom/CylinderEffect"
{
	Properties
	{
		[HideInInspector] time ("Time", Float) = 0.0
		[HideInInspector] cameraOrientation0 ("Camera orientation (0)", Vector) = (1.0, 0.0, 0.0, 0.0)
		[HideInInspector] cameraOrientation1 ("Camera orientation (1)", Vector) = (0.0, 1.0, 0.0, 0.0)
		[HideInInspector] cameraOrientation2 ("Camera orientation (2)", Vector) = (0.0, 0.0, 1.0, 0.0)
		[HideInInspector] cameraPosition ("Camera position", Vector) = (0.0, 0.0, -0.9, 0.0)
		cameraFocalLength ("Focal length of the camera", Float) = 1.2
		dotCount ("Number of dots (horizontally)", Float) = 70.0
		dotRadiusOn ("Dot radius (bright part)", Float) = 0.2
		dotRadiusOff ("Dot radius (fade out)", Float) = 0.6
		dotColorBase ("Base color of the dots", Vector) = (0.2, 1.0, 1.0, 1.0)
		dotColorChange ("Color modifiers", Vector) = (0.2, 0.3, 0.3, 0.0)
		dotRowCount ("Number of rows", Float) = 16.0
	}
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
		}
		Pass
		{
			ZWrite Off
			ZTest Always
			Blend SrcAlpha OneMinusSrcAlpha

			GLSLPROGRAM

			// Define multiple shader program variants
			#pragma multi_compile CAMERA_ALWAYS_IN CAMERA_SOMETIMES_OUT
			#pragma multi_compile COLOR_BLACK COLOR_ALPHA

			// Precision setting (shared between the vertex shader and the fragment shader)
			#ifdef GL_ES
			precision highp float;
			#endif

			// Vertex shader
			#ifdef VERTEX

			// Variables shared between the vertex shader and the OpenGL ES environment
			uniform vec3 cameraOrientation0;
			uniform vec3 cameraOrientation1;
			uniform vec3 cameraOrientation2;
			uniform float cameraFocalLength;

			// Variables shared between the vertex shader and the fragment shader
			varying vec3 ray;

			// Main function
			void main (void)
			{
				// Set the position
				gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;

				// Define the ray corresponding to this fragment
				ray = mat3 (cameraOrientation0, cameraOrientation1, cameraOrientation2) * vec3 (2.0 * gl_MultiTexCoord0.st - 1.0, cameraFocalLength);
			}
			#endif

			// Fragment shader
			// See https://www.shadertoy.com/view/lsjSDd
			#ifdef FRAGMENT

			// Define the arctangent function (an approximation will be used if not defined)
			#define atan2 atan

			// Constants of the fragment shader
			#define M_PI 3.1415926535897932384626433832795

			// Variables shared between the fragment shader and the OpenGL ES environment
			uniform float time;
			uniform vec3 cameraPosition;
			uniform float dotCount;
			uniform float dotRadiusOn;
			uniform float dotRadiusOff;
			uniform vec4 dotColorBase;
			uniform vec3 dotColorChange;
			uniform float dotRowCount;

			// Variables shared between the vertex shader and the fragment shader
			varying vec3 ray;

			// Arctangent function
			#ifndef atan2
			float atan2 (in float y, in float x) {

				// From http://www.deepdyve.com/lp/institute-of-electrical-and-electronics-engineers/full-quadrant-approximations-for-the-arctangent-function-tips-and-V6yJDoI0iF
				// atan (x) = x / (1 + 0.28086 x^2)

				float t1 = abs (y);
				float t2 = abs (x);
				float t3 = min (t1, t2) / max (t1, t2);
				t3 = t3 / (1.0 + 0.28086 * t3 * t3);
				t3 = t1 > t2 ? M_PI / 2.0 - t3 : t3;
				t3 = x < 0.0 ? M_PI - t3 : t3;
				t3 = y < 0.0 ? -t3 : t3;
				return t3;
			}
			#endif

			// PRNG
			float rand (in vec2 seed) {
				return fract (sin (dot (seed, vec2 (12.9898, 78.233))) * 137.5453);
			}

			// Coloring mode
			#ifdef COLOR_BLACK
			#define COLOR color.rgb
			#else
			#define COLOR color.a
			#endif

			// Main function
			void main () {

				// Compute the intersection point (ray / cylinder)
				float a = dot (ray.xz, ray.xz);
				float b = dot (cameraPosition.xz, ray.xz);
				float c = dot (cameraPosition.xz, cameraPosition.xz) - 1.0;
				vec3 hit;
				#ifdef CAMERA_ALWAYS_IN
					hit = cameraPosition + ray * (sqrt (b * b - a * c) - b) / a;
				#else
					c *= a;
					float d = b * b;
					if (c > d * step (b, 0.0)) discard;
					c = sqrt (d - c);
					if (b < -c) {
						hit = cameraPosition - ray * (b + c) / a;
						if (abs (hit.y * dotCount / M_PI + 1.0) > dotRowCount) {
							hit = cameraPosition - ray * (b - c) / a;
						}
					} else {
						hit = cameraPosition - ray * (b - c) / a;
					}
				#endif
				vec2 frag = vec2 ((atan2 (hit.z, hit.x) + M_PI) * dotCount, hit.y * dotCount + M_PI) / (2.0 * M_PI);

				// Compute the fragment color
				vec2 id = floor (frag);
				float row = abs (id.y + 0.5) * 2.0;
				float random = rand (id);
				vec4 color = dotColorBase;
				color.rgb += dotColorChange * vec3 (cos (random), cos (2.0 * random), cos (3.0 * random));
				COLOR *= smoothstep (dotRadiusOff, dotRadiusOn, length (fract (frag) - 0.5));
				COLOR *= 0.8 + 0.2 * cos (random * time);
				COLOR *= smoothstep (dotRowCount + 1.0, 0.0, row);
				#ifdef COLOR_BLACK
					color.a *= step (row, dotRowCount);
				#endif
				gl_FragColor = color;
			}
			#endif

			ENDGLSL
		}
	}
}
