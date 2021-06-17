// Nicolas Robert [Nrx]
Shader "Custom/Shader-25" {
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

// Shader from: https://www.shadertoy.com/view/Mtl3DN

// Entry for [2TC 15] (= 280 chars or less, as counted by Shadertoy)

//#define T(X) texture2D (iChannel0, vec2 (X)).x);
#define T(X) .4 + .4 * cos (X + 8. * iGlobalTime));

void main () {
	vec3 R = iResolution, f = (2. * gl_FragCoord.xyz - R) / R.y;
	f *= 5. - cos (f.yxz) * sin (T (0.)
	float r = cos (dot (floor (f), R));
	R = step (-.8, -cos (f * 6.3));
	gl_FragColor = 3. * fract (r + vec4 (0, .3, .7, 0)) * R.x * R.y * (1. - length (fract (f) - .5)) * cos (r * iDate.w + T (1.)
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
