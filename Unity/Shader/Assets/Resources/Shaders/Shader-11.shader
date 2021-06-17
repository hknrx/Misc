// Nicolas Robert [Nrx]
Shader "Custom/Shader-11" {
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

// Shader from: https://www.shadertoy.com/view/MssSDM

#define M_PI 3.1415926535897932384626433832795

const float samples = 6.0;

vec3 rgb (in vec3 hsv) {
	hsv.yz = clamp (hsv.yz, 0.0, 1.0);
	return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.xxx + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
}

void main (void) {
	vec2 p = (gl_FragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;
	p.x += 0.05 * cos (iGlobalTime + p.y * 20.0);
	vec3 color = vec3 (0.0, 0.0, 0.2);
	float r = 0.2 + 0.1 * sin (iGlobalTime * 10.0); // texture2D (iChannel0, vec2 (0.0)).x * 0.4;
	for(float d = 0.0; d < 1.0; d += 1.0 / samples) {
		vec3 c = rgb (vec3 (d + iGlobalTime, 1.0, 1.0));
		float v = min (0.15 + 0.15 * sin (iGlobalTime * 2.0), 0.2) * (0.6 + 0.4 * sin (2.0 * M_PI * d)); // texture2D (iChannel0, vec2 (d, 0.0)).x * 0.7;
		float a = 2.0 * M_PI * d + iGlobalTime;
		vec2 o = r * vec2 (cos (a), sin (a));
		color += c * v / length (p - o);
	}
	color /= samples;
	color = mix (vec3 (length (color)), color, smoothstep (r + 0.02, r + 0.05, length (p)));
	gl_FragColor = vec4 (pow (color, vec3 (0.6 + r)), 1.0);
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
