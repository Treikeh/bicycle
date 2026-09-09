extends RigidBody3D
class_name Bike


const CAM_ROT_SPEED: float = 7.5

@export var _steer_force: float = 7.0
@export var _lean_force: float = 3.0
@export var _controller_input: ControllerInput
@export var _ground_check: RayCast3D
@export var _pedals: Node3D
@export var _steering_handle: Node3D
@export var _camera_root: Node3D
@export var _chain_sfx: AudioStreamPlayer3D

var enabled: bool = false

@onready var _default_linear_damp: float = linear_damp
@onready var _start_center_of_mass: Vector3 = center_of_mass
@onready var checkpoint_transform: Transform3D = global_transform


func _ready() -> void:
	EventBus.reset_level.connect(_on_reset)
	_camera_root.global_position = global_position


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset") and not EventBus.is_game_finished:
		EventBus.reset_level.emit()


func _process(delta: float) -> void:
	_chain_sfx.volume_linear = clampf(_controller_input.accel, 0.0, 0.95)
	if not enabled:
		return
	
	# Camera
	_camera_root.global_position = global_position
	var desired_rot: float = global_rotation.y + (_controller_input.yaw * 0.2)
	_camera_root.global_rotation.y = lerp_angle(_camera_root.global_rotation.y, desired_rot, CAM_ROT_SPEED * delta)
	
	# Visuals
	_pedals.rotation.x = _controller_input.pedal_rot
	_steering_handle.rotation = Vector3(deg_to_rad(20.5), _controller_input.yaw, 0.0)
	
	if global_basis.y.dot(Vector3.UP) < 0.3:
		fall()


func _physics_process(delta: float) -> void:
	var is_grounded: bool = _ground_check.is_colliding()
	if not enabled or not is_grounded:
		linear_damp = 0.0
		return
	
	linear_damp = _default_linear_damp
	var forward_force: float = max(_controller_input.accel, 0.0)
	apply_central_force(-global_basis.z * forward_force)
	apply_torque(global_basis.y * _controller_input.yaw * _steer_force * clampf(_controller_input.accel, 0.0, 1.0))
	apply_torque(global_basis.z * _controller_input.roll * _lean_force)
	
	_apply_anti_slip(delta)


func _apply_anti_slip(delta: float) -> void:
	const ANI_SLIP_FORCE: float = 0.125
	var slip_dir: Vector3 = global_basis.x
	var slip_vel: float = linear_velocity.dot(slip_dir)
	var force: float = -(slip_vel * ANI_SLIP_FORCE) / delta
	
	apply_central_force(slip_dir * force * mass)


func fall() -> void:
	enabled = false
	center_of_mass.y = 0.0
	EventBus.times_fallen += 1
	EventBus.player_fell.emit(self)


func _on_reset() -> void:
	enabled = true
	center_of_mass = _start_center_of_mass
	EventBus.times_reset += 1
	# Reset physics stuff
	await get_tree().physics_frame
	_controller_input.reset()
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = checkpoint_transform
