#include "game.lua"
#include "options.lua"
#include "score.lua"
#include "debug.lua"
#include "promo.lua"
#include "ui_helpers.lua"
#include "script/challenge.lua"
#include "components/mod_browser_view.lua"
#include "components/challenges_view.lua"
#include "components/sandbox_view.lua"
#include "components/expansions_view.lua"
#include "components/mod_viewer.lua"
#include "components/eula.lua"
-- #include "components/mod_manager.lua"
#include "mods.lua"

bgItems = {nil, nil}
bgCurrent = 0
bgPromoIndex = {}

-- Context Menu
showContextMenu = false
showBuiltinContextMenu = false
showSubscribedContextMenu = false
getContextMousePos = false
contextItem = ""
contextPosX = 0
contextPosY = 0
contextScale = 0

gActivations = 0

promo_full_initiated = false

gForcedFocus = nil

-- Yes-No popup
yesNoPopup = 
{
	show = false,
	yes  = false,
	text = "",
	item = "",
	yes_fn = nil
}
function yesNoInit(text,item,fn)
	yesNoPopup.show = true
	yesNoPopup.yes  = false
	yesNoPopup.text = text
	yesNoPopup.item = item
	yesNoPopup.yes_fn = fn
end

function yesNo()
	local clicked = false
	UiModalBegin()
	UiPush()
		local w = 500
		local h = 160
		UiTranslate(UiCenter()-250, UiMiddle()-85)
		UiAlign("top left")
		UiWindow(w, h)
		UiColor(0.2, 0.2, 0.2)
		UiImageBox("common/box-solid-6.png", w, h, 6, 6)
		UiColor(1, 1, 1)
		UiImageBox("common/box-outline-6.png", w, h, 6, 6)

		if InputPressed("esc") then
			yesNoPopup.yes = false
			return true
		end

		UiColor(1,1,1,1)
		UiTranslate(16, 16)
		UiPush()
			UiTranslate(60, 20)
			UiFont("regular.ttf", 22)
			UiColor(1,1,1)
			UiText(yesNoPopup.text)
		UiPop()
		
		UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1)
		UiTranslate(77, 70)
		UiFont("regular.ttf", 22)
		UiColor(0.6, 0.2, 0.2)
		UiImageBox("common/box-solid-6.png", 140, 40, 6, 6)
		UiFont("regular.ttf", 26)
		UiColor(1,1,1,1)
		if UiTextButton("loc@UI_BUTTON_YES", 140, 40) then
			yesNoPopup.yes = true
			clicked = true
		end

		UiTranslate(170, 0)
		if UiTextButton("loc@UI_BUTTON_NO", 140, 40) then
			yesNoPopup.yes = false
			clicked = true
		end
	UiPop()
	UiModalEnd()
	return clicked
end

function deleteModCallback()
	if yesNoPopup.item ~= "" then
		Command("mods.delete", yesNoPopup.item)
		updateMods()
	end
end


function bgLoad(i)
	bg = {}
	bg.i = i+1
	bg.t = 0
	bg.x = 0
	bg.y = 0
	bg.vx = 0
	bg.vy = 0
	return bg
end


function bgDraw(bg)
	if bg then
		UiPush()
			local dt = GetTimeStep()
			bg.t = bg.t + dt
			local a = math.min(bg.t*0.6, 1.0)
			UiColor(1,1,1,a)
			UiScale(1.03 + bg.t*0.01)
			UiTranslate(bg.x, bg.y)
			if UiHasImage(slideshowImages[bg.i].image) then
				UiImage(slideshowImages[bg.i].image)
			end
		UiPop()
	end
end

bgIndex = 0
bgInterval = 6
bgTimer = bgInterval

function initSlideShowLevel(level)
	local i=1
	while UiHasImage("menu/slideshow/"..level..i..".jpg") do
		local item = {}
		item.image = "menu/slideshow/"..level..i..".jpg"
		item.promo = ""
		slideshowImages[#slideshowImages+1] = item
		i = i + 1
	end
end

function initSlideShowPromo()
	local groups = ListKeys("promo.groups")
	for i=1, #groups do
		local groupKey = "promo.groups."..groups[i]
		local items = ListKeys(groupKey.. ".items")
		for j=1, #items do
			local img = GetString(groupKey..".items."..items[j]..".full_image")
			if img ~= "" then
				local item = {}
				item.image = img
				item.promo = groupKey..".items."..items[j]
				slideshowImages[#slideshowImages+1] = item
				promoInitFull(item.promo)
			end
		end
	end

	bgPromoIndex[0] = #slideshowImages-1
	bgPromoIndex[1] = 1
end

function initSlideshow()
	slideshowImages = {}
	initSlideShowLevel("hub")
	if isLevelUnlocked("lee") then
		initSlideShowLevel("lee")
	end
	if isLevelUnlocked("marina") then
		initSlideShowLevel("marina")
	end
	if isLevelUnlocked("mansion") then
		initSlideShowLevel("mansion")
	end
	if isLevelUnlocked("mall") then
		initSlideShowLevel("mall")
	end
	if isLevelUnlocked("caveisland") then
		initSlideShowLevel("caveisland")
	end
	if isLevelUnlocked("frustrum") then
		initSlideShowLevel("frustrum")
	end
	if isLevelUnlocked("carib") then
		initSlideShowLevel("carib")
	end
	if isLevelUnlocked("factory") then
		initSlideShowLevel("factory")
	end
	if isLevelUnlocked("cullington") then
		initSlideShowLevel("cullington")
	end
	if HasKey("savegame.mod.builtin-artvandals.cinematic.complete") then
		initSlideShowLevel("tillaggaryd")
	end

	--Scramble order
	for i=1, #slideshowImages do
		local j = math.random(1, #slideshowImages)
		local tmp = slideshowImages[j]
		slideshowImages[j] = slideshowImages[i]
		slideshowImages[i] = tmp
	end

	--Reset the slideshow ticker to point at first image with no previous image
	bgPromoIndex[0] = -1
	bgPromoIndex[1] = -1

	bgIndex = 0
	bgCurrent = 0
	bgItems[0] = bgLoad(bgIndex)
	bgItems[1] = nil
	bgTimer = bgInterval	
end

function resetAllWindows()
	gModSelected = ""
	gOptionsScale = 0
	gSandboxScale = 0
	gChallengesScale = 0
	gExpansionsScale =0
	gPlayScale = 0
	gModBrowserScale = 0

	gPlayDropdownShowRequest = false
	gPlayDropdownFullyOpened = false

	gCreateScale = 0
	gPublishScale = 0

	ChallengesView:init()
	SandboxView:init()
	ExpansionsView:init()

	-- ModManager.Window.restoreOnFirsDraw = true
end

function init()
	initSlideshow()
	resetAllWindows()
	
	local showLargeUI = GetBool("game.largeui")
	gUiScaleUpFactor = 1.0
    if showLargeUI then
		gUiScaleUpFactor = 1.2
	end

	gDeploy = GetBool("game.deploy")

	RegisterListenerTo(UI_NAVLIST_SELECT_ITEM, "onListSelectItem")
	RegisterListenerTo(UI_NAVLIST_ACTIVATE_SELECTED, "onListActivateSelected")
	handleIntent()
	options.Tabs:Init()

	-- preload fonts with common sizes
	UiFont("arial.ttf", 27)
	UiFont("regular.ttf", 26)
	UiFont("regular.ttf", 52)
	UiFont("medium.ttf", 26)
	UiFont("medium.ttf", 52)
	UiFont("bold.ttf", 26)
	UiFont("bold.ttf", 52)
end


function isLevelUnlocked(level)
	local missions = ListKeys("savegame.mission")
	for i=1,#missions do
		local missionId = missions[i]
		if gMissions[missionId] and GetBool("savegame.mission."..missionId) then
			if missionId ~= "mall_intro" and missionId ~= "factory_espionage" and gMissions[missionId].level == level then
				return true
			end
		end
	end
	return false
end

function UiTextAligned(str)
	UiPush()
	for line in str:gmatch("[^\n]+") do
		local _, h = UiGetTextSize(line)
		UiText(line)
		UiTranslate(0, h)
	end
	UiPop()
end



--Return list of challenges for level, sorted alphabetically with unlocked first
function getChallengesForLevel(level)
	local ret = {}
	local locked = {}
	for id, ch in pairs(gChallenges) do
		if ch.level == level then
			if isChallengeUnlocked(id) then
				ret[#ret+1] = id
			else
				locked[#locked+1] = id
			end
		end
	end
	table.sort(ret, function(a,b) return gChallenges[a].title < gChallenges[b].title end)
	table.sort(locked, function(a,b) return gChallenges[a].title < gChallenges[b].title end)
	for i=1,#locked do 
		ret[#ret+1] = locked[i]
	end
	return ret
end


function isChallengeUnlocked(id)
	local c = gChallenges[id]
	if c.unlockMission then
		return GetInt("savegame.mission." .. c.unlockMission .. ".score") > 0
	end
	return true
end


function getChallengeScore(id)
	return GetInt("savegame.challenge." .. id .. ".score")
end


function getChallengeStars(id)
	return GetInt("savegame.challenge." .. id .. ".stars")
end


function getChallengeType(id)
	local challengeType = GetString("savegame.challenge." .. id .. ".type")
	
	if challengeType == "" then
		if string.find(gChallenges[id].layers, "hunted") then
			challengeType = "hunted"
		elseif string.find(gChallenges[id].layers, "mayhem") then
			challengeType = "mayhem"
		elseif string.find(gChallenges[id].layers, "fetch") then
			challengeType = "fetch"
		end
	end
	
	return challengeType
end


function getChallengeTimeleft(id)
	timeleft = GetFloat("savegame.challenge." .. id .. ".timeleft")
	
	if timeleft ~= 0 then
		timeleft = math.ceil(timeleft*100)/100
	elseif string.find(gChallenges[id].layers, "fetch") then
		local result = {}
		local scoredetails = GetString("savegame.challenge." .. id .. ".scoredetails")
		for parameter in string.gmatch(scoredetails, '%d+') do
			result[#result+1] = parameter
		end
		timeleft = result[2]
	end
	
	return timeleft
end


function isAnyWindowShown()
	return gOptionsScale > 0 or
		   gSandboxScale > 0 or
		   gChallengesScale > 0 or
		   gExpansionsScale > 0 or 
		   gModBrowserScale > 0 or
		   gCreateScale > 0 or
		   ModViewer.visible == true or -- we use .visible instead of .isClosed, because we want check animation too
		   Promo.Window.visible == true
end


MainMenuButtons = {}
MainMenuButtons.width = 250
MainMenuButtons.height = 48
MainMenuButtons.totalWidth = 820
MainMenuButtons.PlayDropDown = {}
MainMenuButtons.PlayDropDown.contentHeight = 350

MainMenuButtons.drawGamepadHint = function()
	if isAnyWindowShown() then
		return
	end

	UiPush()
		safeCanvas = UiSafeCanvasSize()
		realCanvas = UiCanvasSize()

		UiPush()
			UiTranslateToScreenBottomEdge(0, -160)
			UiColor(1,1,1)
			UiImage("menu/bottom-gradient.png")
		UiPop()

		UiTranslateToScreenBottomEdge(0, -(realCanvas.h - safeCanvas.h) / 2 - 70)
		UiTranslateToScreenLeftEdge(103, 0)
		UiColor(1, 1, 1, 1)
		UiDrawGamepadHintsLeftAlign({
			{ ico="[[menu:menu_accept;iconsize=42,42]]", txt="loc@UI_CREATIVE_SELECT" }
		})
	UiPop()
end

function mainMenu()
	UiPush()
		local topMenuBackgroundHeight = 152
		local logoOffsetX = 45

		UiAlign("top left")

		UiColor(0,0,0, 0.75)
		UiRect(UiWidth(), topMenuBackgroundHeight)
		UiColor(1,1,1)
		UiPush()
			UiTranslate(logoOffsetX, 38)
			UiScale(0.43)
			UiImage("menu/logo.png")
		UiPop()
		UiFont("regular.ttf", 36)

		UiPush()
			UiAlign("middle left")
			UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 0.96, 0.96, 0.96)
			UiColor(0.96, 0.96, 0.96)

			local buttons = {}
			table.insert(buttons,
				{ 
					["loc@UI_BUTTON_PLAY"] = {
						cmd = function()
							if gPlayScale == 0 then
								SetValue("gPlayScale", 1.0, "easeout", 0.25)
								gPlayDropdownShowRequest = true
							else
								SetValue("gPlayScale", 0.0, "easein", 0.25)
							end
						end
					}
				})

			table.insert(buttons,
				{
					["loc@UI_BUTTON_OPTIONS"] = {
						cmd = function()
								SetValue("gOptionsScale", 1.0, "easeout", 0.25)
								SetValue("gPlayScale", 0.0, "easein", 0.25)
						end

					}
				})

			table.insert(buttons,
				{
					["loc@UI_BUTTON_CREDITS"] = {
						cmd = function()
							StartLevel("about", "about.xml")
							SetValue("gPlayScale", 0.0, "easein", 0.25)
						end

					}
				})

			if IsRunningOnPC() then
				table.insert(buttons,
				{
					["loc@UI_BUTTON_QUIT"] = {
						cmd = function()
							Command("game.quit")
							SetValue("gPlayScale", 0.0, "easein", 0.25)
						end
					}

				})
			end

			local buttonsIndent = 36
			local menuBarOffset = (UiCanvasSize().w - #buttons*MainMenuButtons.width - (#buttons-1)*buttonsIndent)/2
			menuBarOffset = menuBarOffset + (#buttons-3)*36

			if IsRunningOnPC() then
				menuBarOffset = menuBarOffset + 150
			else
				menuBarOffset =  menuBarOffset + 166
			end
			UiTranslate(menuBarOffset, topMenuBackgroundHeight/2)

			for index, value in pairs(buttons) do
				UiPush()
				UiButtonHoverColor(1,1,0.5,1)	
				for buttonName, button in pairs(value) do
					if UiTextButton(buttonName, MainMenuButtons.width, MainMenuButtons.height) then
						UiSound("common/click.ogg")
						button.cmd()
					end
				end
				UiPop()
				UiTranslate(MainMenuButtons.width + buttonsIndent, 0)
			end
		UiPop()
	UiPop()

	if gPlayScale > 0 then
		local bw = 230
		local bh = 40
		local bo = 48
		local padding = 25
		local specialIndent = 22
		local bgWidth = 280
		local bgHeight = MainMenuButtons.PlayDropDown.contentHeight + padding * 2
		UiPush()
			if gPlayScale < 1.0 then 
				UiNavSkipUpdate()
				gPlayDropdownFullyOpened = false
			end

			if gPlayScale == 1.0 and InputPressed("menu_cancel") then
				SetValue("gPlayScale", 0.0, "easein", 0.25)
			end

			UiButtonHoverColor(1,1,0.5,1)
		 	local playMenuOffset = menuBarOffset - (bgWidth - MainMenuButtons.width) / 2
			UiTranslate(playMenuOffset, topMenuBackgroundHeight + 10)
			UiScale(1, gPlayScale)
			UiColorFilter(1,1,1,gPlayScale)

			if gPlayScale < 0.5 then
				UiColorFilter(1, 1, 1, gPlayScale * 2)
			end

			UiColor(0,0,0,0.75)
			UiFont("regular.ttf", 26)
			UiImageBox("common/box-solid-10.png", bgWidth, bgHeight, 10, 10)
			UiColor(1,1,1)
			UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1)

			UiColor(0.96, 0.96, 0.96)
			UiAlign("top left")
			UiTranslate(padding, padding)

			local gId = UiNavGroupBegin()

			local navReleased = WasAnyActionReleased(
				{
					"menu_up",
					"menu_down", 
					"menu_left", 
					"menu_right"
				})

			if gPlayDropdownFullyOpened and (not UiIsComponentInFocus(gId)) and navReleased then
				-- hide the dropdown
				SetValue("gPlayScale", 0.0, "easein", 0.25)
			end

			UiBeginFrame()

			if UiTextButton("loc@UI_BUTTON_CAMPAIGN", bw, bh) then
				UiSound("common/click.ogg")
				startHub()
			end	
			UiTranslate(0, bo)

			if UiTextButton("loc@UI_BUTTON_SANDBOX", bw, bh) then
				UiSound("common/click.ogg")
				openSandboxMenu()
			end			
			UiTranslate(0, bo)

			if UiTextButton("loc@UI_BUTTON_CHALLENGES", bw, bh) then
				UiSound("common/click.ogg")
				openChallengesMenu()
			end			
			UiTranslate(0, bo)
			
			if UiTextButton(GetTranslatedStringByKey("UI_BUTTON_EXPANSIONS"), bw, bh) then
				gForcedFocus = UiFocusedComponentId()
				UiSound("common/click.ogg")
				openExpansionsMenu()
			end		
			UiTranslate(0, bo)
			UiTranslate(0, specialIndent)
		
			if IsRunningOnPC() or GetBool("options.debug.mods") then

				if GetBool("options.debug.mods") then
					if UiTextButton("Mod browser", bw, bh) then
						UiSound("common/click.ogg")
						SetValue("gModBrowserScale", 1, "cosine", 0.25)
					end
					UiTranslate(0, bo)
				end

				UiPush()
					if not GetBool("promo.available") then
						UiDisableInput()
						UiIgnoreNavigation()
						UiColorFilter(1,1,1,0.5)
					end
					if UiTextButton("loc@UI_BUTTON_FEATURED_MODS", bw, bh) then
						gForcedFocus = UiFocusedComponentId()
						UiSound("common/click.ogg")
						Promo.Window:show()
					end
					if GetBool("savegame.promoupdated") then
						UiPush()
							UiTranslate(bw, 0)
							UiAlign("center middle")
							UiImage("menu/promo-notification.png")
						UiPop()
					end
				UiPop()
				UiTranslate(0, bo)

				if UiTextButton("loc@UI_BUTTON_MOD_MANAGER", bw, bh) then
					gForcedFocus = UiFocusedComponentId()
					UiSound("common/click.ogg")
					openModsMenu()
				end
				UiTranslate(0, bo)
			end

			if IsRunningOnPlaystation() or IsRunningOnXbox() then
				if UiTextButton("loc@UI_MOD_BROWSER", bw, bh) then
					Command("mods.refresh")
					gForcedFocus = UiFocusedComponentId()
					UiSound("common/click.ogg")
					ModViewer:show()
				end
			end

			_, MainMenuButtons.PlayDropDown.contentHeight = UiEndFrame()
			UiNavGroupEnd()

			if gPlayScale == 1.0 and gPlayDropdownShowRequest == true then
				gPlayDropdownShowRequest = false
				gPlayDropdownFullyOpened = true
				UiForceFocus(gId)
			end

			-- if we returning from window, which opened by button from "Play dropdown", we must refocus to that button
			if not isAnyWindowShown() then
				if gForcedFocus ~= nil and UiFocusedComponentId() ~= gForcedFocus then
					UiForceFocus(gForcedFocus)
				else
					gForcedFocus = nil
				end
			end
		UiPop()
	end
	if gSandboxScale > 0 then
		UiPush()
			UiBlur(gSandboxScale)
			UiColor(0.7,0.7,0.7, 0.25*gSandboxScale)
			UiRect(UiWidth(), UiHeight())
			if not drawSandbox(gSandboxScale) then
				SetValue("gSandboxScale", 0, "cosine", 0.25)
			end
		UiPop()
	end
	if gChallengesScale > 0 then
		UiPush()
			UiBlur(gChallengesScale)
			UiColor(0.7,0.7,0.7, 0.25*gChallengesScale)
			UiRect(UiWidth(), UiHeight())
			if not drawChallenges(gChallengesScale) then
				SetValue("gChallengesScale", 0, "cosine", 0.25)
			end
		UiPop()
	end
	if gExpansionsScale> 0 then
		UiPush()
			UiBlur(gExpansionsScale)
			UiColor(0.7,0.7,0.7, 0.25 * gExpansionsScale)
			UiRect(UiWidth(), UiHeight())
			UiModalBegin()
			if not drawExpansions(gExpansionsScale) then
				SetValue("gExpansionsScale", 0, "cosine", 0.25)
			end
			UiModalEnd()
		UiPop()
	end
	if gOptionsScale > 0 then
		UiPush()
			UiBlur(gOptionsScale)
			UiColor(0.7,0.7,0.7, 0.25 * gOptionsScale)
			UiRect(UiWidth(), UiHeight())
			UiModalBegin()
			SetBool("game.menu.active", true)
			if not drawOptions(gOptionsScale) then
				SetValue("gOptionsScale", 0, "cosine", 0.25)
			end
			UiModalEnd()
		UiPop()
	end
	if gModBrowserScale > 0 then
		UiPush()
			UiBlur(gModBrowserScale)
			UiColor(0.7, 0.7, 0.7, 0.25 * gModBrowserScale)
			UiRect(UiWidth(), UiHeight())
			UiModalBegin()
			drawModBrowser()
			UiModalEnd()
		UiPop()
	end
	if gCreateScale > 0 then
		UiPush()
			UiBlur(gCreateScale-gPublishScale)
			UiColor(0.7,0.7,0.7, 0.25*gCreateScale)
			UiRect(UiWidth(), UiHeight())
			UiModalBegin()
			if not drawCreate(gCreateScale) then
				SetValue("gCreateScale", 0, "cosine", 0.25)
			end
			UiModalEnd()
		UiPop()
	end
end


function tick()
	if GetTime() > 0.1 then
		if gActivations >= 2 then
			PlayMusic("menu-long.ogg")
		else
			PlayMusic("menu.ogg")
		end
		SetFloat("game.music.volume", (1.0 - 0.8*gCreateScale))
	end

end


function drawBackground()
	if promo_full_initiated == false and GetBool("promo.available") and GetInt("savegame.startcount") >= 5 then
		promo_full_initiated = true
		initSlideShowPromo()
	end

	UiPush()
		if bgTimer >= 0 then
			bgTimer = bgTimer - GetTimeStep()
			if bgTimer < 0 then
				bgIndex = math.mod(bgIndex + 1, #slideshowImages)
				if bgPromoIndex[0] >= 0 then
					bgIndex = bgPromoIndex[0]
					bgPromoIndex[0] = bgPromoIndex[1]
					bgPromoIndex[1] = -1
				end
				bgTimer = bgInterval

				bgCurrent = 1-bgCurrent
				local oldItem = bgItems[bgCurrent];
				bgItems[bgCurrent] = bgLoad(bgIndex)

				if oldItem then
					UiUnloadImage(slideshowImages[oldItem.i].image)
				end
			end
		end

		UiTranslate(UiCenter(), UiMiddle())
		UiAlign("center middle")
		bgDraw(bgItems[1-bgCurrent])
		bgDraw(bgItems[bgCurrent])
	UiPop()
end


function draw()
	local wasEulaShown = GetBool("savegame.waseulashown")
	if not wasEulaShown and EULA.Window.isClosed and not IsRunningOnPC() then
		EULA.Window:show()
	end

	-- if ModManager.Window.restoreOnFirsDraw and ModManager.Window.canRestore() then
	-- 	ModManager.Window:restore()
	-- end
	-- ModManager.Window.restoreOnFirsDraw = false
	
	UiButtonHoverColor(0.8,0.8,0.8,1)
	-- for main menu we do now want to draw a cursor
	if LastInputDevice() == UI_DEVICE_GAMEPAD then
		UiSetCursorState(UI_CURSOR_HIDE_AND_LOCK)	
	end

	UiPush()
		--Create a safe 1920x1080 window that will always be visible on screen
		local x0,y0,x1,y1 = UiSafeMargins()
		UiTranslate(x0,y0)
		UiWindow(x1-x0,y1-y0, true)

		drawBackground()
		mainMenu()

		if LastInputDevice() == UI_DEVICE_GAMEPAD then
			MainMenuButtons.drawGamepadHint()
		end
		
	UiPop()

	if not gDeploy and mainMenuDebug then
		mainMenuDebug()
	end

	UiPush()
		UiIgnoreNavigation()
		local version = GetString("game.version")
		local patch = GetString("game.version.patch")
		if patch ~= "" then
			version = version .. " (" .. patch .. ")"
		end
		UiTranslate(UiWidth()-10, UiHeight()-10)
		UiFont("regular.ttf", 18)
		UiAlign("right")
		UiColor(1,1,1,0.5)
		if UiTextButton(version) then
			Command("game.openurl", "http://teardowngame.com/changelog/?version="..GetString("game.version"))
		end
	UiPop()

	--TODO: move to a different place
	if gCreateScale > 0 and GetBool("game.saveerror") then
		UiDrawLater({
			draw = function(self)
				UiPush()
				UiColorFilter(1, 1, 1, gCreateScale)
				UiFont("bold.ttf", 20)
				UiTextOutline(0, 0, 0, 1, 0.1)
				UiColor(1,1,.5)
				UiAlign("center")
				UiTranslate(UiCenter(), UiHeight() - 100)
				UiWordWrap(600)
				UiTextAlignment("center")
				UiText("loc@UI_TEXT_TEARDOWN_WAS")
			UiPop()
			end
		})
	end

	drawLocalUserTag()
end


function handleCommand(cmd)
	if cmd == "opendisplayoptions" then
		gOptionsScale = 1
		optionsTab = "display"
	end
	if cmd == "activate" then
		initSlideshow()
		gActivations = gActivations + 1
		SetPresence("main_menu")
	end
	-- if cmd == "updatemods" then
	-- 	ModManager.Window:refresh()
	-- end
	if cmd == "intent" then
		handleIntent()
	end
	if cmd == "start" then
		SetInt("savegame.startcount", GetInt("savegame.startcount")+1)
		resetActivities()
	end
end

function handleIntent()
	local intent = GetString("options.intent")
	local state = GetString("game.state")
	if intent ~= "" then
		if intent == "campaign" then
			resumeCampaign()
		elseif intent == "challenge_mansion_race" then
			tryStartMission("mansion_race")
		elseif intent == "sandbox" then
			if state ~= "MENU" then
				Menu()
				return
			else
				resetAllWindows()
				openSandboxMenu()
			end
		elseif intent == "challenges" or string.sub(intent, 1, 10) == "challenge_" then
			if state ~= "MENU" then
				Menu()
				return
			else
				resetAllWindows()
				openChallengesMenu()
			end
		elseif string.sub(intent, 1, 8) == "usedmods" or string.sub(intent, 1, 15) == "usedcustomtools" then
			if state ~= "MENU" then
				Menu()
				return
			else
				resetAllWindows()
				openModsMenu()
			end
		elseif string.sub(intent, 1, 3) == "ch_" then
			tryStartChallenge(intent)
		elseif string.sub(intent, -8) == "_sandbox" then
			tryStartSandbox(intent)
		else
			tryStartMission(intent)
		end
		SetString("options.intent", "")
	end
end


function resumeCampaign()
	-- find next mission: opened but without required score
	-- otherwise start hub
	for id,mission in pairs(gMissions) do
		if GetInt("savegame.mission."..id) > 0 and GetInt("savegame.mission."..id..".score") < mission.required then
			ResumeLevel(id, mission.file, mission.layers, "quicksavecampaign")
			return
		end
	end
	startHub()
end


function tryStartMission(id)
	local suf = string.sub(id, -4)
	if suf == "_opt" then
		id = string.sub(id, 1, -4)
	end
	if gMissions[id] and GetInt("savegame.mission."..id) > 0 then
		StartLevel(id, gMissions[id].file, gMissions[id].layers)
	end
end


function tryStartChallenge(id)
	local stars = string.sub(id, -2)
	if stars == "_1" or stars == "_2" or stars == "_3" or stars == "_4" or stars == "_5" then
		id = string.sub(id, 1, -2)
	end
	if gChallenges[id] and isChallengeUnlocked(id) then
		StartLevel(id, gChallenges[id].file, gChallenges[id].layers)
	end
end


function tryStartSandbox(id)
	for i=1, #gSandbox do
		if id == gSandbox[i].id then
			StartLevel(id, gSandbox[i].file, gSandbox[i].layers)
		end
	end
end


function openChallengesMenu()
	ChallengesView:reset()
	SetValue("gChallengesScale", 1, "cosine", 0.25)
end


function openSandboxMenu()
	SandboxView:reset()
	SetValue("gSandboxScale", 1, "cosine", 0.25)
end


function openModsMenu()
	SetValue("gCreateScale", 1, "cosine", 0.25)
end


function openExpansionsMenu()
	ExpansionsView:init()
	SetValue("gExpansionsScale", 1, "cosine", 0.25)

	gChallengeLevel = ""
	gChallengeLevelScale = 0
end