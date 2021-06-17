// Nicolas Robert [Nrx]
Shader "Custom/Shader-23" {
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

// Shader from: https://www.shadertoy.com/view/XtX3D7

// Entry for [2TC 15] (= 280 chars or less, as counted by Shadertoy)

void main () {
	vec3 r = vec3 (gl_FragCoord.xy / iResolution.y - .5, 2), p = vec3 (-20, 30, 1), q;
	float d = .6, c = 0., l = c;
	r.y -= d;
	for (int i = 0; i < 99; ++i)
		if (d > .1 && l < 99.)
			q = p + sin (p.z * .2 + iDate.w),
			l += d = (length (q.xy) - 4. + sin (abs (q.x * q.y) + p.z * 4.) * sin (p.z)) * .1,
			p += r * d,
			c += .01;
	gl_FragColor = c * vec4 (2, 1, 0, 1);
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
