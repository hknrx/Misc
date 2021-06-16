// Nicolas Robert [Nrx]

Shader "Custom/Collider" {
	Properties {
		[HideInInspector] colliders ("Colliders", 2D) = "white" {}
		[HideInInspector] gridSize ("Grid size", Vector) = (1.0, 1.0, 0.0, 0.0)
		[HideInInspector] scaleX ("Scale X", Float) = 1.0
		[HideInInspector] time ("Time", Float) = 0.0
	}
	SubShader {
		Tags {
			"Queue" = "Background"
		}

		Lighting Off
		Fog {Mode Off}
		Cull Off
		ZWrite Off
		ZTest Always
		Blend Off

		Pass {
			GLSLPROGRAM

			// Define multiple shader program variants:
			// - (default): normal display (smoothed corners)
			// - DEBUG: basic display (squares)
			#pragma multi_compile __ DEBUG

			// Vertex shader: begin
			#ifdef VERTEX

				// Variables shared between the vertex shader and the fragment shader
				varying vec2 texCoord;

				// Variables shared between the vertex shader and the OpenGL ES environment
				uniform float scaleX;

				// Main function
				void main () {

					// Set the texture coordinates
					texCoord = gl_MultiTexCoord0.st;
					texCoord.x = (texCoord.x - 0.5) * scaleX + 0.5;

					// Set the vertex position
					gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
				}

			// Vertex shader: end
			#endif

			// Fragment shader: begin
			#ifdef FRAGMENT

				// Variables shared between the vertex shader and the fragment shader
				varying vec2 texCoord;

				// Variables shared between the fragment shader and the OpenGL ES environment
				uniform sampler2D colliders;
				uniform vec2 gridSize;
				uniform float time;

				// PRNG
				float rand (in vec2 seed) {
					return fract (sin (dot (seed, vec2 (12.9898, 78.233))) * 137.5453);
				}

				// HSV to RGB
				vec3 hsv2rgb (in vec3 hsv) {
					hsv.yz = clamp (hsv.yz, 0.0, 1.0);
					return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.x + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
				}

				// Main function
				void main () {

					// Colliders
					#ifdef DEBUG
					float collider = texture2D (colliders, texCoord).a;
					#else
					vec2 frag = texCoord * gridSize;
					vec2 delta = fract (frag) - 0.5;
					frag = (floor (frag) + 0.5) / gridSize;
					float collider = texture2D (colliders, frag).a;
					if (abs (delta.x) + abs (delta.y) > 0.5) {
						delta = sign (delta) / gridSize;
						float colliderHor = texture2D (colliders, frag + delta * vec2 (1.0, 0.0)).a;
						float colliderVer = texture2D (colliders, frag + delta * vec2 (0.0, 1.0)).a;
						if (collider < 0.5) {
							collider = colliderHor * colliderVer;
						} else {
							collider = colliderHor + colliderVer + texture2D (colliders, frag + delta).a;
						}
					}
					#endif

					// Texture
					vec3 color;
					if (collider > 0.5) {

						// Collider (wood)
						vec2 frag = 4.0 * texCoord;
						frag = frag.y * 13.0 + sin (frag * 17.0) * sin (frag.yx * 7.0) * sin (time * 0.2 + frag);
						color = vec3 (0.8, 0.6, 0.4) * (1.0 - 0.5 * length (fract (frag) - 0.5));
					} else {

						// Background (light squares)
						vec2 frag = 16.0 * texCoord;
						frag += 0.5 * cos (frag.yx + time);
						float angle = rand (floor (frag)) * 3.14159;
						vec3 hsv = vec3 (0.6 + 0.1 * cos (angle), 1.0, 0.2 + 0.1 * cos (angle * time));
						color = hsv2rgb (hsv) * smoothstep (1.0, 0.2, length (fract (frag) - 0.5));
					}

					// Set the fragment color
					gl_FragColor = vec4 (color, 1.0);
				}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
