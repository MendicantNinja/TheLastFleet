extends Resource
class_name ItemSlot

var type_of_item: data.item_enum
var number_of_items: int 
var item_icon: Texture2D
# Called when the node enters the scene tree for the first time.


func _init(item_type: data.item_enum, p_number_of_items = 1) -> void:
	type_of_item = item_type
	number_of_items = p_number_of_items

func _ready():
	pass # Replace with function body.
