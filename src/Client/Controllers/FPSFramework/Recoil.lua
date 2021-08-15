-- Recoil
-- Deter
-- August 2, 2021

local Recoil = {
	CurrentRecoil = Vector3.new(),
	TargetRecoil = Vector3.new(),
	RecoilClamp = 7,
	DecaySpeed = 5,
	RiseSpeed = 12,
};
Recoil.__index = Recoil;

function Recoil:Recoil(Strength:number, Randomness:number)
	local Clamp = (1-((50-((self.TargetRecoil.Magnitude - self.RecoilClamp)))/50));
	self.TargetRecoil += Vector3.new(1 * Strength, (math.random()-0.5)*Randomness, 0) * Clamp * -1;
end

local rad = math.rad;
local function GetVectorAsAngles(Vector)
	return CFrame.Angles(
		rad(Vector.X), rad(Vector.Y), rad(Vector.Z)
	);
end

function Recoil:Update(DeltaTime:number, TargetCFrame:CFrame)
	local last = self.CurrentRecoil;

	self.TargetRecoil = self.TargetRecoil:Lerp(Vector3.new(), DeltaTime * self.DecaySpeed);
	self.CurrentRecoil = self.CurrentRecoil:Lerp(self.TargetRecoil, DeltaTime * self.RiseSpeed);

	return TargetCFrame * GetVectorAsAngles(-last) * GetVectorAsAngles(self.CurrentRecoil);
end

function Recoil.new()
	return setmetatable({}, Recoil);
end

return Recoil;