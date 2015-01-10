PLUGIN.Title = "Trivia Questions Template"
PLUGIN.Version = V(0, 0, 1)
PLUGIN.Description = "Example trivia questions for Trivia plugin"
PLUGIN.Author = "Mr. Bubbles AKA BlazR with a ton of help from Mughisi"
PLUGIN.Url = "None"
PLUGIN.ResourceId = 000
PLUGIN.HasConfig = false

local TriviaQuestions = {}
local TriviaAnswers = {}

function PLUGIN:Init()
	TriviaQuestions[1] = "How much is 2 times 4?"
    TriviaAnswers[1] = "8"
    TriviaQuestions[2] = "Calculate x; 2x=10+4"
    TriviaAnswers[2] = "7"
	TriviaQuestions[3] = "Is this a sample question?"
    TriviaAnswers[3] = "yes"
    TriviaQuestions[4] = "What is the name of the game you are playing (not this plugin)?"
    TriviaAnswers[4] = "rust"
	TriviaQuestions[5] = "Is this ridiculous question a ridiculous question?"
    TriviaAnswers[5] = "yes"
end

function PLUGIN:QuestionData()
	return TriviaQuestions, TriviaAnswers
end