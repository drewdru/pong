extends Node2D

@onready var ball = %ball
@onready var left = %left
@onready var right = %right
@onready var left_score_label = %left_score
@onready var right_score_label = %right_score


# -------------------------
# GAME STATE (local copy)
# -------------------------
var screen_size: Vector2

var INITIAL_BALL_SPEED := 80.0
var MAX_BALL_SPEED := 300.0

var INITIAL_PAD_SPEED := 150.0
var MAX_PAD_SPEED := 400.0

var direction := Vector2(1, 0)
var ball_speed := INITIAL_BALL_SPEED

var left_score := 0
var right_score := 0
var game_round := 1


# remote input buffer (client → host)
var remote_input := {
	"up": false,
	"down": false
}


func _ready() -> void:
	screen_size = get_viewport_rect().size

	P2P.packet_received.connect(_on_p2p_packet_received)
	P2P.peer_connected.connect(_on_peer_connected)
	P2P.peer_disconnected.connect(_on_peer_disconnected)


func _process(delta: float) -> void:
	if P2P.is_host:
		_process_host(delta)
	else:
		_process_client(delta)


# =========================================================
# HOST LOGIC (authoritative simulation)
# =========================================================

func _process_host(delta: float) -> void:
	_process_ball(delta)
	_process_game_state()
	_process_paddles_host(delta)

	_send_state()


func _process_ball(delta: float) -> void:
	var ball_pos: Vector2 = ball.global_position

	var pad_size: Variant = left.get_texture().get_size()

	var left_rect := Rect2(left.global_position - pad_size * 0.5, pad_size)
	var right_rect := Rect2(right.global_position - pad_size * 0.5, pad_size)

	# move ball
	ball_pos += direction * ball_speed * delta

	# top/bottom bounce
	if (ball_pos.y < 0 and direction.y < 0) or (ball_pos.y > screen_size.y and direction.y > 0):
		direction.y = -direction.y

	# paddle collision
	if (left_rect.has_point(ball_pos) and direction.x < 0) or (right_rect.has_point(ball_pos) and direction.x > 0):
		direction.x = -direction.x
		direction.y = randf() * 2.0 - 1.0
		direction = direction.normalized()
		ball_speed *= 1.1

	ball.global_position = ball_pos


func _process_game_state() -> void:
	var ball_pos: Vector2 = ball.global_position

	if ball_pos.x < 0:
		right_score += 1

	if ball_pos.x > screen_size.x:
		left_score += 1

	if ball_pos.x < 0 or ball_pos.x > screen_size.x:
		ball_pos = screen_size * 0.5
		game_round += 1
		ball_speed = clamp(
			INITIAL_BALL_SPEED + 10 * game_round,
			INITIAL_BALL_SPEED,
			MAX_BALL_SPEED
		)

	ball.global_position = ball_pos

	left_score_label.text = str(left_score)
	right_score_label.text = str(right_score)


func _process_paddles_host(delta: float) -> void:
	var speed: float = clamp(
		INITIAL_PAD_SPEED + 10 * game_round,
		INITIAL_PAD_SPEED,
		MAX_PAD_SPEED
	)

	# LEFT (local input)
	if Input.is_action_pressed("left_move_up"):
		left.global_position.y -= speed * delta
	if Input.is_action_pressed("left_move_down"):
		left.global_position.y += speed * delta

	# RIGHT (remote input from client)
	if remote_input.up:
		right.global_position.y -= speed * delta
	if remote_input.down:
		right.global_position.y += speed * delta


# =========================================================
# CLIENT LOGIC (no simulation, only input + render state)
# =========================================================

func _process_client(_delta: float) -> void:
	_send_input()


func _send_input() -> void:
	P2P.send_packet({
		"type": "input",
		"up": Input.is_action_pressed("left_move_up") or Input.is_action_pressed("right_move_up"),
		"down": Input.is_action_pressed("left_move_down") or Input.is_action_pressed("right_move_down")
	})


func _apply_state(data: Dictionary) -> void:
	var ball_pos = data.get("ball_pos", {})
	var left_pos = data.get("left_pos", {})
	var right_pos = data.get("right_pos", {})

	ball.global_position = Vector2(ball_pos.x, ball_pos.y)
	left.global_position = Vector2(left_pos.x, left_pos.y)
	right.global_position = Vector2(right_pos.x, right_pos.y)

	left_score = int(data.get("left_score", left_score))
	right_score = int(data.get("right_score", right_score))

	game_round = int(data.get("game_round", game_round))
	ball_speed = float(data.get("ball_speed", ball_speed))

	left_score_label.text = str(left_score)
	right_score_label.text = str(right_score)

	var dir = data.get("direction", {})
	direction = Vector2(dir.x, dir.y)


# =========================================================
# NETWORK
# =========================================================

func _send_state() -> void:
	P2P.send_packet({
		"type": "state",

		"ball_pos": {
			"x": ball.global_position.x,
			"y": ball.global_position.y
		},

		"left_pos": {
			"x": left.global_position.x,
			"y": left.global_position.y
		},

		"right_pos": {
			"x": right.global_position.x,
			"y": right.global_position.y
		},

		"left_score": left_score,
		"right_score": right_score,
		"game_round": game_round,
		"ball_speed": ball_speed,

		"direction": {
			"x": direction.x,
			"y": direction.y
		}
	})


func _on_p2p_packet_received(data: Dictionary) -> void:
	var type := str(data.get("type", ""))

	if P2P.is_host:
		if type == "input":
			remote_input.up = bool(data.get("up", false))
			remote_input.down = bool(data.get("down", false))
	else:
		if type == "state":
			_apply_state(data)


func _on_peer_connected() -> void:
	print("P2P connected")


func _on_peer_disconnected(reason: String) -> void:
	print("P2P disconnected:", reason)