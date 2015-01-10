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

function PLUGIN:Init()
	self:LoadDefaultConfig()
	command.AddChatCommand("trivia", self.Object, "cmdToggleTrivia")
	command.AddChatCommand("answer", self.Object, "cmdAnswerQuestion")
	command.AddChatCommand("triviacategories", self.Object, "cmdCategories")
end

function PLUGIN:OnServerInitialized()
	local pluginsList = plugins.GetAll()
	print("Number of plugins: ".. tostring(pluginsList.Length))
	for i = 0, tonumber(pluginsList.Length) - 1 do
		print(tostring(pluginsList[i].Object.Title))
	end
	TriviaQuestions = {}
	for i = 0, tonumber(pluginsList.Length) - 1 do
		if pluginsList[i].Object.Title:match("Trivia Questions") then  
			local category = pluginsList[i].Object.Title:gsub("Trivia Questions ", "")
			local Questions, Answers = pluginsList[i].Object:QuestionData()
			TriviaQuestions[category] = { Questions, Answers }
		end
	end
	for k, v in pairs(TriviaQuestions) do
		totalNumberOfCategories = totalNumberOfCategories + 1
		print("Category: " .. tostring(k))
	end
	print("Total number of categories: " .. tostring(totalNumberOfCategories))
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

local function QuoteSafe(string)
	return UnityEngine.StringExtensions.QuoteSafe(string)
end

function PLUGIN:LoadDefaultConfig()
	-- Set/load the default config options
	self.Config.Settings = self.Config.Settings or {
		interval = "60",
		enabled = "false",
		doesQuestionRepeat = "true",
		questionRepeats = "3",
		ChatName = "TRIVIA",
		ToggleAuthLevel = "1"
	}
	self.Config.Rewards = self.Config.Rewards or {
		Item = "Cooked Human Meat",
		Amount = 1
	}
	self:SaveConfig()
end

function PLUGIN:AskQuestion()
	-- Check if the question is answered or if question repeating is enabled.
	-- If it has been answered or question repeating is disabled, ask a new question
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
		global.ConsoleSystem.Broadcast("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Questions[tostring(questionNumber)] .. "\"")
	-- If the question has not been answered and repeating is enabled, ask the same question again
	elseif answered ~= "true" and self.Config.Settings.doesQuestionRepeat == "true" then
		-- If the question has been repeated less than the configured number of times, ask it again.
		-- Otherwise, ask a new question
		if repeats <= self.Config.Settings.questionRepeats then
			global.ConsoleSystem.Broadcast("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Questions[tostring(questionNumber)] .. "\"")
		else
			-- Ask a new question here
		end
	end
end

function PLUGIN:cmdAnswerQuestion(player, cmd, args)
	-- Parse args for the answer, if correct, set answered to true and reward the player
end

function PLUGIN:cmdToggleTrivia(player, cmd, args)
	-- Check player auth level and disable the plugin and destroy the timer
end

function PLUGIN:cmdCategories(player, cmd, args)
	for k, v in pairs(TriviaQuestions) do
		global.ConsoleSystem.Broadcast("chat.add " .. self:QuoteSafe(self.Config.Settings.ChatName) .. " " .. self:QuoteSafe(tostring(k)))
	end
end

-- On plugin unload, destroy the timer if it exists
function PLUGIN:Unload()
	if self.TriviaTimer then self.TriviaTimer:Destroy() end
end
