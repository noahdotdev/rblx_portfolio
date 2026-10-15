local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

local IntroGuy = game.Workspace.NPC.Spawn.IntroGuy
local playerGui = player:WaitForChild("PlayerGui")

local speakLabel = playerGui:WaitForChild("Interact"):WaitForChild("safezone"):WaitForChild("label")

local talkingWithNpc = false
local option1Connection, option2Connection, option3Connection

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SetValueEvent = ReplicatedStorage:WaitForChild("events"):WaitForChild("functions"):WaitForChild("SetValue")

local Assets = require(ReplicatedStorage:WaitForChild("modules"):WaitForChild("Assets"))

-- OPTION GUI

local InteractiveGui = playerGui:WaitForChild("InteractiveSelect")
local namePart = InteractiveGui:WaitForChild("safezone").TextLabel
local option1 = InteractiveGui:WaitForChild("safezone").option1
local option2 = InteractiveGui:WaitForChild("safezone").option2
local option3 = InteractiveGui:WaitForChild("safezone").option3

local hud = playerGui:WaitForChild("hud"):WaitForChild("safezone")
local errorLabel = hud:WaitForChild("errorMsg")

local questGui = hud:WaitForChild("QuestGui")

-- WALLS
local Nyxveil = game.Workspace.Map.Nyxveil

-- DUSKWATCH
local Duskwatch = game.Workspace:WaitForChild("Map"):WaitForChild("Duskwatch")
local DuskwatchNPC = Duskwatch:WaitForChild("NPC")
local BoatShopDUSKWATCH = DuskwatchNPC.BoatShop
local FruitShopDUSKWATCH = DuskwatchNPC.FruitShop
local CookTier1DUSKWATCH = DuskwatchNPC.CookTier1
local QuestDUSKWATCH = DuskwatchNPC.QuestNPC

-- QUESTS
local questComp = game:GetService("ReplicatedStorage"):WaitForChild("VFX"):WaitForChild("questCompleted")
local questStart = game:GetService("ReplicatedStorage"):WaitForChild("VFX"):WaitForChild("questStart")
local questLock = game:GetService("ReplicatedStorage"):WaitForChild("VFX"):WaitForChild("questLocked")

local function formatNumber(num)
	if num >= 1_000_000 then
		return string.format("%.2fM", num / 1_000_000)
	elseif num >= 1_000 then
		local int, fraction = math.modf(num / 1_000)
		return string.format("%s,%03d", int, num % 1_000)
	else
		return tostring(num)
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


-- CREATE QUESTS
local function clearQuests()
	for _, child in ipairs(questGui.scroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

function createQuests(guy)
	clearQuests()

	local quests = Assets.Quests[guy]
	local orderedQuests = {}

	for queName, que in pairs(quests) do
		table.insert(orderedQuests, {name = queName, data = que})
	end

	table.sort(orderedQuests, function(a, b)
		return a.data.level < b.data.level
	end)

	for _, quest in ipairs(orderedQuests) do
		local queName = quest.name
		local questDate = quest.data

		local boatHud = (player:WaitForChild("quests")
			:WaitForChild(guy)
			:WaitForChild(queName).Value == true and questComp or player:WaitForChild("leaderstats")
			:WaitForChild("Level").Value >= questDate.level and questStart or questLock):Clone()

		local questStat = player:WaitForChild("quests")
			:WaitForChild(guy)
			:WaitForChild(queName).Value == true and questComp or player:WaitForChild("leaderstats")
			:WaitForChild("Level").Value >= questDate.level and questStart or questLock

		boatHud.desc.Text = questDate.desc
		boatHud.label.Text = queName
		boatHud.req.Text = " Requirement: Level " .. questDate.level
		boatHud.reward.Text = " Reward: " .. formatNumber(questDate.rew) .. " S$"
		boatHud.Visible = true
		boatHud.Parent = questGui.scroll
		
		if questStat == questStart then
			boatHud.btnFrame.TextButton.MouseButton1Click:Connect(function()
				--questEvent:FireServer("start", boatHud.Name)
			end)
		elseif questStat == questLock then
			boatHud.btnFrame.TextButton.MouseButton1Click:Connect(function()
				errorLabel.TextTransparency = 0
				errorLabel.Visible = true
				errorLabel.Text = "This quest is currently locked!"
				task.wait(3)
				turnTrans(errorLabel)
				errorLabel.Visible = false
			end)
		end
	end
end

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

local function talkingwithnpcErr()
	if talkingWithNpc then
		errorLabel.TextTransparency = 0
		errorLabel.Visible = true
		errorLabel.Text = "You are already talking with an NPC!"
		task.wait(3)
		turnTrans(errorLabel)
		errorLabel.Visible = false
		return true
	else
		return false
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

-- INTRO GUY

IntroGuy.ClickDetector.MouseHoverEnter:Connect(function()
	IntroGuy.Highlight.Enabled = true
	speakLabel.Text = "Talk with ???"
	speakLabel.Visible = true
end)

IntroGuy.ClickDetector.MouseHoverLeave:Connect(function()
	IntroGuy.Highlight.Enabled = false
	speakLabel.Visible = false
end)

IntroGuy.ClickDetector.MouseClick:Connect(function()
	if talkingwithnpcErr() then return end
	talkingWithNpc = true
	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	humanoidRootPart.Anchored = true
	
	print("Clicked NPC")
	local targetMsg = IntroGuy.Head:WaitForChild("responsive"):WaitForChild("msg")
	typeMessage(targetMsg, "What can i help you with?...")
	openInteract(
		"???", 
		"Who are you?", 
		"What is this place?", 
		"Bye..", 
		function() 
			task.spawn(function()
				multiTurnTrans(namePart, option1, option2, option3)
				InteractiveGui.Enabled = false
			end)
			humanoidRootPart.Anchored = false
			typeMessage(targetMsg, "I have no name, yet i exist..")
			task.wait(5)
			turnTrans(targetMsg)
			talkingWithNpc = false
			return
		end, 
		
		function()
			task.spawn(function()
				multiTurnTrans(namePart, option1, option2, option3)
				InteractiveGui.Enabled = false
			end)
			typeMessage(targetMsg, "We are no where but inbetween, not in light, not in the shadow.")
			task.wait(2)
			turnTrans(targetMsg)
			typeMessage(targetMsg, "We are where it all started, the Nyxveil.")
			task.wait(2)
			turnTrans(targetMsg)
			typeMessage(targetMsg, "It's time for u to come back my hero, they have waited for too long.")
			task.wait(2)
			turnTrans(targetMsg)
			openInteract("???", "Hero?", nil, nil,
				function()
					task.spawn(function()
						multiTurnTrans(namePart, option1, nil, nil)
						InteractiveGui.Enabled = false
					end)
					typeMessage(targetMsg, "You must walk forward for said answer...")
					task.wait(5)
					turnTrans(targetMsg)
					task.spawn(function()
						multiTurnTrans(namePart, option1, nil, nil)
						InteractiveGui.Enabled = false
					end)
					humanoidRootPart.Anchored = false
					Nyxveil.walls.enabled.first.CanCollide = false
					Nyxveil.walls.enabled.first.Parent = Nyxveil.walls.disabled
					Nyxveil.walls.disabled.way.Transparency = 0
					Nyxveil.walls.disabled.way.Parent = Nyxveil.walls.enabled
					talkingWithNpc = false
					SetValueEvent:FireServer("stats", "hasStarted", true)
				end, nil, nil
			)
			return
		end,
		
		function()
			task.spawn(function()
				multiTurnTrans(namePart, option1, option2, option3)
				InteractiveGui.Enabled = false
			end)
			humanoidRootPart.Anchored = false
			typeMessage(targetMsg, "Bye...")
			task.wait(5)
			turnTrans(targetMsg)
			talkingWithNpc = false
			return
		end
	)
end)

-- DUSKWATCH NPC'S

BoatShopDUSKWATCH.ClickDetector.MouseHoverEnter:Connect(function()
	BoatShopDUSKWATCH.Highlight.Enabled = true
	speakLabel.Text = "Talk with Karl"
	speakLabel.Visible = true
end)

BoatShopDUSKWATCH.ClickDetector.MouseHoverLeave:Connect(function()
	BoatShopDUSKWATCH.Highlight.Enabled = false
	speakLabel.Visible = false
end)

BoatShopDUSKWATCH.ClickDetector.MouseClick:Connect(function()
	if talkingwithnpcErr() then return end
	talkingWithNpc = true
	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	humanoidRootPart.Anchored = true

	print("Clicked NPC")
	local targetMsg = BoatShopDUSKWATCH.Head:WaitForChild("responsive"):WaitForChild("msg")
	typeMessage(targetMsg, "How'd are you my friend?!")
	openInteract(
		"Karl - Boat Shop", 
		"I'd like to open the shop", 
		"Bye..", 
		nil,
		function() 
			task.spawn(function()
				multiTurnTrans(namePart, option1, option2, option3)
				InteractiveGui.Enabled = false
			end)
			humanoidRootPart.Anchored = false
			typeMessage(targetMsg, "Alrighty, have fun!")
			playerGui:WaitForChild("hud"):WaitForChild("safezone"):WaitForChild("BoatShop").Visible = true
			local player = game.Players.LocalPlayer
			local character = player.Character or player.CharacterAdded:Wait()
			local rootPart = character:WaitForChild("HumanoidRootPart")
			rootPart.Anchored = true
			task.wait(5)
			turnTrans(targetMsg)
			talkingWithNpc = false
			return
		end, 

		function()
			task.spawn(function()
				multiTurnTrans(namePart, option1, option2, option3)
				InteractiveGui.Enabled = false
			end)
			typeMessage(targetMsg, "Bye, have fun!")
			task.wait(2)
			turnTrans(targetMsg)
			talkingWithNpc = false
			humanoidRootPart.Anchored = false
			return
		end,

		nil
	)
end)



FruitShopDUSKWATCH.ClickDetector.MouseHoverEnter:Connect(function()
	FruitShopDUSKWATCH.Highlight.Enabled = true
	speakLabel.Text = "Talk with Lisa"
	speakLabel.Visible = true
end)

FruitShopDUSKWATCH.ClickDetector.MouseHoverLeave:Connect(function()
	FruitShopDUSKWATCH.Highlight.Enabled = false
	speakLabel.Visible = false
end)

CookTier1DUSKWATCH.ClickDetector.MouseHoverEnter:Connect(function()
	CookTier1DUSKWATCH.Highlight.Enabled = true
	speakLabel.Text = "Talk with Jason"
	speakLabel.Visible = true
end)

CookTier1DUSKWATCH.ClickDetector.MouseHoverLeave:Connect(function()
	CookTier1DUSKWATCH.Highlight.Enabled = false
	speakLabel.Visible = false
end)

QuestDUSKWATCH.ClickDetector.MouseHoverEnter:Connect(function()
	QuestDUSKWATCH.Highlight.Enabled = true
	speakLabel.Text = "Talk with Wyatt"
	speakLabel.Visible = true
end)

QuestDUSKWATCH.ClickDetector.MouseHoverLeave:Connect(function()
	QuestDUSKWATCH.Highlight.Enabled = false
	speakLabel.Visible = false
end)

QuestDUSKWATCH.ClickDetector.MouseClick:Connect(function()
	if talkingwithnpcErr() then return end
	talkingWithNpc = true
	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	humanoidRootPart.Anchored = true

	print("Clicked NPC")
	local targetMsg = QuestDUSKWATCH.Head:WaitForChild("responsive"):WaitForChild("msg")
	typeMessage(targetMsg, "Hello..")
	openInteract(
		"Wyatt - Quests", 
		"Im ready!", 
		"Bye..", 
		nil,
		function() 
			task.spawn(function()
				multiTurnTrans(namePart, option1, option2, nil)
				InteractiveGui.Enabled = false
			end)
			humanoidRootPart.Anchored = false
			createQuests("Wyatt")
			typeMessage(targetMsg, "Thank you so much!")
			local player = game.Players.LocalPlayer
			local character = player.Character or player.CharacterAdded:Wait()
			local rootPart = character:WaitForChild("HumanoidRootPart")
			rootPart.Anchored = true
			questGui.Visible = true
			task.wait(5)
			turnTrans(targetMsg)
			talkingWithNpc = false
			return
		end, 

		function()
			task.spawn(function()
				multiTurnTrans(namePart, option1, option2, nil)
				InteractiveGui.Enabled = false
			end)
			typeMessage(targetMsg, "Oh.. Bye!")
			task.wait(2)
			turnTrans(targetMsg)
			talkingWithNpc = false
			humanoidRootPart.Anchored = false
			return
		end,

		nil
	)
end)

game:GetService("RunService").Heartbeat:Connect(function()
	if speakLabel.Visible then
		local mousePos = mouse.Hit.p
		local screenPos = game.Workspace.CurrentCamera:WorldToScreenPoint(mousePos)
		speakLabel.Position = UDim2.new(0, screenPos.X + 7, 0.05, screenPos.Y)
	end
end)
