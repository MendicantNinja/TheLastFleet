extends RichTextLabel

# Called when the node enters the scene tree for the first time.
var steps: Array[TutorialStep] = []
var current_step_index: int = 0
var move_order: bool
var attack_order: bool
var never_true: bool = false
var tween: Tween = create_tween()
@onready var next_button: TextureButton = $HBoxContainer/StepForward

func _ready():
	
	
	tween.tween_property(next_button, "self_modulate", Color(2, 2, 2, 2), .7)
	tween.tween_property(next_button, "self_modulate", Color(0.3, 0.3, 0.3, 1), .7)
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.set_loops()
	tween.stop()
	next_button.pressed.connect(func():
		if steps[current_step_index].skippable == true:
			if current_step_index + 1 < steps.size():
				current_step_index += 1
				show_step_text(steps[current_step_index])
)
	$HBoxContainer/StepBackward.pressed.connect(func():
		if current_step_index > 0:
				current_step_index -= 1
				show_step_text(steps[current_step_index])
)

# Check if the current step/condition is returning true or false.
func _process(_delta):
	if current_step_index >= steps.size():
		return

	
	var current_step = steps[current_step_index]
	if current_step.skippable == false:
		$Succeed.visible = false
		$ContinueLabel.visible = false
		tween.stop()
		next_button.self_modulate = Color(0.3, 0.3, 0.3, 1)
		
	if current_step.condition.call() and not current_step.skippable: # Check if the current step/condition is returning true or false.
		current_step.skippable = true
		$Succeed.visible = true
		$ContinueLabel.visible = true
		tween.play()

		#current_step_index += 1
		#if current_step_index < steps.size():
			#show_step_text(steps[current_step_index])


func setup(tutorial_type: data.tutorial_type_enum) -> void:
	if tutorial_type == 1: # Basics
		steps = [ TutorialStep.new(&"tutorial_panning", data.get_text(&"tutorial_panning"), func(): return Input.is_action_just_pressed("camera_action")),
		TutorialStep.new(&"tutorial_deployment", data.get_text(&"tutorial_deployment"), func(): return get_tree().get_nodes_in_group("friendly").size() > 0),
		TutorialStep.new(&"tutorial_camera", data.get_text(&"tutorial_camera"), func(): return Input.is_action_just_pressed("camera_feed")),
		TutorialStep.new(&"tutorial_map", data.get_text(&"tutorial_map"), func(): return Input.is_action_just_pressed("toggle_map")),
		TutorialStep.new(&"tutorial_pause", data.get_text(&"tutorial_pause"), func(): return Input.is_action_just_pressed("pause")),
		TutorialStep.new(&"tutorial_complete", data.get_text(&"tutorial_complete"), func(): return never_true)
		]
	
	elif tutorial_type == 2: # Tactics
		steps = [
		TutorialStep.new(&"tutorial_deployment", data.get_text(&"tutorial_deployment"), func(): return get_tree().get_nodes_in_group("friendly").size() > 0),
		TutorialStep.new(&"tutorial_selection", data.get_text(&"tutorial_selection"), func(): return detect_move_order()),
		TutorialStep.new(&"tutorial_attack", data.get_text(&"tutorial_attack"), func(): return detect_attack_order()),
		TutorialStep.new(&"tutorial_battle", data.get_text(&"tutorial_battle"), func(): return get_tree().get_nodes_in_group("enemy").size() == 0),
		TutorialStep.new(&"tutorial_complete", data.get_text(&"tutorial_complete"), func(): return never_true)
		]
	
	elif tutorial_type == 3: # Manual
		steps = [ 
		TutorialStep.new(&"tutorial_manual", data.get_text(&"tutorial_manual"), func(): return Input.is_action_just_pressed("take_manual_control")),
		TutorialStep.new(&"tutorial_movement", data.get_text(&"tutorial_movement"), func(): return Input.is_action_just_pressed("turn_right")),
		TutorialStep.new(&"tutorial_weapons", data.get_text(&"tutorial_weapons"), func(): return Input.is_action_just_pressed("select_weapon_1")),
		TutorialStep.new(&"tutorial_firing", data.get_text(&"tutorial_firing"), func(): return Input.is_action_just_pressed("select")),
		TutorialStep.new(&"tutorial_shields", data.get_text(&"tutorial_shields"), func(): return Input.is_action_just_pressed("m2")),
		TutorialStep.new(&"tutorial_battle", data.get_text(&"tutorial_battle"), func(): return get_tree().get_nodes_in_group("enemy").size() == 0),
		TutorialStep.new(&"tutorial_complete", data.get_text(&"tutorial_complete"), func(): return never_true)
		]
	else:
		push_error("Check combat_arena.gd and tutorial_walkthrough.gd. This is not a valid tutorial enum.")
	show_step_text(steps[current_step_index])
func detect_attack_order() -> bool:
	return attack_order
	
func detect_move_order() -> bool:
	return move_order

func show_step_text(step: TutorialStep):
	self.text = step.text
	$HBoxContainer/StepCounter.text = str(current_step_index+1) + "/" + str(steps.size()) 
	self.visible = true
