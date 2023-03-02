extends Control

var duck_count = 0

func _on_duckhead_collected():
	duck_count = duck_count + 1
	$Label.text = String(duck_count)
