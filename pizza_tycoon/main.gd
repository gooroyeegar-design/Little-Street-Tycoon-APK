extends Node3D

const WALK_SPEED := 4.2
var cash := 35
var pizzas_sold := 0
var tables := 0
var workers := 0
var oven_level := 1
var move_input := Vector2.ZERO
var joy_active := false
var customer_timer := 0.0
var customers: Array[Node3D] = []
var world_root: Node3D
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var cash_label: Label
var status_label: Label
var joy_knob: ColorRect
var joystick: Control
var last_interaction := ""

func _ready() -> void:
    _build_world()
    _build_player()
    _build_ui()
    _update_hud()

func _material(color: Color, roughness: float = 0.8) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, label: String = "Prop") -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var instance := MeshInstance3D.new()
    instance.name = label
    instance.mesh = mesh
    instance.position = pos
    instance.material_override = _material(color)
    parent.add_child(instance)
    return instance

func _cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.position = pos
    instance.material_override = _material(color)
    parent.add_child(instance)
    return instance

func _build_world() -> void:
    world_root = Node3D.new()
    world_root.name = "Restaurant"
    add_child(world_root)
    var floor_mesh := PlaneMesh.new()
    floor_mesh.size = Vector2(18, 16)
    var floor := MeshInstance3D.new()
    floor.mesh = floor_mesh
    floor.material_override = _material(Color("#d9c4a0"))
    floor.position.y = -0.08
    world_root.add_child(floor)
    _box(world_root, Vector3(18, 3.4, 0.25), Vector3(0, 1.6, -8), Color("#e8d9c1"), "BackWall")
    _box(world_root, Vector3(0.25, 3.4, 16), Vector3(-9, 1.6, 0), Color("#e8d9c1"), "LeftWall")
    _box(world_root, Vector3(0.25, 3.4, 16), Vector3(9, 1.6, 0), Color("#e8d9c1"), "RightWall")
    _box(world_root, Vector3(18, 0.25, 0.25), Vector3(0, 3.25, -8), Color("#6f4432"), "WoodTrim")
    _box(world_root, Vector3(3.8, 1.05, 0.75), Vector3(-4.7, 0.53, -5.7), Color("#8c5438"), "PrepCounter")
    _box(world_root, Vector3(1.3, 0.9, 0.9), Vector3(-5.4, 1.45, -5.7), Color("#4b4f56"), "PizzaMachine")
    _box(world_root, Vector3(0.92, 0.55, 0.06), Vector3(-5.4, 1.48, -5.22), Color("#ed9a50"), "OvenGlow")
    _box(world_root, Vector3(2.8, 0.12, 0.7), Vector3(-4.7, 1.12, -5.7), Color("#e4c69a"), "CounterTop")
    _box(world_root, Vector3(2.2, 0.08, 0.18), Vector3(0, 2.6, -7.75), Color("#b9442f"), "RestaurantSign")
    _box(world_root, Vector3(1.65, 0.05, 0.05), Vector3(0, 2.61, -7.62), Color("#fff1d3"), "SignDetail")
    for x in [-5.5, -1.5, 2.5, 6.0]:
        _cylinder(world_root, 0.28, 0.08, Vector3(x, 2.85, -1.0), Color("#d9a24e"))
        var light := OmniLight3D.new()
        light.position = Vector3(x, 2.55, -1.0)
        light.light_color = Color("#ffd7a0")
        light.light_energy = 0.65
        light.omni_range = 5.5
        world_root.add_child(light)
    for z in [-4.8, -1.0, 2.8]:
        _box(world_root, Vector3(0.04, 1.35, 1.65), Vector3(8.84, 1.8, z), Color("#8ec9d8"), "Window")
        _box(world_root, Vector3(0.09, 0.08, 1.75), Vector3(8.78, 1.8, z), Color("#f8e8c8"), "WindowSill")
    _box(world_root, Vector3(3.1, 0.05, 3.2), Vector3(0, -0.03, 8.4), Color("#777b78"), "Sidewalk")
    _box(world_root, Vector3(1.5, 2.35, 0.14), Vector3(6.5, 1.12, -7.78), Color("#6f4432"), "BackDoor")
    _box(world_root, Vector3(0.35, 0.35, 0.04), Vector3(6.2, 1.15, -7.68), Color("#e7bd64"), "DoorHandle")
    for i in range(3):
        _cylinder(world_root, 0.16, 0.35, Vector3(-6.0 + i * 0.6, 1.42, -6.1), [Color("#bd5940"), Color("#6d9b59"), Color("#e8c76b")][i])
    _box(world_root, Vector3(0.75, 0.9, 0.06), Vector3(-7.7, 2.0, -7.82), Color("#c75c43"), "WallArt")
    _box(world_root, Vector3(0.58, 0.06, 0.04), Vector3(-7.7, 2.25, -7.76), Color("#f7e3bd"), "WallArtDetail")
    _add_table(Vector3(3.0, 0, -3.8), false)
    _add_table(Vector3(5.7, 0, 0.1), false)
    _add_table(Vector3(2.7, 0, 3.8), false)
    _box(world_root, Vector3(18, 0.12, 3), Vector3(0, -0.16, 9.6), Color("#9a9b91"), "Street")
    for x in [-7.5, 7.5]:
        _cylinder(world_root, 0.38, 0.12, Vector3(x, 0.0, 8.6), Color("#a56d46"))
        _cylinder(world_root, 0.62, 1.1, Vector3(x, 0.72, 8.6), Color("#57865b"))
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#f5dfc2")
    environment.ambient_light_energy = 0.75
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = environment
    world_root.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    world_root.add_child(sun)

func _add_table(pos: Vector3, purchased: bool) -> void:
    var table := Node3D.new()
    table.position = pos
    table.name = "DiningTable"
    world_root.add_child(table)
    var wood := Color("#8c5438") if purchased else Color("#b28b64")
    _cylinder(table, 0.52, 0.12, Vector3(0, 0.82, 0), wood)
    _cylinder(table, 0.11, 0.78, Vector3(0, 0.4, 0), Color("#68432f"))
    for offset in [Vector3(0.85, 0, 0), Vector3(-0.85, 0, 0)]:
        _box(table, Vector3(0.5, 0.45, 0.48), offset + Vector3(0, 0.24, 0), Color("#6c8d83"), "Chair")
        _box(table, Vector3(0.5, 0.5, 0.08), offset + Vector3(0, 0.5, -0.2), Color("#6c8d83"), "ChairBack")

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Cook"
    player.position = Vector3(-1.0, 0.0, 2.0)
    add_child(player)
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.34
    capsule.height = 1.65
    var body := MeshInstance3D.new()
    body.mesh = capsule
    body.position.y = 0.83
    body.material_override = _material(Color("#d06b42"))
    player.add_child(body)
    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.27
    head_mesh.height = 0.54
    head.mesh = head_mesh
    head.position = Vector3(0, 1.72, 0)
    head.material_override = _material(Color("#d7a078"))
    player.add_child(head)
    var hat := MeshInstance3D.new()
    var hat_mesh := CylinderMesh.new()
    hat_mesh.top_radius = 0.22
    hat_mesh.bottom_radius = 0.28
    hat_mesh.height = 0.28
    hat.mesh = hat_mesh
    hat.position = Vector3(0, 2.02, 0)
    hat.material_override = _material(Color("#fff4df"))
    player.add_child(hat)
    var collider := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.34
    shape.height = 1.65
    collider.shape = shape
    collider.position.y = 0.83
    player.add_child(collider)
    camera = Camera3D.new()
    camera.position = Vector3(0, 5.2, 8.4)
    camera.rotation_degrees = Vector3(-24, 0, 0)
    camera.current = true
    player.add_child(camera)

func _build_ui() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    var top := PanelContainer.new()
    top.position = Vector2(18, 16)
    top.custom_minimum_size = Vector2(280, 82)
    top.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.14, 0.15, 0.92)))
    hud.add_child(top)
    var col := VBoxContainer.new()
    top.add_child(col)
    cash_label = Label.new()
    cash_label.add_theme_font_size_override("font_size", 23)
    cash_label.add_theme_color_override("font_color", Color("#ffe1a3"))
    col.add_child(cash_label)
    status_label = Label.new()
    status_label.add_theme_font_size_override("font_size", 14)
    status_label.add_theme_color_override("font_color", Color("#f7efe2"))
    col.add_child(status_label)
    var actions := HBoxContainer.new()
    actions.position = Vector2(18, 112)
    actions.add_theme_constant_override("separation", 8)
    hud.add_child(actions)
    _make_button(actions, "COOK", _cook_pizza)
    _make_button(actions, "SERVE +$12", _serve_customer)
    _make_button(actions, "TABLE $45", _buy_table)
    _make_button(actions, "HIRE $90", _hire_worker)
    _make_button(actions, "OVEN $70", _upgrade_oven)
    var hint := Label.new()
    hint.text = "MOVE: WASD / ARROWS  •  WALK TO OVEN TO COOK"
    hint.position = Vector2(20, 158)
    hint.add_theme_font_size_override("font_size", 13)
    hint.add_theme_color_override("font_color", Color("#fff2dc"))
    hud.add_child(hint)
    joystick = Control.new()
    joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    joystick.position = Vector2(24, -190)
    joystick.custom_minimum_size = Vector2(150, 150)
    hud.add_child(joystick)
    var base := ColorRect.new()
    base.size = Vector2(138, 138)
    base.color = Color(0.08, 0.1, 0.1, 0.35)
    base.mouse_filter = Control.MOUSE_FILTER_STOP
    joystick.add_child(base)
    joy_knob = ColorRect.new()
    joy_knob.size = Vector2(58, 58)
    joy_knob.position = Vector2(40, 40)
    joy_knob.color = Color(0.96, 0.79, 0.52, 0.85)
    joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick.add_child(joy_knob)
    joystick.gui_input.connect(_on_joystick_input)
    var interact := Button.new()
    interact.text = "INTERACT"
    interact.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    interact.position = Vector2(-176, -126)
    interact.custom_minimum_size = Vector2(142, 70)
    interact.add_theme_font_size_override("font_size", 18)
    interact.add_theme_color_override("font_color", Color("#fff4df"))
    interact.add_theme_stylebox_override("normal", _button_style(Color("#b84f36")))
    interact.pressed.connect(_interact_nearby)
    hud.add_child(interact)

func _panel_style(color: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.corner_radius_top_left = 14
    s.corner_radius_top_right = 14
    s.corner_radius_bottom_left = 14
    s.corner_radius_bottom_right = 14
    s.content_margin_left = 12
    s.content_margin_right = 12
    s.content_margin_top = 8
    s.content_margin_bottom = 8
    return s

func _button_style(color: Color) -> StyleBoxFlat:
    var s := _panel_style(color)
    s.content_margin_left = 9
    s.content_margin_right = 9
    s.content_margin_top = 8
    s.content_margin_bottom = 8
    return s

func _make_button(parent: Control, title: String, callback: Callable) -> void:
    var b := Button.new()
    b.text = title
    b.custom_minimum_size = Vector2(138, 42)
    b.add_theme_font_size_override("font_size", 14)
    b.add_theme_color_override("font_color", Color("#fff4df"))
    b.add_theme_stylebox_override("normal", _button_style(Color("#273a39")))
    b.add_theme_stylebox_override("hover", _button_style(Color("#42635a")))
    b.pressed.connect(callback)
    parent.add_child(b)

func _process(delta: float) -> void:
    customer_timer += delta
    if customer_timer > 12.0 and customers.size() < 3:
        customer_timer = 0.0
        _spawn_customer()
    _move_player(delta)
    _update_hud()

func _move_player(_delta: float) -> void:
    var input := move_input
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input.y += 1.0
    input = input.limit_length(1.0)
    player.velocity = Vector3(input.x * WALK_SPEED, 0, input.y * WALK_SPEED)
    player.move_and_slide()
    player.position.x = clampf(player.position.x, -8.1, 8.1)
    player.position.z = clampf(player.position.z, -6.8, 7.2)
    if input.length() > 0.1:
        player.rotation.y = atan2(input.x, input.y)
    camera.position = camera.position.lerp(Vector3(0, 5.2, 8.4), 0.08)

func _on_joystick_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        joy_active = event.pressed
        if joy_active:
            _set_joystick(event.position)
        else:
            move_input = Vector2.ZERO
            joy_knob.position = Vector2(40, 40)
    elif event is InputEventScreenDrag and joy_active:
        _set_joystick(event.position)

func _set_joystick(point: Vector2) -> void:
    var center := Vector2(69, 69)
    var delta := (point - joystick.global_position - center).limit_length(42)
    joy_knob.position = center + delta - joy_knob.size / 2.0
    move_input = Vector2(delta.x / 42.0, delta.y / 42.0)

func _cook_pizza() -> void:
    if player.global_position.distance_to(Vector3(-5.4, 0, -5.7)) > 4.2:
        _notify("Walk closer to the pizza oven first!")
        return
    last_interaction = "cooked"
    _notify("Fresh pizza ready! Go serve a customer.")
    _cylinder(world_root, 0.32, 0.06, Vector3(-5.4, 1.24, -5.55), Color("#e7b64f")).name = "FreshPizza"
    _box(world_root, Vector3(0.16, 0.025, 0.16), Vector3(-5.4, 1.28, -5.55), Color("#c65338"), "PizzaTopping")

func _serve_customer() -> void:
    if last_interaction != "cooked":
        _notify("Cook a pizza first!")
        return
    var payout := 12 + (oven_level - 1) * 3 + workers * 3
    cash += payout
    pizzas_sold += 1
    last_interaction = ""
    for n in world_root.get_children():
        if n.name == "FreshPizza" or n.name == "PizzaTopping":
            n.queue_free()
    if customers.size() > 0:
        var c: Node3D = customers.pop_front()
        c.queue_free()
    _notify("Pizza sold! +$%d" % payout)
    _update_hud()

func _buy_table() -> void:
    if cash < 45:
        _notify("You need $45 for a dining table.")
        return
    cash -= 45
    tables += 1
    _add_table(Vector3(5.6, 0, -4.0 + float(tables % 3) * 2.8), true)
    _notify("New table unlocked! Restaurant expanded.")
    _update_hud()

func _hire_worker() -> void:
    if cash < 90:
        _notify("You need $90 to hire a worker.")
        return
    cash -= 90
    workers += 1
    var worker := Node3D.new()
    worker.position = Vector3(-3.5 + workers, 0, -3.7)
    world_root.add_child(worker)
    var mesh := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.3
    capsule.height = 1.5
    mesh.mesh = capsule
    mesh.position.y = 0.75
    mesh.material_override = _material(Color("#568b7d"))
    worker.add_child(mesh)
    _notify("Worker hired! Every sale earns an extra $3.")
    _update_hud()

func _upgrade_oven() -> void:
    if cash < 70:
        _notify("You need $70 to upgrade the oven.")
        return
    cash -= 70
    oven_level += 1
    _notify("Oven upgraded to level %d. Better pizzas pay more!" % oven_level)
    _update_hud()

func _spawn_customer() -> void:
    var customer := Node3D.new()
    customer.position = Vector3(7.5, 0, 5.0)
    world_root.add_child(customer)
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.32
    capsule.height = 1.55
    body.mesh = capsule
    body.position.y = 0.78
    body.material_override = _material([Color("#6c83b5"), Color("#c27e64"), Color("#638d6a")][randi() % 3])
    customer.add_child(body)
    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.24
    sphere.height = 0.48
    head.mesh = sphere
    head.position.y = 1.62
    head.material_override = _material(Color("#d7a078"))
    customer.add_child(head)
    customers.append(customer)
    _notify("A customer walked in!")

func _interact_nearby() -> void:
    if player.global_position.distance_to(Vector3(-5.4, 0, -5.7)) < 4.2:
        _cook_pizza()
    elif last_interaction == "cooked":
        _serve_customer()
    else:
        _notify("Move to the oven, cook a pizza, then serve.")

func _notify(message: String) -> void:
    if is_instance_valid(status_label):
        status_label.text = message

func _update_hud() -> void:
    if not is_instance_valid(cash_label):
        return
    cash_label.text = "$%d   |   PIZZAS %d" % [cash, pizzas_sold]
    status_label.text = "Tables %d   •   Staff %d   •   Oven Lv.%d" % [tables, workers, oven_level]
