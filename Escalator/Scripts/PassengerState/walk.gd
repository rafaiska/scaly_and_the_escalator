extends PassengerState

class_name PassengerStateWalking

var _can_walk : bool
var destination : float

func state_process(_delta):
	_fix_destination()
	var current_direction = sign(destination - passenger.progress_ratio)
	passenger.speed = current_direction * passenger.walk_speed if _can_walk else 0.0

	if _reached_destination():
		if passenger.is_in_escalator():
			return transition_ride()
		
		passenger.speed = 0.0
		passenger.progress_ratio = destination
		if passenger.progress_ratio == passenger.end_of_path():
			return transition_end()
		else:
			return transition_wait()
	
	return self

func transition_ride():
	var new_state = PassengerStateRiding.new()
	new_state.passenger = passenger
	passenger.entered_stairs.emit(passenger)
	return new_state

func transition_wait():
	var new_state = PassengerStateWaiting.new()
	new_state.passenger = passenger
	return new_state

func transition_end():
	var new_state = PassengerStateEnd.new()
	new_state.passenger = passenger
	return new_state
	

func can_walk(toggle : bool):
	_can_walk = toggle

func _reached_destination() -> bool:
	return passenger.is_in_position(destination)

func _fix_destination():
	assert(destination != null, 'Walk state without destination set')
	if destination > 1:
		destination = 1
	elif destination < 0:
		destination = 0

func name():
	return "Walk"

func animation():
	return "walking"
