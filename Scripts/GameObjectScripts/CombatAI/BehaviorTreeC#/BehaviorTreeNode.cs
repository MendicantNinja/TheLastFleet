using Godot;
[Icon("res://Art/MetaIcons/BehaviorTree/category_bt.svg")]
public abstract partial class BehaviorTreeNode : BehaviorTree
{
	public SteerData steer_data = null;

	public ShipWrapper ship_wrapper = null;

    public enum NodeState {FAILURE, SUCCESS, RUNNING};

    protected NodeState state;

    public abstract NodeState Tick(Node agent);
}
