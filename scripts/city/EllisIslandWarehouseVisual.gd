@tool
extends Node3D

# Builds a more Ellis Island–like building silhouette (central hall + wings + towers + domes),
# using cheap primitive meshes + MultiMesh window rows + procedural textures.
#
# This is intentionally visual-only: collisions/triggers live elsewhere in the scene.

@export var rebuild: bool = false:
	set(value):
		rebuild = false
		if Engine.is_editor_hint():
			_build()

@export var footprint_x: float = 34.0 # matches Part2 wall collision width
@export var footprint_z: float = 36.0 # matches Part2 wall collision depth
@export var base_height: float = 8.5

const _BUILDING_NODE_NAME := "EllisIslandBuilding"

var _mat_stone: StandardMaterial3D
var _mat_brick: StandardMaterial3D
var _mat_roof: StandardMaterial3D
var _mat_trim: StandardMaterial3D
var _mat_copper: StandardMaterial3D
var _mat_glass: StandardMaterial3D

static var _tex_cache: Dictionary = {}

func _ready() -> void:
	_build()

func _build() -> void:
	_ensure_materials()
	_clear_old()

	var root := Node3D.new()
	root.name = _BUILDING_NODE_NAME
	add_child(root)

	# --- Base plinth ---
	_add_box(root, "Plinth", Vector3(footprint_x, 1.1, footprint_z), Vector3(0, 0.55, 0), _mat_stone)

	# --- Main massing (central hall + wings) ---
	var wing_w := (footprint_x - 18.0) * 0.5
	wing_w = clamp(wing_w, 6.0, 10.0)
	var center_w := footprint_x - wing_w * 2.0
	var body_d := footprint_z * 0.78

	_add_box(root, "CenterBody", Vector3(center_w, base_height, body_d), Vector3(0, 1.1 + base_height * 0.5, 0), _mat_brick)
	_add_box(root, "WingL", Vector3(wing_w, base_height * 0.78, body_d), Vector3(-(center_w * 0.5 + wing_w * 0.5), 1.1 + (base_height * 0.78) * 0.5, 0), _mat_brick)
	_add_box(root, "WingR", Vector3(wing_w, base_height * 0.78, body_d), Vector3((center_w * 0.5 + wing_w * 0.5), 1.1 + (base_height * 0.78) * 0.5, 0), _mat_brick)

	# --- Towers (four corners) ---
	var t_w := 6.2
	var t_h := base_height + 3.8
	var t_x := footprint_x * 0.5 - t_w * 0.5 - 0.6
	var t_z := body_d * 0.5 - t_w * 0.5 - 0.6
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_build_tower(root, Vector3(sx * t_x, 1.1, sz * t_z), t_w, t_h)

	# --- Cornice rings (key realism cue) ---
	_build_cornice(root, center_w, body_d, 1.1 + base_height + 0.08)
	_build_cornice(root, wing_w, body_d, 1.1 + (base_height * 0.78) + 0.08, -(center_w * 0.5 + wing_w * 0.5))
	_build_cornice(root, wing_w, body_d, 1.1 + (base_height * 0.78) + 0.08, (center_w * 0.5 + wing_w * 0.5))

	# --- Roofs (gabled prisms) ---
	_add_roof_gable(root, "RoofCenter", Vector3(center_w + 0.2, 2.2, body_d + 0.2), Vector3(0, 1.1 + base_height + 1.1, 0), _mat_roof)
	_add_roof_gable(root, "RoofWingL", Vector3(wing_w + 0.1, 1.7, body_d + 0.2), Vector3(-(center_w * 0.5 + wing_w * 0.5), 1.1 + (base_height * 0.78) + 0.95, 0), _mat_roof)
	_add_roof_gable(root, "RoofWingR", Vector3(wing_w + 0.1, 1.7, body_d + 0.2), Vector3((center_w * 0.5 + wing_w * 0.5), 1.1 + (base_height * 0.78) + 0.95, 0), _mat_roof)

	# --- Central dome (iconic silhouette cue) ---
	_build_dome(root, "CentralDome", Vector3(0, 1.1 + base_height + 2.6, -body_d * 0.08), 2.35, 1.5)

	# --- Facade trim bands & entrance arches (south / +Z side) ---
	_build_south_facade(root, center_w, body_d)

	# --- Window rows (cheap but high-impact detail) ---
	_add_window_rows(root, center_w, wing_w, body_d)
	_add_window_frames(root, center_w, wing_w, body_d)

func _ensure_materials() -> void:
	if _mat_stone:
		return

	var stone := _get_or_build_stone_textures()
	_mat_stone = StandardMaterial3D.new()
	_mat_stone.albedo_texture = stone.albedo
	_mat_stone.normal_texture = stone.normal
	_mat_stone.roughness_texture = stone.roughness
	_mat_stone.roughness = 1.0
	_mat_stone.uv1_triplanar = true
	_mat_stone.uv1_scale = Vector3(0.42, 0.42, 0.42)

	_mat_trim = StandardMaterial3D.new()
	_mat_trim.albedo_texture = stone.albedo
	_mat_trim.normal_texture = stone.normal
	_mat_trim.roughness_texture = stone.roughness
	_mat_trim.roughness = 1.0
	_mat_trim.uv1_triplanar = true
	_mat_trim.uv1_scale = Vector3(0.6, 0.6, 0.6)
	_mat_trim.albedo_color = Color(0.96, 0.95, 0.92) # limestone tint

	var brick := _get_or_build_brick_textures()
	_mat_brick = StandardMaterial3D.new()
	_mat_brick.albedo_texture = brick.albedo
	_mat_brick.normal_texture = brick.normal
	_mat_brick.roughness_texture = brick.roughness
	_mat_brick.roughness = 1.0
	_mat_brick.uv1_triplanar = true
	_mat_brick.uv1_scale = Vector3(0.52, 0.52, 0.52)

	var roof := _get_or_build_roof_textures()
	_mat_roof = StandardMaterial3D.new()
	_mat_roof.albedo_texture = roof.albedo
	_mat_roof.normal_texture = roof.normal
	_mat_roof.roughness_texture = roof.roughness
	_mat_roof.roughness = 1.0
	_mat_roof.uv1_triplanar = true
	_mat_roof.uv1_scale = Vector3(0.34, 0.34, 0.34)

	_mat_copper = StandardMaterial3D.new()
	_mat_copper.albedo_color = Color(0.18, 0.40, 0.34)
	_mat_copper.roughness = 0.75
	_mat_copper.metallic = 0.12

	_mat_glass = StandardMaterial3D.new()
	_mat_glass.albedo_color = Color(0.06, 0.07, 0.09)
	_mat_glass.roughness = 0.25
	_mat_glass.metallic = 0.05
	_mat_glass.emission_enabled = true
	_mat_glass.emission = Color(0.08, 0.09, 0.11)
	_mat_glass.emission_energy_multiplier = 0.35

func _clear_old() -> void:
	# Delete only the visuals we own.
	var existing := get_node_or_null(_BUILDING_NODE_NAME)
	if existing:
		existing.queue_free()

func _add_box(parent: Node, node_name: String, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

func _add_prism(parent: Node, node_name: String, size: Vector3, pos: Vector3, mat: Material, rot: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := PrismMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

func _add_cylinder(parent: Node, node_name: String, radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

func _add_sphere(parent: Node, node_name: String, radius: float, pos: Vector3, mat: Material, mesh_scale: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = mesh_scale
	parent.add_child(mi)
	return mi

func _add_roof_gable(parent: Node, node_name: String, size: Vector3, pos: Vector3, mat: Material) -> void:
	# Prism points along +Z by default; rotate so ridge runs along Z (like the reference).
	# We scale Y small to keep it roof-like.
	var roof := _add_prism(parent, node_name, size, pos, mat, Vector3(0, 0, 0))
	roof.scale = Vector3(1, 0.85, 1)

func _build_tower(parent: Node3D, base_pos: Vector3, width: float, height: float) -> void:
	var y0 := base_pos.y
	_add_box(parent, "TowerBase_%s_%s" % [str(base_pos.x).replace(".", "_"), str(base_pos.z).replace(".", "_")],
		Vector3(width, height, width),
		Vector3(base_pos.x, y0 + height * 0.5, base_pos.z),
		_mat_brick)

	# Cornice band
	_add_box(parent, "TowerCornice_%s_%s" % [str(base_pos.x).replace(".", "_"), str(base_pos.z).replace(".", "_")],
		Vector3(width + 0.6, 0.45, width + 0.6),
		Vector3(base_pos.x, y0 + height + 0.22, base_pos.z),
		_mat_trim)

	# Upper stage
	_add_box(parent, "TowerUpper_%s_%s" % [str(base_pos.x).replace(".", "_"), str(base_pos.z).replace(".", "_")],
		Vector3(width * 0.72, 2.2, width * 0.72),
		Vector3(base_pos.x, y0 + height + 1.35, base_pos.z),
		_mat_brick)

	# Dome + spire (oxidized copper vibe)
	_add_sphere(parent, "TowerDome_%s_%s" % [str(base_pos.x).replace(".", "_"), str(base_pos.z).replace(".", "_")],
		1.55,
		Vector3(base_pos.x, y0 + height + 2.7, base_pos.z),
		_mat_copper,
		Vector3(1.0, 0.65, 1.0))
	_add_cylinder(parent, "TowerSpire_%s_%s" % [str(base_pos.x).replace(".", "_"), str(base_pos.z).replace(".", "_")],
		0.18,
		1.1,
		Vector3(base_pos.x, y0 + height + 3.55, base_pos.z),
		_mat_copper)

func _build_dome(parent: Node3D, dome_name: String, pos: Vector3, radius: float, drum_h: float) -> void:
	_add_cylinder(parent, "%s_Drum" % dome_name, radius * 0.7, drum_h, pos + Vector3(0, drum_h * 0.5 - 0.6, 0), _mat_brick)
	_add_sphere(parent, "%s_Dome" % dome_name, radius, pos + Vector3(0, drum_h * 0.5 + 0.2, 0), _mat_copper, Vector3(1.0, 0.62, 1.0))
	_add_cylinder(parent, "%s_Spire" % dome_name, 0.22, 1.5, pos + Vector3(0, drum_h * 0.5 + 1.9, 0), _mat_copper)

func _build_south_facade(parent: Node3D, center_w: float, body_d: float) -> void:
	var z_front := body_d * 0.5 + 0.02

	# A slightly protruding brick band to break up the flat massing.
	_add_box(parent, "SouthBand", Vector3(center_w * 0.92, 0.55, 0.55), Vector3(0, 3.0, z_front), _mat_trim)
	_add_box(parent, "SouthBandTop", Vector3(center_w * 0.96, 0.42, 0.55), Vector3(0, 6.0, z_front), _mat_trim)

	# Entrance portico base + steps (grounding detail)
	_add_box(parent, "EntrySteps", Vector3(10.2, 0.45, 3.0), Vector3(0, 0.25, z_front + 1.9), _mat_stone)
	_add_box(parent, "EntryPorch", Vector3(9.4, 0.55, 2.2), Vector3(0, 0.55, z_front + 1.1), _mat_stone)

	# Three big arched entry cues (frame + half-cylinder "arch" cap).
	var arch_w := 4.6
	var arch_h := 4.6
	var arch_depth := 0.65
	var centers := [-arch_w * 1.15, 0.0, arch_w * 1.15]
	for cx in centers:
		# Vertical legs
		_add_box(parent, "ArchLegL_%s" % str(cx).replace(".", "_"), Vector3(0.55, arch_h * 0.72, arch_depth), Vector3(cx - arch_w * 0.33, 1.2 + (arch_h * 0.72) * 0.5, z_front + 0.15), _mat_trim)
		_add_box(parent, "ArchLegR_%s" % str(cx).replace(".", "_"), Vector3(0.55, arch_h * 0.72, arch_depth), Vector3(cx + arch_w * 0.33, 1.2 + (arch_h * 0.72) * 0.5, z_front + 0.15), _mat_trim)
		# Arch cap (a squashed cylinder to read as an arch)
		var cap := _add_cylinder(parent, "ArchCap_%s" % str(cx).replace(".", "_"), arch_w * 0.36, 0.55, Vector3(cx, 1.2 + arch_h * 0.72 + 0.35, z_front + 0.15), _mat_trim, Vector3(0, 0, 1.570796))
		cap.scale = Vector3(1.0, 0.55, 1.0)

func _add_window_rows(parent: Node3D, center_w: float, wing_w: float, body_d: float) -> void:
	# South and North rows of windows on the main body and wings.
	var z_south := body_d * 0.5 + 0.26
	var z_north := -body_d * 0.5 - 0.26

	_add_windows_on_span(parent, "WindowsSouth_Center", -center_w * 0.5 + 1.4, center_w - 2.8, z_south, false)
	_add_windows_on_span(parent, "WindowsNorth_Center", -center_w * 0.5 + 1.4, center_w - 2.8, z_north, true)

	var wing_center_l := -(center_w * 0.5 + wing_w * 0.5)
	var wing_center_r := (center_w * 0.5 + wing_w * 0.5)
	_add_windows_on_span(parent, "WindowsSouth_WingL", wing_center_l - wing_w * 0.5 + 1.0, wing_w - 2.0, z_south, false)
	_add_windows_on_span(parent, "WindowsSouth_WingR", wing_center_r - wing_w * 0.5 + 1.0, wing_w - 2.0, z_south, false)
	_add_windows_on_span(parent, "WindowsNorth_WingL", wing_center_l - wing_w * 0.5 + 1.0, wing_w - 2.0, z_north, true)
	_add_windows_on_span(parent, "WindowsNorth_WingR", wing_center_r - wing_w * 0.5 + 1.0, wing_w - 2.0, z_north, true)

func _add_windows_on_span(parent: Node3D, node_name: String, x_start: float, span: float, z: float, flip: bool) -> void:
	# Two rows: lower + upper
	var quad := QuadMesh.new()
	quad.size = Vector2(1.05, 1.85)

	var mm := MultiMesh.new()
	mm.mesh = quad
	mm.transform_format = MultiMesh.TRANSFORM_3D

	var spacing := 1.75
	var count := int(max(2.0, floor(span / spacing)))
	var rows := 2
	mm.instance_count = count * rows

	var rot_y := 0.0 if not flip else PI
	var idx := 0
	for r in range(rows):
		var y := 2.4 + r * 2.3
		for i in range(count):
			var x := x_start + i * spacing
			var t := Transform3D(Basis.from_euler(Vector3(0, rot_y, 0)), Vector3(x, y, z))
			mm.set_instance_transform(idx, t)
			idx += 1

	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = _mat_glass
	parent.add_child(mmi)

func _add_window_frames(parent: Node3D, center_w: float, wing_w: float, body_d: float) -> void:
	# Simple trim around windows for depth cues (still cheap via MultiMesh).
	var z_south := body_d * 0.5 + 0.22
	var z_north := -body_d * 0.5 - 0.22

	_add_frames_on_span(parent, "FramesSouth_Center", -center_w * 0.5 + 1.4, center_w - 2.8, z_south, false)
	_add_frames_on_span(parent, "FramesNorth_Center", -center_w * 0.5 + 1.4, center_w - 2.8, z_north, true)

	var wing_center_l := -(center_w * 0.5 + wing_w * 0.5)
	var wing_center_r := (center_w * 0.5 + wing_w * 0.5)
	_add_frames_on_span(parent, "FramesSouth_WingL", wing_center_l - wing_w * 0.5 + 1.0, wing_w - 2.0, z_south, false)
	_add_frames_on_span(parent, "FramesSouth_WingR", wing_center_r - wing_w * 0.5 + 1.0, wing_w - 2.0, z_south, false)
	_add_frames_on_span(parent, "FramesNorth_WingL", wing_center_l - wing_w * 0.5 + 1.0, wing_w - 2.0, z_north, true)
	_add_frames_on_span(parent, "FramesNorth_WingR", wing_center_r - wing_w * 0.5 + 1.0, wing_w - 2.0, z_north, true)

func _add_frames_on_span(parent: Node3D, node_name: String, x_start: float, span: float, z: float, flip: bool) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(1.18, 2.05)

	var mm := MultiMesh.new()
	mm.mesh = quad
	mm.transform_format = MultiMesh.TRANSFORM_3D

	var spacing := 1.75
	var count := int(max(2.0, floor(span / spacing)))
	var rows := 2
	mm.instance_count = count * rows

	var rot_y := 0.0 if not flip else PI
	var idx := 0
	for r in range(rows):
		var y := 2.4 + r * 2.3
		for i in range(count):
			var x := x_start + i * spacing
			var t := Transform3D(Basis.from_euler(Vector3(0, rot_y, 0)), Vector3(x, y, z))
			mm.set_instance_transform(idx, t)
			idx += 1

	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = _mat_trim
	parent.add_child(mmi)

func _build_cornice(parent: Node3D, w: float, d: float, y: float, x_offset: float = 0.0) -> void:
	# A trim ring around the top edge (reads as stone cornice).
	var t := 0.35
	_add_box(parent, "CorniceFront_%s" % str(x_offset).replace(".", "_"), Vector3(w + t * 2.0, t, t), Vector3(x_offset, y, d * 0.5 + t * 0.5), _mat_trim)
	_add_box(parent, "CorniceBack_%s" % str(x_offset).replace(".", "_"), Vector3(w + t * 2.0, t, t), Vector3(x_offset, y, -d * 0.5 - t * 0.5), _mat_trim)
	_add_box(parent, "CorniceLeft_%s" % str(x_offset).replace(".", "_"), Vector3(t, t, d + t * 2.0), Vector3(x_offset - w * 0.5 - t * 0.5, y, 0), _mat_trim)
	_add_box(parent, "CorniceRight_%s" % str(x_offset).replace(".", "_"), Vector3(t, t, d + t * 2.0), Vector3(x_offset + w * 0.5 + t * 0.5, y, 0), _mat_trim)

# --- Procedural texture helpers (cached; fast, no external assets) ---
func _get_or_build_brick_textures() -> Dictionary:
	if _tex_cache.has("brick"):
		return _tex_cache["brick"]
	var tex := _build_brick_textures(384, 384)
	_tex_cache["brick"] = tex
	return tex

func _get_or_build_stone_textures() -> Dictionary:
	if _tex_cache.has("stone"):
		return _tex_cache["stone"]
	var tex := _build_stone_textures(384, 384)
	_tex_cache["stone"] = tex
	return tex

func _get_or_build_roof_textures() -> Dictionary:
	if _tex_cache.has("roof"):
		return _tex_cache["roof"]
	var tex := _build_roof_textures(384, 384)
	_tex_cache["roof"] = tex
	return tex

func _build_brick_textures(w: int, h: int) -> Dictionary:
	var albedo := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var height := Image.create(w, h, false, Image.FORMAT_RF)
	var rough := Image.create(w, h, false, Image.FORMAT_RF)

	var brick_w := 48.0
	var brick_h := 22.0
	var mortar := 2.0

	for y in range(h):
		var row := int(floor(y / brick_h))
		var x_offset := 0.0 if (row % 2) == 0 else brick_w * 0.5
		for x in range(w):
			var fx := fposmod(x + x_offset, brick_w)
			var fy := fposmod(y, brick_h)

			var in_mortar := (fx < mortar) or (fx > brick_w - mortar) or (fy < mortar) or (fy > brick_h - mortar)
			if in_mortar:
				albedo.set_pixel(x, y, Color(0.78, 0.77, 0.74, 1))
				height.set_pixel(x, y, Color(0.28, 0, 0))
				rough.set_pixel(x, y, Color(0.98, 0, 0))
			else:
				var brick_id := int(floor((x + x_offset) / brick_w)) + row * 997
				var n := _hash01(brick_id)
				var n2 := _hash01(brick_id * 17 + 13)
				var base := Color(0.46, 0.16, 0.13, 1).lerp(Color(0.55, 0.20, 0.16, 1), n)
				# subtle per-pixel grain
				var g := (_hash01(x * 73856093 ^ y * 19349663) - 0.5) * 0.06
				base.r = clamp(base.r + g, 0.0, 1.0)
				base.g = clamp(base.g + g, 0.0, 1.0)
				base.b = clamp(base.b + g, 0.0, 1.0)
				albedo.set_pixel(x, y, base)
				height.set_pixel(x, y, Color(0.62 + n2 * 0.06, 0, 0))
				rough.set_pixel(x, y, Color(0.82 + n * 0.08, 0, 0))

	var normal_img := _height_to_normal(height, 2.2)
	return {
		"albedo": ImageTexture.create_from_image(albedo),
		"normal": ImageTexture.create_from_image(normal_img),
		"roughness": ImageTexture.create_from_image(rough),
	}

func _build_stone_textures(w: int, h: int) -> Dictionary:
	var albedo := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var height := Image.create(w, h, false, Image.FORMAT_RF)
	var rough := Image.create(w, h, false, Image.FORMAT_RF)

	for y in range(h):
		for x in range(w):
			var n := _value_noise_2d(x, y, 0.045)
			var n2 := _value_noise_2d(x + 111, y + 73, 0.11)
			var c := Color(0.86, 0.85, 0.82, 1).lerp(Color(0.78, 0.77, 0.74, 1), n2 * 0.65)
			var speck := (n - 0.5) * 0.08
			c.r = clamp(c.r + speck, 0.0, 1.0)
			c.g = clamp(c.g + speck, 0.0, 1.0)
			c.b = clamp(c.b + speck, 0.0, 1.0)
			albedo.set_pixel(x, y, c)
			height.set_pixel(x, y, Color(0.52 + (n2 - 0.5) * 0.08, 0, 0))
			rough.set_pixel(x, y, Color(0.92 - n * 0.14, 0, 0))

	var normal_img := _height_to_normal(height, 1.35)
	return {
		"albedo": ImageTexture.create_from_image(albedo),
		"normal": ImageTexture.create_from_image(normal_img),
		"roughness": ImageTexture.create_from_image(rough),
	}

func _build_roof_textures(w: int, h: int) -> Dictionary:
	var albedo := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var height := Image.create(w, h, false, Image.FORMAT_RF)
	var rough := Image.create(w, h, false, Image.FORMAT_RF)

	var tile_w := 28.0
	var tile_h := 20.0

	for y in range(h):
		var row := int(floor(y / tile_h))
		var x_offset := 0.0 if (row % 2) == 0 else tile_w * 0.5
		for x in range(w):
			var fx := fposmod(x + x_offset, tile_w)
			var fy := fposmod(y, tile_h)

			# Curved tile lip: a soft ridge near the bottom of each row.
			var lip := smoothstep(tile_h * 0.62, tile_h * 0.95, fy) * (1.0 - smoothstep(tile_h * 0.95, tile_h, fy))
			var seam := 1.0 - smoothstep(0.0, 1.2, min(fx, tile_w - fx))

			var tile_id := int(floor((x + x_offset) / tile_w)) + row * 733
			var v := _hash01(tile_id)
			var base := Color(0.47, 0.16, 0.12, 1).lerp(Color(0.56, 0.21, 0.16, 1), v)
			var g := (_hash01(x * 83492791 ^ y * 297121507) - 0.5) * 0.05
			base.r = clamp(base.r + g, 0.0, 1.0)
			base.g = clamp(base.g + g, 0.0, 1.0)
			base.b = clamp(base.b + g, 0.0, 1.0)

			# Darken seams slightly
			base = base.lerp(Color(0.25, 0.10, 0.08, 1), seam * 0.35)
			albedo.set_pixel(x, y, base)

			var hgt := 0.55 + lip * 0.22 - seam * 0.06
			height.set_pixel(x, y, Color(hgt, 0, 0))
			rough.set_pixel(x, y, Color(0.86 + (1.0 - lip) * 0.08, 0, 0))

	var normal_img := _height_to_normal(height, 3.0)
	return {
		"albedo": ImageTexture.create_from_image(albedo),
		"normal": ImageTexture.create_from_image(normal_img),
		"roughness": ImageTexture.create_from_image(rough),
	}

func _height_to_normal(height_img: Image, strength: float) -> Image:
	var w := height_img.get_width()
	var h := height_img.get_height()
	var normal := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var xm: int = maxi(0, x - 1)
			var xp: int = mini(w - 1, x + 1)
			var ym: int = maxi(0, y - 1)
			var yp: int = mini(h - 1, y + 1)
			var h_l := height_img.get_pixel(xm, y).r
			var h_r := height_img.get_pixel(xp, y).r
			var h_u := height_img.get_pixel(x, ym).r
			var h_d := height_img.get_pixel(x, yp).r

			var dx := (h_r - h_l) * strength
			var dy := (h_d - h_u) * strength
			var n := Vector3(-dx, -dy, 1.0).normalized()
			# Encode to [0,1]
			normal.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0))
	return normal

func _hash01(i: int) -> float:
	var x := i
	x = int((x ^ 61) ^ (x >> 16))
	x *= 9
	x = int(x ^ (x >> 4))
	x *= 0x27d4eb2d
	x = int(x ^ (x >> 15))
	return float(x & 0x7fffffff) / 2147483647.0

func _value_noise_2d(x: int, y: int, freq: float) -> float:
	# Simple, fast value noise (bilinear interpolation of hashed grid points).
	var fx := float(x) * freq
	var fy := float(y) * freq
	var x0 := int(floor(fx))
	var y0 := int(floor(fy))
	var tx := fx - float(x0)
	var ty := fy - float(y0)

	var v00 := _hash01(x0 * 92837111 ^ y0 * 689287499)
	var v10 := _hash01((x0 + 1) * 92837111 ^ y0 * 689287499)
	var v01 := _hash01(x0 * 92837111 ^ (y0 + 1) * 689287499)
	var v11 := _hash01((x0 + 1) * 92837111 ^ (y0 + 1) * 689287499)

	var sx := tx * tx * (3.0 - 2.0 * tx)
	var sy := ty * ty * (3.0 - 2.0 * ty)
	var ix0: float = lerpf(v00, v10, sx)
	var ix1: float = lerpf(v01, v11, sx)
	return lerpf(ix0, ix1, sy)
