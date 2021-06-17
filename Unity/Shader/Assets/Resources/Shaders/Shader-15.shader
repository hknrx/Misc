// Nicolas Robert [Nrx]
Shader "Custom/Shader-15" {
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

// Shader from: https://www.shadertoy.com/view/MdSSDy

// Yellow LEDs represent seconds, red ones minutes, and green ones
// hours; all numbers are shown in their binary format (LEDs values
// from right to left: 1, 2, 4, 8, 16 and 32).

#define M_PI 3.14159265359

vec3 rgb (in vec3 hsv) {
	#ifdef HSV_SAFE
	hsv.yz = clamp (hsv.yz, 0.0, 1.0);
	#endif
	return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.xxx + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
}

float segDist (in vec2 p, in vec4 ab, in float cut) {
	p -= ab.xy;
	ab.zw -= ab.xy;
	float l = dot (ab.zw, ab.zw);
	cut *= sqrt (l);
	return length (p - ab.zw * clamp (dot (p, ab.zw), cut, l - cut) / l);
}

void main (void) {

	// Get the fragment's position
	vec2 frag = 7.0 * (2.0 * gl_FragCoord.xy - iResolution.xy) / iResolution.x;

	// Define the background lights
	vec3 lightColor = vec3(0.0, 0.0, 0.2);
	const float lightCount = 5.0;
	for(float lightId = 0.0; lightId < 1.0; lightId += 1.0 / lightCount) {
		float lightAngle = 2.0 * M_PI * lightId + iGlobalTime;
		lightColor += rgb (vec3 (lightId + iGlobalTime * 0.1, 1.0, 1.0)) / length (frag - 2.0 * vec2 (cos (lightAngle), sin (lightAngle))) * (3.0 + 2.0 * cos (iGlobalTime * (1.0 + lightId))) ;
	}
	lightColor /= lightCount;

	// Define the casing color
	float casingColor = 0.3 + 0.2 * cos (frag.x + frag.y + iGlobalTime);

	// Rotate the watch every 5s
	float fragAngle = 0.1 * sin (iGlobalTime * 2.0 * M_PI) * step (4.0, mod (iGlobalTime, 5.0));
	vec2 fragRotate = vec2 (cos (fragAngle), sin (fragAngle));
	frag = mat2 (fragRotate.x, fragRotate.y, -fragRotate.y, fragRotate.x) * frag;

	// Define the panel and the border
	float panelDist = length (frag) - 3.5;
	float borderDist = panelDist - 0.05;

	// Define the LEDs
	float ledThresholdBar2 = step (-0.5, frag.y);
	float ledThresholdBar3 = step (0.5, frag.y);
	vec2 ledPosition = frag + vec2 (0.5 * ledThresholdBar3, 0.5);
	float ledDist = length (fract (ledPosition) - 0.5);
	float ledDisplay = step (ledThresholdBar3 * 0.5 - 3.0, -abs (frag.x)) * step (-1.5, -abs (frag.y));

	float ledTime = mod (iDate.w / (1.0 + 59.0 * ledThresholdBar2 + 3540.0 * ledThresholdBar3), 60.0 - 36.0 * ledThresholdBar3);
	vec3 ledColor = vec3 (1.0 - ledThresholdBar3, ledThresholdBar3 - ledThresholdBar2 + 1.0, 0.0);
	ledColor *= step (0.5, fract (ledTime / exp2 (3.0 - floor (ledPosition.x))));

	// Define the indicators
	float indicatorDist = min (abs (length (frag - vec2 (-1.0, 1.7)) - 0.08), abs (length (frag - vec2 (-1.0, 1.84)) - 0.06));
	indicatorDist = min (indicatorDist, segDist (frag, vec4 (-1.0, 1.8, -1.0, 1.0), 0.3));
	indicatorDist = min (indicatorDist, segDist (frag, vec4 (-1.0, 1.0, -0.5, 0.0), 0.3));
	indicatorDist = min (indicatorDist, segDist (frag, vec4 (-0.5, 0.0, -0.5, -1.0), 0.3));

	// Create everything (lights, panel, casing, LEDs, indicators)
	vec3 color = lightColor * smoothstep (0.0, 0.2, borderDist);
	color += vec3 (0.1, 0.1, 0.3) * (0.7 + 0.3 * cos (frag.y * M_PI / 3.5)) * smoothstep (0.0, -0.1, panelDist) * (1.0 - smoothstep (0.15, 0.1, ledDist) * ledDisplay);
	color += casingColor * smoothstep (0.05, 0.0, max (borderDist, -panelDist));
	color += ledColor * smoothstep (0.25, 0.1, ledDist) * ledDisplay;
	color += 0.1 * smoothstep (0.05, 0.0, indicatorDist);

	// Set the fragment color
	gl_FragColor = vec4 (color, 1.0);
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
