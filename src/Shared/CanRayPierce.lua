local MaterialEffectors =  {
	[Enum.Material.Wood] = .8,
	[Enum.Material.Glass] = .5,
	[Enum.Material.Concrete] = 2,
	[Enum.Material.Brick] = 2,
};

return function(Cast, RaycastResult:RaycastResult, SegmentVelocity)
	if (RaycastResult.Instance.Transparency >= .95) then return true; end;

	Cast.UserData.Hits = (Cast.UserData.Hits and Cast.UserData.Hits + 1) or 1;

	local Hits = Cast.UserData.Hits;

	if (Hits > 5) then return false; end;

	local Direction = Cast.UserData.Direction;

	if (RaycastResult.Instance:IsA("BasePart")) then
		local Size = (RaycastResult.Instance.Size * RaycastResult.Normal).Magnitude;

		if (Size >= 25) then return false; end;

		local ThisRaycastParams = RaycastParams.new();
		ThisRaycastParams.FilterType = Enum.RaycastFilterType.Whitelist;
		ThisRaycastParams.FilterDescendantsInstances = {RaycastResult.Instance};
		ThisRaycastParams.IgnoreWater = true;

		local OpposingRaycast = workspace:Raycast(RaycastResult.Position + (Direction * Size * 1.2), -(Direction * Size * 2), ThisRaycastParams);

		if (OpposingRaycast) then
			local RayCoverage = (RaycastResult.Position - OpposingRaycast.Position).Magnitude * (MaterialEffectors[OpposingRaycast.Material] or 1);
			
			local Hardness = RaycastResult.Instance:GetAttribute("MaterialHardness");
			RayCoverage *= Hardness or 1;

			return (RayCoverage <= 3);
		end
	end

	return false;
end