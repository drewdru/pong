extends LevelBase

var input := InputLocal.new()
var remote_input := InputRemote.new()

func _ready() -> void:
	super._ready()
	GameNetwork.on_message.connect(_on_p2p_packet_received)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameController.game_mode == 'local':
			GameController.toggle_pause()
			pause_menu.visible = GameController.is_game_on_pause
			return
		GameNetwork.send({
			"type": "pause",
			"is_game_on_pause": not GameController.is_game_on_pause,
		})
		if GameController.player_role == 'host':
			GameController.toggle_pause()

func _physics_process(delta: float) -> void:
	if GameController.is_game_on_pause:
		return
	if GameController.game_mode == 'local':
		process_simulation(delta)
		return
	if GameController.player_role == 'host':
		process_simulation(delta)
		_send_state()
	else:
		_send_input()

func left_move_up() -> float:
	return input.left_move_up()

func left_move_down() -> float:
	return input.left_move_down()

func right_move_up() -> float:
	if GameController.game_mode == 'local':
		return input.right_move_up()
	return remote_input.up

func right_move_down() -> float:
	if GameController.game_mode == 'local':
		return input.right_move_down()
	return remote_input.down

func _send_input() -> void:
	var up = max(input.right_move_up(), input.left_move_up())
	var down = max(input.right_move_down(), input.left_move_down())
	if up == 0 and down == 0:
		return
	GameNetwork.send({
		"type": "input",
		"up": up,
		"down": down
	})

func _send_state() -> void:
	GameNetwork.send({
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
	if GameController.game_mode == 'local':
		GameNetwork.close_connection()
		return
	var type: String = data.get("type", "")
	if GameController.player_role == 'host':
		if type == "input":
			remote_input.up = float(data.get("up", 0.0))
			remote_input.down = float(data.get("down", 0.0))
	else:
		if type == "state":
			_apply_state(data)

	if type == "pause":
		if data.get("is_game_on_pause", false):
			GameController.pause()
		else:
			GameController.resume()
		if GameController.player_role == 'host':
			GameNetwork.send({
				"type": "pause",
				"is_game_on_pause": GameController.is_game_on_pause,
			})

func _on_start_play_button_down() -> void:
	if GameController.game_mode == 'local':
		GameController.resume()
		pause_menu.visible = false

func _on_restart_button_down() -> void:
	if GameController.game_mode == 'local':
		GameController.restart_game()
		pause_menu.visible = false
