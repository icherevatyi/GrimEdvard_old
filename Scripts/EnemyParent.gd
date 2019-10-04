extends KinematicBody2D

var state_machine
var max_health = 100
var current_health 

onready var healthbar = $Enemy_HP_Under/TextureProgress
onready var helthbar_animated = $Enemy_HP_Under/TextureProgress/Tween
onready var red_HP_bar = $Enemy_HP_Upper/TextureProgress
onready var alertPlayer = $Alert/AlertPlayer
onready var alertTimer = $Alert/AlertFadeTimer

export(int) var speed = 50
var velocity = Vector2(0, 0)
var movedir
const GRAVITY = 20
const UP = Vector2(0, -1)

var playerDetected = false
var chasingPlayer = false
var damagePoints = 0
var staggerCount = 0
var movementAlloved = true
onready var  staggerTimer = $Timers/StaggerTimer

signal _spawn_loot
signal _spawn_currency





func _ready():
	self.add_to_group("enemies")
	rand_dir()

	healthbar.max_value = max_health
	healthbar.value = max_health
	red_HP_bar.max_value = max_health
	red_HP_bar.value = max_health
	current_health = max_health

	state_machine = $AnimationTree.get("parameters/playback")
	state_machine.start("idle")


func _physics_process(delta):
	if current_health > 0 and movementAlloved == true:
		movement()
		chase()




# Movement section
func movement():
	velocity.y += GRAVITY	
	velocity.x = movedir * speed	
	if is_on_wall():
		movedir *= -1
		$Sprite.flip_h = !$Sprite.flip_h
		$CollisionShape2D.scale.x *= -1
		$DetectionRange.scale.x *= -1
		rand_dir()
		chasingPlayer = false
		speed = 50
		
	match_movedir()
	
	state_machine.travel("walk")
	move_and_slide(velocity, UP)


func match_movedir():
	match movedir:
		-1:
			$Sprite.flip_h = true
			$DetectionRange.scale.x = -1
			$CollisionShape2D.scale.x = -1
		1:
			$Sprite.flip_h = false
			$DetectionRange.scale.x = 1	
			$CollisionShape2D.scale.x = 1


func _on_MovementChangeTimer_timeout():
	if current_health > 0 and movementAlloved == true:
		rand_dir()


func rand_dir():
	randomize()
	var d = randi() % 2 + 1
	match d:
		1:
			movedir = -1
		2:
			movedir = 1




# Combat section

# Player was seen
func _on_DetectionRange_entered(body):
	if body.name == "Player" and current_health > 0:
		alert()
		playerDetected = true
		# stop movement
		movementAlloved = false


# alert animation started, attacking
func alert():
	alertPlayer.play("alert")
	alertTimer.start()
	# attack
	attack()


func _on_AlertFadeTimer_timeout():
	$Alert.visible = false


# Player starts to run, chasing him
func _on_DetectionRange_exited(body):
	if body.name == "Player" and current_health > 0:
		playerDetected = false
		movementAlloved = true
		chasingPlayer = true


# Chasing function
func chase():
	if chasingPlayer == true:
		speed = 150
		follow_player()


func follow_player():
	var bodies = $ChasingRange.get_overlapping_bodies()
	for body in bodies:
		if body.name == "Player":
			var player_position_x = body.get_global_position().x
			var direction = get_position().x - player_position_x
			if direction > 0:
				movedir = -1
			else:
				movedir = 1


func attack():
	state_machine.travel("attack")


# Player hit landed
func _on_EnemyHitBox_entered(area):
	if area.name == "PlayerWeaponHitRange":
		take_damage()


func _on_damage_received(damage):
	damagePoints = damage


# Damage taken function
func take_damage():
	current_health -= damagePoints
	helthbar_animated.interpolate_property(healthbar, "value", max_health, current_health, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	helthbar_animated.start()
	max_health = current_health
	red_HP_bar.value = max_health
	
	if current_health > 0:
		if playerDetected == false and chasingPlayer == false:
			movementAlloved = false
			state_machine.travel("damaged")
			staggerTimer.start()
		else:
			if staggerCount == 2:
				staggerCount = 0
				state_machine.travel("damaged")
				staggerTimer.start()
			else:
				staggerCount += 1
	else:
		die()


# Returning to attack after stagger
func _on_StaggerTimer_timeout():
	if current_health > 0:
		follow_player()
		match_movedir()
		alert()


func die():
	state_machine.travel("death")
	set_collision_mask_bit(0, false)
	$EnemyHitBox.set_collision_mask_bit(0, false)
	match movedir:
		-1:
			$Sprite.flip_h = true
		1:
			$Sprite.flip_h = false
	set_physics_process(false)


func check_player_status():
	if Global.player_died == true:
		state_machine.travel("idle")