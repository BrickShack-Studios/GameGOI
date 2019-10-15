extends Area2D

func _on_Area2D_body_entered(body):
	if (body.has_method("resetPosition")):
		body.resetPosition()
