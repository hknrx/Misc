/*
 * Libraries.
 */
#include "math.h"

/*
 * Global variables.
 */
/**
 * Look up table for sine (whole circle, i.e. from 0 to 2*PI).
 */
const signed short mathSineTable[SIN_COUNT] =
{
	0, 6, 13, 19, 25, 31, 38, 44, 50, 56, 62, 68, 74, 80, 86, 92,
	98, 104, 109, 115, 121, 126, 132, 137, 142, 147, 152, 157, 162, 167, 172, 177,
	181, 185, 190, 194, 198, 202, 206, 209, 213, 216, 220, 223, 226, 229, 231, 234,
	237, 239, 241, 243, 245, 247, 248, 250, 251, 252, 253, 254, 255, 255, 256, 256,
	256, 256, 256, 255, 255, 254, 253, 252, 251, 250, 248, 247, 245, 243, 241, 239,
	237, 234, 231, 229, 226, 223, 220, 216, 213, 209, 206, 202, 198, 194, 190, 185,
	181, 177, 172, 167, 162, 157, 152, 147, 142, 137, 132, 126, 121, 115, 109, 104,
	98, 92, 86, 80, 74, 68, 62, 56, 50, 44, 38, 31, 25, 19, 13, 6,
	0, -6, -13, -19, -25, -31, -38, -44, -50, -56, -62, -68, -74, -80, -86, -92,
	-98, -104, -109, -115, -121, -126, -132, -137, -142, -147, -152, -157, -162, -167, -172, -177,
	-181, -185, -190, -194, -198, -202, -206, -209, -213, -216, -220, -223, -226, -229, -231, -234,
	-237, -239, -241, -243, -245, -247, -248, -250, -251, -252, -253, -254, -255, -255, -256, -256,
	-256, -256, -256, -255, -255, -254, -253, -252, -251, -250, -248, -247, -245, -243, -241, -239,
	-237, -234, -231, -229, -226, -223, -220, -216, -213, -209, -206, -202, -198, -194, -190, -185,
	-181, -177, -172, -167, -162, -157, -152, -147, -142, -137, -132, -126, -121, -115, -109, -104,
	-98, -92, -86, -80, -74, -68, -62, -56, -50, -44, -38, -31, -25, -19, -13, -6,
};

/**
 * Seed of the pseudo random number generator.
 */
unsigned long long mathRandomSeed;

/*
 * Functions.
 */
/**
 * Set the seed of the pseudo random number generator.
 *
 * @param seed Seed.
 */
void MathRandSeed(const unsigned long long seed)
{
	mathRandomSeed = seed;
}

/**
 * Return a pseudo random value.
 *
 * @see <a href="http://java.sun.com/javase/6/docs/api/java/util/Random.html">J2SE "Random" implementation</a>
 * @param limit The bound on the random number to be returned.
 * @return A pseudo random, uniformly distributed integer between 0 (inclusive) and limit (exclusive).
 */
unsigned long MathRand(const unsigned long limit)
{
	mathRandomSeed = (mathRandomSeed * 0x5DEECE66DLL + 0xBLL) & ((1LL << 48) - 1);
	return((unsigned long)(mathRandomSeed >> (48 - 31)) % limit);
}

/**
 * Compute the square root of a number.
 *
 * @param x Number from which the square root shall be extracted.
 * @return Square root of the number.
 */
signed long MathSqrt(signed long x)
{
	signed long n = 0;
	for(signed long m = x; m > 3; m >>= 2, ++n);

	signed long q = 0;
	while(n >= 0)
	{
		signed long d = (q | (1 << n)) << n;
		if(x >= d)
		{
			x -= d;
			q |= 2 << n;
		}
		--n;
	}
	return(q >> 1);
}

/**
 * Compute the norm of a 2D vector using the square root function.
 *
 * @param dx X coordinate of the vector.
 * @param dy Y coordinate of the vector.
 * @return Norm of the vector.
 */
signed long MathNorm(const signed long dx, const signed long dy)
{
	return(MathSqrt(dx * dx + dy * dy));
}

/**
 * Compute the norm of a 2D vector using a special approximation (Coquin-Bolon's chamfer distance).
 *
 * @param dx X coordinate of the vector.
 * @param dy Y coordinate of the vector.
 * @return Norm of the vector.
 */
signed long MathNormFast(signed long dx, signed long dy)
{
	// Adapted from Coquin-Bolon's chamfer distance (d10=0.9604, d11=1.3583):
	// D=(max(|dx|,|dy|)*123+min(|dx|,|dy|)*51)/128
	if(dx < 0)
	{
		dx = -dx;
	}
	if(dy < 0)
	{
		dy = -dy;
	}

	if(dx > dy)
	{
		return((dx * 123 + dy * 51) >> 7);
	}
	return((dy * 123 + dx * 51) >> 7);
}

/**
 * Compute the arcsin of a value (using dichotomy).
 *
 * @param x Input value (shall be a fixed point).
 * @return Corresponding angle.
 */
unsigned char MathArcSin(signed long x)
{
	unsigned char negative;
	unsigned char min = 0;
	unsigned char arcSin = PI >> 2;
	unsigned char max = PI >> 1;

	if(x > 0)
	{
		negative = 0;
	}
	else
	{
		x = -x;
		negative = 1;
	}

	do
	{
		if(mathSineTable[arcSin] >= x)
		{
			max = arcSin;
		}
		else
		{
			min = arcSin;
		}
		arcSin = (min + max) >> 1;
	}
	while(arcSin != min);

	if(negative)
	{
		return((PI << 1) - arcSin);
	}
	return(arcSin);
}

/**
 * Compute the angle corresponding to a 2D vector.
 *
 * @param x X coordinate of the vector.
 * @param y Y coordinate of the vector.
 * @return Angle of the vector.
 */
unsigned char MathAngle(const signed long x, const signed long y)
{
	const signed long norm = MathNorm(x, y);
	if(!norm)
	{
		return(0);
	}
	const unsigned char angle = MathArcSin(((y << 9) / norm + 1) >> 1);
	if(x >= 0)
	{
		return(angle);
	}
	return(PI - angle);
}

/**
 * Compute the angle corresponding to a 2D vector.
 *
 * @see <a href="http://www.dspguru.com/comp.dsp/tricks/alg/fxdatan2.htm">Fixed-Point Atan2 With Self Normalization</a>
 * @param x X coordinate of the vector.
 * @param y Y coordinate of the vector.
 * @return Angle of the vector.
 */
unsigned char MathAngleFast(const signed long x, const signed long y)
{
	signed long angle;
	signed long numerator;
	signed long denominator;
	if(y > 0 ^ x > 0)
	{
		if(y > 0)
		{
			angle = (3 * PI) >> 2;
		}
		else
		{
			angle = (7 * PI) >> 2;
		}
		numerator = x + y;
		denominator = x - y;
	}
	else
	{
		if(y > 0)
		{
			angle = (1 * PI) >> 2;
		}
		else
		{
			angle = (5 * PI) >> 2;
		}
		numerator = y - x;
		denominator = y + x;
	}
	if(!denominator)
	{
		return(angle);
	}
	return(angle + (PI >> 2) * numerator / denominator);
}

/**
 * Check whether two segments intersect themselves or not.
 *
 * @param x1 X coordinate of the first point of the first segment.
 * @param y1 Y coordinate of the first point of the first segment.
 * @param x2 X coordinate of the second point of the first segment.
 * @param y2 Y coordinate of the second point of the first segment.
 * @param x3 X coordinate of the first point of the second segment.
 * @param y3 Y coordinate of the first point of the second segment.
 * @param x4 X coordinate of the second point of the second segment.
 * @param y4 Y coordinate of the second point of the second segment.
 * @return 1 if the first segment crosses the second one, 0 otherwise.
 */
unsigned char MathSegmentSegmentIntersectionCheck(const signed long x1, const signed long y1, const signed long x2, const signed long y2, const signed long x3, const signed long y3, const signed long x4, const signed long y4)
{
	// Check whether the point 3 and the point 4 are on opposite sides of the line (1-2)
	// Note: if either 3 or 4 is exactly on the line (1-2), then we consider there can be an intersection
	signed long A = y2 - y1;
	signed long B = x1 - x2;
	signed long C = A * x1 + B * y1;

	signed long side1 = A * x3 + B * y3 - C;
	if(side1)
	{
		const signed long side2 = A * x4 + B * y4 - C;
		if(side2 && ((side1 < 0) ^ (side2 > 0)))
		{
			// No intersection
			return(0);
		}
	}

	// Check whether the point 1 and the point 2 are on opposite sides of the line (3-4)
	// Note: if either 1 or 2 is exactly on the line (3-4), then we consider there can be an intersection
	A = y4 - y3;
	B = x3 - x4;
	C = A * x3 + B * y3;

	side1 = A * x1 + B * y1 - C;
	if(side1)
	{
		const signed long side2 = A * x2 + B * y2 - C;
		if(side2 && ((side1 < 0) ^ (side2 > 0)))
		{
			// No intersection
			return(0);
		}
	}

	// The two segments intersect themselves!
	return(1);
}

/**
 * Check whether a segment intersect a line.
 *
 * @param segmentX1 X coordinate of the first point of the segment.
 * @param segmentY1 Y coordinate of the first point of the segment.
 * @param segmentX2 X coordinate of the second point of the segment.
 * @param segmentY2 Y coordinate of the second point of the segment.
 * @param lineX X coordinate of a point of the line.
 * @param lineY Y coordinate of a point of the line.
 * @param lineDx Direction of the line along the X axis.
 * @param lineDy Direction of the line along the Y axis.
 * @return 1 if the segment intersect the line, 0 otherwise.
 */
unsigned char MathSegmentLineIntersectionCheck(const signed long segmentX1, const signed long segmentY1, const signed long segmentX2, const signed long segmentY2, const signed long lineX, const signed long lineY, const signed long lineDx, const signed long lineDy)
{
	const signed long numerator = lineDx * (segmentY1 - lineY) - lineDy * (segmentX1 - lineX);
	const signed long denominator = lineDy * (segmentX2 - segmentX1) - lineDx * (segmentY2 - segmentY1);

	if(numerator >= 0)
	{
		if(denominator >= 0 && numerator < denominator)
		{
			return(1);
		}
	}
	else
	{
		if(denominator < 0 && numerator > denominator)
		{
			return(1);
		}
	}
	return(0);
}

/**
 * Check whether the distance of a point to a segment is lower than a given limit.
 *
 * @param x0 X coordinate of the point.
 * @param y0 Y coordinate of the point.
 * @param x1 X coordinate of the first point of the segment.
 * @param y1 Y coordinate of the first point of the segment.
 * @param x2 X coordinate of the second point of the segment.
 * @param y2 Y coordinate of the second point of the segment.
 * @param dist Limit.
 * @return 1 if the actual distance is lower than the limit, 0 otherwise.
 */
unsigned char MathSegmentCloseToPointCheck(const signed long x0, const signed long y0, const signed long x1, const signed long y1, const signed long x2, const signed long y2, const signed long dist)
{
	const signed long dX21 = x2 - x1;
	const signed long dY12 = y1 - y2;
	const signed long dX01 = x0 - x1;
	const signed long dY01 = y0 - y1;

	// Check whether the segment is actually a single point (i.e. {x1,y1} is {x2,y2})
	if(!dX21 && !dY12)
	{
		// Simply check the distance from {x0,y0} to {x1,y1}
		if(MathNormFast(dX01, dY01) < dist)
		{
			return(1);
		}
		return(0);
	}

	// Check that the projection of {x0,y0} onto the line is between {x1,y1} and {x2,y2}
	if((dX21 * dX01 < dY12 * dY01) || (dX21 * (x0 - x2) > dY12 * (y0 - y2)))
	{
		return(0);
	}

	// Check the distance from {x0,y0} to the line defined by {x1,y1} and {x2,y2}
	signed long product = dX21 * dY01 + dY12 * dX01;
	if(product < 0)
	{
		product = -product;
	}
	if(product < dist * MathNormFast(dX21, dY12))
	{
		return(1);
	}
	return(0);
}

/**
 * Find the intersection of two lines.
 *
 * @param x1 X coordinate of the first point of the line 1.
 * @param y1 Y coordinate of the first point of the line 1.
 * @param x2 X coordinate of the second point of the line 1.
 * @param y2 Y coordinate of the second point of the line 1.
 * @param x3 X coordinate of the first point of the line 2.
 * @param y3 Y coordinate of the first point of the line 2.
 * @param x4 X coordinate of the second point of the line 2.
 * @param y4 Y coordinate of the second point of the line 2.
 * @param intersection Pointer to an array of 2 integers in which the intersection point's coordinates will be stored.
 * @return 1 if the two lines intersect each other, 0 otherwise.
 */
unsigned char MathLineLinetIntersectionFind(const signed long x1, const signed long y1, const signed long x2, const signed long y2, const signed long x3, const signed long y3, const signed long x4, const signed long y4, signed long* intersection)
{
	const signed long dX1 = x2 - x1;
	const signed long dY1 = y2 - y1;
	const signed long dX2 = x4 - x3;
	const signed long dY2 = y4 - y3;

	const signed long dX1dY2 = (dX1 * dY2) >> FIXED_POINT_SHIFT;
	const signed long dX2dY1 = (dX2 * dY1) >> FIXED_POINT_SHIFT;

	const signed long determinant = dX2dY1 - dX1dY2;
	if(!determinant)
	{
		return(0);
	}

	intersection[0] = (dX2dY1 * x1 - dX1dY2 * x3 + ((dX1 * dX2) >> FIXED_POINT_SHIFT) * (y3 - y1)) / determinant;
	intersection[1] = (dX2dY1 * y3 - dX1dY2 * y1 + ((dY1 * dY2) >> FIXED_POINT_SHIFT) * (x3 - x1)) / determinant;
	return(1);
}

/**
 * Round a 32 bits integer to the next largest power of 2.
 *
 * @param x Number to be rounded.
 * @return Rounded value (next largest power of 2).
 */
unsigned long MathRoundPower2(unsigned long x)
{
	--x;
	x |= x >> 1;
	x |= x >> 2;
	x |= x >> 4;
	x |= x >> 8;
	x |= x >> 16;
	return(x + 1);
}
