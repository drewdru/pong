extends Node2D

@onready var ball = %ball
@onready var left = %left
@onready var right = %right
@onready var left_score_label = %left_score
@onready var right_score_label = %right_score

var state := GameState.new()
var input := InputLocal.new()

func _ready():
	state.setup(
		get_viewport_rect().size,
		left.get_texture().get_size()
	)

func process_ball(delta: float):
	var ball_pos = ball.global_position
	var left_rect = Rect2(left.global_position - state.pad_size * 0.5, state.pad_size)
	var right_rect = Rect2(right.global_position - state.pad_size * 0.5, state.pad_size)

	# Move ball
	ball_pos += state.direction * state.ball_speed * delta

	# Flip when touching roof or floor
	if ((ball_pos.y < 0 and state.direction.y < 0) or (ball_pos.y > state.screen_size.y and state.direction.y > 0)):
		state.direction.y = -state.direction.y

	# Flip, change direction and increase speed when touching pads
	if ((left_rect.has_point(ball_pos) and state.direction.x < 0) or (right_rect.has_point(ball_pos) and state.direction.x > 0)):
		state.direction.x = -state.direction.x
		state.direction.y = randf() * 2.0 - 1.0
		state.direction = state.direction.normalized()
		state.ball_speed *= 1.1

	ball.global_position = ball_pos

func process_game_state():
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

	ball.global_position = ball_pos

func process_left_pad(delta: float):
	var left_pos = left.global_position
	var speed = clamp(
		state.INITIAL_PAD_SPEED + 10 * state.game_round,
		state.INITIAL_PAD_SPEED,
		state.MAX_PAD_SPEED
	)

	if (left_pos.y > 0 and input.left_move_up()):
		left_pos.y += -speed * delta
	if (left_pos.y < state.screen_size.y and input.left_move_down()):
		left_pos.y += speed * delta

	left.global_position = left_pos

func process_right_pad(delta: float):
	var right_pos = right.global_position
	var speed = clamp(
		state.INITIAL_PAD_SPEED + 10 * state.game_round,
		state.INITIAL_PAD_SPEED,
		state.MAX_PAD_SPEED
	)

	if (right_pos.y > 0 and input.right_move_up()):
		right_pos.y += -speed * delta
	if (right_pos.y < state.screen_size.y and input.right_move_down()):
		right_pos.y += speed * delta

	right.global_position = right_pos

func _process(delta: float):
	process_ball(delta)
	process_game_state()
	process_left_pad(delta)
	process_right_pad(delta)
