local composer = require( "composer" )
local json = require("json")

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local scoreTableLength = 8


function deepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

local ccX = display.contentCenterX
local ccY = display.contentCenterY
local cH = display.contentHeight
local cW = display.contentWidth

local background
local title1
local title2


local skinWidget
local skinId = composer.getVariable("skin")
local skinTable = composer.getVariable("skinTable")
local skinColor = composer.getVariable("skinColor")
local skinTimer
local skinF = 10

local backButton



local function moveSkinWidget()

	skinWidget.y = skinWidget.y + skinF 
	skinWidget.rotation = skinWidget.rotation + 2

	if (skinWidget.y > cH-275 or skinWidget.y < 250) then
			skinF = -skinF
	end
end




local finalScore = composer.getVariable("finalScore") or 0
local scoreData
local filePath = system.pathForFile("scoreData.json", system.DocumentsDirectory)

local function saveScores()
	local file = io.open(filePath, "w")

	file:write(json.encode(scoreData))

	io.close(file)
end


local function loadScores()

	local file = io.open(filePath, "r")

	if file then
		local contents = file:read("*a")
		io.close(file)
		scoreData = json.decode(contents)
	end

	if (scoreData == nil or #scoreData == 0) then
		scoreData = {tonumber(finalScore) or 0, 0, 0, 0, 0}
	elseif (composer.getVariable("isFromGame")) then
		table.insert(scoreData, finalScore)
		table.sort(scoreData, function(a, b) return a > b end)
		scoreData[scoreTableLength+1] = nil
	end

		saveScores()

end

local scoreTextTable = {}
local function showScores(parent)

	local isCurrentDone = false

	for i=1, #scoreData do

		scoreTextTable[i] = display.newText(parent, tostring(scoreData[i] or 0), 3*cW/4, 150+i*100, native.systemFont, 72)

		if (not isCurrentDone and scoreData[i] == finalScore and finalScore ~= 0) then
			isCurrentDone = true
			scoreTextTable[i]:setFillColor(unpack(skinColor))

		end

	end
	
end

local function onBackButtonPress()

		timer.cancel(skinTimer)

		composer.gotoScene("menu", {effect="slideUp", time = 500})
		timer.performWithDelay(550, function()
			composer.removeScene("highscores")
		end)	
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	background = display.newRect(sceneGroup, cW/4, ccY, ccX, cH)

	title1 = display.newText(sceneGroup, "Highs", ccX-90, 100, native.systemFont, 72)
	title1:setFillColor(0, 0, 0)
	title2 = display.newText(sceneGroup, "cores", ccX+90, 100, native.systemFont, 72)

	skinWidget = display.newImageRect(sceneGroup, skinTable[skinId], 150, 150)
	skinWidget.x=cW/4; skinWidget.y=ccY
	skinWidget:setFillColor(unpack(skinColor))

	backButton = display.newImageRect(sceneGroup, "back.png", 100, 100)
	backButton.x = ccX; backButton.y = cH-100
	backButton:setFillColor(unpack(skinColor))

	loadScores()

	showScores(sceneGroup)

end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

		skinTimer = timer.performWithDelay(10, moveSkinWidget, 0)
		backButton:addEventListener("tap", onBackButtonPress)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen

	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)



	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen

	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
