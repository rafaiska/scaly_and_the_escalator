extends Panel

func _on_restart_button_pressed():
	visible = false
	Game.restart()
