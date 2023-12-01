extends PassengerState

class_name PassengerStateWaiting

func state_process(delta):
	if passenger.is_in_position(_escalator_waiting_spot()) and _can_board_escalator():
		return _try_transition_walk(Game.STAIRS_START if passenger._direction == 1 else Game.STAIRS_END)

	if self.passenger._passenger_in_front != null and passenger._passenger_in_front.is_in_waiting_area():
		return _try_transition_walk(passenger._passenger_in_front.get_place_before_in_line())
	else:
		return _try_transition_walk(_escalator_waiting_spot())

func transition_walk(destination: float):
	var new_state = PassengerStateWalking.new()
	new_state.passenger = passenger
	new_state.destination = destination
	new_state.can_walk(false)
	passenger.start_walk_timer()
	return new_state

func _try_transition_walk(destination: float):
	if passenger._direction == 1 and passenger.progress_ratio < destination:
		return transition_walk(destination)
	elif passenger._direction == -1 and passenger.progress_ratio > destination:
		return transition_walk(destination)
	else:
		return self

func _escalator_waiting_spot() -> float:
	return Game.STAIRS_START - Game.WAITING_LINE_DIST if passenger._direction == 1 else Game.STAIRS_END + Game.WAITING_LINE_DIST

func _can_board_escalator() -> bool:
	return (passenger._direction == 1 and Game.escalator_speed() > 0) or (passenger._direction == -1 and Game.escalator_speed() < 0)
