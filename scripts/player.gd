extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var weapon_socket = $WeaponSocket
@onready var camera = $Camera2D
@onready var collision = $CollisionShape2D
@onready var hurt_fx = $HurtSound
@onready var death_fx = $DeathSound
@onready var bgm = $BGM

var max_speed = 160
var acceleration = 1400
var friction = 1800

var direction = Vector2.ZERO
var facing_dir = Vector2.DOWN

@export var max_health := 5
@export var damage_cooldown := 0.65

var health = 5

var dead = false
var invulnerable := false

var using_gamepad := false

var mouse_smoothing := 0.90


signal health_changed(current, max)
signal player_died


func _process(_delta):

	if Input.is_action_just_pressed("switch"):
		using_gamepad = !using_gamepad

	update_facing_direction()


func _physics_process(delta):

	if dead:
		return

	movement(delta)
	animations()

	move_and_slide()
	
	if Input.is_action_just_pressed("def"):
		die()


func movement(delta):

	direction = Input.get_vector("left","right","up","down")

	if direction != Vector2.ZERO:

		direction = direction.normalized()

		velocity = velocity.move_toward(direction * max_speed, acceleration * delta)

	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


func update_facing_direction():

	if using_gamepad:

		var aim_input = Vector2(
			Input.get_axis("aim_left", "aim_right"),
			Input.get_axis("aim_up", "aim_down")
		)

		if aim_input.length() > 0.2:
			facing_dir = aim_input.normalized()

	else:
		var mouse_dir = get_global_mouse_position() - global_position
		
		if mouse_dir.length() > 1:
			
			var target_dir = mouse_dir.normalized()
			
			facing_dir = facing_dir.lerp(
				target_dir,
				mouse_smoothing
			).normalized()



func take_damage(enemy_damage):
	
	if dead or invulnerable:
		return

	invulnerable = true

	health -= enemy_damage
	health_changed.emit(health, max_health)

	if health <=0:
		die()
		return

	hurt_fx.play()

	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout

	if dead:
		return

	sprite.modulate = Color.WHITE
	await get_tree().create_timer(max(damage_cooldown - 0.1, 0.0)).timeout

	if dead:
		return

	invulnerable = false



func animations():

	if dead:
		play_anim("dead")
		return
	
	var dir = get_direction_name(facing_dir)
	
	if velocity.length() > 5:
		play_anim("run_" + dir)
	else:
		play_anim("idle_" + dir)
		


func get_direction_name(dir : Vector2) -> String:

	var horizontal_bias = 0.9
	
	if abs(dir.x) > abs(dir.y) * horizontal_bias:
	
		if dir.x > 0:
			return "right"
		else:
			return "left"
	
	else:
		if dir.y > 0:
			return "down"
		else:
			return "up"


func play_anim(anim_name : String):

	if sprite.animation != anim_name:
		sprite.play(anim_name)


func die():

	dead = true
	
	death_fx.play()
	
	velocity = Vector2.ZERO
	
	play_anim("dead")
	
	weapon_socket.queue_free()
	
	player_died.emit()
	
	bgm.stop()
