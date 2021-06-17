#ifndef MATH_H
#define MATH_H

/*
 * Macros.
 */
#define FIXED_POINT_SHIFT 8
#define FIXED_POINT       (1 << FIXED_POINT_SHIFT)
#define FIXED_INFINITY    ((1 << 29) - 1) // Note: it is important to prevent overflows while allowing "infinite" numbers to be multiplied at least by 2

#define PI_SHIFT       7
#define PI             (1 << PI_SHIFT)
#define PI_REAL        (3.14159265359 * FIXED_POINT)
#define SIN_COUNT      (1 << (PI_SHIFT + 1))
#define SIN_COUNT_MASK (SIN_COUNT - 1)
#define SIN(x)         mathSineTable[(x) & SIN_COUNT_MASK]
#define COS(x)         mathSineTable[((x) + (PI / 2)) & SIN_COUNT_MASK]

/*
 * Global variables.
 */
extern const signed short mathSineTable[SIN_COUNT];

/*
 * Prototypes.
 */
void MathRandSeed(const unsigned long long seed);
unsigned long MathRand(const unsigned long limit);
signed long MathSqrt(signed long x);
signed long MathNorm(const signed long dx, const signed long dy);
signed long MathNormFast(signed long dx, signed long dy);
unsigned char MathArcSin(signed long x);
unsigned char MathAngle(const signed long x, const signed long y);
unsigned char MathAngleFast(const signed long x, const signed long y);
unsigned char MathSegmentSegmentIntersectionCheck(const signed long x1, const signed long y1, const signed long x2, const signed long y2, const signed long x3, const signed long y3, const signed long x4, const signed long y4);
unsigned char MathSegmentLineIntersectionCheck(const signed long segmentX1, const signed long segmentY1, const signed long segmentX2, const signed long segmentY2, const signed long lineX, const signed long lineY, const signed long lineDx, const signed long lineDy);
unsigned char MathSegmentCloseToPointCheck(const signed long x0, const signed long y0, const signed long x1, const signed long y1, const signed long x2, const signed long y2, const signed long dist);
unsigned char MathLineLinetIntersectionFind(const signed long x1, const signed long y1, const signed long x2, const signed long y2, const signed long x3, const signed long y3, const signed long x4, const signed long y4, signed long* intersection);
unsigned long MathRoundPower2(unsigned long x);

#endif // MATH_H
