extends LevelBase

var input := InputLocal.new()
var remote_input := InputRemote.new()
var _last_up := 0.0
var _last_down := 0.0
var _state_send_timer := 0.0
const STATE_SEND_INTERVAL := 1.0 / 30.0
var touch_count := 0

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
		process_simulation(delta)
		_state_send_timer += delta
		if _state_send_timer >= STATE_SEND_INTERVAL:
			_state_send_timer -= STATE_SEND_INTERVAL
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
	if up == _last_up and down == _last_down:
		return
	_last_up = up
	_last_down = down
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

	state.sound_effect = data.get("sound_effect", '')
	if state.sound_effect == 'beep_sound':
		beep_sound.play()
	if state.sound_effect == 'start_sound':
		start_sound.play()


func _on_p2p_packet_received(data: Dictionary) -> void:
	if GameController.game_mode == 'local':
		GameNetwork.close_connection()
		return
	var type: String = data.get("type", "")
	if GameController.player_role == 'host':
		if type == "input":
			remote_input.up = float(data.get("up", 0.0))
			remote_input.down = float(data.get("down", 0.0))
		if type == "resume":
			WebGameBridge.notify('OtherPlayerWantToResume')
		if type == "restart":
			WebGameBridge.notify('OtherPlayerWantToRestart')
		if type == "pause":
			if data.get("is_game_on_pause", false):
				GameController.pause()
			else:
				GameController.resume()
			GameNetwork.send({
				"type": "pause",
				"is_game_on_pause": GameController.is_game_on_pause,
			})
	else:
		if type == "state":
			_apply_state(data)

		if type == "pause":
			if data.get("is_game_on_pause", false):
				GameController.pause()
			else:
				GameController.resume()

func _on_start_play_button_down() -> void:
	if GameController.game_mode == 'local':
		GameController.resume()
		pause_menu.visible = false

func _on_restart_button_down() -> void:
	if GameController.game_mode == 'local':
		GameController.restart_game()
		pause_menu.visible = false
