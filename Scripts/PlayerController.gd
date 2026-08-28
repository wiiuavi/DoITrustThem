extends CharacterBody3D

@export var speed: float = 4.0
@export var gravity: float = 9.8

@onready var camera: Camera3D = $Camera3D
@onready var raycast: RayCast3D = $Camera3D/RayCast3D

var current_interactable: Node = null

func _ready():
	if Global.game_active:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent):
	if not Global.game_active or Global.is_paused:
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * Global.mouse_sensitivity)
		camera.rotate_x(-event.relative.y * Global.mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))

	if event.is_action_pressed("interact"):
		if current_interactable and current_interactable.has_method("interact"):
			current_interactable.interact()

func _physics_process(delta: float):
	if not Global.game_active or Global.is_paused:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	_check_raycast()

func _check_raycast():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.has_method("interact"):
			if current_interactable != collider:
				current_interactable = collider
				UIManager.set_reticle_active(true)
			return

	if current_interactable != null:
		current_interactable = null
		UIManager.set_reticle_active(false)
