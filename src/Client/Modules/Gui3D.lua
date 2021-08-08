-- 3D Gui Handler
-- Deter
-- July 3, 2021

local UserInputService = game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

local Gui3D = {};
Gui3D.__index = Gui3D;

function Gui3D:Initalize()
	self.Camera = workspace.CurrentCamera;
	self.WeaponHandler = self.Controllers.FPSFramework.WeaponHandler;
	self.Maid = self.Shared.Maid.new();

	self.Effects = {};

	for _, Effect:BasePart in ipairs(self.Container:GetChildren()) do
		if (Effect:IsA("PostEffect")) then
			table.insert(self.Effects, Effect);
		end
	end
end

function Gui3D:Display()
	self.Maid:DoCleaning();

	self.Disabled = self.Disabled or {};

	for _, Effect in ipairs(self.Effects) do
		for _, OtherEffect in ipairs(game:GetService("Lighting"):GetChildren()) do
			if (Effect.ClassName == OtherEffect.ClassName) then
				OtherEffect.Enabled = false;
				self.Disabled[#self.Disabled + 1] = OtherEffect;
			end
		end

		Effect.Enabled = true;
		Effect.Parent = game:GetService("Lighting");
	end

	self.Shared.Thread.Spawn(function()		
		self.Maid.RenderLoop = RunService.RenderStepped:Connect(function(DeltaTime:number)
			self.Camera.CameraType = Enum.CameraType.Scriptable;
	
			-- local ZoomOut = ((3-self.Camera.ViewportSize.X/self.Camera.ViewportSize.Y)*4);
			local CameraCFrame = self.Container:WaitForChild("Gui").CFrame * CFrame.new(self.Container.Gui.CFrameOffset.Value)-- * CFrame.new(0, 0, ZoomOut);
	
			if (self.TargetWindow) then
				CameraCFrame = self.TargetWindow.CFrame * CFrame.new(self.TargetWindow.CFrameOffset.Value);
			end
			
			if (not self.CameraCFrame) then
				self.CameraCFrame = CameraCFrame;
			else
				self.CameraCFrame = self.CameraCFrame:Lerp(CameraCFrame, DeltaTime * 5);
			end
	
			local MouseLocation = UserInputService:GetMouseLocation();
			local MousePercentile = -(MouseLocation / self.Camera.ViewportSize);
	
			self.Camera.Focus = self.Container.PrimaryPart.CFrame;
	
			local RotationCFrame = CFrame.Angles(
				math.tan(math.rad(MousePercentile.Y)),
				math.tan(math.rad(MousePercentile.X)),
				0
			);
			self.RotationCFrame = not self.RotationCFrame and CFrame.new() or self.RotationCFrame:Lerp(RotationCFrame, DeltaTime * 5);
	
			self.Camera.CFrame = self.CameraCFrame * self.RotationCFrame;
		end)
	end)
end

function Gui3D:ClearCurrentWindow()
	if (self.TargetWindow) then
		local WindowFadeOut = TweenService:Create(
			self.TargetWindow,
			TweenInfo.new(.2, Enum.EasingStyle.Cubic), {
				Transparency = 1
			}
		);

		local GuiFadeOut = TweenService:Create(
			self.TargetWindow:FindFirstChildWhichIsA("SurfaceGui"),
			TweenInfo.new(.2, Enum.EasingStyle.Cubic), {
				LightInfluence = 1
			}
		);

		self.TargetWindow:FindFirstChildWhichIsA("SurfaceGui").Enabled = true;

		WindowFadeOut:Play();
		GuiFadeOut:Play();

		local comp; comp = WindowFadeOut.Completed:Connect(function()
			comp:Disconnect();
			WindowFadeOut:Destroy();
			GuiFadeOut:Destroy();
			self.TargetWindow:FindFirstChildWhichIsA("SurfaceGui").Enabled = false;
			self.TargetWindow = nil;

			comp = nil;
		end)
	end
end

function Gui3D:SwitchWindows(WindowName:string)
	local Window = self.Container:FindFirstChild(WindowName);

	self:ClearCurrentWindow();

	if (Window) then
		self.TargetWindow = Window;

		local WindowFadeIn = TweenService:Create(
			Window,
			TweenInfo.new(.2, Enum.EasingStyle.Cubic), {
				Transparency = .75
			}
		);

		local GuiFadeIn = TweenService:Create(
			Window:FindFirstChildWhichIsA("SurfaceGui"),
			TweenInfo.new(.2, Enum.EasingStyle.Cubic), {
				LightInfluence = 0
			}
		);

		Window:FindFirstChildWhichIsA("SurfaceGui").Enabled = true;

		WindowFadeIn:Play();
		GuiFadeIn:Play();

		local comp; comp = WindowFadeIn.Completed:Connect(function()
			comp:Disconnect();
			WindowFadeIn:Destroy();
			GuiFadeIn:Destroy();

			comp = nil;
		end)

		return Window:FindFirstChildWhichIsA("SurfaceGui");
	else
		warn(string.format("Window: %s not found", WindowName));
	end
end

function Gui3D:GetGui()
	return self.Container:WaitForChild("Gui"):WaitForChild("SurfaceGui");
end

function Gui3D:Remove()
	for _, DisabledEffect in ipairs(self.Disabled) do
		DisabledEffect.Enabled = true;
	end
	table.clear(self.Disabled);
	for _, Effect in ipairs(self.Effects) do
		Effect.Parent = self.Container;
	end
	self:ClearCurrentWindow();
	self.Maid:DoCleaning();
	self.Camera.CameraType = Enum.CameraType.Custom;
end

function Gui3D:Toggle(State:boolean?)
	self.Toggled = State;

	if (self.Toggled) then
		self:Display();
	else
		self:Remove();
	end
end

function Gui3D.new(Container:Model)
	assert(Container, "Attempt to make a 3D Gui without container");

	local self = setmetatable({
		Container = Container;
	}, Gui3D);

	self:Initalize();

	return self;
end

return Gui3D;