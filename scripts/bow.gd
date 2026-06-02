extends Node2D

@export var arrow_scene: PackedScene
@export var reload_time := 0.35

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var arrow_spawn: Marker2D = $ArrowSpawn
@onready var pull_fx: AudioStreamPlayer = $Pulling
@onready var release_fx: AudioStreamPlayer = $Release
@onready var test: Timer = $ChargeTime

@export var base_damage := 10

@export var max_charge_time := 10.0
@export var charged_threshold := 0.5
@export var charged_multiplier := 3.0
@export var quick_shots_before_reload := 3
@export var reload_tint := Color(0.55, 0.55, 0.55, 1.0)

var charge_time := 0.0

var can_shoot := true
var charging := false
var shots_left := quick_shots_before_reload

var charge_tween: Tween
var fully_charged := false

var is_reloading := false

var using_gamepad := false

@onready var player = owner


func _process(delta):

	if player == null:
		return

	using_gamepad = player.using_gamepad

	update_aim()
	handle_input()
	
	if charging:
		charge_time += delta
		charge_time = min(charge_time, max_charge_time)
	
	var now_fully_charged = charging and charge_time >= charged_threshold

	if now_fully_charged != fully_charged:

		fully_charged = now_fully_charged

		if fully_charged:
			bow_color(Color.BLACK)
		else:
			bow_color(Color.WHITE)


func update_aim():

	var dir = player.facing_dir

	rotation = dir.angle() - PI / 2

	z_index = -1 if dir.y < 0 else 1

	sprite.flip_h = dir.x < 0


func handle_input():

	if Input.is_action_just_pressed("attack"):
		start_charging()

	if Input.is_action_just_released("attack"):
		try_shoot()


func start_charging():

	if !can_shoot or charging or is_reloading:
		return

	charging = true
	charge_time = 0.0

	play_anim("pulling")

	pull_fx.play()


func try_shoot():

	if !charging or !can_shoot:
		return
	
	charging = false
	
	play_anim("shoot")
	
	var was_charged = charge_time >= charged_threshold
	
	shoot_arrow()
	
	if was_charged:
		shots_left = quick_shots_before_reload
		can_shoot = false
		start_reload()
		return
	
	shots_left -= 1
	
	if shots_left <=0:
		shots_left = quick_shots_before_reload
		can_shoot = false
		start_reload()
	else:
		play_anim("idle")


func start_reload():

	if is_reloading:
		return

	is_reloading = true

	can_shoot = false
	fully_charged = false

	bow_color(reload_tint)

	await get_tree().create_timer(reload_time).timeout

	if !is_inside_tree() or !is_reloading:
		return

	finish_reload()



func finish_reload():

	is_reloading = false

	can_shoot = true

	bow_color(Color.WHITE)

	if Input.is_action_pressed("attack"):
		start_charging()
	else:
		play_anim("idle")


func shoot_arrow():

	var arrow = arrow_scene.instantiate()

	get_tree().current_scene.add_child(arrow)

	release_fx.play()

	arrow.global_position = arrow_spawn.global_position
	arrow.rotation = rotation
	arrow.direction = Vector2.from_angle(global_rotation + PI / 2)
	
	arrow.damage = base_damage
	
	if charge_time >= charged_threshold:
		arrow.damage *= charged_multiplier
		arrow.charged = true


func _on_animated_sprite_2d_animation_finished():

	match sprite.animation:

		"pulling":
			play_anim("hold")

		"shoot":
			if !charging and !is_reloading:
				play_anim("idle")

func bow_color (target_color: Color):
	
	if charge_tween:
		charge_tween.kill()
	
	charge_tween = create_tween()
	
	charge_tween.tween_property(
		sprite,
		"modulate",
		target_color,
		0.15
	)


func play_anim(anim_name: String):

	if sprite.animation == anim_name:
		return

	sprite.play(anim_name)
