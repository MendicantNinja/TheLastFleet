extends Resource
class_name GalaxyMapStats

@export_storage var sectors : Array[SectorMap] = [null, null, null, null, null, null, null, null];
@export_storage var selected_path : Array[int] = [0];
@export_storage var seed : int = 0;

# Called after load to unpack all saved sectors. 
func unpack(saved_sectors: Array[PackedScene]) -> void:
	for idx in range(8):
		if saved_sectors[idx] == null: continue
		print("Unpacking Sector ", idx, saved_sectors[idx]);
		sectors[idx] = saved_sectors[idx].instantiate();
		
func pack() -> Array[PackedScene]:
	var out : Array[PackedScene] = [null, null, null, null, null, null, null, null];
	for idx in range(8):
		if sectors[idx] == null: continue
		out[idx] = PackedScene.new();
		out[idx].pack(sectors[idx]);
		print("Packing Sector ", idx, out[idx]);
	return out;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
