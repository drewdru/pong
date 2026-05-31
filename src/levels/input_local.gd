extends RefCounted
class_name InputLocal

func left_move_up() -> float:
	return Input.get_action_strength("left_move_up")

func left_move_down() -> float:
	return Input.get_action_strength("left_move_down")

func right_move_up() -> float:
	return Input.get_action_strength("right_move_up")

func right_move_down() -> float:
	return Input.get_action_strength("right_move_down")