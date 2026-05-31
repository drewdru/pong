extends RefCounted
class_name InputRemote

var up := false
var down := false

func set_state(data: Dictionary) -> void:
	up = data.get("up", false)
	down = data.get("down", false)

func to_state() -> Dictionary:
	return {
		"up": up,
		"down": down,
	}