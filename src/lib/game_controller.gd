extends Node

signal restart

var game_mode := 'local'
var player_role := 'player'
var is_game_on_pause := true

func pause() -> void:
	is_game_on_pause = true
	WebGameBridge.set_menu_visibility(true)

func resume() -> void:
	is_game_on_pause = false
	WebGameBridge.set_menu_visibility(false)

func toggle_pause() -> void:
	is_game_on_pause = not is_game_on_pause
	WebGameBridge.set_menu_visibility(is_game_on_pause)

func set_role(role: String) -> void:
	player_role = 'host' if role == 'host' else 'player'

func set_game_mode(mode: String) -> void:
	game_mode = 'online' if mode == 'online' else 'local'

func restart_game() -> void:
	restart.emit()
