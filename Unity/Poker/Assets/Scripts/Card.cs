using UnityEngine;
using System.Collections.Generic;

public struct BoardHand
{
	public int offset;
	public int increment;
	public uint mask;
	public Poker.Combination combination;
	public int barCenterBoardIndex;
	public float barAngle;
	public bool barDiagonal;
}

public class Card
{
	// Public members
	public static uint maskHighlighted;
	public static uint maskEnabled;
	public static uint maskLocked;
	public static uint maskBars;
	public static float[] rowShift = new float[5];
	public const float rowShiftCardsHidden = 1000.0f;
	public static readonly BoardHand[] boardHands = new BoardHand [12] {
		new BoardHand {offset =  0, increment = 1, mask = 0x000001F, barCenterBoardIndex =  2, barAngle =   0.0f, barDiagonal = false}, // Row #1
		new BoardHand {offset =  5, increment = 1, mask = 0x00003E0, barCenterBoardIndex =  7, barAngle =   0.0f, barDiagonal = false}, // Row #2
		new BoardHand {offset = 10, increment = 1, mask = 0x0007C00, barCenterBoardIndex = 12, barAngle =   0.0f, barDiagonal = false}, // Row #3
		new BoardHand {offset = 15, increment = 1, mask = 0x00F8000, barCenterBoardIndex = 17, barAngle =   0.0f, barDiagonal = false}, // Row #4
		new BoardHand {offset = 20, increment = 1, mask = 0x1F00000, barCenterBoardIndex = 22, barAngle =   0.0f, barDiagonal = false}, // Row #5
		new BoardHand {offset =  0, increment = 5, mask = 0x0108421, barCenterBoardIndex = 10, barAngle =  90.0f, barDiagonal = false}, // Column #1
		new BoardHand {offset =  1, increment = 5, mask = 0x0210842, barCenterBoardIndex = 11, barAngle =  90.0f, barDiagonal = false}, // Column #2
		new BoardHand {offset =  2, increment = 5, mask = 0x0421084, barCenterBoardIndex = 12, barAngle =  90.0f, barDiagonal = false}, // Column #3
		new BoardHand {offset =  3, increment = 5, mask = 0x0842108, barCenterBoardIndex = 13, barAngle =  90.0f, barDiagonal = false}, // Column #4
		new BoardHand {offset =  4, increment = 5, mask = 0x1084210, barCenterBoardIndex = 14, barAngle =  90.0f, barDiagonal = false}, // Column #5
		new BoardHand {offset =  0, increment = 6, mask = 0x1041041, barCenterBoardIndex = 12, barAngle = -45.0f, barDiagonal = true}, // Diagonal #1
		new BoardHand {offset =  4, increment = 4, mask = 0x0111110, barCenterBoardIndex = 12, barAngle =  45.0f, barDiagonal = true}, // Diagonal #2
	};

	// Private class members
	const float cardSpacing = 110.0f;
	static Card[] board = new Card [25];
	static GameObject[] bars = new GameObject [12];

	// Private instance members
	int boardIndex;
	int cardValue;
	GameObject[] cardSprites;
	GameObject highlightSprite;

	/**
	 * Static constructor.
	 */
	static Card ()
	{
		// Let's create one bar for each poker hand
		Vector2 barSize = Sprite.GetSize ("bar");
		float barScale = cardSpacing * 6.0f / barSize.x - 1.0f;
		Vector3 barScaleNormal = new Vector3 (barScale, 1.0f, 1.0f);
		Vector3 barScaleDiagonal = new Vector3 (barScale * Mathf.Sqrt (2.0f) - barSize.y / barSize.x, 1.0f, 1.0f);
		for (int handIndex = 0; handIndex < boardHands.Length; ++handIndex) {
			int boardIndex = boardHands [handIndex].barCenterBoardIndex;
			GameObject bar = Sprite.Create ("bar", new Vector3 ((boardIndex % 5 - 2) * cardSpacing, (2 - boardIndex / 5) * cardSpacing, 2.0f), 4);
			bar.transform.localScale = boardHands [handIndex].barDiagonal ? barScaleDiagonal : barScaleNormal;
			bar.transform.Rotate (0.0f, 0.0f, boardHands [handIndex].barAngle);
			bars [handIndex] = bar;
		}
	}

	/**
	 * Constructor.
	 *
	 * @param cardValue Value of the card (mix of its rank and suit).
	 */
	Card (int cardValue)
	{
		// Initialize the board index
		boardIndex = -1;

		// Take note of the card value
		this.cardValue = cardValue;

		// Create the card's sprites (1 for the card itself + 2 for the motion blur effect)
		// Note: it is important to have all sprites be out of the screen to avoid problems with the motion blur
		cardSprites = new GameObject [3];
		string name = Poker.CardValueToString (cardValue);
		Vector3 position = new Vector3 (-rowShiftCardsHidden, 0.0f, 0.0f);
		cardSprites [0] = Sprite.Create (name, position);
		position.z += 0.1f;
		cardSprites [1] = Sprite.Create (name, position, 1);
		position.z += 0.1f;
		cardSprites [2] = Sprite.Create (name, position, 2);

		// Create the highlight sprite
		position.z = -0.1f;
		highlightSprite = Sprite.Create ("highlight", position, 4);

		// Disable all the sprites
		cardSprites [0].SetActive (false);
		cardSprites [1].SetActive (false);
		cardSprites [2].SetActive (false);
		highlightSprite.SetActive (false);
	}

	/**
	 * Create a deck of cards.
	 *
	 * @param wildCount Number of wild cards to be added to the deck.
	 * @return A deck of cards.
	 */
	public static List <Card> CreateDeck (int wildCount)
	{
		List <Card> deck = new List <Card> ();
		foreach (int cardValue in Poker.CreateDeck (wildCount)) {
			deck.Add (new Card (cardValue));
		}
		return deck;
	}

	/**
	 * Move a card on the board.
	 *
	 * @param newBoardIndex Index of the card on the board.
	 * @return True if the card could be moved, false otherwise.
	 */
	public bool MoveOnBoard (int newBoardIndex)
	{
		// Make sure the index is valid and the new position isn't locked
		if (newBoardIndex < 0 || newBoardIndex >= board.Length || (maskLocked & (1 << newBoardIndex)) != 0) {
			return false;
		}

		// Make sure the card isn't locked
		bool cardOnBoard = boardIndex >= 0 && boardIndex < board.Length;
		if (cardOnBoard && (maskLocked & (1 << boardIndex)) != 0) {
			return false;
		}

		// Check about the card that is already at this position of the board
		Card otherCard = board [newBoardIndex];
		if (otherCard != null) {

			// Move the other card
			otherCard.boardIndex = boardIndex;
			if (cardOnBoard) {
				board [boardIndex] = otherCard;
			} else {
				otherCard.cardSprites [0].SetActive (false);
				otherCard.cardSprites [1].SetActive (false);
				otherCard.cardSprites [2].SetActive (false);
				otherCard.highlightSprite.SetActive (false);
			}
		} else if (cardOnBoard) {

			// There is no card here anymore
			board [boardIndex] = null;
		}

		// Move the card
		boardIndex = newBoardIndex;
		board [newBoardIndex] = this;
		return true;
	}

	/**
	 * Remove a card from the board.
	 *
	 * @param boardIndex Index of the corresponding position on the board.
	 * @return True if the card could be removed, false otherwise.
	 */
	public static bool RemoveFromBoard (int boardIndex)
	{
		// Make sure the index is valid and the position isn't locked
		if (boardIndex < 0 || boardIndex >= board.Length || (maskLocked & (1 << boardIndex)) != 0) {
			return false;
		}

		// Check the card that is at this position of the board
		Card card = board [boardIndex];
		if (card != null) {

			// Remove the card
			card.boardIndex = -1;
			board [boardIndex] = null;
		}
		return true;
	}

	/**
	 * Display a card.
	 */
	void Display ()
	{
		// Make sure the card is on the board
		if (boardIndex < 0 || boardIndex >= board.Length) {
			return;
		}

		// Set the position of all the sprites
		Vector2 positionVeryOld = cardSprites [1].transform.position;
		Vector2 positionOld = cardSprites [0].transform.position;

		int mask = 1 << boardIndex;
		int row = boardIndex / 5;
		Vector3 position = new Vector3 ((boardIndex % 5 - 2) * cardSpacing, (2 - row) * cardSpacing, 0.0f);
		if ((maskLocked & mask) == 0) {
			position.x -= rowShift [row];
			position.z += 1.0f;
		}

		cardSprites [2].transform.position = new Vector3 (positionVeryOld.x, positionVeryOld.y, position.z + 0.2f);
		cardSprites [1].transform.position = new Vector3 (positionOld.x, positionOld.y, position.z + 0.1f);
		cardSprites [0].transform.position = position;
		highlightSprite.transform.position = new Vector3 (position.x, position.y, position.z - 0.1f);

		// Set the card's sprites
		cardSprites [0].SetActive (true);
		cardSprites [1].SetActive (Mathf.Abs (positionOld.x - position.x) >= 1.0f || Mathf.Abs (positionOld.y - position.y) >= 1.0f);
		cardSprites [2].SetActive (Mathf.Abs (positionVeryOld.x - position.x) >= 1.0f || Mathf.Abs (positionVeryOld.y - position.y) >= 1.0f);
		Sprite.SetSpriteMaterial (cardSprites [0], (maskEnabled & mask) != 0 ? 0 : 3);

		// Set the highlight
		highlightSprite.SetActive ((maskHighlighted & mask) != 0);
	}

	/**
	 * Display the board (cards and bars).
	 */
	public static void DisplayBoard ()
	{
		// Display the cards
		foreach (Card card in board) {
			if (card != null) {
				card.Display ();
			}
		}

		// Display the bars
		for (int handIndex = 0; handIndex < boardHands.Length; ++handIndex) {
			bars [handIndex].SetActive ((maskBars & (1 << handIndex)) != 0);
		}
	}

	/**
	 * Convert a screen position to a board index.
	 *
	 * @screenPosition Position on the screen.
	 * @return Index of the corresponding position on the board, or -1 if outside the board.
	 */
	public static int ScreenToBoardIndex (Vector2 screenPosition)
	{
		Vector2 worldPosition = Camera.main.ScreenToWorldPoint (screenPosition);

		if (worldPosition.x < -2.5f * cardSpacing || worldPosition.x > 2.5f * cardSpacing || worldPosition.y < -2.5f * cardSpacing || worldPosition.y > 2.5f * cardSpacing) {
			return -1;
		}

		int column = (int)(worldPosition.x / cardSpacing + 2.5f);
		int row = (int)(2.5f - worldPosition.y / cardSpacing);
		return column + 5 * row;
	}

	/**
	 * Check a poker hand.
	 *
	 * @param handIndex Index of the hand to check.
	 */
	static void CheckHand (int handIndex)
	{
		// Get the 5 cards of the hand
		int boardIndex = boardHands [handIndex].offset;
		int boardIndexIncrement = boardHands [handIndex].increment;

		int[] hand = new int [5];
		for (int cardIndex = 0; cardIndex < hand.Length; ++cardIndex) {
			Card card = board [boardIndex];
			if (card == null) {
				boardHands [handIndex].combination = Poker.Combination.HighCard;
				return;
			}
			hand [cardIndex] = card.cardValue;
			boardIndex += boardIndexIncrement;
		}

		// Check the hand
		boardHands [handIndex].combination = Poker.CheckHand (hand [0], hand [1], hand [2], hand [3], hand [4]);
	}

	/**
	 * Check all the poker hands of the board.
	 */
	public static void CheckHands ()
	{
		// Let's check all the different poker hands
		for (int handIndex = 0; handIndex < boardHands.Length; ++handIndex) {
			CheckHand (handIndex);
		}
	}
}
