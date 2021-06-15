// Nicolas Robert [Nrx]
Shader "Custom/ColorNrx" {
	Properties {
		[HideInInspector] resolution ("Resolution", Vector) = (1.0, 1.0, 0.0, 0.0)
		[HideInInspector] time ("Time", Float) = 0.0
		[HideInInspector] video ("Video", 2D) = "white" {}
		[HideInInspector] videoResolution ("Video resolution", Vector) = (1.0, 1.0, 0.0, 0.0)
		[HideInInspector] videoRotation ("Video rotation", Vector) = (1.0, 0.0, 0.0, 1.0)
		[HideInInspector] videoDisplay ("Video display", Float) = 1.0
		[HideInInspector] videoError ("Video error", Float) = 0.0
		[HideInInspector] goal ("Goal", Float) = 0.0
		[HideInInspector] result ("Result", Float) = 0.0
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

			// Constants shared by the vertex shader and the fragment shader
			const float RING_RADIUS_MIN = 0.4;
			const float RING_RADIUS_MAX = 0.8;
			const float GOAL_RADIUS = 0.08;
			const float GOAL_THICKNESS = 0.01;
			const float RESULT_THICKNESS = 0.02;
			const float RESULT_SIZE = 0.1;
			const float RESULT_MOVEMENT = 0.02;
			const float OUTLINE = 0.02;
			const float BLUR = 0.02;
			const float PI = 3.14159265359;

			// Variables shared between the OpenGL ES environment and the vertex & fragment shaders
			uniform vec2 resolution;
			uniform float time;
			uniform sampler2D video;
			uniform vec2 videoResolution;
			uniform vec4 videoRotation;
			uniform float videoDisplay;
			uniform float videoError;
			uniform float goal;
			uniform float result;

			// Vertex shader: begin
			#ifdef VERTEX

				// Variables shared between the vertex shader and the fragment shader
				varying vec2 videoScale;
				varying float resultScale;
				varying vec2 resultPoint1;
				varying vec2 resultPoint2;
				varying vec2 resultPoint3;
				varying vec2 resultPoint4;
				varying vec2 resultOffset;

				// Main function
				void main () {

					// Video
					float screenRatio = resolution.x / resolution.y;
					float videoRatio = videoResolution.x / videoResolution.y;
					videoScale = vec2 (screenRatio, videoRatio) / max (screenRatio, videoRatio);
					videoScale *= min (resolution.x, resolution.y) / resolution;

					// Result
					resultScale = 1.0 - videoError;
					float offsetNear = RESULT_MOVEMENT * cos (time * 20.0) * resultScale;
					float offsetFar = offsetNear + RESULT_SIZE * resultScale;
					vec2 direction = vec2 (sin (result - goal), cos (result - goal));
					resultPoint1 = (RING_RADIUS_MIN - offsetNear) * direction;
					resultPoint2 = (RING_RADIUS_MIN - offsetFar) * direction;
					resultPoint3 = (RING_RADIUS_MAX + offsetNear) * direction;
					resultPoint4 = (RING_RADIUS_MAX + offsetFar) * direction;
					resultOffset = vec2 (direction.y, -direction.x) * 0.5 * RESULT_SIZE * resultScale;

					// Position
					gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
				}

			// Vertex shader: end
			#endif

			// Fragment shader: begin
			#ifdef FRAGMENT

				// Variables shared between the vertex shader and the fragment shader
				varying vec2 videoScale;
				varying float resultScale;
				varying vec2 resultPoint1;
				varying vec2 resultPoint2;
				varying vec2 resultPoint3;
				varying vec2 resultPoint4;
				varying vec2 resultOffset;

				// Segment
				float segDist (in vec2 p, in vec2 a, in vec2 b) {
					p -= a;
					b -= a;
					return length (p - b * clamp (dot (p, b) / dot (b, b), 0.0, 1.0));
				}

				// HSV to RGB
				vec3 hsv2rgb (in vec3 hsv) {
					return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.x + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
				}

				// Main function
				void main () {

					// Get the fragment position
					vec2 frag = (2.0 * gl_FragCoord.xy - resolution) / min (resolution.x, resolution.y);

					// Deformation
					float dist = length (frag);
					float ringOutside = step (RING_RADIUS_MAX, dist);
					vec2 fragDeformed = frag * (1.0 + ringOutside * 0.03 * cos (dist * 5.0 + time * 10.0));

					// Wave background
					vec3 color =  hsv2rgb (vec3 (goal / (2.0 * PI), 0.3 - 0.3 * frag.y, 0.8));
					color = mix (color, vec3 (1.0), smoothstep (0.5, 1.0, cos (frag.y * 20.0 + 5.0 * cos (frag.x + time))));

					// Video
					vec2 fragVideo = 0.5 + 0.5 * mat2 (videoRotation) * (videoScale * fragDeformed);
					color = mix (color, texture2D (video, fragVideo).rgb, videoDisplay);

					// Error
					color = mix (color, vec3 (0.3) * smoothstep (-0.5, 0.5, cos (30.0 * fragDeformed.x) * cos (30.0 * fragDeformed.y)), videoDisplay * videoError * ringOutside);

					// Ring
					dist = max (dist - RING_RADIUS_MAX, RING_RADIUS_MIN - dist);
					color = mix (color, vec3 (0.0), smoothstep (OUTLINE + BLUR, OUTLINE, dist));
					color = mix (color, hsv2rgb (vec3 ((goal + atan (frag.x, frag.y)) / (2.0 * PI), 0.8, 1.0)), smoothstep (BLUR, 0.0, dist));

					// Result
					float halfThickness = RESULT_THICKNESS * 0.5 * resultScale;
					dist = segDist (frag, resultPoint1, resultPoint2 - resultOffset);
					dist = min (dist, segDist (frag, resultPoint1, resultPoint2 + resultOffset));
					dist = min (dist, segDist (frag, resultPoint3, resultPoint4 - resultOffset));
					dist = min (dist, segDist (frag, resultPoint3, resultPoint4 + resultOffset));
					color = mix (color, vec3 (0.0), videoDisplay * resultScale * smoothstep (halfThickness + OUTLINE + BLUR, halfThickness + OUTLINE, dist));
					color = mix (color, vec3 (resultScale), videoDisplay * resultScale * smoothstep (halfThickness + BLUR, halfThickness, dist));

					// Goal
					dist = abs (segDist (frag, vec2 (0.0, RING_RADIUS_MIN), vec2 (0.0, RING_RADIUS_MAX)) - GOAL_RADIUS);
					color = mix (color, vec3 (0.0), smoothstep (GOAL_THICKNESS * 0.5 + OUTLINE + BLUR, GOAL_THICKNESS * 0.5 + OUTLINE, dist));
					color = mix (color, hsv2rgb (vec3 (goal / (2.0 * PI), 0.8, 1.0)), smoothstep (GOAL_THICKNESS * 0.5 + BLUR, GOAL_THICKNESS * 0.5, dist));

					// Set the fragment color
					gl_FragColor = vec4 (color, 1.0);
				}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
