
local composer = require( "composer" )
local json = require("json")

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local ccX = display.contentCenterX -- Preinitialise utility/object related vaiables
local ccY = display.contentCenterY
local cH = display.contentHeight
local cW = display.contentWidth

local background

local backButton

local skinWidget = {}
local skinId = composer.getVariable("skin")
local skinTable = composer.getVariable("skinTable")
local skinColor = composer.getVariable("skinColor")
local skinTimer
local skinF = 7

local skinColors = {{0, 0.5, 1}, {1, 0.5, 1}, {1, 0.5, 0}, {0, 0.8, 0.2}}

local colorButtons = {}
local skinButtons = {}

local skinData = {}

local filePath = system.pathForFile("skinData.json", system.DocumentsDirectory)

-- Following functions load and save user selected skin & color to file; 'non-volitle' storage

local function loadData()

	local file = io.open(filePath, "r")

	if file then
		local contents = file:read("*a")
		io.close(file)
		skinData = json.decode(contents)
	end

end

local function saveData()

	local file = io.open(filePath, "w")

	if file then
		file:write(json.encode(skinData))
		io.close(file)
	end
end

local function updateSkin( id)
	skinId = id+1
	composer.setVariable("skin", skinId)

	local newSkinWidget = display.newImageRect(skinWidget.parent, skinTable[skinId], 100, 100)
	newSkinWidget.x = skinWidget.x; newSkinWidget.y =skinWidget.y; newSkinWidget.rotation = skinWidget.rotation
	newSkinWidget:setFillColor(unpack(skinColor))

	skinWidget:removeSelf()
	skinWidget = newSkinWidget


	-- Store selected skin
	skinData["skin"] = skinId
end

local function US0() updateSkin(0) end -- Event handlers for updating skin icons
local function US1() updateSkin(1) end
local function US2() updateSkin(2) end
local function US3() updateSkin(3) end

local function updateColor(id)
	skinColor = skinColors[id+1]
	skinWidget:setFillColor(unpack(skinColor))
	composer.setVariable("skinColor", skinColor)


	-- Store selected color
	skinData["skinColor"] = skinColor

end

local function UC0() updateColor(0) end -- Event handlers for updating skin color
local function UC1() updateColor(1) end
local function UC2() updateColor(2) end
local function UC3() updateColor(3) end



local function moveSkinWidget() -- Player 'icon' animation function

	skinWidget.x = skinWidget.x + skinF
	skinWidget.rotation = skinWidget.rotation + 2

	if (skinWidget.x > cW-75 or skinWidget.x < 225) then
			skinF = -skinF
	end
end

local function onBackButtonPress() --Back button event handler

		timer.cancel(skinTimer)

		composer.gotoScene("menu", {effect="slideRight", time = 500})
		timer.performWithDelay(550, function()
			composer.removeScene("skins")
		end)
end






-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	loadData() -- Load skin/color data

-- Create display objects

	background = display.newRect(sceneGroup, 0.75*cW, ccY, ccX, cH)

	backButton = display.newImageRect(sceneGroup, "back.png", 100, 100)
	backButton.x = 100; backButton.y = ccY
	backButton:setFillColor(unpack(skinColor))

	skinWidget = display.newImageRect(sceneGroup, skinTable[skinId], 100, 100)
	skinWidget.x=ccX; skinWidget.y=ccY
	skinWidget:setFillColor(unpack(skinColor))

	-- Create skin/color changing buttons

	for i=0, 3 do
		local x, y
		if (i % 2 == 0) then
			x = cW*0.30
		else
			x = cW*0.70
		end
		if (i<2) then
			y = cW*0.20
		else
			y = cW*0.55
		end

		local newButton = display.newRoundedRect(sceneGroup, x, y, 200, 200, 25)
		newButton:setFillColor(unpack(skinColors[i+1]))
		colorButtons[i] = newButton
	end

	for i=0, 3 do
		local x, y
		if (i % 2 == 0) then
			x = cW*0.30
		else
			x = cW*0.70
		end
		if (i<2) then
			y = (cW*0.20)+ccY+50
		else
			y = (cW*0.55)+ccY+50
		end

		local newButton = display.newImageRect(sceneGroup, "skin"..tostring(i+1)..".png",200, 200)
		newButton.x = x; newButton.y = y
		newButton:setFillColor(unpack(skinColor))
		skinButtons[i] = newButton
	end


end


function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

		backButton:addEventListener("tap", onBackButtonPress) -- Binf event listers to handlers
		colorButtons[0]:addEventListener("tap", UC0)
		colorButtons[1]:addEventListener("tap", UC1)
		colorButtons[2]:addEventListener("tap", UC2)
		colorButtons[3]:addEventListener("tap", UC3)
		skinButtons[0]:addEventListener("tap", US0)
		skinButtons[1]:addEventListener("tap", US1)
		skinButtons[2]:addEventListener("tap", US2)
		skinButtons[3]:addEventListener("tap", US3)

		skinTimer = timer.performWithDelay(10, moveSkinWidget, 0)

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

		saveData()



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
