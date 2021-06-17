using UnityEngine;

public class TransparentParts : MonoBehaviour
{
	const float TIMER = 1.0f;
	float time;

	void OnCollisionEnter (Collision collision)
	{
		time = Time.time + TIMER;
	}

	void Update ()
	{
		GetComponent<Renderer>().enabled = Time.time < time;
	}
}
