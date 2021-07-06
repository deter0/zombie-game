-- Settings Controller
-- Deter
-- July 1, 2021

local ContextActionService = game:GetService("ContextActionService");
local TweenService = game:GetService("TweenService");

local SettingsController = {
	Components = {},
	ComponentMiddlewares = {
		Slider = function(Value:number, Userdata)
			print("AINSFIHNAIFHGU");
			Userdata.ComponentGui:WaitForChild("Container"):WaitForChild("Value").Text = string.sub(tostring(Value), 1, 5);
		end
	}
};

function SettingsController:Start()
	self.Maid = self.Shared.Maid.new();
	
	self.WeaponHandler = self.Controllers.FPSFramework.WeaponHandler;

	self.GuiContainer = game:GetService("ReplicatedStorage"):WaitForChild("SettingsGui");

	self.Gui3D = self.Gui3D.new(self.GuiContainer, "Settings");

	ContextActionService:BindAction("Open Settings", function()
		if (not self.Opened) then
			self:OpenSettings();
		end
	end, false, Enum.KeyCode.F2);
end

function SettingsController:Close()
	self:ClearCurrentSettings();
	self.Gui3D:Toggle(false);
	self.Opened = false;
	self.Maid:DoCleaning();
	self.WeaponHandler:MenuToggled("Settings", false);
	self.Opened = false;

	self.GuiContainer.Parent = game:GetService("ReplicatedStorage");

	workspace.CurrentCamera.CFrame = self.OpenedCameraCFrame;
end

function SettingsController:OpenSettings()
	self.OpenedCameraCFrame = workspace.CurrentCamera.CFrame;
	if (self.Opened) then return; end;
	self.WeaponHandler:MenuToggled("Settings", true);
	self.Gui3D:Toggle(true);
	self.Gui = self.Gui3D:GetGui();
	self:BuildGui();
	self.Opened = true;
	self.GuiContainer.Parent = workspace;
	self:Register();

	self.SaveAlert.Position = UDim2.new(0, 0, 1, 145);
	self.SettingsContainer.Parent.Size = UDim2.new(1, 0, 1, 0);
end

function SettingsController:Register()
	self.SettingsContainer = self.Gui:WaitForChild("Settings"):WaitForChild("Container"):WaitForChild("SettingsContainer");
	self.Storage = self.SettingsContainer:WaitForChild("Storage");
	self.SaveAlert = self.Gui:WaitForChild("Settings"):WaitForChild("SaveAlert");
end

function SettingsController:GetAttachedComponent(Child:Instance)
	for _, Component in ipairs(self.Components) do
		if (Component.Userdata and Component.Userdata.ComponentGui == Child) then
			return Component;
		end
	end
end

function SettingsController:ClearCurrentSettings()
	self.Maid:DoCleaning();

	for _, Child:Instance in ipairs(self.SettingsContainer:GetChildren()) do
		if (not Child:IsA("UIComponent") and not Child:IsA("Model")) then
			local Component = self.Components[Child];

			if (Component) then
				Component:Destroy();
				warn("Cleared setting component", Child.Name);
			else
				warn("Setting component not found", Child.Name);
			end

			Child:Destroy();
		end
	end

	table.clear(self.Components);
end

function SettingsController:SettingChanged()
	local Changed = 0;
	for _, SettingChanged in pairs(self.Changed) do
		Changed += SettingChanged and 1 or 0;
	end

	if (not self.SaveSettingsToggled) then
		self.DisplaySaveAlertUpTween = self.DisplaySaveAlertUpTween or TweenService:Create(
			self.SaveAlert, TweenInfo.new(.3, Enum.EasingStyle.Circular), {
				Position = UDim2.new(0, 0, 1, 0)
			}
		);
		self.ReduceSizeTween = self.ReduceSizeTween or TweenService:Create(
			self.SettingsContainer.Parent, TweenInfo.new(.3, Enum.EasingStyle.Circular), {
				Size = UDim2.new(1, 0, 1, -165)
			}
		);

		self.DisplaySaveAlertUpTween:Play();
		self.ReduceSizeTween:Play();

		self.SaveSettingsToggled = true;
	end

	self.SaveAlert:WaitForChild("PromptText").Text = string.format("You have %d unsaved setting%s, would you like to save %s?", Changed, Changed > 1 and "s" or "", Changed > 1 and "them" or "it");
end

function SettingsController:BuildGui()
	local Settings = self.Controllers.SettingsManager:GetSettings();

	self:Register();
	self:ClearCurrentSettings();

	local LayoutOrder = 0;

	local HoverTweenInfo = TweenInfo.new(.35, Enum.EasingStyle.Circular, Enum.EasingDirection.Out, 0, false, 0);

	self.Maid.SettingsClosed = self.Gui:WaitForChild("Settings"):WaitForChild("Container"):WaitForChild("TitleContainer"):WaitForChild("CloseButton").MouseButton1Click:Connect(function()
		if (not self.Opened) then return; end;
		self:Close();
	end)

	for SettingCategoryName:string, SettingCategory in pairs(Settings) do
		local SettingCategoryTitle = self.Storage:WaitForChild("SettingCategory"):Clone();

		SettingCategoryTitle.LayoutOrder = LayoutOrder;
		SettingCategoryTitle.Name = SettingCategoryName;
		SettingCategoryTitle.Parent = self.SettingsContainer;

		LayoutOrder += 1;

		local Line = self.Storage:WaitForChild("Line"):Clone();
		local BoundsX = SettingCategoryTitle.TextBounds.X;

		Line.LayoutOrder = LayoutOrder;
		
		Line.GraphicsLine.Size = UDim2.new(0, BoundsX, 0, 5);
		Line.GraphicsLine.GraphicsLine.Position = UDim2.fromOffset(BoundsX, 0);
		
		Line.Parent = self.SettingsContainer;
		LayoutOrder += 1;

		-- table.sort(SettingCategory, function(a, b)
		-- 	return a.Order > b.Order;
		-- end)

		for index, Setting in ipairs(SettingCategory) do
			local SettingName = Setting.Name;

			local Component = self.Modules.UIComponents[Setting.Type];
			local ComponentGui:GuiObject = self.Storage:FindFirstChild(Setting.Type);

			if (Component and ComponentGui) then
				ComponentGui = ComponentGui:Clone();
				ComponentGui.LayoutOrder = LayoutOrder;
				ComponentGui.Parent = self.SettingsContainer;

				local SettingComponent = Component.new(
					ComponentGui:WaitForChild("Container"),
					{ComponentGui = ComponentGui}, Setting, self.Storage
				);
				self.Components[ComponentGui] = SettingComponent;

				SettingComponent:SetValue(Setting.DefaultValue);
				if (self.ComponentMiddlewares[Setting.Type]) then
					self.ComponentMiddlewares[Setting.Type](SettingComponent.Value, SettingComponent.Userdata);
				end

				SettingComponent.Changed:Connect(function(...)
					self.Changed = self.Changed or {};

					self.Changed[SettingName] = true;
					self:SettingChanged();

					if (self.ComponentMiddlewares[Setting.Type]) then
						self.ComponentMiddlewares[Setting.Type](...);
					end
				end)

				self.Maid[SettingName.."Information"] = ComponentGui:WaitForChild("SettingName").MouseButton1Click:Connect(function()
					warn("Opened");

					if (not self.InformationOpen) then
						self.Gui3D:ClearCurrentWindow();
						self.InformationGui = self.Gui3D:SwitchWindows("Information");
					end

					local Info = self.InformationGui:WaitForChild("SettingInformation");
					local TitleContainer = Info:WaitForChild("TitleContainer");
					local Title = TitleContainer:WaitForChild("Title");

					Title.Text = SettingName;

					self.Maid.InformationClose = TitleContainer:WaitForChild("CloseButton").MouseButton1Up:Connect(function()
						self.Gui3D:ClearCurrentWindow();
						self.InformationOpen = false;
					end)

					Info:WaitForChild("Container"):WaitForChild("InformationText").Text = Setting.Description;
					self.InformationOpen = true;
				end)

				ComponentGui:WaitForChild("SettingName").Text = SettingName;

				do -- disgusting code
					self.Maid[SettingName..'1'] = TweenService:Create(
						ComponentGui,
						HoverTweenInfo, {
							BackgroundTransparency = .75
						}
					);
					self.Maid[SettingName..'2'] = TweenService:Create(
						ComponentGui:WaitForChild("UIStroke"),
						HoverTweenInfo, {
							Thickness = 4
						}
					);

					self.Maid[SettingName..'3'] = TweenService:Create(
						ComponentGui,
						HoverTweenInfo, {
							BackgroundTransparency = 1
						}
					);
					self.Maid[SettingName..'4'] = TweenService:Create(
						ComponentGui:WaitForChild("UIStroke"),
						HoverTweenInfo, {
							Thickness = 1
						}
					);

					self.Maid[SettingName.."Enter"] = ComponentGui.MouseEnter:Connect(function()
						self.Maid[SettingName..'1']:Play();
						self.Maid[SettingName..'2']:Play();

						self.Maid[SettingName..'3']:Pause();
						self.Maid[SettingName..'4']:Pause();
					end)

					self.Maid[SettingName.."Leave"] = ComponentGui.MouseLeave:Connect(function()
						self.Maid[SettingName..'3']:Play();
						self.Maid[SettingName..'4']:Play();
						
						self.Maid[SettingName..'1']:Pause();
						self.Maid[SettingName..'2']:Pause();
					end)
				end

				LayoutOrder += 1;
			else
				warn("Unknown setting component or setting component ui not found, for type: ".. Setting.Type);
			end
		end
	end
end

function SettingsController:Init()
	self.Gui3D = self.Modules.Gui3D;
end

return SettingsController