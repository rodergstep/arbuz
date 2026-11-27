class_name Weather
extends Node3D
## England's weather (roadmap step 26): now and then a gentle shower. The light dims, soft rain
## falls around him, Tygrytsa says "Look! It's raining!" (the first time the rain card teaches
## the word), and after a while the sun comes back. Never loud, never dark.

const FIRST_SHOWER: float = 100.0
const BETWEEN: float = 240.0
const SHOWER: float = 35.0

var town: GreyboxVillage
var _sun: DirectionalLight3D
var _env: Environment
var _rain: CPUParticles3D
var _clock: float = 0.0
var _next: float = FIRST_SHOWER
var _raining: bool = false
var _sun_energy: float = 1.0
var _ambient: float = 0.42


func setup(the_town: GreyboxVillage) -> void:
	town = the_town
	for node: Node in town.find_children("*", "DirectionalLight3D", false, false):
		_sun = node
	for node: Node in town.find_children("*", "WorldEnvironment", false, false):
		_env = (node as WorldEnvironment).environment
	if _sun != null:
		_sun_energy = _sun.light_energy
	if _env != null:
		_ambient = _env.ambient_light_energy
	_rain = _make_rain()
	add_child(_rain)


func is_raining() -> bool:
	return _raining


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_clock += delta
	if town.hero != null:
		var follow: Node3D = town.car if town.car != null and town.car.driving else town.hero
		_rain.global_position = follow.global_position + Vector3(0, 9, 0)
	if not _raining and _clock >= _next:
		_start()
	elif _raining and _clock >= _next:
		_stop()


func _start() -> void:
	_raining = true
	_next = _clock + SHOWER
	_rain.emitting = true
	_fade(0.55, 0.75)
	EventLog.log_event(&"weather", {"rain": true})
	var pos: Vector3 = town.hero.global_position
	if not town.learning.offer(&"rain", pos, pos + Vector3(3, 3, 4)):
		town.say_when_free("weather:rain")


func _stop() -> void:
	_raining = false
	_next = _clock + BETWEEN
	_rain.emitting = false
	_fade(1.0, 1.0)
	EventLog.log_event(&"weather", {"rain": false})
	town.say_when_free("weather:sun")


func _fade(sun_k: float, ambient_k: float) -> void:
	var tween: Tween = create_tween().set_parallel()
	if _sun != null:
		tween.tween_property(_sun, "light_energy", _sun_energy * sun_k, 4.0)
	if _env != null:
		tween.tween_property(_env, "ambient_light_energy", _ambient * ambient_k, 4.0)


## Soft rain: thin pale streaks falling in a box above him (one CPU particle system).
func _make_rain() -> CPUParticles3D:
	var rain: CPUParticles3D = CPUParticles3D.new()
	var streak: QuadMesh = QuadMesh.new()
	streak.size = Vector2(0.03, 0.5)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.78, 0.86, 1.0, 0.55)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	streak.material = mat
	rain.mesh = streak
	rain.amount = 700
	rain.lifetime = 0.9
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(18, 0.5, 14)
	rain.direction = Vector3.DOWN
	rain.spread = 3.0
	rain.gravity = Vector3(0, -12, 0)
	rain.initial_velocity_min = 8.0
	rain.initial_velocity_max = 10.0
	rain.emitting = false
	return rain
