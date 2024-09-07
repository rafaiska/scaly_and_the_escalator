extends Control

class_name ScoreControl

var score_label : RichTextLabel
var score: int = 0
var score_buffer: int = 0

const SCORE_UPDATE_RATE = 10

func clear():
	score = 0
	score_buffer = 0

func update(passenger: Passenger):
	score_buffer += int(passenger._mood * 10.0)

func _ready():
	score_label = $ScorePanel/ScoreText

func _process(_delta):
	if score_buffer > 0:
		var transfer = max(int(_delta * SCORE_UPDATE_RATE), 1)
		score_buffer -= transfer
		score += transfer
		
	score_label.text = '%06d' % score
