using UnityEngine;

public class RaymarchObject : MonoBehaviour {
    private Renderer renderer;

    public float extraData;

    private void Awake() {
        renderer = GetComponent<Renderer>();
    }
    public enum ShapeType {
        Circle = 0,
        Box = 1,
        Torus = 2,
        Capsule = 3
    }
    
    public Matrix4x4 worldToLocalMatrix { get {
            return renderer.worldToLocalMatrix;
    } }
    public Vector3 repetitions;
    public ShapeType type;
    public Color color;
}