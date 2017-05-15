local composer = require("composer")
local json = require("json")

display.setStatusBar(display.HiddenStatusBar)

math.randomseed(os.time())

local skinData = {}

local function loadData()

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

composer.setVariable("isFromGame", false)


composer.gotoScene("menu")

