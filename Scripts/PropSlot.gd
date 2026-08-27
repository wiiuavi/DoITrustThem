class_name PropSlot
extends Node3D

@export_enum("Random", "Painting", "Vase", "Box", "TV", "Plant", "Image") var category: String = "Random"

const COLORS = ["Red", "Blue", "Green", "Purple", "Yellow", "Black"]
const PAINTING_TITLES = ["Patrick Jane", "Mona Lisa", "Dark Woods", "The Screaming Man", "Ocean Wave"]
const IMAGE_TITLES = ["Image 1", "Image 2", "Image 3", "Image 4", "Image 5"]


func spawn_random_prop() -> Dictionary:
	for child in get_children():
		child.queue_free()

	if randf() > 0.8:
		return {}

	var categories_list = ["Painting", "Vase", "Box", "TV", "Plant", "Image"]
	var item_dict = {}
	
	var prop_node = StaticBody3D.new()
	prop_node.set_script(load("res://Scripts/Interactable.gd"))
	prop_node.collision_layer = 2

	var mesh_inst = MeshInstance3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.6, 0.8, 0.1)
	
	var col_shape = CollisionShape3D.new()
	col_shape.shape = box_shape

	prop_node.add_child(mesh_inst)
	prop_node.add_child(col_shape)

	var mat = StandardMaterial3D.new()

	
	var attempts = 0
	var is_duplicate = true
	var final_cat = category
	var p_title = ""
	var img_title = ""
	var color_name = ""

	while is_duplicate and attempts < 30:
		attempts += 1
		if category == "Random":
			final_cat = categories_list.pick_random()
		else:
			final_cat = category

		item_dict.clear()

		if final_cat == "Painting":
			p_title = PAINTING_TITLES.pick_random()
			item_dict["name"] = p_title + " Painting"
			item_dict["color"] = ""
		elif final_cat == "Image":
			img_title = IMAGE_TITLES.pick_random()
			item_dict["name"] = img_title
			item_dict["color"] = ""
		else:
			color_name = COLORS.pick_random()
			item_dict["name"] = final_cat
			item_dict["color"] = color_name

		is_duplicate = false
		for existing in Global.active_house_items:
			if existing["name"] == item_dict["name"] and existing["color"] == item_dict["color"]:
				is_duplicate = true
				break

	if is_duplicate:
		prop_node.queue_free()
		return {}


	if final_cat == "Painting":
		prop_node.item_name = item_dict["name"]
		prop_node.item_color = ""
		prop_node.description = "A painting titled '" + item_dict["name"].trim_suffix(" Painting") + "'"
		
		var quad = QuadMesh.new()
		quad.size = Vector2(0.8, 1.0)
		mesh_inst.mesh = quad
		mat.albedo_color = Color(randf(), randf(), randf())

	elif final_cat == "Image":
		prop_node.item_name = item_dict["name"]
		prop_node.item_color = ""
		prop_node.description = "An image titled '" + item_dict["name"] + "'"
		
		var thin_box = BoxMesh.new()
		thin_box.size = Vector3(0.5, 0.7, 0.04)
		mesh_inst.mesh = thin_box
		mat.albedo_color = Color.WHITE

	else:
		prop_node.item_name = final_cat
		prop_node.item_color = item_dict["color"]
		prop_node.description = item_dict["color"] + " " + final_cat

		var box = BoxMesh.new()
		box.size = Vector3(0.4, 0.4, 0.4)
		mesh_inst.mesh = box
		
		match item_dict["color"]:
			"Red": mat.albedo_color = Color.RED
			"Blue": mat.albedo_color = Color.BLUE
			"Green": mat.albedo_color = Color.GREEN
			"Purple": mat.albedo_color = Color.PURPLE
			"Yellow": mat.albedo_color = Color.YELLOW
			"Black": mat.albedo_color = Color.DARK_SLATE_GRAY

	mesh_inst.material_override = mat
	add_child(prop_node)
	
	return item_dict
