class_name WindGrass
extends MultiMeshInstance3D
## Grass tufts that sway in the wind: one MultiMesh (a single draw call) of small crossed-blade
## tufts in the painted shader with sway on. Low density by design (Intel MacBook budget).

const TUFT_HEIGHT: float = 0.45

## The grass colour of this country (set before scatter()).
var color: Color = Color(0.45, 0.72, 0.36)


## Scatters `count` tufts inside `area` (x/z rectangle), skipping spots where `blocked` returns
## true (roads, river, houses).
func scatter(area: Rect2, count: int, blocked: Callable, seed_value: int = 7) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var spots: Array[Transform3D] = []
	var tries: int = 0
	while spots.size() < count and tries < count * 4:
		tries += 1
		var p: Vector2 = Vector2(
			rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y)
		)
		if blocked.call(p):
			continue
		var basis: Basis = Basis(Vector3.UP, rng.randf() * TAU).scaled(
			Vector3.ONE * rng.randf_range(0.7, 1.3)
		)
		spots.append(Transform3D(basis, Vector3(p.x, 0.0, p.y)))
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _tuft_mesh()
	mm.instance_count = spots.size()
	for i: int in spots.size():
		mm.set_instance_transform(i, spots[i])
	multimesh = mm
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _tuft_mesh() -> ArrayMesh:
	# Three thin crossed blades, pointy tops; normals up so the toon light reads them as grass.
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in 3:
		var a: float = TAU * k / 3.0
		var side: Vector3 = Vector3(cos(a), 0.0, sin(a)) * 0.07
		var lean: Vector3 = Vector3(-sin(a), 0.0, cos(a)) * 0.06
		var top: Vector3 = Vector3(0, TUFT_HEIGHT, 0) + lean
		for v: Vector3 in [-side, side, top, side, -side, top]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	var mesh: ArrayMesh = st.commit()
	var mat: ShaderMaterial = PaintedMaterials.make(color, 0.12).duplicate()
	mat.set_shader_parameter(&"gradient", 0.45)
	mat.set_shader_parameter(&"gradient_scale", 2.0)
	mesh.surface_set_material(0, mat)
	return mesh
