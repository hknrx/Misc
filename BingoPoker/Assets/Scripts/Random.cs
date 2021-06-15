public class Random
{
	// Private members
	ulong seed;

	/**
	 * Constructor.
	 *
	 * @param seed Seed of the pseudo random number generator.
	 */
	public Random (ulong seed)
	{
		this.seed = seed;
	}

	/**
	 * Constructor (set the seed of the pseudo random number generator according to the current time).
	 */
	public Random ()
	{
		seed = (ulong)System.DateTime.Now.Ticks;
	}

	/**
	 * Return a pseudo random value.
	 *
	 * @see <a href="http://java.sun.com/javase/6/docs/api/java/util/Random.html">J2SE "Random" implementation</a>
	 * @param limit The bound on the random number to be returned.
	 * @return A pseudo random integer, uniformly distributed between 0 (inclusive) and limit (exclusive).
	 */
	public int Value (int limit)
	{
		seed = (seed * 0x5DEECE66DLL + 0xBLL) & ((1LL << 48) - 1);
		return (int)(seed >> (48 - 31)) % limit;
	}
}
