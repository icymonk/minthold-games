class_name Nature
extends RefCounted
## Quaternius Stylized Nature MegaKit 모델을 불러와 공통 재질(nature.gdshader)로 바꿔 씌운다.

const DIR := "res://assets/models/nature/%s.gltf"
const SHADER := preload("res://shaders/nature.gdshader")
## 재질 이름 → 바람에 흔들리는 정도
const SWAY := {
	&"Leaves_NormalTree": 0.35, &"Leaves_Pine": 0.25, &"Leaves_TwistedTree": 0.3,
	&"Grass": 4.0, &"Leaves": 2.0, &"Flowers": 2.0,
}

static var _scenes := {}
static var _shared := {}


static func scene(model: String) -> PackedScene:
	if not _scenes.has(model):
		_scenes[model] = load(DIR % model)
	return _scenes[model]


## overrides: 재질 이름 → 대신 쓸 재질(나무 종마다 잎 색을 따로 칠할 때)
static func spawn(model: String, overrides := {}) -> Node3D:
	var node: Node3D = scene(model).instantiate()
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(s)
			var key := StringName(src.resource_name)
			mi.set_surface_override_material(s, overrides.get(key, shared(src)))
	return node


## 같은 원본 재질이면 모두 한 재질을 같이 쓴다(그리기 호출·계절 바꾸기가 가벼워진다).
static func shared(src: Material) -> ShaderMaterial:
	var key := StringName(src.resource_name)
	if not _shared.has(key):
		_shared[key] = make(src)
	return _shared[key]


static func make(src: Material, tint := Color.WHITE, recolor := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	var base := src as BaseMaterial3D
	if base:
		m.set_shader_parameter(&"albedo_tex", base.albedo_texture)
		tint *= base.albedo_color
	m.set_shader_parameter(&"tint", tint)
	m.set_shader_parameter(&"recolor", recolor)
	m.set_shader_parameter(&"sway", SWAY.get(StringName(src.resource_name), 0.0))
	return m


## 모델의 첫 메시(여러 개를 MultiMesh로 흩뿌릴 때)
static func mesh_of(model: String) -> Mesh:
	var node := scene(model).instantiate()
	var mi: MeshInstance3D = node.find_children("*", "MeshInstance3D", true, false)[0]
	var mesh := mi.mesh
	node.free()
	return mesh
