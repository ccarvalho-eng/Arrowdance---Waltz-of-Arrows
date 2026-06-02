extends Control

@onready var health_label = $CanvasLayer/VBoxContainer/HealthCounter
@onready var kill_label = $CanvasLayer/VBoxContainer/KillCounter
@onready var victory_label = $CanvasLayer/VictoryLabel

var player
var spawner
var enemies

var kills := 0


func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		player.health_changed.connect(update_health)
		
	spawner = get_tree().get_first_node_in_group("spawner")
	
	if spawner:
		spawner.victory.connect(_on_victory)
	
	enemies = get_tree().get_first_node_in_group("enemy")
	
	if enemies:
		enemies.died.connect(_on_enemy_died)


func connect_enemy(enemy):
	enemy.died.connect(_on_enemy_died)
	pass


func update_health(current, max_health):
	health_label.text = "Health: %d/%d" % [current, max_health]


func _on_enemy_died():
	kills += 1
	kill_label.text = "Kills: %d" % kills


func _on_victory():
	victory_label.visible = true
	pass
