using Godot;
using System.Collections.Generic;

public partial class CompositeSelector : Composite
{
    public override NodeState Tick()
    {
        foreach (var child in children)
        {
            var result = child.Tick();
            if (result != NodeState.FAILURE)
            {
                return result;
            }
        }
        return NodeState.SUCCESS;
    }
}
