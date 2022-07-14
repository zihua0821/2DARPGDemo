extends KinematicBody2D

var knockback = Vector2.ZERO
onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var sprite = $AnimateSprite
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController
onready var blinkAnimationPlayer = $AnimationPlayer
onready var hurtbox = $Hurtbox

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

enum {
	IDLE,
	WANDER,
	CHASE
}

var state = IDLE
var velocity = Vector2.ZERO
export var acc = 200
export var max_seppd = 50
export var fric = 200

func _ready():
	var arr = [IDLE,WANDER]
	state = pick_random_state(arr)

func _process(delta):
	knockback = knockback.move_toward(Vector2.ZERO,fric * delta)
	knockback = move_and_slide(knockback)
	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO,fric * delta)
			seek_player()
			if wanderController.get_time_left() == 0:
				var arr = [IDLE,WANDER]
				state = pick_random_state(arr)
				wanderController.start_wander_timer(rand_range(1,3))
		WANDER:
			seek_player()
			if wanderController.get_time_left() == 0:
				var arr = [IDLE,WANDER]
				state = pick_random_state(arr)
				wanderController.start_wander_timer(rand_range(1,3))
			
			var direction = global_position.direction_to(wanderController.target_position)
			velocity = velocity.move_toward(direction * max_seppd,acc * delta)
			sprite.flip_h = velocity.x < 0			
			
			if global_position.distance_to(wanderController.target_position) <= 4:
				var arr = [IDLE,WANDER]
				state = pick_random_state(arr)
				wanderController.start_wander_timer(rand_range(1,3))
		CHASE:
			var player = playerDetectionZone.player
			if player != null:
				var playerDirection = global_position.direction_to(player.global_position)
				velocity = velocity.move_toward(playerDirection * max_seppd,acc * delta)
			else:
				state = IDLE
			sprite.flip_h = velocity.x < 0			
			seek_player()
			
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 400
	velocity = move_and_slide(velocity)

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE
	
func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage	
	knockback = area.knockback_vector * 120
	hurtbox.start_invincibility(0.4)


func _on_Stats_no_health():
	queue_free()
	create_EnemyDeathEffect()


func create_EnemyDeathEffect():
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()


func _on_Hurtbox_invincibility_started():
	blinkAnimationPlayer.play("start")


func _on_Hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("stop")
