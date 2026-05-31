extends LevelBase

var input := InputLocal.new()

# AI state
var ai_target_y := 0.0
var ai_timer := 0.0
var ai_smoothed_y := 0.0
var ai_active_target := 0.0

var ai_reaction_delay := 0.15
var ai_error := 35.0
# | Уровень | reaction | error | результат      |
# | ------- | -------- | ----- | -------------- |
# | easy    | 0.25s    | 60px  | легко выиграть |
# | normal  | 0.15s    | 35px  | честная игра   |
# | hard    | 0.08s    | 10px  | почти машина   |


func _process(delta: float) -> void:
	process_simulation(delta)

	_update_ai(delta)

# LEFT = игрок
func left_move_up() -> float:
	return input.left_move_up()

func left_move_down() -> float:
	return input.left_move_down()

# RIGHT = AI
func right_move_up() -> float:
	return ai_active_target < right.global_position.y

func right_move_down() -> float:
	return ai_active_target > right.global_position.y

func predict_ball_y(at_x: float) -> float:
	var ball_pos = ball.global_position
	var dir = state.direction
	var speed = state.ball_speed

	# если мяч вообще не летит в сторону AI — не надо двигаться
	if dir.x <= 0:
		return ai_target_y

	var distance = at_x - ball_pos.x
	var time = distance / (dir.x * speed)

	var predicted_y = ball_pos.y + dir.y * speed * time
	return predicted_y

func reflect_y(y: float) -> float:
	var h = state.screen_size.y

	while y < 0 or y > h:
		if y < 0:
			y = -y
		elif y > h:
			y = h - (y - h)

	return y

func _update_ai(delta: float) -> void:
	ai_timer -= delta
	if ai_timer <= 0.0:
		ai_timer = ai_reaction_delay

		var raw_target = predict_ball_y(right.global_position.x)
		raw_target = reflect_y(raw_target)

		var noise = randf_range(-ai_error, ai_error)

		# ❗ НЕ ПЕРЕЗАПИСЫВАЕМ РЕЗКО TARGET
		var new_target = raw_target + noise

		# вместо этого — сглаживаем сам TARGET
		ai_target_y = lerp(ai_target_y, new_target, 0.4)

	ai_smoothed_y = lerp(ai_smoothed_y, ai_target_y, 8.0 * delta)
	ai_active_target = ai_smoothed_y
