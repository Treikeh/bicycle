extends Node
class_name ControllerInput


const CONTROLLER: int = 0
const GYRO_SENS: float = 1.0

@export var _pedals: RigidBody3D
@export var _left_foot: Node3D
@export var _right_foot: Node3D
@export var _roll_node: Node3D
@export var _yaw_node: Node3D
@export var _accel_curve: Curve

var left_input: Vector2
var right_input: Vector2
var pedal_rot: float
var roll: float = 0.0
var yaw: float = 0.0
var accel: float = 0.0

@onready var _left_node_start_pos: Vector3 = _left_foot.position
@onready var _right_node_start_pos: Vector3 = _right_foot.position


func _ready() -> void:
	# Check if controller is connected
	if CONTROLLER not in Input.get_connected_joypads():
		return
	
	# Check if controller has motion sensors
	if not Input.has_joy_motion_sensors(CONTROLLER):
		return
	
	# Enable controller motion sensors
	Input.set_joy_motion_sensors_enabled(CONTROLLER, true)


func _physics_process(delta: float) -> void:
	left_input = Input.get_vector("left_l", "left_r", "left_d", "left_u")
	right_input = Input.get_vector("right_l", "right_r", "right_d", "right_u")
	
	_left_foot.position = _left_node_start_pos + Vector3(0.0, left_input.x, -left_input.y)
	_right_foot.position = _right_node_start_pos + Vector3(0.0, -right_input.x, -right_input.y)
	
	# Rotate with gyroscope
	var gyro: Vector3 = Input.get_joy_gyroscope(0)
	_roll_node.rotation.z += gyro.z * GYRO_SENS * delta
	_yaw_node.rotation.y += gyro.y * GYRO_SENS * delta
	
	yaw = _yaw_node.rotation.y
	roll = _roll_node.rotation.z
	
	# Get accel from pedals
	accel = _accel_curve.sample(-_pedals.angular_velocity.x)
	pedal_rot = _pedals.rotation.x


func reset() -> void:
	_yaw_node.rotation.y = 0.0
	_roll_node.rotation.z = 0.0
	_pedals.angular_velocity.x = 0.0
