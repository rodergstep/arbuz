class_name DayNight
extends Node
## Evening and night (roadmap step 26): after a while the sun goes down (a golden sky, "Look!
## It's evening."), then it is night (a soft blue sky, warm lights in the lamps and windows, a
## moon; "It's night! Good night, moon!" and the first time a card teaches "night"), and later
## the morning comes back ("Good morning! It's day!"). Never really dark: the world stays easy to see.

const EVENING_AT: float = 420.0
const NIGHT_AT: float = 470.0
const MORNING_AT: float = 590.0

var town: GreyboxVillage
var _sun: DirectionalLight3D
var _env: Environment
var _sky: ShaderMaterial
var _clock: float = 0.0
var _phase: int = 0
var _day: Dictionary = {}
var _lights: Array[OmniLight3D] = []
var _moon: Node3D
var _bright_target: float = 1.0


## lights: where warm lights come on at night (lamps, windows).
func setup(the_town: GreyboxVillage, lights: Array[Vector3]) -> void:
	town = the_town
	for node: Node in town.find_children("*", "DirectionalLight3D", false, false):
		_sun = node
	for node: Node in town.find_children("*", "WorldEnvironment", false, false):
		_env = (node as WorldEnvironment).environment
	if _env != null and _env.sky != null:
		_sky = _env.sky.sky_material as ShaderMaterial
	_day = _read()
	for spot: Vector3 in lights:
		var light: OmniLight3D = OmniLight3D.new()
		light.light_color = Color(1.0, 0.8, 0.5)
		light.omni_range = 7.0
		light.light_energy = 0.0
		light.visible = false
		town.add_child(light)
		light.global_position = spot
		_lights.append(light)


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_clock += delta
	if _env != null and not is_equal_approx(_env.adjustment_brightness, _bright_target):
		_env.adjustment_brightness = move_toward(_env.adjustment_brightness, _bright_target, delta * 0.06)
	if _phase == 0 and _clock >= EVENING_AT:
		_phase = 1
		_blend(
			Color(1.0, 0.62, 0.38),
			0.75,
			Color(0.62, 0.52, 0.72),
			Color(0.95, 0.55, 0.35),
			Color(0.42, 0.45, 0.78),
			0.0,
			0.86
		)
		town.say_when_free("daynight:evening")
	elif _phase == 1 and _clock >= NIGHT_AT:
		_phase = 2
		_blend(
			Color(0.62, 0.7, 1.0),
			0.35,
			Color(0.42, 0.48, 0.8),
			Color(0.35, 0.38, 0.62),
			Color(0.14, 0.2, 0.45),
			1.6,
			0.6
		)
		_show_moon(true)
		var pos: Vector3 = town.hero.global_position
		if not town.learning.offer(&"night", pos, pos + Vector3(3, 3, 4)):
			town.say_when_free("daynight:night")
	elif _phase == 2 and _clock >= MORNING_AT:
		_phase = 3
		_restore()
		_show_moon(false)
		town.say_when_free("daynight:morning")


func _read() -> Dictionary:
	var d: Dictionary = {}
	if _sun != null:
		d["sun_color"] = _sun.light_color
		d["sun_energy"] = _sun.light_energy
	if _env != null:
		d["ambient"] = _env.ambient_light_color
	if _sky != null:
		d["horizon"] = _sky.get_shader_parameter(&"horizon_color")
		d["top"] = _sky.get_shader_parameter(&"top_color")
	return d


func _blend(
	sun: Color, sun_k: float, ambient: Color, horizon: Color, top: Color, lamps: float, bright: float = 1.0
) -> void:
	var tween: Tween = create_tween().set_parallel()
	if _sun != null:
		tween.tween_property(_sun, "light_color", sun, 8.0)
		tween.tween_property(_sun, "light_energy", float(_day["sun_energy"]) * sun_k, 8.0)
	if _env != null:
		tween.tween_property(_env, "ambient_light_color", ambient, 8.0)
		# The whole picture dims a little (the painted look keeps its colours): never truly dark.
		_env.adjustment_enabled = true
		_bright_target = bright
	if _sky != null:
		tween.tween_method(
			func(c: Color) -> void: _sky.set_shader_parameter(&"horizon_color", c),
			_day["horizon"],
			horizon,
			8.0
		)
		tween.tween_method(
			func(c: Color) -> void: _sky.set_shader_parameter(&"top_color", c), _day["top"], top, 8.0
		)
	for light: OmniLight3D in _lights:
		light.visible = lamps > 0.0 or light.visible
		tween.tween_property(light, "light_energy", lamps, 6.0)


func _restore() -> void:
	_blend(_day["sun_color"], 1.0, _day["ambient"], _day["horizon"], _day["top"], 0.0, 1.0)


func _show_moon(on: bool) -> void:
	if on and _moon == null:
		_moon = Props.make(&"moon")
		_moon.scale = Vector3.ONE * 4.0
		town.add_child(_moon)
	if _moon != null:
		_moon.visible = on
		_moon.global_position = town.hero.global_position + Vector3(-14, 18, -30)
