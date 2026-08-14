extends Node2D
class_name LevelBase

@onready var ball = %ball
@onready var left = %left
@onready var right = %right
@onready var left_score_label = %left_score
@onready var right_score_label = %right_score
@onready var pause_menu = %pause_menu
@onready var beep_sound = %beep_sound
@onready var start_sound = %start_sound

var state := GameState.new()

func _ready() -> void:
	if OS.has_feature("web"):
		pause_menu.visible = false
	GameController.restart.connect(_on_restart)
	state.setup(
		get_viewport_rect().size,
		left.get_texture().get_size()
	)
	start_sound.play()

func process_ball(delta: float) -> void:
	var ball_pos = ball.global_position
	var left_rect = Rect2(left.global_position - state.pad_size * 0.5, state.pad_size)
	var right_rect = Rect2(right.global_position - state.pad_size * 0.5, state.pad_size)

	# Move ball
	ball_pos += state.direction * state.ball_speed * delta

	# Flip when touching roof or floor
	if ((ball_pos.y < 0 and state.direction.y < 0) or (ball_pos.y > state.screen_size.y and state.direction.y > 0)):
		state.direction.y = -state.direction.y
		beep_sound.play()
		state.sound_effect = 'beep_sound'

	# Flip, change direction and increase speed when touching pads
	if ((left_rect.has_point(ball_pos) and state.direction.x < 0) or (right_rect.has_point(ball_pos) and state.direction.x > 0)):
		state.direction.x = -state.direction.x
		state.direction.y = randf() * 2.0 - 1.0
		state.direction = state.direction.normalized()
		state.ball_speed *= 1.1
		beep_sound.play()
		state.sound_effect = 'beep_sound'

	ball.global_position = ball_pos

func process_game_state() -> void:
	var ball_pos = ball.global_position

	if ball_pos.x < 0:
		state.right_score += 1
		right_score_label.text = str(state.right_score)

	if ball_pos.x > state.screen_size.x:
		state.left_score += 1
		left_score_label.text = str(state.left_score)

	if (ball_pos.x < 0 or ball_pos.x > state.screen_size.x):
		ball_pos = state.screen_size * 0.5
		state.game_round += 1
		state.ball_speed = clamp(
			state.INITIAL_BALL_SPEED + 10 * state.game_round,
			state.INITIAL_BALL_SPEED,
			state.MAX_BALL_SPEED
		)
		start_sound.play()
		state.sound_effect = 'start_sound'

	ball.global_position = ball_pos

func process_pad(pad, move_up: float, move_down: float, delta: float) -> void:
	var pad_pos = pad.global_position

	var speed = clamp(
		state.INITIAL_PAD_SPEED + 10 * state.game_round,
		state.INITIAL_PAD_SPEED,
		state.MAX_PAD_SPEED
	)

	var input = move_down - move_up
	pad_pos.y += input * speed * delta
	var half_height = state.pad_size.y * 0.5

	if pad_pos.y < half_height:
		pad_pos.y = half_height
	elif pad_pos.y > state.screen_size.y - half_height:
		pad_pos.y = state.screen_size.y - half_height

	pad.global_position = pad_pos

func left_move_up() -> float:
	return 0.0

func left_move_down() -> float:
	return 0.0

func right_move_up() -> float:
	return 0.0

func right_move_down() -> float:
	return 0.0

func process_left_pad(delta: float) -> void:
	process_pad(left, left_move_up(), left_move_down(), delta)

func process_right_pad(delta: float) -> void:
	process_pad(right, right_move_up(), right_move_down(), delta)

func process_simulation(delta: float) -> void:
	state.sound_effect = ''
	process_ball(delta)
	process_game_state()
	process_left_pad(delta)
	process_right_pad(delta)

func _on_restart() -> void:
	state = GameState.new()
	state.setup(
		get_viewport_rect().size,
		left.get_texture().get_size()
	)
	start_sound.play()
	state.sound_effect = 'start_sound'
	ball.global_position = Vector2(320, 180)
	left.global_position = Vector2(67, 183)
	right.global_position = Vector2(577, 187)
	left_score_label.text = str(state.left_score)
	right_score_label.text = str(state.right_score)
	GameController.resume()
	if GameController.game_mode == 'local':
		if not OS.has_feature("web"):
			pause_menu.visible = false
		return
	if GameController.player_role == 'host':
		GameNetwork.send({
			"type": "pause",
			"is_game_on_pause": GameController.is_game_on_pause,
		})
	else:
		GameNetwork.send({ "type": "restart" })
		WebGameBridge.notify('WaitForHost')
	