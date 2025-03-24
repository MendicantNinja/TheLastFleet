using Godot;
using System;
using System.ComponentModel;

public class SteerData
{
	public Vector2 desired_velocity { get; set; }
	public float default_acceleration { get; private set; }
	public float zero_flux_bonus { get ; private set; }
	public double n_delta { get; private set; }
	public float time_coefficient { get; private set; }

	public void Initialize(Node agent)
	{
		var ship_stats = (Resource)agent.Get("ship_stats") ?? throw new InvalidOperationException("ship_stats cannot be null");
		desired_velocity = Vector2.Zero;
		default_acceleration = (float)ship_stats.Get("acceleration") + (float)ship_stats.Get("bonus_acceleration");
		time_coefficient = (float)agent.Get("time_coefficient");
	}
	
	public void SetDelta(double value)
	{
		n_delta = value;
	}
}
