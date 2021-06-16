// Nicolas Robert [Nrx]
Shader "Custom/Tile"
{
	Properties
	{
		tileSize ("Tile Size", Float) = 8.0
		tileMap ("Tile Map", 2D) = "white" {}
		tileMapWidth ("Tile Map Width", Float) = 32.0
		tileMapHeight ("Tile Map Height", Float) = 32.0
		tileSet ("Tile Set", 2D) = "white" {}
		tileSetSize ("Tile Set Size", Float) = 128.0
	}
	SubShader
	{
		Pass
		{
			ZWrite Off
			ZTest Always
			Blend SrcAlpha OneMinusSrcAlpha

			GLSLPROGRAM

			// Define multiple shader program variants:
			// - BASIC (default): doesn't do any special check on the tile map, so it basically respect the texture's wrap mode
			// - REPEAT: repeats the tile map (useful when it is a NPOT texture, for which repeat isn't supported on some devices)
			// - CUT: doesn't display anything outside of the tile map (this is different from clamping, which repeats the border tiles)
			#pragma multi_compile BASIC REPEAT CUT

			// Vertex shader
			#ifdef VERTEX
			void main (void)
			{
				gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
			}
			#endif

			// Fragment shader
			#ifdef FRAGMENT
			#ifdef GL_ES
			precision highp float;
			#endif

			uniform float tileSize;
			uniform sampler2D tileMap;
			uniform float tileMapWidth;
			uniform float tileMapHeight;
			uniform sampler2D tileSet;
			uniform float tileSetSize;

			uniform vec4 transform;
			uniform vec2 translate;

			void main (void)
			{
				// Get the fragment's coordinates
				vec2 frag = gl_FragCoord.xy;
				frag = (mat2 (transform) * frag + translate) / tileSize;
				#ifdef CUT
				if (frag.x < 0.0 || frag.x >= tileMapWidth || frag.y < 0.0 || frag.y >= tileMapHeight)
				{
					discard;
				}
				#endif

				// Get the offset (tile number)
				vec2 uv = (floor (frag) + 0.5) / vec2 (tileMapWidth, tileMapHeight);
				#ifdef REPEAT
				uv = fract (uv);
				#endif
				float tileScale = tileSetSize / tileSize;
				float tile = texture2D (tileMap, uv).a * tileScale;
				vec2 offset = floor (vec2 (fract (tile) * tileScale, tile));

				// Get the final fragment color
				uv = (floor ((fract (frag) + offset) * tileSize) + 0.5) / tileSetSize;
				gl_FragColor = texture2D (tileSet, uv);
			}
			#endif

			ENDGLSL
		}
	}
}
