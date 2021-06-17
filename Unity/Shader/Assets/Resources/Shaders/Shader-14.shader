// Nicolas Robert [Nrx]
Shader "Custom/Shader-14" {
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

// Shader from: https://www.shadertoy.com/view/MdjXRt

// Modified version that apparently runs a little faster (but the code is harder to understand and maintain)

// LED watch: the two bars on the left represent hours, the two on the
// right minutes. LEDs in the first bar count for 6, LEDs in the third
// bar count for 10; LEDs in the 2 other bars count for 1.

#define M_PI 3.1415926535897932384626433832795
#define VERTICAL

float boxDist (in vec2 p, in vec2 b) {
	return length (max (abs (p) - b, 0.0));
}

float boxDist (in vec2 p, in vec3 b) {
	return length (max (abs (p) - b.xy + b.z, 0.0)) - b.z;
}

vec3 rgb (in vec3 hsv) {
	#ifdef HSV_SAFE
	hsv.yz = clamp (hsv.yz, 0.0, 1.0);
	#endif
	return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.xxx + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
}

float rand (in vec2 seed) {
	return fract (sin (dot (seed, vec2 (12.9898, 78.233))) * 137.5453);
}

void main (void) {

	// Get the fragment's position in the watch space
	#ifndef VERTICAL
	vec2 frag = (2.0 * gl_FragCoord.xy - iResolution.xy) / iResolution.x;
	#else
	vec2 frag = (2.0 * gl_FragCoord.yx - iResolution.yx) / iResolution.y;
	#endif
	frag *= 1.0 - vec2 (0.02, 0.04) * cos (frag.yx * 2.0) * max (0.0, 50.0 * sin (iGlobalTime * M_PI * 2.0 / 5.0) - 49.0);
	#ifndef VERTICAL
	frag *= 8.0;
	#else
	frag *= vec2 (6.0, -6.0);
	#endif

	// Define the panel and the border
	vec3 panelSize = vec3 (5.0, 2.2, 1.0);
	float panelDist = -boxDist (frag, panelSize);
	float borderDist = boxDist (frag, panelSize + 0.1);

	// Define the LEDs
	vec2 led = frag;
	led.x -= 0.5;
	vec2 ledId = floor (led);
	float random = rand (ledId);
	float ledThresholdBar2 = step (-1.5, ledId.y);
	float ledThresholdBar4 = step (0.5, ledId.y);
	float ledTimeModulo = 10.0 - 4.0 * ledThresholdBar2 - 2.0 * ledThresholdBar4;
	float ledMode = max (0.0, cos (iGlobalTime * 0.5));
	float ledIntensity = mix (0.8 * step (ledId.x + 6.0, mod (iDate.w / (60.0 + 540.0 * ledThresholdBar2 + 3000.0 * step (-0.5, ledId.y) + 18000.0 * ledThresholdBar4), ledTimeModulo)), 0.5 + 0.5 * cos (random + random * iGlobalTime + iGlobalTime), ledMode);
	float ledDist = boxDist (fract (led) - 0.5, vec2 (0.2, 0.03));

	// Create everything (panel, casing, small indicator and LEDs)
	vec3 color = vec3 (0.2, 0.2, 0.2) * (0.7 + 0.3 * cos (frag.x * M_PI / panelSize.x)) * smoothstep (0.1, 0.15, panelDist) * smoothstep (0.2, 0.25, abs (fract (frag.y) - 0.5));
	color += (0.4 + 0.2 * cos (frag.x + frag.y + iGlobalTime)) * smoothstep (0.1, 0.0, max (borderDist, panelDist));
	color += 0.3 * smoothstep (0.05, 0.0, boxDist (frag + vec2 (0.0, 1.9), vec3 (0.04, 0.1, 0.04)));
	color += mix (vec3 (0.1) * smoothstep (0.025, 0.0, ledDist), rgb (vec3 (random + iGlobalTime * 0.1, ledMode, 1.0)) * smoothstep (0.25, 0.0, ledDist), ledIntensity) * step (-4.5, frag.x) * step (5.5 - ledTimeModulo, -frag.x) * step (-2.0, -abs (frag.y));

	// Get the fragment's position in the background tile space
	#ifndef VERTICAL
	frag = 15.0 * gl_FragCoord.xy / iResolution.x;
	#else
	frag = 15.0 * gl_FragCoord.yx / iResolution.y;
	#endif
	frag -= vec2 (iGlobalTime, sin (iGlobalTime));

	// Create the background tiles
	random = rand (floor (frag));
	color += rgb (vec3 (random, 1.0, 1.0)) * smoothstep (0.6, 0.0, length (fract (frag) - 0.5)) * (0.2 + 0.2 * cos (random + random * iGlobalTime + iGlobalTime)) * smoothstep (0.0, 0.2, borderDist);

	// Set the fragment color
	gl_FragColor = vec4 (color, 1.0);
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
