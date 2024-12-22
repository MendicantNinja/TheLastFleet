extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	var group_leaders: Array = agent.group_leaders.values()
	var test_array: Array = []
	for leader: Ship in group_leaders:
		if leader.idle == true:
			test_array.push_back(leader.group_name)
	
	agent.order_groups = test_array
	return SUCCESS
