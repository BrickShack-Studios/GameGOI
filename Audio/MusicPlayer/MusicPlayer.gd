extends Area2D

enum Song {TITLE, BG}
var currentSong = Song.TITLE

var TITLE_SONG := preload("res://Audio/Music/14 Dunes at Night.ogg")
var BGM        := preload("res://Audio/Music/8_Bit_Menu_-_David_Renda_-_FesliyanStudios.com.ogg")

onready var player := $AudioStreamPlayer


func _ready() -> void:
	#player.stream = TITLE_SONG
	#player.play()
	return

func swapSongs() -> void:
	$Tween.interpolate_property(
		$AudioStreamPlayer,
		"volume_db",
		-10,
		-100,
		2,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT)
	
	$Tween.start()
	return

func _on_MusicPlayer_body_exited(body: PhysicsBody2D) -> void:
	swapSongs()
	
	return


func _on_Tween_tween_completed(object: Object, key: NodePath) -> void:
	player.volume_db = -10
	player.stop()
	
	player.stream = BGM
	player.play()
	return

func _on_MusicPlayer_body_entered(body: PhysicsBody2D) -> void:
	player.stop()
	player.stream = TITLE_SONG
	player.play()
	
	return
