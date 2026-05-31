extends Node

@onready var room_code_label: Label = %RoomCodeLabel
@onready var room_code_input: LineEdit = %RoomCodeInput
@onready var status_label: Label = %StatusLabel

const SIGNALING_URL := "ws://localhost:8080" # поменяешь на свой сервер

func _ready() -> void:
	status_label.text = "Ready"

	P2P.room_created.connect(_on_room_created)
	P2P.room_joined.connect(_on_room_joined)
	P2P.peer_connected.connect(_on_peer_connected)
	P2P.peer_disconnected.connect(_on_peer_disconnected)


# -------------------------
# HOST
# -------------------------
func _on_create_button_pressed() -> void:
	status_label.text = "Creating room..."

	var err = P2P.host(SIGNALING_URL)
	if err != OK:
		status_label.text = "Failed to connect signaling server"
		return

	status_label.text = "Waiting for room id..."


func _on_room_created(room_id: String) -> void:
	room_code_label.text = "ROOM: " + room_id
	status_label.text = "Share this code"


# -------------------------
# JOIN
# -------------------------
func _on_join_button_pressed() -> void:
	var code := room_code_input.text.strip_edges()

	if code.is_empty():
		status_label.text = "Enter room code"
		return

	status_label.text = "Joining room..."

	var err = P2P.join(SIGNALING_URL, code)
	if err != OK:
		status_label.text = "Failed to connect signaling server"
		return


func _on_room_joined(room_id: String) -> void:
	status_label.text = "Connected to room: " + room_id


# -------------------------
# P2P CONNECTED
# -------------------------
func _on_peer_connected() -> void:
	status_label.text = "Peer connected!"

	await get_tree().create_timer(1.0).timeout

	get_tree().change_scene_to_file("res://levels/level_remote.tscn")


func _on_peer_disconnected(reason: String) -> void:
	status_label.text = "Disconnected: " + reason

func _on_local_coop_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_local.tscn")
