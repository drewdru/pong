extends LevelBase

var input := InputLocal.new()
var remote_input := InputRemote.new()
var _last_up := 0.0
var _last_down := 0.0
var _state_send_timer := 0.0
const STATE_SEND_INTERVAL := 1.0
var touch_count := 0
var is_send_right_position := false

func _ready() -> void:
	super._ready()
	GameNetwork.on_message.connect(_on_p2p_packet_received)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_count += 1
			if touch_count == 2:
				_on_pause_pressed()
		else:
			touch_count = max(touch_count - 1, 0)
		return
	if event.is_action_pressed("pause"):
		_on_pause_pressed()
	else:
		input.handle_input(event)

func _on_pause_pressed() -> void:
	if GameController.game_mode == 'local':
		GameController.toggle_pause()
		if not OS.has_feature("web"):
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
		var force = process_simulation(delta)
		var force_update = force[0]
		var force_ball_teleport = force[1]
		_state_send_timer += delta
		if force_update or force_ball_teleport or _state_send_timer >= STATE_SEND_INTERVAL:
			_state_send_timer = 0
			_send_state(force_ball_teleport)
		else:
			_send_position()
	else:
		process_web_client_simulation(delta)
		_send_client_input()

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

func _get_left_position_to_send() -> Variant:
	var up = input.left_move_up()
	var down = input.left_move_down()
	if up == 0 and down == 0 and _last_up == 0 and _last_down == 0:
		return null
	_last_up = up
	_last_down = down
	return {
		"x": left.global_position.x,
		"y": left.global_position.y,
	}
func _get_right_position_to_send() -> Variant:
	if not is_send_right_position:
		return null
	return {
		"x": right.global_position.x,
		"y": right.global_position.y,
	}
	

func _send_position() -> void:
	var left_pos = _get_left_position_to_send()
	var right_pos = _get_right_position_to_send()
	if right_pos is not Dictionary and left_pos is not Dictionary:
		return
	GameNetwork.send({
		"type": "position",
		"left_pos": left_pos,
		"right_pos": right_pos,
	})

func _send_client_input() -> void:
	var up = left_move_up()
	var down = left_move_down()
	if up == _last_up and down == _last_down:
		return
	_last_up = up
	_last_down = down
	GameNetwork.send({
		"type": "input",
		"up": up,
		"down": down
	})

func _send_state(force_ball_teleport: bool) -> void:
	GameNetwork.send({
		"type": "state",
		"ball_pos": {
			"x": ball.global_position.x,
			"y": ball.global_position.y,
			"is_teleport": force_ball_teleport
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
	var host_ball_pos := Vector2(
		float(ball_pos.get("x", 0.0)),
		float(ball_pos.get("y", 0.0))
	)
	if ball_pos.is_teleport:
		ball.global_position = host_ball_pos
	else:
		ball.global_position = ball.global_position.lerp(host_ball_pos, 0.2)

	var left_pos = data.get("left_pos", {})
	var right_pos = data.get("right_pos", {})

	left.global_position = left.global_position.lerp(Vector2(
		float(left_pos.get("x", 0.0)),
		float(left_pos.get("y", 0.0))
	), 0.2)
	right.global_position = right.global_position.lerp(Vector2(
		float(right_pos.get("x", 0.0)),
		float(right_pos.get("y", 0.0))
	), 0.2)

	state.left_score = int(data.get("left_score", state.left_score))
	state.right_score = int(data.get("right_score", state.right_score))
	state.game_round = int(data.get("game_round", state.game_round))
	state.ball_speed = float(data.get("ball_speed", state.ball_speed))

	left_score_label.text = str(state.left_score)
	right_score_label.text = str(state.right_score)

	var direction = data.get("direction", {})
	state.direction = Vector2(
		float(direction.get("x", 0.0)),
		float(direction.get("y", 0.0))
	)


func _on_p2p_packet_received(data: Dictionary) -> void:
	if GameController.game_mode == 'local':
		GameNetwork.close_connection()
		return
	var type: String = data.get("type", "")
	if type == "pause":
		if data.get("is_game_on_pause", false):
			GameController.pause()
		else:
			GameController.resume()
	if GameController.player_role == 'host':
		if type == "input":
			remote_input.up = float(data.get("up", 0.0))
			remote_input.down = float(data.get("down", 0.0))
			is_send_right_position = true 
		if type == "resume":
			WebGameBridge.notify('OtherPlayerWantToResume')
		if type == "restart":
			WebGameBridge.notify('OtherPlayerWantToRestart')
		if type == "pause":
			GameNetwork.send({
				"type": "pause",
				"is_game_on_pause": GameController.is_game_on_pause,
			})
	else:
		if type == "state":
			_apply_state(data)
		if type == "position":
			var left_pos: Variant = data.get("left_pos", null)
			if left_pos is Dictionary:
				left.global_position = left.global_position.lerp(Vector2(
					float(left_pos.get("x", 0.0)),
					float(left_pos.get("y", 0.0))
				), 0.2)
			var right_pos: Variant = data.get("right_pos", null)
			if right_pos is Dictionary:
				right.global_position = right.global_position.lerp(Vector2(
					float(right_pos.get("x", 0.0)),
					float(right_pos.get("y", 0.0))
				), 0.2)

func _on_start_play_button_down() -> void:
	if GameController.game_mode == 'local':
		GameController.resume()
		pause_menu.visible = false

func _on_restart_button_down() -> void:
	if GameController.game_mode == 'local':
		GameController.restart_game()
		pause_menu.visible = false
