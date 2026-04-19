extends CharacterBody2D
 
const  GRAVITY : int = 4200 
const  JUMP_SPEED : int = -1800

func _physics_process(delta):
	velocity.y += GRAVITY * delta
	if is_on_floor():
		if not get_parent().game_running:
			$AnimatedSprite2D.play("Idle")
		else:
			$Ride.disabled = false
			$Ride2.disabled = false
			$"Ride+Down".disabled = false
			$"Ride+Down2".disabled = false
			$Down.disabled = true
			$Down2.disabled = true
			if Input.is_action_pressed("ui_accept"):
				velocity.y = JUMP_SPEED
				$Jump.play()
			elif Input.is_action_pressed("ui_down"): 
				$AnimatedSprite2D.play("Down")
				$Ride.disabled = true
				$Ride2.disabled = true
				$Down.disabled = false
				$Down2.disabled = false
			else:
				$AnimatedSprite2D.play("Ride")
	else:
		$AnimatedSprite2D.play("Jump")
	
	move_and_slide()
