// Nicolas Robert [Nrx]
Shader "Custom/PressureEffect"
{
	Properties
	{
		[HideInInspector] _MainTex ("Base (RGB)", 2D) = "white" {}
		[HideInInspector] screenResolution ("Screen Resolution", Vector) = (640.0, 480.0, 0.0, 0.0)
		renderIterationCount ("Render Iteration Count", Float) = 5
		[HideInInspector] touchOrigin ("Touch Origin", Vector) = (0.0, 0.0, 0.0, 0.0)
		[HideInInspector] touchCurrent ("Touch Current", Vector) = (0.0, 0.0, 0.0, 0.0)
		[HideInInspector] touchControl ("Touch Control", Float) = 0.0
		touchRadius ("Touch Radius", Float) = 0.12
		gridRadius ("Grid Radius", Float) = 0.2
		gridFactor ("Grid Factor", Float) = 40.0
		gridThickness ("Grid Thickness", Float) = 0.06
		[HideInInspector] gridColorCenter ("Grid Color Center", Vector) = (0.0, 1.0, 0.0, 1.0)
		[HideInInspector] gridColorBorder ("Grid Color Border", Vector) = (1.0, 1.0, 0.0, 1.0)
		lightDirection ("Light Direction", Vector) = (1.0, 1.0, 1.0, 0.0)
		lightMinimum ("Light Minimum", Range (0.0, 1.0)) = 0.5
	}
	SubShader
	{
		Pass
		{
			ZWrite Off
			ZTest Always

			GLSLPROGRAM

			// Define multiple shader program variants
			#pragma multi_compile SMOOTH_OFF SMOOTH_ON
			#pragma multi_compile LIGHT_OFF LIGHT_ON

			// Precision setting (shared between the vertex shader and the fragment shader)
			#ifdef GL_ES
			precision highp float;
			#endif

			// Constants shared between the vertex shader and the fragment shader
			#define SMOOTH_DISTANCE 0.05

			// Variables shared between the vertex & fragment shaders and the OpenGL ES environment
			uniform vec2 screenResolution;
			uniform float touchRadius;
			uniform float gridRadius;
			uniform float lightMinimum;

			// Vertex shader
			#ifdef VERTEX

			// Constants of the vertex shader
			#define CAMERA_DISTANCE 1.5

			// Variables shared between the vertex shader and the OpenGL ES environment
			uniform vec2 touchOrigin;
			uniform vec2 touchCurrent;
			uniform float touchControl;
			uniform vec3 lightDirection;

			// Variables shared between the vertex shader and the fragment shader
			varying vec3 touchA;
			varying vec3 touchAB;
			varying float touchAB2;
			varying vec3 camera;
			varying float touchRadiusControlled;
			varying float gridRadiusControlled;
			varying vec3 lightDirectionNormalized;
			varying float lightDefault;

			// Main function
			// Note: we should better compute all these varying variables outside the shader...
			// ...but it would force us to split the code between the C# script and the GLSL shader! :(
			void main (void)
			{
				// Set the touch variables
				float c = touchControl - 1.0;
				float r = SMOOTH_DISTANCE * 1.1;

				touchA = vec3 (touchOrigin / screenResolution.y, c * r - touchRadius);
				vec3 touchB = vec3 (touchCurrent / screenResolution.y, c * (r + touchRadius));
				touchAB = touchB - touchA;
				touchAB2 = dot (touchAB, touchAB);

				// Precompute some values
				camera = vec3 (0.5 * screenResolution.x / screenResolution.y, 0.5, -CAMERA_DISTANCE);
				touchRadiusControlled = -touchRadius * touchControl;
				gridRadiusControlled = -gridRadius * touchControl;
				#ifdef LIGHT_ON
				lightDirectionNormalized = normalize (lightDirection);
				lightDefault = mix (max (0.0, lightDirectionNormalized.z), 1.0, lightMinimum);
				#endif

				// Set the position
				gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
			}
			#endif

			// Fragment shader
			// See https://www.shadertoy.com/view/lsBXWK
			#ifdef FRAGMENT

			// Constants of the fragment shader
			#define DELTA 0.001

			// Variables shared between the fragment shader and the OpenGL ES environment
			uniform sampler2D _MainTex;
			uniform float renderIterationCount;
			uniform float gridFactor;
			uniform float gridThickness;
			uniform vec4 gridColorCenter;
			uniform vec4 gridColorBorder;

			// Variables shared between the vertex shader and the fragment shader
			varying vec3 touchA;
			varying vec3 touchAB;
			varying float touchAB2;
			varying vec3 camera;
			varying float touchRadiusControlled;
			varying float gridRadiusControlled;
			varying vec3 lightDirectionNormalized;
			varying float lightDefault;

			// Global variable
			vec3 touchXP;
			float touchDistance;

			#ifdef SMOOTH_ON
			// Smooth minimum (http://www.iquilezles.org/www/articles/smin/smin.htm)
			float smoothMin (in float a, in float b, in float k)
			{
				float h = clamp (0.5 + 0.5 * (a - b) / k, 0.0, 1.0);
				return mix (a, b, h) - k * h * (1.0 - h);
			}
			#endif

			// Get the distance of a point to the surface
			float surfaceDistance (in vec3 p)
			{
				vec3 touchAP = p - touchA;
				touchXP = touchAP - touchAB * clamp (dot (touchAP, touchAB) / touchAB2, 0.0, 1.0);
				touchDistance = length (touchXP);
				#ifdef SMOOTH_ON
				return -smoothMin (p.z, touchDistance - touchRadius, SMOOTH_DISTANCE);
				#else
				return -min (p.z, touchDistance - touchRadius);
				#endif
			}

			// Main function
			void main (void)
			{
				// Get the position of this fragment
				vec3 frag = vec3 (gl_FragCoord.xy / screenResolution.y, 0.0);

				// Raymarching
				vec3 ray = normalize (frag - camera);
				float d = surfaceDistance (frag);
				for (float i = 0.0; i < renderIterationCount; ++i)
				{
					if (d < DELTA)
					{
						break;
					}
					frag += d * ray;
					d = surfaceDistance (frag);
				}

				// Get the color from the texture
				vec4 color = texture2D (_MainTex, vec2 (frag.x * screenResolution.y / screenResolution.x, frag.y));

				// Check whether there is any effect to apply
				if (touchDistance < gridRadius)
				{
					// Add the grid
					vec4 gridColor = mix (gridColorCenter, gridColorBorder, length (touchXP.xy) / touchRadius);
					vec2 gridPosition = smoothstep (gridThickness * 0.5, gridThickness * 1.5, abs (fract (frag.xy * gridFactor) - 0.5));
					color = mix (color, gridColor, (1.0 - gridPosition.x * gridPosition.y) * smoothstep (gridRadiusControlled, touchRadiusControlled, -touchDistance));

					#ifdef LIGHT_ON
					// Lighting
					const vec2 h = vec2 (DELTA, 0.0);
					vec3 normal = normalize (vec3 (
						d - surfaceDistance (frag + h.xyy),
						d - surfaceDistance (frag + h.yxy),
						h.x
					));
					color.xyz *= mix (max (0.0, dot (normal, lightDirectionNormalized)), 1.0, lightMinimum);
				}
				else
				{
					color.xyz *= lightDefault;
					#endif
				}

				// Set the fragment color
				gl_FragColor = color;
			}
			#endif

			ENDGLSL
		}
	}
}
