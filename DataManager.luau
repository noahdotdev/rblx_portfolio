local DataManager = {}
local DataStoreService = game:GetService("DataStoreService")
local dataStore = DataStoreService:GetDataStore("development-V0.1")
local Assets = require(game:GetService("ReplicatedStorage"):WaitForChild("modules"):WaitForChild("Assets"))

DataManager.DefaultFolders = {
	leaderstats = {
		Level = 1
	},
	stats = {
		shards = 0,
		gems = 0,
		xp = 0,
		needExp = 100,
		stamina = 100,
		maxStamina = 100,
		weapons = {},
		skills = {},
		class = "none",
		title = "Newbie",
		eclipsepass = 0,
		eclipsepassprem = false,
		backpack = Assets.Items,
		mounts = {},
		pets = {},
		skins = {},
		abilities = {},
		boats = {
			takenOut = false,
			Driftwood = false,
			Tidechaser = false,
			Stormpiercer = false,
			["Leviathan Runner"] = false,
			["Abyss Raider"] = false,
			["Ironfang Galleon"] = false,
			["Eclipse Dreadnought"] = false,
			["The Phantom Tide"] = false,
			["Celestial Voyager"] = false,
			["Nyxveil’s Embrace"] = false,
		},
		hasStarted = false
	},
	quests = {
		Wyatt = {
			["City intruders"] = false,
			["The Witch"] = false,
			["New Intruders"] = false,
			["The Leader"] = false,
			["Newly discovery"] = false,
			["What the..."] = false,
		}	
	},
}

function DataManager:SaveData(player)
	local playerData = {}

	for folderName, defaultStats in pairs(self.DefaultFolders) do
		local folder = player:FindFirstChild(folderName)
		if folder then
			playerData[folderName] = {}
			for statName, defaultValue in pairs(defaultStats) do
				local stat = folder:FindFirstChild(statName)
				if typeof(defaultValue) == "table" then
					playerData[folderName][statName] = {}
					for childName, childValue in pairs(defaultValue) do
						local childStat = stat and stat:FindFirstChild(childName)
						playerData[folderName][statName][childName] = childStat and childStat.Value or childValue
					end
				elseif stat then
					playerData[folderName][statName] = stat.Value
				end
			end
		end
	end

	local success, errorMessage = pcall(function()
		dataStore:SetAsync(player.UserId, playerData)
	end)

	if success then
		print("Data saved for player:", player.UserId)
	else
		warn("Failed to save data for player:", player.UserId, errorMessage)
	end
end

function DataManager:LoadData(player)
	local data = nil
	local success, errorMessage = pcall(function()
		data = dataStore:GetAsync(player.UserId)
	end)

	for folderName, defaultStats in pairs(self.DefaultFolders) do
		local folder = player:FindFirstChild(folderName) or Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = player

		if success and data and data[folderName] then
			for statName, defaultValue in pairs(defaultStats) do
				if typeof(defaultValue) == "table" then
					local subFolder = folder:FindFirstChild(statName) or Instance.new("Folder")
					subFolder.Name = statName
					subFolder.Parent = folder
					for childName, childValue in pairs(defaultValue) do
						local childStat = subFolder:FindFirstChild(childName) or Instance.new(typeof(childValue) == "boolean" and "BoolValue" or "IntValue")
						childStat.Name = childName
						childStat.Parent = subFolder
						childStat.Value = data[folderName][statName] and data[folderName][statName][childName] or childValue
					end
				else
					local stat = folder:FindFirstChild(statName) or Instance.new(typeof(defaultValue) == "boolean" and "BoolValue" or (typeof(defaultValue) == "string" and "StringValue" or "IntValue"))
					stat.Name = statName
					stat.Parent = folder
					stat.Value = data[folderName][statName] ~= nil and data[folderName][statName] or defaultValue
				end
			end
		else
			print("No data found for player in folder:", folderName, "or an error occurred:", errorMessage)
			for statName, defaultValue in pairs(defaultStats) do
				if typeof(defaultValue) == "table" then
					local subFolder = folder:FindFirstChild(statName) or Instance.new("Folder")
					subFolder.Name = statName
					subFolder.Parent = folder
					for childName, childValue in pairs(defaultValue) do
						local childStat = subFolder:FindFirstChild(childName) or Instance.new(typeof(childValue) == "boolean" and "BoolValue" or "IntValue")
						childStat.Name = childName
						childStat.Parent = subFolder
						childStat.Value = childValue
					end
				else
					local stat = folder:FindFirstChild(statName) or Instance.new(typeof(defaultValue) == "boolean" and "BoolValue" or (typeof(defaultValue) == "string" and "StringValue" or "IntValue"))
					stat.Name = statName
					stat.Parent = folder
					stat.Value = defaultValue
				end
			end
		end
	end
end

function DataManager:AddValue(player, folderName, valueName, defaultValue)
	local folder = player:FindFirstChild(folderName)
	if folder then
		local existingStat = folder:FindFirstChild(valueName)
		if not existingStat then
			local stat = Instance.new(typeof(defaultValue) == "boolean" and "BoolValue" or (typeof(defaultValue) == "string" and "StringValue" or "IntValue"))
			stat.Name = valueName
			stat.Parent = folder
			stat.Value = defaultValue
		end
	else
		print("Folder:", folderName, "not found for player.")
	end
end

function DataManager:SetValue(player, folderName, valueName, newValue, valueName2)
	print(valueName)
	print(newValue)
	print(folderName)
	local folder = player:FindFirstChild(folderName)
	if folder then
		local stat = folder:FindFirstChild(valueName)
		if valueName2 ~= nil then
			if stat then
				local stat2 = stat:FindFirstChild(valueName2)
				stat2.Value = newValue
			end
		else
			if valueName == "xp" then
				local getReqXp = player:FindFirstChild("stats"):FindFirstChild("needExp").Value
				print(getReqXp)

				if newValue >= getReqXp then
					stat.Value = 0
					local oldLevel = DataManager:GetValue(player, "leaderstats", "Level")
					DataManager:SetValue(player, "leaderstats", "Level", oldLevel + 1)

					local oldXpReq = DataManager:GetValue(player, "stats", "needExp")
					local newXpReq = math.floor(oldXpReq * 1.45)
					DataManager:SetValue(player, "stats", "needExp", newXpReq)

					stat.Value = newValue - getReqXp
				else
					stat.Value = newValue
				end
			else
				if stat then
					stat.Value = newValue
				end
			end
		end
	end
end

function DataManager:RemoveValue(player, folderName, valueName)
	local folder = player:FindFirstChild(folderName)
	if folder then
		local stat = folder:FindFirstChild(valueName)
		if stat then
			stat:Destroy()
		end
	end
end

function DataManager:AddItem(player, folderName, tableName, item)
	local folder = player:FindFirstChild(folderName)
	if folder then
		local tableFolder = folder:FindFirstChild(tableName)
		if tableFolder and tableFolder:IsA("Folder") then
			local itemValue = Instance.new("StringValue")
			itemValue.Name = tostring(#tableFolder:GetChildren() + 1)
			itemValue.Parent = tableFolder
			itemValue.Value = item
		end
	end
end

function DataManager:RemoveItem(player, folderName, tableName, itemName)
	local folder = player:FindFirstChild(folderName)
	if folder then
		local tableFolder = folder:FindFirstChild(tableName)
		if tableFolder and tableFolder:IsA("Folder") then
			local item = tableFolder:FindFirstChild(itemName)
			if item then
				item:Destroy()
			end
		end
	end
end

function DataManager:GetValue(player, folderName, valueName)
	local folder = player:FindFirstChild(folderName)
	if folder then
		local stat = folder:FindFirstChild(valueName)
		if stat then
			if stat:IsA("Folder") then
				local values = {}
				for _, child in ipairs(stat:GetChildren()) do
					if child:IsA("ValueBase") then
						values[child.Name] = child.Value
					end
				end
				return values
			else
				return stat.Value
			end
		end
	end
	return nil
end

return DataManager
