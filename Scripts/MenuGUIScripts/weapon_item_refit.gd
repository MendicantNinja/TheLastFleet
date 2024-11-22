extends TextureButton

@onready var WeaponName: RichTextLabel = $WeaponName
@onready var WeaponInfo: RichTextLabel = $WeaponInfo
@onready var WeaponCount: RichTextLabel = $WeaponCount
@onready var OrdinancePointCount: RichTextLabel = $OrdinancePointCount
@onready var item_slot: ItemSlot
# Called when the node enters the scene tree for the first time.
func _ready():
	self_modulate = settings.gui_color
	self.gui_input.connect(_on_input_event)

func _on_input_event(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		game_state.player_fleet.remove_single_item(item_slot)
		var focused_weapon_slot: WeaponSlotDisplay = get_viewport().gui_get_focus_owner()
		# Allows swapping weapons
		if focused_weapon_slot.weapon_slot.weapon.item_enum != data.item_enum.EMPTY:
			get_tree().get_current_scene().RefitView.player_fleet.add_item(focused_weapon_slot.weapon_slot.weapon)
		# Set the weapon slot and update list
		focused_weapon_slot.weapon_slot.weapon = data.item_dictionary.get(item_slot.type_of_item)
		get_tree().get_current_scene().RefitView.update_weapon_list()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
