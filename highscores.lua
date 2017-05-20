local composer = require( "composer" )
local json = require("json")

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local scoreTableLength = 8 -- How many scores to display

local ccX = display.contentCenterX -- Preinitalise utility/object reated variables
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


local function moveSkinWidget() --Player 'icon' annimation function

	skinWidget.y = skinWidget.y + skinF
	skinWidget.rotation = skinWidget.rotation + 2

	if (skinWidget.y > cH-275 or skinWidget.y < 250) then
			skinF = -skinF
	end
end


--Following code manipulates stored highscore data

local finalScore = composer.getVariable("finalScore") or 0 --Load final score from just completed game (defaults to zero if none found; the "or 0" part)
local scoreData
local filePath = system.pathForFile("scoreData.json", system.DocumentsDirectory)


local function loadScores()

	local file = io.open(filePath, "r")

	if file then
		local contents = file:read("*a")
		io.close(file)
		scoreData = json.decode(contents)
	end

	if (scoreData == nil or #scoreData == 0) then
		scoreData = {tonumber(finalScore) or 0, 0, 0, 0, 0}
	elseif (composer.getVariable("isFromGame")) then -- Insert final gamescore into highscores if previous scene was the game; dont repeat this if the highscores button on main menu si pressed
		table.insert(scoreData, finalScore)
		table.sort(scoreData, function(a, b) return a > b end)
		scoreData[scoreTableLength+1] = nil
	end

  local file = io.open(filePath, "w") -- save updated scores
  file:write(json.encode(scoreData))
  io.close(file)

end

local scoreTextTable = {}
local function showScores(parent)

  local isCurrentDone = false --Keeps track of whether or not the user's most recent score is highlighted; stops any duplicate scores also being highlighted

	for i=1, #scoreData do

		scoreTextTable[i] = display.newText(parent, tostring(scoreData[i] or 0), 3*cW/4, 150+i*100, native.systemFont, 72) --create new text widget in appropriate place

		if (not isCurrentDone and scoreData[i] == finalScore and finalScore ~= 0) then
			isCurrentDone = true
			scoreTextTable[i]:setFillColor(unpack(skinColor)) -- highlight user's most recent score
		end

	end

end

local function onBackButtonPress() --Event handler for back button interaction

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

  --Creates consistent display objects; i.e. those that are always the same

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

	loadScores() -- Load score data from file
	showScores(sceneGroup) -- Display this data

end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

		skinTimer = timer.performWithDelay(10, moveSkinWidget, 0) --Bind event listeners to handlers
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
