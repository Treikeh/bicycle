extends Control
class_name Gui


const CONTROLLER: int = 0


@export var _game_ui: Control
@export var _pause_menu: Control
@export var _credits: Control
@export var _controller_not_connected: Control

@export_group("Game ui")
@export var _player_fell_prompt: Control
@export var _checkpoint_reached_label: RichTextLabel

var _count_time: bool = false


func _process(delta: float) -> void:
	if _count_time:
		EventBus.time_played += delta


func _ready() -> void:
	EventBus.player_fell.connect(_on_player_fell)
	EventBus.reset_level.connect(_on_reset_level)
	EventBus.checkpoint_reached.connect(_on_checkpoint_reached)
	EventBus.game_finished.connect(_on_game_finished)
	
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_controller_not_connected.hide()
	
	_resume()
	_player_fell_prompt.hide()
	_checkpoint_reached_label.visible_ratio = 0.0
	%DialogueLabel.visible_ratio = 0.0
	%LightBeam.hide()
	%PurgatoryLabel.modulate = Color.TRANSPARENT
	%ControllerThing.modulate = Color.TRANSPARENT
	
	if CONTROLLER not in Input.get_connected_joypads():
		_controller_not_connected.show()
		get_tree().paused = true
		%ControllerNotConnectedLabel.text = "No controller detected"
		return
	
	if not Input.has_joy_motion_sensors(CONTROLLER):
		_controller_not_connected.show()
		get_tree().paused = true
		%ControllerNotConnectedLabel.text = "No gyro found in controller"
		return
	
	_controller_not_connected.hide()
	_initial_fade_stuff()


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if device == CONTROLLER and connected == false:
		get_tree().paused = true
		%ControllerNotConnectedLabel.text = "No controller detected"
		_controller_not_connected.show()
	
	if device == CONTROLLER and connected == true:
		if not Input.has_joy_motion_sensors(CONTROLLER):
			%ControllerNotConnectedLabel.text = "No gyro found in controller"
			return
		
		if _pause_menu.visible == false:
			get_tree().paused = false
		
		_controller_not_connected.hide()
		Input.set_joy_motion_sensors_enabled(CONTROLLER, true)
		if %InitialFade.modulate != Color.TRANSPARENT:
			_initial_fade_stuff()


func _initial_fade_stuff() -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(%InitialFade, "modulate", Color.TRANSPARENT, 1.0)
	tween.tween_callback(%InitialFade.hide)
	#tween.tween_property(%PurgatoryLabel, "modulate", Color.WHITE, 0.75)
	tween.tween_callback(
		func():
			get_tree().get_first_node_in_group("player").enabled = true
			_count_time = true
	)
	#tween.tween_interval(2.0)
	#tween.tween_property(%PurgatoryLabel, "modulate", Color.TRANSPARENT, 0.75)
	tween.tween_property(%ControllerThing, "modulate", Color.WHITE, 0.75)
	tween.tween_interval(4.0)
	tween.tween_property(%MoveShow, "modulate", Color.TRANSPARENT, 0.75)
	tween.tween_property(%BalanceShow, "modulate", Color.WHITE, 0.75)
	tween.tween_interval(4.0)
	tween.tween_property(%BalanceShow, "modulate", Color.TRANSPARENT, 0.75)
	tween.tween_property(%TurnShow, "modulate", Color.WHITE, 0.75)
	tween.tween_interval(4.0)
	tween.tween_property(%TurnShow, "modulate", Color.TRANSPARENT, 0.75)
	tween.tween_callback(%ControllerThing.hide)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not EventBus.is_game_finished:
		if get_tree().paused:
			_resume()
		else:
			_pause()
	
	if event.is_action_pressed("ui_accept") and get_tree().paused:
		_resume()
	
	if event.is_action_pressed("quit") and (_pause_menu.visible or _credits.visible):
		get_tree().quit()


func _on_player_fell(_player: Bike) -> void:
	_player_fell_prompt.show()


func _on_reset_level() -> void:
	_player_fell_prompt.hide()


func _on_checkpoint_reached() -> void:
	const TWEEN_DURATION: float = 0.75
	const VISIBLE_TIME: float = 3.0
	var tween: Tween = create_tween().chain()
	tween.tween_property(_checkpoint_reached_label, "visible_ratio", 1.0, TWEEN_DURATION)
	tween.tween_interval(VISIBLE_TIME)
	tween.tween_property(_checkpoint_reached_label, "visible_ratio", 0.0, TWEEN_DURATION)


func _on_game_started() -> void:
	pass


func _on_game_finished() -> void:
	_game_ui.hide()
	_pause_menu.hide()
	_count_time = false
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(%TopBar, "offset_transform_position:y", 0.0, EventBus.CUTSCENE_TWEEN_DUR_INTRO)
	tween.tween_property(%BottomBar, "offset_transform_position:y", 0.0, EventBus.CUTSCENE_TWEEN_DUR_INTRO)
	tween.set_parallel(false)
	tween.tween_interval(1.0)
	tween.tween_callback(
		func():
			%SpeachVfx.play()
			create_tween().tween_property(%SpeachVfx, "volume_linear", 1.0, 0.75)
	)
	tween.tween_property(%DialogueLabel, "visible_ratio", 1.0, 3.0)
	tween.tween_callback(
		func():
			var tween_1: Tween = create_tween()
			tween_1.tween_property(%SpeachVfx, "volume_linear", 0.0, 0.75)
			tween_1.tween_callback(%SpeachVfx.stop)
	)
	tween.tween_interval(5.0)
	tween.tween_callback(
		func():
			%DialogueLabel.visible_ratio = 0.0
			%DialogueLabel.text = "[shake level=15 rate=5]NOW GO FORTH AND BE FREE FROM SHACKLES OF FATE[/shake]"
	)
	tween.tween_interval(0.2)
	tween.tween_callback(
		func():
			%SpeachVfx.play()
			create_tween().tween_property(%SpeachVfx, "volume_linear", 1.0, 0.75)
	)
	tween.tween_property(%DialogueLabel, "visible_ratio", 1.0, 6.0)
	tween.tween_callback(
		func():
			var tween_2: Tween = create_tween()
			tween_2.tween_property(%SpeachVfx, "volume_linear", 0.0, 0.75)
			tween_2.tween_callback(%SpeachVfx.stop)
	)
	tween.tween_interval(5.0)
	tween.tween_callback(
		func():
			%DialogueLabel.visible_ratio = 0.0
	)
	tween.tween_interval(0.2)
	tween.tween_callback(
		func():
			%LightBeam.scale = Vector3.ZERO
			%LightBeam.show()
	)
	tween.tween_property(%LightBeam, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(
		func():
			get_tree().get_first_node_in_group("player").hide()
	)
	tween.tween_property(%LightBeam, "scale", Vector3.ZERO, 0.5)
	tween.tween_interval(3.5)
	tween.tween_callback(
		func():
			_credits.modulate = Color.TRANSPARENT
			_credits.show()
	)
	tween.tween_property(_credits, "modulate", Color.WHITE, 3.0)
	tween.tween_callback(
		func():
			var minutes: int = floori(EventBus.time_played / 60.0)
			var seconds: int = int(EventBus.time_played) % 60
			var time_played: String = "%sm, %ss" % [minutes, seconds]
			%GameStatsLabel.text = "Time Played: %s\nTimes Reset: %s\nTimes Fallen: %s
			" % [time_played, EventBus.times_reset, EventBus.times_fallen]
	)
	tween.tween_property(%CreditsThing, "modulate", Color.WHITE, 2.0)
	tween.tween_interval(1.0)
	tween.tween_property(%Quit, "modulate", Color.WHITE, 2.0)


func _pause() -> void:
	if _pause_menu.visible == false:
		_game_ui.hide()
		_pause_menu.show()
		get_tree().paused = true


func _resume() -> void:
	if _pause_menu.visible == true and _controller_not_connected.visible == false:
		_pause_menu.hide()
		_game_ui.show()
		get_tree().paused = false
