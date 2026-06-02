extends Node2D

@export var enemies: Array[PackedScene]
@export var max_total_enemies := 20
@export var max_enemies := 5
@export var spawn_interval := 2.2

@onready var timer: Timer = $Timer

var total_spawned = 0

var kill_count := 0

var player: Node2D

var interface

var enemy_count := 0

var player_dead = false

signal victory


func _ready() -> void:

	await get_tree().process_frame

	interface = get_tree().get_first_node_in_group("interface")

	timer.timeout.connect(spawn_enemy)

	timer.wait_time = spawn_interval
	timer.start()
	
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		player.player_died.connect(_on_player_death)


func _physics_process(_delta: float) -> void:
	
	if player_dead:
		queue_free()


func spawn_enemy() -> void:
	
	if total_spawned >= max_total_enemies:
		timer.stop()
		return

	# impede spawn acima do limite
	if enemy_count >= max_enemies:
		return

	var camera = get_viewport().get_camera_2d()

	if camera == null:
		return

	if enemies.is_empty():
		return

	# tamanho visível da tela
	var visible_rect = get_viewport().get_visible_rect()

	var screen_size = visible_rect.size

	var half_size = screen_size / 2 / 1.5

	# posição da câmera
	var cam_pos = camera.global_position

	# distância fora da tela
	var spawn_margin = 32.0

	# bordas visíveis
	var left = cam_pos.x - half_size.x
	var right = cam_pos.x + half_size.x
	var top = cam_pos.y - half_size.y
	var bottom = cam_pos.y + half_size.y

	var spawn_pos := Vector2.ZERO

	# escolhe lado aleatório
	var side = randi() % 4

	match side:

		0: # cima
			spawn_pos = Vector2(
				randf_range(left, right),
				top - spawn_margin
			)

		1: # baixo
			spawn_pos = Vector2(
				randf_range(left, right),
				bottom + spawn_margin
			)

		2: # esquerda
			spawn_pos = Vector2(
				left - spawn_margin,
				randf_range(top, bottom)
			)

		3: # direita
			spawn_pos = Vector2(
				right + spawn_margin,
				randf_range(top, bottom)
			)

	# escolhe inimigo aleatório
	var enemy_scene = enemies.pick_random()

	var enemy = enemy_scene.instantiate()

	enemy.global_position = spawn_pos

	# adiciona na cena
	get_tree().current_scene.call_deferred("add_child", enemy)
	interface.connect_enemy(enemy)

	# conta inimigo
	enemy_count += 1
	total_spawned += 1

	# quando o inimigo sair da árvore, diminui contador
	enemy.tree_exited.connect(_on_enemy_removed)
	enemy.died.connect(_on_enemy_died)


func _on_enemy_removed() -> void:

	enemy_count -= 1

	# segurança extra
	if enemy_count < 0:
		enemy_count = 0

	if kill_count >= max_total_enemies and enemy_count == 0:
		victory.emit()


func _on_enemy_died():
	
	kill_count += 1
	
	if kill_count >= max_total_enemies and enemy_count <= 1:
		print("Vitória!")
		


func _on_player_death() -> void:
	
	player_dead = true
