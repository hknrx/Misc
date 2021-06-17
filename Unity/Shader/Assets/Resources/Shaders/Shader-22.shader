// Nicolas Robert [Nrx]
Shader "Custom/Shader-22" {
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

// Shader from: https://www.shadertoy.com/view/llXGD4

// Entry for [2TC 15] (= 280 chars or less, as counted by Shadertoy)

void main () {
	float m = 0., h;
	vec4 r = gl_FragCoord / iResolution.y - .8, T = r - r, P = T, N;
	++r.y;
	r.z = m;
	for (int i = 0; i < 42; ++i)
		if ((h = cos (P.x * P.y + iDate.w * 4.) - 15.) < m)
			P += N = h > (m = min (T.x, T.y) * (r.y - 2.)) ? N - N : step (T, T.yxzw) * sign (r),
			T += N / r;
	gl_FragColor = (.6 + .4 * sin (P)) * (.8 - .4 * N.x - .2 * N.y);
}

// Below: code to demonstrate how to move the camera (290 chars)
/*
void main () {
	float t = iDate.w * 4., m = t, h;
	vec4 N = vec4 (cos (t), t, -.8, .2),
		r = gl_FragCoord / iResolution.y + N.zwxy,
		S = sign (r),
		T = (.5 + .5 * S - fract (N)) / r,
		P = floor (N);
	for (int i = 0; i < 42; ++i)
		if ((h = cos (P.x * P.y + t) - 9.) < m)
			P += N = h > (m = min (T.x, T.y) * (r.y - 2.)) ? N - N : step (T, T.yxww) * S,
			T += N / r;
	gl_FragColor = cos (P) + N.x * .4 + N.y * .2;
}
*/

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
