using Godot;
using InfluenceMap;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;

public partial class FindEnemyWeakness : Action
{
	public override NodeState Tick(Node agent)
	{
		if (Engine.GetPhysicsFrames() % 180 != 0) return NodeState.FAILURE;

		Admiral admiral = agent as Admiral;

		Imap weighted_imap = ImapManager.Instance.WeightedImap;
		Imap influence_map = ImapManager.Instance.AgentMaps[ImapType.InfluenceMap];
		Imap inverse_tension_map = ImapManager.Instance.AgentMaps[ImapType.TensionMap];
		Imap tension_map = ImapManager.Instance.TensionMap;
		Imap vulnerability_map = ImapManager.Instance.VulnerabilityMap;

		Godot.Collections.Dictionary<Vector2I, float> player_vulnerability = new Godot.Collections.Dictionary<Vector2I, float>();
		for (int m = 0; m < vulnerability_map.Height; m++)
		{
			for (int n = 0; n < vulnerability_map.Width; n++)
			{
				float imap_value = influence_map.MapGrid[m, n];
				float weighted_imap_value = weighted_imap.MapGrid[m, n];
				float tension_value = 0.0f;
				float vuln_value = 0.0f;
				if (inverse_tension_map.MapGrid[m, n] == 0.0f && imap_value == 0.0f)
				{
					tension_map.MapGrid[m, n] = tension_value;
					vulnerability_map.MapGrid[m, n] = vuln_value;
					vulnerability_map.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, vuln_value);
					weighted_imap.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, weighted_imap_value);
					tension_map.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, tension_value);
					inverse_tension_map.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, inverse_tension_map.MapGrid[m, n]);
					continue;
				}

				tension_value = Mathf.Max(0.0f, inverse_tension_map.MapGrid[m, n] - Mathf.Abs(imap_value));
				vuln_value = tension_value - Mathf.Abs(weighted_imap_value);
				tension_map.MapGrid[m, n] = tension_value;
				vulnerability_map.MapGrid[m, n] = vuln_value;
				if (imap_value > 0.0f)
				{
					player_vulnerability[new Vector2I(m, n)] = vuln_value;
				}

				vulnerability_map.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, vuln_value);
				weighted_imap.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, weighted_imap_value);
				tension_map.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, tension_value);
				inverse_tension_map.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, inverse_tension_map.MapGrid[m,n]);
			}
		}

		if (player_vulnerability.Keys.Count == 0)
		{
			admiral.PlayerVulnerability = player_vulnerability;
			return NodeState.FAILURE;
		}

		Godot.Collections.Dictionary<Vector2I, float> enemy_vuln_norm = new Godot.Collections.Dictionary<Vector2I, float>();
		float vuln_min = player_vulnerability.Values.Min();
		float vuln_max = player_vulnerability.Values.Max();
		foreach (Vector2I cell in player_vulnerability.Keys)
		{
			float value = player_vulnerability[cell];
			float norm_value = 2.0f * ((value - vuln_min) / (vuln_max - vuln_min)) - 1.0f;
			enemy_vuln_norm[cell] = norm_value;
		}
		Godot.Collections.Dictionary<Vector2I, float> target_cells = new Godot.Collections.Dictionary<Vector2I, float>();
		float norm_max = enemy_vuln_norm.Values.Max();
		float norm_min = enemy_vuln_norm.Values.Min();
		foreach (Vector2I cell in enemy_vuln_norm.Keys)
		{
			if (enemy_vuln_norm[cell] == norm_max || enemy_vuln_norm[cell] == norm_min)
			{
				target_cells[cell] = enemy_vuln_norm[cell];
			}
		}

		admiral.PlayerVulnerability = target_cells;
		return NodeState.FAILURE;
	}

}
