extends KinematicBody2D

export (int) var maxSpeed
export (int) var jumpHeight
export (int) var gravity
export (int) var acceleration
export (float) var friction
export (float) var afterjumpTime

enum States{RUNNING,
			IDLE,
			JUMPING,
			FALLING,
			HANGING,
			PULL_UP,
			SLIPPING}
var State = States.IDLE

const UP = Vector2(0, -1)
const MAX_INCLINE = sin(deg2rad(50))

var SHUFFLE_SOUND = load("res://Audio/Shuffle.wav")
var JUMP_SOUND = load("res://Audio/Jump.wav")
var PULL_UP_SOUND = load("res://Audio/Pull Up.wav")
var BOINK_SOUND = load("res://Audio/Boink.wav")

var velocity = Vector2()
var afterjumpReady = false
var cameraDirection = "Left" #Wrong on purpose

var resetPos = Vector2()
func _ready():
	$Afterjump.set_wait_time(afterjumpTime)
	resetPos = global_position
	return
	
func playSound():
	if (State == States.RUNNING):
		if ($MovementAudio.stream != SHUFFLE_SOUND):
			$MovementAudio.stream = SHUFFLE_SOUND
		if (!$MovementAudio.playing):
			$MovementAudio.play()
	return

func playSoundOnce(sound):
	if ($MovementAudio.stream != sound):
		$MovementAudio.stream = sound
	$MovementAudio.play()
	return

func printState():
	match State:
		States.RUNNING:
			print("Running")
		States.IDLE:
			print("Idle")
		States.JUMPING:
			print("Jumping")
		States.FALLING:
			print("Falling")
		States.HANGING:
			print("Hanging")
		States.PULL_UP:
			print("Pull Up")
		States.SLIPPING:
			print("Slipping")
	return

func animate():
	match State:
		States.RUNNING:
			$Sprite.play("Slide")
		States.IDLE:
			$Sprite.play("Idle")
		States.JUMPING:
			$Sprite.play("Jump")
		States.FALLING:
			$Sprite.play("Fall")
		States.HANGING:
			$Sprite.play("Hang")
		States.PULL_UP:
			$Sprite.play("PullUp")
		States.SLIPPING:
			$Sprite.play("Fall")
	return
	
func tweenCamera():
	var finalPosition = Vector2()
	if ($Sprite.flip_h):
		finalPosition = Vector2(-50, 0)
	else:
		finalPosition = Vector2(50, 0)
		
	$Tween.interpolate_property(
		$Camera2D,
		'position',
		$Camera2D.position,
		finalPosition,
		1,
		Tween.TRANS_SINE,
		Tween.EASE_OUT)
	$Tween.start()
	
	return
	
func control(delta):
	var dangling = (State == States.HANGING || State == States.PULL_UP)
	
	if (Input.is_action_pressed("ui_right") && State != States.HANGING && State != States.SLIPPING):
		if (Input.is_action_pressed("ui_shift")):
			velocity.x = min(velocity.x + acceleration * delta,
							maxSpeed / 2 * delta)
		else:
			velocity.x = min(velocity.x + acceleration * delta,
								maxSpeed * delta)
		$Sprite.flip_h = false
		
		if (is_on_floor()):
			State = States.RUNNING
	elif (Input.is_action_pressed("ui_left") && State != States.HANGING && State != States.SLIPPING):
		if (Input.is_action_pressed("ui_shift")):
			velocity.x = max(velocity.x - acceleration * delta,
							-maxSpeed / 2 * delta)
		else:
			velocity.x = max(velocity.x - acceleration * delta,
								-maxSpeed * delta)
		$Sprite.flip_h = true
		
		if (is_on_floor()):
			State = States.RUNNING
	else:
		#Don't slow down when slipping
		if (State != States.SLIPPING):
			velocity.x = lerp(velocity.x, 0, friction)
			
			if (is_on_floor()):
				State = States.IDLE
	
	#Afterjump preparations
	if (is_on_floor()):
		afterjumpReady = true
	else:
		if ($Afterjump.is_stopped() && afterjumpReady):
			$Afterjump.start()
	
	if (!dangling):
		if (Input.is_action_pressed("ui_up") && afterjumpReady && State != States.JUMPING && State != States.SLIPPING):
				velocity.y = -jumpHeight + (velocity.y * 0.2 if velocity.y > 0 else 0)
				State = States.JUMPING
				playSoundOnce(JUMP_SOUND)
	else:
		if (State != States.PULL_UP):
			if (Input.is_action_just_pressed("ui_up")):
				State = States.PULL_UP
				velocity.y = -100
				playSoundOnce(PULL_UP_SOUND)
			elif (Input.is_action_just_pressed("ui_down")):
				State = States.FALLING
	
	#Debug cheats for warping
	if (Input.is_action_just_pressed("ui_page_down")):
		global_position = resetPos
	elif (Input.is_action_just_pressed("ui_page_up")):
		resetPos = global_position
	
	return

func _process(delta):
	animate()
	
	#Checks if the direction the player is facing isn't the direction
	#the camera is facing
	if ($Sprite.flip_h && cameraDirection != "Left"):
		cameraDirection = "Left"
		tweenCamera()
	elif (!$Sprite.flip_h && cameraDirection != "Right"):
		cameraDirection = "Right"
		tweenCamera()
		
	return

func _physics_process(delta):
	#Prevents recatching a ledge
	if (State != States.HANGING && State != States.PULL_UP):
		$LedgeRay.enabled = true
	else:
		$LedgeRay.enabled = false
	
	#Ensures that the ledge-grabbing ray always points in front of the
	#player, relative to his sprite
	if ($Sprite.flip_h):
		$LedgeRay.cast_to = Vector2(0, -5)
	else:
		$LedgeRay.cast_to = Vector2(0, 5)
		
	if ($LedgeRay.is_colliding() && State == States.FALLING):
		State = States.HANGING
		global_position.y += 5 #Magic number to align the grab
	
	#Logic for falling
	if (State != States.HANGING):
		if (velocity.y > 0):
			velocity.y += gravity * 1.2
			
			if (State != States.SLIPPING):
				State = States.FALLING
		else:
			velocity.y += gravity
	else:
		velocity = Vector2()
		
	control(delta)
	
	#If the floor we collided with is steeper than 40 degrees, we consider it
	#a slope. Dot products return the cosine of the angle between them (if
	#they're unit vectors). Also adds some oomf to the x velocity
	#relative to the y velocity, to fling the player
	if (get_slide_count() > 0):
		for i in range(get_slide_count()):
			if (get_slide_collision(i).collider.has_method("isBouncy")):
				State = States.SLIPPING
				velocity = get_slide_collision(i).normal * 1 * abs(velocity.y)
				velocity.x += 1 * get_slide_collision(i).normal.x + (abs(velocity.y) * get_slide_collision(i).normal.x) / 3
				$SlipTimer.start()
				playSoundOnce(BOINK_SOUND)
	#get_slide_count() only updates on move_and_slide
	#MAS on a vertical jump doesn't return kinematic colliders for
	#some reason. This is the hacky solution: Test if the thing we're
	#on is a bouncy thing infinitely
	elif (is_on_floor() && test_move(transform, Vector2(0, 1))):
		var refresh = move_and_collide(Vector2(0, 1))
		if (refresh != null):
			if (refresh.collider.has_method("isBouncy")):
				State = States.SLIPPING
				velocity = refresh.normal * 1 * abs(velocity.y)
				velocity.x += 1 * refresh.normal.x + (abs(velocity.y) * refresh.normal.x) / 3
				$SlipTimer.start()
				playSoundOnce(BOINK_SOUND)
	
	#Stay slipping until you hit the ground
	if (State == States.SLIPPING && $SlipTimer.time_left == 0 && is_on_floor()):
		#&& get_slide_count() > 0 && !get_slide_collision(0).collider.has_method("isBouncy")):
		State = States.IDLE
	
	playSound()

	velocity = move_and_slide(velocity, UP)
	#printState()
	return

func _on_Afterjump_timeout():
	afterjumpReady = false
	return
