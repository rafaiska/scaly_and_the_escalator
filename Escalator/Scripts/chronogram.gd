extends Node

class_name Chronogram

var c_tables: Array
var current_table_index: int
var timer: float
var next_table_t: float

@export var stage_length: float
@export var clock_text: RichTextLabel

func _init():
	c_tables = []
	c_tables.append([0, {'HouseHusband': 1, 'HouseWife': 1}, 0.1])
	c_tables.append([10, {'HouseHusband': 1, 'HouseWife': 1}, 0.3])
	c_tables.append([20, {'HouseHusband': 1, 'HouseWife': 1}, 1.0])
	c_tables.append([30, {'HouseHusband': 1, 'HouseWife': 1}, 0.3])
	c_tables.append([80, {'HouseHusband': 1, 'HouseWife': 1}, 1.0])
	c_tables.append([90, {'HouseHusband': 1, 'HouseWife': 1}, 0.4])
	c_tables.append([110, {'HouseHusband': 1, 'HouseWife': 1}, 0.05])

func configure():
	timer = 0
	current_table_index = 0
	next_table_t = _get_next_table_t()

func get_current_spawn_rate():
	_update_chrono_table()
	return c_tables[current_table_index][2]

func get_next_passenger_type():
	_update_chrono_table()
	return _roll_ranks(c_tables[current_table_index][1])

func get_mall_time():
	var mall_minutes = (timer / stage_length) * 720.0
	var hours = 10
	while (mall_minutes > 60):
		mall_minutes -= 60
		hours += 1
	return [hours, int(mall_minutes)]

func is_stage_over():
	return timer >= stage_length

func _roll_ranks(ranks: Dictionary):
	var ranks_val_sum = ranks.values().reduce(func(a, n): return a + n, 0)
	var roll = randf() * float(ranks_val_sum)
	for passenger_type in ranks:
		if roll <= ranks[passenger_type]:
			return passenger_type
		else:
			roll -= ranks[passenger_type]
	push_error('Unexpected error in passenger spawn roll')
	
func _update_chrono_table():
	if next_table_t > 0 and timer >= next_table_t:
		current_table_index += 1
		next_table_t = _get_next_table_t()

func _get_next_table_t():
	var next_index = current_table_index + 1
	if next_index >= c_tables.size():
		return -1.0
	else:
		return c_tables[next_index][0]

func _process(delta):
	if timer < stage_length:
		timer += delta
		clock_text.text = '%02d:%02d' % get_mall_time()
