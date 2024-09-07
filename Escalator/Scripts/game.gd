extends Node

const THROTTLE_RATE : float = 1
const THROTTLE_DECAY : float = 2.5
const ESCALATOR_MAX_THROTTLE : float = 1.0
const ESCALATOR_MAX_SPEED : float = 0.7
const ESCALATOR_WEIGHT_RATE : float = 0.5
const GLOBAL_MOOD_MAX : float = 5

var _path : Path2D
var _escalator_sprite : AnimatedSprite2D
var _throttle_display_bar : TextureProgressBar
var _reverse_display_sprite : Sprite2D
var _game_over_panel : Panel
var _throttle : float
var _total_weight : float
var _escalator_speed : float
var _score_control : ScoreControl
var _spawner: PassengerSpawner
var _chronogram: Chronogram

var _l_waiting_spot: PathFollow2D
var _r_waiting_spot: PathFollow2D
var _l_escalator_start: PathFollow2D
var _r_escalator_start: PathFollow2D

var _sfx_crash: AudioStreamPlayer

func _ready():
	_path = get_tree().get_current_scene().find_child("Path2D")
	_l_waiting_spot = _path.get_node('LWaitingSpot')
	_r_waiting_spot = _path.get_node('RWaitingSpot')
	_l_escalator_start = _path.get_node('LEscalatorStart')
	_r_escalator_start = _path.get_node('REscalatorStart')
	_escalator_sprite = get_tree().get_current_scene().find_child("Escalator")
	_throttle_display_bar = get_tree().get_current_scene().find_child("ThrottleDisplay")
	_reverse_display_sprite = get_tree().get_current_scene().find_child("ReverseDisplay")
	_game_over_panel = get_tree().get_current_scene().find_child("GameOver")
	_score_control = get_tree().get_current_scene().find_child("Score")
	_sfx_crash = get_tree().get_current_scene().find_child("Crash")
	_spawner = get_tree().get_current_scene().find_child("Spawner")
	_chronogram = get_tree().get_current_scene().find_child("Chronogram")
	_configure_level()

func restart():
	_clear_all_passengers()
	_configure_level()
	Engine.time_scale = 1

func connect_passenger_signals(passenger: Passenger):
	passenger.exited_stairs.connect(_on_passenger_exited_escalator)
	passenger.entered_stairs.connect(_on_passenger_boarded_escalator)
	passenger.exited_map.connect(_on_passenger_exited_map)

func _process(delta):
	if _chronogram.is_stage_over():
		_game_over()
	
	_handle_input(delta)
	_update_speed(delta)
		
	_reverse_display_sprite.visible = escalator_speed() < 0
	_throttle_display_bar.value = (abs(escalator_speed()) / ESCALATOR_MAX_SPEED) * 100

	_update_escalator_sprite()

func escalator_speed():
	return _escalator_speed

func _handle_input(delta):
	if Input.is_action_pressed("throttle_up"):
		_throttle += THROTTLE_RATE * delta
	elif Input.is_action_pressed("throttle_down"):
		_throttle -= THROTTLE_RATE * delta
	else:
		_throttle_decay(delta)
	_throttle = min(abs(_throttle), ESCALATOR_MAX_THROTTLE) * sign(_throttle)

func _on_passenger_boarded_escalator(passenger: Passenger):
	_total_weight += passenger.weight
	_escalator_speed -= (passenger.weight / _total_weight) * _escalator_speed * ESCALATOR_WEIGHT_RATE

func _on_passenger_exited_escalator(passenger: Passenger):
	_total_weight -= passenger.weight

func _update_escalator_sprite():
	if _escalator_sprite.animation == 'up' and _escalator_speed < 0:
		_escalator_sprite.animation = 'down'
	if _escalator_sprite.animation == 'down' and _escalator_speed > 0:
		_escalator_sprite.animation = 'up'
	_escalator_sprite.speed_scale = abs(_escalator_speed) * 2.3

func _on_passenger_exited_map(passenger: Passenger):
	_score_control.update(passenger)
	passenger.disable()
	_spawner.add_to_pool(passenger)

func _game_over():
	_spawner.set_spawn(false)
	_game_over_panel.visible = true
	Engine.time_scale = 0

func _throttle_decay(delta):
	var t_sign = sign(_throttle)
	_throttle -= THROTTLE_DECAY * t_sign * delta
	if t_sign != sign(_throttle):
		_throttle = 0

func _update_speed(delta):
	var acceleration = (_throttle / _total_weight) if _total_weight > 1 else _throttle
	_escalator_speed += acceleration * delta
	_escalator_speed = min(_escalator_speed, ESCALATOR_MAX_SPEED)

func _configure_level():
	_chronogram.configure()
	_escalator_speed = 0.0
	_throttle = 0.0
	_score_control.clear()
	_spawner.set_spawn(true)

func _clear_all_passengers():
	for p in _path.get_children():
		if is_instance_of(p, Passenger):
			p.queue_free()
	_spawner.clear_passenger_pools()

func play_crash():
	_sfx_crash.play()
