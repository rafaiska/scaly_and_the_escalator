extends Panel

class_name ScorePanel

var score_label : RichTextLabel

func _ready():
	score_label = $ScoreText

func set_score(new_score: int):
	score_label.text = '%06d' % new_score
