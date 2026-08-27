extends StaticBody3D

enum Type { ITEM, DOOR, PHONE }

@export var type: Type = Type.ITEM
@export var item_name: String = "Generic Object"
@export var item_color: String = ""
@export var description: String = "An ordinary object."

var is_door_open: bool = false

func _ready():
	set_collision_layer_value(1, true)
	set_collision_layer_value(2, true)

func interact():
	match type:
		Type.ITEM:
			var text = description
			if item_color != "":
				text = item_color.capitalize() + " " + item_name
			else:
				text = item_name
			UIManager.show_subtitle("Item: " + text, 3.0)
		
		Type.DOOR:
			if is_door_open:
				return
			
			GameManager.handle_player_decision(true)
			_animate_door()
			
		Type.PHONE:
			if Global.phone_disabled:
				UIManager.show_subtitle("Security phone line disabled: No further response.", 3.0)
			else:
				GameManager.handle_player_decision(false)

func _animate_door():
	var mesh_inst: MeshInstance3D = null
	
	for child in get_children():
		if child is MeshInstance3D:
			mesh_inst = child
			break
			
	if not mesh_inst:
		return
		
	is_door_open = true
	
	var orig_pos = mesh_inst.position
	var orig_rot = mesh_inst.rotation
	
	var tween = create_tween()
	tween.tween_property(mesh_inst, "position:x", orig_pos.x - 0.975, 0.3)
	tween.parallel().tween_property(mesh_inst, "rotation:y", orig_rot.y - deg_to_rad(90), 0.3)
	
	await get_tree().create_timer(2.5).timeout
	
	var tween_close = create_tween()
	tween_close.tween_property(mesh_inst, "position", orig_pos, 0.1)
	tween_close.parallel().tween_property(mesh_inst, "rotation", orig_rot, 0.1)
	
	await tween_close.finished
	is_door_open = false
