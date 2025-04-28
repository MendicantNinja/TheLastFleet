using Godot;
using InfluenceMap;
using System;
using System.Diagnostics;
using Vector2 = System.Numerics.Vector2;

public partial class Imap : GodotObject
{
	private readonly Vector2 AnchorLocation;
	private readonly float CellSize;
	public readonly int Height;
	public readonly int Width;
	public readonly ImapType Type;
	// m = row, n = column (following M x N convention)
	public float [,] MapGrid;

	// Signals
	[Signal]
	public delegate void UpdateGridValueEventHandler(int m, int n, float value);

	[Signal]
	public delegate void UpdateRowValueEventHandler(int m, float[] values);

	// Constructor
	public Imap(int new_width, int new_height, float x = 0.0f, float y = 0.0f, int new_cell_size = 1)
	{
		Width = new_width / new_cell_size;
		Height = new_height / new_cell_size;
		CellSize = new_cell_size;
		AnchorLocation = new Vector2(x, y);

		MapGrid = new float[Height, Width];
		for (int m = 0; m < Height; m++)
		{
			for (int n = 0; n < Width; n++)
			{
				MapGrid[m, n] = 0.0f;
			}
		}
	}

	public void ClearMap()
	{
		// Create a single-dimensional array representing a row, initialized with zeros.
		float[] reset_row = new float[Width];
		Array.Fill<float>(reset_row, 0.0f); // Fill the entire array with 0.0 (default value for clearing).

		// Iterate through each row index in the 2D MapGrid.
		for (int m = 0; m < Height; m++) // Changed to < Height to avoid out-of-range issues.
		{
			// Use Buffer.BlockCopy to copy the contents of reset_row into the corresponding row of MapGrid.
			// Parameters:
			// - reset_row: The source array (the row of zeros to copy).
			// - 0: The starting offset in the source array (beginning of reset_row).
			// - MapGrid: The destination array (the 2D grid where the row is being set).
			// - m * Width * sizeof(float): The byte offset in MapGrid where row m begins.
			// - Width * sizeof(float): The number of bytes to copy (entire width of the row).
			Buffer.BlockCopy(reset_row, 0, MapGrid, m * Width * sizeof(float), Width * sizeof(float));
		}
	}

	public Vector2I FindCellIndexFromPosition(Vector2 position)
	{
		int cell_row = (int)(position.Y / CellSize); // M
		int cell_column = (int)(position.X / CellSize); // N
		// M x N = row x col
		Vector2I indices = new Vector2I(cell_row, cell_column);
		return indices;
	}

	public Vector2 FindCenterPositionFromCellIndex(Vector2I index)
	{
		// x = row = y position, y = col = x position
		Vector2 center_pos = new Vector2(index.Y, index.X) * CellSize;
		center_pos.X += CellSize / 2.0f;
		center_pos.Y += CellSize / 2.0f;
		return center_pos;
	}

	// Uses a linear function so that the center cell values are peak, and the outermost cell values are near 0.
	public void PropagateInfluenceFromCenter(float magnitude = 1.0f)
	{
		int radius = Height;
		Vector2 center = new Vector2((radius - 1) / 2, (radius - 1) / 2);
		for (int m = -radius; m < radius; m++)
		{
			for (int n = radius; n < radius; n++)
			{
				Vector2 cell_vector = new Vector2(m, n);
				float distance = Vector2.Distance(center, cell_vector);
				float prop_value = magnitude - magnitude * (distance / radius);
				MapGrid[m, n] = prop_value;
			}
		}
	}

	// Uses the Gaussian Function, ie normal distribution, for distributing cell values in such a way that the peak forms a "ring" of cells.
	// Propagation values will fall off the further away the cells are from this peak.
	public void PropagateInfluenceAsRing(float magnitude = 1.0f, float sigma = 1.0f)
	{
		int radius = Height;
		Vector2 center = new Vector2((radius - 1) / 2, (radius - 1) / 2);
		for (int m = -radius; m < radius; m++)
		{
			for (int n = radius; n < radius; n++)
			{
				Vector2 cell_vector = new Vector2(m, n);
				float distance = Vector2.Distance(center, cell_vector);
				float prop_value = (float)(magnitude / (sigma * Math.Sqrt(2 * Math.PI))) * (float)Math.Exp(-Math.Pow(distance - center.X / 2, 2) / (2 * Math.Pow(sigma, 2)));
				MapGrid[m, n] = prop_value;
			}
		}
	}

	public void AddMap(Imap source_map, int center_row, int center_column, float magnitude = 1.0f, int offset_column = 0, int offset_row = 0)
	{
		Debug.Assert(source_map != null, "source_map is null");
		if (source_map == null) return;

		int start_column = center_column + offset_column - source_map.Width / 2;
		int start_row = center_row + offset_row - source_map.Height / 2;

		for (int m = 0; m < source_map.Height; m++)
		{
			int target_row = m + start_row;
			
			for (int n = 0; m < source_map.Width; n++)
			{
				int target_col = n + start_column;
				float value = 0.0f;
				if (target_col >= 0 && target_col < Width && target_row >= 0 && target_row < Height)
				{
					value = MapGrid[target_row, target_col] + source_map.MapGrid[m, n] * magnitude;
					if (Mathf.Snapped(value, 0.1) == 0.0f) value = 0.0f;

					MapGrid[target_row, target_col] = value;
					//UpdateGridValueEventHandler blah blah blah
				}
			}
		}
	}

	public void AddIntoMap(Imap target_map, int center_column, int center_row, float magnitude = 1.0f, int offset_column = 0, int offset_row = 0)
	{
		Debug.Assert(target_map != null, "target_map is null");

		// Locate the upper left corner of where we are propagating values into the map
		// Offset allows center points off the current map to bleed over from adjacent influence maps
		// The right shift operator divides the length by a power of two
		int start_column = center_column + offset_column - (target_map.Width >> 1);
		int start_row = center_row + offset_row - (target_map.Height >> 1);

		int neg_adj_col = 0;
		int neg_adj_row = 0;
		if (AnchorLocation.X < 0.0f) neg_adj_col = -1;
		if (AnchorLocation.Y < 0.0f) neg_adj_row = -1;
		int min_n = Math.Max(0, neg_adj_col - start_column);
		int min_m = Math.Max(0, neg_adj_row - start_row);
		int max_n = Math.Min(target_map.Width, Width - start_column + neg_adj_col);
		int max_m = Math.Min(target_map.Height, Height - start_row + neg_adj_row);

		float[] zero_fill_row = new float[target_map.Width];
		Array.Fill<float>(zero_fill_row, 0.0f);

		for (int m = min_m; m < max_m; m++)
		{
			int source_row = m + start_row - neg_adj_row;

			// Find the minimum and maximum values in the source row
			float source_min = float.MaxValue;
			float source_max = float.MinValue;

			for (int n = 0; n < Width; n++)
			{
				float value = MapGrid[source_row, n];
				if (value < source_min) source_min = value;
				if (value > source_max) source_max = value;
			}

			// If the entire row is zero, fill the target row with zeros
			if (source_min == 0.0f && source_max == 0.0f)
			{
				Buffer.BlockCopy(zero_fill_row, 0, target_map.MapGrid, m * Width * sizeof(float), Width * sizeof(float));
				continue;
			}

			for (int n = min_n; n < max_n; n++)
			{
				int source_col = n + start_column - neg_adj_col;
				target_map.MapGrid[m, n] = MapGrid[source_row, source_col] * magnitude;
			}
		}
	}

}
