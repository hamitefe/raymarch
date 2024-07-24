using UnityEngine;

public class RaymarchObject : MonoBehaviour {
    
    public enum ShapeType {
        Circle,
        Box
    }
    
    public Matrix4x4 worldToLocalMatrix { get {
            return transform.worldToLocalMatrix;
    } }

    public ShapeType type;
    public Color color;
}