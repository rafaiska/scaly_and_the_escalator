extends ScrollContainer

func _on_check_box_toggled(button_pressed):
	Game._spawn_enabled = button_pressed


func _on_button_pressed():
	Game._spawn_passenger()
