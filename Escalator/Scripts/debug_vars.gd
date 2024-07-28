extends ScrollContainer

var speed_l: Label

func _ready():
	speed_l = $Speed

func _process(delta):
	speed_l.text = 'Speed: %1.2f' % Game.escalator_speed()
