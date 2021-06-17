// Nicolas Robert [Nrx]
Shader "Custom/Shader-24" {
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

// Shader from: https://www.shadertoy.com/view/lllGW7

// Entry for [2TC 15] (= 280 chars or less, as counted by Shadertoy)

//#define T(X) texture2D (iChannel0, vec2 (X, 0)).x
#define T(X) (.4 + .4 * cos (X + X * t))
void main () {
	float t = iGlobalTime, r = T (0.) * .4, a = t;
	vec4 p = gl_FragCoord / iResolution.y - .5, c = -p;
	for (float d = 1.; d > 0.; d -= .1)
		gl_FragColor = c += fract (d + t + vec4 (0, .7, .3, 0))
			* .1 * (.1 + T (d))
			/ length (p.xy - r * vec2 (cos (a += .63), sin (a)));
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
