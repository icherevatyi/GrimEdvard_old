extends CanvasLayer

onready var health_bar = $HUD/HPBar
onready var health_animation_node = $HUD/HPBar/Tween

onready var stamina_bar = $HUD/StaminaBar
onready var stamina_animation_node = $HUD/StaminaBar/Tween
onready var stamina_regeneration_delay_timer = $HUD/StaminaBar/RegenerationDelay

onready var souls_indicator = $HUD/Souls/SoulsIndicator
onready var souls_animator = $HUD/Souls/SoulsIndicator/Tween



func _handle_health_ready(max_value):
	health_bar.max_value = max_value
	health_bar.value = max_value

func _handle_health_change(old_value, new_value, change_duration):
	health_animation_node.interpolate_property(health_bar, "value", old_value, new_value, change_duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	health_animation_node.start()

func _handle_stamina_ready(max_value):
	stamina_bar.max_value = max_value
	stamina_bar.value = max_value

func _handle_stamina_regen_timer_trigger(set_state):
	match set_state:
		"start":
			stamina_regeneration_delay_timer.start()
		"stop":
			stamina_regeneration_delay_timer.stop()

func _handle_stamina_change(old_value, new_value, change_duration):
	stamina_animation_node.interpolate_property(stamina_bar, "value", old_value, new_value, change_duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	stamina_animation_node.start()

func _handle_souls_ready(current_value):
	souls_indicator.text = str(round(current_value))
	
func _update_count_text(souls_total):
	souls_indicator.text = str(round(souls_total))

func _handle_souls_change(old_value, new_value, change_duration):
	souls_animator.interpolate_method(self, "_update_count_text", old_value, new_value, change_duration, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	souls_animator.start()