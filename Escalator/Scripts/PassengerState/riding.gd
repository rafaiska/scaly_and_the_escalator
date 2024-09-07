extends PassengerState

class_name PassengerStateRiding

var current_animation = "standing"

func state_process(_delta):
	_fix_position()
	
	passenger.speed = Game.escalator_speed()
	
	if _passenger_toppled():
		return transition_falling(passenger.speed)
	
	if abs(passenger.speed) > passenger.get_topple_speed() * 0.8:
		current_animation = "woah"
	else:
		current_animation = "standing"
	
	if passenger.is_in_position(passenger.end_of_escalator()):
		passenger.speed = 0
		return transition_walk(passenger.end_of_path())
	
	passenger.speed = Game.escalator_speed()
	return self

func transition_walk(destination):
	var new_state = PassengerStateWalking.new()
	new_state.passenger = passenger
	new_state.destination = destination
	new_state.can_walk(true)
	passenger.exited_stairs.emit(passenger)
	return new_state

func transition_falling(rotation_speed):
	var new_state = PassengerStateFalling.new()
	new_state.passenger = passenger
	new_state.rotate(rotation_speed)
	passenger.exited_stairs.emit(passenger)
	return new_state

func _fix_position():
	if passenger._direction == 1:
		passenger.progress_ratio = max(Game._r_escalator_start.progress_ratio, passenger.progress_ratio)
	elif passenger._direction == -1:
		passenger.progress_ratio = min(Game._l_escalator_start.progress_ratio, passenger.progress_ratio)
	else:
		assert(false, 'Wrong direction')

func _passenger_toppled() -> bool:
	return abs(passenger.speed) > passenger.get_topple_speed()

func name():
	return "Riding"

func animation():
	return current_animation
