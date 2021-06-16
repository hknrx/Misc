using UnityEngine;
using System;
using System.Collections.Generic;

public class Poker
{
	// Public members
	public enum Combination
	{
		FiveOfAKind,
		RoyalFlush,
		StraightFlush,
		FourOfAKind,
		FullHouse,
		Flush,
		Straight,
		ThreeOfAKind,
		TwoPair,
		OnePair,
		HighCard
	}
	public const int MASK_SUIT = 15 << 15;
	public const int MASK_RANK = (1 << 15) - 1;
	public const int MASK_WILD = 1 << 21;
	public const int VALUE_WILD_RED = MASK_WILD | MASK_SUIT;
	public const int VALUE_WILD_BLACK = (1 << 24) | MASK_WILD | MASK_SUIT;
	public static readonly char[] SUITS = new char [] {'H', 'S', 'D', 'C'};
	public static readonly char[] RANKS = new char [] {'2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A'};

	/**
	 * Create a deck of cards.
	 *
	 * Each cards is encoded on an integer:
	 *   [wild color]  |       |  [wild]  |       |  [suit]   |       |  [rank]
	 *   B             |  0 0  |  W       |  0 0  |  C D S H  |  0 0  |  A K Q J T 9 8 7 6 5 4 3 2
	 *
	 * Normal cards have 2 bits set (one for the suit and one for the rank), wild cards are always represented
	 * using x001001111000000000000000 (the wild color bit, the wild bit, and all the suits).
	 *
	 * Note: empty spaces (2 bits) between each set of information are important: they allow doing the sum of the 5 cards without
	 * having to fear about overflows (the worst case being a hand with 4 As, 5 Spades or 5 Wilds, we need 2 extra bits after "A",
	 * 2 extra bits after "S", and 2 extra bits after "W").
	 *
	 * @param wildCountRed Number of red wild cards to be added to the deck.
	 * @param wildCountBlack Number of black wild cards to be added to the deck.
	 * @return A deck of cards (list of card values).
	 */
	public static List <int> CreateDeck (int wildCountRed, int wildCountBlack)
	{
		List <int> deck = new List <int> (52 + wildCountRed + wildCountBlack);
		for (int suit = 1 << 15; suit <= 1 << 18; suit <<= 1) {
			for (int rank = 1 << 0; rank <= 1 << 12; rank <<= 1) {
				deck.Add (suit | rank);
			}
		}
		while (wildCountRed-- > 0) {
			deck.Add (VALUE_WILD_RED);
		}
		while (wildCountBlack-- > 0) {
			deck.Add (VALUE_WILD_BLACK);
		}
		return deck;
	}

	/**
	 * Create a deck of cards.
	 *
	 * @param wildCount Number of wild cards to be added to the deck.
	 * @return A deck of cards (list of card values).
	 */
	public static List <int> CreateDeck (int wildCount)
	{
		int wildCountRed = wildCount >> 1;
		int wildCountBlack = wildCount - wildCountRed;
		return CreateDeck (wildCountRed, wildCountBlack);
	}

	/**
	 * Shuffle a deck of cards.
	 *
	 * @param deck The deck of cards (any kind of list).
	 * @param random Instance of the pseudo random number generator to use to shuffle the cards.
	 */
	public static void Shuffle <T> (List <T> deck, Random random)
	{
		int count = deck.Count;
		while (count > 1) {
			int swap = random.Value (count--);
			T card = deck [swap];
			deck [swap] = deck [count];
			deck [count] = card;
		}
	}

	/**
	 * Check a poker hand of 5 cards and return the corresponding combination.
	 *
	 * @param card1 The 1st card of the poker hand.
	 * @param card2 The 2nd card of the poker hand.
	 * @param card3 The 3rd card of the poker hand.
	 * @param card4 The 4th card of the poker hand.
	 * @param card5 The 5th card of the poker hand.
	 * @return The combination found.
	 */
	public static Combination CheckHand (int card1, int card2, int card3, int card4, int card5)
	{
		int orRank = (card1 | card2 | card3 | card4 | card5) & MASK_RANK;

		int countRank = orRank - ((orRank >> 1) & 0x5555);
		countRank = ((countRank >> 2) & 0x3333) + (countRank & 0x3333);
		countRank = ((countRank >> 4) + countRank) & 0x0F0F;
		countRank = ((countRank >> 8) + countRank) & 0x1F;

		int countWild;
		bool straight;
		bool flush;
		Combination defaultCombination;

		switch (countRank) {
		case 2:
			int sumValue = card1 + card2 + card3 + card4 + card5;
			countWild = (sumValue >> 21) & 7;
			if (countWild == 0) {
				int sumRank = sumValue & MASK_RANK;
				int sumRank_2orRank = sumRank - (orRank << 1);
				return (sumRank_2orRank & -sumRank_2orRank) == sumRank_2orRank && sumRank_2orRank != 0 ? Combination.FullHouse : Combination.FourOfAKind;
			}
			if (countWild == 1) {
				int xorRank = (card1 ^ card2 ^ card3 ^ card4 ^ card5) & MASK_RANK;
				return xorRank == 0 ? Combination.FullHouse : Combination.FourOfAKind;
			}
			if (countWild == 2) {
				return Combination.FourOfAKind;
			}
			flush = (card1 & card2 & card3 & card4 & card5 & MASK_SUIT) != 0;
			if (flush) {
				straight = (orRank & (31 * (orRank & -orRank))) == orRank;
				if (straight) {
					if ((orRank & (31 << 8)) == orRank) {
						return Combination.RoyalFlush;
					}
					return Combination.StraightFlush;
				}
				straight = (orRank & ((1 << 12) | 15)) == orRank;
				if (straight) {
					return Combination.StraightFlush;
				}
			}
			return Combination.FourOfAKind;
		case 3:
			countWild = ((card1 + card2 + card3 + card4 + card5) >> 21) & 7;
			if (countWild == 0) {
				int xorRank = (card1 ^ card2 ^ card3 ^ card4 ^ card5) & MASK_RANK;
				return (xorRank & -xorRank) == xorRank ? Combination.TwoPair : Combination.ThreeOfAKind;
			}
			if (countWild == 1) {
				return Combination.ThreeOfAKind;
			}
			defaultCombination = Combination.ThreeOfAKind;
			break;
		case 4:
			countWild = ((card1 + card2 + card3 + card4 + card5) >> 21) & 7;
			if (countWild == 0) {
				return Combination.OnePair;
			}
			defaultCombination = Combination.OnePair;
			break;
		case 5:
			defaultCombination = Combination.HighCard;
			break;
		default:
			return Combination.FiveOfAKind;
		}

		straight = ((orRank & (31 * (orRank & -orRank))) == orRank) || ((orRank & ((1 << 12) | 15)) == orRank);
		flush = (card1 & card2 & card3 & card4 & card5 & MASK_SUIT) != 0;
		if (flush) {
			if (!straight) {
				return Combination.Flush;
			}
			if ((orRank & (31 << 8)) == orRank) {
				return Combination.RoyalFlush;
			}
			return Combination.StraightFlush;
		}
		if (straight) {
			return Combination.Straight;
		}
		return defaultCombination;
	}

	/**
	 * Convert a card value to a string.
	 *
	 * @param card The card value to be converted.
	 * @return The corresponding string ("?" if the conversion failed).
	 */
	public static string CardValueToString (int card)
	{
		// Check whether this is a wild card
		if ((card & MASK_WILD) != 0) {
			if ((card & ~(1 << 24)) != VALUE_WILD_RED) {
				return "?";
			}
			return (card & (1 << 24)) == 0 ? "WR" : "WB";
		}

		// Get the suit
		int suit;
		switch (card & MASK_SUIT) {
		case 1 << 15:
			suit = 0;
			break;
		case 1 << 16:
			suit = 1;
			break;
		case 1 << 17:
			suit = 2;
			break;
		case 1 << 18:
			suit = 3;
			break;
		default:
			return "?";
		}

		// Get the rank
		card &= MASK_RANK;
		if ((card & -card) != card) {
			return "?";
		}
		int rank = 0;
		while (card > 1) {
			card >>= 1;
			++rank;
		}
		return new string (new char [] {RANKS [rank], SUITS [suit]});
	}

	/**
	 * Convert a string to a card value.
	 *
	 * @param card The string to be converted.
	 * @return The corresponding card value (0 if the conversion failed).
	 */
	public static int StringToCardValue (string card)
	{
		// Make sure the format is correct
		if (card.Length != 2) {
			return 0;
		}

		// Check whether this is a wild card
		if (card [0] == 'W') {
			if (card [1] == 'R') {
				return VALUE_WILD_RED;
			}
			if (card [1] == 'B') {
				return VALUE_WILD_BLACK;
			}
			return 0;
		}

		// Get the suit
		int suit = Array.IndexOf (SUITS, card [1]);
		if (suit < 0) {
			return 0;
		}

		// Get the rank
		int rank = Array.IndexOf (RANKS, card [0]);
		if (rank < 0) {
			return 0;
		}
		return (1 << (suit + 15)) | (1 << rank);
	}

	/**
	 * Test the poker hand checker.
	 *
	 * @param wildCount Number of wild cards to be added to the deck.
	 * @param testCount Number of iterations.
	 * @param displayCount Number of results displayed for each combination.
	 */
	public static void Test (int wildCount, int testCount, int displayCount)
	{
		// Initialize the PRNG (to shuffle the cards)
		Random random = new Random ();

		// Create a deck
		List <int> deck = CreateDeck (wildCount);

		// Iterate several times
		Combination combination = Combination.HighCard;
		float start = Time.realtimeSinceStartup;
		float durationCheck = 0.0f;
		int cardIndex = 0;
		int [] countCombinations = new int [(int)Combination.HighCard + 1];
		for (int testIndex = 0; testIndex < testCount; ++testIndex) {

			// Shuffle the deck
			if (cardIndex < 5) {
				Shuffle (deck, random);
				cardIndex = deck.Count;
			}

			// Make a hand
			int card1 = deck [--cardIndex];
			int card2 = deck [--cardIndex];
			int card3 = deck [--cardIndex];
			int card4 = deck [--cardIndex];
			int card5 = deck [--cardIndex];

			// Check the hand
			float startCheck = Time.realtimeSinceStartup;
			combination = CheckHand (card1, card2, card3, card4, card5);
			durationCheck += Time.realtimeSinceStartup - startCheck;

			// Record the result
			int countCombination = ++countCombinations [(int)combination];

			// Display the first results of each combination
			if (countCombination <= displayCount) {
				Debug.Log ("Test #" + testIndex + ": " + CardValueToString (card1) + " " + CardValueToString (card2) + " " + CardValueToString (card3) + " " + CardValueToString (card4) + " " + CardValueToString (card5) + " => " + combination);
			}
		}

		// Display a short report
		System.Text.StringBuilder log = new System.Text.StringBuilder ();
		float duration = Time.realtimeSinceStartup - start;
		log.AppendFormat ("Test duration: {0}s\nPoker hand check duration: {1}s (= {2} tests/s)", duration, durationCheck, testCount / durationCheck);
		int combinationIndex = countCombinations.Length;
		while (combinationIndex-- > 0) {
			log.AppendFormat ("\n- {0}: {1} ({2}%) => {3}", (Combination)combinationIndex, countCombinations [combinationIndex], countCombinations [combinationIndex] * 100.0f / testCount, countCombinations [(int)Combination.OnePair] / countCombinations [combinationIndex]);
		}
		Debug.Log (log);
	}

	/**
	 * Test the poker hand checker.
	 *
	 * @param cards The poker hand (array of 5 strings).
	 */
	public static void Test (string [] cards)
	{
		// Get the 5 cards of the hand
		if (cards.Length != 5) {
			Debug.Log ("Error: the hand must be made of 5 cards.");
			return;
		}
		int[] hand = new int [5];
		for (int cardIndex = 0; cardIndex < hand.Length; ++cardIndex) {
			int card = StringToCardValue (cards [cardIndex]);
			if (card == 0) {
				Debug.Log ("Error: \"" + cards [cardIndex] + "\" is not a valid card name");
				return;
			}
			hand [cardIndex] = card;
		}

		// Check the hand
		Combination combination = CheckHand (hand [0], hand [1], hand [2], hand [3], hand [4]);

		// Display the result
		Debug.Log (cards [0] + " " + cards [1] + " " + cards [2] + " " + cards [3] + " " + cards [4] + " => " + combination);
	}
}
