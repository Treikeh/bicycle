extends Area3D


@export var _final: bool = false
@export var _checkpoint_transform_node: Node3D
@export var _mesh: MeshInstance3D
@export var _rotation_curve: Curve
@export var _default_mat: StandardMaterial3D
@export var _final_mat: StandardMaterial3D
@export var _reached_sfx: AudioStreamPlayer

var _reached: bool = false
var _rotation_curve_time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_mesh.mesh.material = _final_mat if _final else _default_mat


func _process(delta: float) -> void:
	var rotation_speed: float = _rotation_curve.sample(_rotation_curve_time)
	_mesh.mesh.material.uv1_offset.x += delta * rotation_speed


func _on_body_entered(body: Node3D) -> void:
	# Check if the body is the player and if the player is enabled
	if body is Bike and body.enabled == true and _reached == false:
		_reached = true
		_reached_sfx.play()
		if _final:
			body.enabled = false
			EventBus.is_game_finished = true
			EventBus.game_finished.emit()
		else:
			EventBus.checkpoint_reached.emit()
			body.checkpoint_transform = _checkpoint_transform_node.global_transform
			var tween: Tween = create_tween()
			tween.tween_property(self, "_rotation_curve_time", 1.0, 1.0)
