extends Node

const STAIRS_START : float = 0.18
const STAIRS_END : float = 0.59
const WAITING_LINE_DIST : float = 0.07
const PASSENGER_SCENE : Resource = preload("res://Scenes/passenger.tscn")
const THROTTLE_RATE : float = 1
const ESCALATOR_MAX_THROTTLE : float = 5
const ESCALATOR_MAX_ACCEL : float = 1
const ESCALATOR_MAX_SPEED : float = 1
const ESCALATOR_PULL_SPEED : float = 0.05
const ESCALATOR_WEIGHT : float = 3
const THROTTLE_DECAY : float = 2.5
const GLOBAL_MOOD_MAX : float = 5
const STARTING_PASSENGER_SPAWN_RATE : float = 0.2
const PASSENGER_SPAWN_INCREASE_RATE : float = 0.001

var _spawn_timer : float
var _spawn_rate : float
var _path : Path2D
var _escalator_sprite : AnimatedSprite2D
var _throttle_display_bar : TextureProgressBar
var _reverse_display_sprite : Sprite2D
var _game_over_panel : Panel
var _last_spawned_passenger_L : PathFollow2D
var _last_spawned_passenger_R : PathFollow2D
var _throttle : float
var _friction : float
var _key_pressed_counter : float
var _key_pressed : String
var _total_weight : float
var _escalator_speed : float
var _passenger_pool : Array
var _global_mood : float
var _mood_bar : TextureProgressBar
var _score_panel : ScorePanel
var _total_score : int

# Called when the node enters the scene tree for the first time.
func _ready():
	_path = get_tree().get_current_scene().find_child("Path2D")
	_escalator_sprite = get_tree().get_current_scene().find_child("Escalator")
	_throttle_display_bar = get_tree().get_current_scene().find_child("ThrottleDisplay")
	_reverse_display_sprite = get_tree().get_current_scene().find_child("ReverseDisplay")
	_game_over_panel = get_tree().get_current_scene().find_child("GameOver")
	_mood_bar = get_tree().get_current_scene().find_child("MoodBarFrame").find_child("MoodBar")
	_score_panel = get_tree().get_current_scene().find_child("ScorePanel")
	_configure_level()

func restart():
	_clear_all_passengers()
	_configure_level()
	Engine.time_scale = 1

func get_passengers_in_line(side) -> Array[PathFollow2D]:
	assert(side in ['R', 'L'], 'Invalid parameter side')
	var passengers = []
	var line_start = 0.0 if side == 'L' else STAIRS_END + WAITING_LINE_DIST
	var line_end = STAIRS_START - WAITING_LINE_DIST if side == 'L' else 1.0
	for c in _path.get_children():
		if line_start <= c.progress_ratio <= line_end:
			passengers.append(c)
	return passengers

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _global_mood <= 0:
		_game_over()
	
	_update_mood_bar()
	_handle_spawn(delta)
	_handle_input(delta)
	_throttle_decay(delta)
	_calculate_friction()
	_update_speed(delta)
		
	_reverse_display_sprite.visible = _throttle < 0
	_throttle_display_bar.value = (abs(_throttle) / ESCALATOR_MAX_THROTTLE) * 100

	_update_escalator_sprite()

func escalator_speed():
	return _escalator_speed

func _spawn_passenger(starting_side):
	var new_passenger = _create_or_fetch_from_pool()
	
	var passenger_before = _last_spawned_passenger_L if starting_side == 'L' else _last_spawned_passenger_R
	new_passenger.configure(starting_side, 1.0, passenger_before)
	if starting_side == 'L':
		_last_spawned_passenger_L = new_passenger
	else:
		_last_spawned_passenger_R = new_passenger

func _create_or_fetch_from_pool() -> Passenger:
	var new_passenger : Passenger
	if _passenger_pool.size() > 0:
		new_passenger = _passenger_pool.pop_front()
	else:
		new_passenger = PASSENGER_SCENE.instantiate()
		new_passenger.exited_stairs.connect(_on_passenger_exited_escalator)
		new_passenger.entered_stairs.connect(_on_passenger_boarded_escalator)
		new_passenger.exited_map.connect(_on_passenger_exited_map)
		_path.add_child(new_passenger)
	return new_passenger

func _handle_spawn(delta):
	_spawn_rate += delta * PASSENGER_SPAWN_INCREASE_RATE
	_spawn_timer -= delta
	if _spawn_timer <= 0:
		_spawn_timer = 1 / _spawn_rate
		print(_spawn_timer)
		_spawn_passenger('L' if randi() % 2 == 1 else 'R')

func _handle_input(delta):
	if _key_pressed != "" and Input.is_action_just_released(_key_pressed):
		_key_pressed = ""
		_key_pressed_counter = 0
	
	if Input.is_action_pressed("throttle_up"):
		_key_pressed = "throttle_up"
		_key_pressed_counter += delta
		_throttle += _key_pressed_counter * THROTTLE_RATE
	elif Input.is_action_pressed("throttle_down"):
		_key_pressed = "throttle_down"
		_key_pressed_counter += delta
		_throttle -= _key_pressed_counter * THROTTLE_RATE
	_throttle = min(abs(_throttle), ESCALATOR_MAX_THROTTLE) * sign(_throttle)

func _on_passenger_boarded_escalator(passenger: Passenger):
	_total_weight += passenger._weight

func _on_passenger_exited_escalator(passenger: Passenger):
	_total_weight -= passenger._weight

func _update_escalator_sprite():
	if _escalator_sprite.animation == 'up' and _escalator_speed < 0:
		_escalator_sprite.animation = 'down'
	if _escalator_sprite.animation == 'down' and _escalator_speed > 0:
		_escalator_sprite.animation = 'up'
	_escalator_sprite.speed_scale = abs(_escalator_speed) / ESCALATOR_MAX_SPEED

func _on_passenger_exited_map(passenger: Passenger):
	_global_mood += passenger._mood - 0.5
	_total_score += int(passenger._mood * 10)
	_score_panel.set_score(_total_score)
	passenger.disable()
	_passenger_pool.append(passenger)

func _game_over():
	_game_over_panel.visible = true
	Engine.time_scale = 0

func _throttle_decay(delta):
	var t_sign = sign(_throttle)
	_throttle -= THROTTLE_DECAY * t_sign * delta
	if t_sign != sign(_throttle):
		_throttle = 0

func _calculate_friction():
	_friction = _total_weight * sign(_escalator_speed) * -1

func _update_speed(delta):
	var acceleration = (_throttle + _friction) / _total_weight
	_escalator_speed = min(abs(_escalator_speed + (acceleration * delta)), ESCALATOR_MAX_SPEED) * sign(_escalator_speed + (acceleration * delta))
	if _throttle == 0 and abs(_escalator_speed) < ESCALATOR_PULL_SPEED:
		_escalator_speed = 0

func _update_mood_bar():
	_mood_bar.value = (_global_mood / GLOBAL_MOOD_MAX) * 100

func _configure_level():
	_spawn_rate = STARTING_PASSENGER_SPAWN_RATE
	_spawn_timer = 1 / _spawn_rate
	_escalator_speed = 0.0
	_total_weight = ESCALATOR_WEIGHT
	_throttle = 0.0
	_global_mood = GLOBAL_MOOD_MAX / 2.0
	_total_score = 0

func _clear_all_passengers():
	for p in _path.get_children():
		p.queue_free()
	_passenger_pool.clear()
