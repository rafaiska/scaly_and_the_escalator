extends PathFollow2D

class_name Passenger

signal entered_stairs(passenger)
signal exited_stairs(passenger)
signal exited_map(passenger)

var _sprite : AnimatedSprite2D
var _moodlet : Sprite2D
var _move_delay : Timer
var _direction : int
var _passenger_in_front : PathFollow2D
var _weight : float
var speed : float
var _mood : float
var _topple_accel : float = 8
var _state : PassengerState
var _state_name : String

const SLIDE_ACCEL = -0.05
const WALK_SPEED_ABS = 0.05
const DELAY_BEFORE_WALK = 1.0
const POSITION_DELTA_TOLERANCE = 0.01
const MOOD_DECAY_RATE = 0.02

const moodlet_texture_vhappy = preload("res://Assets/moodlet_vhappy.png")
const moodlet_texture_happy = preload("res://Assets/moodlet_happy.png")
const moodlet_texture_serious = preload("res://Assets/moodlet_serious.png")
const moodlet_texture_angry = preload("res://Assets/moodlet_angry.png")
const moodlet_texture_vangry = preload("res://Assets/moodlet_vangry.png")

func start_of_escalator():
	return Game.STAIRS_START if _direction == 1 else Game.STAIRS_END

func end_of_escalator():
	return Game.STAIRS_END if _direction == 1 else Game.STAIRS_START

func is_in_position(position_rate):
	return abs(progress_ratio - position_rate) <= POSITION_DELTA_TOLERANCE

func is_between_spots(spot_a, spot_b):
	if spot_a > spot_b:
		var aux = spot_a
		spot_a = spot_b
		spot_b = aux
	return is_in_position(spot_a) or is_in_position(spot_b) or (progress_ratio > spot_a and progress_ratio < spot_b)

func is_in_waiting_area():
	return (_direction == 1 and is_between_spots(0, Game.STAIRS_START - Game.WAITING_LINE_DIST)) or (_direction == -1 and is_between_spots(Game.STAIRS_END + Game.WAITING_LINE_DIST, 1))

func is_in_escalator():
	return is_between_spots(Game.STAIRS_START, Game.STAIRS_END)

func disable():
	_sprite.visible = false
	set_process(false)

func configure(starting_side, weight, passenger_in_front):
	call_deferred('_configure', starting_side, weight, passenger_in_front)

func get_place_before_in_line():
	return self.progress_ratio - Game.WAITING_LINE_DIST if self._direction == 1 else self.progress_ratio + Game.WAITING_LINE_DIST

func start_walk_timer():
	_move_delay.start(DELAY_BEFORE_WALK)

func end_of_path():
	return 1 if _direction == 1 else 0

func get_topple_accel():
	return _topple_accel

func _configure(starting_side, weight, passenger_in_front):
	assert(starting_side in ['R', 'L'], 'Invalid parameter starting_side')
	
	self._mood = 1.0
	
	self._state = PassengerStateWaiting.new()
	self._state.passenger = self
	
	self._weight = weight
	self._passenger_in_front = passenger_in_front
	if _passenger_in_front != null:
		_passenger_in_front.exited_map.connect(self._on_passenger_in_front_exited)
	
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
	_mood -= MOOD_DECAY_RATE * delta
	_update_moodlet()
	self._state = self._state.state_process(delta)
	if speed > 0:
		progress_ratio = min(progress_ratio + (speed * delta), 1)
	elif speed < 0:
		progress_ratio = max(progress_ratio + (speed * delta), 0)

func _on_move_delay_timeout():
	if _state.has_method('can_walk'):
		self._state.can_walk(true)

func _on_passenger_in_front_exited(passenger: Passenger):
#	assert(passenger == _passenger_in_front)
	passenger.exited_stairs.disconnect(_on_passenger_in_front_exited)
	_passenger_in_front = null

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
