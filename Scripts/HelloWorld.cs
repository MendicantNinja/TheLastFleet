using Godot;
using System;

public partial class HelloWorld : Node
{
	public override void _Ready()
	{
		GD.Print("Hello, World!");
	}
}
