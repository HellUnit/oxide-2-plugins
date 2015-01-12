PLUGIN.Title = "MoneyForGather"
PLUGIN.Version = V(0, 0, 3)
PLUGIN.Description = "Gain money through the Economics API for gathering"
PLUGIN.Author = "Mr. Bubbles AKA BlazR"
PLUGIN.Url = "http://forum.rustoxide.com/plugins/money-for-gather.770/"
PLUGIN.ResourceId = 770
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
	command.AddConsoleCommand("m4g.setforwood", self.Object, "ccmdM4G")
	command.AddConsoleCommand("m4g.setforores", self.Object, "ccmdM4G")
	command.AddConsoleCommand("m4g.toggle", self.Object, "ccmdM4G")
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
		GatherMessagesEnabled = "true",
		-- GatherEnabled = "true",
		AuthLevel = "1"
	}
	-- Various messages used by the plugin
	self.Config.Messages = self.Config.Messages or {
		OreAmountChanged = "The ore amount has been changed to %s",
		WoodAmountChanged = "The wood amount has been changed to %s",
		NoPermission = "You do not have permission for that command.",
		PluginEnabled = "MoneyForGather has been enabled.",
		PluginDisabled = "MoneyForGather has been disabled.",
		ReceivedMoney = "You have received %s for gathering %s.",
		HelpText1 = "/setforwood <amount> - Sets the amount of money given for gathering wood",
		HelpText2 = "/setforores <amount> - Sets the amount of money given for gathering ores",
		HelpText3 = "/m4gtoggle - Toggles the MoneyForGather plugin on and off"
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
				if self.Config.Settings.GatherMessagesEnabled == "true" then
					self:SendMessage(player, self.Config.Messages.ReceivedMoney:format(self.Config.Settings.WoodAmount, item.info.displayname))
				end
			elseif item.info.displayname == "Metal Ore" or item.info.displayname == "Sulfur Ore" then
				userdata:Deposit(tonumber(self.Config.Settings.OreAmount))
				if self.Config.Settings.GatherMessagesEnabled == "true" then
					self:SendMessage(player, self.Config.Messages.ReceivedMoney:format(self.Config.Settings.OreAmount, item.info.displayname))
				end
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
			notified = "true"
		end
	end
end

function PLUGIN:cmdSetAmount(player, cmd, args)
	if player.net.connection.authLevel >= tonumber(self.Config.Settings.AuthLevel) then
		if args then
			if cmd == "setforwood" then
				self.Config.Settings.WoodAmount = tostring(args[0])
				self:SaveConfig()
				self:SendMessage(player, self.Config.Messages.WoodAmountChanged:format(tostring(args[0])))
			else
				self.Config.Settings.OreAmount = tostring(args[0])
				self:SaveConfig()
				self:SendMessage(player, self.Config.Messages.OreAmountChanged:format(tostring(args[0])))
			end
		end
	else
		self:SendMessage(player, self.Config.Messages.NoPermission)
	end
end

-- function PLUGIN:cmdGather(player, cmd, args)
	-- Add code to toggle config.Settings.GatherEnabled here
-- end

function PLUGIN:cmdToggle(player, cmd, args)
	if player.net.connection.authLevel >= tonumber(self.Config.Settings.AuthLevel) then
		if self.Config.Settings.PluginEnabled == "true" then
			self.Config.Settings.PluginEnabled = "false"
			self:SaveConfig()
			self:SendMessage(player, self.Config.Messages.PluginDisabled)
		else
			self.Config.Settings.PluginEnabled = "true"
			self:SaveConfig()
			self:SendMessage(player, self.Config.Messages.PluginEnabled)
		end
	else
		self:SendMessage(player, self.Config.Messages.NoPermission))
	end
end

function PLUGIN:ccmdM4G(arg)
	command = arg.cmd.namefull
	if command == "m4g.setforwood" then
		if not arg.Args or arg.Args.Length == 0 then
			arg:ReplyWith("You must specify an amount. 'm4g.setforwood <amount>'")
		elseif arg.Args[0] then
			self.Config.Settings.WoodAmount = tostring(arg.Args[0])
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.WoodAmountChanged:format(tostring(arg.Args[0])))
		end
	elseif command == "m4g.setforores" then
		if not arg.Args or arg.Args.Length == 0 then
			arg:ReplyWith("You must specify an amount. 'm4g.setforores <amount>'")
		elseif arg.Args[0] then
			self.Config.Settings.OreAmount = tostring(arg.Args[0])
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.OreAmountChanged:format(tostring(arg.Args[0])))
		end
	elseif command == "m4g.toggle" then
		if self.Config.Settings.PluginEnabled == "true" then
			self.Config.Settings.PluginEnabled = "false"
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.PluginDisabled)
		else
			self.Config.Settings.PluginEnabled = "true"
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.PluginEnabled)
		end
	end
	return
end

function PLUGIN:SendHelpText(player)
	if player.net.connection.authLevel >= tonumber(self.Config.Settings.AuthLevel) then
		self:SendMessage(player, self.Config.Messages.HelpText1)
		self:SendMessage(player, self.Config.Messages.HelpText2)
		self:SendMessage(player, self.Config.Messages.HelpText3)
	end
end

function PLUGIN:SendMessage(player, message)
	player:SendConsoleCommand("chat.add " .. QuoteSafe(self.Config.Settings.ChatName) .. " " .. QuoteSafe(message))
end
