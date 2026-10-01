extends Node3D

var money := 650.0
var income_per_sec := 7.0
var street_level := 1
var selected_shop := -1
var shop_levels := [1, 1, 1, 1]
var shop_names := ["Corner Cafe", "Market", "Barber", "Bakery"]
var shop_prices := [250.0, 500.0, 900.0, 1500.0]
var customers: Array[Node3D] = []
var money_label: Label
var income_label: Label
var level_label: Label
var detail_label: Label
var upgrade_button: Button
var camera: Camera3D
var world := Node3D.new()

func _ready():
	add_child(world)
	build_world()
	build_ui()
	setup_camera()

func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color):
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	m.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	m.material_override = mat
	parent.add_child(m)

func sphere(parent: Node3D, radius: float, pos: Vector3, color: Color):
	var m := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	m.mesh = mesh
	m.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	m.material_override = mat
	parent.add_child(m)

func cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color):
	var m := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	m.mesh = mesh
	m.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	parent.add_child(m)

func shop(index: int, pos: Vector3, color: Color):
	var root := Node3D.new()
	root.position = pos
	root.set_meta("shop_index", index)
	world.add_child(root)
	box(root, Vector3(3.8, 2.7, 3.0), Vector3(0, 1.35, 0), color)
	box(root, Vector3(4.15, 0.28, 3.3), Vector3(0, 2.82, 0), color.lightened(0.14))
	box(root, Vector3(1.5, 1.2, 0.08), Vector3(0, 1.45, -1.53), Color("#26343b"))
	box(root, Vector3(0.95, 0.85, 0.08), Vector3(-1.15, 1.42, -1.54), Color("#b9d6d5"))
	box(root, Vector3(0.95, 0.85, 0.08), Vector3(1.15, 1.42, -1.54), Color("#b9d6d5"))
	var sign := Label3D.new()
	sign.text = shop_names[index]
	sign.font_size = 34
	sign.outline_size = 8
	sign.modulate = Color("#fff9ea")
	sign.position = Vector3(0, 2.55, -1.72)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(sign)

func house(pos: Vector3, color: Color):
	var root := Node3D.new()
	root.position = pos
	world.add_child(root)
	box(root, Vector3(4, 2.6, 3.6), Vector3(0, 1.3, 0), color)
	box(root, Vector3(4.4, 0.45, 4), Vector3(0, 2.85, 0), color.darkened(0.18))
	box(root, Vector3(0.85, 1.1, 0.08), Vector3(0, 1.1, -1.83), Color("#725c4c"))

func tree(pos: Vector3):
	var root := Node3D.new()
	root.position = pos
	world.add_child(root)
	cylinder(root, 0.24, 1.6, Vector3(0, 0.8, 0), Color("#765640"))
	sphere(root, 1.25, Vector3(0, 2.0, 0), Color("#5d875d"))
	sphere(root, 0.9, Vector3(0.55, 2.35, 0.15), Color("#6d9867"))

func person(i: int):
	var p := Node3D.new()
	p.position = Vector3(-14.0 + i * 3.8, 0, 0.9 + sin(i) * 1.1)
	world.add_child(p)
	cylinder(p, 0.24, 1.05, Vector3(0, 0.58, 0), Color("#3d4c65").lightened((i % 3) * 0.06))
	sphere(p, 0.3, Vector3(0, 1.3, 0), Color("#c89168"))
	customers.append(p)

func build_world():
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#a9c9d9")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#fff4df")
	e.ambient_light_energy = 0.75
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80
	add_child(sun)

	box(world, Vector3(34, 0.5, 24), Vector3(0, -0.35, 0), Color("#b8c89a"))
	box(world, Vector3(34, 0.18, 7), Vector3(0, -0.06, 0), Color("#5c6064"))
	box(world, Vector3(34, 0.16, 3), Vector3(0, -0.05, 7), Color("#62666a"))
	for x in range(-15, 16, 3):
		box(world, Vector3(1.35, 0.035, 0.13), Vector3(x, 0.04, 0), Color("#e8dd9c"))

	shop(0, Vector3(-9, 0, 4), Color("#d98f64"))
	shop(1, Vector3(-3, 0, 4), Color("#7ca5a7"))
	shop(2, Vector3(3, 0, 4), Color("#c8a35c"))
	shop(3, Vector3(9, 0, 4), Color("#b56f73"))

	house(Vector3(-11, 0, -6), Color("#e2b985"))
	house(Vector3(-5, 0, -6), Color("#8e9eb1"))
	house(Vector3(1, 0, -6), Color("#c58d78"))
	house(Vector3(7, 0, -6), Color("#9bb48c"))
	tree(Vector3(-15, 0, -4))
	tree(Vector3(14, 0, -5))
	tree(Vector3(13, 0, 6))
	tree(Vector3(-15, 0, 7))

	for i in range(8):
		person(i)

func setup_camera():
	camera = Camera3D.new()
	camera.position = Vector3(0, 24, 25)
	camera.rotation_degrees = Vector3(-48, 0, 0)
	camera.fov = 52
	add_child(camera)
	camera.current = true

func label(parent: Node, text_value: String, pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.text = text_value
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.modulate = Color("#f7f0df")
	parent.add_child(l)
	return l

func build_ui():
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := Panel.new()
	top.position = Vector2(24, 20)
	top.size = Vector2(1232, 92)
	top.modulate = Color(0.09, 0.12, 0.14, 0.94)
	layer.add_child(top)
	money_label = label(layer, "CASH  $650", Vector2(48, 38), 26)
	income_label = label(layer, "+$7 / sec", Vector2(48, 74), 17)
	level_label = label(layer, "STREET LEVEL  1", Vector2(1030, 45), 20)
	detail_label = label(layer, "Tap a business to manage it", Vector2(36, 620), 18)
	upgrade_button = Button.new()
	upgrade_button.text = "UPGRADE"
	upgrade_button.position = Vector2(1020, 610)
	upgrade_button.size = Vector2(220, 64)
	upgrade_button.add_theme_font_size_override("font_size", 20)
	upgrade_button.pressed.connect(upgrade_selected)
	layer.add_child(upgrade_button)

func _process(delta):
	money += income_per_sec * delta
	money_label.text = "CASH  $%0.0f" % money
	income_label.text = "+$%0.0f / sec" % income_per_sec
	level_label.text = "STREET LEVEL  %d" % street_level
	for i in customers.size():
		var p = customers[i]
		p.position.x += delta * (0.65 + i * 0.025)
		if p.position.x > 14.5:
			p.position.x = -14.5

func _input(event):
	if event is InputEventScreenTouch and event.pressed:
		try_select(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		try_select(event.position)

func try_select(screen_pos: Vector2):
	var from := camera.project_ray_origin(screen_pos)
	var direction := camera.project_ray_normal(screen_pos)
	var plane := Plane(Vector3.UP, 0)
	var hit = plane.intersects_ray(from, direction)
	if hit == null:
		return
	var x := float(hit.x)
	var z := float(hit.z)
	if z > 1.5 and z < 6.0:
		var idx := clampi(int(round((x + 9.0) / 6.0)), 0, 3)
		if abs(x - (-9.0 + idx * 6.0)) < 2.6:
			selected_shop = idx
			var cost := shop_prices[idx] * shop_levels[idx]
			detail_label.text = "%s  |  Level %d  |  Upgrade: $%0.0f" % [shop_names[idx], shop_levels[idx], cost]
			return
	detail_label.text = "Select a business on the street"

func upgrade_selected():
	if selected_shop < 0:
		detail_label.text = "Select a business first"
		return
	var cost := shop_prices[selected_shop] * shop_levels[selected_shop]
	if money < cost:
		detail_label.text = "Not enough cash  |  Need $%0.0f" % cost
		return
	money -= cost
	shop_levels[selected_shop] += 1
	income_per_sec += 3.5 + selected_shop * 1.5
	var total := 0
	for v in shop_levels:
		total += v
	street_level = 1 + int((total - 4) / 3)
	detail_label.text = "%s upgraded to Level %d" % [shop_names[selected_shop], shop_levels[selected_shop]]
