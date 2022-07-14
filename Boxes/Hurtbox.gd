extends Area2D

const HitEffect = preload("res://Effects/HitEffect.tscn")
export(bool) var show_hit = true
var invincible = false setget set_invincible
signal invincibility_started
signal invincibility_ended
onready var timer = $Timer

func set_invincible(value):
	invincible = value
	if invincible:
		emit_signal("invincibility_started")
	else:
		emit_signal("invincibility_ended")

func start_invincibility(duration):
	self.invincible = true
	timer.start(duration)

func _on_Hurtbox_area_entered(area):
	if show_hit :
		create_hitEffect()

func create_hitEffect():
	var hitEffect = HitEffect.instance()
	get_tree().current_scene.add_child(hitEffect)
	hitEffect.global_position = global_position


func _on_Timer_timeout():
	self.invincible = false


func _on_Hurtbox_invincibility_started():
	set_deferred("monitorable",false)


func _on_Hurtbox_invincibility_ended():
	monitorable = true
