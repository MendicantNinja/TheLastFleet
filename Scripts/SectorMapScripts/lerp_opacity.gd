extends RichTextLabel

@export var factor = 0.02;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self_modulate.a = 0.;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self_modulate.a = lerp(self_modulate.a, 1., factor);
