using Godot;
using System;

[Icon("res://Art/MetaIcons/BehaviorTree/category_decorator.svg")]
public abstract partial class Decorator : BehaviorTreeNode
{
    public override void _Ready()
    {
        if (GetChildCount() <= 0)
        {
            throw new InvalidOperationException($"{GetType().Name} should have at least one child.");
        }
    }
}
