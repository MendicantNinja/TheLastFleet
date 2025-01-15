extends Control
class_name StarTile

@export var padding : float = 10;
@export var texture = -1;

@onready var star = $Star;

const STARS = [
	{
		pivot_offset = Vector2(970, 800),
		image = preload("res://Art/GUIArt/sector_map_star.png"),
		scale = 0.051,
		rotation = 0,
	},
	{
		pivot_offset = Vector2(1186, 953),
		image = preload("res://Art/GUIArt/sector_map_star_2.png"),
		scale = 0.051,
		rotation = -15 * PI / 180,
	},
	{
		pivot_offset = Vector2(1032, 827),
		image = preload("res://Art/GUIArt/sector_map_star_3.png"),
		scale = 0.051,
		rotation = -15 * PI / 180,
	}
];

func initialize() -> void:
	$LineOverlay.initialize();
	$LineOverlaySelected.initialize();

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var cols = $"../..".columns;
	var rows = $"../..".rows;
	
	if texture == -1:
		texture = randi() % 3
		
	$Star.texture = STARS[texture].image;
	$Star.pivot_offset = STARS[texture].pivot_offset;
	$Star.position = -STARS[texture].pivot_offset + Vector2(padding, padding);
	$Star.scale = Vector2(STARS[texture].scale, STARS[texture].scale);
	$Star.rotation = STARS[texture].rotation;
	$Star.texture_idx = texture;
	$Star.scale *= randf_range(0.6, 1.3);
	
func randomize_star() -> void:
	$Star.position = Vector2(
		randf_range(padding, size.x - padding),
		randf_range(padding, size.y - padding),
	) - $Star.pivot_offset; # + global_position;
	
	var ret = $Reticle;
	ret.pivot_offset = ret.size / 2.;
	

func neighboring_tiles() -> Array:
	var cols = $"../..".columns;
	var rows = $"../..".rows;
	
	var idx = int(str(name));
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
