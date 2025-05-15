using Godot;

[Icon("res://Art/MetaIcons/BehaviorTree/selector.svg")]
public partial class Selector : Composite
{
	public override NodeState Tick(Node agent)
	{
		foreach (var child in children)
		{
			var result = child.Tick(agent);
			if (result != NodeState.FAILURE)
			{
				return result;
			}
		}
		return NodeState.FAILURE;
	}
}
