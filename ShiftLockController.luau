
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer

-- CONFIG

local CONFIG = {
	ToggleKey = Enum.KeyCode.LeftControl,

	ShoulderOffset = Vector3.new(1.75, 0.15, 0),

	CameraTweenTime = 0.25,
	RotationSpeed = 18,
	DashVelocityThreshold = 40,
}

-- END OF CONFIG

local ShiftLocked = false
local Character
local Humanoid
local Root

local CameraTween
local CameraOffsetDefault = Vector3.zero


local function SetupCharacter(character)
	Character = character
	Humanoid = character:WaitForChild("Humanoid")
	Root = character:WaitForChild("HumanoidRootPart")

	CameraOffsetDefault = Humanoid.CameraOffset
	
	ShiftLocked = false
	Humanoid.AutoRotate = true
	UIS.MouseBehavior = Enum.MouseBehavior.Default

end


local function SetCameraOffset(enabled)
	if not Humanoid then
		return
	end

	if CameraTween then
		CameraTween:Cancel()
		CameraTween = nil
	end

	local target = CameraOffsetDefault

	if enabled then
		target += CONFIG.ShoulderOffset
	end

	CameraTween = TweenService:Create(
		Humanoid,
		TweenInfo.new(
			CONFIG.CameraTweenTime,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			CameraOffset = target
		}
	)

	CameraTween:Play()
end


local function SetShiftLock(enabled)
	if not Humanoid or not Root then
		return
	end

	if Humanoid.Health <= 0 then
		return
	end

	ShiftLocked = enabled

	Humanoid.AutoRotate = not enabled

	if enabled then
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		UIS.MouseIconEnabled = false
	else
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
	end

	SetCameraOffset(enabled)
end
----------------

UIS.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == CONFIG.ToggleKey then
		SetShiftLock(not ShiftLocked)
	end
end)

local function UpdateCharacterRotation(dt)
	if not ShiftLocked then
		return
	end

	if not Humanoid or not Root then
		return
	end

	if Humanoid.Health <= 0 then
		return
	end

	local camera = workspace.CurrentCamera

	if not camera then
		return
	end

	UIS.MouseBehavior = Enum.MouseBehavior.LockCenter

	if Player:GetAttribute("IsDashing") == true then
		return
	end

	local velocity = Root.AssemblyLinearVelocity

	local horizontalSpeed = Vector3.new(
		velocity.X,
		0,
		velocity.Z
	).Magnitude

	if horizontalSpeed > CONFIG.DashVelocityThreshold then
		return
	end

	local look = camera.CFrame.LookVector

	local direction = Vector3.new(
		look.X,
		0,
		look.Z
	)

	if direction.Magnitude < 0.001 then
		return
	end

	direction = direction.Unit

	local target = CFrame.lookAt(
		Root.Position,
		Root.Position + direction
	)

	local alpha = 1 - math.exp(
		-CONFIG.RotationSpeed * dt
	)

	Root.CFrame = Root.CFrame:Lerp(target, alpha)
end


RunService:BindToRenderStep(
	"CursedSeasCustomShiftLock",
	Enum.RenderPriority.Camera.Value + 2,
	UpdateCharacterRotation
)

Player.CharacterAdded:Connect(SetupCharacter)

if Player.Character then
	task.spawn(SetupCharacter, Player.Character)
end

Player.CharacterRemoving:Connect(function()
	ShiftLocked = false

	UIS.MouseBehavior = Enum.MouseBehavior.Default
	UIS.MouseIconEnabled = true

	Character = nil
	Humanoid = nil
	Root = nil
end)
