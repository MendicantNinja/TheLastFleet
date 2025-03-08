extends Camera3D
class_name GalaxyMapCamera3D

# new camera controller
#@export var zoom_fov_change : float = 1.;
#@export var pan_sensitivity : float = 0.005;
#@export var rotation_sensitivity : float = 0.08;
#@export var fov_sensitivity : float = 3;

# old camera controller
@export var zoom_fov_change : float = 1.;
@export var pan_sensitivity : float = 0.01;
@export var rotation_sensitivity : float = 0.05;
@export var fov_sensitivity : float = 1;

var mouse_location : Vector2;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func get_screenspace(node: Node3D) -> Vector2:
	return unproject_position(node.global_position);


func _input(event): 
	if not(event is InputEventMouseMotion and Input.is_action_pressed("camera_pan")):
		return
	position += -Vector3(event.relative.x, 0, event.relative.y) * pan_sensitivity; # * global_transform.basis.get_rotation_quaternion();
	rotation.x -= event.relative.y * pan_sensitivity * rotation_sensitivity;
	fov += event.relative.y * pan_sensitivity * fov_sensitivity;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("camera_zoom_in"):
		print("Zoom In!");
		fov = clamp(fov - zoom_fov_change, 50, 125);
	
	if Input.is_action_pressed("camera_zoom_out"):
		print("Zoom Out!");
		fov = clamp(fov + zoom_fov_change, 50, 125);
		
