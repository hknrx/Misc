// Nicolas Robert [Nrx]
Shader "Custom/City" {
	Properties {
		[HideInInspector] resolution ("Resolution", Vector) = (1.0, 1.0, 0.0, 0.0)
		[HideInInspector] fragOffset ("Fragment offset", Float) = 0.0
		FOV ("FOV", Float) = 96.0
		IPD ("IPD", Float) = 0.0005
		[HideInInspector] VR ("VR", Float) = 1.0
		headModel ("Head model", Vector) = (0.0, 0.001, 0.0005, 0.0)
		[HideInInspector] headOrientation0 ("Head orientation (0)", Vector) = (1.0, 0.0, 0.0, 0.0)
		[HideInInspector] headOrientation1 ("Head orientation (1)", Vector) = (0.0, 1.0, 0.0, 0.0)
		[HideInInspector] headOrientation2 ("Head orientation (2)", Vector) = (0.0, 0.0, 1.0, 0.0)
		[HideInInspector] headPosition ("Head position", Vector) = (0.0, 0.0, 0.0, 0.0)
		[HideInInspector] time ("Time", Float) = 0.0
	}
	SubShader {
		Pass {
			ZWrite Off
			ZTest Always

			GLSLPROGRAM

			// Define multiple shader program variants:
			// - (default): low quality (better performances, higher frame rate)
			// - QUALITY_HIGH: high quality (lower performances)
			#pragma multi_compile __ QUALITY_HIGH

			// Precision setting (shared between the vertex shader and the fragment shader)
			#ifdef GL_ES
			precision highp float;
			#endif

			// Vertex shader: begin
			#ifdef VERTEX

				// Variables shared between the vertex shader and the OpenGL ES environment
				uniform vec3 headOrientation0;
				uniform vec3 headOrientation1;
				uniform vec3 headOrientation2;

				// Variables shared between the vertex shader and the fragment shader
				varying mat3 headRotate;

				// Main function
				void main () {

					// Define the head's rotation matrix
					headRotate = mat3 (headOrientation0, headOrientation1, headOrientation2);

					// Set the position
					gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
				}

			// Vertex shader: end
			#endif

			// Fragment shader: begin
			#ifdef FRAGMENT

				// Variables shared between the fragment shader and the OpenGL ES environment
				uniform vec3 resolution;
				uniform float fragOffset;
				uniform float FOV;
				uniform float IPD;
				uniform float VR;
				uniform vec3 headModel;
				uniform vec3 headPosition;
				uniform float time;

				// Variables shared between the vertex shader and the fragment shader
				varying mat3 headRotate;

// Shader from: https://www.shadertoy.com/view/Xt2GRm

// Rendering parameters (optional)
#define HOLES
#ifdef QUALITY_HIGH
	#define HOLLOW_THICKNESS	0.01
	#define SHADOW_LENGTH		20.0
	#define SHADOW_FACTOR		250.0
#endif
#define HSV2RGB_FAST

// Rendering parameters (mandatory)
#define RAY_LENGTH_MAX		15.0
#define RAY_STEP_MAX		120.0
#define AMBIENT				0.05
#define SPECULAR_POWER		2.0
#define SPECULAR_INTENSITY	0.3
#define FADE_POWER			2.0
#define GAMMA				0.8

// Math constants
#define DELTA	0.001
#define PI		3.14159265359

// PRNG
float rand (in vec2 seed) {
	return fract (sin (dot (seed, vec2 (12.9898, 78.233))) * 137.5453);
}

// Identifier (color) of the ground
float idGround (in vec2 p) {
	p = fract (p * 25.0) - 0.5;
	return p.x * p.y * 0.2 + 0.5;
}

// Distance to the building
float distBuilding (in vec3 p, out float id) {

	// Take note of the ground coordinates
	vec2 ground = p.xz;

	// Change coordinates to cell space, and get the id of this building
	p.xz += 0.5;
	id = rand (floor (p.xz));
	if (fract (id * 31.0) > 0.7) {

		// Ground (empty cell)
		id = idGround (ground);
		return p.y;
	}
	p.xz = fract (p.xz) - 0.5;

	// Rotation
	float angle = id * PI * 0.5;
	float c = cos (angle);
	float s = sin (angle);
	p.xz = vec2 (c * p.x + s * p.z, c * p.z - s * p.x);

	// Translation
	angle = id * PI * 5.0;
	p.xz += 0.07 * vec2 (cos (angle), sin (angle));

	// Rounded box
	float boxHalfSize = 0.25 + 0.1 * cos (id * PI * 7.0);
	float boxHeight = 2.5 + id * 5.5;
	float boxRadius = boxHalfSize * (0.5 + 0.5 * cos (id * PI * 11.0));
	vec3 o = abs (p) - vec3 (boxHalfSize, boxHeight, boxHalfSize) + boxRadius;
	float dist = length (max (o, 0.0)) - boxRadius;

	// Carve this rounded box using other (signed) rounded boxes
	#ifdef HOLES
	#ifdef HOLLOW_THICKNESS
	const float thickness = HOLLOW_THICKNESS;
	boxHalfSize -= thickness;
	boxHeight -= thickness;
	boxRadius = max (0.0, boxRadius - thickness);
	o = abs (p) - vec3 (boxHalfSize, boxHeight, boxHalfSize) + boxRadius;
	dist = max (dist, boxRadius - min (max (o.x, max (o.y, o.z)), 0.0) - length (max (o, 0.0)));
	boxHalfSize += thickness;
	#endif

	float boxPeriod = boxHalfSize * 0.3 * (0.8 + 0.2 * cos (id * PI * 13.0));
	boxHalfSize = boxPeriod * 0.45 * (0.9 + 0.1 * cos (id * PI * 17.0));
	boxRadius = boxHalfSize * (0.5 + 0.5 * cos (id * PI * 19.0));
	o = abs (mod (p, boxPeriod) - 0.5 * boxPeriod) - boxHalfSize + boxRadius;
	dist = max (dist, boxRadius - min (max (o.x, max (o.y, o.z)), 0.0) - length (max (o, 0.0)));
	#endif

	// Ground
	if (dist > p.y) {
		dist = p.y;
		id = idGround (ground);
	}
	return dist;
}

// Cast a ray
vec3 hit (in vec3 rayOrigin, in vec3 rayDirection, in float rayLengthMax, out float rayLength, out float rayStepCount, out float shadow) {

	// Initialize the returned values
	vec3 hitPosition = rayOrigin;
	rayLength = 0.0;
	rayStepCount = 0.0;
	shadow = 1.0;

	// Initialize the tracking of the grid cells
	vec2 raySign = sign (rayDirection.xz);
	vec2 rayDeltaCell;
	rayDeltaCell.x = rayDirection.x != 0.0 ? raySign.x / rayDirection.x : RAY_STEP_MAX;
	rayDeltaCell.y = rayDirection.z != 0.0 ? raySign.y / rayDirection.z : RAY_STEP_MAX;
	vec2 rayDelta = (0.5 - raySign * (fract (rayOrigin.xz + 0.5) - 0.5)) * rayDeltaCell;
	float distMax = min (rayDelta.x, rayDelta.y);

	// Launch the ray
	for (float rayStep = 0.0; rayStep < RAY_STEP_MAX; ++rayStep) {

		// Get the distance to the building in this grid cell
		float id;
		float dist = distBuilding (hitPosition, id);
		if (dist < DELTA) {
			shadow = 0.0;
			break;
		}

		// Soft shadow
		#ifdef SHADOW_FACTOR
		shadow = min (shadow, SHADOW_FACTOR * dist / rayLength);
		#endif

		// Make sure we haven't reached the next grid cell
		if (dist > distMax - rayLength) {
			dist = distMax - rayLength + DELTA;
			rayDelta += step (rayDelta.xy, rayDelta.yx) * rayDeltaCell;
			distMax = min (rayDelta.x, rayDelta.y);
		}

		// March...
		rayLength += dist;
		if (rayLength > rayLengthMax) {
			break;
		}
		hitPosition += dist * rayDirection;
		++rayStepCount;
	}

	// Return the hit point
	return hitPosition;
}

// Normal at a given point
vec3 normal (in vec3 p, out float id) {
	const vec2 h = vec2 (DELTA, -DELTA);
	return normalize (
        h.xxx * distBuilding (p + h.xxx, id) +
		h.xyy * distBuilding (p + h.xyy, id) +
		h.yxy * distBuilding (p + h.yxy, id) +
		h.yyx * distBuilding (p + h.yyx, id)
	);
}

// HSV to RGB
vec3 hsv2rgb (in vec3 hsv) {
	#ifdef HSV2RGB_SAFE
	hsv.yz = clamp (hsv.yz, 0.0, 1.0);
	#endif
	#ifdef HSV2RGB_FAST
	return hsv.z * (1.0 + 0.5 * hsv.y * (cos (2.0 * PI * (hsv.x + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0))) - 1.0));
	#else
	return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.x + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
	#endif
}

// Main function
void main () {

	// Change the position of the head
	vec3 headPositionModified = headPosition + vec3 (10.0 * cos (time * 0.1), 0.2 + 7.8 * smoothstep (0.5, -0.5, cos (time * 0.2)), 0.5);

	// Define the ray corresponding to this fragment
	vec2 fragCoord = gl_FragCoord.xy - fragOffset;
	float rayStereo = 0.5 * sign (fragCoord.x - resolution.x * 0.5) * step (0.5, VR);
	vec3 rayOrigin = headPositionModified + headRotate * (headModel + vec3 (rayStereo * IPD, 0.0, 0.0));
	vec3 rayDirection = headRotate * normalize (vec3 ((2.0 * fragCoord.x - (1.0 + rayStereo) * resolution.x), 2.0 * fragCoord.y - resolution.y, 0.5 * resolution.x / tan (FOV * PI / 360.0)));

	// Cast a ray
	float hitDistance;
	float hitStepCount;
	float hitShadow;
	vec3 hitPosition = hit (rayOrigin, rayDirection, RAY_LENGTH_MAX, hitDistance, hitStepCount, hitShadow);

	// Get the normal and ID
	float hitId;
	vec3 hitNormal = normal (hitPosition, hitId);

	// Lighting
	float lightYawAngle = PI * 0.1;
	float lightPitchAngle = time * 0.1;
	vec3 lightDirection = vec3 (sin (lightYawAngle) * sin (lightPitchAngle), cos (lightPitchAngle), cos (lightYawAngle) * sin (lightPitchAngle));

	float diffuse = 0.0;
	float specular = 0.0;
	if (lightDirection.y > 0.0) {
		diffuse = max (0.0, dot (hitNormal, lightDirection));
		specular = pow (max (0.0, dot (reflect (rayDirection, hitNormal), lightDirection)), SPECULAR_POWER) * SPECULAR_INTENSITY;
		#ifdef SHADOW_LENGTH
		float shadowDistance;
		float shadowStepCount;
		float shadow;
		hit (hitPosition + hitNormal * DELTA * 2.0, lightDirection, SHADOW_LENGTH, shadowDistance, shadowStepCount, shadow);
		diffuse *= shadow;
		specular *= shadow;
		#endif
	}

	// Set the object color
	vec3 color = hsv2rgb (vec3 (hitId, 0.8, 0.4));
	color = (AMBIENT + diffuse) * color + specular;

	// Set the sky color
	diffuse = max (0.0, dot (rayDirection, lightDirection));
	float skyBelow = min (1.0, 1.0 + lightDirection.y);
	vec3 skyColor = mix (vec3 (1.0, 0.4, 0.2), vec3 (0.6, 0.4, 1.0), max (0.0, lightDirection.y));
	skyColor += vec3 (1.0, 0.9, 0.6) * pow (diffuse, 6.0);
	skyColor = mix (vec3 (0.0, 0.0, 0.1), skyColor, skyBelow);
	skyColor *= 0.3 + 0.7 * diffuse;

	// Blend the object and sky colors
	color = mix (skyColor, color, pow (max (0.0, 1.0 - hitDistance / RAY_LENGTH_MAX), FADE_POWER));

	// Adjust the gamma
	color = pow (color, vec3 (GAMMA));

	// Add a glow effect
	color += (hitStepCount / RAY_STEP_MAX) * (1.0 - hitShadow) * mix (vec3 (0.4, 0.6, 1.0) * smoothstep (6.0, 0.0, hitPosition.y), vec3 (0.3, 0.3, 0.3), skyBelow);

	// Set the fragment color
	gl_FragColor = vec4 (color, 1.0);
}

			// Fragment shader: end
			#endif

			ENDGLSL
		}
	}
}
