PLUGIN.Title = "Trivia Core"
PLUGIN.Version = V(0, 0, 1)
PLUGIN.Description = "Trivia game that asks specified questions at the specified interval"
PLUGIN.Author = "Mr. Bubbles AKA BlazR with a ton of help from Mughisi"
PLUGIN.Url = "None"
PLUGIN.ResourceId = 000
PLUGIN.HasConfig = true

local currentAnswer = nil
local answered = "true"
local questionNumber = nil
local repeats = nil
local totalNumberOfQuestions = 0
local totalNumberOfCategories = 0

-- Quotesafe function to help prevent unexpected output
local function QuoteSafe(string)
	return UnityEngine.StringExtensions.QuoteSafe(string)
end

function PLUGIN:Init()
	-- Load the default config and set the commands
	self:LoadDefaultConfig()
	command.AddChatCommand("triviatoggle", self.Object, "cmdToggleTrivia")
	command.AddChatCommand("answer", self.Object, "cmdAnswerQuestion")
	command.AddChatCommand("triviacategories", self.Object, "cmdCategories")
end

function PLUGIN:OnServerInitialized()
	-- Get a list of all loaded plugins
	local pluginsList = plugins.GetAll()
	-- DEBUG: List the number of loaded plugins
	print("Number of plugins: ".. tostring(pluginsList.Length))
	-- DEBUG: Print the names of all loaded plugins
	for i = 0, tonumber(pluginsList.Length) - 1 do
		print(tostring(pluginsList[i].Object.Title))
	end
	-- Load the questions from the trivia extension plugins
	TriviaQuestions = {}
	for i = 0, tonumber(pluginsList.Length) - 1 do
		if pluginsList[i].Object.Title:match("Trivia Questions") then  
			local category = pluginsList[i].Object.Title:gsub("Trivia Questions ", "")
			local Questions, Answers = pluginsList[i].Object:QuestionData()
			TriviaQuestions[category] = { Questions, Answers }
		end
	end
	-- DEBUG: Print all category names
	for k, v in pairs(TriviaQuestions) do
		totalNumberOfCategories = totalNumberOfCategories + 1
		print("Category: " .. tostring(k))
	end
	-- DEBUG: Print the total number of categories
	print("Total number of categories: " .. tostring(totalNumberOfCategories))
	-- DEBUG: Print the questions/answers in each category
	for k, v in pairs(TriviaQuestions) do
		print("Category: " .. tostring(k))
		for k, v in pairs(v) do
			if k == 1 then
				for k, v in pairs(v) do
					print ("Question: " .. v )
				end
			else
				for k, v in pairs(v) do
					print ("Answer: " .. v )
				end
			end
		end
	end
	-- If enabled, start the timer to broadcast questions
	if self.Config.Settings.enabled == "true" then
		self.TriviaTimer = {}
		self.TriviaTimer = timer.Repeat (tonumber(self.Config.Settings.interval) , 0 , function() self:AskQuestion( ) end )
	end
end

function PLUGIN:LoadDefaultConfig()
	-- Set/load the default config options
	self.Config.Settings = self.Config.Settings or {
		-- How often are the questions asked
		interval = "60",
		-- Enable or disable the plugin
		enabled = "false",
		-- Whether or not the same question is repeated if
		-- not answered correctly
		doesQuestionRepeat = "true",
		-- How many times a certain question will be repeated
		questionRepeats = "3",
		-- Name to be used in plugin broadcasts
		ChatName = "TRIVIA",
		-- Auth level required to enable/disable plugin
		-- "0" = Anyone
		-- "1" = Moderator
		-- "2" = Owner
		ToggleAuthLevel = "1",
		-- Enable/disable use of the Jeopardy web API
		EnableJeopardyAPI = "true",
		-- Enable disable the use of a point system to
		-- determine "round" winner.
		EnablePointSystem = "true",
		-- Enable/disable the economy API for rewarding
		-- correct answers
		EnableEconomyAPI = "true",
		-- Enable/disable the item reward system
		EnableRewards = "true"
	}
	self.Config.Rewards = self.Config.Rewards or {
		-- Item Reward System configuration. Probably needs
		-- to be changed to a table to allow for multiple
		-- rewards
		Item = "Cooked Human Meat",
		Amount = 1
	}
	-- Various messages used by the plugin
	self.Config.Messages = self.Config.Messages or {
		TriviaEnabled = "Trivia has been enabled.",
		TriviaDisabled = "Trivia has been disabled.",
		NoPermission = "You do not have permission for that command."
	}
	self:SaveConfig()
end

function PLUGIN:AskQuestion()
	-- Check if the question is answered or if question
	-- repeating is enabled. If it has been answered or
	-- question repeating is disabled, ask a new question
	if answered == "true" or self.Config.Settings.doesQuestionRepeat == "false" then
		previousQuestionNumber = questionNumber
		-- Make sure that the same question is not asked again
		while questionNumber == previousQuestionNumber do 
			-- Get a random question number to ask
			questionNumber = math.random(totalNumberOfQuestions)
		end
		-- Set the answer for the current question being asked
		currentAnswer = self.Config.Answers[tostring(questionNumber)]
		-- Broadcast the question
		global.ConsoleSystem.Broadcast("chat.add " .. self:QuoteSafe(self.Config.Settings.ChatName) .. " " .. self:QuoteSafe(self.Config.Questions[tostring(questionNumber)]))
	-- If the question has not been answered and repeating
	-- is enabled, ask the same question again
	elseif answered ~= "true" and self.Config.Settings.doesQuestionRepeat == "true" then
		-- If the question has been repeated less than the
		-- configured number of times, ask it again.
		-- Otherwise, ask a new question
		if repeats <= tonumber(self.Config.Settings.questionRepeats) then
			global.ConsoleSystem.Broadcast("chat.add " .. self:QuoteSafe(self.Config.Settings.ChatName) .. " " .. self:QuoteSafe(self.Config.Questions[tostring(questionNumber)]))
		else
			-- Ask a new question here
		end
	end
end

function PLUGIN:cmdAnswerQuestion(player, cmd, args)
	-- Parse args for the answer, if correct, set answered
	-- to true and reward the player
end

function PLUGIN:cmdToggleTrivia(player, cmd, args)
	-- Check player auth level, disable the plugin, and
	-- destroy the timer
	if player.net.connection.authLevel >= tonumber(self.Config.Settings.authLevel) then
		if self.Config.Settings.enabled == "true" then
			self.Config.Settings.enabled = "false"
			self:SaveConfig()
			if self.TriviaTimer then
				self.TriviaTimer:Destroy()
			end
			player:SendConsoleCommand("chat.add " .. self:QuoteSafe(self.Config.Settings.ChatName) .. " " .. self:QuoteSafe(self.Config.Messages.TriviaDisabled))
		else
			self.Config.Settings.enabled = "true"
			self:SaveConfig()
			self.TriviaTimer = {}
			self.TriviaTimer = timer.Repeat (tonumber(self.Config.Settings.interval) , 0 , function() self:AskQuestion( ) end )
			player:SendConsoleCommand("chat.add " .. self:QuoteSafe(self.Config.Settings.ChatName) .. " " .. self:QuoteSafe(self.Config.Messages.TriviaEnabled))
		end
	else
		-- Notify user that they do not have permission to
		-- enable/disable the plugin
		player:SendConsoleCommand("chat.add " .. self:QuoteSafe(self.Config.Settings.ChatName) .. " " .. self:QuoteSafe(self.Config.Messages.NoPermission))
	end
end

function PLUGIN:cmdCategories(player, cmd, args)
	-- List the available categories in a global broadcast
	for k, v in pairs(TriviaQuestions) do
		global.ConsoleSystem.Broadcast("chat.add " .. self:QuoteSafe(self.Config.Settings.ChatName) .. " " .. self:QuoteSafe(tostring(k)))
	end
end

-- On plugin unload, destroy the timer if it exists
function PLUGIN:Unload()
	if self.TriviaTimer then self.TriviaTimer:Destroy() end
end
