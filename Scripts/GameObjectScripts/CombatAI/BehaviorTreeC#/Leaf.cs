using Godot;
using System;

[Icon("res://Art/MetaIcons/BehaviorTree/action.svg")]
public abstract partial class Leaf : BehaviorTreeNode
{
	public override void _Ready()
	{
		if (GetChildCount() > 0)
		{
			throw new InvalidOperationException($"{GetType().Name} should not have children.");
		}
	}
}
