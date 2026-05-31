extends Node
class_name P2PWebRTC

signal room_created(room_id: String)
signal room_joined(room_id: String)
signal peer_connected()
signal peer_disconnected(reason: String)
signal packet_received(data: Dictionary)

const CHANNEL_NAME := "pong"

const ICE_SERVERS := [
	{ "urls": ["stun:stun.l.google.com:19302"] }
]

var socket := WebSocketPeer.new()

var peer: WebRTCPeerConnection
var channel: WebRTCDataChannel

var signaling_url := ""
var room_id := ""
var is_host := false

var _create_sent := false
var _join_sent := false
var _connected_emitted := false


# -------------------------
# PUBLIC API
# -------------------------
func host(url: String) -> Error:
	_reset()

	signaling_url = url
	is_host = true

	_init_peer()

	var err := socket.connect_to_url(signaling_url)
	if err != OK:
		return err

	set_process(true)
	return OK


func join(url: String, code: String) -> Error:
	_reset()

	signaling_url = url
	room_id = code.strip_edges().to_upper()
	is_host = false

	_init_peer()

	var err := socket.connect_to_url(signaling_url)
	if err != OK:
		return err

	set_process(true)
	return OK


func send_packet(data: Dictionary) -> void:
	if channel == null:
		return
	if channel.get_ready_state() != WebRTCDataChannel.STATE_OPEN:
		return

	channel.put_packet(JSON.stringify(data).to_utf8_buffer())


# -------------------------
# MAIN LOOP
# -------------------------
func _process(_delta: float) -> void:
	socket.poll()

	_process_socket()

	if peer:
		peer.poll()

	_process_channel()
	_check_connected()
	_process_flow()


# -------------------------
# SIGNALING FLOW
# -------------------------
func _process_flow() -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return

	if is_host and not _create_sent:
		_send_ws({ "type": "create_room" })
		_create_sent = true

	elif not is_host and not _join_sent and room_id != "":
		_send_ws({
			"type": "join_room",
			"roomId": room_id
		})
		_join_sent = true


# -------------------------
# SOCKET
# -------------------------
func _process_socket() -> void:
	while socket.get_ready_state() == WebSocketPeer.STATE_OPEN and socket.get_available_packet_count() > 0:
		var pkt := socket.get_packet()
		if not socket.was_string_packet():
			continue

		var msg = JSON.parse_string(pkt.get_string_from_utf8())
		if typeof(msg) != TYPE_DICTIONARY:
			continue

		match msg.get("type"):

			"room_created":
				room_id = msg.roomId
				room_created.emit(room_id)

			"room_joined":
				room_joined.emit(msg.roomId)

			"peer_joined":
				if is_host:
					# Host creates the channel FIRST
					channel = peer.create_data_channel(CHANNEL_NAME)
					channel.write_mode = WebRTCDataChannel.WRITE_MODE_TEXT
					
					# Force a clean frame sequence window
					await get_tree().process_frame
					await get_tree().process_frame
					
					peer.create_offer()

			"signal":
				_handle_signal(msg.signal)

			"error":
				peer_disconnected.emit(msg.message)

# -------------------------
# SIGNAL HANDLING
# -------------------------
func _handle_signal(sig: Dictionary) -> void:
	match sig.kind:

		"session":
			var type = sig.type
			var sdp = sig.sdp

			if type == "offer":
				# This call automatically updates state AND creates the answer out-of-the-box
				peer.set_remote_description("offer", sdp)

				await get_tree().process_frame
				await get_tree().process_frame

				# REMOVED: peer.create_answer() — This is what caused the crash!

			elif type == "answer":
				peer.set_remote_description("answer", sdp)

		"ice":
			if peer:
				peer.add_ice_candidate(
					sig.media,
					int(sig.index),
					sig.name
				)


# -------------------------
# CHANNEL
# -------------------------
func _process_channel() -> void:
	if channel == null:
		return

	while channel.get_available_packet_count() > 0:
		var text := channel.get_packet().get_string_from_utf8()
		var data = JSON.parse_string(text)

		if typeof(data) == TYPE_DICTIONARY:
			packet_received.emit(data)


# -------------------------
# CONNECTED CHECK (ONLY REAL SIGNAL IN GODOT)
# -------------------------
func _check_connected() -> void:
	if _connected_emitted:
		return

	if channel != null and channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
		_connected_emitted = true
		peer_connected.emit()


# -------------------------
# PEER SETUP
# -------------------------
func _init_peer() -> void:
	if peer != null:
		return

	peer = WebRTCPeerConnection.new()
	peer.initialize({ "iceServers": ICE_SERVERS })

	peer.session_description_created.connect(_on_sdp)
	peer.ice_candidate_created.connect(_on_ice)

	# JOINER receives channel
	peer.data_channel_received.connect(_on_data_channel)


func _on_data_channel(dc: WebRTCDataChannel) -> void:
	channel = dc
	channel.write_mode = WebRTCDataChannel.WRITE_MODE_TEXT


# -------------------------
# SDP / ICE SEND
# -------------------------
func _on_sdp(type: String, sdp: String) -> void:
	peer.set_local_description(type, sdp)

	_send_ws({
		"type": "signal",
		"roomId": room_id,
		"signal": {
			"kind": "session",
			"type": type,
			"sdp": sdp
		}
	})


func _on_ice(media: String, index: int, name: String) -> void:
	_send_ws({
		"type": "signal",
		"roomId": room_id,
		"signal": {
			"kind": "ice",
			"media": media,
			"index": index,
			"name": name
		}
	})


# -------------------------
# WS SEND
# -------------------------
func _send_ws(data: Dictionary) -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return

	socket.send_text(JSON.stringify(data))


# -------------------------
# RESET
# -------------------------
func _reset() -> void:
	_create_sent = false
	_join_sent = false
	_connected_emitted = false

	if channel:
		channel.close()
		channel = null

	if peer:
		peer.close()
		peer = null

	if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		socket.close()

	set_process(false)