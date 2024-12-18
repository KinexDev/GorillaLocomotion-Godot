extends Node

@export var max_jump_speed:float = 7
@export var drag:float = 1
@export var jump_multiplier:float = 1
@export var velocity_limit:float = 0.4
@export var velocity_history_size:int = 8

@onready var player:CharacterBody3D = $Player
@onready var player_collision:CollisionShape3D = $Player/Collision
@onready var head:Node3D = $Player/XROrigin3D/Head
@onready var left_hand:Node3D = $Player/XROrigin3D/LeftHand/Follow
@onready var right_hand:Node3D = $Player/XROrigin3D/RightHand/Follow
@onready var left_hand_follower:CharacterBody3D = $LeftHandFollower
@onready var right_hand_follower:CharacterBody3D = $RightHandFollower

var velocity_history:Array[Vector3] = []
var previous_position:Vector3
var velocity_average:Vector3
var velocity_index:int

var is_moving:bool
var is_left_hand_colliding:bool
var is_right_hand_colliding:bool

func _ready() -> void:
	init()

func _process(delta:float) -> void:
	player_collision.global_position = head.global_position - Vector3(0, 0.25, 0)
	
	if not player.is_on_floor():
		player.velocity += Vector3.DOWN * delta * 9.8
	else:
		player.velocity *= 1 - (drag * delta * (1 - player.get_floor_angle()))
	move_followers(true, delta)

	var left_hand_velocity = left_hand_follower.global_position - left_hand.global_position
	var right_hand_velocity = right_hand_follower.global_position - right_hand.global_position
	var movement = Vector3.ZERO
	
	if is_left_hand_colliding and is_right_hand_colliding:
		movement = (left_hand_velocity + right_hand_velocity) / 2
	else:
		movement = (left_hand_velocity if is_left_hand_colliding else Vector3.ZERO) + (right_hand_velocity if is_right_hand_colliding else Vector3.ZERO) 
	
	if is_left_hand_colliding or is_right_hand_colliding:
		player.velocity = movement / delta
		is_moving = true
	elif is_moving:
		if velocity_average.length() > velocity_limit:
			if velocity_average.length() * jump_multiplier > max_jump_speed:
				player.velocity = velocity_average.normalized() * max_jump_speed
			else:
				player.velocity = jump_multiplier * velocity_average
		else:
			player.velocity = Vector3.ZERO
		is_moving = false
		pass
	
	player.move_and_slide()
	
	move_followers(false, delta)
	
	store_velocities(delta)

func move_followers(include_velocity:bool, delta:float) -> void:
	delta = clampf(delta, 0.0005, 1)
	# stick force helps player stick to the ground while on the floor so movement doesn't feel odd

	var additional_force = Vector3.DOWN * 2 * 9.8 * delta * delta if include_velocity else Vector3.ZERO
	
	left_hand_follower.velocity = (left_hand.global_position - left_hand_follower.global_position) + additional_force
	right_hand_follower.velocity = (right_hand.global_position - right_hand_follower.global_position) + additional_force
	
	var left_hand_collision = left_hand_follower.move_and_collide(left_hand_follower.velocity, false, 0.0000001, true)
	var right_hand_collision = right_hand_follower.move_and_collide(right_hand_follower.velocity, false, 0.0000001, true)
	
	is_left_hand_colliding = left_hand_collision != null
	is_right_hand_colliding = right_hand_collision != null

func init() -> void:
	for i in range(velocity_history_size):
		velocity_history.append(Vector3.ZERO)
	previous_position = player.global_position

func store_velocities(delta:float) -> void:
	velocity_index = (velocity_index + 1) % velocity_history_size
	var oldest_velocity := velocity_history[velocity_index]
	var current_velocity := (player.global_position - previous_position) / delta
	velocity_average += (current_velocity - oldest_velocity) / float(velocity_history_size);
	velocity_history[velocity_index] = current_velocity
	previous_position = player.global_position
