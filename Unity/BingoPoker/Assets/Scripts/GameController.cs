// WARNING:
// This work is *only* for prototyping. In particular, the code is dirty and shall not be reused as-is.

// Questions & notes (game design):
// - There shall be a way to check the pay table while in game (e.g. an icon showing a hand of card, which would display
//   a popup window when tapped).
// - Add some lucky charms (on sell): the player could purchase four leaf clovers and attach them to any coin, at any
//   time; this coin will then always flip to its good face when used (but then, the four leaf clover would disappear).
// - Add some more coins (on sell): either with a special bad face (e.g. -2 instead -3). or with no bad face at all
//   (e.g. "X"), or with a special good face (e.g. "+2 chips")... There could also be a coin that let you see the card
//   drawn, or another one to daub as many cards as you want that have the same rank, etc.
// - We shall also sell a special item to allow getting many more chips everyday (i.e. have a higher login bonus). This
//   could be appealing for players who usually never pay for F2P games, as they would see the actual value of this
//   particular item (the difference being that it's effect is "for life", i.e. it's not a consumable item but an unlock).
//   Note: it means there shall be a button to restore IAP, of course.
// - Be careful: when a coin makes the player lose chips, it may become impossible for the player to do a bingo (which
//   requires at least 5 chips). => Shall we forbid to use a coin that would lead to this situation? (= cannot use a coin
//   if the player has < (5 + risk) chips in total?)
// - There shall be a voice to announce about each card drawn (or each coin flipped).
// - Instead of having stages like in Candy Crush, we can propose an experience system like in "Bingo!", i.e. there
//   would still be different areas (worlds), but no sub-stages. In case we have various sets of images that players
//   can collect (typically, 1 set / world), then each image could correspond to a given poker combination: the player
//   would need to play several times to try achieve all different combinations.
// - ...or we can have a stage map, like in Candy Crush, each stage having its own settings (and goal). We could
//   innovate a bit by having multiple paths, letting the player choose how to progress...
// - Both the solo play and multiplayer modes shall be available from the beginning, but the game shall first emphasis
//   on solo play, that will serve as a tutorial, introducing features one by one (e.g. you simply need to complete a
//   bingo in the first stage, regardless of the poker combination, following a simple pattern, having plenty of chips
//   but no coins... then we ask the same with much less cards in the draw deck, but with a star coin... then we ask to
//   do at least a 3 of a kind, but introduce the swap coin, etc.). Then, once the player knows the game well enough, we
//   emphasis more on the multiplayer mode (= competition, where the player can "bet" chips).
// - In multiplayer, we should make sure players don't wait more than 20s to join a room (so, there shall be enough
//   rooms to accomodate everyone, basically #rooms = game_duration / 20s).
// - We should hold a daily tournament: a particular set of parameters for the multiplayer games (different win patterns,
//   different pay tables, etc.). Players would be free to join multiple times a day, to try improve their results; the
//   leaderboard would just show the best result of each player (one new leaderboard for each new tournament, everyday).
// - At the end of each game, we shall sort all players according to their score (+ timing in case of a draw). The total
//   number of chips played shall then be shared among players, depending on their ranking (e.g. if 5 players bet 10
//   chips each, i.e. 50 chips in total, then the 1st one could win 20, the 2nd 15, the 3rd 10, the 4th 5, and the last
//   one 0). The ending screen shall show the ranking as well as the number of poker chips won or lost.
// - To award poker chips in a multiplayer game, we could put all the players in a list sorted by their number of points
//   (reminder: we may need to also take into account the time at which they scored, to be able to sort people who have
//   the same score); if there is just one person in the list, then we give him the whole sum of chips... or else, we give
//   the first one 60% of the total, remove him from the list, then continue the process. For example, if we have 4 people,
//   then we would have: 1st = 60%, 2nd = 24%, 3rd = 9.6%, 4th = 6.4%.
// - For tournaments (multiplayer), we shall let players choose among different possible handicaps (different settings)
//   for a given game: each handicap would have a reward which the value depends on the difficulty (risk). For example,
//   if you enter a room with just 10 poker chips and no coin, you could get a much higher reward than if you enter with
//   30 chips and 3 powerful coins, of course. Note: we must be careful about monetization: paid items shall not be
//   impacted too much by handicaps...
// - Notes about the layout of the screen:
//   * There might be four leaf clovers in the future: counter to be shown under the coins?
//   * The bingo results area could be used to list the results of the player (when doing a bingo), or those of other
//     players in multiplayer games (realtime report about what others do), or to show the goal to reach in solo games...
// - In addition to the existing settings available in the prototype's menu, we could have:
//   * For solo games, the bingo card to use (unless it is always random?);
//   * For solo games, goal to reach (note: the goal shall be clearly displayed while in-game):
//     - Score?
//     - Number of bingos?
//     - A certain poker hand? (defined as the count of each combination to make?)
//   * Number of four leaf clovers to bring [note: this feature doesn't exist yet...].
using UnityEngine;
using System.Collections.Generic;

public class GameController : MonoBehaviour
{
	// Screen
	const float SCREEN_GAP = 10.0f;
	float screenDesignHeight;
	float screenDesignWidth;
	float screenGuiFactor;
	bool screenGuiSetup;

	// Font
	public Font font;

	// Pseudo random number generators
	Random randomCommon;
	Random randomPrivate;

	// Menu
	Rect menuButtonPosition;
	GUIStyle menuButtonStyle;

	// Countdown
	Rect countdownPosition;
	GUIStyle countdownStyle;
	string countdownValue;

	// Bingo card & its poker cards
	const float BINGO_SHUFFLE_DURATION = 1.0f;
	const float BINGO_SHUFFLE_CYCLE = 8;
	const float BINGO_SHUFFLE_MOVE = 10.0f;
	const float BINGO_TIMER_RESULT_HANDS = 1.0f;
	const float BINGO_TIMER_RESULT_DETAILS = 10.0f;
	const float CARD_MOVE_FILTER = 0.15f;
	GameObject bingoCard;
	Rect bingoButtonPosition;
	GUIStyle bingoButtonStyle;
	struct BingoResult
	{
		public int patternGroupIndex;
		public int patternIndex;
		public Poker.Combination combination;
		public int score;
	}
	List <BingoResult> bingoResults;
	GameObject[] bingoResultsHighlight;
	Rect bingoResultsPosition;
	Rect bingoResultsSize;
	Vector2 bingoResultsOffset;
	GUIStyle bingoResultsStyle;
	System.Text.StringBuilder bingoResultsDisplay;
	GUIContent bingoResultsContent;
	bool bingoResultsScroll;
	GameObject bingoDeck;
	List <int> bingoDeckCards;
	Dictionary<GameObject, int> bingoCardIndexes;
	int bingoCardSelectedMask;
	GameObject bingoCardHighlight;
	GameObject bingoCardLatestDaubed;
	enum BingoState
	{
		UNKNOWN,
		SHUFFLE,
		DEAL,
		PLAY,
		CHECK,
		SHOW_HANDS,
		CLEANUP,
		END,
	}
	BingoState bingoStateCurrent;
	BingoState bingoStateNext;
	float bingoStateTimeStart;
	float bingoStateTimeDuration;
	bool bingoCanPlay;

	// Drawing system
	List <int> drawDeck;
	int drawCardCount;
	int drawCardIndex;
	int drawCardValue;
	bool drawCardFaceUp;
	GameObject drawCard;
	GameObject drawPileDraw;
	GameObject drawPileDiscard;
	const float DRAW_SHUFFLE_DURATION = 1.0f;
	const float DRAW_SHUFFLE_CYCLE = 8;
	const float DRAW_SHUFFLE_MOVE = 10.0f;
	const float DRAW_TIMER_MOVE = 0.3f;
	const float DRAW_TIMER_FLIP = 0.2f;
	const int DRAW_ALERT_COUNT = 5;
	const float DRAW_ALERT_SCALE = 0.1f;
	const float DRAW_ALERT_SPEED = Mathf.PI * 4;
	Rect drawTimerPosition;
	GUIStyle drawTimerStyle;
	Rect drawPassMessagePosition;
	GUIStyle drawPassMessageStyle;
	Rect drawCountPosition;
	GUIStyle drawCountStyle;
	enum DrawMaskCode
	{
		SWAP_CARDS = -1,
		CREATE_WILD = -2,
		OTHER_TO_BE_DEFINED = -3, // Note: all special mask codes shall be lower than 0!
	}
	int drawSelectableRanks;
	enum DrawState
	{
		UNKNOWN,
		COUNTDOWN,
		DRAW,
		FLIP_FACE_UP,
		PLAY,
		FLIP_FACE_DOWN,
		CLEANUP,
		ENDING,
		END,
	}
	DrawState drawStateCurrent;
	DrawState drawStateNext;
	float drawStateTimeStart;
	float drawStateTimeDuration;
	bool drawCanPlay;
	bool drawCanDaub;

	// Coins
	struct Coin
	{
		public string coin;
		public string faceGood;
		public string faceBad;
		public int risk;
	}
	static readonly Coin[] COINS = new Coin [] {
		new Coin {coin = "coinBlue", faceGood = "coinFaceWild", faceBad = "coinFaceSkull-1", risk = 1},     // Wild
		new Coin {coin = "coinYellow", faceGood = "coinFaceStar", faceBad = "coinFaceSkull-2", risk = 2},   // Star
		new Coin {coin = "coinRed", faceGood = "coinFaceSwap", faceBad = "coinFaceSkull-3", risk = 3},      // Swap
		new Coin {coin = "coinPurple", faceGood = "coinFaceS-Wild", faceBad = "coinFaceSkull-5", risk = 5}, // S-Wild
	};
	GameObject coinSelected;
	enum CoinSelectedState
	{
		IDLE,
		FLIPPING,
		USED,
	}
	CoinSelectedState coinSelectedState;
	class CoinData
	{
		public int index;
		public Vector3 positionUnselected;
		public float angle;
		public float timer;
		public bool flipping;
	}
	Dictionary<GameObject, CoinData> coins;
	const float COIN_SCALE_SELECTED = 1.4f;
	const float COIN_SCALE_UNSELECTED = 0.7f;
	const float COIN_FLIP_SPEED_USED = Mathf.PI * 10;
	const float COIN_FLIP_SPEED_UNUSED = Mathf.PI * 2;
	const float COIN_WAIT_DURATION = 1.0f;
	const float COIN_MOVE_FILTER = 0.1f;

	// Basic player data
	int playerScoreReal;
	int playerScoreDisplay;
	int playerScoreExpected;
	float PLAYER_SCORE_UPDATE_DURATION = 1.0f;
	float playerScoreUpdateTime;
	float playerScoreUpdateSpeed;
	Rect playerScorePosition;
	GUIStyle playerScoreStyle;

	// Chips
	int chipCountReal;
	int chipCountDisplay;
	Rect chipCountPosition;
	GUIStyle chipCountStyle;
	GameObject chip;
	GameObject chipWarning;
	const float CHIP_SCALE_IDLE = 1.0f;
	const float CHIP_SCALE_CHANGE = 1.6f;
	const float CHIP_SCALE_FILTER = 0.25f;

	// Patterns
	const float PATTERN_GRID_UPDATE_PERIOD = 0.5f;
	static readonly int[][] PATTERNS = new int [][] {
		new int [] {
			(20 << 0) | (21 << 5) | (22 << 10) | (23 << 15) | (24 << 20),
			(15 << 0) | (16 << 5) | (17 << 10) | (18 << 15) | (19 << 20),
			(10 << 0) | (11 << 5) | (12 << 10) | (13 << 15) | (14 << 20),
			(5 << 0) | (6 << 5) | (7 << 10) | (8 << 15) | (9 << 20),
			(0 << 0) | (1 << 5) | (2 << 10) | (3 << 15) | (4 << 20),
		},
		new int [] {
			(0 << 0) | (5 << 5) | (10 << 10) | (15 << 15) | (20 << 20),
			(1 << 0) | (6 << 5) | (11 << 10) | (16 << 15) | (21 << 20),
			(2 << 0) | (7 << 5) | (12 << 10) | (17 << 15) | (22 << 20),
			(3 << 0) | (8 << 5) | (13 << 10) | (18 << 15) | (23 << 20),
			(4 << 0) | (9 << 5) | (14 << 10) | (19 << 15) | (24 << 20),
		},
		new int [] {
			(4 << 0) | (8 << 5) | (12 << 10) | (16 << 15) | (20 << 20),
			(0 << 0) | (6 << 5) | (12 << 10) | (18 << 15) | (24 << 20),
		},
		new int [] {
			(0 << 0) | (4 << 5) | (12 << 10) | (20 << 15) | (24 << 20),
			(2 << 0) | (10 << 5) | (12 << 10) | (14 << 15) | (22 << 20),
		},
		new int [] {
			(10 << 0) | (12 << 5) | (16 << 10) | (20 << 15) | (22 << 20),
			(11 << 0) | (13 << 5) | (17 << 10) | (21 << 15) | (23 << 20),
			(12 << 0) | (14 << 5) | (18 << 10) | (22 << 15) | (24 << 20),
			(5 << 0) | (7 << 5) | (11 << 10) | (15 << 15) | (17 << 20),
			(6 << 0) | (8 << 5) | (12 << 10) | (16 << 15) | (18 << 20),
			(7 << 0) | (9 << 5) | (13 << 10) | (17 << 15) | (19 << 20),
			(0 << 0) | (2 << 5) | (6 << 10) | (10 << 15) | (12 << 20),
			(1 << 0) | (3 << 5) | (7 << 10) | (11 << 15) | (13 << 20),
			(2 << 0) | (4 << 5) | (8 << 10) | (12 << 15) | (14 << 20),
		},
		new int [] {
			(11 << 0) | (15 << 5) | (16 << 10) | (17 << 15) | (21 << 20),
			(12 << 0) | (16 << 5) | (17 << 10) | (18 << 15) | (22 << 20),
			(13 << 0) | (17 << 5) | (18 << 10) | (19 << 15) | (23 << 20),
			(6 << 0) | (10 << 5) | (11 << 10) | (12 << 15) | (16 << 20),
			(7 << 0) | (11 << 5) | (12 << 10) | (13 << 15) | (17 << 20),
			(8 << 0) | (12 << 5) | (13 << 10) | (14 << 15) | (18 << 20),
			(1 << 0) | (5 << 5) | (6 << 10) | (7 << 15) | (11 << 20),
			(2 << 0) | (6 << 5) | (7 << 10) | (8 << 15) | (12 << 20),
			(3 << 0) | (7 << 5) | (8 << 10) | (9 << 15) | (13 << 20),
		},
		new int [] {
			(10 << 0) | (14 << 5) | (16 << 10) | (18 << 15) | (22 << 20),
			(2 << 0) | (8 << 5) | (14 << 10) | (18 << 15) | (22 << 20),
			(2 << 0) | (6 << 5) | (8 << 10) | (10 << 15) | (14 << 20),
			(2 << 0) | (6 << 5) | (10 << 10) | (16 << 15) | (22 << 20),
		},
		new int [] {
			(10 << 0) | (15 << 5) | (16 << 10) | (21 << 15) | (22 << 20),
			(14 << 0) | (18 << 5) | (19 << 10) | (22 << 15) | (23 << 20),
			(2 << 0) | (3 << 5) | (8 << 10) | (9 << 15) | (14 << 20),
			(1 << 0) | (2 << 5) | (5 << 10) | (6 << 15) | (10 << 20),
		},
		new int [] {
			(10 << 0) | (11 << 5) | (16 << 10) | (17 << 15) | (22 << 20),
			(13 << 0) | (14 << 5) | (17 << 10) | (18 << 15) | (22 << 20),
			(2 << 0) | (7 << 5) | (8 << 10) | (13 << 15) | (14 << 20),
			(2 << 0) | (6 << 5) | (7 << 10) | (10 << 15) | (11 << 20),
		},
	};
	GameObject patternGrid;
	float patternGridUpdateTime;
	int patternGridGroupIndex;
	int patternGridIndex;
	int patternGroupMask;

	/**
	 * Method called by Unity after that the GameObject has been instantiated.
	 * This is the place where we initialize everything.
	 */
	void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Tests...
//		Poker.Test (Settings.Instance.bingoDeckWildCount, 10000000, 0);

		// Initialize the PRNG (to shuffle the cards)
		randomCommon = new Random ((ulong)new System.TimeSpan (System.DateTime.Now.Ticks).Minutes);
		randomPrivate = new Random ();

		// Compute the zoom factor to respect the design of the screen layout
		screenDesignHeight = Camera.main.orthographicSize * 2;
		screenDesignWidth = Camera.main.aspect * screenDesignHeight;
		screenGuiFactor = Screen.height / screenDesignHeight;

		// Create all elements
		BingoCardCreate ();
		DrawSystemCreate ();
		CoinsCreate ();
		PatternGridCreate ();
		ChipCreate ();

		// Initialize the state machines
		bingoStateNext = BingoState.SHUFFLE;
		drawStateNext = DrawState.COUNTDOWN;
	}

	/**
	 * Method called by Unity at every frame.
	 */
	void Update ()
	{
		// Animate the material used to highlight the cards
		float tint = 0.8f + 0.2f * Mathf.Sin (Time.frameCount * 0.2f);
		Sprite.SetMaterialColor (2, new Color (tint, tint, tint, 1.0f));

		// Update the bingo card
		BingoCardUpdate ();

		// Update the draw system
		DrawSystemUpdate ();

		// Update the coins
		CoinsUpdate ();

		// Update the pattern grid
		PatternGridUpdate ();

		// Update the chip
		ChipUpdate ();

		// Update the player's inputs
		PlayerInputUpdate ();

		// Update the player's (displayed) score
		PlayerScoreUpdate ();
	}

	/**
	 * Update the player's (displayed) score.
	 */
	void PlayerScoreUpdate ()
	{
		int error = playerScoreReal - playerScoreDisplay;
		if (error != 0) {
			float speed = error / PLAYER_SCORE_UPDATE_DURATION;
			float duration = Time.time - playerScoreUpdateTime;
			int increment;
			bool ok;
			if (error > 0) {
				playerScoreUpdateSpeed = Mathf.Max (playerScoreUpdateSpeed, speed);
				increment = Mathf.CeilToInt (playerScoreUpdateSpeed * duration);
				ok = error <= increment;
			} else {
				playerScoreUpdateSpeed = Mathf.Min (playerScoreUpdateSpeed, speed);
				increment = Mathf.FloorToInt (playerScoreUpdateSpeed * duration);
				ok = error >= increment;
			}
			if (ok) {
				playerScoreDisplay = playerScoreReal;
				playerScoreUpdateSpeed = 0.0f;
			} else {
				playerScoreDisplay += increment;
			}
		}
		playerScoreUpdateTime = Time.time;
	}

	/**
	 * Handle the player's inputs.
	 */
	void PlayerInputUpdate ()
	{
		// Check whether we can play
		if (!bingoCanPlay || !drawCanPlay) {
			return;
		}

		// Check whether the player is tapping the screen
		if (!Input.GetMouseButtonDown (0)) {
			return;
		}

		// Check whether an element is touched
		Ray ray = Camera.main.ScreenPointToRay (Input.mousePosition);
		RaycastHit hit;
		if (!Physics.Raycast (ray, out hit, Mathf.Infinity)) {
			return;
		}
		GameObject touchedObject = hit.collider.gameObject;

		// Check whether a card is touched
		int index;
		if (bingoCardIndexes.TryGetValue (touchedObject, out index)) {

			// Check whether the card is already selected
			int mask = 1 << index;
			if ((bingoCardSelectedMask & mask) != 0) {

				// Unselect the card
				++chipCountReal;
				bingoCardSelectedMask ^= mask;
				Sprite.SetSpriteMaterial (touchedObject, 0);
				if (touchedObject == bingoCardLatestDaubed) {
					bingoCardHighlight.SetActive (false);
					bingoCardLatestDaubed = null;
				}
				return;
			}

			// Check whether we are to swap 2 cards
			if (drawSelectableRanks == (int)DrawMaskCode.SWAP_CARDS) {

				// Check whether we already selected another card
				if (!bingoCardLatestDaubed) {

					// Select this card
					bingoCardLatestDaubed = touchedObject;
					Sprite.SetSpriteMaterial (bingoCardLatestDaubed, 2);
					bingoCardHighlight.transform.localPosition = bingoCardLatestDaubed.transform.localPosition + Vector3.back;
					bingoCardHighlight.SetActive (true);
					return;
				}

				// Is this the card that is already selected?
				if (touchedObject != bingoCardLatestDaubed) {

					// Swap the 2 cards
					int otherIndex = bingoCardIndexes [bingoCardLatestDaubed];
					bingoCardIndexes [bingoCardLatestDaubed] = index;
					bingoCardIndexes [touchedObject] = otherIndex;

					int cardValue = bingoDeckCards [index];
					bingoDeckCards [index] = bingoDeckCards [otherIndex];
					bingoDeckCards [otherIndex] = cardValue;

					touchedObject.transform.Translate (Vector3.back);
					bingoCardLatestDaubed.transform.Translate (Vector3.back);

					// The swap is completed
					drawSelectableRanks = 0;
				}

				// There is nothing selected at this point
				Sprite.SetSpriteMaterial (bingoCardLatestDaubed, 0);
				bingoCardHighlight.SetActive (false);
				bingoCardLatestDaubed = null;
				return;
			}

			// Check whether we shall create a wild card
			if (drawSelectableRanks == (int)DrawMaskCode.CREATE_WILD) {

				// Create a wild card
				int cardValue = randomPrivate.Value (2) == 0 ? Poker.VALUE_WILD_RED : Poker.VALUE_WILD_BLACK;
				bingoDeckCards [index] = cardValue;
				Sprite.Modify (touchedObject, Poker.CardValueToString (cardValue));
				touchedObject.transform.position = coinSelected.transform.localPosition + Vector3.forward;

				// The wild card creation is completed
				drawSelectableRanks = 0;
				return;
			}

			// Check whether the card can be selected
			if (drawCanDaub && (drawSelectableRanks & bingoDeckCards [index]) != 0 && (bingoCardLatestDaubed || chipCountReal > 0)) {

				// Select the card
				if (bingoCardLatestDaubed) {
					bingoCardSelectedMask ^= 1 << bingoCardIndexes [bingoCardLatestDaubed];
					Sprite.SetSpriteMaterial (bingoCardLatestDaubed, 0);
				} else {
					--chipCountReal;
				}
				bingoCardSelectedMask ^= mask;
				bingoCardLatestDaubed = touchedObject;
				Sprite.SetSpriteMaterial (bingoCardLatestDaubed, 1);
				bingoCardHighlight.transform.localPosition = bingoCardLatestDaubed.transform.localPosition + Vector3.back;
				bingoCardHighlight.SetActive (true);
			}
			return;
		}

		// Check whether the draw card is touched
		if (touchedObject == drawCard) {

			// Shall we pass?
			if (Settings.Instance.drawCanPass && drawStateCurrent == DrawState.PLAY) {
				drawStateNext = DrawState.FLIP_FACE_DOWN;
			}
			return;
		}

		// Check whether a coin is touched
		if (coins.ContainsKey (touchedObject)) {

			// Can we select a coin?
			if (!coinSelected || coinSelectedState == CoinSelectedState.IDLE) {
				if (touchedObject != coinSelected) {

					// Select this coin
					coinSelected = touchedObject;
				} else {

					// Unselect this coin
					coinSelected = null;
				}
			} else if (Settings.Instance.drawCanPass && drawStateCurrent == DrawState.PLAY) {

				// Pass
				drawStateNext = DrawState.FLIP_FACE_DOWN;
			}
		}
	}

	/**
	 * Update the bingo results display.
	 *
	 * @param message Message to be displayed.
	 */
	void BingoResultsUpdate (string message)
	{
		if (bingoResultsDisplay == null) {
			bingoResultsDisplay = new System.Text.StringBuilder (message);
		} else {
			bingoResultsDisplay.AppendLine ();
			bingoResultsDisplay.Append (message);
		}
		bingoResultsContent = new GUIContent (bingoResultsDisplay.ToString ());
		bingoResultsSize.height = Mathf.Max (bingoResultsPosition.height, bingoResultsStyle.CalcHeight (bingoResultsContent, bingoResultsSize.width));
		bingoResultsScroll = true;
	}

	/**
	 * Get the position of a card on the bingo card.
	 *
	 * @param x column Column in which the card is.
	 * @param y row Row in which the card is.
	 * @return Position of the card.
	 */
	Vector3 BingoCardPosition (int column, int row)
	{
		return new Vector3 ((100.0f + SCREEN_GAP) * (column - 2), (100.0f + SCREEN_GAP) * (row - 2), 0.0f);
	}

	/**
	 * Move all the cards to their correct position.
	 *
	 * @param moveBackToDeck True if the cards shall move back to the draw deck, false otherwise.
	 * @return True if all the cards are in place, false otherwise.
	 */
	bool BingoCardMove (bool moveBackToDeck)
	{
		bool cardAllInPlace = true;
		Vector3 cardTargetPosition = bingoDeck.transform.localPosition;
		foreach (KeyValuePair<GameObject, int> cardInfo in bingoCardIndexes) {
			GameObject cardSprite = cardInfo.Key;
			if (!moveBackToDeck) {
				int cardIndex = cardInfo.Value;
				cardTargetPosition = BingoCardPosition (cardIndex % 5, cardIndex / 5);
			}
			Vector3 error = cardTargetPosition - cardSprite.transform.localPosition;
			cardSprite.transform.localPosition += error * CARD_MOVE_FILTER;
			cardAllInPlace &= error.sqrMagnitude < 1.0f;
		}
		return cardAllInPlace;
	}

	/**
	 * Create a bingo card.
	 */
	void BingoCardCreate ()
	{
		// Create a deck of cards
		bingoDeckCards = Poker.CreateDeck (Settings.Instance.bingoDeckWildCount);
		Vector3 bingoDeckPosition = BingoCardPosition (5, 1);

		// Make sure we can retrieve the card indexes
		bingoCardIndexes = new Dictionary<GameObject, int> (25);

		// Create the bingo card
		bingoCard = new GameObject ("bingoCard");
		bingoDeck = Sprite.Create ("back", bingoDeckPosition);
		bingoDeck.transform.parent = bingoCard.transform;
		for (int cardIndex = 0; cardIndex < 25; ++cardIndex) {
			GameObject cardSprite = Sprite.Create ("back", bingoDeckPosition);
			cardSprite.transform.parent = bingoCard.transform;
			cardSprite.AddComponent<BoxCollider> ();
			bingoCardIndexes.Add (cardSprite, cardIndex);
		}

		// Create the highlight sprites
		bingoResultsHighlight = new GameObject [5];
		for (int cardIndex = 0; cardIndex < 6; ++cardIndex) {
			bingoCardHighlight = Sprite.Create ("highlight", Vector3.zero, 2);
			bingoCardHighlight.transform.parent = bingoCard.transform;
			bingoCardHighlight.SetActive (false);
			if (cardIndex < 5) {
				bingoResultsHighlight [cardIndex] = bingoCardHighlight;
			}
		}

		// Move the bingo card
		float bingoCardHeight = 5 * 100.0f + 4 * SCREEN_GAP;
		float zoom = (screenDesignHeight - (SCREEN_GAP * 5 + 100.0f)) / bingoCardHeight;
		bingoCard.transform.localScale = new Vector3 (zoom, zoom, 1.0f);
		bingoCard.transform.localPosition = new Vector3 (0.0f, -(SCREEN_GAP * 3 + 100.0f) * 0.5f, 0.0f);

		// Create a list to hold the bingo results
		bingoResults = new List<BingoResult> ();
	}

	/**
	 * Update the bingo card.
	 */
	void BingoCardUpdate ()
	{
		// Update the state machine: handle the change of states
		if (bingoStateCurrent != bingoStateNext) {

			// Exit the current state
			switch (bingoStateCurrent) {
			case BingoState.SHUFFLE:

				// Make sure the draw deck is at the right place
				bingoDeck.transform.localPosition = BingoCardPosition (5, 1);
				break;
			case BingoState.DEAL:
				break;
			case BingoState.PLAY:

				// The player isn't allowed to play anymore
				bingoCanPlay = false;
				break;
			case BingoState.CHECK:
				break;
			case BingoState.SHOW_HANDS:

				// Hide all the highlight sprites used to show the poker hands
				foreach (GameObject sprite in bingoResultsHighlight) {
					sprite.SetActive (false);
				}
				break;
			case BingoState.CLEANUP:
				break;
			case BingoState.END:
				break;
			}

			// Change the state
			bingoStateCurrent = bingoStateNext;
			bingoStateTimeStart = Time.time;

			// Enter the current state
			switch (bingoStateCurrent) {
			case BingoState.SHUFFLE:

				// Shuffle the deck of cards
				Poker.Shuffle (bingoDeckCards, randomCommon);
				break;
			case BingoState.DEAL:

				// Change all the cards on the bingo card
				foreach (KeyValuePair<GameObject, int> cardInfo in bingoCardIndexes) {
					GameObject cardSprite = cardInfo.Key;
					int cardIndex = cardInfo.Value;
					int cardValue = bingoDeckCards [cardIndex];
					Sprite.Modify (cardSprite, Poker.CardValueToString (cardValue));
				}

				// There is nothing selected at this point
				bingoCardSelectedMask = 0;
				bingoCardLatestDaubed = null;
				break;
			case BingoState.PLAY:
				break;
			case BingoState.CHECK:

				// Clear the results
				bingoResults.Clear ();
				playerScoreExpected = playerScoreReal;
				if (patternGroupMask > 0) {

					// Check all the allowed pattern groups
					BingoResult bingoResult = new BingoResult ();
					int[] hand = new int [5];
					int patternGroupIndex = Math.TrailingZeroCount (patternGroupMask);
					while (patternGroupIndex < PATTERNS.Length) {

						// Check all the patterns in this group
						bingoResult.patternGroupIndex = patternGroupIndex;
						for (int patternIndex = 0; patternIndex < PATTERNS [patternGroupIndex].Length; ++patternIndex) {
							int mask = 0;
							int cellIndexes = PATTERNS [patternGroupIndex] [patternIndex];
							for (int cellCount = 0; cellCount < 5; ++cellCount) {
								int cellIndex = cellIndexes & 31;
								cellIndexes >>= 5;
								mask |= 1 << cellIndex;
								hand [cellCount] = bingoDeckCards [cellIndex];
							}

							// Check that the pattern has been marked with chips
							if ((mask & bingoCardSelectedMask) == mask) {

								// Check this poker hand
								Poker.Combination combination = Poker.CheckHand (hand [0], hand [1], hand [2], hand [3], hand [4]);

								// Take note of this result
								bingoResult.patternIndex = patternIndex;
								bingoResult.combination = combination;
								bingoResult.score = Settings.Instance.bingoScoreHand [(int)combination];
								bingoResults.Add (bingoResult);

								// Update the expected score
								playerScoreExpected += bingoResult.score;
							}
						}
						++patternGroupIndex;
						patternGroupIndex += Math.TrailingZeroCount (patternGroupMask >> patternGroupIndex);
					}
				}

				// Is there a bingo?
				if (bingoResults.Count > 0) {

					// Update the expected score
					playerScoreExpected += Settings.Instance.bingoScoreBingo;

					// Let show the results
					bingoStateNext = BingoState.SHOW_HANDS;
				} else {

					// Continue to play...
					bingoStateNext = BingoState.PLAY;
				}
				break;
			case BingoState.SHOW_HANDS:

				// Hide the highlight sprite used for selection
				bingoCardHighlight.SetActive (false);

				// Make sure there is a bingo
				if (bingoResults.Count > 0) {

					// Update the score
					if (Settings.Instance.bingoScoreBingo != 0) {
						playerScoreReal += Settings.Instance.bingoScoreBingo;
						BingoResultsUpdate (string.Format ("BINGO! ({0:+#;-#;0})", Settings.Instance.bingoScoreBingo));
					} else {
						BingoResultsUpdate ("BINGO!");
					}

					// Enable all the highlight sprites used to show the poker hands
					foreach (GameObject sprite in bingoResultsHighlight) {
						sprite.SetActive (true);
					}
				}
				break;
			case BingoState.CLEANUP:

				// Get back the chips that are on the bingo card
				chipCountReal += Math.BitCount (bingoCardSelectedMask);
				break;
			case BingoState.END:

				// Update the score
				int daubCount = Math.BitCount (bingoCardSelectedMask);
				int daubScore = daubCount * Settings.Instance.bingoScoreDaub;
				if (daubScore != 0) {
					playerScoreReal += daubScore;
					BingoResultsUpdate (string.Format ("{0} daubed cards! ({1:+#;-#;0})", daubCount, daubScore));
				}
				break;
			}
		}

		// Update the state machine: execute the current state
		bingoStateTimeDuration = Time.time - bingoStateTimeStart;
		switch (bingoStateCurrent) {
		case BingoState.SHUFFLE:

			// Animate the draw deck
			Vector3 bingoDeckPosition = BingoCardPosition (5, 1);
			bingoDeckPosition.y += BINGO_SHUFFLE_MOVE * (0.5f - 0.5f * Mathf.Cos (2 * Mathf.PI * BINGO_SHUFFLE_CYCLE * bingoStateTimeDuration / BINGO_SHUFFLE_DURATION));
			bingoDeck.transform.localPosition = bingoDeckPosition;

			// Handle the change of state
			if (bingoStateTimeDuration >= BINGO_SHUFFLE_DURATION) {
				bingoStateNext = BingoState.DEAL;
			}
			break;
		case BingoState.DEAL:

			// Move all the cards to their correct position
			bool cardAllInPlace = BingoCardMove (false);

			// Handle the change of state
			if (cardAllInPlace) {
				bingoStateNext = BingoState.PLAY;
			}
			break;
		case BingoState.PLAY:

			// Move all the cards to their correct position
			bingoCanPlay = BingoCardMove (false);

			// Update the expected score
			playerScoreExpected = playerScoreReal + Math.BitCount (bingoCardSelectedMask) * Settings.Instance.bingoScoreDaub;

			// Handle the change of state
			if (bingoCanPlay && drawStateCurrent == DrawState.ENDING) {
				bingoStateNext = BingoState.END;
			}
			break;
		case BingoState.CHECK:
			break;
		case BingoState.SHOW_HANDS:

			// Wait a little before modifying the results
			if (bingoStateTimeDuration < 0.0f) {
				break;
			}

			// Check whether we still have results to display
			if (bingoResults.Count > 0) {

				// Update the score
				BingoResult bingoResult = bingoResults [0];
				bingoResults.RemoveAt (0);
				if (bingoResult.score != 0) {
					playerScoreReal += bingoResult.score;
					BingoResultsUpdate (string.Format ("{0}! ({1:+#;-#;0})", bingoResult.combination, bingoResult.score));
				} else {
					BingoResultsUpdate (bingoResult.combination + "...");
				}

				// Show the hand
				int cellIndexes = PATTERNS [bingoResult.patternGroupIndex] [bingoResult.patternIndex];
				foreach (GameObject sprite in bingoResultsHighlight) {
					int cellIndex = cellIndexes & 31;
					cellIndexes >>= 5;
					sprite.transform.localPosition = BingoCardPosition (cellIndex % 5, cellIndex / 5) + Vector3.back;
				}

				// Reset the state timer
				bingoStateTimeStart = Time.time + BINGO_TIMER_RESULT_HANDS;
			} else {

				// Get a new bingo card
				bingoStateNext = BingoState.CLEANUP;
			}
			break;
		case BingoState.CLEANUP:

			// Move all the cards back to the draw deck
			cardAllInPlace = BingoCardMove (true);

			// Handle the change of state
			if (cardAllInPlace) {
				bingoStateNext = BingoState.SHUFFLE;
			}
			break;
		case BingoState.END:
			break;
		}
	}

	/**
	 * Create the draw system.
	 */
	void DrawSystemCreate ()
	{
		// Create and shuffle a deck of cards
		drawDeck = Poker.CreateDeck (Settings.Instance.bingoDeckWildCount);
		Poker.Shuffle (drawDeck, randomCommon);
		drawCardCount = (drawDeck.Count * Mathf.Clamp (Settings.Instance.drawCardQuarterCount + 1, 1, 4)) >> 2;

		// Create the draw pile, the draw card, and the discard pile
		Vector3 cardPosition = new Vector3 (-SCREEN_GAP * 3 - 100.0f, screenDesignHeight * 0.5f - SCREEN_GAP - 100.0f * 0.5f, 0.0f);
		drawPileDraw = Sprite.Create ("back", cardPosition);
		drawCard = Sprite.Create ("back", cardPosition);
		drawCard.AddComponent<BoxCollider> ();
		cardPosition.x = SCREEN_GAP * 3 + 100.0f;
		drawPileDiscard = Sprite.Create ("back", cardPosition);
		drawPileDiscard.SetActive (false);
	}

	/**
	 * Update the draw system.
	 */
	void DrawSystemUpdate ()
	{
		// Animate the draw pile
		if (drawCardCount - drawCardIndex <= DRAW_ALERT_COUNT) {
			float drawPileScale = 1.0f + DRAW_ALERT_SCALE * Mathf.Sin (Time.time * DRAW_ALERT_SPEED);
			drawPileDraw.transform.localScale = new Vector3 (drawPileScale, drawPileScale, 1.0f);
		}

		// Update the state machine: handle the change of states
		if (drawStateCurrent != drawStateNext) {

			// Exit the current state
			switch (drawStateCurrent) {
			case DrawState.COUNTDOWN:

				// Remove the countdown message
				countdownValue = null;

				// Make sure the draw pile is at the right place
				drawPileDraw.transform.localPosition = drawCard.transform.localPosition;

				// The player is now allowed to play
				drawCanPlay = true;
				break;
			case DrawState.DRAW:
				break;
			case DrawState.FLIP_FACE_UP:

				// Set the selectable ranks
				if (!coinSelected || coinSelectedState != CoinSelectedState.USED) {

					// Use the card
					drawSelectableRanks = drawCardValue & ~Poker.MASK_SUIT;
				} else {

					// Use the coin
					CoinData coinData = coins [coinSelected];
					if (Mathf.Cos (coinData.angle) > 0.0f) {
						switch (coinData.index) {
						case 0:
							drawSelectableRanks = Poker.MASK_WILD;
							break;
						case 1:
							drawSelectableRanks = Poker.MASK_WILD | ((1 << Poker.RANKS.Length) - 1);
							break;
						case 2:
							drawSelectableRanks = (int)DrawMaskCode.SWAP_CARDS;
							break;
						case 3:
							drawSelectableRanks = (int)DrawMaskCode.CREATE_WILD;
							break;
						}
					} else {

						// Lose some chips!
						chipCountReal -= COINS [coinData.index].risk;
					}
				}
				break;
			case DrawState.PLAY:

				// Cancel any pending swap action
				if (drawSelectableRanks == (int)DrawMaskCode.SWAP_CARDS && bingoCardLatestDaubed) {
					Sprite.SetSpriteMaterial (bingoCardLatestDaubed, 0);
				}

				// The player isn't allowed to daub cards anymore
				drawCanDaub = false;
				drawSelectableRanks = 0;
				bingoCardLatestDaubed = null;
				bingoCardHighlight.SetActive (false);
				break;
			case DrawState.FLIP_FACE_DOWN:

				// Check if a coin was used
				if (coinSelected && coinSelectedState == CoinSelectedState.USED) {
					coinSelected = null;
					coinSelectedState = CoinSelectedState.IDLE;
				}
				break;
			case DrawState.CLEANUP:

				// We now have a discard pile, for sure
				drawPileDiscard.SetActive (true);
				break;
			case DrawState.ENDING:
				break;
			case DrawState.END:
				break;
			}

			// Change the state
			drawStateCurrent = drawStateNext;
			drawStateTimeStart = Time.time;

			// Enter the current state
			switch (drawStateCurrent) {
			case DrawState.COUNTDOWN:
				break;
			case DrawState.DRAW:

				// Get the card
				drawCardValue = drawDeck [drawCardIndex];

				// Prepare to draw another card
				++drawCardIndex;

				// Check whether the draw pile is now empty
				if (drawCardIndex >= drawCardCount) {
					drawPileDraw.SetActive (false);
				}
				break;
			case DrawState.FLIP_FACE_UP:

				// Request to use the selected coin
				if (coinSelected && coinSelectedState == CoinSelectedState.FLIPPING) {
					coinSelectedState = CoinSelectedState.USED;
				}
				break;
			case DrawState.PLAY:

				// The player is now allowed to daub cards
				drawCanDaub = true;
				break;
			case DrawState.FLIP_FACE_DOWN:

				// Check if a coin has to be used
				if (coinSelected && coinSelectedState == CoinSelectedState.IDLE && drawCardIndex < drawCardCount) {
					coinSelectedState = CoinSelectedState.FLIPPING;
				}
				break;
			case DrawState.CLEANUP:
				break;
			case DrawState.ENDING:

				// The player isn't allowed to play anymore
				drawCanPlay = false;

				// Send the expected score to the server (to compute the leaderboard and share the poker chips)
				// Note: for now, let's display the value in the log, to check it's ok.
				Debug.Log ("Expected final score: " + playerScoreExpected);
				break;
			case DrawState.END:

				// Game over!
				countdownPosition.height = 320.0f * screenGuiFactor;
				countdownPosition.y = (Screen.height - countdownPosition.height) * 0.5f - bingoCard.transform.localPosition.y * screenGuiFactor;
				countdownStyle.fontSize = (int)(140.0f * screenGuiFactor);
				countdownValue = "GAME\nOVER!";
				break;
			}
		}

		// Update the state machine: execute the current state
		drawStateTimeDuration = Time.time - drawStateTimeStart;
		switch (drawStateCurrent) {
		case DrawState.COUNTDOWN:

			// Handle the countdown
			if (drawStateTimeDuration < 3.0f) {
				countdownValue = Mathf.CeilToInt (3.0f - drawStateTimeDuration).ToString ();
			} else if (drawStateTimeDuration < 4.0f) {
				countdownValue = "GO!";
			} else {
				drawStateNext = DrawState.DRAW;
			}

			// Animate the draw pile
			if (drawStateTimeDuration <= DRAW_SHUFFLE_DURATION) {
				Vector3 drawPilePosition = drawCard.transform.localPosition;
				drawPilePosition.y += DRAW_SHUFFLE_MOVE * (0.5f - 0.5f * Mathf.Cos (2 * Mathf.PI * DRAW_SHUFFLE_CYCLE * bingoStateTimeDuration / DRAW_SHUFFLE_DURATION));
				drawPileDraw.transform.localPosition = drawPilePosition;
			}
			break;
		case DrawState.DRAW:

			// Move the draw card
			Vector3 position = drawCard.transform.localPosition;
			position.x = Mathf.Lerp (drawPileDraw.transform.localPosition.x, 0.0f, drawStateTimeDuration / DRAW_TIMER_MOVE);
			drawCard.transform.localPosition = position;

			// Handle the change of state
			if (drawStateTimeDuration >= DRAW_TIMER_MOVE) {
				drawStateNext = DrawState.FLIP_FACE_UP;
			}
			break;
		case DrawState.FLIP_FACE_UP:

			// Flip the card
			if (!coinSelected || coinSelectedState != CoinSelectedState.USED) {
				float scale = Mathf.Cos (Mathf.PI * Mathf.Min (1.0f, drawStateTimeDuration / DRAW_TIMER_FLIP));
				drawCard.transform.localScale = new Vector3 (Mathf.Abs (scale), 1.0f, 1.0f);
				if (scale < 0.0f && !drawCardFaceUp) {
					Sprite.Modify (drawCard, Poker.CardValueToString (drawCardValue));
					drawCardFaceUp = true;
				}
			}

			// Handle the change of state
			if (drawStateTimeDuration >= DRAW_TIMER_FLIP) {
				drawStateNext = DrawState.PLAY;
			}
			break;
		case DrawState.PLAY:

			// Handle the change of state
			if (drawStateTimeDuration >= Settings.Instance.drawTimerPlay) {
				drawStateNext = DrawState.FLIP_FACE_DOWN;
			}
			break;
		case DrawState.FLIP_FACE_DOWN:

			// Flip the card
			if (!coinSelected || coinSelectedState != CoinSelectedState.USED) {
				float scale = Mathf.Cos (Mathf.PI * Mathf.Min (1.0f, drawStateTimeDuration / DRAW_TIMER_FLIP));
				drawCard.transform.localScale = new Vector3 (Mathf.Abs (scale), 1.0f, 1.0f);
				if (scale < 0.0f && drawCardFaceUp) {
					Sprite.Modify (drawCard, "back");
					drawCardFaceUp = false;
				}
			}

			// Handle the change of state
			if (drawStateTimeDuration >= DRAW_TIMER_FLIP) {
				drawStateNext = DrawState.CLEANUP;
			}
			break;
		case DrawState.CLEANUP:

			// Move the draw card
			position = drawCard.transform.localPosition;
			position.x = Mathf.Lerp (0.0f, drawPileDiscard.transform.localPosition.x, drawStateTimeDuration / DRAW_TIMER_MOVE);
			drawCard.transform.localPosition = position;

			// Handle the change of state
			if (drawStateTimeDuration >= DRAW_TIMER_MOVE) {
				if (drawCardIndex < drawCardCount) {
					drawStateNext = DrawState.DRAW;
				} else {
					drawStateNext = DrawState.ENDING;
				}
			}
			break;
		case DrawState.ENDING:

			// Handle the change of state
			if (bingoStateCurrent == BingoState.END) {
				drawStateNext = DrawState.END;
			}
			break;
		case DrawState.END:
			break;
		}
	}

	/**
	 * Create some coins.
	 */
	void CoinsCreate ()
	{
		// Make sure the selected coins are all available, aren't unknown, and aren't too many
		int coinMask = Settings.Instance.coinAvailableMask & Settings.Instance.coinSelectedMask & ((1 << COINS.Length) - 1);
		int coinCount = Mathf.Min (Math.BitCount (coinMask), Settings.Instance.coinCountMax);
		coins = new Dictionary<GameObject, CoinData> (coinCount);

		// Create the coins
		Vector3 coinPosition = new Vector3 (screenDesignWidth * 0.5f - SCREEN_GAP - 100.0f * COIN_SCALE_UNSELECTED * 0.5f, screenDesignHeight * 0.5f - SCREEN_GAP - 100.0f * COIN_SCALE_UNSELECTED * 0.5f, 0.0f);
		float timer = Time.time + COIN_WAIT_DURATION;
		float timerIncrement = COIN_WAIT_DURATION / coinCount;
		while (coinCount-- > 0) {
			CoinData coinData = new CoinData ();
			coinData.index = Math.TrailingZeroCount (coinMask);
			coinData.positionUnselected = coinPosition;
			coinData.angle = 0.0f;
			coinData.timer = timer;

			GameObject coinSprite = Sprite.Create (COINS [coinData.index].coin, coinPosition);
			GameObject coinFace = Sprite.Create (COINS [coinData.index].faceGood, Vector3.zero);
			coinFace.transform.parent = coinSprite.transform;
			coinFace.transform.localPosition = Vector3.back;
			coinSprite.AddComponent<BoxCollider> ();

			coins.Add (coinSprite, coinData);

			coinMask -= (coinMask & -coinMask);
			coinPosition.y -= SCREEN_GAP + 100.0f * COIN_SCALE_UNSELECTED;
			timer += timerIncrement;
		}
	}

	/**
	 * Update the coins.
	 */
	void CoinsUpdate ()
	{
		// Check all the coins
		foreach (KeyValuePair<GameObject, CoinData> coinInfo in coins) {

			// Get the coin's data
			GameObject coinSprite = coinInfo.Key;
			CoinData coinData = coinInfo.Value;

			// Make sure we can afford to use this coin
			int price = COINS [coinData.index].risk;
			if (price <= chipCountReal) {
				Sprite.SetSpriteMaterial (coinSprite, 0);
			} else {
				Sprite.SetSpriteMaterial (coinSprite, 1);
				if (coinSprite == coinSelected && coinSelectedState == CoinSelectedState.IDLE) {
					coinSelected = null;
				}
			}

			// Set the coin's position and scale
			Vector3 coinTargetPosition;
			float coinTargetScale;
			if (coinSprite == coinSelected) {
				coinTargetPosition = new Vector3 (100.0f * 0.5f + SCREEN_GAP * 3 + 100.0f + SCREEN_GAP * 3 + 100.0f * COIN_SCALE_SELECTED * 0.5f, screenDesignHeight * 0.5f - SCREEN_GAP - 100.0f * COIN_SCALE_SELECTED * 0.5f, -2.0f);
				coinTargetScale = COIN_SCALE_SELECTED;
			} else {
				coinTargetPosition = coinData.positionUnselected;
				coinTargetScale = COIN_SCALE_UNSELECTED;
			}
			coinSprite.transform.localPosition += (coinTargetPosition - coinSprite.transform.localPosition) * COIN_MOVE_FILTER;
			float scale = coinSprite.transform.localScale.y;
			scale += (coinTargetScale - scale) * COIN_MOVE_FILTER;

			// Check whether the coin shall be flipped
			if (coinSprite == coinSelected) {
				coinData.flipping |= (coinSelectedState == CoinSelectedState.FLIPPING || (coinSelectedState == CoinSelectedState.IDLE && Time.time > coinData.timer));
			} else {
				coinData.flipping |= Time.time > coinData.timer;
			}
			if (!coinData.flipping) {

				// Set the coin's display (scale)
				coinSprite.transform.localScale = new Vector3 (scale, scale, 1.0f);
			} else {

				// Flip the coin (modify its rotation angle)
				float cosinePrevious = Mathf.Cos (coinData.angle);
				float sinePrevious = Mathf.Sin (coinData.angle);
				float angleIncrement;
				if (coinSprite != coinSelected || coinSelectedState == CoinSelectedState.IDLE) {
					angleIncrement = COIN_FLIP_SPEED_UNUSED;
				} else {
					angleIncrement = COIN_FLIP_SPEED_USED * (8 + randomPrivate.Value (5)) * 0.1f;
				}
				float angleCurrent = coinData.angle + angleIncrement * Time.deltaTime;
				float sineCurrent = Mathf.Sin (angleCurrent);

				// Check whether the coin shall stop flipping
				if ((sinePrevious < 0.0f ^ sineCurrent < 0.0f) && (coinSprite != coinSelected || coinSelectedState != CoinSelectedState.FLIPPING)) {
					coinData.flipping = false;
					coinData.timer = Time.time + COIN_WAIT_DURATION;
					angleCurrent = cosinePrevious > 0.0f ? 0.0f : Mathf.PI;
				}
				coinData.angle = angleCurrent;
				float cosineCurrent = Mathf.Cos (angleCurrent);

				// Set the coin's display (scale and sprite)
				coinSprite.transform.localScale = new Vector3 (Mathf.Abs (cosineCurrent) * scale, scale, 1.0f);
				if (cosinePrevious >= 0.0f) {
					if (cosineCurrent < 0.0f) {
						Sprite.Modify (coinSprite.transform.GetChild (0).gameObject, COINS [coinData.index].faceBad);
					}
				} else {
					if (cosineCurrent >= 0.0f) {
						Sprite.Modify (coinSprite.transform.GetChild (0).gameObject, COINS [coinData.index].faceGood);
					}
				}
			}
		}
	}

	/**
	 * Create the pattern grid.
	 */
	void PatternGridCreate ()
	{
		// Make sure the pattern mask doesn't contain unknown patterns
		patternGroupMask = Settings.Instance.patternGroupMask & ((1 << PATTERNS.Length) - 1);

		// Create the pattern grid
		patternGrid = Sprite.Create ("patternGrid", new Vector3 (-screenDesignWidth * 0.5f + SCREEN_GAP + 100.0f * 0.5f, -screenDesignHeight * 0.5f + SCREEN_GAP + 100.0f * 0.5f, 0.0f));
		if (patternGroupMask != 0) {
			for (int patternCell = 0; patternCell < 5; ++patternCell) {
				GameObject patternCellSprite = Sprite.Create ("patternCell", Vector3.zero);
				patternCellSprite.transform.parent = patternGrid.transform;
			}
		}

		// Make sure the pattern will be updated now
		patternGridUpdateTime = 0.0f;
		patternGridGroupIndex = Math.TrailingZeroCount (patternGroupMask);
		patternGridIndex = 0;
	}

	/**
	 * Update the pattern grid.
	 */
	void PatternGridUpdate ()
	{
		// Check when to update the grid
		if (patternGroupMask != 0 && Time.time > patternGridUpdateTime) {

			// Display a pattern
			int cellIndexes = PATTERNS [patternGridGroupIndex] [patternGridIndex];
			foreach (Transform patternCellTransform in patternGrid.transform) {
				int cellIndex = cellIndexes & 31;
				cellIndexes >>= 5;
				patternCellTransform.localPosition = new Vector3 (((cellIndex % 5) - 2) * 20.0f, ((cellIndex / 5) - 2) * 20.0f, -0.1f);
			}

			// Next pattern...
			patternGridUpdateTime = Time.time + PATTERN_GRID_UPDATE_PERIOD;
			if (++patternGridIndex >= PATTERNS [patternGridGroupIndex].Length) {
				int mask = patternGroupMask >> ++patternGridGroupIndex;
				if (mask > 0) {
					patternGridGroupIndex += Math.TrailingZeroCount (mask);
				} else {
					patternGridGroupIndex = Math.TrailingZeroCount (patternGroupMask);
				}
				patternGridIndex = 0;
			}
		}
	}

	/**
	 * Create the poker chip.
	 */
	void ChipCreate ()
	{
		// Create a poker chip sprite
		chip = Sprite.Create ("pokerChip", new Vector3 (-screenDesignWidth * 0.5f + SCREEN_GAP + 100.0f * 0.5f, -screenDesignHeight * 0.5f + SCREEN_GAP + 100.0f + SCREEN_GAP * 2 + 100.0f * 0.5f, 0.0f));

		// Create a warning sprite
		chipWarning = Sprite.Create ("warning", new Vector3 (-screenDesignWidth * 0.5f + SCREEN_GAP + 100.0f, -screenDesignHeight * 0.5f + SCREEN_GAP + 100.0f + SCREEN_GAP * 2 + 100.0f, -1.0f), 2);
		chipWarning.SetActive (false);

		// Initialize the counters
		chipCountReal = Mathf.Min (Settings.Instance.chipCountMax, Settings.Instance.chipCount);
		chipCountDisplay = chipCountReal;
	}

	/**
	 * Update the poker chip.
	 */
	void ChipUpdate ()
	{
		// Animate the chip
		float chipScaleCurrent = chip.transform.localScale.x;
		if (chipCountDisplay != chipCountReal && Mathf.Abs (CHIP_SCALE_IDLE - chipScaleCurrent) < CHIP_SCALE_IDLE * 0.1f) {
			if (chipCountDisplay < chipCountReal) {
				++chipCountDisplay;
			} else {
				--chipCountDisplay;
			}
			chipScaleCurrent = CHIP_SCALE_CHANGE;
		}
		chipScaleCurrent += (CHIP_SCALE_IDLE - chipScaleCurrent) * CHIP_SCALE_FILTER;
		chip.transform.localScale = new Vector3 (chipScaleCurrent, chipScaleCurrent, 1.0f);

		// Handle the warning sign
		chipWarning.SetActive (chipCountReal == 0);
	}

	/**
	 * Setup the GUI.
	 */
	void GuiCreate ()
	{
		// Setup everything once only
		if (screenGuiSetup) {
			return;
		}
		screenGuiSetup = true;

		// Menu button
		menuButtonPosition = new Rect (SCREEN_GAP * screenGuiFactor, SCREEN_GAP * screenGuiFactor, 150.0f * screenGuiFactor, 50.0f * screenGuiFactor);
		menuButtonStyle = new GUIStyle (GUI.skin.button);
		menuButtonStyle.font = font;
		menuButtonStyle.fontSize = (int)(40.0f * screenGuiFactor);

		// Countdown
		countdownPosition = new Rect (Screen.width * 0.5f - 200.0f * screenGuiFactor, Screen.height * 0.5f - 100.0f * screenGuiFactor, 400.0f * screenGuiFactor, 200.0f * screenGuiFactor);
		countdownStyle = new GUIStyle (GUI.skin.label);
		countdownStyle.font = font;
		countdownStyle.fontSize = (int)(200.0f * screenGuiFactor);
		countdownStyle.alignment = TextAnchor.MiddleCenter;
		countdownStyle.normal.textColor = Color.red;

		// Bingo button
		float bingoCardWidth = screenDesignHeight - (SCREEN_GAP * 5 + 100.0f);
		bingoButtonPosition = new Rect (Screen.width * 0.5f + (bingoCardWidth * 0.5f + SCREEN_GAP) * screenGuiFactor, Screen.height - (SCREEN_GAP + 80.0f) * screenGuiFactor, Screen.width * 0.5f - (SCREEN_GAP + bingoCardWidth * 0.5f + SCREEN_GAP) * screenGuiFactor, 80.0f * screenGuiFactor);
		bingoButtonStyle = new GUIStyle (GUI.skin.button);
		bingoButtonStyle.font = font;
		bingoButtonStyle.fontSize = (int)(40.0f * screenGuiFactor);

		// Bingo results
		bingoResultsPosition = new Rect (SCREEN_GAP * screenGuiFactor, (SCREEN_GAP + 50.0f + SCREEN_GAP + 90.0f + SCREEN_GAP) * screenGuiFactor, Screen.width * 0.5f - (SCREEN_GAP + bingoCardWidth * 0.5f + SCREEN_GAP) * screenGuiFactor, Screen.height - ((SCREEN_GAP + 50.0f + SCREEN_GAP + 90.0f + SCREEN_GAP) + (SCREEN_GAP + 100.0f + SCREEN_GAP * 2 + 100.0f + 100.0f * 0.5f)) * screenGuiFactor);
		bingoResultsSize = new Rect (0, 0, bingoResultsPosition.width, bingoResultsPosition.height);
		bingoResultsContent = new GUIContent ();
		bingoResultsStyle = new GUIStyle (GUI.skin.box);
		bingoResultsStyle.font = font;
		bingoResultsStyle.fontSize = (int)(20.0f * screenGuiFactor);
		bingoResultsStyle.alignment = TextAnchor.UpperLeft;
		bingoResultsStyle.normal.textColor = new Color (1.0f, 0.7f, 1.0f);
		bingoResultsStyle.wordWrap = true;

		// Draw information
		drawTimerPosition = new Rect (Screen.width * 0.5f + (SCREEN_GAP * 3 + 100.0f - 50.0f) * screenGuiFactor, (100.0f * 0.5f + SCREEN_GAP - 20.0f) * screenGuiFactor, 100.0f * screenGuiFactor, 40.0f * screenGuiFactor);
		drawTimerStyle = new GUIStyle (GUI.skin.label);
		drawTimerStyle.font = font;
		drawTimerStyle.fontSize = (int)(40.0f * screenGuiFactor);
		drawTimerStyle.alignment = TextAnchor.MiddleCenter;

		drawPassMessagePosition = new Rect (Screen.width * 0.5f - 50.0f * screenGuiFactor, (100.0f + SCREEN_GAP) * screenGuiFactor, 100.0f * screenGuiFactor, 24.0f * screenGuiFactor);
		drawPassMessageStyle = new GUIStyle (GUI.skin.label);
		drawPassMessageStyle.font = font;
		drawPassMessageStyle.fontSize = (int)(16.0f * screenGuiFactor);
		drawPassMessageStyle.alignment = TextAnchor.MiddleCenter;
		drawPassMessageStyle.normal.textColor = new Color (0.4f, 0.8f, 0.4f);

		drawCountPosition = new Rect (Screen.width * 0.5f - (SCREEN_GAP * 3 + 100.0f + 50.0f) * screenGuiFactor, (100.0f * 0.5f + SCREEN_GAP - 20.0f) * screenGuiFactor, 100.0f * screenGuiFactor, 40.0f * screenGuiFactor);
		drawCountStyle = new GUIStyle (GUI.skin.label);
		drawCountStyle.font = font;
		drawCountStyle.fontSize = (int)(25.0f * screenGuiFactor);
		drawCountStyle.alignment = TextAnchor.MiddleCenter;

		// Player's score
		playerScorePosition = new Rect (SCREEN_GAP * screenGuiFactor, (SCREEN_GAP + 50.0f + SCREEN_GAP) * screenGuiFactor, 150.0f * screenGuiFactor, 90.0f * screenGuiFactor);
		playerScoreStyle = new GUIStyle (GUI.skin.label);
		playerScoreStyle.font = font;
		playerScoreStyle.fontSize = (int)(40.0f * screenGuiFactor);
		playerScoreStyle.alignment = TextAnchor.MiddleLeft;

		// Count of chips
		chipCountPosition = new Rect ((SCREEN_GAP + 100.0f) * screenGuiFactor, Screen.height - (SCREEN_GAP + 100.0f + SCREEN_GAP * 2 + 100.0f * 0.5f) * screenGuiFactor, 80.0f * screenGuiFactor, 50.0f * screenGuiFactor);
		chipCountStyle = new GUIStyle (GUI.skin.label);
		chipCountStyle.font = font;
		chipCountStyle.fontSize = (int)(40.0f * screenGuiFactor);
		chipCountStyle.alignment = TextAnchor.MiddleLeft;
	}

	/**
	 * Method called by Unity to refresh the GUI.
	 */
	void OnGUI ()
	{
		// Setup the GUI
		GuiCreate ();

		// Display the menu button
		if (GUI.Button (menuButtonPosition, "MENU", menuButtonStyle)) {
			Application.LoadLevel ("Menu");
		}

		// Display the bingo button
		if (GUI.Button (bingoButtonPosition, "BINGO!", bingoButtonStyle) && bingoCanPlay && drawCanPlay) {
			bingoStateNext = BingoState.CHECK;
		}

		// Display the latest bingo results
		if (bingoResultsScroll) {
			bingoResultsScroll = false;
			bingoResultsOffset.y = bingoResultsSize.height;
		}
		bingoResultsOffset = GUI.BeginScrollView (bingoResultsPosition, bingoResultsOffset, bingoResultsSize, GUIStyle.none, GUIStyle.none);
		GUI.Box (bingoResultsSize, bingoResultsContent, bingoResultsStyle);
		GUI.EndScrollView ();

		// Display the draw information
		if (drawStateCurrent == DrawState.PLAY) {
			GUI.Label (drawTimerPosition, Mathf.RoundToInt (Settings.Instance.drawTimerPlay - drawStateTimeDuration) + "s", drawTimerStyle);
			if (Settings.Instance.drawCanPass) {
				GUI.Label (drawPassMessagePosition, "(Tap to pass)", drawPassMessageStyle);
			}
		}
		if (drawCardIndex < drawCardCount) {
			GUI.Label (drawCountPosition, "(" + (drawCardCount - drawCardIndex) + "/" + drawCardCount + ")", drawCountStyle);
		}

		// Display the player's score
		GUI.Label (playerScorePosition, "Score:\n" + playerScoreDisplay, playerScoreStyle);

		// Display the count of chips
		GUI.Label (chipCountPosition, "x" + chipCountDisplay, chipCountStyle);

		// Display the countdown (if any)
		if (countdownValue != null) {
			GUI.Label (countdownPosition, countdownValue, countdownStyle);
		}
	}
}
