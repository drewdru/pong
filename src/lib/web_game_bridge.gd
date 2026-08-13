extends Node

var _window: JavaScriptObject

var _start_online_callback: JavaScriptObject
var _start_local_callback: JavaScriptObject
var _pause_callback: JavaScriptObject
var _restart_game_callback: JavaScriptObject
var _resume_callback: JavaScriptObject


func _ready() -> void:
	if not OS.has_feature("web"):
		return

	_window = JavaScriptBridge.get_interface("window")

	_start_online_callback = JavaScriptBridge.create_callback(_on_start_online)
	_window.__godotWebGameBridgeStartOnline = _start_online_callback

	_start_local_callback = JavaScriptBridge.create_callback(_on_start_local)
	_window.__godotWebGameBridgeStartLocal = _start_local_callback

	_pause_callback = JavaScriptBridge.create_callback(_on_pause)
	_window.__godotWebGameBridgePause = _pause_callback

	_resume_callback = JavaScriptBridge.create_callback(_on_resume)
	_window.__godotWebGameBridgeResume = _resume_callback

	_restart_game_callback = JavaScriptBridge.create_callback(_on_restart_game)
	_window.__godotWebGameBridgeRestart = _restart_game_callback


func _on_start_online(args: Array) -> void:
	if args.is_empty() || not OS.has_feature("web"):
		return
	GameController.set_role(str(args[0]))
	GameController.set_game_mode('online')
	GameController.restart_game()
	GameController.resume()


func _on_start_local() -> void:
	if not OS.has_feature("web"):
		return
	GameController.set_game_mode('local')
	GameController.restart_game()
	GameController.resume()


func _on_pause() -> void:
	if not OS.has_feature("web"):
		return
	GameController.pause()

func _on_resume() -> void:
	if not OS.has_feature("web"):
		return
	GameController.resume()


func set_menu_visibility(value: bool) -> void:
	if not OS.has_feature("web"):
		return
	_window.__godotWebGameBridgeSetMenuVisibility(value)


func _on_restart_game() -> void:
	if not OS.has_feature("web"):
		return
	GameController.restart_game()
