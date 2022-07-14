extends KinematicBody2D

const PlayerHurtSound = preload("res://Player/PlayerHurtSound.tscn")

const acc = 300;
const maxSpeed = 100;
const friction = 40000;
enum {
	MOVE,
	ROLL,
	ATTACK
};
var state = MOVE;
var velocity = Vector2.ZERO;
var rollVelocity = Vector2.RIGHT;
var stats = PlayerStats

onready var animationPlayer = $AnimationPlayer;
onready var animationTree = $AnimationTree;
onready var animationState = animationTree.get("parameters/playback");
onready var swordHitBox = $HitboxPos/SwordHitbox
onready var hurtbox = $Hurtbox
onready var blinkAnimationPlayer = $BlinkAnimationPlayer

func _ready():
	randomize()
	stats.connect("no_health",self,"queue_free")
	animationTree.active = true;
	$HitboxPos/SwordHitbox/CollisionShape2D.disabled = true
	swordHitBox.knockback_vector = rollVelocity


func _process(delta):
	match state:
		MOVE:
			move_state(delta);
		ROLL:
			roll_state(delta);
		ATTACK:
			attack_state(delta);
	
	

func move_state(delta):
	var input_vector = Vector2.RIGHT;
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left");
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up");
	input_vector = input_vector.normalized();
	if input_vector != Vector2.ZERO:
		rollVelocity = input_vector;
		swordHitBox.knockback_vector = input_vector
		
		animationTree.set("parameters/idle/blend_position",input_vector);
		animationTree.set("parameters/run/blend_position",input_vector);
		animationTree.set("parameters/attack/blend_position",input_vector);
		animationTree.set("parameters/roll/blend_position",input_vector);
		animationState.travel("run");
		velocity = velocity.move_toward(input_vector * maxSpeed,acc * delta);
	else:
		animationState.travel("idle");		
		#velocity = velocity.move_toward(Vector2.ZERO,friction * delta);
		velocity = Vector2.ZERO
	move();
	
	if Input.is_action_just_pressed("roll"):
		state = ROLL
	if Input.is_action_just_pressed("attack"):
		state = ATTACK;
func roll_state(delta):
	velocity = rollVelocity * maxSpeed * 1.2;
	animationState.travel("roll");
	move();
	

func attack_state(delta):
	velocity = Vector2.ZERO;
	animationState.travel("attack");
	
func move():
	velocity = move_and_slide(velocity);
		

func roll_animation_finished():
	velocity /= 1.5
	state = MOVE

func attack_animation_finished():
	state = MOVE;


func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invincibility(0.5)
	get_tree().current_scene.add_child(PlayerHurtSound.instance())



func _on_Hurtbox_invincibility_started():
	blinkAnimationPlayer.play("start")


func _on_Hurtbox_invincibility_ended():
		blinkAnimationPlayer.play("stop")
