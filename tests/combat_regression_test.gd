extends SceneTree

const BOW_SCENE := preload("res://scenes/bow.tscn")
const ARROW_SCRIPT := preload("res://scripts/arrow.gd")
const ENEMY_SCRIPT := preload("res://scripts/enemy_ai.gd")
const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const SPAWNER_SCENE := preload("res://scenes/spawner.tscn")
const SKELETON_SCENE := preload("res://scenes/skeleton.tscn")

var failures := 0


func _initialize() -> void:
	await _run()
	quit(1 if failures > 0 else 0)


func _run() -> void:
	await _test_bow_reload_finishes_without_aim_rotation()
	await _test_player_damage_has_invulnerability_window()
	_test_enemy_and_spawn_defaults_are_less_punishing()
	_test_weak_enemies_fall_to_two_quick_arrows()
	await _test_charged_arrow_uses_visible_highlight()


func _test_bow_reload_finishes_without_aim_rotation() -> void:
	var bow = BOW_SCENE.instantiate()
	bow.set_process(false)
	root.add_child(bow)
	await process_frame

	if !_has_property(bow, "reload_time"):
		_fail("bow exposes a timed reload duration")
		_free_now(bow)
		return

	bow.reload_time = 0.05
	bow.can_shoot = false

	bow.start_reload()

	_assert_true(bow.is_reloading, "bow enters reload state")
	_assert_false(bow.can_shoot, "bow cannot shoot while reloading")

	await create_timer(0.08).timeout

	_assert_false(bow.is_reloading, "bow reload finishes without aim rotation")
	_assert_true(bow.can_shoot, "bow can shoot after timed reload")

	await create_timer(0.18).timeout

	_free_now(bow)


func _test_player_damage_has_invulnerability_window() -> void:
	var player = _build_test_player()
	root.add_child(player)
	player.set_physics_process(false)
	player.set_process(false)
	await process_frame

	if !_has_property(player, "damage_cooldown"):
		_fail("player exposes a damage cooldown")
		_free_now(player)
		return

	player.damage_cooldown = 0.08
	player.health = 5

	player.take_damage(1)
	player.take_damage(1)

	_assert_eq(player.health, 4, "immediate repeated damage is ignored")

	await create_timer(0.16).timeout

	player.take_damage(1)

	_assert_eq(player.health, 3, "damage applies again after invulnerability ends")

	await create_timer(0.16).timeout

	_free_now(player)


func _test_enemy_and_spawn_defaults_are_less_punishing() -> void:
	var enemy = CharacterBody2D.new()
	enemy.set_script(ENEMY_SCRIPT)

	_assert_true(enemy.speed <= 55.0, "enemy default speed is capped")

	var spawner = SPAWNER_SCENE.instantiate()
	var timer := spawner.get_node("Timer") as Timer

	_assert_true(spawner.max_enemies <= 5, "active enemy cap is lower")
	_assert_true(spawner.max_total_enemies <= 20, "total enemy count is lower")
	_assert_true(timer.wait_time >= 2.2, "spawn timer gives the player breathing room")

	enemy.free()
	spawner.free()


func _test_weak_enemies_fall_to_two_quick_arrows() -> void:
	var bow = BOW_SCENE.instantiate()
	var skeleton = SKELETON_SCENE.instantiate()

	_assert_true(
		skeleton.health <= bow.base_damage * 2,
		"weak enemies should fall to two quick arrows"
	)

	bow.free()
	skeleton.free()


func _test_charged_arrow_uses_visible_highlight() -> void:
	var arrow = Area2D.new()
	arrow.set_script(ARROW_SCRIPT)

	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	arrow.add_child(sprite)

	root.add_child(arrow)
	await process_frame

	if !_has_property(arrow, "charged_color"):
		_fail("arrow exposes an explicit charged highlight color")
		_free_now(arrow)
		return

	arrow.charged = true
	arrow._process(0.016)

	_assert_eq(sprite.modulate, arrow.charged_color, "charged arrow uses explicit highlight color")
	_assert_true(sprite.modulate.a > 0.0, "charged arrow highlight remains visible")

	_free_now(arrow)


func _build_test_player() -> CharacterBody2D:
	var player = CharacterBody2D.new()
	player.set_script(PLAYER_SCRIPT)

	var sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	player.add_child(sprite)

	var weapon_socket = Node2D.new()
	weapon_socket.name = "WeaponSocket"
	player.add_child(weapon_socket)

	var camera = Camera2D.new()
	camera.name = "Camera2D"
	player.add_child(camera)

	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	player.add_child(collision)

	var hurt_sound = AudioStreamPlayer.new()
	hurt_sound.name = "HurtSound"
	player.add_child(hurt_sound)

	var death_sound = AudioStreamPlayer.new()
	death_sound.name = "DeathSound"
	player.add_child(death_sound)

	var bgm = AudioStreamPlayer.new()
	bgm.name = "BGM"
	player.add_child(bgm)

	return player


func _assert_true(value: bool, message: String) -> void:
	if !value:
		_fail(message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		_fail(message)


func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _fail(message: String) -> void:
	failures += 1
	push_error(message)


func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if property.name == property_name:
			return true

	return false


func _free_now(node: Node) -> void:
	if node.get_parent():
		node.get_parent().remove_child(node)

	node.free()
