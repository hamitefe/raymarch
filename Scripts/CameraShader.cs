using UnityEngine;

public class CameraShader : MonoBehaviour {
    public Material mat;

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (!mat) return;
        Graphics.Blit(source, destination, mat);
    }
}