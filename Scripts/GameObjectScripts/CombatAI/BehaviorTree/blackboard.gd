extends RefCounted
class_name Blackboard

var blackboard = {}

func set_data(key, value: Variant, blackboard_name = &"default") -> void:
	if not blackboard.has(blackboard_name):
		blackboard[blackboard_name] = {}
	
	blackboard[blackboard_name][key] = value

func ret_data(key, default_value = null, blackboard_name = &"default") -> Variant:
	if has_data(key, blackboard_name):
		return blackboard[blackboard_name][key]
	return default_value

func has_data(key, blackboard_name = &"default"):
	return blackboard.has(blackboard_name) and blackboard[blackboard_name].has(key) and blackboard[blackboard_name][key] != null

func remove_data(key, blackboard_name = &"default") -> void:
	if has_data(key):
		blackboard[blackboard_name].erase(key)

func _on_target_destroyed(target, target_group_key: StringName, target_key: StringName) -> void:
	var current_target = ret_data(target_key)
	if target == current_target:
		remove_data(target_key)
	
	if not has_data(target_group_key):
		return
	
	var available_targets: Array = ret_data(target_group_key)
	available_targets.erase(target)
	set_data(target_group_key, available_targets)

func _on_threat_detected(threat_detected, threat_key: StringName, targets_key: StringName) -> void:
	var current_threats_detected: Array = []
	if has_data(threat_key):
		current_threats_detected = ret_data(threat_key)

	var available_targets: Array = []
	if has_data(targets_key):
		available_targets = ret_data(targets_key)

	if not threat_detected in available_targets and not threat_detected in current_threats_detected:
		current_threats_detected.push_back(threat_detected)
	
	set_data(threat_key, current_threats_detected)

func _on_threat_exited(threat_detected, threat_key: StringName, targets_key: StringName) -> void:
	if not has_data(threat_key):
		return
	var current_threats_detected: Array = ret_data(threat_key)
	current_threats_detected.erase(threat_detected)
	set_data(threat_key, current_threats_detected)
