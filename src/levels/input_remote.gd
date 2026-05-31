extends RefCounted
class_name InputRemote

var up := 0.0
var down := 0.0

func set_state(data: Dictionary) -> void:
	up = data.get("up", 0.0)
	down = data.get("down", 0.0)

func to_state() -> Dictionary:
	return {
		"up": up,
		"down": down,
	}