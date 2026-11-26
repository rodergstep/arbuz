class_name PaintedMaterials
extends RefCounted
## Makes materials for the shared painted look (game/art/painted.gdshader). One shader, many
## colours: Godot batches them well, and the look stays consistent across every model.

const SHADER: Shader = preload("res://game/art/painted.gdshader")

static var _cache: Dictionary[String, ShaderMaterial] = {}


static func make(color: Color, sway: float = 0.0, variation: float = 0.0) -> ShaderMaterial:
	var key: String = "%s|%s|%s" % [color.to_html(), sway, variation]
	if _cache.has(key):
		return _cache[key]
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter(&"base_color", color)
	mat.set_shader_parameter(&"sway", sway)
	mat.set_shader_parameter(&"variation", variation)
	_cache[key] = mat
	return mat
