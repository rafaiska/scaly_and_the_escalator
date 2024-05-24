extends PassengerState

class_name PassengerStateFalling

var _fall_speed : float = 0.0
var _rotation_speed : float = 0.0

const STOPPED_TOLERANCE = 0.05
const ROTATION_RATE = 50
const GRAVITY = -1
const FRICTION = 0.2

func state_process(delta):
	passenger._mood = 0
	passenger._sprite.rotation -= _rotation_speed * delta
	if passenger.is_in_escalator():
		_fall_speed += GRAVITY * delta
		passenger.speed = Game.escalator_speed() + _fall_speed
	else:
		passenger.speed -= FRICTION * delta * sign(passenger.speed)
	
	if !passenger.is_in_escalator() and abs(passenger.speed) < STOPPED_TOLERANCE:
		passenger.speed = 0
		passenger._sprite.rotation = 0
		return transition_walk()
	
	return self

func transition_ride():
	var new_state = PassengerStateRiding.new()
	new_state.passenger = passenger
	return new_state

func transition_walk():
	var new_state = PassengerStateWalking.new()
	var destination = _get_destination()
	new_state.passenger = passenger
	return new_state

func _get_destination():
	if passenger.is_between_spots(passenger.end_of_escalator(), passenger.end_of_path()):
		return passenger.end_of_path()
	else:
		return passenger.start_of_escalator()

func rotate(rspeed: float):
	_rotation_speed = rspeed * ROTATION_RATE

func name():
	return "Falling"
