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
	# A lush tuft: seven curved blades of different heights fanning out from a small clump,
	# each in two segments (it bends) and tapering to a point. Normals point up so the toon
	# light reads them as soft grass; the painted gradient darkens the base.
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	for k: int in 7:
		var a: float = TAU * k / 7.0 + rng.randf_range(-0.3, 0.3)
		var out: Vector3 = Vector3(cos(a), 0.0, sin(a))
		var side: Vector3 = Vector3(-sin(a), 0.0, cos(a))
		var h: float = TUFT_HEIGHT * rng.randf_range(0.7, 1.35)
		var root: Vector3 = out * 0.05
		var mid: Vector3 = root + out * 0.06 + Vector3(0, h * 0.55, 0)
		var tip: Vector3 = root + out * rng.randf_range(0.16, 0.26) + Vector3(0, h, 0)
		var w0: Vector3 = side * 0.045
		var w1: Vector3 = side * 0.03
		var tris: Array[Vector3] = [
			root - w0, root + w0, mid + w1, root - w0, mid + w1, mid - w1, mid - w1, mid + w1, tip
		]
		# Both sides of each blade (the painted shader culls back faces).
		var back: Array[Vector3] = tris.duplicate()
		back.reverse()
		tris.append_array(back)
		for v: Vector3 in tris:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	var mesh: ArrayMesh = st.commit()
	var mat: ShaderMaterial = PaintedMaterials.make(color, 0.12).duplicate()
	mat.set_shader_parameter(&"gradient", 0.55)
	mat.set_shader_parameter(&"gradient_scale", 2.0)
	mat.set_shader_parameter(&"variation", 0.25)
	mesh.surface_set_material(0, mat)
	return mesh
