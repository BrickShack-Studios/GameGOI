extends Node2D

func _ready():
	$Sprite/StaticBody2D/CollisionShape2D.rotate(2*PI)
	pass
	
func _physics_process(delta):
	$Sprite/StaticBody2D/CollisionShape2D.rotate(0.1)