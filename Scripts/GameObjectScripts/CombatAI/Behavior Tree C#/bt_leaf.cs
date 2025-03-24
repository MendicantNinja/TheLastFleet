using Godot;
using System;

public abstract partial class Leaf : BehaviorTreeNode
{
    public interface IInitialize
	{
		void Initialize(Node agent);
	}
    
    public override void _Ready()
    {
        if (GetChildCount() > 0)
        {
            throw new InvalidOperationException($"{GetType().Name} should not have children.");
        }
    }
}
