public class Math
{
	// Private members
	static ulong randomSeed;

	/**
	 * Set the seed of the pseudo random number generator.
	 *
	 * @param seed Seed.
	 */
	public static void RandSeed (ulong seed)
	{
		randomSeed = seed;
	}

	/**
	 * Set the seed of the pseudo random number generator according to the current time.
	 */
	public static void RandSeed ()
	{
		randomSeed = (ulong)System.DateTime.Now.Ticks;
	}

	/**
	 * Return a pseudo random value.
	 *
	 * @see <a href="http://java.sun.com/javase/6/docs/api/java/util/Random.html">J2SE "Random" implementation</a>
	 * @param limit The bound on the random number to be returned.
	 * @return A pseudo random, uniformly distributed integer between 0 (inclusive) and limit (exclusive).
	 */
	public static int Rand (int limit)
	{
		randomSeed = (randomSeed * 0x5DEECE66DLL + 0xBLL) & ((1LL << 48) - 1);
		return (int)(randomSeed >> (48 - 31)) % limit;
	}

	/**
	 * Count the number of bits set in an integer.
	 *
	 * @param number Integer.
	 * @return Number of bits set.
	 */
	public static uint BitCount (uint number)
	{
		number -= (number >> 1) & 0x55555555;
		number = ((number >> 2) & 0x33333333) + (number & 0x33333333);
		number = ((number >> 4) + number) & 0x0F0F0F0F;
		number += number >> 8;
		number += number >> 16;
		return number & 0x0000003F;
	}
}
