extends LevelBase

var input := InputLocal.new()

func _process(delta: float) -> void:
	process_simulation(delta)

func left_move_up() -> bool:
	return input.left_move_up()

func left_move_down() -> bool:
	return input.left_move_down()

func right_move_up() -> bool:
	return input.right_move_up()

func right_move_down() -> bool:
	return input.right_move_down()