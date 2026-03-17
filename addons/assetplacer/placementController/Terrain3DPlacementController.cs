// Terrain3DPlacementController.cs
// Copyright (c) 2023 CookieBadger. All Rights Reserved.

#if TOOLS
#nullable disable
using System;
using System.Collections.Generic;
using System.Diagnostics;
using Godot;

namespace AssetPlacer;

public partial class Terrain3DPlacementController : SurfacePlacementController
{
	private enum Terrain3DVersion { Compatible, Version_0_9_3_orLower, Incompatible}

	private static Terrain3DVersion _version = Terrain3DVersion.Compatible;
	public Terrain3DPlacementController()
	{
	}
	
	public Terrain3DPlacementController(PlacementUi placementUi, Snapping snapping, EditorInterface editorInterface, Node root) : base(placementUi, snapping, editorInterface, root)
	{
	}

	private static Variant GetTerrain3DDataWithError(Node terrain3DNode)
	{
		if (_version == Terrain3DVersion.Incompatible)
		{
			return new Variant();
		}
		var data = GetTerrain3DData(terrain3DNode, _version);
		
		if (data.Obj != null)
		{
			return data;
		}
		
		// if the accessor ever happens to be renamed again, we can put several retry versions in an array, and loop over it until it is empty 
		var retryVersion = _version switch
		{
			Terrain3DVersion.Compatible => Terrain3DVersion.Version_0_9_3_orLower,
			Terrain3DVersion.Version_0_9_3_orLower => Terrain3DVersion.Compatible,
			_ => Terrain3DVersion.Incompatible
		};
		data = GetTerrain3DData(terrain3DNode, retryVersion);

		if (data.Obj != null)
		{
			_version = retryVersion;
			GD.Print($"({nameof(AssetPlacerPlugin)}) : Outdated Terrain3D API - this error is caused by your Terrain3D version. Consider updating to Terrain3D version 0.9.3 or newer and restarting AssetPlacer.");
		}
		else
		{
			_version = Terrain3DVersion.Incompatible;
			GD.Print($"({nameof(AssetPlacerPlugin)}) : Unexpected error while trying to get Terrain3D data. Consider downgrading to a working Terrain3D version and restarting AssetPlacer, or contact the AssetPlacer developer.");
		}
		
		return data;
	}
	private static Variant GetTerrain3DData(Node terrain3DNode, Terrain3DVersion version)
	{
		var data = new Variant();
		switch (version)
		{
			case Terrain3DVersion.Compatible:
				data =  terrain3DNode.Call("get_data");
				break;
			case Terrain3DVersion.Version_0_9_3_orLower:
				data = terrain3DNode.Get("storage");
				break;
		}
		return data;
	}
	public override PlacementInfo GetPlacementPosition(Camera3D viewportCam, Vector2 viewportMousePosition, List<Node3D> placingNodes)
	{
		var _terrain3DNode = placementUi._terrain3DSelector.Node;
		if(viewportCam == null) return new PlacementInfo(PlacementPositionInfo.invalidInfo);
		if(_terrain3DNode == null) return new PlacementInfo(PlacementPositionInfo.invalidInfo, "Assign Terrain3D Node!", Colors.Red);
		var from = viewportCam.ProjectRayOrigin(viewportMousePosition * viewportCam.GetViewport().GetVisibleRect().Size);
		var dir = viewportCam.ProjectRayNormal(viewportMousePosition * viewportCam.GetViewport().GetVisibleRect().Size);

		
		var data = GetTerrain3DDataWithError(_terrain3DNode);
		if (data.Obj == null)
		{
			return new PlacementInfo(PlacementPositionInfo.invalidInfo, "Error retrieving Terrain3D data", Colors.Red);
		}
		var heightRange = data.As<GodotObject>().Call("get_height_range");
		if (heightRange.Obj == null)
		{
			heightRange = data.As<Resource>().Get("height_range"); // legacy (>0.9.3)
			if (heightRange.Obj == null)
			{
				return new PlacementInfo(PlacementPositionInfo.invalidInfo, "Error retrieving Terrain3D height range", Colors.Red);	
			}
		}
		
		if (viewportCam.Projection == Camera3D.ProjectionType.Orthogonal)
		{
			from = OrthogonalClamp(from, dir, heightRange.AsVector2());
		}
		
		var intersectionVar = _terrain3DNode.Call("get_intersection", from, dir);
		if (intersectionVar.Obj == null)
		{
			return new PlacementInfo(PlacementPositionInfo.invalidInfo, "Error retrieving Intersection with Terrain3D", Colors.Red);
		}

		var intersection = intersectionVar.AsVector3();
		if (intersection.X >= 3.4e38) // no intersection
		{
			return new PlacementInfo(PlacementPositionInfo.invalidInfo, "Hover over Terrain3D to place");
		}
        
		var pos = intersection;
		var normalVar = data.As<GodotObject>().Call("get_normal", intersection);
		if (normalVar.Obj == null)
		{
			return new PlacementInfo(PlacementPositionInfo.invalidInfo, "Error retrieving Terrain3D Normal", Colors.Red);
		}
		var normal = normalVar.AsVector3();
		if (Mathf.IsNaN(normal.X) && Mathf.IsNaN(normal.Y) && Mathf.IsNaN(normal.Z))
		{
			normal = Vector3.Up;
		} else if (normal.LengthSquared() < Mathf.Epsilon || Mathf.IsNaN(normal.X) || Mathf.IsNaN(normal.Y) || Mathf.IsNaN(normal.Z))
		{
			return new PlacementInfo(PlacementPositionInfo.invalidInfo, "Error retrieving Terrain3D Normal", Colors.Red);
		}
		
		var placementInfo = new SurfacePlacementPositionInfo(pos, true, placementUi.AlignWithSurfaceNormal, normal, placementUi.AlignmentDirection);

		if (placementInfo.posValid)
		{
			var (gridPos, gridRot) = GetGridTransform(placementInfo);
			snapping.UpdateGridTransform(gridPos, viewportCam.Projection == Camera3D.ProjectionType.Perspective, gridRot);
		}
		
		_lastValidPlacementInfo = placementInfo;
		if(placementInfo.posValid) snapping.HideGrid(false);
		//return new PlacementInfo(PlacementPositionInfo.invalidInfo, $"{from}, {dir}, {intersection}", Colors.Red);
		return new PlacementInfo(placementInfo);
	}

	private Vector3 OrthogonalClamp(Vector3 from, Vector3 dir, Vector2 heightRange)
	{
		const int distance = 30;
		if (from.Y > 1 && dir.Y < 0) // looking from above
		{
			var m = heightRange.Y + distance;
			var t = (m - from.Y) / dir.Y;

			return from + dir * t;
		}
		else if (from.Y < -1 && dir.Y > 0) // looking from below
		{
			var m = heightRange.X - distance;
			var t = (m - from.Y) / dir.Y;

			return from + dir * t;
		}
		return from;
	}
}
#endif
