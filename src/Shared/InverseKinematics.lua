-- Inverse Kinematics
-- Deter
-- June 15, 2021



local InverseKinematics = {}
InverseKinematics.__index = InverseKinematics

function InverseKinematics:Calculate()
	local center:Vector3 = (self.start + self.target) / 2;

	local maxLength = self.segments[1].Size.Z + self.segments[2].Size.Z;

	local currentLength = (self.start - self.target).Magnitude;
	local crossed = self.start:Cross(self.target).Unit;
	local length = (maxLength * math.clamp(1 - (currentLength/maxLength), -1, 1) - (crossed.Magnitude/maxLength));

	local inverse = self.inverse;
	
	if (inverse and crossed.Y < 0) then
		inverse = false;
	elseif (not inverse and crossed.Y > 0) then
		inverse = true;
	end

	local face = (center + (crossed * (inverse and length or -length)));
	

	local function calculate(x, y, segment)
		local cf = CFrame.lookAt(x, y) * CFrame.new(0, 0, -segment.Size.Z/2);
		return cf, (cf * CFrame.new(0, 0,-segment.Size.Z/2)).Position;
	end

	local results = {};

	local cf, last = calculate(self.start, face, self.segments[1]);
	results[1] = cf;

	local cf2 = calculate(last, self.target, self.segments[2]);
	results[2] = cf2;

	return results;
end

function InverseKinematics.new(start:Vector3, target:Vector3, segments:{{Size: Vector3}},inverse:boolean|nil)
	local self = setmetatable({
		start = start,
		target = target,
		segments = segments,
		inverse = inverse
	}, InverseKinematics);

	return self;
end


return InverseKinematics