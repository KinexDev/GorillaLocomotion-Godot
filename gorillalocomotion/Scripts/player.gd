extends Node

@export var player_speed:float = 7
@export var velocity_history_size:int = 8

@onready var player:CharacterBody3D = $Player
@onready var player_collision:CollisionShape3D = $Player/Collision
@onready var head:Node3D = $Player/XROrigin3D/Head
@onready var left_hand:Node3D = $Player/XROrigin3D/LeftHand
@onready var right_hand:Node3D = $Player/XROrigin3D/RightHand
@onready var left_hand_follower:CharacterBody3D = $LeftHandFollower
@onready var right_hand_follower:CharacterBody3D = $RightHandFollower

var velocity_history:Array[Vector3] = []
var previous_position:Vector3
var velocity_average:Vector3
var velocity_index:int

func _ready() -> void:
	init()

func _process(delta:float) -> void:
	player_collision.global_position = head.global_position - Vector3(0, 0.25, 0)
	
	if not player.is_on_floor():
		player.velocity += ProjectSettings.get_setting("physics/3d/default_gravity_vector") * delta
	
	move_followers(true, delta)

	if hand_colliding(left_hand_follower) and hand_colliding(right_hand_follower):
		pass
	else:
		pass
	
	move_followers(false, delta)
	
	player.move_and_slide()
	
	store_velocities(delta)

func move_followers(enable_stick_force:bool, delta:float) -> void:
	delta = clampf(delta, 0.01, 1)
	# stick force helps player stick to the ground while on the floor so movement doesn't feel odd
	var additional_force = Vector3.DOWN * 2 * 9.8 * delta * delta if enable_stick_force else Vector3.ZERO
	
	left_hand_follower.velocity = ((left_hand.global_position - left_hand_follower.global_position) / delta) + additional_force + player.velocity
	right_hand_follower.velocity = ((right_hand.global_position - right_hand_follower.global_position) / delta)  + additional_force + player.velocity
	
	left_hand_follower.move_and_slide()
	right_hand_follower.move_and_slide()

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

# Helper methods
func hand_colliding(hand:CharacterBody3D) -> bool:
	return hand.get_slide_collision_count() > 0
