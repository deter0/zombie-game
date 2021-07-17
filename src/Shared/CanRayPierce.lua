local MaterialAffectors =  {
	[Enum.Material.Wood] = .8,
	[Enum.Material.Glass] = .5,
	[Enum.Material.Concrete] = 1.35,
};

return function(Cast, RaycastResult:RaycastResult, SegmentVelocity)
	if (RaycastResult.Instance.Transparency >= .95) then return true; end;

	Cast.UserData.Hits = (Cast.UserData.Hits and Cast.UserData.Hits + 1) or 1;

	local Hits = Cast.UserData.Hits;

	if (Hits > 5) then return false; end; -- Throttle

	local RaycastOrigin = Cast.UserData.RayOrigin;
	local Direction = Cast.UserData.Direction;

	if (RaycastResult.Instance:IsA("BasePart")) then
		local Size = (RaycastResult.Instance.Size * RaycastResult.Normal).Magnitude;

		if (Size > 25) then return false; end;

		local OpposingRaycast = workspace:Raycast(RaycastResult.Position + (Direction * Size * 2), -(Direction * Size * 2));

		if (OpposingRaycast) then
			local RayCoverage = (RaycastResult.Position - OpposingRaycast.Position).Magnitude * (MaterialAffectors[OpposingRaycast.Material] or 1);

			print(RayCoverage);

			return (RayCoverage <= 2);
		end
	end

	return false;
end