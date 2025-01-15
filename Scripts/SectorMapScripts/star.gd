extends TextureRect
class_name Star

var texture_idx : int;
var radius = 10;
var hovered = false;
var selected = false;
var was_selected = false;
var initialized = false;

@onready var star_center = get_global_transform() * pivot_offset;

func _draw() -> void:
	#if initialized:
		#draw_circle($"../LineOverlay".position, 25000, Color.RED);
		#draw_circle($"../LineOverlay".get_child(0).position, 25000, Color.GREEN);
	#draw_circle($"../..".position, 250, Color.RED);
	#draw_circle(global_position, 200, Color.RED);
	#draw_circle(pivot_offset, 200, Color.GREEN);
	#print("Pivot Offset: ", pivot_offset);
	#draw_circle(global_position + pivot_offset, 200, Color.GREEN);
	pass
	
func _get_startile(n) -> StarTile:
	#print("Getting Star ", n, " from ", $"../..");
	return $"../..".get_child(n);

func _id(n) -> int:
	return int(str(n));
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
	
func _process(_delta: float) -> void:
	hovered = (get_viewport().get_mouse_position() - star_center).length() < radius;
	var ret : TextureRect = $"../Reticle";
	#var ret_center = ret.pivot_offset * get_global_transform();
	ret.global_position = star_center - ret.pivot_offset * ret.scale;
	ret.visible = hovered;
	star_center = get_global_transform() * pivot_offset;
	$"../LineOverlay".visible = hovered and not selected;
	$"../LineOverlaySelected".visible = selected;
	
	if Input.is_action_just_pressed("select") and hovered:
		_on_pressed();

func _on_pressed() -> void:
	$"../../../Ship".move_to_idx(int(str(get_parent().name)));
