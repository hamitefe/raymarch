using UnityEngine;

public class Spinning : MonoBehaviour {
    public Vector3 axes;
    public float speed;

    private void Update() {
        transform.eulerAngles = Time.time * speed * axes;
    }
}