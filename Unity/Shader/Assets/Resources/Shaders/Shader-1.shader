// Nicolas Robert [Nrx]
Shader "Custom/Shader-1" {
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

#define M_PI 3.1415926535897932384626433832795

void main () {
	vec2 position = 2.0 * gl_FragCoord.xy / iResolution.xy - 1.0;
	position.x *= iResolution.x / iResolution.y;
	float d2D = 1.0 / length (position) + iGlobalTime;
	float a2D = atan (position.y, position.x) + sin (iGlobalTime * 0.2) * M_PI;
	gl_FragColor = vec4 (0.5 + sin (d2D * 8.0) * 0.5, 0.5 + sin (a2D * 8.0) * 0.5, 0.5 + sin (d2D * 4.0) * sin (a2D * 4.0) * 0.5, 1.0);
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
