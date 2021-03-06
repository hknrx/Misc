using UnityEngine;
using System.Collections.Generic;

public partial class Sprite
{
	static readonly Dictionary<string, List<Vector2>> spritesContour = new Dictionary<string, List<Vector2>> ()
	{
		{"Apple", new List<Vector2> {
			new Vector2 (38, 6),
			new Vector2 (13, 14),
			new Vector2 (2, 26),
			new Vector2 (0, 39),
			new Vector2 (2, 50),
			new Vector2 (13, 68),
			new Vector2 (27, 78),
			new Vector2 (50, 78),
			new Vector2 (60, 75),
			new Vector2 (75, 59),
			new Vector2 (79, 42),
			new Vector2 (80, 32),
			new Vector2 (76, 20),
			new Vector2 (61, 8),
		}},
		{"Banana", new List<Vector2> {
			new Vector2 (2, 0),
			new Vector2 (2, 9),
			new Vector2 (8, 15),
			new Vector2 (9, 27),
			new Vector2 (15, 39),
			new Vector2 (35, 50),
			new Vector2 (65, 50),
			new Vector2 (79, 45),
			new Vector2 (95, 31),
			new Vector2 (100, 17),
			new Vector2 (93, 14),
			new Vector2 (62, 30),
			new Vector2 (36, 28),
			new Vector2 (12, 13),
			new Vector2 (11, 7),
			new Vector2 (4, 0),
		}},
		{"Strawberry", new List<Vector2> {
			new Vector2 (0, 36),
			new Vector2 (0, 39),
			new Vector2 (4, 45),
			new Vector2 (41, 49),
			new Vector2 (49, 47),
			new Vector2 (66, 29),
			new Vector2 (68, 14),
			new Vector2 (62, 9),
			new Vector2 (38, 0),
			new Vector2 (27, 3),
			new Vector2 (1, 31),
		}},
		{"Test", new List<Vector2> {
			new Vector2 (0, 0),
			new Vector2 (0, 100),
			new Vector2 (50, 100),
			new Vector2 (50, 20),
			new Vector2 (20, 20),
			new Vector2 (20, 80),
			new Vector2 (20, 80),
			new Vector2 (30, 80),
			new Vector2 (30, 30),
			new Vector2 (40, 30),
			new Vector2 (40, 90),
			new Vector2 (10, 90),
			new Vector2 (10, 10),
			new Vector2 (60, 10),
			new Vector2 (60, 100),
			new Vector2 (100, 100),
			new Vector2 (100, 0),
			new Vector2 (80, 0),
			new Vector2 (80, 10),
			new Vector2 (90, 10),
			new Vector2 (90, 90),
			new Vector2 (70, 90),
			new Vector2 (70, 0),
		}},
	};
}
