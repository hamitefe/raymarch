using UnityEngine;

public class PlayerController : MonoBehaviour {
    public Transform camera;
    private Vector2 rotation;
    private Vector3 movement;

    public float speed, sensivity;
    private bool pause = false;

    private void Update() {
        if (Input.GetMouseButtonDown(0)) pause = false;
        if (Input.GetKeyDown(KeyCode.Escape)) pause = true;
        if (pause) {
            movement = Vector3.zero;
            return;
        }
        AssignMovements();
    }

    private void AssignMovements() {
        Cursor.lockState = CursorLockMode.Locked;
        rotation.x += Input.GetAxis("Mouse X") * sensivity;
        rotation.y += Input.GetAxis("Mouse Y") * sensivity;

        transform.eulerAngles = Vector3.up * rotation.x;
        camera.localEulerAngles = Vector3.left * rotation.y;

        movement = new Vector3(
            Input.GetAxis("Horizontal"),
            0,
            Input.GetAxis("Vertical")
        );
    }

    private void FixedUpdate() {
        transform.Translate(movement*Time.fixedDeltaTime*speed);
    }


}