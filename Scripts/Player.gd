extends KinematicBody2D

# movement variables
const UP = Vector2(0, -1)
const GRAVITY = 20
var movement = Vector2(0, 0)
export(int) var speed = 150
export(int) var acceleration = 50
export(int) var jump_height = -300
export(bool) var punch = false


onready var GUI = $GUI
onready var healing_animation = $Spells/Heal
onready var healing_animation_timer = $Spells/Heal/Heal_animation_timer

# animation variables
var state_machine
var audio_file

# health management variables
var health_max = 200
var health_current = health_max

export(bool) var damage_received
var is_dead = false

# stamina management variables
var stamina_max = 60
var stamina_current = stamina_max
var stamprice = 20

# attack variables
var is_in_combat = false
export(bool) var timer_start = false
var damage_params = {
	"slash_damage": 30, 
	"shaft_hit": 15
	}
var is_blocking = false

#loot variables
onready var souls_indicator = $GUI/HUD/Souls/SoulsIndicator
onready var souls_animator = $GUI/HUD/Souls/SoulsIndicator/Tween

var souls_total = 30
var prev_souls
var souls_change
var souls_price = 30
var healing_amount = souls_price * 1.5

#signals
signal _on_pass_damage

signal _on_health_ready(max_value)
signal _on_health_change(old_value, new_value, change_duration)

signal _on_stamina_regen_timer_trigger(set_value)
signal _on_stamina_ready(max_value)
signal _on_stamina_change(old_value, new_value, change_duration)


func _ready():
	#connecting signals
	#health
	connect("_on_health_ready", GUI, "_handle_health_ready")
	connect("_on_health_change", GUI, "_handle_health_change")

	#stamina
	connect("_on_stamina_ready", GUI, "_handle_stamina_ready")
	connect("_on_stamina_change", GUI, "_handle_stamina_change")
	connect("_on_stamina_regen_timer_trigger", GUI, "_handle_stamina_regen_timer_trigger")

	emit_signal("_on_health_ready", health_max)
	emit_signal("_on_stamina_ready", 60)

	Global.player_died = false
	damage_received = false
	state_machine = $AnimationTree.get("parameters/playback")
	_update_souls_count(0)



# movement section	
func _physics_process(delta):
	_move()
	_attack()
	_block()
	_hurts()
	_toggle_exp_bar()


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
		print("max: ", health_max)
		print("current: ", health_current)
		if souls_total >= 30 and health_current < health_max:
			_heal()
			souls_change = - souls_price
			_update_souls_count(souls_change)


func _heal():
	var old_value = health_current
	health_current = min(health_current + healing_amount, health_max)
	emit_signal("_on_health_change", old_value, health_current, 0.4 )
	
	audio_file = "res://Resources/audio/player_sounds/player_heal.wav"
	$Audio/SFX.stream = load(audio_file) 
	$Audio/SFX.play()
	healing_animation.visible = true
	healing_animation_timer.start()

func _on_Heal_animation_timer_timeout():
	healing_animation.visible = false
	

func _on_souls_received(collected_amount):
	is_in_combat = false
	souls_change = collected_amount
	audio_file = "res://Resources/audio/player_sounds/absorb_souls.wav"
	$Audio/SFX.stream = load(audio_file)
	$Audio/SFX.play()
	_update_souls_count(souls_change)


# stamina management section
func _stamina_deplete(amount):
	var new_value = stamina_current - amount
	emit_signal("_on_stamina_change", stamina_current, new_value, 0.3)
	stamina_current = new_value


func _manage_stamina():
		if is_in_combat == true:
			if is_blocking == true:
				emit_signal("_on_stamina_regen_timer_trigger", "stop")
			else:
				emit_signal("_on_stamina_regen_timer_trigger", "start")
		else:
			_stamina_regen()
		pass

func _stamina_regen():
	if stamina_current < stamina_max:
		var new_value = stamina_current + 5
		emit_signal("_on_stamina_change", stamina_current, new_value, 0.4)
		stamina_current = new_value


func _on_RegenerationDelay_timeout():
	_stamina_regen()


func _toggle_exp_bar():
	pass


# combat section
func _attack():
	if Input.is_action_pressed("ui_attack") and is_dead == false:
		is_in_combat = true
		if timer_start == false:
			movement.x = 0
			state_machine.travel("attack")
			return
		else:
			state_machine.travel("attack_2")
			return
	

func _block():	
	if Input.is_action_pressed("ui_block") and is_dead == false:
		if stamina_current >= stamprice:
			is_in_combat = true
			movement.x = 0
			$Block.visible = true
			state_machine.travel("block")
			is_blocking = true
			emit_signal("_on_stamina_regen_timer_trigger", "stop")
			return
		else:
			$GUI/DisplayTextMsg/AnimationPlayer.play("msg_show")
	elif Input.is_action_just_released("ui_block") and is_dead == false:
		$Block/CollisionShape2D.disabled = true
		$Block.visible = false
		is_blocking = false
		emit_signal("_on_stamina_regen_timer_trigger", "start")


func _on_Block_area_entered(area):
	if area.is_in_group("enemy_weapons"):
		$Camera/ScreenShake.start(0.1, 18, 3, 1)
		$Block/BlockedStrike.visible = true
		$Block/BlockedStrike.set_emitting(true)
		_get_clash_sound()
		_stamina_deplete(stamprice)


func _get_clash_sound():
	randomize()
	var rand_val = randi() % 3 + 1
	match rand_val: 
		1:
			audio_file = "res://Resources/audio/player_sounds/weapon_clash_1.wav"
		2:
			audio_file = "res://Resources/audio/player_sounds/weapon_clash_2.wav"
		3:
			audio_file = "res://Resources/audio/player_sounds/weapon_clash_3.wav"
	$Audio/SFX.stream = load(audio_file) 
	$Audio/SFX.play()
				
func _slash():
	emit_signal("_on_pass_damage", damage_params.slash_damage)


func _hit():
	emit_signal("_on_pass_damage", damage_params.shaft_hit)


func _hurts():
	if damage_received == true:
		is_in_combat = true
		state_machine.travel("hurts")
		movement.x = 0
		movement.y = 0


func _check_living_state():
	if health_current <= 0:
		set_collision_mask_bit(1, false)
		$HitBox.set_collision_mask_bit(1, false)
		state_machine.travel("death")
		Global.player_died = true


func _take_damage(damage):
	damage_received = true
	var old_value = health_current
	health_current -= damage
	if health_current <= 0:
		is_dead = true
	emit_signal("_on_health_change", old_value, health_current, 0.3 )
	print("max value: ", health_max)
	print("current value: ", health_current)


func _on_hit(area):
	if area.is_in_group("enemy_weapons"):
		$Camera/ScreenShake.start(0.2, 30, 3, 1)
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
	is_in_combat = false
	Pause._pause_action()


func _on_player_screen_exited():
	_take_damage(health_current)
