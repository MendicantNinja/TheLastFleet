extends Resource
class_name GalaxyMapStats

# FIXME!!! TEMPORARY!!!
var sectors : Array[SectorMap] = [null, null, null, null, null, null, null, null];

# Called after load to unpack all saved sectors. 
func unpack(saved_sectors: Array[PackedScene]) -> void:
	for idx in range(8):
		if saved_sectors[idx] == null: continue
		print("Unpacking Sector ", idx);
		sectors[idx] = saved_sectors[idx].instantiate();
		
func pack() -> Array[PackedScene]:
	var out : Array[PackedScene] = [null, null, null, null, null, null, null, null];
	for idx in range(8):
		if sectors[idx] == null: continue
		print("Packing Sector ", idx);
		out[idx] = PackedScene.new();
		out[idx].pack(sectors[idx]);
	return out;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
