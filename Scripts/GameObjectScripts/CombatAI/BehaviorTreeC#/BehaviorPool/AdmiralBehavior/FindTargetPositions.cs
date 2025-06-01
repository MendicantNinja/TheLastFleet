using Godot;
using Globals;
using System;
using System.Collections.Generic;
using System.Numerics;
using Vector2 = System.Numerics.Vector2;
using System.Linq;

public partial class FindTargetPositions : Action
{
	public override NodeState Tick(Node agent)
	{
		if (Engine.GetPhysicsFrames() % 240 != 0) return NodeState.FAILURE;

		Admiral admiral = agent as Admiral;
		if (admiral.HeuristicGoal != Goal.SKIRMISH) return NodeState.FAILURE;

		Godot.Collections.Dictionary<Vector2I, float> player_vulnerability = new Godot.Collections.Dictionary<Vector2I, float>();
		if (admiral.PlayerVulnerability.Keys.Count > 0)
		{
			player_vulnerability = admiral.PlayerVulnerability;
		}
		else if (admiral.PlayerVulnerability.Keys.Count > 0) return NodeState.SUCCESS;

		List<Vector2I> vulnerable_cells = new List<Vector2I>();
		List<Vector2I> isolated_cells = new List<Vector2I>();
		foreach (Vector2I cell in player_vulnerability.Keys)
		{
			float value = player_vulnerability[cell];
			if (value > 0.0f) vulnerable_cells.Add(cell);
			else if (value < 0.0f) isolated_cells.Add(cell);
		}

		Dictionary<Vector2I, Godot.Collections.Array<Vector2I>> isolated_clusters = new Dictionary<Vector2I, Godot.Collections.Array<Vector2I>>();
		foreach (Vector2I cell in isolated_cells)
		{
			Vector2 cell_position = new Vector2(cell.Y * ImapManager.Instance.DefaultCellSize, cell.X * ImapManager.Instance.DefaultCellSize);
			Vector2I registry_cell = new Vector2I((int)cell_position.Y / ImapManager.Instance.MaxCellSize, (int)cell_position.X / ImapManager.Instance.MaxCellSize);

			foreach (Godot.Collections.Array<Vector2I> cluster in ImapManager.Instance.FriendlyClusters)
			{
				if (cluster.Contains(registry_cell) && !isolated_clusters.ContainsKey(registry_cell))
				{
					isolated_clusters[registry_cell] = new Godot.Collections.Array<Vector2I>();
				}
				if (cluster.Contains(registry_cell))
				{
					isolated_clusters[registry_cell].Add(cell);
				}
			}
		}

		Dictionary<Vector2I, Godot.Collections.Array<Vector2I>> vulnerability_cluster = new Dictionary<Vector2I, Godot.Collections.Array<Vector2I>>();
		foreach (Vector2I cell in vulnerable_cells)
		{
			Vector2 cell_position = new Vector2(cell.Y * ImapManager.Instance.DefaultCellSize, cell.X * ImapManager.Instance.DefaultCellSize);
			Vector2I registry_cell = new Vector2I((int)cell_position.Y / ImapManager.Instance.MaxCellSize, (int)cell_position.X / ImapManager.Instance.MaxCellSize);

			foreach (Godot.Collections.Array<Vector2I> cluster in ImapManager.Instance.FriendlyClusters)
			{
				if (cluster.Contains(registry_cell) && !vulnerability_cluster.ContainsKey(registry_cell))
				{
					vulnerability_cluster[registry_cell] = new Godot.Collections.Array<Vector2I>();
				}
				if (cluster.Contains(registry_cell))
				{
					vulnerability_cluster[registry_cell].Add(cell);
				}
			}

		}

		admiral.GoalValue = new Dictionary<Vector2I, float>();
		if (vulnerability_cluster.Count == 0 && isolated_clusters.Count == 0) return NodeState.FAILURE;

		Node globals = GetTree().Root.GetNode("globals");
		List<Vector2I> geo_median_cells = new List<Vector2I>();
		Dictionary<Vector2I, Vector2I> isolated_geo_med = new Dictionary<Vector2I, Vector2I>();
		//List<Vector2I> remove_iso_cluster = new List<Vector2I>();
		foreach (Vector2I cluster in isolated_clusters.Keys)
		{
			Godot.Collections.Array<Vector2I> cells = isolated_clusters[cluster];
			Godot.Vector2 geo_med = (Godot.Vector2)globals.Call("geometric_median_of_objects", cells);
			isolated_geo_med[cluster] = new Vector2I((int)geo_med.X, (int)geo_med.Y);
			geo_median_cells.Add(new Vector2I((int)geo_med.X, (int)geo_med.Y));
		}
		
		Dictionary<Vector2I, Vector2I> vulnerability_geo_med = new Dictionary<Vector2I, Vector2I>();
		foreach (Vector2I cluster in vulnerability_cluster.Keys)
		{
			Godot.Collections.Array<Vector2I> cells = vulnerability_cluster[cluster];
			Godot.Vector2 geo_med = (Godot.Vector2)globals.Call("geometric_median_of_objects", cells);
			vulnerability_geo_med[cluster] = new Vector2I((int)geo_med.X, (int)geo_med.Y);
			geo_median_cells.Add(new Vector2I((int)geo_med.X, (int)geo_med.Y));
		}

		Dictionary<float, Vector2I> dist_to_geo_med = new Dictionary<float, Vector2I>();
		Vector2I baseline = Vector2I.Zero;
		foreach (Vector2I cell in geo_median_cells)
		{
			float dist_to = baseline.DistanceSquaredTo(baseline);
			dist_to_geo_med[dist_to] = cell;
		}

		Vector2I furthest_cell = dist_to_geo_med[dist_to_geo_med.Keys.Max()];
		int goal_radius = (int)(baseline.DistanceTo(furthest_cell) / 2.0f);
		admiral.GoalRadius = goal_radius;
		foreach (Vector2I gm_cell in isolated_geo_med.Keys)
		{
			Vector2I goal_cell = isolated_geo_med[gm_cell];
			admiral.GoalValue[goal_cell] = 1.0f;
		}

		foreach (Vector2I gm_cell in vulnerability_geo_med.Keys)
		{
			Vector2I goal_cell = vulnerability_geo_med[gm_cell];
			if (isolated_clusters.Keys.Count == 0)
			{
				admiral.GoalValue[goal_cell] = 1.0f;
			}
			else
			{
				admiral.GoalValue[goal_cell] = -1.0f;
			}
		}
		
		return NodeState.SUCCESS;
	}

}
