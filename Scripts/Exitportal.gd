extends Area

# level needed to load
export (PackedScene) var load_level

# when player enters
func _on_Exit_body_entered(_body):
	get_tree().change_scene_to(load_level)
	# if
