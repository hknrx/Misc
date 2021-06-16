// Nicolas Robert [Nrx]

Shader "Custom/Particle" {
	SubShader {
		Tags {
			"Queue" = "Overlay"
		}

		Lighting Off
		Fog {Mode Off}
		Cull Off
		ZWrite Off
		ZTest Always
		Blend One One

		Pass {
			GLSLPROGRAM

			// Define multiple shader program variants:
			// - (default): normal display
			// - DEBUG: basic display
			#pragma multi_compile __ DEBUG

			// Vertex shader: begin
			#ifdef VERTEX

				// Variables shared between the vertex shader and the fragment shader
				varying vec2 texCoord;

				// Main function
				void main () {

					// Set the texture coordinates
					texCoord = gl_MultiTexCoord0.st;

					// Set the vertex color
					gl_FrontColor = gl_Color;

					// Set the vertex position
					gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
				}

			// Vertex shader: end
			#endif

			// Fragment shader: begin
			#ifdef FRAGMENT

				// Variables shared between the vertex shader and the fragment shader
				varying vec2 texCoord;

				// Main function
				void main () {

					// Set the fragment color
					#ifdef DEBUG
					vec2 p = texCoord - 0.5;
					gl_FragColor = vec4 (gl_Color.rgb * step (dot (p, p), 0.25), 1.0);
					#else
					gl_FragColor = vec4 (gl_Color.rgb * (1.0 - length (2.0 * texCoord - 1.0)), 1.0);
					#endif
				}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
