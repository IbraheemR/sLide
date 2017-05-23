
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

local immortal = true

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

local objsAcitve = true
local objsActiveTimer

local barIndicatorActive = false

local doPUps = true
local pUpTable = {}
local pUpChance = 5
local pointPUpMultiplyer = 100

local inScoreVal = 1

local function makeEnd() --Stops game loops and safely deletes game objects

	timer.cancel(gameLoopTimer)
	timer.cancel(updateTimer)
	timer.cancel(skinTimer)

	for i=#objTable, 1, -1 do
		display.remove( objTable[i] )
	end

	objTable = nil

	for i=#pUpTable, 1, -1 do
		display.remove( pUpTable[i] )
	end

	pUpTable = nil


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

	if (gameState < 1 ) then
		gameState = 1
	end

	if (phase == "began" and gameState < 2) then

		display.currentStage:setFocus(p) --focus on ship
		touchOffsetX = event.x - p.x -- store initial offset
		touchOffsetY = event.y - p.y

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

local function doIndication(text, color) -- display text for powerup etc

	local text = display.newText(scene.view, tostring(text), 3*cW/4, 100, native.systemFont, 56) -- creates text
	text:setFillColor(unpack(color or {}))

	local lenTime = 1000 -- duration text stays on screen

	transition.to( text, {time=lenTime, alpha=0, y=-50 }) -- Animation: moves text up and fades it
	timer.performWithDelay( lenTime, function() display.remove( text )end ) --Safely removes text after it has faded

end

local function doBarIndication(fadeTime, color)
	bar = display.newRect(scene.view, 0, cH, cW, 50 )
	bar:setFillColor(unpack( color ))
	barIndicatorActive = true

	id = transition.to( bar, {width = 0, time = fadeTime} )
	timer.performWithDelay(fadeTime, function()
		barIndicatorActive = false
		display.remove(bar)
	end)

	--return id
end

local function doPointIndication(points, color) -- displays points gained from power up

	doIndication("+" .. tostring(points), color)

end

local function incScore() --Increaes score every tic and updates display text

	gameScore = gameScore + inScoreVal
	gameScoreText.text = gameScore
end

--followinf functions create powerups

local pointPUpColors = {{0, 0.1, 1}, {0, 1, 0,1}, {0.9, 0, 0}}

local function newPointPUp() --this powerup gives the player an amount of points (blue 200, green 500, red 1000)

	local val = math.random(3)
	local points = (math.pow(val, 2)+1) * pointPUpMultiplyer

	newPUp = display.newRect(math.random(cW), -20, 20, 20)
	newPUp:setFillColor(unpack(pointPUpColors[val]))

	newPUp.points = points
	newPUp.val = val
	newPUp.doneTouch = false

	function newPUp:powerFunction() --called if powerup is activated/touched
		gameScore = gameScore + self.points -- Increase point amount
		doPointIndication(self.points, pointPUpColors[self.val]) --tell the player howmany points they got
	end

	function newPUp:updateFunction() -- called every tick, moves the object down and rotates it
		transition.to(self,  {y = self.y + (self.speed or objSpeed), rotation = self.rotation+90, time=100})
	end

	return newPUp
end

local function newPhasePUp() -- allows the player to 'phase through' objects for 10 seconds

	local newPUp = display.newRect(math.random(cW), -20, 20, 20) -- display object
	newPUp:setFillColor(0.5, 0.5, 0.5) -- set color

	newPUp.doneTouch = false --set to treu once touched, stops the powerup being activated multiple times

	function newPUp:powerFunction() --called if powerup is activated/touched

		if (not barIndicatorActive) then -- ensures there is no other 'long term' powerup active
			objsAcitve = false -- Allow the player to pass through objects
			doIndication("Invincible", {0.5, 0.5, 0.5}) -- tells the player about this
			doBarIndication(10000, {0.5, 0.5, 0.5}) -- Set a bar at the bottom, which shrinks as the powerup runs out

			if(objsActiveTimer) then timer.cancel(objsActiveTimer) end --cancel any other running delays with the "phase" tag
			timer.performWithDelay(10000, function() objsAcitve = true end) -- deactivate the powerup after 10 seconds (10000 microseconds)
		end
	end
end

	local function newSpeedPUp() -- allows the player to 'phase through' objects for 10 seconds

		local newPUp = display.newRect(math.random(cW), -20, 20, 20) -- display object
		newPUp:setFillColor(1, 0, 1) -- set color

		newPUp.doneTouch = false --set to true once touched, stops the powerup being activated multiple times

		function newPUp:powerFunction() --called if powerup is activated/touched

				objSpeed = math.ceil(objSpeed * 1.31) -- Speed up the game
				gameScore = gameScore + 1000 -- reward the player for speeding up
				doIndication("Speeding Up\n     +1000", {1, 0, 1}) -- tells the player about this
		end

	function newPUp:updateFunction() -- called every tick, moves the object down and rotates it
		transition.to(self, {y = self.y + (self.speed or objSpeed), rotation = self.rotation-90, time=100})
	end

	return newPUp
end

local function createPUp() -- creates a powerup
	-- local pUpType = math.random(pUpChance) -- determine type

	-- if (pUpType == 1) then
	-- 	newPUp = newPhasePUp()
	-- elseif (pUpType == 2) then
	-- 	 newPUp = newPhasePUp()
	-- elseif (pUpType == 3) then
	-- 	 newPUp = newPhasePUp()
	-- end

	newPUp = newPhasePUp()

	if newPUp then
		newPUp.type = 2--pUpType
		table.insert(pUpTable, newPUp)
	end

end


local function createObj() -- Creates  an obstacle

	local objType = math.random(5) --determine obstace type (1 across the whole side, 2 or 3 on the left, 4 or 5 on the right)
	local objSide = math.random(2) -- determine if the obsatce is on the left or right side

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

		if (not objsAcitve) then
			thisObj.alpha = 0.7

		end



		local x = skinWidget.x; local y = skinWidget.y

		local lowX = thisObj.x - (thisObj.width/2)
		local upX = thisObj.x + (thisObj.width/2)

		local lowY = thisObj.y - (thisObj.height/2)
		local upY = thisObj.y + (thisObj.height/2)


		if (x >= lowX and x <= upX and y >= lowY and y <= upY and objsAcitve and not immortal) then -- detect if player has hit an obstacle
			gameState = 2
			skinWidget:setFillColor(1, 0.2, 0)
		end

	end

end

local function updatePUps()

	for i = #pUpTable, 1, -1 do

		local thisPUp = pUpTable[i]

		--if (thisPUp.type == 2 and barIndicatorActive) then -- delete phase power ups (type 2) if another is already active
			--thisPUp.needRemove = true
		--end

		local x1 = skinWidget.x; local y1 = skinWidget.y
		local x2 = thisPUp.x or 0 ; local y2 = thisPUp.y or 0

		local dist = math.pow(math.pow(x1-x2, 2) + math.pow(y1-y2, 2), 0.5)

		if (dist < 100 and not thisPUp.doneTouch) then -- if player touches a power up, run irs power function, fade it and delete it
			thisPUp.doneTouch = true

			thisPUp:powerFunction()

			transition.to( thisPUp, {xScale=4, yScale=4, alpha=0, time=250} )
			timer.performWithDelay( 250,  function() thisPUp.needRemove = true end ) -- schedule it to be deleted, instead of deleting it now which can cause errors

		end

		if (thisPUp.needRemove or  thisPUp.y > (display.contentHeight+100)) then

			display.remove( thisPUp )--remove powerup from display scene
			table.remove(pUpTable, i)--remove powerup from memory

		else
			thisPUp:updateFunction()

		end

	end

end

local i = 0


local function gameLoop() -- Main game loop

	if (gameState == 1) then
		createObj()
		if doPUps then createPUp() end
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

-- create 'known' display objects (those which always appear and are nor placed randomly, e.g obstacles)

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

		--game loop timers

		skinTimer = timer.performWithDelay(10, moveSkinWidget, 0)
		timer.performWithDelay(1000, function()
			gameState = 0.9
		end)

		skinWidget:addEventListener("touch", onSkinWidgetTouch)

		gameLoopTimer = timer.performWithDelay(750, gameLoop, 0)
		updateTimer = timer.performWithDelay(30, updateLoop, 0)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
		doPointIndication(1000)

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
