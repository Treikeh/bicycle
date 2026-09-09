extends Node3D


@export var _camera: Camera3D


func _ready() -> void:
	EventBus.game_finished.connect(_on_game_finished)


func _on_game_finished() -> void:
	var cam: Camera3D = get_tree().get_first_node_in_group("cam")
	var tween: Tween = create_tween()
	tween.tween_property(cam, "global_transform", _camera.global_transform, EventBus.CUTSCENE_TWEEN_DUR_INTRO)
