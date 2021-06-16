using UnityEngine;
using System.Text;

public struct Element
{
	public string name;
	public int[] pointIndexes;
	public int[] pointCounts;
}

public class NamedClassesGenerator
{
	// There are 4 levels for each element
	const int LEVEL_COUNT = 4;
	static readonly string[] LEVEL_NAMES = new string [LEVEL_COUNT] {"1-2-3", "4-5-6", "7-8-9", "10-11-12"};

	// All gestures are made of a serie of segments which the ends are taken from a small group of points
	static readonly Vector2[] points = new Vector2 [] {
		new Vector2 (0.0f, 4.0f),
		new Vector2 (0.0f, 3.0f),
		new Vector2 (0.0f, 2.0f),
		new Vector2 (0.0f, 1.0f),
		new Vector2 (0.0f, 0.0f),
		new Vector2 (3.0f, 4.0f),
		new Vector2 (3.0f, 2.0f),
		new Vector2 (3.0f, 0.0f),
		new Vector2 (1.5f, 4.0f),
	};

	// Each element has a name and is associated a full gesture (a list of points); levels define how many points must be considered
	static readonly Element[] elements = new Element [] {
		new Element {name = "Fire", pointIndexes = new int [] {5, 0, 4 ,5 ,2, 6}, pointCounts = new int [LEVEL_COUNT] {3, 4, 5, 6}},
		new Element {name = "Water", pointIndexes = new int [] {5, 1, 6, 3, 7, 5, 0}, pointCounts = new int [LEVEL_COUNT] {3, 5, 6, 7}},
		new Element {name = "Air", pointIndexes = new int [] {4, 8, 7, 4, 6, 2}, pointCounts = new int [LEVEL_COUNT] {3, 4, 5, 6}},
		new Element {name = "Earth", pointIndexes = new int [] {7, 4, 0, 5, 2, 6}, pointCounts = new int [LEVEL_COUNT] {3, 4, 5, 6}},
		new Element {name = "Light", pointIndexes = new int [] {0, 4, 7, 2, 6, 4}, pointCounts = new int [LEVEL_COUNT] {3, 4, 5, 6}},
		new Element {name = "Dark", pointIndexes = new int [] {0, 4, 6, 0, 5, 6}, pointCounts = new int [LEVEL_COUNT] {3, 4, 5, 6}},
		new Element {name = "None", pointIndexes = new int [] {0, 7, 5, 4, 0, 5}, pointCounts = new int [LEVEL_COUNT] {3, 4, 5, 6}},
//		new Element {name = "TEST-A1", pointIndexes = new int [] {1, 0, 5, 7, 4, 1}, pointCounts = new int [LEVEL_COUNT] {3, 4, 5, 6}},
//		new Element {name = "TEST-A2", pointIndexes = new int [] {3, 0, 5, 7, 4, 3}, pointCounts = new int [LEVEL_COUNT] {3, 4, 5, 6}},
//		new Element {name = "TEST-B1", pointIndexes = new int [] {0, 5, 1, 6, 7, 4, 0}, pointCounts = new int [LEVEL_COUNT] {4, 5, 6, 7}},
//		new Element {name = "TEST-B2", pointIndexes = new int [] {0, 5, 6, 3, 7, 4, 0}, pointCounts = new int [LEVEL_COUNT] {4, 5, 6, 7}},
	};

	// We also have an "escape" gesture...
	static int[] escapePointIndexes = new int [] {5, 8, 0};

	/**
	 * Add a new class to a string.
	 *
	 * @param namedClasses String to which the new class shall be added.
	 * @param name Name of the new class.
	 * @param gestureRecognition Gesture recognition instance to which points of the new class have been added.
	 */
	static void AddClass (StringBuilder namedClasses, string name, GestureRecognition gestureRecognition)
	{
		// Get the list of features
		gestureRecognition.Classify ();
		float [] features = gestureRecognition.GetLastFeatures ();

		// Append these features to the string
		if (features != null && features.Length > 0) {
			namedClasses.Append ("\n\t\tnew NamedClass {name = \"" + name + "\", features = new float [] {");
			int featureIndex = 0;
			while (featureIndex < features.Length - 1) {
				namedClasses.Append (features [featureIndex++] + "f, ");
			}
			namedClasses.Append (features [featureIndex] + "f}},");
		}
	}

	/**
	 * Generate the array "namedClasses" that describes all our gestures.
	 */
	static public void GenerateNamedClasses ()
	{
		// Initialize a string builder to generate the array "namedClasses"
		StringBuilder namedClasses = new StringBuilder ();
		namedClasses.Append ("\tstatic readonly NamedClass[] namedClasses = new NamedClass [] {");

		// Initialize the gesture recognizer
		// Important: we don't use any filter here, as all our template classes are "perfect" and made of a minimum set of points
		GestureRecognition gestureRecognition = new GestureRecognition (null, 0.0f, 0.1f);

		// Get the features of the "escape" gesture
		foreach (int pointIndex in escapePointIndexes) {
			gestureRecognition.AddPoint (points [pointIndex]);
		}
		AddClass (namedClasses, "Escape", gestureRecognition);

		// Get the features of all the elements
		foreach (Element element in elements) {
			for (int level = 0; level < LEVEL_COUNT; ++level) {
				for (int pointIndex = 0; pointIndex < element.pointCounts[level]; ++pointIndex) {
					gestureRecognition.AddPoint (points [element.pointIndexes [pointIndex]]);
				}
				AddClass (namedClasses, element.name + " " + LEVEL_NAMES [level], gestureRecognition);
			}
		}

		// Finalize the string, then display it in the log
		namedClasses.Append ("\n\t};");
		Debug.Log (namedClasses);
	}
}
