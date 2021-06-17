using UnityEngine;
using System.Collections.Generic;

public class Game : MonoBehaviour
{
	// TODO:
	// * Add a point counter on screen so that we better know what combinations were made?
	// * Display and animate the name of the combinations found (independent animation system).
	// * (end)

	// Private members: animation constants
	const float dealAnimationDuration = 0.4f;
	const float dealAnimationRowDelay = 0.1f;

	// Private members: deck of cards
	List <Card> deck = null;

	// Private members: state machine
	bool stateMode12Hands;
	enum State
	{
		unknown = 0,
		deal,
		play,
		waitBeforeDiscard,
		discard,
		draw,
		countOnePair,
		showOthers,
		showAll,
		waitBeforeCleanup,
		cleanup
	};
	State stateCurrent;
	State stateNext;
	float stateStartTime;
	int stateHandIndex;
	int stateCountOnePair;

	// Private members: touch events
	enum TouchState
	{
		begin,
		move,
		end,
		nothing
	};
	TouchState touchState;
	Vector2 touchPosition;

	/**
	 * Method called by Unity after that the GameObject has been instantiated.
	 * This is the place where we initialize everything.
	 */
	void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Test the poker hand checker
//		Poker.Test (2, 10000000, 1);
//		Poker.Test (new string [] {"AS", "KS", "QS", "JS", "TS"});

		// Initialize the PRNG (to shuffle the cards)
		Math.RandSeed ();

		// Create a deck of cards
		deck = Card.CreateDeck (2);

		// Initialize the state machine
		stateNext = State.deal;
	}

	/**
	 * Handle the touch events.
	 */
	void UpdateTouch ()
	{
#if UNITY_IPHONE || UNITY_ANDROID
		if (Input.touchCount == 0) {
			touchState = TouchState.nothing;
		} else {
			Touch touch = Input.GetTouch (0);
			touchPosition = touch.position;
			switch (touch.phase) {
			case TouchPhase.Began:
				touchState = TouchState.begin;
				break;
			case TouchPhase.Moved:
			case TouchPhase.Stationary:
				touchState = TouchState.move;
				break;
			case TouchPhase.Canceled:
			case TouchPhase.Ended:
				touchState = TouchState.end;
				break;
			}
		}
#else
		touchPosition = Input.mousePosition;
		if (Input.GetMouseButtonDown (0)) {
			touchState = TouchState.begin;
		} else if (Input.GetMouseButtonUp (0)) {
			touchState = TouchState.end;
		} else if (Input.GetMouseButton (0)) {
			touchState = TouchState.move;
		} else {
			touchState = TouchState.nothing;
		}
#endif
	}

	/**
	 * Animate the card rows.
	 *
	 * @param appear True if the cards must appear, false if they shall disappear.
	 * @param time Time (starting at 0).
	 * @return True if the animation is finished, false otherwise.
	 */
	bool AnimateCardRows (bool appear, float time)
	{
		// Make the cards appear/disappear, row per row
		float angle = time * Mathf.PI * 0.5f / dealAnimationDuration;
		for (int index = 0; index < 5; ++index) {
			float clampedAngle = Mathf.Clamp (angle, 0.0f, Mathf.PI * 0.5f);
			Card.rowShift [index] = Card.rowShiftCardsHidden * (1.0f - (appear ? Mathf.Sin (clampedAngle) : Mathf.Cos (clampedAngle)));
			angle -= dealAnimationRowDelay;
		}

		// Check whether the last row is in place
		return (angle > Mathf.PI * 0.5f);
	}

	/**
	 * Method called by Unity at every frame.
	 */
	void Update ()
	{
		// Handle the user inputs
		UpdateTouch ();

		// Animate the material used to highlight the cards
		float tint = 0.8f + 0.2f * Mathf.Sin (Time.frameCount * 0.2f);
		Sprite.SetMaterialColor (4, new Color (tint, tint, tint, 1.0f));

		// Handle changes of state
		if (stateCurrent != stateNext) {

			// Exit the current state
			switch (stateCurrent) {
			case State.countOnePair:
				Debug.Log (stateCountOnePair + " " + Poker.Combination.OnePair);
				break;
			}

			// Change the state
			stateCurrent = stateNext;
			stateStartTime = Time.time;

			// Enter the current state
			switch (stateCurrent) {
			case State.deal:
				Poker.Shuffle (deck);
				bool wasStateMode12Hands = stateMode12Hands;
				stateMode12Hands = touchState != TouchState.nothing;
				if (stateMode12Hands) {
					for (int cardIndex = 0; cardIndex < 25; ++cardIndex) {
						deck [cardIndex].MoveOnBoard (cardIndex);
					}
				} else {
					for (int cardIndex = 5; cardIndex < 20; ++cardIndex) {
						deck [cardIndex].MoveOnBoard (cardIndex);
					}
					if (wasStateMode12Hands) {
						for (int cardIndex = 0; cardIndex < 5; ++cardIndex) {
							Card.RemoveFromBoard (cardIndex);
							Card.RemoveFromBoard (cardIndex + 20);
						}
					}
				}
				Card.maskHighlighted = 0;
				Card.maskEnabled = (1 << 26) - 1;
				Card.maskLocked = 0;
				break;
			case State.waitBeforeDiscard:
				Card.maskEnabled = 0;
				break;
			case State.draw:
				if (stateMode12Hands) {
					for (int cardIndex = 0; cardIndex < 25; ++cardIndex) {
						deck [cardIndex + 25].MoveOnBoard (cardIndex);
					}
				} else {
					for (int cardIndex = 5; cardIndex < 20; ++cardIndex) {
						deck [cardIndex + 25].MoveOnBoard (cardIndex);
					}
				}
				break;
			case State.countOnePair:
				Card.CheckHands ();
				stateHandIndex = 0;
				stateCountOnePair = 0;
				Card.maskHighlighted = 0;
				Card.maskLocked = 0;
				break;
			case State.showOthers:
				stateHandIndex = 0;
				break;
			case State.showAll:
				Card.CheckHands ();
				stateHandIndex = 0;
				Card.maskHighlighted = 0;
				Card.maskLocked = 0;
				break;
			case State.waitBeforeCleanup:
				Card.maskHighlighted = 0;
				Card.maskEnabled = 0;
				Card.maskBars = 0;
				break;
			}
		}

		// Execute the current state
		float stateTime = Time.time - stateStartTime;
		switch (stateCurrent) {
		case State.deal:
			if (AnimateCardRows (true, stateTime)) {
				stateNext = State.play;
			}
			break;
		case State.play:
			if (touchState == TouchState.begin) {
				int boardIndex = Card.ScreenToBoardIndex (touchPosition);
				if (stateMode12Hands) {
					if (boardIndex != -1) {
						uint mask = 1U << boardIndex;
						Card.maskHighlighted ^= mask;
						Card.maskEnabled ^= mask;
						Card.maskLocked ^= mask;
						if (Math.BitCount (Card.maskLocked) >= 5) {
							stateNext = State.waitBeforeDiscard;
						}
					}
				} else {
					if (boardIndex >= 5 && boardIndex < 20) {
						uint mask = 1U << boardIndex;
						Card.maskHighlighted ^= mask;
						Card.maskEnabled ^= mask;
						Card.maskLocked ^= mask;
					} else {
						stateNext = State.waitBeforeDiscard;
					}
				}
			}
			break;
		case State.waitBeforeDiscard:
			if (stateTime > 0.5f) {
				stateNext = State.discard;
			}
			break;
		case State.discard:
			if (AnimateCardRows (false, stateTime)) {
				stateNext = State.draw;
			}
			break;
		case State.draw:
			if (AnimateCardRows (true, stateTime)) {
				stateNext = stateMode12Hands ? State.countOnePair : State.showAll;
			}
			break;
		case State.countOnePair:
			if (Card.maskEnabled == 0 || stateTime > 0.1f) {
				stateNext = State.showOthers;
				while (stateHandIndex < Card.boardHands.Length) {
					BoardHand boardHand = Card.boardHands [stateHandIndex++];
					if (boardHand.combination == Poker.Combination.OnePair) {
						++stateCountOnePair;
						Card.maskHighlighted |= boardHand.mask;
						Card.maskEnabled |= boardHand.mask;
						Card.maskBars |= 1U << (stateHandIndex - 1);
						stateNext = State.countOnePair;
						stateStartTime = Time.time;
						break;
					}
				}
			}
			break;
		case State.showOthers:
			if (Card.maskEnabled == 0 || stateTime > 1.0f) {
				stateNext = State.waitBeforeCleanup;
				while (stateHandIndex < Card.boardHands.Length) {
					BoardHand boardHand = Card.boardHands [stateHandIndex++];
					if ((int)boardHand.combination < (int)Poker.Combination.OnePair) {
						Card.maskHighlighted = boardHand.mask;
						Card.maskEnabled = boardHand.mask;
						Card.maskBars = 1U << (stateHandIndex - 1);
						Debug.Log (boardHand.combination);
						stateNext = State.showOthers;
						stateStartTime = Time.time;
						break;
					}
				}
			}
			break;
		case State.showAll:
			if (Card.maskEnabled == 0 || stateTime > 1.0f) {
				stateNext = State.waitBeforeCleanup;
				while (stateHandIndex < Card.boardHands.Length) {
					BoardHand boardHand = Card.boardHands [stateHandIndex++];
					if (boardHand.combination != Poker.Combination.HighCard) {
						Card.maskHighlighted = boardHand.mask;
						Card.maskEnabled = boardHand.mask;
						Card.maskBars = 1U << (stateHandIndex - 1);
						Debug.Log (boardHand.combination);
						stateNext = State.showAll;
						stateStartTime = Time.time;
						break;
					}
				}
			}
			break;
		case State.waitBeforeCleanup:
			if (stateTime > 0.5f) {
				stateNext = State.cleanup;
			}
			break;
		case State.cleanup:
			if (AnimateCardRows (false, stateTime)) {
				stateNext = State.deal;
			}
			break;
		}

		// Display all the cards
		Card.DisplayBoard ();
	}
}
