extends Node2D

@onready var bgm = $player/BGM
@onready var victory = $Interface/CanvasLayer/VictoryLabel
@onready var fanfare = $Fanfare

var muted := false
var victory_played = false

func _physics_process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("mute"):
		
		if muted:
			muted = false
			bgm.volume_db = -12.0
		elif !muted:
			muted = true
			bgm.volume_db = -80.0
			
	if victory.visible == true:
		bgm.stop()
		if victory_played == false:
			victory_played = true
			victory_fx()


func victory_fx():
	fanfare.play()
	pass
