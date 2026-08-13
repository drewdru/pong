extends Node

signal on_message(data: Dictionary)

var _window: JavaScriptObject
var _on_js_message_callback: JavaScriptObject

func _ready() -> void:
	if not OS.has_feature("web"):
		return

	_window = JavaScriptBridge.get_interface("window")

	_on_js_message_callback = JavaScriptBridge.create_callback(_on_js_message)
	_window.__godotGameNetworkOnMessage = _on_js_message_callback


func send(data: Dictionary) -> void:
	var message := JSON.stringify(data)
	_window.__godotGameNetworkSend(message)


func _on_js_message(args: Array) -> void:
	if args.is_empty():
		return
	var data = JSON.parse_string(str(args[0]))
	if data is Dictionary:
		on_message.emit(data)