extends PassengerState

class_name PassengerStateRiding

const TOPPLE_ACCEL = 8

func state_process(delta):
	_fix_position()
	
	var previous_speed = passenger.speed
	passenger.speed = Game.escalator_speed()
	
	if _passenger_toppled(previous_speed, delta):
		return transition_falling(previous_speed - passenger.speed)
	
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
	return new_state

func transition_falling(rotation_speed):
	var new_state = PassengerStateFalling.new()
	new_state.passenger = passenger
	new_state.rotate(rotation_speed)
	return new_state

func _fix_position():
	if passenger._direction == 1:
		passenger.progress_ratio = max(Game.STAIRS_START, passenger.progress_ratio)
	elif passenger._direction == -1:
		passenger.progress_ratio = min(Game.STAIRS_END, passenger.progress_ratio)
	else:
		assert(false, 'Wrong direction')

func _passenger_toppled(previous_speed, delta) -> bool:
	return (abs(passenger.speed - previous_speed) / delta) > TOPPLE_ACCEL
