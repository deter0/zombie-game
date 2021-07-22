local FPS = {};

function FPS:Start()
	local PlayerService = game:GetService("Players");
	local Player = PlayerService.LocalPlayer;

	local PlayerGui = Player:WaitForChild("PlayerGui");

	local FPSText = PlayerGui:WaitForChild("FPS"):WaitForChild("FPS");
	local FrameTimeText = PlayerGui:WaitForChild("FPS"):WaitForChild("FrameTime");

	local RunService = game:GetService("RunService");

	local Updated = 0;
	RunService.RenderStepped:Connect(function(DeltaTime:number)
		if (time() - Updated > .1) then
			local FrameRate = string.sub(tostring(1/DeltaTime), 1, 5);

			FPSText.Text = FrameRate .. " FPS";
			FrameTimeText.Text = string.sub(tostring(DeltaTime * 1000), 1, 5).. "ms";

			Updated = time();
		end
	end)
end

return FPS;