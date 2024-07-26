using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UIElements;

public class SDFTest : MonoBehaviour {
    public Transform point;

    private void Update() {
        Vector3 pos = point.position;
        Vector4 pos4 = new(
            pos.x,
            pos.y,
            pos.z,
            1
        );
        Debug.Log(
            transform.worldToLocalMatrix.MultiplyPoint(
                pos4).magnitude <= .5);
    }
}