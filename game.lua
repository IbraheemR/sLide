
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local ccX = display.contentCenterX -- Preinitliaise utility and object related variables
local ccY = display.contentCenterY
local cH = display.contentHeight
local cW = display.contentWidth

local background

local immortal = false
local doPUps = true

local gameState = 0 -- Game state: 0 to 0.9 is waiting, 1 ingame, 2 ended & cleanup, 3 finished
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

local pUpTable = {}
local pointPUpMultiplyer = 100

local inScoreVal = 1

local doUpSpeed =true

local function makeEnd() --Stops game loops and safely deletes game objects

	timer.cancel(gameLoopTimer)
	timer.cancel(updateTimer)
	timer.cancel(skinTimer)

	for i=#objTable, 1, -1 do
		display.remove( objTable[i] )
	end

	objTable = {}

	for i=#pUpTable, 1, -1 do
		display.remove( pUpTable[i] )
	end

	pUpTable = {}


end

local function moveSkinWidget() -- Rotates player 'icon' when in mation
	if (gameState == 1) then
		skinWidget.rotation = skinWidget.rotation + 5
	end
end

local touchOffsetX
local touchOffsetY

local function onSkinWidgetTouch( event ) -- calculates movement offset  when player 'icon' is being dragged

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

local function doPointIndication(text, color) -- displays points gained from power up

	local text = display.newText(scene.view, "+"..tostring(text), 3*cW/4, 100, native.systemFont, 56) -- creates text
	text:setFillColor(unpack(color))

	local lenTime = 1000 -- duration text stays on screen

	transition.to( text, {time=lenTime, alpha=0, y=-50 }) -- Animation: moves text up and fades it
	timer.performWithDelay( lenTime, function() display.remove( text )end ) --Safely removes text after it has faded

end

local function incScore() --Increaes score every tic and updates display text

	gameScore = gameScore + inScoreVal
	gameScoreText.text = gameScore
end

--followinf functions create powerups

local pointPUpColors = {{0, 0.1, 1}, {0, 1, 0,1}, {0.9, 0, 0}}

local function createPointPUp()

	local val = math.random(3)
	local points = (math.pow(val, 2)+1) * pointPUpMultiplyer

	newPUp = display.newRect(math.random(cW), -20, 20, 20)
	newPUp:setFillColor(unpack(pointPUpColors[val]))

	newPUp.points = points
	newPUp.val = val
	newPUp.doneTouch = false

	table.insert(pUpTable, newPUp)
end

local function createPUp()
	local pUpType = math.random(10)

	if (pUpType == 1) then
		createPointPUp()
	end

end


local function createObj() -- Creates obstacle

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


--Following functions update powerpus and obstacles

local function updateObjs()

	for i = #objTable, 1, -1 do

		local thisObj = objTable[i]

		if (thisObj.y > display.contentHeight+100) then

			display.remove( thisObj )
			table.remove(objTable, i)


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


		if (x >= lowX and x <= upX and y >= lowY and y <= upY and not immortal) then
			gameState = 2
			skinWidget:setFillColor(1, 0.2, 0)
		end

	end

end

local function updatePUps()

	for i = #pUpTable, 1, -1 do

		local thisPUp = pUpTable[i]
		local thisPUpSpeed = thisPUp.speed or objSpeed

		if (thisPUp.y > display.contentHeight+100) then

			display.remove( thisPUp )
			table.remove(pUpTable, i)

		else

			transition.to(thisPUp, {y = thisPUp.y + (thisPUpSpeed), rotation = thisPUp.rotation+90, time=100})

		end



		local x1 = skinWidget.x; local y1 = skinWidget.y
		local x2 = thisPUp.x ; local y2 = thisPUp.y

		local dist = math.pow(math.pow(x1-x2, 2) + math.pow(y1-y2, 2), 0.5)

		if (dist < 100 and not thisPUp.doneTouch) then
			thisPUp.doneTouch = true

			gameScore = gameScore + thisPUp.points
			doPointIndication(thisPUp.points, pointPUpColors[thisPUp.val])

			transition.to( thisPUp, {xScale=4, yScale=4, alpha=0, time=250} )
			timer.performWithDelay( 301, function()
				table.remove( pUpTable, i )
				display.remove( thisPUp )
			end)
		end

	end

end



local function upSpeed() -- Increases speed as player levels up
	if (doUpSpeed) then
		objSpeed = objSpeed + 2
		inScoreVal = inScoreVal + 1

	end
end

local i = 0


local function gameLoop() -- Main game loop

	if (gameState == 1) then
		createObj()
		if doPUps then createPUp() end
	end

	if (gameScore > 30 and gameScore < 1000) then
		upSpeed()
	end



end

local function updateLoop() -- Updates obstacles and powerups. Initialies end of game when state = 2
	if (gameState == 1) then
		updateObjs()
		updatePUps()
		incScore()
	elseif (gameState == 2) then
		makeEnd()
		composer.gotoScene("highscores", {effect="slideDown", time = 1000})
		timer.performWithDelay(1050, function()
			composer.removeScene("game")
		end)
	end
end


local function saveScores() -- Sets final game score to be added to saved highscores if it is high enough (in highscores scene)

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

	gameScoreText = display.newText(sceneGroup, gameScore, cW/4, 100, native.systemFont, 72)
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
