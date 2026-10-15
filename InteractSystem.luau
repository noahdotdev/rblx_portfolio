local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local Nyxveil = game.Workspace.Map.Nyxveil

local interactingWith = false
local option1Connection, option2Connection, option3Connection

local playerGui = player:WaitForChild("PlayerGui")
local hud = playerGui:WaitForChild("hud"):WaitForChild("safezone")
local errorLabel = hud:WaitForChild("errorMsg")
local speakLabel = playerGui:WaitForChild("Interact"):WaitForChild("safezone"):WaitForChild("label")

local InteractiveGui = playerGui:WaitForChild("InteractiveSelect")
local namePart = InteractiveGui:WaitForChild("safezone").TextLabel
local option1 = InteractiveGui:WaitForChild("safezone").option1
local option2 = InteractiveGui:WaitForChild("safezone").option2
local option3 = InteractiveGui:WaitForChild("safezone").option3

local responsHdrTemp = game.ReplicatedStorage:WaitForChild("VFX"):WaitForChild("responsiveHeader")

-- NYXVEIL INTERACTION
local NyxveilInteract = {}
NyxveilInteract.Campfire = Nyxveil:WaitForChild("parts"):WaitForChild("Campfire"):WaitForChild("Campfire")

-- FUNCS

local function typeMessage(targetTextLabel, message)
	local currentText = ""
	targetTextLabel.TextTransparency = 0
	for i = 1, #message do
		currentText = currentText .. message:sub(i, i)
		targetTextLabel.Text = currentText
		task.wait(0.05) 
	end
end

local function turnTrans(targetTextLabel)
	local newTrans = 0
	for i = 1, 11 do
		targetTextLabel.TextTransparency = newTrans
		newTrans = newTrans + 0.1
		task.wait(0.05)
	end
end

local function InteractError()
	if interactingWith then
		errorLabel.Visible = true
		errorLabel.Text = "You are already interaing with a object!"
		task.wait(3)
		turnTrans(errorLabel)
		errorLabel.Visible = false
		return 
	end
end

local function multiTurnTrans(target1, target2, target3, target4)
	local newTrans = 0
	for i = 1, 11 do
		if target1 ~= nil then
			target1.TextTransparency = newTrans
			if target1:FindFirstChild("dot") then
				target1.dot.ImageTransparency = newTrans
			end
		end
		if target2 ~= nil then
			target2.TextTransparency = newTrans
			if target2:FindFirstChild("dot") then
				target2.dot.ImageTransparency = newTrans
			end
		end
		if target3 ~= nil then
			target3.TextTransparency = newTrans
			if target3:FindFirstChild("dot") then
				target3.dot.ImageTransparency = newTrans
			end
		end
		if target4 ~= nil then
			target4.TextTransparency = newTrans
			if target4:FindFirstChild("dot") then
				target4.dot.ImageTransparency = newTrans
			end
		end
		newTrans = newTrans + 0.1
		task.wait(0.02)
	end
end

local function errUsing()
	if interactingWith then
		errorLabel.Visible = true
		errorLabel.Text = "You are already talking with an NPC!"
		task.wait(3)
		turnTrans(errorLabel)
		errorLabel.Visible = false
		return 
	end
end

local function openInteract(name, option1Txt, option2Txt, option3Txt, opt1Result, opt2Result, opt3Result)
	if option1Connection then option1Connection:Disconnect() end
	if option2Connection then option2Connection:Disconnect() end
	if option3Connection then option3Connection:Disconnect() end

	namePart.Text = name
	namePart.Visible = true
	namePart.TextTransparency = 0

	if option1Txt then
		option1.Text = option1Txt
		option1.TextTransparency = 0
		option1.Visible = true
		option1Connection = option1.MouseButton1Click:Connect(opt1Result)
		if option1:FindFirstChild("dot") then
			option1.dot.ImageTransparency = 0
		end
	end

	if option2Txt then
		option2.Text = option2Txt
		option2.TextTransparency = 0
		option2.Visible = true
		option2Connection = option2.MouseButton1Click:Connect(opt2Result)
		if option2:FindFirstChild("dot") then
			option2.dot.ImageTransparency = 0
		end
	end

	if option3Txt then
		option3.Text = option3Txt
		option3.TextTransparency = 0
		option3.Visible = true
		option3Connection = option3.MouseButton1Click:Connect(opt3Result)
		if option3:FindFirstChild("dot") then
			option3.dot.ImageTransparency = 0
		end
	end

	InteractiveGui.Enabled = true
end
