extends CharacterBody2D

@export var speed := 55.0
@export var health := 30
@export var enemy_damage := 1

@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D
@onready var hurt = $HurtSound

var player: Node2D

var direction
var dead := false
var player_dead = false

signal died


func _ready() -> void:
	
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		player.player_died.connect(_on_player_death)


func _physics_process(_delta: float) -> void:

	if player == null:
		return
	
	if player_dead:
		velocity = Vector2.ZERO
		animations()
		move_and_slide()
		return
	
	
	if health <= 0 and !dead:
		die()

	if !dead:
		direction = global_position.direction_to(player.global_position)
		
		if abs(direction.x) > 0.1:
			sprite.flip_h = direction.x < 0

		velocity = direction * speed

	animations()

	move_and_slide()


func animations():
	
	if dead:
		return
	
	if velocity.length() > 5:
		play_anim("run")
	elif velocity.length() == 0 and !dead:
		play_anim("idle")


func take_damage(damage):
	
	health -= damage
	hurt.play()


func die():
	
	if dead:
		return
	
	dead = true
	died.emit()
	direction = 0
	velocity = Vector2.ZERO
	collision.disabled = true
	sprite.play("death")
	await sprite.animation_finished
	queue_free()


func play_anim(anim_name):
	if sprite.animation != anim_name:
		sprite.play(anim_name)
	pass


func _on_player_death() -> void:
	
	player_dead = true


func _on_collision_body_entered(body: Node2D) -> void:
	
	if !dead:
		if body.has_method("take_damage"):
			body.take_damage(enemy_damage)
