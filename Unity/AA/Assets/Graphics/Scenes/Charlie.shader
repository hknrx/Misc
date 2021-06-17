// Nicolas Robert [Nrx]
Shader "Custom/Charlie" {
	Properties {
		[HideInInspector] iResolution ("Resolution", Vector) = (1.0, 1.0, 0.0, 0.0)
		[HideInInspector] iGlobalTime ("Time", Float) = 0.0
		[HideInInspector] iMouse ("Mouse", Vector) = (0.0, 0.0, 0.0, 0.0)
		[HideInInspector] fragOffset ("Fragment offset", Float) = 0.0
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

				// Variables shared between the fragment shader and the OpenGL ES environment
				uniform vec3 iResolution;	// Shadertoy input
				uniform float iGlobalTime;	// Shadertoy input
				uniform vec4 iMouse;		// Shadertoy input
				uniform float fragOffset;	// To perform the anti-aliasing

// Shader from: https://www.shadertoy.com/view/ltX3Wr

// Quick & dirty, but...

#define EFFECT

float line (vec2 p, vec2 a, vec2 b) {
	p -= a;
	b -= a;
	a = p - b * dot (p, b) / dot (b , b);
	b *= 0.5;
	p = abs (p - b) - abs (b);
	return max (length (a), max (p.x, p.y));
}

float circle (vec2 p, vec2 o, float r) {
	return abs (length (p - o) - r);
}

void main (void) {
	vec2 frag = (2.0 * (gl_FragCoord.xy - fragOffset) - iResolution.xy) / iResolution.x;
	frag = 3.0 * frag + vec2 (2.6, 1.1);

	float d1 = max (circle (frag, vec2 (0.4, 0.5), 0.5), frag.x - 0.4);

	d1 = min (d1, line (frag, vec2 (0.8, 0.0), vec2 (0.8, 1.0)));
	d1 = min (d1, line (frag, vec2 (1.3, 0.0), vec2 (1.3, 1.0)));
	d1 = min (d1, line (frag, vec2 (0.8, 0.5), vec2 (1.3, 0.5)));

	d1 = min (d1, line (frag, vec2 (1.7, 0.0), vec2 (1.9, 1.0)));
	d1 = min (d1, line (frag, vec2 (2.3, 0.0), vec2 (2.1, 1.0)));
	d1 = min (d1, line (frag, vec2 (1.8, 0.2), vec2 (2.2, 0.2)));

	d1 = min (d1, max (circle (frag, vec2 (2.9, 0.7), 0.3), 2.8 - frag.x));
	d1 = min (d1, line (frag, vec2 (2.7, 0.0), vec2 (2.7, 1.0)));
	d1 = min (d1, line (frag, vec2 (2.9, 0.4), vec2 (3.2, 0.0)));

	d1 = min (d1, line (frag, vec2 (3.6, 0.0), vec2 (3.6, 1.0)));
	d1 = min (d1, line (frag, vec2 (3.6, 0.0), vec2 (4.0, 0.0)));

	d1 = min (d1, line (frag, vec2 (4.4, 0.0), vec2 (4.4, 1.0)));

	d1 = min (d1, line (frag, vec2 (4.8, 0.0), vec2 (4.8, 1.0)));
	d1 = min (d1, line (frag, vec2 (4.8, 0.0), vec2 (5.3, 0.0)));
	d1 = min (d1, line (frag, vec2 (4.8, 0.5), vec2 (5.3, 0.5)));
	d1 = min (d1, line (frag, vec2 (4.8, 1.0), vec2 (5.3, 1.0)));

	d1 -= 0.16;

	float d2 = max (circle (frag, vec2 (0.2, 1.7), 0.3), frag.y - 1.6);
	d2 = min (d2, line (frag, vec2 (0.5, 1.8), vec2 (0.5, 2.2)));

	d2 = min (d2, line (frag, vec2 (0.9, 1.4), vec2 (0.9, 2.2)));
	d2 = min (d2, line (frag, vec2 (0.9, 1.4), vec2 (1.4, 1.4)));
	d2 = min (d2, line (frag, vec2 (0.9, 1.8), vec2 (1.3, 1.8)));
	d2 = min (d2, line (frag, vec2 (0.9, 2.2), vec2 (1.4, 2.2)));

	d2 = min (d2, max (circle (frag, vec2 (4.9, 2.0), 0.2), frag.x - 4.8));
	d2 = min (d2, max (circle (frag, vec2 (5.1, 1.6), 0.2), 5.2 - frag.x));
	d2 = min (d2, line (frag, vec2 (5.0, 2.2), vec2 (5.15, 2.2)));
	d2 = min (d2, line (frag, vec2 (4.99, 1.8), vec2 (5.01, 1.8)));
	d2 = min (d2, line (frag, vec2 (4.75, 1.4), vec2 (5.0, 1.4)));

	d2 = min (d2, line (frag, vec2 (4.3, 1.4), vec2 (4.3, 2.2)));

	d2 = min (d2, line (frag, vec2 (3.9, 1.8), vec2 (3.9, 2.2)));
	d2 = min (d2, line (frag, vec2 (3.3, 1.8), vec2 (3.3, 2.2)));
	d2 = min (d2, max (circle (frag, vec2 (3.6, 1.7), 0.3), frag.y - 1.6));

	d2 = min (d2, max (circle (frag, vec2 (2.5, 2.0), 0.2), frag.x - 2.4));
	d2 = min (d2, max (circle (frag, vec2 (2.7, 1.6), 0.2), 2.8 - frag.x));
	d2 = min (d2, line (frag, vec2 (2.6, 2.2), vec2 (2.75, 2.2)));
	d2 = min (d2, line (frag, vec2 (2.59, 1.8), vec2 (2.61, 1.8)));
	d2 = min (d2, line (frag, vec2 (2.35, 1.4), vec2 (2.6, 1.4)));

	d2 -= 0.1;

	#ifdef EFFECT
	d1 += 0.03 * sin (10.0 * sin (iGlobalTime * 0.1) * (frag.x + frag.y));
	d2 *= 1.0 + 0.9 * sin ((iGlobalTime + frag.x + frag.y) * 20.0);
	#endif

	float tint = smoothstep (0.02, 0.0, min (d1, d2));
	if (d1 < d2) {
		tint *= 0.8;
	}
	gl_FragColor = vec4 (tint, tint, tint, 1.0);
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
