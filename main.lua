local composer = require("composer") -- Import reuired libaries/modules
local json = require("json")

math.randomseed(os.time()) -- Create new random generator seed

local skinData = {}

local function loadData() -- Load skin data

	local filePath = system.pathForFile("skinData.json", system.DocumentsDirectory)

	local file = io.open(filePath, "r")

	if file then
		local contents = file:read("*a")
		io.close(file)
		skinData = json.decode(contents)
	end
end

loadData()

local skinId = skinData["skin"] or 2    --Load from permanent data
composer.setVariable("skin", skinId)
local skinTable = {"skin1.png", "skin2.png", "skin3.png", "skin4.png"}
composer.setVariable("skinTable", skinTable)
local skinColor =  skinData["skinColor"] or {0, 0.5, 1}
composer.setVariable("skinColor", skinColor)

composer.setVariable("isFromGame", false) -- Keeps track of tranistions to highscores scene


composer.gotoScene("menu") -- Go to menu scene
