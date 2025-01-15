extends Control

@export var padding : float = 10;
@export var texture = -1;

const STARS = [
	{
		pivot_offset = Vector2(970, 800),
		image = preload("res://Art/GUIArt/sector_map_star.png"),
		scale = 0.051,
		rotation = 0,
	},
	{
		pivot_offset = Vector2(1180, 950),
		image = preload("res://Art/GUIArt/sector_map_star_2.png"),
		scale = 0.051,
		rotation = -15 * PI / 180,
	},
	{
		pivot_offset = Vector2(995, 820),
		image = preload("res://Art/GUIArt/sector_map_star_3.png"),
		scale = 0.051,
		rotation = -15 * PI / 180,
	}
];

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
