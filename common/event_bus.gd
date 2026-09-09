extends Node

@warning_ignore_start("unused_signal")
signal checkpoint_reached
signal game_finished
signal game_started
signal player_fell(player: Bike)
signal reset_level

signal controller_connected(device: int)


const CUTSCENE_TWEEN_DUR_INTRO: float = 1.0

var is_game_finished: bool = false

var times_fallen: int = 0
var times_reset: int = 0
var time_played: float = 0.0
