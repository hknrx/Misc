// Nicolas Robert [Nrx]

using UnityEngine;

// Template interface
public interface Template
{
	void Setup (Demo instance);
	void Update (Demo instance, float time);
}

// Template: empty environment
public class TemplateEmpty : Template
{
	public void Setup (Demo instance)
	{
		Liquid.SourceCreate (0, new Vector2 (instance.physicsParameters.gridWidth * 0.5f, instance.physicsParameters.gridHeight * 0.5f));
	}

	public void Update (Demo instance, float time)
	{
		Liquid.SourceUpdate (0, 100.0f, time);
	}
}

// Template: simple container
public class TemplateSimpleContainer : Template
{
	public void Setup (Demo instance)
	{
		float width = instance.physicsParameters.gridWidth;
		float height = instance.physicsParameters.gridHeight;

		instance.ColliderPathStart (new Vector2 (1.5f, 1.5f));
		instance.ColliderPathContinue (new Vector2 (width - 1.5f, 1.5f));
		instance.ColliderPathContinue (new Vector2 (width - 1.5f, height - 1.5f));
		instance.ColliderPathContinue (new Vector2 (1.5f, height - 1.5f));
		instance.ColliderPathContinue (new Vector2 (1.5f, 1.5f));
		instance.ParticleBlockCreate (new Vector2 (2.5f, 2.5f), new Vector2 (width - 2.5f, height - 2.5f));

		Liquid.SourceCreate (0, new Vector2 (width * 0.5f, height * 0.5f));
	}

	public void Update (Demo instance, float time)
	{
		Liquid.SourceUpdate (0, 100.0f, time);
	}
}

// Template: fountain
public class TemplateFountain : Template
{
	public void Setup (Demo instance)
	{
		float halfWidth = 0.5f * instance.physicsParameters.gridWidth;
		float size = 0.2f * instance.physicsParameters.gridHeight;
		float halfSize = 0.5f * size;

		instance.ColliderPathStart (new Vector2 (halfWidth - 1.5f, 1.5f + size * 1.3f));
		instance.ColliderPathContinue (new Vector2 (halfWidth - 1.5f, 1.5f + size));
		instance.ColliderPathContinue (new Vector2 (halfWidth - halfSize, 1.5f + size));
		instance.ColliderPathContinue (new Vector2 (halfWidth - halfSize, 1.5f));
		instance.ColliderPathContinue (new Vector2 (halfWidth + halfSize, 1.5f));
		instance.ColliderPathContinue (new Vector2 (halfWidth + halfSize, 1.5f + size));
		instance.ColliderPathContinue (new Vector2 (halfWidth + 1.5f, 1.5f + size));
		instance.ColliderPathContinue (new Vector2 (halfWidth + 1.5f, 1.5f + size * 1.3f));

		Liquid.SourceCreate (0, new Vector2 (halfWidth - halfSize + 2.0f, 1.5f + size - 2.0f), 120.0f, Mathf.PI * 1.5f);
		Liquid.SourceCreate (1, new Vector2 (halfWidth + halfSize - 2.0f, 1.5f + size - 2.0f), 120.0f, Mathf.PI * 1.5f);
	}

	public void Update (Demo instance, float time)
	{
	}
}

// Template: sandglass
public class TemplateSandglass : Template
{
	public void Setup (Demo instance)
	{
		float width = instance.physicsParameters.gridWidth;
		float height = instance.physicsParameters.gridHeight;

		float slope = Mathf.Floor (Mathf.Min (height * 0.3f - 3.0f, width * 0.45f - 3.5f));
		instance.ColliderPathStart (new Vector2 (1.5f, height * 0.2f));
		instance.ColliderPathContinue (new Vector2 (1.5f, height * 0.8f));
		instance.ColliderPathContinue (new Vector2 (width * 0.45f - slope, height * 0.8f));
		instance.ColliderPathContinue (new Vector2 (width * 0.45f, height * 0.8f - slope));
		instance.ColliderPathContinue (new Vector2 (width * 0.55f, height * 0.8f - slope));
		instance.ColliderPathContinue (new Vector2 (width * 0.55f + slope, height * 0.8f));
		instance.ColliderPathContinue (new Vector2 (width - 1.5f, height * 0.8f));
		instance.ColliderPathContinue (new Vector2 (width - 1.5f, height * 0.2f));
		instance.ColliderPathContinue (new Vector2 (width * 0.55f + slope, height * 0.2f));
		instance.ColliderPathContinue (new Vector2 (width * 0.55f, height * 0.2f + slope));
		instance.ColliderPathContinue (new Vector2 (width * 0.45f, height * 0.2f + slope));
		instance.ColliderPathContinue (new Vector2 (width * 0.45f - slope, height * 0.2f));
		instance.ColliderPathContinue (new Vector2 (1.5f, height * 0.2f));
		instance.ParticleBlockCreate (new Vector2 (2.5f, height * 0.2f + 1.0f), new Vector2 (width * 0.45f - slope, height * 0.8f - 1.0f));
		instance.ParticleBlockCreate (new Vector2 (width * 0.55f + slope, height * 0.2f + 1.0f), new Vector2 (width - 2.5f, height * 0.8f - 1.0f));

		Liquid.SourceCreate (0, new Vector2 (width * 0.3f, height * 0.5f));
	}

	public void Update (Demo instance, float time)
	{
		Liquid.SourceUpdate (0, 100.0f, time);
	}
}

// Template: communicating vessels
public class TemplateCommunicatingVessels : Template
{
	public void Setup (Demo instance)
	{
		float width = instance.physicsParameters.gridWidth;
		float height = instance.physicsParameters.gridHeight;

		instance.ColliderPathStart (new Vector2 (1.5f, height * 0.8f));
		instance.ColliderPathContinue (new Vector2 (1.5f, height * 0.2f));
		instance.ColliderPathContinue (new Vector2 (width - 1.5f, height * 0.2f));
		instance.ColliderPathContinue (new Vector2 (width - 1.5f, height * 0.8f));
		instance.ColliderPathContinue (new Vector2 (width * 0.6f, height * 0.8f));
		instance.ColliderPathContinue (new Vector2 (width * 0.6f, height * 0.3f));
		instance.ColliderPathContinue (new Vector2 (width * 0.4f, height * 0.3f));
		instance.ColliderPathContinue (new Vector2 (width * 0.4f, height * 0.8f));
		instance.ColliderPathContinue (new Vector2 (1.5f, height * 0.8f));
		instance.ParticleBlockCreate (new Vector2 (2.5f, height * 0.2f + 1.0f), new Vector2 (width * 0.4f - 1.0f, height * 0.8f - 1.0f));
		instance.ParticleBlockCreate (new Vector2 (width * 0.6f + 1.0f, height * 0.2f + 1.0f), new Vector2 (width - 2.5f, height * 0.8f - 1.0f));

		Liquid.SourceCreate (0, new Vector2 (width * 0.2f, height * 0.5f));
		Liquid.SourceCreate (1, new Vector2 (width * 0.8f, height * 0.5f));
	}

	public void Update (Demo instance, float time)
	{
		Liquid.SourceUpdate (0, 100.0f, time);
		Liquid.SourceUpdate (1, 100.0f, -time);
	}
}

// Template: rain
public class TemplateRain : Template
{
	public void Setup (Demo instance)
	{
		float width = instance.physicsParameters.gridWidth;
		float height = instance.physicsParameters.gridHeight;

		instance.ColliderPathStart (new Vector2 (1.5f, height * 0.4f));
		instance.ColliderPathContinue (new Vector2 (1.5f, height - 1.5f));
		instance.ColliderPathContinue (new Vector2 (width - 1.5f, height - 1.5f));
		instance.ColliderPathContinue (new Vector2 (width - 1.5f, height * 0.4f));
		for (float x = 2.5f; x <= width - 2.5f; x += 2.0f) {
			Liquid.ColliderSet (new Vector2 (x, height * 0.5f), true);
		}
		instance.ParticleBlockCreate (new Vector2 (2.5f, height * 0.5f + 1.0f), new Vector2 (width - 2.5f, height - 2.5f));

		Liquid.SourceCreate (0, new Vector2 (5.5f, height - 5.5f), 80.0f, 0.0f);
		Liquid.SourceCreate (1, new Vector2 (width - 5.5f, height - 5.5f), 80.0f, Mathf.PI);
	}

	public void Update (Demo instance, float time)
	{
	}
}

// Template: pressure cooker
public class TemplatePressureCooker : Template
{
	public void Setup (Demo instance)
	{
		float halfWidth = 0.5f * instance.physicsParameters.gridWidth;
		float halfHeight = 0.5f * instance.physicsParameters.gridHeight;

		instance.ColliderPathStart (new Vector2 (halfWidth - 3.0f, halfHeight - 3.0f));
		instance.ColliderPathContinue (new Vector2 (halfWidth + 3.0f, halfHeight - 3.0f));
		instance.ColliderPathContinue (new Vector2 (halfWidth + 3.0f, halfHeight + 3.0f));
		instance.ColliderPathContinue (new Vector2 (halfWidth - 3.0f, halfHeight + 3.0f));
		instance.ColliderPathContinue (new Vector2 (halfWidth - 3.0f, halfHeight - 3.0f));

		Liquid.SourceCreate (0, new Vector2 (halfWidth, halfHeight));
	}

	public void Update (Demo instance, float time)
	{
		Liquid.SourceUpdate (0, 100.0f, time);
	}
}

// Template: water flow
public class TemplateWaterFlow : Template
{
	public void Setup (Demo instance)
	{
		float halfWidth = 0.5f * instance.physicsParameters.gridWidth;
		float halfHeight = 0.5f * instance.physicsParameters.gridHeight;
		Vector2 center = new Vector2 (halfWidth, halfHeight);

		float angle = Mathf.PI * 2.0f;
		float dAngle = angle / 8.0f;
		float radius = Mathf.Min (halfWidth, halfHeight) - 1.5f;
		Vector2 A = new Vector2 (Mathf.Cos (dAngle), Mathf.Sin (dAngle));
		Vector2 B = new Vector2 (1.0f, 0.0f);
		while (angle > 0.5f * dAngle) {
			angle -= dAngle;
			Vector2 C = new Vector2 (Mathf.Cos (angle), Mathf.Sin (angle));
			instance.ColliderPathStart (center + radius * A);
			instance.ColliderPathContinue (center + radius * B);
			instance.ColliderPathContinue (center + radius * (B + 0.15f * new Vector2 (C.y - A.y, A.x - C.x)));
			A = B;
			B = C;
			C = 0.5f * (A + B);
			instance.ColliderPathStart (center + radius * 0.4f * A);
			instance.ColliderPathContinue (center + radius * 0.4f * B);
			instance.ColliderPathStart (center + radius * 0.4f * C);
			instance.ColliderPathContinue (center + radius * 0.6f * C);
		}

		Liquid.SourceCreate (0, new Vector2 (halfWidth, halfHeight - radius * 0.6f), 100.0f, Mathf.PI * 0.5f);
	}

	public void Update (Demo instance, float time)
	{
	}
}

// Template: pachinko
public class TemplatePachinko : Template
{
	public void Setup (Demo instance)
	{
		float width = instance.physicsParameters.gridWidth;
		float height = instance.physicsParameters.gridHeight;

		instance.ColliderPathStart (new Vector2 (1.5f, 1.5f));
		instance.ColliderPathContinue (new Vector2 (width - 1.5f, 1.5f));
		instance.ColliderPathContinue (new Vector2 (width - 1.5f, height - 1.5f));
		instance.ColliderPathContinue (new Vector2 (1.5f, height - 1.5f));
		instance.ColliderPathContinue (new Vector2 (1.5f, 1.5f));

		float delta = instance.physicsParameters.particleRadius * 8.0f;
		float dx = 2.0f * width / Mathf.Floor (width / (delta * 1.732f));
		float dy = height / Mathf.Floor (height / delta);
		float left = dx * 0.5f;
		float right = width - left * 0.99f;
		float bottom = dy;
		float top = height - dy * 0.99f;
		delta = 0.0f;
		for (float y = bottom; y <= top; y += dy) {
			for (float x = left + delta; x <= right; x += dx) {
				Liquid.ColliderSet (new Vector2 (x, y), true);
			}
			delta = delta > 0.0f ? 0.0f : dx * 0.5f;
		}

		instance.ParticleBlockCreate (new Vector2 (2.5f, 2.5f), new Vector2 (width - 2.5f, height - 2.5f));

		Liquid.SourceCreate (0, new Vector2 (5.5f, 5.5f), 80.0f, Mathf.PI * 0.5f);
		Liquid.SourceCreate (1, new Vector2 (5.5f, height - 5.5f), 80.0f, Mathf.PI * 1.5f);
	}

	public void Update (Demo instance, float time)
	{
	}
}

// Template: circle
public class TemplateCircle : Template
{
	public void Setup (Demo instance)
	{
		Vector2 center = 0.5f * new Vector2 (instance.physicsParameters.gridWidth, instance.physicsParameters.gridHeight);
		int x = (int)(Mathf.Min (center.x, center.y) - 1.5f);
		int y = 0;
		int error = 1 - x;
		while (y <= x) {
			Liquid.ColliderSet (center + new Vector2 (x, y), true);
			Liquid.ColliderSet (center + new Vector2 (-x, y), true);
			Liquid.ColliderSet (center + new Vector2 (x, -y), true);
			Liquid.ColliderSet (center + new Vector2 (-x, -y), true);
			Liquid.ColliderSet (center + new Vector2 (y, x), true);
			Liquid.ColliderSet (center + new Vector2 (-y, x), true);
			Liquid.ColliderSet (center + new Vector2 (y, -x), true);
			Liquid.ColliderSet (center + new Vector2 (-y, -x), true);
			if (error > 0) {
				error -= --x << 1;
			}
			error += (++y << 1) + 1;
		}

		Liquid.SourceCreate (0, center, 100.0f, Mathf.PI * 0.5f);
	}

	public void Update (Demo instance, float time)
	{
	}
}
