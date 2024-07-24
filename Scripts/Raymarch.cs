using System.Linq;
using UnityEditor;
using UnityEngine;
public class Raymarch : MonoBehaviour {
    public Camera cam;
    public Material mat;
    public RaymarchObject[] objects;
    public Transform light;
    public int iterations;
    public GUIStyle style, style2;
    private void OnRenderObject() {
        if (!cam) return;
        if (!mat) return;
        mat.SetMatrix("_CamFrustum", CamFrustum());
        mat.SetMatrix("_CamToWorld", cam.cameraToWorldMatrix);
        float[] types = new float[50];
        Matrix4x4[] matrices = new Matrix4x4[50];
        Color[] colors = new Color[50];

        for (int i = 0; i < objects.Length; i++) {
            var obj = objects[i];
            types[i] = (int)obj.type;
            colors[i] = obj.color;
            matrices[i] = obj.worldToLocalMatrix;
        }

        mat.SetMatrixArray("positions",matrices);
        mat.SetColorArray("colors", colors);
        mat.SetFloatArray("types", types);
        mat.SetInteger("objectCount", objects.Length);
        mat.SetVector("_Light", light.forward);
        mat.SetVector("_CamPosition", cam.transform.position);
        
    }
    private Matrix4x4 CamFrustum() {
        Vector3[] corners = new Vector3[4];
        cam.CalculateFrustumCorners(new Rect(0, 0, 1, 1),cam.nearClipPlane ,Camera.MonoOrStereoscopicEye.Mono, corners);
        Matrix4x4 mat = Matrix4x4.identity;
        mat.SetRow(0, corners[0]);
        mat.SetRow(1, corners[1]);
        mat.SetRow(2, corners[2]);
        mat.SetRow(3, corners[3]);
        return mat;
    }

}
