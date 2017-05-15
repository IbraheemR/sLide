
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local ccX = display.contentCenterX
local ccY = display.contentCenterY
local cH = display.contentHeight
local cW = display.contentWidth

local background

local gameState = 0 -- 0 to 0.9 is waiting, 1 ingame, 2 ended & cleanup, 3 finished
local gameScore = 0
local gameScoreText

local gameLoopTimer
local updateTimer

local skinWidget
local skinId = composer.getVariable("skin")
local skinTable = composer.getVariable("skinTable")
local skinColor = composer.getVariable("skinColor")
local skinTimer

local objSpeed = 50
local objSpeedM = 2
local lObjSpeed = 0
local rObjSpeed = 0
local objTable = {}

local inScoreVal = 1

local doUpSpeed =true

local function makeEnd()

	timer.cancel(gameLoopTimer)
	timer.cancel(updateTimer)
	timer.cancel(skinTimer)

	for i=#objTable, 1, -1 do
		display.remove( objTable[i] )
	end

	objTable = {}


end

local function moveSkinWidget()
	if (gameState == 1) then
		skinWidget.rotation = skinWidget.rotation + 5
	end
end

local touchOffsetX
local touchOffsetY
local function onSkinWidgetTouch( event )

	local p = event.target
	local phase = event.phase

	if (phase == "began" and gameState < 2) then

		display.currentStage:setFocus(p) --focus on ship
		touchOffsetX = event.x - p.x -- store initial offset
		touchOffsetY = event.y - p.y

		if (gameState < 1 ) then
			gameState = 1
		end

	elseif (phase == "moved" and gameState < 2) then

		p.x = event.x - touchOffsetX --move ship to new pos
		p.y = event.y - touchOffsetY

		if (p.x < 50) then
			p.x = 50
		elseif (p.x > cW-50) then
			p.x=cW-50
		end

		if (p.y < 200) then
			p.y = 200
		elseif (p.y > cH-100) then
			p.y=cH-100
		end

		if (p.x > ccX) then
			rObjSpeed = objSpeedM
			lObjSpeed = 1

		else
			lObjSpeed = objSpeedM
			rObjSpeed = 1
		end


	elseif ( phase == "ended" or phase == "cancelled" or state == 2) then

		display.currentStage:setFocus(nil) -- release focus

	end

	return true
end

local function incScore()

	gameScore = gameScore + inScoreVal
	gameScoreText.text = gameScore
end

local function createObj()

	local objType = math.random(5)
	local objSide = math.random(2)

	local newObj

	if (objType == 1 ) then
		
		newObj = display.newRect( display.contentWidth*0.25, -display.contentHeight/30, display.contentWidth/2, display.contentHeight/15)

	elseif (objType == 2 or objType == 3) then

		newObj = display.newRect( display.contentWidth*0.125, -display.contentHeight/30, display.contentWidth/4, display.contentHeight/15)

	else

		newObj = display.newRect( display.contentWidth*0.125*3, -display.contentHeight/30, display.contentWidth/4, display.contentHeight/15)

	end

	if (objSide == 1 ) then
		
		newObj.x = newObj.x + display.contentCenterX

	else

		newObj:setFillColor(0, 0, 0)

	end

	newObj.side = objSide

	table.insert(objTable, newObj)
	
end

local function updateObjs()

	for i = #objTable, 1, -1 do



		local thisObj = objTable[i]

		if (thisObj.y > display.contentHeight+100) then

			table.remove(objTable, i)
			display.remove( thisObj )

		elseif (thisObj.side == 1) then

			transition.to(thisObj, {y = thisObj.y + (objSpeed*rObjSpeed), time=100})
			
		else

			transition.to(thisObj, {y = thisObj.y + (objSpeed*lObjSpeed), time=100})
			
		end

		local x = skinWidget.x; local y = skinWidget.y



		local lowX = thisObj.x - (thisObj.width/2)
		local upX = thisObj.x + (thisObj.width/2)

		local lowY = thisObj.y - (thisObj.height/2)
		local upY = thisObj.y + (thisObj.height/2)


		if (x >= lowX and x <= upX and y >= lowY and y <= upY) then
			gameState = 2
			skinWidget:setFillColor(1, 0.2, 0)
		end

		


	end
	
end
	

local function upSpeed()
	if (doUpSpeed) then
		objSpeed = objSpeed + 2
		inScoreVal = inScoreVal + 1

	end
end

local i = 0
local function gameLoop()

	if (gameState == 1) then
		createObj()
	end

	if (gameScore > 30 and gameScore < 1000) then
		upSpeed()
	end



end

local function updateLoop()
	if (gameState == 1) then
		updateObjs()
		incScore()
	elseif (gameState == 2) then
		makeEnd()
		composer.gotoScene("highscores", {effect="slideDown", time = 1000})
		timer.performWithDelay(1050, function()
			composer.removeScene("game")
		end)
	end
end


local filePath = system.pathForFile("scoreData.json", system.DocumentsDirectory)

local function saveScores()
	
	composer.setVariable("finalScore", gameScore)
	composer.setVariable("isFromGame", true)
	
end



-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	background = display.newRect(sceneGroup, cW/4, ccY, ccX, cH)
	

	skinWidget = display.newImageRect(sceneGroup, skinTable[skinId], 100, 100)
	skinWidget.x=ccX; skinWidget.y=cH-200
	skinWidget:setFillColor(unpack(skinColor))

	gameScoreText = display.newText(sceneGroup, gameScore, ccX-85, 100, native.systemFont, 72)
	gameScoreText:setFillColor(0, 0, 0)



end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen

		skinTimer = timer.performWithDelay(10, moveSkinWidget, 0)
		timer.performWithDelay(1000, function()
			gameState = 0.9
		end)

		skinWidget:addEventListener("touch", onSkinWidgetTouch)

		gameLoopTimer = timer.performWithDelay(750, gameLoop, 0)
		updateTimer = timer.performWithDelay(30, updateLoop, 0)

	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)

		saveScores()

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
