PLUGIN.Title = "Money For Gather"
PLUGIN.Version = V(0, 0, 1)
PLUGIN.Description = "Gain money through the economics API rather than resources"
PLUGIN.Author = "Mr. Bubbles AKA BlazR"
PLUGIN.Url = "None"
PLUGIN.ResourceId = 000
PLUGIN.HasConfig = true

local API = nil
local notified = "false"

-- Quotesafe function to help prevent unexpected output
local function QuoteSafe(string)
	return UnityEngine.StringExtensions.QuoteSafe(string)
end

function PLUGIN:Init()
	-- Load the default config and set the commands
	self:LoadDefaultConfig()
	command.AddChatCommand("setforwood", self.Object, "cmdSetAmount")
	command.AddChatCommand("setforores", self.Object, "cmdSetAmount")
	-- command.AddChatCommand("gather", self.Object, "cmdGather")
	command.AddChatCommand("m4gtoggle", self.Object, "cmdToggle")
end

function PLUGIN:OnServerIntialized()
	pluginsList = plugins.GetAll()
	for i = 0, tonumber(pluginsList.Length) - 1 do
		if pluginsList[i].Object.Title:match("Economics") then  
			API = GetEconomyAPI()
		end
	end
	if API == nil then
		print("Economics plugin not found. MoneyForGather plugin will not function!")
	end
end

function PLUGIN:LoadDefaultConfig()
	-- Set/load the default config options
	self.Config.Settings = self.Config.Settings or {
		ChatName = "MoneyForGather",
		PluginEnabled = "true",
		WoodAmount = "100",
		OreAmount = "100",
		-- GatherEnabled = "true",
		AuthLevel = "1"
	}
	-- Various messages used by the plugin
	self.Config.Messages = self.Config.Messages or {
		OreAmountChanged = "The ore amount has been changed to ",
		WoodAmountChanged = "The wood amount has been changed to ",
		NoPermission = "You do not have permission for that command.",
		PluginEnabled = "MoneyForGather has been enabled.",
		PluginDisabled = "MoneyForGather has been disabled.",
		ReceivedMoney = "You have received "
		-- GatherEnabled = "Gathering has been enabled.",
		-- GatherDisabled = "Gathering has been disabled."
	}
	self:SaveConfig()
end

function PLUGIN:OnGather(dispenser, player, item)
	if API ~= nil and self.Config.Settings.PluginEnabled == "true" then
		player = player:ToPlayer()
		if player then
			userdata = API:GetUserDataFromPlayer(player)
			if dispenser:GetComponentInParent(global.TreeEntity._type) then
				userdata:Deposit(tonumber(self.Config.Settings.WoodAmount))
				player:SendConsoleCommand("chat.add " .. QuoteSafe(self.Config.Settings.ChatName) .. " " .. QuoteSafe(self.Config.Messages.ReceivedMoney .. self.Config.Settings.WoodAmount))
			else
				userdata:Deposit(tonumber(self.Config.Settings.OreAmount))
				player:SendConsoleCommand("chat.add " .. QuoteSafe(self.Config.Settings.ChatName) .. " " .. QuoteSafe(self.Config.Messages.ReceivedMoney .. self.Config.Settings.OreAmount))
			end
		end
	elseif API == nil and notified == "false" then
		pluginsList = plugins.GetAll()
		for i = 0, tonumber(pluginsList.Length) - 1 do
			if pluginsList[i].Object.Title:match("Economics") then  
				API = GetEconomyAPI()
			end
		end
		if API == nil then
			print("Economics plugin not found. MoneyForGather plugin will not function!")
		end
		notified = "true"
	end
end

function PLUGIN:cmdSetAmount(player, cmd, args)
	if player.net.connection.authLevel >= tonumber(self.Config.Settings.AuthLevel) then
		if args then
			if cmd == "setforwood" then
				self.Config.Settings.WoodAmount = tostring(args[0])
				self:SaveConfig()
				player:SendConsoleCommand("chat.add " .. QuoteSafe(self.Config.Settings.ChatName) .. " " .. QuoteSafe(self.Config.Messages.WoodAmountChanged .. tostring(args[0])))
			else
				self.Config.Settings.OreAmount = tostring(args[0])
				self:SaveConfig()
				player:SendConsoleCommand("chat.add " .. QuoteSafe(self.Config.Settings.ChatName) .. " " .. QuoteSafe(self.Config.Messages.OreAmountChanged .. tostring(args[0])))
			end
		end
	else
		player:SendConsoleCommand("chat.add " .. QuoteSafe(self.Config.Settings.ChatName) .. " " .. QuoteSafe(self.Config.Messages.NoPermission))
	end
end

-- function PLUGIN:cmdGather(player, cmd, args)
	-- Add code to toggle config.Settings.GatherEnabled here
-- end

function PLUGIN:cmdToggle(player, cmd, args)
	if player.net.connection.authLevel >= tonumber(self.Config.Settings.AuthLevel) then
		if self.Config.Settings.Enabled == "true" then
			self.Config.Settings.Enabled = "false"
			self:SaveConfig()
			player:SendConsoleCommand("chat.add " .. QuoteSafe(self.Config.Settings.ChatName) .. " " .. QuoteSafe(self.Config.Messages.PluginDisabled))
		else
			self.Config.Settings.Enabled = "true"
			self:SaveConfig()
			player:SendConsoleCommand("chat.add " .. QuoteSafe(self.Config.Settings.ChatName) .. " " .. QuoteSafe(self.Config.Messages.PluginEnabled))
		end
	else
		player:SendConsoleCommand("chat.add " .. QuoteSafe(self.Config.Settings.ChatName) .. " " .. QuoteSafe(self.Config.Messages.NoPermission))
	end
end
