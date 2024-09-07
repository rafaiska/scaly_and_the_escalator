extends PathFollow2D

class_name Passenger

signal entered_stairs(passenger)
signal exited_stairs(passenger)
signal exited_map(passenger)

var _sprite : AnimatedSprite2D
var _moodlet : Sprite2D
var _move_delay : Timer
var _direction : int
var speed : float
var _mood : float
var _state : PassengerState
var _state_name : String

@export var weight: float
@export var mood_decay_rate: float
@export var walk_speed: float
@export var passenger_type: String

const SLIDE_ACCEL = -0.05
const DELAY_BEFORE_WALK = 1.0
const POSITION_DELTA_TOLERANCE = 0.01
const TOPPLE_SPEED_RATE = 0.4

const moodlet_texture_vhappy = preload("res://Assets/moodlet_vhappy.png")
const moodlet_texture_happy = preload("res://Assets/moodlet_happy.png")
const moodlet_texture_serious = preload("res://Assets/moodlet_serious.png")
const moodlet_texture_angry = preload("res://Assets/moodlet_angry.png")
const moodlet_texture_vangry = preload("res://Assets/moodlet_vangry.png")

func reached_destination():
	return is_in_position(end_of_path())

func reached_start():
	return is_in_position(start_of_path())

func start_of_escalator():
	return Game._r_escalator_start.progress_ratio if _direction == 1 else Game._l_escalator_start.progress_ratio

func end_of_escalator():
	return Game._l_escalator_start.progress_ratio if _direction == 1 else Game._r_escalator_start.progress_ratio

func is_in_position(position_rate, tolerance=POSITION_DELTA_TOLERANCE):
	return abs(progress_ratio - position_rate) <= tolerance

func is_between_spots(spot_a, spot_b):
	if spot_a > spot_b:
		var aux = spot_a
		spot_a = spot_b
		spot_b = aux
	return is_in_position(spot_a) or is_in_position(spot_b) or (progress_ratio > spot_a and progress_ratio < spot_b)

func is_in_waiting_area():
	return (_direction == 1 and is_between_spots(0, Game._r_escalator_start.progress_ratio)) or (_direction == -1 and is_between_spots(Game._l_escalator_start.progress_ratio, 1))

func is_in_escalator():
	return is_between_spots(Game._r_escalator_start.progress_ratio, Game._l_escalator_start.progress_ratio)

func disable():
	_sprite.visible = false
	set_process(false)

func configure(starting_side):
	call_deferred('_configure', starting_side)

func start_walk_timer():
	_move_delay.start(DELAY_BEFORE_WALK)

func end_of_path():
	return 1.0 if _direction == 1 else 0.0

func start_of_path():
	return 0.0 if _direction == 1 else 1.0

func get_topple_speed():
	return weight * TOPPLE_SPEED_RATE

func _configure(starting_side):
	assert(starting_side in ['R', 'L'], 'Invalid parameter starting_side')
	
	self._mood = 1.0
	$Sprite.flip_h = starting_side == 'R'
	
	self._state = PassengerStateWaiting.new()
	self._state.passenger = self
	
	_direction = 1 if starting_side == 'R' else -1
	progress_ratio = 0 if starting_side == 'R' else 1
	
	_sprite.visible = true
	set_process(true)

func _ready():
	_sprite = $Sprite
	_move_delay = $MoveDelay
	_moodlet = $Moodlet
	_move_delay.timeout.connect(self._on_move_delay_timeout)

func _process(delta):
	_state_name = _state.name()
	_mood -= mood_decay_rate * delta
	_update_moodlet()
	self._state = self._state.state_process(delta)
	_update_animation(self._state.animation())
	if speed > 0:
		progress_ratio = min(progress_ratio + (speed * delta), 1)
	elif speed < 0:
		progress_ratio = max(progress_ratio + (speed * delta), 0)

func _on_move_delay_timeout():
	if _state.has_method('can_walk'):
		self._state.can_walk(true)

func _update_moodlet():
	if _mood > 0.8:
		_moodlet.texture = moodlet_texture_vhappy
	elif _mood > 0.6:
		_moodlet.texture = moodlet_texture_happy
	elif _mood > 0.4:
		_moodlet.texture = moodlet_texture_serious
	elif _mood > 0.2:
		_moodlet.texture = moodlet_texture_angry
	else:
		_moodlet.texture = moodlet_texture_vangry

func _update_animation(animation_name: String):
	if $Sprite.animation != animation_name:
		$Sprite.animation = animation_name
		$Sprite.play()
