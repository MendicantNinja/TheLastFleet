using Godot;
using System;
using System.Collections.Generic;

public partial class SeekAndArrive : LeafAction
{
	// Called when the node enters the scene tree for the first time.
	float occupancy_radius = 0.0f;
	float radius_modifier = 0.95f;
	int target_area_radius = 50;

	float time = 0.0f;

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override NodeState Tick(Node agent)
	{
		return NodeState.FAILURE;
	}
}
