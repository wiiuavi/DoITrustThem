# Interactable.gd - Interactive base script
extends StaticBody3D

enum Type { ITEM, DOOR, PHONE }

@export var type: Type = Type.ITEM
@export var item_name: String = "Generic Object"
@export var item_color: String = ""
@export var description: String = "An ordinary object."

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
			# Trust visitor (Open door)
			GameManager.handle_player_decision(true)
			
		Type.PHONE:
			if Global.phone_disabled:
				UIManager.show_subtitle("Security phone line disabled: No further response.", 3.0)
			else:
				# Distrust visitor (Call security)
				GameManager.handle_player_decision(false)
