
local composer = require( "composer" )

local scene = composer.newScene() --Set up for scene api/structure

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local ccX = display.contentCenterX -- Preinitialise utility and object related variables
local ccY = display.contentCenterY
local cH = display.contentHeight
local cW = display.contentWidth

local background
local title1
local title2
local title3

local skinWidget
local skinId = composer.getVariable("skin")
local skinTable = composer.getVariable("skinTable")
local skinColor = composer.getVariable("skinColor")
local skinTimer
local skinSpeed = 10

local playButton
local highscoresButton
local skinButton



--Event handlers for button interactions

local function onPlayButtonPress()

		timer.cancel(skinTimer)

		composer.gotoScene("game", {effect="slideUp", time = 500})
		timer.performWithDelay(550, function()
			composer.removeScene("menu")
		end)
end

local function onHighscoresButtonPress()

	timer.cancel(skinTimer)

	composer.setVariable("isFromGame", false)

	composer.gotoScene("highscores", {effect="slideDown", time = 500})
	timer.performWithDelay(550, function()
			composer.removeScene("menu")
		end)
end

local function onSkinButtonPress()

	timer.cancel(skinTimer)

	composer.gotoScene("skins", {effect="slideLeft", time = 500})
	timer.performWithDelay(550, function()
			composer.removeScene("menu")
		end)
end


local function moveSkinWidget() -- Function animates moving player 'icon'

	skinWidget.x = skinWidget.x + skinSpeed
	skinWidget.rotation = skinWidget.rotation + 2

	if (skinWidget.x > cW-75 or skinWidget.x < 75) then
			skinSpeed = -skinSpeed -- make skinWidget move in opposite direction if it comes to an end
	end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view

	-- Following code creates objects on screen

	background = display.newRect(sceneGroup, cW/4, ccY, ccX, cH)

	title1 = display.newText(sceneGroup, "sLi", ccX-85, 200, native.systemFont, 144)
	title1:setFillColor(0, 0, 0)
	title2 = display.newText(sceneGroup, "de", ccX+85, 200, native.systemFont, 144)

	title3 = display.newText(sceneGroup, "by Ibraheem Rodrigues", 25, cH-300, native.systemFont, 36)
	title3:setFillColor(0, 0, 0)
	title3.rotation = 270


	playButton = display.newImageRect(sceneGroup, "arrow.png", 250, 250)
	playButton.x=ccX; playButton.y = ccY

	skinButton = display.newImageRect(sceneGroup, "skins.png", 100, 100)
	skinButton.x = 3*cW/4; skinButton.y = 3*cH/4

	highscoresButton = display.newImageRect(sceneGroup, "mode.png", 100, 100)
	highscoresButton.x = cW/4; highscoresButton.y = 3*cH/4
	highscoresButton.rotation = 180


	skinWidget = display.newImageRect(sceneGroup, skinTable[skinId], 100, 100) -- Animated icons ; skinTable[skinId] gets user selected skin
	skinWidget.x=ccX; skinWidget.y=350
	skinWidget:setFillColor(unpack(skinColor)) -- Get current user selected color




end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then

		playButton:addEventListener("tap", onPlayButtonPress) -- Bind button interaction event listeners
		highscoresButton:addEventListener("tap", onHighscoresButtonPress)
		skinButton:addEventListener("tap", onSkinButtonPress)

		skinTimer = timer.performWithDelay(10, moveSkinWidget, 0) -- Start player 'icon' annimation

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen



	end
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
