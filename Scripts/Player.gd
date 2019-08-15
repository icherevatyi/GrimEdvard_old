extends KinematicBody2D

# movement variables
const UP = Vector2(0, -1)
const GRAVITY = 20
var movement = Vector2(0, 0)
export(int) var speed = 150
export(int) var acceleration = 50
export(int) var jump_height = -300
export(bool) var punch = false

# animation variables
var state_machine
var audio_file

# health management variables
var max_health = 200
var max_health_limit = 200
var current_health
onready var healthbar = $HUD/MainHPBar
onready var health_animation_node = $HUD/MainHPBar/Tween
export(bool) var damage_received
var is_dead = false


# attack variables
export(bool) var timer_start = false
var damage_params = {
	"slash_damage": 30, 
	"shaft_hit": 15
	}

#loot variables
onready var souls_indicator = $HUD/Souls/SoulsIndicator
onready var souls_animator = $HUD/Souls/SoulsIndicator/Tween

var souls_total = 30
var prev_souls
var souls_change
var souls_price = 30
var healing_amount = souls_price * 1.5

#signals
signal _on_pass_damage
signal _on_item_pickup



func _ready():
	Global.player_died = false
	damage_received = false
	state_machine = $AnimationTree.get("parameters/playback")
	current_health = 200
	healthbar.max_value = max_health
	healthbar.value = current_health
	_update_souls_count(0)


# movement section	
func _physics_process(delta):
	_move()
	_attack()
	_block()
	_hurts()
	
func _move():	
	if is_dead == false:
		movement.y += GRAVITY
	
		if Input.is_action_pressed("ui_right"):
			movement.x = min(movement.x + acceleration, speed)
			state_machine.travel("walk")
			$Sprite.flip_h = false
			$CollisionShape2D.scale.x = 1
			$Block.scale.x = 1
			$PlayerWeaponHitRange.scale.x = 1
			
		elif Input.is_action_pressed("ui_left"):
			movement.x = max(movement.x - acceleration, -speed)
			state_machine.travel("walk")
			$Sprite.flip_h = true
			$CollisionShape2D.scale.x = -1
			$Block.scale.x = -1
			$PlayerWeaponHitRange.scale.x = -1
			
		elif Input.is_action_pressed("ui_left_up"):
			if is_on_floor():
				movement.y = jump_height
			else:
				movement.x = max(movement.x - acceleration, -speed)
				$Sprite.flip_h = true
				$CollisionShape2D.scale.x = -1
				$Block.scale.x = -1
				$PlayerWeaponHitRange.scale.x = -1
				
		elif Input.is_action_pressed("ui_right_up"):
			if is_on_floor():
				movement.y = jump_height
			else:
				movement.x = min(movement.x + acceleration, speed)
				$Sprite.flip_h = false
				$CollisionShape2D.scale.x = 1
				$Block.scale.x = 1
				$PlayerWeaponHitRange.scale.x = 1
		
		else:
			movement.x = lerp(movement.x, 0, 0.4)
			state_machine.travel("idle")
			
		if is_on_floor():
			if Input.is_action_just_pressed("ui_up"):
				movement.y = jump_height
			
				
				
		else:
			if movement.y < 0:
				state_machine.travel("jump")
			elif movement.y > 0:
				state_machine.travel("fall")
			else:
				state_machine.travel("idle")
			
	move_and_slide(movement, UP)

# healing and skill using section
func _update_souls_count(souls_change):
	prev_souls = souls_total
	souls_total += souls_change
	souls_animator.interpolate_method(self, "_update_count_text", prev_souls, souls_total, 0.3, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	souls_animator.start()


func _update_count_text(souls_total):
	souls_indicator.text = str(round(souls_total))


func _input(event):
	if event.is_action_pressed("ui_action_1"):
		if souls_total >= 30 and current_health < max_health_limit:
			_heal()
			souls_change = - souls_price
			_update_souls_count(souls_change)


# loot management section	
	
func _heal():
	if current_health < max_health_limit:
		var prev_health = current_health
		current_health += healing_amount
		health_animation_node.interpolate_property(healthbar, "value", prev_health, current_health, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		max_health = current_health
		health_animation_node.start()
		if current_health > max_health_limit:
			current_health = max_health_limit	
		
		audio_file = "res://Resources/audio/player_sounds/player_heal.wav"
		$Audio/SFX.stream = load(audio_file) 
		$Audio/SFX.play()
		$ParticlesAnimation.visible = true
		$ParticlesAnimation/Timer.start()


func _on_souls_received(collected_amount):
	souls_change = collected_amount
	audio_file = "res://Resources/audio/player_sounds/absorb_souls.wav"
	$Audio/SFX.stream = load(audio_file)
	$Audio/SFX.play()
	_update_souls_count(souls_change)


func _on_SoulReceive_timeout():
	$ParticlesAnimation.visible = false

# combat section
func _attack():
	if Input.is_action_pressed("ui_attack") and is_dead == false:
		if timer_start == false:
			movement.x = 0
			state_machine.travel("attack")
			return
		else:
			state_machine.travel("attack_2")
			return
	
func _block():
	if Input.is_action_pressed("ui_block") and is_dead == false:
		movement.x = 0
		$Block.visible = true
		state_machine.travel("block")
		return
	elif Input.is_action_just_released("ui_block") and is_dead == false:
		$Block/CollisionShape2D.disabled = true
		$Block.visible = false

func _slash():
	emit_signal("_on_pass_damage", damage_params.slash_damage)

func _hit():
	emit_signal("_on_pass_damage", damage_params.shaft_hit)

func _hurts():
	if damage_received == true:
		state_machine.travel("hurts")
		movement.x = 0
		movement.y = 0

func _check_living_state():
	if current_health <= 0:
		set_collision_mask_bit(1, false)
		$HitBox.set_collision_mask_bit(1, false)
		state_machine.travel("death")
		Global.player_died = true

func _take_damage(damage):
	damage_received = true
	current_health -= damage
	if current_health <= 0:
		is_dead = true
	health_animation_node.interpolate_property(healthbar, "value", max_health, current_health, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	max_health = current_health
	health_animation_node.start()

func _on_hit(area):
	if area.name == "Bullet":
		$Camera/ScreenShake.start(0.1, 20, 3, 1)
		_take_damage(20)


func _on_damage_dealt(body):
	if body.is_in_group("enemies"):
		if punch == false:
			audio_file = "res://Resources/audio/weapon_attack/player_weapon_hit_1.wav"
		else: 
			audio_file = "res://Resources/audio/weapon_attack/player_weapon_hit_2.wav"
		$Audio/SFX.stream = load(audio_file) 
		$Audio/SFX.play()
		
func _on_death_restart():
	Pause._pause_action()

func _on_player_screen_exited():
	_take_damage(current_health)