extends LeafAction

# strafe: useful for a handful of combat scenarios
# Use Case:
# Manuever out of an enemy's field of fire
# Bombing/strafing runs

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.target_in_range == false:
		return FAILURE
	
	return FAILURE
