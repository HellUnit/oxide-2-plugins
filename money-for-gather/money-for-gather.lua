PLUGIN.Title = "MoneyForGather"
PLUGIN.Version = V(1, 1, 0)
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
	command.AddChatCommand("setforcorpses", self.Object, "cmdSetAmount")
	-- command.AddChatCommand("gather", self.Object, "cmdGather")
	command.AddChatCommand("m4gtoggle", self.Object, "cmdToggle")
	command.AddChatCommand("m4gtogglechat", self.Object, "cmdToggleChat")
	command.AddChatCommand("m4gtogglewood", self.Object, "cmdToggleWood")
	command.AddChatCommand("m4gtoggleores", self.Object, "cmdToggleOres")
	command.AddChatCommand("m4gtogglecorpses", self.Object, "cmdToggleCorpses")
	command.AddChatCommand("m4ghelp", self.Object, "cmdHelp")
	command.AddConsoleCommand("m4g.setforwood", self.Object, "ccmdM4G")
	command.AddConsoleCommand("m4g.setforores", self.Object, "ccmdM4G")
	command.AddConsoleCommand("m4g.setforcorpses", self.Object, "ccmdM4G")
	command.AddConsoleCommand("m4g.toggle", self.Object, "ccmdM4G")
	command.AddConsoleCommand("m4g.togglechat", self.Object, "ccmdM4G")
	command.AddConsoleCommand("m4g.togglewood", self.Object, "ccmdM4G")
	command.AddConsoleCommand("m4g.toggleores", self.Object, "ccmdM4G")
	command.AddConsoleCommand("m4g.togglecorpses", self.Object, "ccmdM4G")
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
		ChatName = "[MoneyForGather]",
		PluginEnabled = "true",
		WoodAmount = "100",
		OreAmount = "100",
		CorpseAmount = "100",
		GatherMessagesEnabled = "true",
		-- GatherEnabled = "true",
		MoneyForWoodEnabled = "true",
		MoneyForOresEnabled = "true",
		MoneyForCorpsesEnabled = "false",
		AuthLevel = "1"
	}
	-- Various messages used by the plugin
	self.Config.Messages = self.Config.Messages or {
		AmountChanged = "The %s amount has been changed to %s",
		NoPermission = "You do not have permission for that command.",
		PluginStatusChanged = "MoneyForGather has been %s.",
		ReceivedMoney = "You have received %s for gathering %s.",
		GatherMessagesChanged = "MoneyForGather gather messages in chat have been %s.",
		MoneyOnGatherStateChanged = "Money for gathering %s has been %s.",
		HelpText = "Use /m4ghelp to get a list of MoneyForGather commands.",
		HelpText1 = "/setforwood <amount> - Sets the amount of money given for gathering wood",
		HelpText2 = "/setforores <amount> - Sets the amount of money given for gathering ores",
		HelpText3 = "/setforcorpses <amount> - Sets the amount of money given for gathering from corpses",
		HelpText4 = "/m4gtoggle - Toggles the MoneyForGather plugin on/off",
		HelpText5 = "/m4gtogglechat - Toggles the MoneyForGather gather messages in chat on/off",
		HelpText6 = "/m4gtogglewood - Toggles getting money for gathering wood on/off",
		HelpText7 = "/m4gtoggleores - Toggles getting money for gathering ores on/off",
		HelpText8 = "/m4gtogglecorpses - Toggles getting money for gathering corpses on/off"
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
			if dispenser:GetComponentInParent(global.TreeEntity._type) and self.Config.Settings.MoneyForWoodEnabled == "true" then
				userdata:Deposit(tonumber(self.Config.Settings.WoodAmount))
				if self.Config.Settings.GatherMessagesEnabled == "true" then
					self:SendMessage(player, self.Config.Messages.ReceivedMoney:format(self.Config.Settings.WoodAmount, item.info.displayname))
				end
			elseif item.info.displayname == "Metal Ore" or item.info.displayname == "Sulfur Ore" then
				if self.Config.Settings.MoneyForOresEnabled == "true" then
					userdata:Deposit(tonumber(self.Config.Settings.OreAmount))
					if self.Config.Settings.GatherMessagesEnabled == "true" then
						self:SendMessage(player, self.Config.Messages.ReceivedMoney:format(self.Config.Settings.OreAmount, item.info.displayname))
					end
				end
			elseif dispenser:ToString():match("corpse") and self.Config.Settings.MoneyForCorpsesEnabled == "true" then
				userdata:Deposit(tonumber(self.Config.Settings.CorpseAmount))
				if self.Config.Settings.GatherMessagesEnabled == "true" then
					self:SendMessage(player, self.Config.Messages.ReceivedMoney:format(self.Config.Settings.CorpseAmount, "from a corpse"))
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
		if args.Length == 1 then
			if cmd == "setforwood" then
				self.Config.Settings.WoodAmount = tostring(args[0])
				self:SaveConfig()
				self:SendMessage(player, self.Config.Messages.AmountChanged:format("Wood", tostring(args[0])))
			elseif cmd == "setforores" then
				self.Config.Settings.OreAmount = tostring(args[0])
				self:SaveConfig()
				self:SendMessage(player, self.Config.Messages.AmountChanged:format("Ores", tostring(args[0])))
			else
				self.Config.Settings.CorpseAmount = tostring(args[0])
				self:SaveConfig()
				self:SendMessage(player, self.Config.Messages.AmountChanged:format("corpses", tostring(args[0])))
			end
		else
			if cmd == "setforwood" then
				self:SendMessage(player, self.Config.Messages.HelpText1)
			elseif cmd == "setforores" then
				self:SendMessage(player, self.Config.Messages.HelpText2)
			else
				self:SendMessage(player, self.Config.Messages.HelpText3)
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
			self:SendMessage(player, self.Config.Messages.PluginStatusChanged:format("disabled"))
		else
			self.Config.Settings.PluginEnabled = "true"
			self:SaveConfig()
			self:SendMessage(player, self.Config.Messages.PluginStatusChanged:format("enabled"))
		end
	else
		self:SendMessage(player, self.Config.Messages.NoPermission)
	end
end

function PLUGIN:cmdToggleChat(player, cmd, args)
	if player.net.connection.authLevel >= tonumber(self.Config.Settings.AuthLevel) then
		if self.Config.Settings.GatherMessagesEnabled == "true" then
			self.Config.Settings.GatherMessagesEnabled = "false"
			self:SaveConfig()
			self:SendMessage(player, self.Config.Messages.GatherMessagesChanged:format("disabled"))
		else
			self.Config.Settings.GatherMessagesEnabled = "true"
			self:SaveConfig()
			self:SendMessage(player, self.Config.Messages.GatherMessagesChanged:format("enabled"))
		end
	else
		self:SendMessage(player, self.Config.Messages.NoPermission)
	end
end

function PLUGIN:cmdToggleWood(player, cmd, args)
	if player.net.connection.authLevel >= tonumber(self.Config.Settings.AuthLevel) then
		if self.Config.Settings.MoneyForWoodEnabled == "true" then
			self.Config.Settings.MoneyForWoodEnabled = "false"
			self:SaveConfig()
			self:SendMessage(player, self.Config.Messages.MoneyOnGatherStateChanged:format("Wood", "disabled"))
		else
			self.Config.Settings.MoneyForWoodEnabled = "true"
			self:SaveConfig()
			self:SendMessage(player, self.Config.Messages.MoneyOnGatherStateChanged:format("Wood", "enabled"))
		end
	else
		self:SendMessage(player, self.Config.Messages.NoPermission)
	end
end

function PLUGIN:cmdToggleOres(player, cmd, args)
	if player.net.connection.authLevel >= tonumber(self.Config.Settings.AuthLevel) then
		if self.Config.Settings.MoneyForOresEnabled == "true" then
			self.Config.Settings.MoneyForOresEnabled = "false"
			self:SaveConfig()
			self:SendMessage(player, self.Config.Messages.MoneyOnGatherStateChanged:format("Ore", "disabled"))
		else
			self.Config.Settings.MoneyForOresEnabled = "true"
			self:SaveConfig()
			self:SendMessage(player, self.Config.Messages.MoneyOnGatherStateChanged:format("Ore", "enabled"))
		end
	else
		self:SendMessage(player, self.Config.Messages.NoPermission)
	end
end

function PLUGIN:cmdToggleCorpses(player, cmd, args)
	if player.net.connection.authLevel >= tonumber(self.Config.Settings.AuthLevel) then
		if self.Config.Settings.MoneyForCorpsesEnabled == "true" then
			self.Config.Settings.MoneyForCorpsesEnabled = "false"
			self:SaveConfig()
			self:SendMessage(player, self.Config.Messages.MoneyOnGatherStateChanged:format("corpses", "disabled"))
		else
			self.Config.Settings.MoneyForCorpsesEnabled = "true"
			self:SaveConfig()
			self:SendMessage(player, self.Config.Messages.MoneyOnGatherStateChanged:format("corpses", "enabled"))
		end
	else
		self:SendMessage(player, self.Config.Messages.NoPermission)
	end
end

function PLUGIN:cmdHelp(player, cmd, args)
	if player.net.connection.authLevel >= tonumber(self.Config.Settings.AuthLevel) then
		self:SendMessage(player, self.Config.Messages.HelpText1)
		self:SendMessage(player, self.Config.Messages.HelpText2)
		self:SendMessage(player, self.Config.Messages.HelpText3)
		self:SendMessage(player, self.Config.Messages.HelpText4)
		self:SendMessage(player, self.Config.Messages.HelpText5)
		self:SendMessage(player, self.Config.Messages.HelpText6)
		self:SendMessage(player, self.Config.Messages.HelpText7)
		self:SendMessage(player, self.Config.Messages.HelpText8)
	else
		self:SendMessage(player, self.Config.Messages.NoPermission)
	end
end

function PLUGIN:ccmdM4G(arg)
	command = arg.cmd.namefull
	if command == "m4g.setforwood" then
		if not arg.Args or arg.Args.Length ~= 1 then
			arg:ReplyWith("You must specify an amount. 'm4g.setforwood <amount>'")
		elseif arg.Args[0] then
			self.Config.Settings.WoodAmount = tostring(arg.Args[0])
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.AmountChanged:format("Wood", tostring(arg.Args[0])))
		end
	elseif command == "m4g.setforores" then
		if not arg.Args or arg.Args.Length ~= 1 then
			arg:ReplyWith("You must specify an amount. 'm4g.setforores <amount>'")
		elseif arg.Args[0] then
			self.Config.Settings.OreAmount = tostring(arg.Args[0])
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.AmountChanged:format("Ores", tostring(arg.Args[0])))
		end
	elseif command == "m4g.setforcorpses" then
		if not arg.Args or arg.Args.Length ~= 1 then
			arg:ReplyWith("You must specify an amount. 'm4g.setforcorpses <amount>'")
		elseif arg.Args[0] then
			self.Config.Settings.CorpseAmount = tostring(arg.Args[0])
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.AmountChanged:format("corpses", tostring(arg.Args[0])))
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
	elseif command == "m4g.togglechat" then
		if self.Config.Settings.GatherMessagesEnabled == "true" then
			self.Config.Settings.GatherMessagesEnabled = "false"
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.GatherMessagesChanged:format("disabled"))
		else
			self.Config.Settings.GatherMessagesEnabled= "true"
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.GatherMessagesChanged:format("enabled"))
		end
	elseif command == "m4g.togglewood" then
		if self.Config.Settings.MoneyForWoodEnabled == "true" then
			self.Config.Settings.MoneyForWoodEnabled = "false"
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.MoneyOnGatherStateChanged:format("Wood", "disabled"))
		else
			self.Config.Settings.MoneyForWoodEnabled = "true"
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.MoneyOnGatherStateChanged:format("Wood", "enabled"))
		end
	elseif command == "m4g.toggleores" then
		if self.Config.Settings.MoneyForOresEnabled == "true" then
			self.Config.Settings.MoneyForOresEnabled = "false"
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.MoneyOnGatherStateChanged:format("Ores", "disabled"))
		else
			self.Config.Settings.MoneyForOresEnabled = "true"
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.MoneyOnGatherStateChanged:format("Ores", "enabled"))
		end
	elseif command == "m4g.togglecorpses" then
		if self.Config.Settings.MoneyForCorpsesEnabled == "true" then
			self.Config.Settings.MoneyForCorpsesEnabled = "false"
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.MoneyOnGatherStateChanged:format("corpses", "disabled"))
		else
			self.Config.Settings.MoneyForCorpsesEnabled = "true"
			self:SaveConfig()
			arg:ReplyWith(self.Config.Messages.MoneyOnGatherStateChanged:format("corpses", "enabled"))
		end
	end
	return
end

function PLUGIN:SendHelpText(player)
	if player.net.connection.authLevel >= tonumber(self.Config.Settings.AuthLevel) then
		self:SendMessage(player, self.Config.Messages.HelpText)
	end
end

function PLUGIN:SendMessage(player, message)
	player:SendConsoleCommand("chat.add " .. QuoteSafe(self.Config.Settings.ChatName) .. " " .. QuoteSafe(message))
end
