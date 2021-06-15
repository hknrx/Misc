// WARNING:
// This work is *only* for prototyping. In particular, the code is dirty and shall not be reused as-is.
using UnityEngine;

public class MenuController : MonoBehaviour
{
	// Screen
	const float SCREEN_GAP = 10;
	float screenGap;
	float screenGuiFactor;
	bool screenGuiSetup;

	// Font
	public Font font;

	// Page management
	enum Page
	{
		MAIN,
		HELP,
		SETTINGS,
		PAY_TABLE,
	}
	Page page;

	// Navigation buttons
	GUIStyle navigationButtonStyle;
	Rect navigationButtonPositionLeft;
	Rect navigationButtonPositionRight;

	// Start button
	GUIStyle startButtonStyle;
	Rect startButtonPosition;

	// Preset settings
	GUIStyle presetButtonStyle;
	class Preset
	{
		public string name;
		public int bingoDeckWildCount;
		public int bingoScoreBingo;
		public int bingoScoreDaub;
		public int[] bingoScoreHand;
		public int drawCardQuarterCount;
		public int drawTimerPlay;
		public bool drawCanPass;
		public int patternGroupMask;
		public int coinCountMax;
		public int coinAvailableMask;
		public int chipCountMax;
	}
	static readonly Preset[] presets = new Preset [] {
		new Preset {
			name = "Classic",
			bingoDeckWildCount = 2,
			bingoScoreBingo = 500,
			bingoScoreDaub = 10,
			bingoScoreHand = new int [] {5000, 5000, 3500, 2500, 2500, 2000, 1500, 500, 1000, 100, 0},
			drawCardQuarterCount = 1,
			drawTimerPlay = 5,
			drawCanPass = false,
			patternGroupMask = 7,
			coinCountMax = 3,
			coinAvailableMask = 7,
			chipCountMax = 25,
		},
		new Preset {
			name = "Bingo",
			bingoDeckWildCount = 0,
			bingoScoreBingo = 1000,
			bingoScoreDaub = 20,
			bingoScoreHand = new int [] {50, 50, 35, 25, 25, 20, 15, 5, 10, 1, 0},
			drawCardQuarterCount = 2,
			drawTimerPlay = 6,
			drawCanPass = true,
			patternGroupMask = 3,
			coinCountMax = 1,
			coinAvailableMask = 2,
			chipCountMax = 50,
		},
		new Preset {
			name = "Poker",
			bingoDeckWildCount = 2,
			bingoScoreBingo = 500,
			bingoScoreDaub = 10,
			bingoScoreHand = new int [] {10000, 10000, 7000, 5000, 5000, 4000, 3000, 1000, 2000, 100, -500},
			drawCardQuarterCount = 2,
			drawTimerPlay = 8,
			drawCanPass = true,
			patternGroupMask = 7,
			coinCountMax = 3,
			coinAvailableMask = 7,
			chipCountMax = 50,
		},
		new Preset {
			name = "Race 1",
			bingoDeckWildCount = 0,
			bingoScoreBingo = 1000,
			bingoScoreDaub = 20,
			bingoScoreHand = new int [] {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			drawCardQuarterCount = 1,
			drawTimerPlay = 2,
			drawCanPass = false,
			patternGroupMask = 48,
			coinCountMax = 0,
			coinAvailableMask = 0,
			chipCountMax = 20,
		},
		new Preset {
			name = "Race 2",
			bingoDeckWildCount = 0,
			bingoScoreBingo = 0,
			bingoScoreDaub = 1,
			bingoScoreHand = new int [] {500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500},
			drawCardQuarterCount = 0,
			drawTimerPlay = 2,
			drawCanPass = false,
			patternGroupMask = 48,
			coinCountMax = 0,
			coinAvailableMask = 0,
			chipCountMax = 20,
		},
		new Preset {
			name = "Optimize",
			bingoDeckWildCount = 4,
			bingoScoreBingo = 500,
			bingoScoreDaub = 10,
			bingoScoreHand = new int [] {5000, 5000, 3500, 2500, 2500, 2000, 1500, 500, 1000, 100, 0},
			drawCardQuarterCount = 3,
			drawTimerPlay = 5,
			drawCanPass = true,
			patternGroupMask = 7,
			coinCountMax = 2,
			coinAvailableMask = 7,
			chipCountMax = 8,
		},
		new Preset {
			name = "Crazy",
			bingoDeckWildCount = 6,
			bingoScoreBingo = 0,
			bingoScoreDaub = 5,
			bingoScoreHand = new int [] {5000, 5000, 3500, 2000, 2000, 1000, 500, -500, 0, -500, -1000},
			drawCardQuarterCount = 1,
			drawTimerPlay = 4,
			drawCanPass = false,
			patternGroupMask = 392,
			coinCountMax = 4,
			coinAvailableMask = 15,
			chipCountMax = 25,
		},
		new Preset {
			name = "King",
			bingoDeckWildCount = 2,
			bingoScoreBingo = 0,
			bingoScoreDaub = 1,
			bingoScoreHand = new int [] {0, 5000, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			drawCardQuarterCount = 2,
			drawTimerPlay = 8,
			drawCanPass = true,
			patternGroupMask = 7,
			coinCountMax = 2,
			coinAvailableMask = 15,
			chipCountMax = 30,
		},
	};

	// Summaries
	GUIStyle summaryLabelsStyle;
	GUIStyle summaryValuesStyle;
	Rect summaryPayTablePosition;
	GUIContent summaryPayTableLabels;
	System.Text.StringBuilder summaryPayTableValues;
	Rect summarySettingsPosition;
	GUIContent summarySettingsLabels;
	System.Text.StringBuilder summarySettingsValues;

	// Help text
	GUIStyle helpTextStyle;
	Rect helpTextPosition;
	static readonly string helpText = @"Poker cards are drawn at a constant speed, one at a time, at the top of the screen. Everytime a card is drawn, you can daub 1 card of same rank on your bingo card (the suit doesn't matter). One daub action costs 1 poker chip; if you don't have any chip left, you can still un-daub some cards to get some chips back...

Once you have formed one of the win patterns, you can press the Bingo! button to score: you will be awarded a fixed amount of points everytime you do a bingo, regardless of the poker hands... but you will also get bonus points depending on each poker hand you make!

Once the draw pile is exhausted, the game ends. You'll score additional points for all daubed cards.

You can use special coins on the right side of the screen, one at a time, to hopefully get special actions! But beware that these special coins can also make you lose chips!";

	// Settings
	Settings settings;
	static readonly string[] settingsDrawCardQuarterDescription = new string [] {"1/4", "1/2", "3/4", "ALL"};
	static readonly string[] settingsCoinDescription = new string [] {"Wild", "Star", "Swap", "S-Wild"};
	const int SETTINGS_PATTERN_COUNT = 9;
	Rect settingsPosition;
	GUIStyle settingsStyleLabel;
	GUIStyle settingsStyleSlider;
	GUIStyle settingsStyleSliderThumb;
	GUIStyle settingsStyleToggle;
	GUIStyle settingsStyleTextField;

	/**
	 * Method called by Unity after that the GameObject has been instantiated.
	 * This is the place where we initialize everything.
	 */
	void Start ()
	{
		// Set the target frame rate
		Application.targetFrameRate = 60;

		// Compute the zoom factor to respect the design of the screen layout
		screenGuiFactor = Screen.height / (Camera.main.orthographicSize * 2);
		screenGap = SCREEN_GAP * screenGuiFactor;

		// Initialize the settings once
		settings = Settings.Instance;
		if (!settings.isInitialized) {
			PresetUse (presets [0]);
			settings.isInitialized = true;
		}
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

		// Navigation buttons
		navigationButtonPositionLeft = new Rect (screenGap, Screen.height - screenGap - 50 * screenGuiFactor, 180 * screenGuiFactor, 50 * screenGuiFactor);
		navigationButtonPositionRight = new Rect (Screen.width - screenGap - navigationButtonPositionLeft.width, navigationButtonPositionLeft.y, navigationButtonPositionLeft.width, navigationButtonPositionLeft.height);
		navigationButtonStyle = new GUIStyle (GUI.skin.button);
		navigationButtonStyle.font = font;
		navigationButtonStyle.fontSize = (int)(24 * screenGuiFactor);

		// Start button
		startButtonPosition = new Rect (Screen.width * 0.5f - 160 * screenGuiFactor, Screen.height - screenGap - 100 * screenGuiFactor, 320 * screenGuiFactor, 100 * screenGuiFactor);
		startButtonStyle = new GUIStyle (GUI.skin.button);
		startButtonStyle.font = font;
		startButtonStyle.fontSize = (int)(80 * screenGuiFactor);

		// Preset buttons
		presetButtonStyle = new GUIStyle (GUI.skin.button);
		presetButtonStyle.font = font;
		presetButtonStyle.fontSize = (int)(30 * screenGuiFactor);

		// Summaries
		summaryLabelsStyle = new GUIStyle (GUI.skin.box);
		summaryLabelsStyle.font = font;
		summaryLabelsStyle.fontSize = (int)(22 * screenGuiFactor);
		summaryLabelsStyle.alignment = TextAnchor.UpperLeft;
		summaryLabelsStyle.padding = new RectOffset ((int)screenGap, (int)screenGap, (int)screenGap, (int)screenGap);
		summaryLabelsStyle.normal.textColor = Color.yellow;

		summaryValuesStyle = new GUIStyle (GUI.skin.label);
		summaryValuesStyle.font = font;
		summaryValuesStyle.fontSize = (int)(22 * screenGuiFactor);
		summaryValuesStyle.alignment = TextAnchor.UpperRight;
		summaryValuesStyle.padding = new RectOffset ((int)screenGap, (int)screenGap, (int)screenGap, (int)screenGap);
		summaryValuesStyle.normal.textColor = Color.yellow;

		float summaryWidth = 300 * screenGuiFactor;
		System.Text.StringBuilder summaryPayTableText = new System.Text.StringBuilder ("Bingo:\n");
		for (int combinationIndex = (int)Poker.Combination.HighCard; combinationIndex >= 0; --combinationIndex) {
			summaryPayTableText.AppendLine ((Poker.Combination)combinationIndex + ":");
		}
		summaryPayTableText.Append ("Daubed card:");

		summaryPayTableLabels = new GUIContent (summaryPayTableText.ToString ());
		summaryPayTablePosition = new Rect (Screen.width - screenGap - summaryWidth, screenGap, summaryWidth, summaryLabelsStyle.CalcHeight (summaryPayTableLabels, summaryWidth));
		SummaryPayTableUpdate ();

		summarySettingsLabels = new GUIContent ("Wild cards:\nDraw deck size:\nDraw speed:\nCan pass:\nWin patterns:");
		summarySettingsPosition = new Rect (summaryPayTablePosition.x, summaryPayTablePosition.y + summaryPayTablePosition.height + screenGap, summaryWidth, summaryLabelsStyle.CalcHeight (summarySettingsLabels, summaryWidth));
		SummarySettingsUpdate ();

		// Help text
		helpTextPosition = new Rect (screenGap, screenGap, Screen.width - screenGap * 2, navigationButtonPositionLeft.y - screenGap * 2);
		helpTextStyle = new GUIStyle (GUI.skin.box);
		helpTextStyle.font = font;
		helpTextStyle.fontSize = (int)(27 * screenGuiFactor);
		helpTextStyle.alignment = TextAnchor.UpperLeft;
		helpTextStyle.padding = new RectOffset ((int)screenGap, (int)screenGap, (int)screenGap, (int)screenGap);
		helpTextStyle.wordWrap = true;

		// Settings
		settingsPosition = new Rect (screenGap, screenGap, Screen.width - screenGap * 2, navigationButtonPositionLeft.y - screenGap * 2);

		settingsStyleLabel = new GUIStyle (GUI.skin.label);
		settingsStyleLabel.font = font;
		settingsStyleLabel.fontSize = (int)(30 * screenGuiFactor);

		settingsStyleSlider = new GUIStyle (GUI.skin.horizontalSlider);
		settingsStyleSlider.fixedHeight = (int)(24 * screenGuiFactor);
		settingsStyleSlider.overflow.top -= (int)(10 * screenGuiFactor);
		settingsStyleSlider.overflow.bottom += (int)(10 * screenGuiFactor);

		settingsStyleSliderThumb = new GUIStyle (GUI.skin.horizontalSliderThumb);
		settingsStyleSliderThumb.fixedWidth = (int)(28 * screenGuiFactor);
		settingsStyleSliderThumb.fixedHeight = (int)(24 * screenGuiFactor);
		settingsStyleSliderThumb.overflow.top -= (int)(10 * screenGuiFactor);
		settingsStyleSliderThumb.overflow.bottom += (int)(10 * screenGuiFactor);

		settingsStyleToggle = new GUIStyle (GUI.skin.toggle);
		settingsStyleToggle.font = font;
		settingsStyleToggle.fontSize = (int)(30 * screenGuiFactor);
		settingsStyleToggle.padding.left = (int)(30 * screenGuiFactor);

		settingsStyleTextField = new GUIStyle (GUI.skin.textField);
		settingsStyleTextField.font = font;
		settingsStyleTextField.fontSize = (int)(30 * screenGuiFactor);
		settingsStyleTextField.alignment = TextAnchor.MiddleRight;
		settingsStyleTextField.padding = new RectOffset ((int)screenGap, (int)screenGap, (int)screenGap, (int)screenGap);
	}

	/**
	 * Method called by Unity to refresh the GUI.
	 */
	void OnGUI ()
	{
		// Setup the GUI
		GuiCreate ();

		// Display the appropriate page
		switch (page) {
		case Page.MAIN:
			DisplayMainPage ();
			break;
		case Page.HELP:
			DisplayHelpPage ();
			break;
		case Page.SETTINGS:
			DisplaySettingsPage ();
			break;
		case Page.PAY_TABLE:
			DisplayPayTablePage ();
			break;
		}
	}

	/**
	 * Update the player settings.
	 */
	void PlayerSettingsUpdate ()
	{
		// Update the player settings
		settings.coinSelectedMask = settings.coinAvailableMask;
		settings.chipCount = settings.chipCountMax;
	}

	/**
	 * Use a preset.
	 *
	 * @param preset Preset to be used.
	 */
	void PresetUse (Preset preset)
	{
		// Copy the preset
		settings.bingoDeckWildCount = preset.bingoDeckWildCount;
		settings.bingoScoreBingo = preset.bingoScoreBingo;
		settings.bingoScoreDaub = preset.bingoScoreDaub;
		System.Array.Copy (preset.bingoScoreHand, settings.bingoScoreHand, preset.bingoScoreHand.Length);
		settings.drawCardQuarterCount = preset.drawCardQuarterCount;
		settings.drawTimerPlay = preset.drawTimerPlay;
		settings.drawCanPass = preset.drawCanPass;
		settings.patternGroupMask = preset.patternGroupMask;
		settings.coinCountMax = preset.coinCountMax;
		settings.coinAvailableMask = preset.coinAvailableMask;
		settings.chipCountMax = preset.chipCountMax;

		// Update the player settings
		PlayerSettingsUpdate ();
	}

	/**
	 * Update the pay table summary.
	 */
	void SummaryPayTableUpdate ()
	{
		// Update the pay table summary
		summaryPayTableValues = new System.Text.StringBuilder (settings.bingoScoreBingo.ToString ());
		summaryPayTableValues.AppendLine ();
		for (int combinationIndex = (int)Poker.Combination.HighCard; combinationIndex >= 0; --combinationIndex) {
			summaryPayTableValues.AppendLine (settings.bingoScoreHand [combinationIndex].ToString ());
		}
		summaryPayTableValues.Append (settings.bingoScoreDaub.ToString ());
	}

	/**
	 * Update the settings summary.
	 */
	void SummarySettingsUpdate ()
	{
		// Update the settings summary
		summarySettingsValues = new System.Text.StringBuilder (settings.bingoDeckWildCount.ToString ());
		summarySettingsValues.AppendLine ();
		summarySettingsValues.AppendLine (settingsDrawCardQuarterDescription [settings.drawCardQuarterCount]);
		summarySettingsValues.Append (settings.drawTimerPlay.ToString ());
		summarySettingsValues.AppendLine ("s");
		summarySettingsValues.AppendLine (settings.drawCanPass.ToString ());
		summarySettingsValues.Append (System.Convert.ToString (settings.patternGroupMask, 2).PadLeft (SETTINGS_PATTERN_COUNT, '0'));
	}

	/**
	 * Display the main page.
	 */
	void DisplayMainPage ()
	{
		// Display the settings button
		if (GUI.Button (navigationButtonPositionLeft, "<< SETTINGS", navigationButtonStyle)) {
			page = Page.SETTINGS;
		}

		// Display the help button
		if (GUI.Button (navigationButtonPositionRight, "HELP >>", navigationButtonStyle)) {
			page = Page.HELP;
		}

		// Display the start button
		if (GUI.Button (startButtonPosition, "START!", startButtonStyle)) {
			Application.LoadLevel ("Game");
		}

		// Pay table summary
		GUI.Label (summaryPayTablePosition, summaryPayTableLabels, summaryLabelsStyle);
		GUI.Label (summaryPayTablePosition, summaryPayTableValues.ToString (), summaryValuesStyle);

		// Common settings summary
		GUI.Label (summarySettingsPosition, summarySettingsLabels, summaryLabelsStyle);
		GUI.Label (summarySettingsPosition, summarySettingsValues.ToString (), summaryValuesStyle);

		// Preset buttons
		Rect rectLabel = new Rect (screenGap, screenGap, 150.0f * screenGuiFactor, 50 * screenGuiFactor);
		foreach (Preset preset in presets) {
			if (rectLabel.x + rectLabel.width + screenGap >= summaryPayTablePosition.x) {
				rectLabel.x = screenGap;
				rectLabel.y += rectLabel.height + screenGap;
			}
			if (GUI.Button (rectLabel, preset.name, presetButtonStyle)) {

				// Set all parameters
				PresetUse (preset);

				// Update the summaries
				SummarySettingsUpdate ();
				SummaryPayTableUpdate ();
			}
			rectLabel.x += rectLabel.width + screenGap;
		}

		// Coin selection
		rectLabel.x = screenGap;
		rectLabel.y += (rectLabel.height + screenGap) * 2;
		rectLabel.width = 140 * screenGuiFactor;
		rectLabel.height = 50 * screenGuiFactor;
		Rect rectToggle = new Rect (rectLabel.x + rectLabel.width + screenGap, rectLabel.y, 120 * screenGuiFactor, 50 * screenGuiFactor);

		GUI.Label (rectLabel, "Coins (" + settings.coinCountMax + "):", settingsStyleLabel);
		if (settings.coinCountMax > 0) {
			int mask = settings.coinSelectedMask;
			int coinSelectedCountBefore = Math.BitCount (mask);
			int coinSelectedCountAfter = 0;
			settings.coinSelectedMask = 0;
			for (int index = 0; index < settingsCoinDescription.Length; ++index) {
				int bit = 1 << index;
				if ((settings.coinAvailableMask & bit) != 0) {
					if (rectToggle.x + rectToggle.width + screenGap >= summaryPayTablePosition.x) {
						rectToggle.x = rectLabel.x + rectLabel.width + screenGap;
						rectToggle.y += rectLabel.height;
					}
					GUI.enabled = coinSelectedCountAfter < settings.coinCountMax && ((mask & bit) != 0 || coinSelectedCountBefore < settings.coinCountMax);
					if (GUI.Toggle (rectToggle, (mask & bit) != 0, settingsCoinDescription [index], settingsStyleToggle) && GUI.enabled) {
						settings.coinSelectedMask |= bit;
						++coinSelectedCountAfter;
					}
					rectToggle.x += rectToggle.width + screenGap;
				}
			}
			GUI.enabled = true;
		}

		// Chips
		rectLabel.y = rectToggle.y + rectToggle.height + screenGap;
		GUI.Label (rectLabel, "Chips:", settingsStyleLabel);
		float x = rectLabel.x + rectLabel.width + screenGap;
		settings.chipCount = Mathf.Min (settings.chipCountMax, settings.chipCount);
		if (settings.chipCountMax > 5) {
			Rect rectSlider = new Rect (x, rectLabel.y, 300 * screenGuiFactor, 50 * screenGuiFactor);
			settings.chipCount = Mathf.RoundToInt (GUI.HorizontalSlider (rectSlider, settings.chipCount, 5, settings.chipCountMax, settingsStyleSlider, settingsStyleSliderThumb));
			x += rectSlider.width + screenGap;
		}
		Rect rectValue = new Rect (x, rectLabel.y, 50 * screenGuiFactor, 50 * screenGuiFactor);
		GUI.Label (rectValue, settings.chipCount.ToString (), settingsStyleLabel);
	}

	/**
	 * Display the help page.
	 */
	void DisplayHelpPage ()
	{
		// Display the back button
		if (GUI.Button (navigationButtonPositionLeft, "<<", navigationButtonStyle)) {
			page = Page.MAIN;
		}

		// Display the help text
		GUI.Label (helpTextPosition, helpText, helpTextStyle);
	}

	/**
	 * Display the settings page.
	 */
	void DisplaySettingsPage ()
	{
		// Display the pay table button
		if (GUI.Button (navigationButtonPositionLeft, "<< PAY TABLE", navigationButtonStyle)) {
			page = Page.PAY_TABLE;
		}

		// Display the back button
		if (GUI.Button (navigationButtonPositionRight, ">>", navigationButtonStyle)) {
			SummarySettingsUpdate ();
			page = Page.MAIN;
		}

		// Create a group
		GUI.BeginGroup (settingsPosition);

		// Wild cards
		Rect rectLabel = new Rect (0, 0, 220 * screenGuiFactor, 50 * screenGuiFactor);
		Rect rectSlider = new Rect (rectLabel.x + rectLabel.width + screenGap, rectLabel.y, 360 * screenGuiFactor, 50 * screenGuiFactor);
		Rect rectValue = new Rect (rectSlider.x + rectSlider.width + screenGap, rectLabel.y, 80 * screenGuiFactor, 50 * screenGuiFactor);
		float width = rectValue.x + rectValue.width;

		GUI.color = Color.gray;
		GUI.Label (rectLabel, "Wild cards:", settingsStyleLabel);
		settings.bingoDeckWildCount = (int)(GUI.HorizontalSlider (rectSlider, settings.bingoDeckWildCount, 0, 6, settingsStyleSlider, settingsStyleSliderThumb) + 1) & ~1;
		GUI.Label (rectValue, settings.bingoDeckWildCount.ToString (), settingsStyleLabel);

		// Size of the draw deck
		rectLabel.y += rectLabel.height + screenGap;
		rectSlider.y = rectLabel.y;
		rectValue.y = rectLabel.y;

		GUI.Label (rectLabel, "Draw deck size:", settingsStyleLabel);
		settings.drawCardQuarterCount = Mathf.RoundToInt (GUI.HorizontalSlider (rectSlider, settings.drawCardQuarterCount, 0, settingsDrawCardQuarterDescription.Length - 1, settingsStyleSlider, settingsStyleSliderThumb));
		GUI.Label (rectValue, settingsDrawCardQuarterDescription [settings.drawCardQuarterCount], settingsStyleLabel);

		// Draw speed
		rectLabel.y += rectLabel.height + screenGap;
		rectSlider.y = rectLabel.y;
		rectValue.y = rectLabel.y;

		GUI.Label (rectLabel, "Draw speed:", settingsStyleLabel);
		settings.drawTimerPlay = Mathf.RoundToInt (GUI.HorizontalSlider (rectSlider, settings.drawTimerPlay, 2, 8, settingsStyleSlider, settingsStyleSliderThumb));
		GUI.Label (rectValue, settings.drawTimerPlay + "s", settingsStyleLabel);

		// Possibility to pass or not
		rectLabel.y += rectLabel.height + screenGap;
		Rect rectToggle = new Rect (rectLabel.x + rectLabel.width + screenGap, rectLabel.y, 120 * screenGuiFactor, 50 * screenGuiFactor);

		GUI.Label (rectLabel, "Can pass:", settingsStyleLabel);
		settings.drawCanPass = GUI.Toggle (rectToggle, settings.drawCanPass, settings.drawCanPass.ToString (), settingsStyleToggle);

		// Win patterns
		rectLabel.y += rectLabel.height + screenGap;
		rectToggle.y = rectLabel.y;
		rectToggle.width = 80 * screenGuiFactor;

		GUI.Label (rectLabel, "Win patterns:", settingsStyleLabel);
		int mask = settings.patternGroupMask;
		settings.patternGroupMask = 0;
		for (int index = 0; index < SETTINGS_PATTERN_COUNT;) {
			if (rectToggle.x + rectToggle.width > settingsPosition.width) {
				rectToggle.x = rectLabel.x + rectLabel.width + screenGap;
				rectToggle.y += rectLabel.height;
			}
			int bit = 1 << index;
			if (GUI.Toggle (rectToggle, (mask & bit) != 0, "#" + ++index, settingsStyleToggle)) {
				settings.patternGroupMask |= bit;
			}
			rectToggle.x += rectToggle.width;
			width = Mathf.Max (width, rectToggle.x);
			rectToggle.x += screenGap;
		}

		// Maximum number of coins
		rectLabel.y = rectToggle.y + rectToggle.height + screenGap;
		rectSlider.y = rectLabel.y;
		rectValue.y = rectLabel.y;

		GUI.Label (rectLabel, "Coins (max):", settingsStyleLabel);
		settings.coinCountMax = Mathf.RoundToInt (GUI.HorizontalSlider (rectSlider, settings.coinCountMax, 0, 4, settingsStyleSlider, settingsStyleSliderThumb));
		GUI.Label (rectValue, settings.coinCountMax.ToString (), settingsStyleLabel);

		// Available coins
		rectLabel.y += rectLabel.height + screenGap;
		rectToggle = new Rect (rectLabel.x + rectLabel.width + screenGap, rectLabel.y, 120 * screenGuiFactor, 50 * screenGuiFactor);

		GUI.Label (rectLabel, "Coins available:", settingsStyleLabel);
		mask = settings.coinAvailableMask;
		settings.coinAvailableMask = 0;
		for (int index = 0; index < settingsCoinDescription.Length; ++index) {
			if (rectToggle.x + rectToggle.width > settingsPosition.width) {
				rectToggle.x = rectLabel.x + rectLabel.width + screenGap;
				rectToggle.y += rectLabel.height;
			}
			int bit = 1 << index;
			if (GUI.Toggle (rectToggle, (mask & bit) != 0, settingsCoinDescription [index], settingsStyleToggle)) {
				settings.coinAvailableMask |= bit;
			}
			rectToggle.x += rectToggle.width;
			width = Mathf.Max (width, rectToggle.x);
			rectToggle.x += screenGap;
		}

		// Maximum number of chips
		rectLabel.y = rectToggle.y + rectToggle.height + screenGap;
		rectSlider.y = rectLabel.y;
		rectValue.y = rectLabel.y;

		GUI.Label (rectLabel, "Chips (max):", settingsStyleLabel);
		settings.chipCountMax = Mathf.RoundToInt (GUI.HorizontalSlider (rectSlider, settings.chipCountMax, 5, 50, settingsStyleSlider, settingsStyleSliderThumb));
		GUI.Label (rectValue, settings.chipCountMax.ToString (), settingsStyleLabel);

		// Close the group and adjust its position
		GUI.EndGroup ();
		settingsPosition.width = width;
		settingsPosition.x = (Screen.width - width) * 0.5f;
	}

	/**
	 * Display the pay table page.
	 */
	void DisplayPayTablePage ()
	{
		// Display the back button
		if (GUI.Button (navigationButtonPositionRight, ">>", navigationButtonStyle)) {
			SummaryPayTableUpdate ();
			page = Page.SETTINGS;
		}

		// Bingo
		Rect rectLabel = new Rect (0, screenGap, 200 * screenGuiFactor, 50 * screenGuiFactor);
		Rect rectValue = new Rect (0, rectLabel.y, 120 * screenGuiFactor, 50 * screenGuiFactor);
		rectLabel.x = (Screen.width - (rectLabel.width + screenGap + rectValue.width) * 2 - screenGap) / 2;
		rectValue.x = rectLabel.x + rectLabel.width;

		GUI.color = Color.gray;
		GUI.Label (rectLabel, "Bingo:", settingsStyleLabel);
		int.TryParse (GUI.TextField (rectValue, settings.bingoScoreBingo.ToString (), settingsStyleTextField), out settings.bingoScoreBingo);

		// Poker hands
		for (int combinationIndex = (int)Poker.Combination.HighCard; combinationIndex >= 0; --combinationIndex) {

			rectLabel.y += rectLabel.height + screenGap;
			if (rectLabel.y + rectLabel.height >= navigationButtonPositionRight.y - screenGap) {
				rectLabel.x = rectValue.x + rectValue.width + screenGap;
				rectValue.x = rectLabel.x + rectLabel.width + screenGap;
				rectLabel.y = screenGap;
			}
			rectValue.y = rectLabel.y;

			GUI.Label (rectLabel, (Poker.Combination)combinationIndex + ":", settingsStyleLabel);
			int.TryParse (GUI.TextField (rectValue, settings.bingoScoreHand [combinationIndex].ToString (), settingsStyleTextField), out settings.bingoScoreHand [combinationIndex]);
		}

		// Daubed card
		rectLabel.y += rectLabel.height + screenGap;
		rectValue.y = rectLabel.y;

		GUI.Label (rectLabel, "Daubed card:", settingsStyleLabel);
		int.TryParse (GUI.TextField (rectValue, settings.bingoScoreDaub.ToString (), settingsStyleTextField), out settings.bingoScoreDaub);
	}
}
