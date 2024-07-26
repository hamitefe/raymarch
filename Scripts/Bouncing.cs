using UnityEngine;

public class Bouncing : MonoBehaviour {
    public float treshold;

    private void Update() {
        transform.localPosition = Mathf.Abs(Time.time % 2.0f - 1.0f) * treshold * Vector3.up;
    }
}