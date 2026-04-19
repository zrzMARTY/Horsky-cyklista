extends Area2D

#voláno po objevení 
func _ready():
	pass
	
func _physics_process(delta):
	var base_speed = get_parent().speed
	position.x -= (base_speed / 2) * delta
	
