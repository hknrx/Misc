public class Math
{
	/**
	 * Count the number of bits set in an integer.
	 *
	 * @param number Integer.
	 * @return Number of bits set.
	 */
	public static int BitCount (int number)
	{
		number -= (number >> 1) & 0x55555555;
		number = ((number >> 2) & 0x33333333) + (number & 0x33333333);
		number = ((number >> 4) + number) & 0x0F0F0F0F;
		number += number >> 8;
		number += number >> 16;
		return number & 0x0000003F;
	}

	/**
	 * Return the Log2 of an integer.
	 *
	 * @param number Integer.
	 * @return Log2 of this integer.
	 */
	public static int Log2 (int number)
	{
		number |= number >> 1;
		number |= number >> 2;
		number |= number >> 4;
		number |= number >> 8;
		number |= number >> 16;
		return (BitCount (number >> 1));
	}

	/**
	 * Return the number of trailing zero bits in an integer.
	 *
	 * @param number Integer.
	 * @return Number of trailing zero bits.
	 */
	public static int TrailingZeroCount (int number)
	{
		return (BitCount ((number & -number) - 1));
	}
}
