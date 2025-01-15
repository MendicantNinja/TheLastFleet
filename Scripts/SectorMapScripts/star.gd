extends TextureRect
class_name Star

@export var line_overlay_offset = Vector2(20, 20);
var texture_idx : int;
var radius = 10;
var hovered = false;

@onready var star_center = get_global_transform() * pivot_offset;

func _draw() -> void:
	pass
	#draw_circle(global_position, 200, Color.RED);
	#draw_circle(pivot_offset, 200, Color.GREEN);
	#print("Pivot Offset: ", pivot_offset);
	#draw_circle(global_position + pivot_offset, 200, Color.GREEN);

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	var ret : TextureRect = $"../Reticle";
	#var ret_center = ret.pivot_offset * get_global_transform();
	ret.global_position = star_center - ret.pivot_offset * ret.scale;
	ret.visible = hovered;
	star_center = get_global_transform() * pivot_offset;
	var old_hovered = hovered;
	if (get_viewport().get_mouse_position() - star_center).length() < radius:
		hovered = true
	else: 
		hovered = false
		
	if Input.is_action_just_pressed("select") and hovered:
		_on_pressed();
	
	if old_hovered and not hovered:
		_on_mouse_exited();
		
	if not old_hovered and hovered:
		_on_mouse_entered();
		
	
func neighboring_tiles() -> Array:
	var cols = $"../../..".columns;
	var rows = $"../../..".rows;
	var idx = int(str(get_parent().name));
	var neighboring_tiles = [
		idx - cols, # up
		idx + cols, # down
	];
	
	var neighboring_tiles_left = [
		idx - 1 + cols, # lower left
		idx - 1, # left
		idx - 1 - cols, # upper left
	];
	
	var neighboring_tiles_right = [
		idx + 1 - cols, # upper right
		idx + 1, # right
		idx + 1 + cols, # lower right
	];
	
	if idx % cols != 0: neighboring_tiles.append_array(neighboring_tiles_left);
	if idx % cols != (cols - 1): neighboring_tiles.append_array(neighboring_tiles_right);
	
	return neighboring_tiles;
	
func _on_mouse_entered() -> void:
	var cols = $"../../..".columns;
	var rows = $"../../..".rows;
	for tile in neighboring_tiles():
		if tile < 0 or tile >= cols * rows:
			continue;
		var target_startile = $"../..".get_child(tile);
		var target_star = target_startile.get_child(0);
		var start : Vector2 = star_center - line_overlay_offset;
		var end : Vector2 = target_star.star_center - line_overlay_offset;
		var line : Line2D = $"../Line2D".duplicate();
		$"../../../LineOverlay".add_child(line);
		line.points[0] = start - line.position;
		line.points[1] = end - line.position;
		line.visible = true;
		line.antialiased = true;
		line.width = 1;
		line.position = Vector2(20, 20);
		line.default_color = Color.WHITE;
		
func _on_mouse_exited():
	for child in $"../../../LineOverlay".get_children():
		child.queue_free();


func _on_pressed() -> void:
	$"../../../Ship".move_to_idx(int(str(get_parent().name)));
