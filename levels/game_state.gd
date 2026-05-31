extends RefCounted
class_name GameState

@export var INITIAL_BALL_SPEED := 80.0
@export var MAX_BALL_SPEED := 300.0

@export var INITIAL_PAD_SPEED := 150.0
@export var MAX_PAD_SPEED := 400.0

var screen_size := Vector2.ZERO
var pad_size := Vector2.ZERO
var pad_speed := 0.0

var direction := Vector2(1.0, 0.0)
var ball_speed := 80.0

var left_score := 0
var right_score := 0
var game_round := 1

func setup(_screen_size: Vector2, _pad_size: Vector2) -> void:
	screen_size = _screen_size
	pad_size = _pad_size
	pad_speed = INITIAL_PAD_SPEED
	direction = Vector2(1.0, 0.0)
	ball_speed = INITIAL_BALL_SPEED
	left_score = 0
	right_score = 0
	game_round = 1