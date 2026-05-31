extends RefCounted
class_name InputLocal

func left_move_up() -> bool:
	return Input.is_action_pressed("left_move_up")

func left_move_down() -> bool:
	return Input.is_action_pressed("left_move_down")

func right_move_up() -> bool:
	return Input.is_action_pressed("right_move_up")

func right_move_down() -> bool:
	return Input.is_action_pressed("right_move_down")