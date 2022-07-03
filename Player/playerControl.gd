extends KinematicBody2D

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

onready var animationPlayer = $AnimationPlayer;
onready var animationTree = $AnimationTree;
onready var animationState = animationTree.get("parameters/playback");

func _ready():
	animationTree.active = true;

func _process(delta):
	match state:
		MOVE:
			move_state(delta);
		ROLL:
			pass;
		ATTACK:
			attack_state(delta);
	
	

func move_state(delta):
	var input_vector = Vector2.ZERO;
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left");
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up");
	input_vector = input_vector.normalized();
	if input_vector != Vector2.ZERO:
		animationTree.set("parameters/idle/blend_position",input_vector);
		animationTree.set("parameters/run/blend_position",input_vector);
		animationTree.set("parameters/attack/blend_position",input_vector);
		animationState.travel("run");
		velocity = velocity.move_toward(input_vector * maxSpeed,acc * delta);
	else:
		animationState.travel("idle");		
		velocity = velocity.move_toward(Vector2.ZERO,friction * delta);
		
	velocity = move_and_slide(velocity);
	if Input.is_action_just_pressed("attack"):
		state = ATTACK;

func attack_state(delta):
	velocity = Vector2.ZERO;
	animationState.travel("attack");
	
func attack_animation_finished():
	state = MOVE;