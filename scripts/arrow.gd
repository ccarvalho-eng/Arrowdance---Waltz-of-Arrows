extends Area2D

@export var speed := 600
@export var damage := 10
@export var lifetime := 5.0

@onready var sprite = $Sprite2D

var charged := false

var stuck := false
var fade_tween: Tween

var direction := Vector2.ZERO


func _ready():

	rotation = direction.angle()


func _process(delta):
	
	if stuck:
		return

	global_position += direction * speed * delta
	
	if charged == true:
		sprite.modulate = Color()

func fade_and_destroy():

	if fade_tween:
		fade_tween.kill()

	fade_tween = create_tween()

	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_OUT)

	fade_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.3
	)

	await fade_tween.finished

	queue_free()


func _on_body_entered(body):

	if stuck:
		return

	if body.is_in_group("player"):
		return

	stuck = true

	if body.has_method("take_damage"):
		body.take_damage(damage)

	# Para movimento
	set_process(false)

	# Desativa colisão de forma segura
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# Guarda posição global
	var hit_position = global_position

	# Reparent seguro
	call_deferred("stick_to_target", body, hit_position)

	fade_and_destroy()

func stick_to_target(body, hit_position):

	if !is_instance_valid(body):
		return

	reparent(body)

	global_position = hit_position


func _on_visible_on_screen_notifier_2d_screen_exited():

	queue_free()
