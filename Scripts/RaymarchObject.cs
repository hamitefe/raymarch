using UnityEngine;

public class RaymarchObject : MonoBehaviour {
    public enum ShapeType {
        Circle = 0,
        Box = 1,
        Donut = 2
    }

    public float GetExtraData() {
        if (type == ShapeType.Donut) return transform.lossyScale.x;
        return 0;
    }
    
    public Matrix4x4 worldToLocalMatrix { get {
            return transform.worldToLocalMatrix;
    } }

    public ShapeType type;
    public Color color;
}