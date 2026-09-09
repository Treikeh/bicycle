extends MeshInstance3D


func _process(delta: float) -> void:
	mesh.material.uv1_offset.x += delta * 0.05
