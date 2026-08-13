extends Node

signal restart

var game_mode := 'local'
var player_role := 'player'
var is_game_on_pause := true

func pause() -> void:
	is_game_on_pause = true
	WebGameBridge.set_menu_visibility(true)
	if game_mode == 'local':
		return
	if player_role == 'host':
		GameNetwork.send({
			"type": "pause",
			"is_game_on_pause": is_game_on_pause,
		})

func resume(need_notify: bool = false) -> void:
	is_game_on_pause = false
	WebGameBridge.set_menu_visibility(false)
	if game_mode == 'local':
		return
	if player_role == 'host':
		GameNetwork.send({
			"type": "pause",
			"is_game_on_pause": is_game_on_pause,
		})
	elif need_notify:
		GameNetwork.send({ "type": "resume" })
		WebGameBridge.notify('WaitForHost')

func toggle_pause() -> void:
	is_game_on_pause = not is_game_on_pause
	WebGameBridge.set_menu_visibility(is_game_on_pause)
	if game_mode == 'local':
		return
	if player_role == 'host':
		GameNetwork.send({
			"type": "pause",
			"is_game_on_pause": is_game_on_pause,
		})
	elif not is_game_on_pause:
		GameNetwork.send({ "type": "resume" })
		WebGameBridge.notify('WaitForHost')

func set_role(role: String) -> void:
	player_role = 'host' if role == 'host' else 'player'

func set_game_mode(mode: String) -> void:
	game_mode = 'online' if mode == 'online' else 'local'

func restart_game() -> void:
	restart.emit()
