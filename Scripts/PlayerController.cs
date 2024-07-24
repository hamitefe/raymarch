using UnityEngine;

public class PlayerController : MonoBehaviour {
    private Vector2 movement;
    private Vector2 rotation;
    public float speed = 10, sensivity = 2;
    private bool locked = false;
    private void Update() {
        if (Input.GetKeyDown(KeyCode.Escape)) locked = true;
        else if (Input.GetMouseButtonDown(0)) locked = false;
        if (locked) {
            movement = Vector2.zero;
            return;
        }
        rotation.x += sensivity * Input.GetAxis("Mouse X");
        rotation.y += sensivity * Input.GetAxis("Mouse Y");
        movement.Set(
            Input.GetAxis("Horizontal"),
            Input.GetAxis("Vertical")
        );
        transform.eulerAngles = new Vector3(-rotation.y, rotation.x);
        Cursor.lockState = CursorLockMode.Locked;
        
    }

    private void FixedUpdate() {
        transform.Translate(
            speed *
            Time.fixedDeltaTime *
            new Vector3(movement.x, 0, movement.y)
        );

    }

}