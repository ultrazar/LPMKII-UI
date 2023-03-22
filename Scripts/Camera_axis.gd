extends Spatial


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.rotation.y += 0.2*delta
