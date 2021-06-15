public sealed class Settings
{
	// Singleton
	private static readonly Settings instance = new Settings ();
	public bool isInitialized;

	// Settings
	public int bingoDeckWildCount;
	public int bingoScoreBingo;
	public int bingoScoreDaub;
	public int[] bingoScoreHand = new int [(int)Poker.Combination.HighCard + 1];
	public int drawCardQuarterCount;
	public int drawTimerPlay = 5;
	public bool drawCanPass;
	public int patternGroupMask;
	public int coinCountMax;
	public int coinAvailableMask;
	public int coinSelectedMask;
	public int chipCountMax = 5;
	public int chipCount;

	private Settings ()
	{
	}

	public static Settings Instance {
		get {
			return instance;
		}
	}
}
