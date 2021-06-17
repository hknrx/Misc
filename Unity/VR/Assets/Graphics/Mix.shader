// Nicolas Robert [Nrx]
Shader "Custom/Mix" {
	Properties {
		[HideInInspector] resolution ("Resolution", Vector) = (1.0, 1.0, 0.0, 0.0)
		[HideInInspector] _MainTex ("Normal texture", 2D) = "white" {}
		[HideInInspector] offsettedTexture ("Offsetted texture", 2D) = "white" {}
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

			// Vertex shader
			#ifdef VERTEX
			uniform vec2 resolution;
			varying vec2 uv0;
			varying vec2 uv1;
			void main () {
				gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
				uv0 = gl_MultiTexCoord0.st;
				uv1 = (uv0 * resolution + 0.5) / (resolution + 1.0);
			}
			#endif

			// Fragment shader
			#ifdef FRAGMENT
			uniform sampler2D _MainTex;
			uniform sampler2D offsettedTexture;
			varying vec2 uv0;
			varying vec2 uv1;
			void main () {
				gl_FragColor = (texture2D (_MainTex, uv0) + texture2D (offsettedTexture, uv1)) * 0.5;
			}
			#endif

			ENDGLSL
		}
	}
}
