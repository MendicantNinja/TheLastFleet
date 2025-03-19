using Godot;
using System.Collections.Generic;

public partial class CompositeSequence : Composite
{
    public override NodeState Tick()
    {
        foreach (var child in children)
        {
            var result = child.Tick();
            if (result != NodeState.SUCCESS)
            {
                return result;
            }
        }
        return NodeState.SUCCESS;
    }
}
