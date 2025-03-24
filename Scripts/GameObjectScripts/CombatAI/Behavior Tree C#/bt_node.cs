using Godot;
using System;

public abstract partial class BehaviorTreeNode : BehaviorTree
{
    public enum MapType 
	{
	OCCUPANCY_MAP,
	THREAT_MAP,
	INFLUENCE_MAP,
	TENSION_MAP,
	VULNERABILITY_MAP,
	}

	public SteerData steer_data;

	public ShipWrapper ship_wrapper;

    public enum NodeState {FAILURE, SUCCESS, RUNNING};

    protected NodeState state;

    public abstract NodeState Tick(Node agent);
}
