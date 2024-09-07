extends PassengerState

class_name PassengerStateWaiting

const waiting_area_delta = 0.06

func state_process(_delta):
	if passenger.is_in_position(_escalator_waiting_spot(), waiting_area_delta):
		if _can_board_escalator():
			return transition_walk(Game._r_escalator_start.progress_ratio if passenger._direction == 1 else Game._l_escalator_start.progress_ratio)
		else:
			return self
	if passenger.is_in_waiting_area():
		return transition_walk(_somewhere_around(_escalator_waiting_spot(), waiting_area_delta))
	else:
		return transition_walk(1.0 if passenger._direction == 1 else 0.0)

func transition_walk(destination: float):
	var new_state = PassengerStateWalking.new()
	new_state.passenger = passenger
	new_state.destination = destination
	new_state.can_walk(false)
	passenger.start_walk_timer()
	return new_state

func _escalator_waiting_spot() -> float:
	if passenger._direction == 1:
		return Game._r_waiting_spot.progress_ratio
	else:
		return Game._l_waiting_spot.progress_ratio

func _somewhere_around(spot: float, delta: float):
	return spot - (delta / 2.0) + (randf() * delta)

func _can_board_escalator() -> bool:
	return (passenger._direction == 1 and Game.escalator_speed() > 0) or (passenger._direction == -1 and Game.escalator_speed() < 0)

func name():
	return "Wait"

func animation():
	return "standing"
