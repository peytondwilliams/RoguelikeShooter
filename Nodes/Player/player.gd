extends RigidBody3D


const TARGET_SPEED = 5.0

#var _pid = Pid3D.new()

# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass




@onready var head = $Head/h
@onready var camera = $Head/h/v
@onready var groundRay = $GroundRay

# new vars

var is_grounded = true
var accel = 0.5
var air_control = 0.25

var toggle = false

#var look_sensitivity = ProjectSettings.get_setting("player/look_sensitivity")
var look_sensitivity = 0.005

func _ready():
	linear_damp = 1.0
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


#func _physics_process(delta):
#	#reset friction to zero to avoid sticking to walk when velocity is applied
#	if friction >= 0: 
#		friction = 0
#	is_on_floor = false
#	move_input = Vector2.ZERO
#	var dir = Vector3()
#	#movement input
#	move_input = Input.get_vector("move_left","move_right","move_forward","move_backward")
#	dir += move_input.x*head.global_transform.basis.x;
#	dir += move_input.y*head.global_transform.basis.z;
#	velocity = lerp(velocity,dir*speed,acceleration*accel_multiplier*delta)
#	apply_central_force(velocity)
#	if feet.is_colliding():
#		is_on_floor = true
#		friction = 1.0
#		accel_multiplier = 1.0
#	if Input.is_action_just_pressed("jump") and is_on_floor:
#		accel_multiplier = 0.1
#		is_on_floor = false
#		apply_central_impulse(Vector3.UP * jump_velocity * 1)
#	#view and rotation
#	#camera.rotation_degrees.x -= mouse_input.y * view_sensitivity * delta;
#	#camera.rotation_degrees.x = clamp(camera.rotation_degrees.x,-80,80)
#	#head.rotation_degrees.y -= mouse_input.x * view_sensitivity * delta;
#	#mouse_input =Vector2.ZERO
	

#func _integrate_forces_2(state):
#	#limit max speed
#	if state.linear_velocity.length() > max_speed:
#		state.linear_velocity=state.linear_velocity.normalized()*max_speed
#
#	#artificial stopping movement i.e not using physics
#	if move_input.length() < 0.2:
#		state.linear_velocity.x = lerpf(state.linear_velocity.x,0,stop_speed)
#		state.linear_velocity.z = lerpf(state.linear_velocity.z,0,stop_speed)
#
#	#push against floor to avoid sliding on "unreasonable" slopes
#	#if state.get_contact_count() > 0 and move_input.length()< 0.2:
#	#	if is_on_floor and state.get_contact_local_normal(0).y < 0.9:
#	#		apply_central_force(-state.get_contact_local_normal(0)*10)

func _integrate_forces(state):
	
	# relative input
	is_grounded = groundRay.is_colliding()
	var move_input = Input.get_vector("move_left","move_right","move_forward","move_backward")
	var direction = Vector3()
	direction += move_input.x * head.global_transform.basis.x;
	direction += move_input.y * head.global_transform.basis.z;

	var goal_vel = direction * 10 * 1
	var vel_diff_dot = goal_vel.dot(state.get_linear_velocity())
	var new_accel = accel * vel_diff_factor(vel_diff_dot)
	
	goal_vel = goal_vel.move_toward(goal_vel + state.get_linear_velocity(), new_accel * state.step)		

	var neededAccel = Vector3()

	if is_grounded:
		neededAccel = ((goal_vel - state.get_linear_velocity()) / state.step)
	else:
		var linear_vel_no_y = Vector3(state.get_linear_velocity().x, 0, state.get_linear_velocity().z)
		neededAccel = ((goal_vel - linear_vel_no_y) / state.step)
	neededAccel *= .1
	# missing needAccel cap
	
	state.apply_central_force(Vector3(0, -9.8, 0) * mass * 10)

	float_capsule(state)
	move(neededAccel, state)

	#print(state.get_linear_velocity())
#	var vel = Vector3()
#
#
#	var curr_linear_vel = state.get_linear_velocity()
#
#
#	if is_grounded:
#		# keep vertical vel to avoid accel. on slopes
#		vel = curr_linear_vel
#		# add code for contacting body
#	else:
#		#Ignore y velocity in air
#		vel = Vector3(curr_linear_vel.x, 0, curr_linear_vel.z)

		
func float_capsule(state):
	if groundRay.is_colliding():
		var vel = state.get_linear_velocity()
		
		var ray_hit_len = groundRay.global_transform.origin.y - groundRay.get_collision_point().y
		var height_diff = ray_hit_len - 0.8
		
		var down_vel_dot = groundRay.target_position.normalized().dot(vel)
		
		var springForce = (height_diff * 30) - (down_vel_dot * 2)
		
		state.apply_central_force(groundRay.target_position.normalized() * springForce * mass * state.step * 2000)
	


func move(direction, state):
	#print(direction)
	#causing problems with gravity
	if is_grounded:
		var slope_check = 0
		state.apply_central_force(direction * mass)
		
	else:
		state.apply_central_force(direction * mass * air_control)

func set_friction():
	pass
	#player_physics_material.friction 

func vel_diff_factor(dot):
	var factor = 1
	if dot < 0:
		factor -= dot
		
	return factor

#mouse input
func _input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * look_sensitivity)
		camera.rotate_x(-event.relative.y * look_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
