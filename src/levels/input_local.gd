extends RefCounted
class_name InputLocal

var mouse_pressed := false
var mouse_start_y := 0.0
var mouse_current_y := 0.0

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_pressed = event.pressed

			if mouse_pressed:
				mouse_start_y = event.position.y
				mouse_current_y = event.position.y

	elif event is InputEventMouseMotion and mouse_pressed:
		mouse_current_y = event.position.y


func _mouse_drag(direction: int) -> float:
	if not mouse_pressed:
		return 0.0
	var delta := mouse_current_y - mouse_start_y
	if direction == -1: # up
		return clamp(-delta / 100.0, 0.0, 1.0)
	if direction == 1: # down
		return clamp(delta / 100.0, 0.0, 1.0)
	return 0.0


func left_move_up() -> float:
	return max(
		Input.get_action_strength("left_move_up"),
		_mouse_drag(-1)
	)

func left_move_down() -> float:
	return max(
		Input.get_action_strength("left_move_down"),
		_mouse_drag(1)
	)

func right_move_up() -> float:
	return Input.get_action_strength("right_move_up")

func right_move_down() -> float:
	return Input.get_action_strength("right_move_down")
