
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

-- CONFIG 
local CONFIG = {
	ImageId = "rbxassetid://101541915252383",

	Size = 88,
	Color = Color3.fromRGB(255, 255, 255),
	HoverColor = Color3.fromRGB(255, 184, 5),
	HoverScale = 1.3,
	ClickScale = 0.75,
	IdleSpin = 20,

	TrailEnabled = true,
	TrailCount = 5,

	RippleEnabled = true,
	RippleColor = Color3.fromRGB(255, 255, 255),
}
-- END OF CONFIG

if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "CustomCursor"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function makeCursorImage(name, transparency)
	local img = Instance.new("ImageLabel")
	img.Name = name
	img.BackgroundTransparency = 1
	img.Image = CONFIG.ImageId
	img.ImageColor3 = CONFIG.Color
	img.ImageTransparency = transparency or 0
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Size = UDim2.fromOffset(CONFIG.Size, CONFIG.Size)
	img.Active = false
	img.Parent = gui

	local scale = Instance.new("UIScale")
	scale.Parent = img
	return img, scale
end

local ghosts = {}
if CONFIG.TrailEnabled then
	for i = 1, CONFIG.TrailCount do
		local transparency = 0.45 + (i / CONFIG.TrailCount) * 0.5
		local img, scale = makeCursorImage("Ghost" .. i, transparency)
		img.ZIndex = 1
		scale.Scale = 1 - (i * 0.06)
		table.insert(ghosts, { img = img, pos = Vector2.new(), speed = 32 - i * 4 })
	end
end

local cursor, cursorScale = makeCursorImage("Cursor", 0)
cursor.ZIndex = 10

local hovering = false
local pressing = false
local spin = 0

local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local colorInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function updateState()
	local targetScale = 1
	if hovering then targetScale = CONFIG.HoverScale end
	if pressing then targetScale = targetScale * CONFIG.ClickScale end

	TweenService:Create(cursorScale, tweenInfo, { Scale = targetScale }):Play()
	TweenService:Create(cursor, colorInfo, {
		ImageColor3 = hovering and CONFIG.HoverColor or CONFIG.Color,
	}):Play()
end

local function spawnRipple(pos)
	if not CONFIG.RippleEnabled then return end

	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromOffset(pos.X, pos.Y)
	ring.Size = UDim2.fromOffset(10, 10)
	ring.BackgroundTransparency = 1
	ring.ZIndex = 5
	ring.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring

	local stroke = Instance.new("UIStroke")
	stroke.Color = CONFIG.RippleColor
	stroke.Thickness = 3
	stroke.Parent = ring

	local info = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, { Size = UDim2.fromOffset(CONFIG.Size * 1.8, CONFIG.Size * 1.8) }):Play()
	local fade = TweenService:Create(stroke, info, { Transparency = 1, Thickness = 0.5 })
	fade:Play()
	fade.Completed:Once(function()
		ring:Destroy()
	end)
end

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		pressing = true
		updateState()
		spawnRipple(UserInputService:GetMouseLocation())
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		pressing = false
		updateState()
	end
end)

local function isOverButton(mousePos)
	local inset = GuiService:GetGuiInset()
	local objects = playerGui:GetGuiObjectsAtPosition(mousePos.X - inset.X, mousePos.Y - inset.Y)
	for _, obj in ipairs(objects) do
		if obj:IsA("GuiButton") and not obj:IsDescendantOf(gui) and obj.Visible then
			return true
		end
	end
	return false
end

RunService.RenderStepped:Connect(function(dt)
	UserInputService.MouseIconEnabled = false

	local mousePos = UserInputService:GetMouseLocation()
	cursor.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)

	if CONFIG.IdleSpin ~= 0 then
		spin = (spin + CONFIG.IdleSpin * dt) % 360
		cursor.Rotation = spin
	end

	if CONFIG.TrailEnabled then
		for _, ghost in ipairs(ghosts) do
			local alpha = math.clamp(ghost.speed * dt, 0, 1)
			ghost.pos = ghost.pos:Lerp(mousePos, alpha)
			ghost.img.Position = UDim2.fromOffset(ghost.pos.X, ghost.pos.Y)
			ghost.img.Rotation = cursor.Rotation
		end
	end

	local over = isOverButton(mousePos)
	if over ~= hovering then
		hovering = over
		updateState()
	end
end)
