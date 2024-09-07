extends PassengerState

class_name PassengerStateEnd

var notified : bool = false

func state_process(_delta):
	if !notified:
		passenger.exited_map.emit(passenger)
		notified = true
	return self

func name():
	return "Ended"

func animation():
	return "standing"
