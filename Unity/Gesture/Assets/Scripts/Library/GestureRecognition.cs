/*
 * Gesture Recognition - By Nrx
 *
 * This work is based on the paper "Specifying Gestures by Example" (Computer Graphics, Volume 25, Number 4, July 1991):
 * http://www.hci.iastate.edu/REU09/pub/Main/Multi-touchTableBlog/p329-rubine.pdf
 *
 * The idea is that for any given gesture, a set of features is computed and used to classify this gesture.
 *
 * The list of features is not the same as in the paper mentioned above (e.g. features which are related to a distance are
 * scaled using the dimensions of the bounding box, for the system to be "scale independent"; the angle of the last angle has
 * been added; etc.).
 *
 * 13 features are computed:
 *   0) Total gesture length (after scaling);
 *   1) Sum of the angles;
 *   2) Sum of the absolute value of the angles;
 *   3) Sum of the squared value of the angles;
 *   4) X coordinate of the vector between the first point and the center of mass (after scaling);
 *   5) Y coordinate of the vector between the first point and the center of mass (after scaling);
 *   6) Cosine of the first angle;
 *   7) Sine of the first angle;
 *   8) X coordinate of the vector between the last point and the center of mass (after scaling);
 *   9) Y coordinate of the vector between the last point and the center of mass (after scaling);
 *   10) Cosine of the last angle;
 *   11) Sine of the last angle;
 *   12) Angle of the bounding box diagonal.
 *
 * Instead of a linear discriminator and a set of training examples to classify a gesture, we simply use a single template for
 * each class and compute a score (the smallest score gives us the best matching class). The score of a class is given by the
 * sum of the squared difference of the standard scores:
 *
 *   a) Average
 *   average(feature) = SUM[class](feature[class]) / classCount
 *
 *   b) Variance
 *   variance(feature) = (SUM[class](feature[class] ^ 2) / classCount) - average(feature) ^ 2
 *   variance(feature) = (SUM[class](feature[class] ^ 2) - (SUM[class](feature[class]) ^ 2) / classCount) / classCount
 *
 *   c) Standard deviation
 *   standardDeviation(feature) = SQRT(variance(feature))
 *
 *   d) Standard score
 *   standardScore(value,feature) = (value - average(feature)) / standardDeviation(feature)
 *
 *   e) Error
 *   error(value,class,feature) = standardScore(value,feature) - standardScore(feature[class],feature)
 *   error(value,class,feature) = (value - feature[class]) / standardDeviation(feature)
 *
 *   f) Squared error
 *   squaredError(value,class,feature) = error(value,class,feature) ^ 2
 *   squaredError(value,class,feature) = (value - feature[class]) ^ 2 / variance(feature)
 *
 *   g) Scores
 *   scoreSquaredError(class) = SUM[feature](squaredError(value[feature],class,feature)) / featureCount
 *   scoreAbsError(class) = SUM[feature](ABS(error(value[feature],class,feature))) / featureCount
 */
using UnityEngine;
using System.Collections.Generic;

public class GestureRecognitonClass
{
	public float[] features;
}

public struct GestureRecognitionResults
{
	public struct Result
	{
		public GestureRecognitonClass reference;
		public float score;
	}
	public Result squaredError;
	public Result absError;
}

public class GestureRecognition
{
	// Constants
	const int FEATURE_COUNT = 13;
	const float DEFAULT_FILTER_COEFFICIENT = 0.5f;
	const float DEFAULT_MINIMUM_DISTANCE = 10.0f;
	const float MINIMUM_VARIANCE = 0.1f;

	// Classes
	class ReferencedClass : GestureRecognitonClass
	{
		public GestureRecognitonClass reference;
	}
	List<ReferencedClass> referencedClasses;

	// Points
	float pointFilterCoefficient;
	float pointMinimumDistance;
	int pointCount;
	Vector2 firstPoint;
	Vector2 previousFilteredPoint;
	Vector2 previousInputPoint;
	Vector2 previousSegment;
	Vector2 min;
	Vector2 max;
	Vector2 centerOfMass;

	// Features
	float[] features;
	float[] featuresVariance;
	float[] featuresStandardDeviation;
	enum FeaturesStatus
	{
		notComputed,
		available,
		error
	}
	FeaturesStatus featuresStatus;

	// Results
	static readonly GestureRecognitionResults resultsUnknown = new GestureRecognitionResults {
		squaredError = new GestureRecognitionResults.Result {reference = null, score = Mathf.Infinity},
		absError = new GestureRecognitionResults.Result {reference = null, score = Mathf.Infinity}
	};
	GestureRecognitionResults results;

	/**
	 * Constructor.
	 *
	 * @param _classes Features of all the classes that will serve to classify the gestures.
	 * @param filterCoefficient Coefficient of the point filter, between 0 (no filter) and 1 (all points are discarded).
	 * @param minimumDistance Minimum distance between a new point and the previous one for the new point to be taken into account.
	 */
	public GestureRecognition (GestureRecognitonClass[] _classes, float filterCoefficient = DEFAULT_FILTER_COEFFICIENT, float minimumDistance = DEFAULT_MINIMUM_DISTANCE)
	{
		// Take note of the parameters
		pointFilterCoefficient = Mathf.Clamp (filterCoefficient, 0.0f, 1.0f);
		pointMinimumDistance = Mathf.Max (0.0f, minimumDistance);

		// Copy the features of all the classes
		referencedClasses = new List<ReferencedClass> ();
		if (_classes != null) {
			foreach (GestureRecognitonClass _class in _classes) {
				if (_class.features != null && _class.features.Length == FEATURE_COUNT) {
					referencedClasses.Add (new ReferencedClass {reference = _class, features = (float[])_class.features.Clone ()});
				}
			}
		}

		// Initialize our list of features
		features = new float [FEATURE_COUNT];
		featuresStatus = FeaturesStatus.error;

		// Initialize the results
		results = resultsUnknown;

		// Compute the variance and standard deviation of each feature
		featuresVariance = new float [FEATURE_COUNT];
		featuresStandardDeviation = new float [FEATURE_COUNT];
		if (referencedClasses.Count != 0) {
			for (int featureIndex = 0; featureIndex < FEATURE_COUNT; ++featureIndex) {
				float sum = 0.0f;
				float sumSquare = 0.0f;
				foreach (ReferencedClass referencedClass in referencedClasses) {
					float feature = referencedClass.features [featureIndex];
					sum += feature;
					sumSquare += feature * feature;
				}
				float variance = Mathf.Max ((sumSquare - (sum * sum) / referencedClasses.Count) / referencedClasses.Count, MINIMUM_VARIANCE);
				featuresVariance [featureIndex] = variance;
				featuresStandardDeviation [featureIndex] = Mathf.Sqrt (variance);
			}
		}

		// Reset the gesture
		Reset ();
	}

	/**
	 * Get the list of features of the last gesture.
	 */
	public float [] GetLastFeatures ()
	{
		return featuresStatus == FeaturesStatus.available ? features : null;
	}

	/**
	 * Reset the gesture recognition (the next point to be added will be the 1st point of the gesture).
	 */
	public void Reset ()
	{
		pointCount = 0;
	}

	/**
	 * Add a point to the gesture.
	 *
	 * @param point Point to be added.
	 */
	public void AddPoint (Vector2 point)
	{
		if (pointCount == 0) {

			// Take note of this first point
			firstPoint = point;

			// Initialize the max and min values
			min = point;
			max = point;

			// Initialize some features
			features [0] = 0.0f;
			features [1] = 0.0f;
			features [2] = 0.0f;
			features [3] = 0.0f;
			centerOfMass = Vector2.zero;
			featuresStatus = FeaturesStatus.notComputed;

			// We just got our first point (which we didn't filter, of course)...
			previousFilteredPoint = point;
		} else {

			// Apply a basic filter
			Vector2 filteredPoint = point * (1.0f - pointFilterCoefficient) + previousInputPoint * pointFilterCoefficient;

			// Compute the segment
			Vector2 segment = filteredPoint - previousFilteredPoint;
			float length = segment.magnitude;

			// Make sure the distance with the previous registered point is big enough (or else, discard the new point)
			if (length < pointMinimumDistance) {
				return;
			}

			// Update the max and min values
			if (min.x > filteredPoint.x) {
				min.x = filteredPoint.x;
			} else if (max.x < filteredPoint.x) {
				max.x = filteredPoint.x;
			}
			if (min.y > filteredPoint.y) {
				min.y = filteredPoint.y;
			} else if (max.y < filteredPoint.y) {
				max.y = filteredPoint.y;
			}

			// Compute some features
			features [0] += length;
			if (pointCount == 1) {
				features [6] = segment.x / length;
				features [7] = segment.y / length;
			} else {
				float angle = Mathf.Atan2 (segment.x * previousSegment.y - segment.y * previousSegment.x, segment.x * previousSegment.x + segment.y * previousSegment.y);
				features [1] += angle;
				features [2] += Mathf.Abs (angle);
				features [3] += angle * angle;
			}
			centerOfMass += (filteredPoint + previousFilteredPoint) * length;

			// We just got a new filtered point and a segment...
			previousFilteredPoint = filteredPoint;
			previousSegment = segment;
		}

		// Whatever the case, we just got an input point...
		previousInputPoint = point;
		++pointCount;
	}

	/**
	 * Classify the gesture which the points have been added already.
	 *
	 * @return Result of the classification.
	 */
	public GestureRecognitionResults Classify ()
	{
		// Check whether all features have already been computed
		if (featuresStatus == FeaturesStatus.notComputed) {

			// Reset the results
			results = resultsUnknown;

			// Make sure we have enough points for the gesture to be classified
			if (pointCount < 3) {
				featuresStatus = FeaturesStatus.error;
			} else {

				// Compute some features
				centerOfMass /= 2 * features [0];
				Vector2 boundingBox = max - min;
				float scale = Mathf.Max (boundingBox.x, boundingBox.y);
				features [0] /= scale;
				firstPoint = (firstPoint - centerOfMass) / scale;
				features [4] = firstPoint.x;
				features [5] = firstPoint.y;
				previousFilteredPoint = (previousFilteredPoint - centerOfMass) / scale;
				features [8] = previousFilteredPoint.x;
				features [9] = previousFilteredPoint.y;
				float length = previousSegment.magnitude;
				features [10] = previousSegment.x / length;
				features [11] = previousSegment.y / length;
				features [12] = Mathf.Atan2 (boundingBox.y, boundingBox.x);
				featuresStatus = FeaturesStatus.available;

				// Classify the gesture
				foreach (ReferencedClass referencedClass in referencedClasses) {
					float scoreSquaredError = 0.0f;
					float scoreAbsError = 0.0f;
					for (int featureIndex = 0; featureIndex < FEATURE_COUNT; ++featureIndex) {
						float error = features [featureIndex] - referencedClass.features [featureIndex];
						scoreSquaredError += error * error / featuresVariance [featureIndex];
						scoreAbsError += Mathf.Abs (error) / featuresStandardDeviation [featureIndex];
					}
					if (scoreSquaredError < results.squaredError.score) {
						results.squaredError.score = scoreSquaredError;
						results.squaredError.reference = referencedClass.reference;
					}
					if (scoreAbsError < results.absError.score) {
						results.absError.score = scoreAbsError;
						results.absError.reference = referencedClass.reference;
					}
				}
				results.squaredError.score /= FEATURE_COUNT;
				results.absError.score /= FEATURE_COUNT;
			}

			// Reset the gesture recognition
			Reset ();
		}

		// Return the results
		return results;
	}
}
