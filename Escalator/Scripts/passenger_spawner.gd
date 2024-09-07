extends Node

class_name PassengerSpawner

@export var escalator_path: Path2D
@export var spawn_chronogram: Chronogram

var passenger_pools: Dictionary
var passenger_packed_scenes: Dictionary
var _spawn_timer: float
var _spawn_enabled: bool = false

func clear_passenger_pools():
	for pool in passenger_pools.values():
		pool.clear()

func add_to_pool(passenger: Passenger):
	_get_pool(passenger.passenger_type).append(passenger)

func set_spawn(toggle: bool):
	_spawn_enabled = toggle

func _spawn_passenger():
	var starting_side = 'L' if randi() % 2 == 1 else 'R'
	var new_passenger = _create_or_fetch_from_pool(spawn_chronogram.get_next_passenger_type())
	new_passenger.configure(starting_side)

func _create_or_fetch_from_pool(passenger_type: String) -> Passenger:
	var new_passenger : Passenger
	var pool = _get_pool(passenger_type)
	if pool.size() > 0:
		new_passenger = pool.pop_front()
	else:
		new_passenger = _get_passenger_packed_scene(passenger_type).instantiate()
		Game.connect_passenger_signals(new_passenger)
		escalator_path.add_child(new_passenger)
	return new_passenger

func _get_pool(passenger_type: String):
	if not passenger_pools.has(passenger_type):
		passenger_pools[passenger_type] = []
	return passenger_pools[passenger_type]

func _get_passenger_packed_scene(passenger_type: String) -> PackedScene:
	if not passenger_packed_scenes.has(passenger_type):
		passenger_packed_scenes[passenger_type] = load('res://Scenes/Passenger/' + passenger_type + '.tscn')
	return passenger_packed_scenes[passenger_type]

func _ready():
	passenger_pools = {}
	_spawn_timer = 0

func _process(delta):
	if not _spawn_enabled:
		return
		
	_spawn_timer -= delta
	if _spawn_timer <= 0:
		_spawn_timer = 1 / spawn_chronogram.get_current_spawn_rate()
		if _spawn_enabled:
			_spawn_passenger()
