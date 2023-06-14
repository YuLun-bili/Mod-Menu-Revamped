#include "game.lua"
#include "options.lua"
#include "score.lua"
#include "debug.lua"
#include "promo.lua"

#include "mods.lua"

bgItems = {nil, nil}
bgCurrent = 0
bgPromoIndex = {}

-- Context Menu
getContextMousePos = false
contextItem = ""
contextPosX = 0
contextPosY = 0
contextScale = 0

gActivations = 0

promo_full_initiated = false


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
			if HasFile(slideshowImages[bg.i].image) then
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
	while HasFile("menu/slideshow/"..level..i..".jpg") do
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

function init()
	SetInt("savegame.startcount", GetInt("savegame.startcount")+1)
	transferCollection()

	gMods = {}
	for i=1,3 do
		gMods[i] = {}
		gMods[i].items = {}
		gMods[i].pos = 0
		gMods[i].possmooth = 0
		gMods[i].sort = 0
		gMods[i].sortInv = false
		gMods[i].filter = 0
		gMods[i].dragstarty = 0
		gMods[i].isdragging = false
	end
	gMods[1].title = "Built-In"
	gMods[2].title = "Subscribed"
	gMods[3].title = "Local files"
	gModSelected = ""
	gModSelectedScale = 0
	updateMods()

	gCollections = {}
	updateCollections()
	gCollectionList = {}
	collectionReset()
	gCollectionMain = {
		pos = 0,
		possmooth = 0,
		sort = 0,
		sortInv = false,
		filter = 0,
		dragstarty = 0,
		isdragging = false,
	}
	gCollectionSelected = 0
	gCollectionTyping = false
	gCollectionFocus = false
	gCollectionRename = false
	gCollectionClick = false
	gCollectionName = ""
	gCollectMod = ""

	gSearchTyping = false
	gSearchFocus = false
	gSearchClick = false
	gSearchText = ""
	gSearch = {
		items = {},
		pos = 0,
		possmooth = 0,
		sortInv = false,
		filter = 0,
		dragstarty = 0,
		isdragging = false
	}

	gLoadedPreview = ""
	gLargePreview = 0
	gQuitLarge = false

	initSlideshow()

	gOptionsScale = 0
	gSandboxScale = 0
	gChallengesScale = 0
	gExpansionsScale = 0  
	gPlayScale = 0
	
	gChallengeLevel = ""
	gChallengeLevelScale = 0
	gChallengeSelected = ""

	gCreateScale = 0
	gPublishScale = 0
	
	local showLargeUI = GetBool("game.largeui")
	gUiScaleUpFactor = 1.0
    if showLargeUI then
		gUiScaleUpFactor = 1.2
	end

	gDeploy = GetBool("game.deploy")
end


function isLevelUnlocked(level)
	local missions = ListKeys("savegame.mission")
	local levelMissions = {}
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


function selectLevel(selected, alwaysUnlocked, challenges)
	if not gLevelSelectScroll then
		gLevelSelectScroll = 0
		SetValue("gLevelSelectScroll", 1, "cosine", 0.5)
	end
	if not selected then selected = "" end
	local ret = selected
	local visibleLevels = 0
	UiPush()
		local w = 740
		UiTranslate(60, 0)
		UiWindow(w, 200, true)
		UiTranslate(150 - gLevelSelectScroll*150, 0)
		for i=1, #gSandbox do
			local level = gSandbox[i].level
			local image = gSandbox[i].image
			local name = gSandbox[i].name
			local show = true
			if challenges and (level == "cullington" or level == "hub_carib") then
				show = false
			end
			if show then
				UiPush()
					if visibleLevels+1 < gLevelSelectScroll or visibleLevels+1 > gLevelSelectScroll + 4 then
						UiDisableInput()
					end
					local locked = not (isLevelUnlocked(level) or alwaysUnlocked)

					-- Carib hub is a special case since it doesn't contain any missions to check against, so unlocking once the travel email is recieved
					if level == "hub_carib" and GetInt("savegame.message.carib_travel") > 0 then 
						locked = false 
					end

					UiPush()
						if locked then
							UiDisableInput()
							UiColorFilter(.5, .5, .5)
						end
						if level ~= selected and selected ~= "" then
							UiColorFilter(1,1,1,0.5)
						end
						if UiImageButton(image) then
							UiSound("common/click.ogg")
							ret = level
						end
					UiPop()
					if locked then
						UiPush()
							UiTranslate(64, 64)
							UiAlign("center middle")
							UiImage("menu/locked.png")
						UiPop()
						if UiIsMouseInRect(128, 128) then
							UiPush()
								UiAlign("center middle")
								UiTranslate(64,  180)
								UiFont("regular.ttf", 18)
								UiColor(.8, .8, .8)
								UiText("Play campaign or\nunlock in options")
							UiPop()
						end
					end

					UiAlign("center")
					UiTranslate(64, 150)
					if level == selected then
						UiColor(0.8, 0.8, 0.8)
						UiFont("bold.ttf", 22)
					else
						UiColor(0.8, 0.8, 0.8)
						UiFont("regular.ttf", 22)
					end
					UiText(name)
				UiPop()
				UiTranslate(150, 0)
				visibleLevels = visibleLevels + 1
			end
		end
	UiPop()
	UiPush()
		UiPush()
			if gLevelSelectScroll > 1 then
				UiColor(1,1,1, 0.8)
			else
				UiColor(1,1,1, 0.1)
				UiDisableInput()
			end
			UiTranslate(15, 40)
			if UiImageButton("menu/arrow-left.png") or InputPressed("left") or InputPressed("leftarrow") then
				SetValue("gLevelSelectScroll", 1, "cosine", 0.3)
			end
		UiPop()
		UiPush()
			if gLevelSelectScroll < visibleLevels-4 then
				UiColor(1,1,1, 0.8)
			else
				UiColor(1,1,1, 0.1)
				UiDisableInput()
			end
			UiTranslate(810, 40)
			if UiImageButton("menu/arrow-right.png") or InputPressed("right") or InputPressed("rightarrow") then
				SetValue("gLevelSelectScroll", visibleLevels-4, "cosine", 0.3)
			end
		UiPop()
	UiPop()
	gLevelSelectScroll = math.min(gLevelSelectScroll, visibleLevels-4)
	return ret
end

function drawSandbox(scale)
	local open = true
	UiPush()
		local w = 840
		local h = 440
		UiTranslate(UiCenter(), UiMiddle())
		UiScale(scale*gUiScaleUpFactor)
		UiColorFilter(1, 1, 1, scale)
		UiColor(0,0,0, 0.5)
		UiAlign("center middle")
		UiImageBox("common/box-solid-shadow-50.png", w, h, -50, -50)
		UiWindow(w, h)
		UiAlign("left top")
		UiColor(1,1,1)
		if InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and InputPressed("lmb")) then
			open = false
		end

		UiPush()
			UiFont("bold.ttf", 48)
			UiColor(1,1,1)
			UiAlign("center")
			UiTranslate(UiCenter(), 80)
			UiText("SANDBOX")
		UiPop()
		
		UiPush()
			UiFont("regular.ttf", 22)
			local tw, th = UiGetTextSize("Free roam sandbox play with unlimited resources and no challenge.")
			UiTranslate(w/2 - tw/2, 90)
			UiWordWrap(tw)
			UiColor(0.8, 0.8, 0.8)
			UiText("Free roam sandbox play with unlimited resources and no challenge.Play the campaign to unlock more environments and tools. If you want to unlock everything without playing through the campaign you can enable that in the                  menu.")
			UiTranslate(212, 66)
			UiColor(1, 0.95, .7)
			if UiTextButton("options") then
				optionsTab = "game"
				SetValue("gOptionsScale", 1.0, "easeout", 0.25)
			end
		UiPop()

		UiPush()
			UiTranslate(0, 220)
			local selected = selectLevel(nil, GetInt("options.game.sandbox.unlocklevels") == 1, false)
			if selected then
				for i=1, #gSandbox do
					if selected == gSandbox[i].level then
						StartLevel(gSandbox[i].id, gSandbox[i].file, gSandbox[i].layers)
					end
				end
			end
		UiPop()

	UiPop()
	return open
end

function drawExpansions(scale)
	local open = true
	UiPush()
		local w = 840
		local h = 440
		UiTranslate(UiCenter(), UiMiddle())
		UiScale(scale*gUiScaleUpFactor)
		UiColorFilter(1, 1, 1, scale)
		UiColor(0,0,0, 0.5)
		UiAlign("center middle")
		UiImageBox("common/box-solid-shadow-50.png", w, h, -50, -50)
		UiWindow(w, h)
		UiAlign("left top")
		UiColor(1,1,1)
		if InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and InputPressed("lmb")) then
			open = false
		end

		UiPush()
			UiFont("bold.ttf", 48)
			UiColor(1,1,1)
			UiAlign("center")
			UiTranslate(UiCenter(), 80)
			UiText("EXPANSIONS")
		UiPop()
		
		UiPush()
			UiFont("regular.ttf", 22)
			local tw = 550
			UiTranslate(w/2 - tw/2 + 20, 90)
			UiWordWrap(tw)
			UiColor(0.8, 0.8, 0.8)
			UiText("Expansions are created by the Teardown team. You are welcome to play them at any time, but they are intended to be played once the campaign is finished.")
		UiPop()

		UiPush()
			local w = 740
			UiTranslate(70, 220)
			UiWindow(w, 200, true)
			UiTranslate(w/2-10-75*#gExpansions, 0)
			for i=1, #gExpansions do
				local level = gExpansions[i].level
				local image = gExpansions[i].image
				local name = gExpansions[i].name
				local available = gExpansions[i].available
				UiPush()
					UiPush()
						if not available then
							UiDisableInput()
							UiColorFilter(.5, .5, .5)
						end
						UiTranslate(-50, 0)
						if UiImageButton(image) then
							UiSound("common/click.ogg")
							Command("mods.play", level)
						end
					UiPop()
					if not available then
						UiPush()
							UiTranslate(64, 64)
							UiAlign("center middle")
							UiImage("menu/locked.png")
						UiPop()
						if UiIsMouseInRect(128, 128) then
							UiPush()
								UiAlign("center middle")
								UiTranslate(64,  180)
								UiFont("regular.ttf", 20)
								UiColor(.8, .8, .8)
								UiText("Coming soon")
							UiPop()
						end
					end

					UiAlign("center")
					UiTranslate(64, 150)
					UiColor(0.8, 0.8, 0.8)
					UiFont("regular.ttf", 22)
					UiText(name)
				UiPop()
				UiTranslate(150, 0)
			end
		UiPop()
	UiPop()
	return open
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


function getChallengeStars(id)
	return GetInt("savegame.challenge." .. id .. ".stars")
end


function getChallengeScoreDetails(id)
	return GetString("savegame.challenge." .. id .. ".scoredetails")
end


function drawChallenges(scale)
	local open = true
	UiPush()
		local w = 840
		local h = 400 + gChallengeLevelScale*300
		UiTranslate(UiCenter(), UiMiddle())
		UiScale(scale*gUiScaleUpFactor)
		UiColorFilter(1, 1, 1, scale)
		UiColor(0,0,0, 0.5)
		UiAlign("center middle")
		UiImageBox("common/box-solid-shadow-50.png", w, h, -50, -50)
		UiWindow(w, h)
		UiAlign("left top")
		UiColor(1,1,1)
		if InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and InputPressed("lmb")) then
			open = false
		end

		UiPush()
			UiFont("bold.ttf", 48)
			UiColor(1,1,1)
			UiAlign("center")
			UiTranslate(UiCenter(), 80)
			UiText("CHALLENGES")
		UiPop()
		
		UiPush()
			UiFont("regular.ttf", 22)
			local tw, th = UiGetTextSize("You play challenges with the same tools and upgrades you have unlocked in the campaign.")
			UiTranslate(w/2 - tw/2, 90)
			UiWordWrap(tw)
			UiColor(0.8, 0.8, 0.8)
			UiText("Challenges are experimental game modes where you can try out your skills. Unlock new environments and challenges by playing the campaign. You play challenges with the same tools and upgrades you have unlocked in the campaign.")
		UiPop()
	
		UiPush()
			UiTranslate(0, 190)
			local selected = selectLevel(gChallengeLevel, false, true)
			if selected ~= gChallengeLevel then
				SetValue("gChallengeLevelScale", 1, "cosine", 0.25)
				gChallengeLevel = selected
				gChallengeSelected = ""
			end
		UiPop()
		
		UiTranslate(34, 400)
		if gChallengeLevelScale > 0 then
			UiPush()
				UiScale(1, gChallengeLevelScale)
				UiColor(1,1,1)
				UiPush()
					UiPush()
						UiTranslate(10, 0)
						UiFont("bold.ttf", 32)
						UiText("Challenge")
					UiPop()
					UiTranslate(0, 40)
					UiWindow(200, 200)
					UiColor(1,1,1,0.05)
					UiImageBox("common/box-solid-6.png", UiWidth(), UiHeight(), 6, 6)
					UiTranslate(10, 28)
					UiFont("regular.ttf", 22)
					UiColor(1,1,1)
					local list = getChallengesForLevel(gChallengeLevel)
					UiAlign("left")
					local lockedInfo = false
					if #list == 0 then
						UiColor(1, 1, 1, 0.5)
						UiTranslate(430, 80)
						UiText("Coming soon!")
					end
					for i=1, #list do
						local id = list[i]
						local mouseOver = false
						UiPush()
							local unlocked = isChallengeUnlocked(id)
							UiTranslate(-10, -18)
							UiColor(0,0,0,0)
							if gChallengeSelected == id then
								UiColor(1,1,1,0.1)
							else
								if UiIsMouseInRect(UiWidth(), 28) then
									mouseOver = true
									UiColor(0,0,0,0.1)
									if not unlocked then
										lockedInfo = true
									end
								end
							end
							if unlocked and mouseOver then
								if InputPressed("lmb") then
									UiSound("terminal/message-select.ogg")
									gChallengeSelected = id
								end
							end
							UiRect(UiWidth(), 28)
						UiPop()
						UiPush()
							if not unlocked then
								UiColor(1,1,1,0.5)
								UiPush()
									UiTranslate(170, -7)
									UiAlign("center middle")
									UiImage("menu/locked-small.png")
								UiPop()
							else
								local stars = getChallengeStars(id)
								if stars > 0 then
									UiPush()
										UiTranslate(170, -6)
										UiAlign("center middle")
										UiScale(0.6)
										for i=1,stars do
											UiImage("common/star.png")
											UiTranslate(-25, 0)
										end
									UiPop()
								end
							end
							UiTranslate(0, 2)
							UiText(gChallenges[id].title, true)
						UiPop()
						UiTranslate(0, 28)
					end
				UiPop()
				if lockedInfo then
					UiPush()
						UiAlign("center middle")
						UiTranslate(90,  270)
						UiFont("regular.ttf", 20)
						UiColor(.8, .8, .8)
						UiText("Unlocked in\ncampaign")
					UiPop()
				end
				UiPush()
					UiTranslate(250, 0)
					if gChallengeSelected ~= "" then
						UiPush()
							UiTranslate(10, 0)
							UiFont("bold.ttf", 32)
							UiText(gChallenges[gChallengeSelected].title)
						UiPop()
					end
					UiTranslate(0, 40)
					UiWindow(520, 200)
					UiColor(1,1,1,0.05)
					UiImageBox("common/box-solid-6.png", UiWidth(), UiHeight(), 6, 6)
					UiColor(1,1,1)

					if gChallengeSelected ~= "" then
						local challenge = gChallenges[gChallengeSelected]
						UiPush()
							UiTranslate(10, 10)
							UiFont("regular.ttf", 20)
							UiWordWrap(UiWidth()-20)
							UiText(challenge.desc)
						UiPop()
						local stars = getChallengeStars(gChallengeSelected)
						local details = getChallengeScoreDetails(gChallengeSelected)
						if stars > 0 or details ~= "" then
							UiPush()
								UiTranslate(20, 125)
								UiFont("regular.ttf", 20)
								UiPush()
									UiColor(1,1,0.5)
									for i=1,stars do
										UiImage("common/star.png")
										UiTranslate(25, 0)
									end
									for i=stars+1, 5 do
										UiImage("common/star-outline.png")
										UiTranslate(25, 0)
									end
								UiPop()
								UiTranslate(0, 30)
								UiText(details)
							UiPop()
						end
						UiPush()
							UiFont("regular.ttf", 26)
							UiTranslate(UiWidth()-120, UiHeight()-40)
							UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1, 0.7)
							UiAlign("center middle")	
							UiPush()
								UiColor(.7, 1, .8, 0.2)
								UiImageBox("common/box-solid-6.png", 200, 40, 6, 6)
							UiPop()
							if UiTextButton("Play", 200, 40) then
								StartLevel(gChallengeSelected, challenge.file, challenge.layers)
							end
						UiPop()	
					end
				UiPop()
			UiPop()
		end
	UiPop()
	return open
end


function selectMod(mod)
	gModSelected = mod
	if mod ~= "" then
		Command("mods.updateselecttime", gModSelected)
	Command("game.selectmod", gModSelected)
	end
end

function mainMenu()
	UiPush()
		UiColor(0,0,0, 0.75)
		UiRect(UiWidth(), 150)
		UiColor(1,1,1)
		UiPush()
			UiTranslate(50, 20)
			UiScale(0.8)
			UiImage("menu/logo.png")
		UiPop()
		UiFont("regular.ttf", 36)
		UiTranslate(800, 30)
		UiTranslate(0, 50)
		UiAlign("center middle")
		UiPush()
			UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 0.96, 0.96, 0.96)
			UiColor(0.96, 0.96, 0.96)
			local bh = 50
			local bo = 56

			UiPush()
				if UiTextButton("Play", 250, bh) then
					UiSound("common/click.ogg")
					if gPlayScale == 0 then
						SetValue("gPlayScale", 1.0, "easeout", 0.25)
					else
						SetValue("gPlayScale", 0.0, "easein", 0.25)
					end
				end
			UiPop()

			UiTranslate(300, 0)

			UiPush()
				if UiTextButton("Options", 250, bh) then
					UiSound("common/click.ogg")
					SetValue("gOptionsScale", 1.0, "easeout", 0.25)
					SetValue("gPlayScale", 0.0, "easein", 0.25)
				end
			UiPop()

			UiTranslate(300, 0)

			UiPush()
				if UiTextButton("Credits", 250, bh) then
					UiSound("common/click.ogg")
					StartLevel("about", "about.xml")
					SetValue("gPlayScale", 0.0, "easein", 0.25)
				end
			UiPop()
				
			UiTranslate(300, 0)

			UiPush()
				if UiTextButton("Quit", 250, bh) then
					UiSound("common/click.ogg")
					Command("game.quit")
					SetValue("gPlayScale", 0.0, "easein", 0.25)
				end
			UiPop()
		UiPop()
	UiPop()

	if gPlayScale > 0 then
		local bw = 206
		local bh = 40
		local bo = 48
		UiPush()
			UiTranslate(672, 160)
			UiScale(1, gPlayScale)
			UiColorFilter(1,1,1,gPlayScale)
			if gPlayScale < 0.5 then
				UiColorFilter(1,1,1,gPlayScale*2)
			end
			UiColor(0,0,0,0.75)
			UiFont("regular.ttf", 26)
			UiImageBox("common/box-solid-10.png", 256, 352, 10, 10)
			UiColor(1,1,1)
			UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1)

			UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 0.96, 0.96, 0.96)
			UiColor(0.96, 0.96, 0.96)

			UiAlign("top left")
			UiTranslate(25, 25)

			if UiTextButton("Campaign", bw, bh) then
				UiSound("common/click.ogg")
				startHub()
			end	
			UiTranslate(0, bo)

			if UiTextButton("Sandbox", bw, bh) then
				UiSound("common/click.ogg")
				SetValue("gSandboxScale", 1, "cosine", 0.25)
			end			
			UiTranslate(0, bo)

			if UiTextButton("Challenges", bw, bh) then
				UiSound("common/click.ogg")
				SetValue("gChallengesScale", 1, "cosine", 0.25)
				gChallengeLevel = ""
				gChallengeLevelScale = 0
			end			
			UiTranslate(0, bo)
			
			if UiTextButton("Expansions", bw, bh) then
				UiSound("common/click.ogg")
				SetValue("gExpansionsScale", 1, "cosine", 0.25)
				gChallengeLevel = ""
				gChallengeLevelScale = 0
			end			
			UiTranslate(0, bo)

			UiTranslate(0, 22)

			UiPush()
				if not GetBool("promo.available") then
					UiDisableInput()
					UiColorFilter(1,1,1,0.5)
				end
				if UiTextButton("Featured mods", bw, bh) then
					UiSound("common/click.ogg")
					promoShow()
				end
				if GetBool("savegame.promoupdated") then
					UiPush()
						UiTranslate(200, 0)
						UiAlign("center middle")
						UiImage("menu/promo-notification.png")
					UiPop()
				end
			UiPop()
			UiTranslate(0, bo)
			if UiTextButton("Mod manager", bw, bh) then
				UiSound("common/click.ogg")
				SetValue("gCreateScale", 1, "cosine", 0.25)
				gModSelectedScale=0
				updateMods()
				selectMod("")
			end			
		UiPop()
	end
	if gSandboxScale > 0 then
		UiPush()
			UiBlur(gSandboxScale)
			UiColor(0.7,0.7,0.7, 0.25*gSandboxScale)
			UiRect(UiWidth(), UiHeight())
			UiModalBegin()
			if not drawSandbox(gSandboxScale) then
				SetValue("gSandboxScale", 0, "cosine", 0.25)
			end
			UiModalEnd()
		UiPop()
	end
	if gChallengesScale > 0 then
		UiPush()
			UiBlur(gChallengesScale)
			UiColor(0.7,0.7,0.7, 0.25*gChallengesScale)
			UiRect(UiWidth(), UiHeight())
			UiModalBegin()
			if not drawChallenges(gChallengesScale) then
				SetValue("gChallengesScale", 0, "cosine", 0.25)
			end
			UiModalEnd()
		UiPop()
	end
	if gExpansionsScale> 0 then
		UiPush()
			UiBlur(gExpansionsScale)
			UiColor(0.7,0.7,0.7, 0.25*gExpansionsScale)
			UiRect(UiWidth(), UiHeight())
			UiModalBegin()
			if not drawExpansions(gExpansionsScale) then
				SetValue("gExpansionsScale", 0, "cosine", 0.25)
			end
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
	if gOptionsScale > 0 then
		UiPush()
			UiBlur(gOptionsScale)
			UiColor(0.7,0.7,0.7, 0.25*gOptionsScale)
			UiRect(UiWidth(), UiHeight())
			UiModalBegin()
			if not drawOptions(gOptionsScale, true) then
				SetValue("gOptionsScale", 0, "cosine", 0.25)
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
				bgItems[bgCurrent] = bgLoad(bgIndex)
			end
		end

		UiTranslate(UiCenter(), UiMiddle())
		UiAlign("center middle")
		bgDraw(bgItems[1-bgCurrent])
		bgDraw(bgItems[bgCurrent])
	UiPop()

	if promo_full_initiated then
		promoDrawFeatured()
	end
end


function draw()
	UiButtonHoverColor(0.8,0.8,0.8,1)

	UiPush()
		--Create a safe 1920x1080 window that will always be visible on screen
		local x0,y0,x1,y1 = UiSafeMargins()
		UiTranslate(x0,y0)
		UiWindow(x1-x0,y1-y0, true)

		drawBackground()
		mainMenu()
		
	UiPop()

	if not gDeploy and mainMenuDebug then
		mainMenuDebug()
	end

	UiPush()
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

	if gCreateScale > 0 and GetBool("game.saveerror") then
		UiPush()
			UiColorFilter(1,1,1,gCreateScale)
			UiFont("bold.ttf", 20)
			UiTextOutline(0, 0, 0, 1, 0.1)
			UiColor(1,1,.5)
			UiAlign("center")
			UiTranslate(UiCenter(), UiHeight()-100)
			UiWordWrap(600)
			UiText("Teardown was denied write access to your Documents folder. This is usually caused by Windows Defender or similar security software. Without access to the Documents folder, local mods will not function correctly.")
		UiPop()
	end
	
	promoDraw()
end


function handleCommand(cmd)
	if cmd == "resolutionchanged" then
		gOptionsScale = 1
		optionsTab = "display"
	end
	if cmd == "activate" then
		initSlideshow()
		gActivations = gActivations + 1
	end
	if cmd == "updatemods" then
		updateMods()
	end
end