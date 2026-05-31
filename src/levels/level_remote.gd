extends LevelBase

var input := InputLocal.new()
var remote_input := InputRemote.new()

func _ready() -> void:
	super._ready()
	P2P.packet_received.connect(_on_p2p_packet_received)
	P2P.peer_connected.connect(_on_peer_connected)
	P2P.peer_disconnected.connect(_on_peer_disconnected)

func _process(delta: float) -> void:
	if P2P.is_host:
		process_simulation(delta)
		_send_state()
	else:
		_send_input()

func left_move_up() -> float:
	return input.left_move_up()

func left_move_down() -> float:
	return input.left_move_down()

func right_move_up() -> float:
	return remote_input.up

func right_move_down() -> float:
	return remote_input.down

func _send_input() -> void:
	P2P.send_packet({
		"type": "input",
		"up": input.right_move_up() + input.left_move_up(),
		"down": input.right_move_down() + input.left_move_down()
	})

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
		"left_score": state.left_score,
		"right_score": state.right_score,
		"game_round": state.game_round,
		"ball_speed": state.ball_speed,
		"direction": {
			"x": state.direction.x,
			"y": state.direction.y
		}
	})

func _apply_state(data: Dictionary) -> void:
	var ball_pos = data.get("ball_pos", {})
	var left_pos = data.get("left_pos", {})
	var right_pos = data.get("right_pos", {})

	ball.global_position = Vector2(ball_pos.x, ball_pos.y)
	left.global_position = Vector2(left_pos.x, left_pos.y)
	right.global_position = Vector2(right_pos.x, right_pos.y)

	state.left_score = int(data.get("left_score", state.left_score))
	state.right_score = int(data.get("right_score", state.right_score))
	state.game_round = int(data.get("game_round", state.game_round))
	state.ball_speed = float(data.get("ball_speed", state.ball_speed))

	left_score_label.text = str(state.left_score)
	right_score_label.text = str(state.right_score)

	var dir = data.get("direction", {})
	state.direction = Vector2(dir.x, dir.y)

func _on_p2p_packet_received(data: Dictionary) -> void:
	var type := str(data.get("type", ""))

	if P2P.is_host:
		if type == "input":
			remote_input.up = float(data.get("up", 0.0))
			remote_input.down = float(data.get("down", 0.0))
	else:
		if type == "state":
			_apply_state(data)

func _on_peer_connected() -> void:
	print("P2P connected")

func _on_peer_disconnected(reason: String) -> void:
	print("P2P disconnected:", reason)