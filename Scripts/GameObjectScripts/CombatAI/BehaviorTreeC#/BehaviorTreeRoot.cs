using System;
using Godot;

[Icon("res://Art/MetaIcons/BehaviorTree/tree.svg")]
public partial class BehaviorTreeRoot : BehaviorTree
{
	[Export]
	public bool enabled { get; private set; }

	public Node agent;

	public override void _Ready()
	{
		agent = GetParent();
		if (GetChildCount() != 1)
		{
			ToggleRoot(false);
			return;
		}
	}

	public override void _PhysicsProcess(double delta)
	{
		if (enabled == false)
		{
			return;
		}

		if (GetChild(0) is not BehaviorTreeNode child)
		{
			throw new InvalidOperationException("The first child of BehaviorTreeRoot is not a valid BehaviorTreeNode.");
		}
		child.Tick(agent);
	}

	public void ToggleRoot(bool value)
	{
		enabled = value;
	}
}
