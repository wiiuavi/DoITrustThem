@tool
class_name PropSlot
extends Node3D

@export_enum("Prop", "Image") var slot_type: String = "Prop":
	set(value):
		slot_type = value
		_update_placeholder_visibility()

const COLORS = ["Red", "Blue", "Green", "Purple", "Yellow", "Black"]

func _ready():
	_update_placeholder_visibility()

func _update_placeholder_visibility():
	var canvas = get_node_or_null("PlaceholderCanvas") as MeshInstance3D
	if canvas:
		canvas.visible = slot_type == "Image"

func clear_slot():
	for child in get_children():
		child.queue_free()

func spawn_random_prop() -> Dictionary:
	clear_slot()

	var item_dict = {}
	var prop_node = StaticBody3D.new()
	prop_node.set_script(load("res://Scripts/Interactable.gd"))
	prop_node.collision_layer = 2

	var templates = []
	var template_parent = get_node_or_null("/root/Main/TemplateProps")
	if template_parent:
		for child in template_parent.get_children():
			if child is MeshInstance3D and child.mesh:
				templates.append(child)
	
	var image_titles = []
	var dir = DirAccess.open("res://images")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".png"):
					var t = file_name.trim_suffix(".png")
					if not image_titles.has(t):
						image_titles.append(t)
				elif file_name.ends_with(".png.import"):
					var t = file_name.trim_suffix(".png.import")
					if not image_titles.has(t):
						image_titles.append(t)
			file_name = dir.get_next()
			
	var is_duplicate = true
	var attempts = 0
	var chosen_name = ""
	var chosen_color = ""
	var chosen_template = null

	while is_duplicate and attempts < 30:
		attempts += 1
		if slot_type == "Image":
			if image_titles.size() > 0:
				chosen_name = image_titles.pick_random()
			else:
				chosen_name = "Placeholder"
			chosen_color = ""
		else:
			if templates.size() > 0:
				chosen_template = templates.pick_random()
				chosen_name = chosen_template.name
			else:
				chosen_name = "Generic Box"
			chosen_color = COLORS.pick_random()

		is_duplicate = false
		for existing in Global.active_house_items:
			if existing["name"] == chosen_name and existing["color"] == chosen_color:
				is_duplicate = true
				break

	if is_duplicate:
		prop_node.queue_free()
		return {}

	item_dict["name"] = chosen_name
	item_dict["color"] = chosen_color
	item_dict["node"] = prop_node

	if slot_type == "Image":
		prop_node.item_name = chosen_name
		prop_node.item_color = ""
		prop_node.description = "An image titled '" + chosen_name + "'"
		
		var canvas_mesh = MeshInstance3D.new()
		var canvas_box = BoxMesh.new()
		canvas_box.size = Vector3(0.6, 0.8, 0.05)
		canvas_mesh.mesh = canvas_box
		var canvas_mat = StandardMaterial3D.new()
		canvas_mat.albedo_color = Color.WHITE
		canvas_mesh.material_override = canvas_mat
		prop_node.add_child(canvas_mesh)
		
		var face_mesh = MeshInstance3D.new()
		var quad = QuadMesh.new()
		quad.size = Vector2(0.55, 0.75)
		face_mesh.mesh = quad
		face_mesh.position.z = 0.026 
		var face_mat = StandardMaterial3D.new()
		if ResourceLoader.exists("res://images/" + chosen_name + ".png"):
			face_mat.albedo_texture = load("res://images/" + chosen_name + ".png")
		else:
			face_mat.albedo_color = Color.DARK_GRAY
		face_mesh.material_override = face_mat
		prop_node.add_child(face_mesh)

		var col_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(0.6, 0.8, 0.05)
		col_shape.shape = box_shape
		prop_node.add_child(col_shape)
		
	else:
		prop_node.item_name = chosen_name
		prop_node.item_color = chosen_color
		prop_node.description = chosen_color + " " + chosen_name

		var mesh_inst = MeshInstance3D.new()
		var col_shape = CollisionShape3D.new()

		if chosen_template:
			mesh_inst.mesh = chosen_template.mesh.duplicate()
			mesh_inst.scale = chosen_template.scale
			var shape = mesh_inst.mesh.create_convex_shape()
			col_shape.shape = shape
			col_shape.scale = chosen_template.scale
			var aabb = mesh_inst.mesh.get_aabb()
			col_shape.position = aabb.get_center() * chosen_template.scale
		else:
			var box = BoxMesh.new()
			box.size = Vector3(0.4, 0.4, 0.4)
			mesh_inst.mesh = box
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(0.4, 0.4, 0.4)
			col_shape.shape = box_shape

		var mat = StandardMaterial3D.new()
		match chosen_color:
			"Red": mat.albedo_color = Color.RED
			"Blue": mat.albedo_color = Color.BLUE
			"Green": mat.albedo_color = Color.GREEN
			"Purple": mat.albedo_color = Color.PURPLE
			"Yellow": mat.albedo_color = Color.YELLOW
			"Black": mat.albedo_color = Color.DARK_SLATE_GRAY
			
		mesh_inst.material_override = mat
		prop_node.add_child(mesh_inst)
		prop_node.add_child(col_shape)

	add_child(prop_node)
	return item_dict
