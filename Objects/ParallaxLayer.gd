extends ParallaxLayer

func _process(delta: float) -> void:
	self.motion_offset.x += self.motion_scale.x * delta * -50
	return
