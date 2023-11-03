locInitCalled = false
-- Context Menu
contextMenu = {
	show = false,
	type = 1
}
contextIsCollection = false

collectionPop = false

errCode = 0
errShow = false
errFade = 1
errList = {
	"Collection already exists, use other names", -- removed
	"Name too short, min 3 charactors",
	"Name too long, max 20 charactors"
}

newList = {}
refreshFade = 0
oldCollectionNode = "savegame.collection"
collectionNode = "options.collection"
settingsNode = "options.modmenu"

prevSelectMod = ""
initSelect = true

menuVer = "v1.3.2"
initSettings = {
	["showpath.1"] = {"bool", false},
	["showpath.2"] = {"bool", false},
	["startcategory"] = {"int", 0},
	["rememberlast"] = {"bool", false}
}
optionSettings = {
	{"Built-in path",	"showpath.1",	"bool"},
	{"Workshop path",	"showpath.2", 	"bool"},
	{"Initial category","startcategory","int", 3},
	{"Remember last",	"rememberlast",	"bool", 0, "overwrite previous"}
}

category = GetInt(settingsNode..".startcategory")+1
categoryLookup = {
	builtin = 1,
	steam = 2,
	["local"] = 3
}
categoryInvertLookup = {
	"Built-in",
	"Workshop",
	"Local"
}

-- Yes-No popup
yesNoPopup = 
{
	show	= false,
	yes		= false,
	no		= false,
	text	= "",
	item	= "",
	yes_fn	= nil,
	no_fn	= nil
}

function yesNoInit(text,item,fn,fn1)
	yesNoPopup.show		= true
	yesNoPopup.yes		= false
	yesNoPopup.no		= false
	yesNoPopup.text		= text
	yesNoPopup.item		= item
	yesNoPopup.yes_fn	= fn
	yesNoPopup.no_fn	= fn1
end

function yesNo()
	local clicked = false
	UiModalBegin()
	UiPush()
		local w = yesNoPopup.no_fn and 530 or 500
		local h = 160
		UiTranslate(UiCenter()-w/2, UiMiddle()-85)
		UiAlign("top left")
		UiWindow(w, h)
		UiColor(0.2, 0.2, 0.2)
		UiImageBox("common/box-solid-6.png", w, h, 6, 6)
		UiColor(1, 1, 1)
		UiImageBox("common/box-outline-6.png", w, h, 6, 6)

		if InputPressed("esc") then
			yesNoPopup.yes = false
			yesNoPopup.no = false
			return true
		end

		UiColor(1,1,1,1)
		UiTranslate(16, 16)
		UiPush()
			UiAlign("top center")
			UiTranslate(w/2-16, 20)
			UiFont("regular.ttf", 22)
			UiColor(1,1,1)
			UiText(yesNoPopup.text)
		UiPop()
		
		UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1)
		UiTranslate(77, 70)
		if yesNoPopup.no_fn then
			UiTranslate(15, 0)
			UiPush()
				UiColor(0.6, 0.3, 0.2)
				UiImageBox("common/box-solid-6.png", 80, 40, 6, 6)
				UiTranslate(80+35, 0)
				UiColor(0.35, 0.5, 0.2)
				UiImageBox("common/box-solid-6.png", 80, 40, 6, 6)
			UiPop()
		else
			UiColor(0.6, 0.2, 0.2)
			UiImageBox("common/box-solid-6.png", 140, 40, 6, 6)
		end
		UiFont("regular.ttf", 26)
		UiColor(1,1,1,1)
		if yesNoPopup.no_fn then
			if UiTextButton("Yes", 80, 40) then
				yesNoPopup.yes = true
				clicked = true
			end

			UiTranslate(80+35, 0)
			if UiTextButton("No", 80, 40) then
				yesNoPopup.no = true
				clicked = true
			end

			UiTranslate(80+35, 0)
			if UiTextButton("Cancel", 80, 40) then
				clicked = true
			end
		else
			if UiTextButton("Yes", 140, 40) then
				yesNoPopup.yes = true
				clicked = true
			end

			UiTranslate(170, 0)
			if UiTextButton("No", 140, 40) then
				yesNoPopup.no = true
				clicked = true
			end
		end
	UiPop()
	UiModalEnd()
	return clicked
end

function selectMod(mod)
	gModSelected = mod
	if mod ~= "" then
		Command("mods.updateselecttime", gModSelected)
	Command("game.selectmod", gModSelected)
	end
end

function debugRect()
	UiPush()
		UiColor(0, 0, 0)
		UiRect(UiWidth(), UiHeight())
	UiPop()
end

function initModMenuSettings()
	if GetString(settingsNode) == menuVer then return end
	for setNode, setVal in pairs(initSettings) do
		if setVal[1] == "bool" then SetBool(settingsNode.."."..setNode, setVal[2]) end
		if setVal[1] == "int" then SetInt(settingsNode.."."..setNode, setVal[2]) end
	end
	SetString(settingsNode, menuVer)
end

function transferCollection()
	if not HasKey(oldCollectionNode) or HasKey(collectionNode) then return end
	for _, oldCollNode in pairs(ListKeys(oldCollectionNode)) do
		local locNode = oldCollectionNode.."."..oldCollNode
		local newNode = collectionNode.."."..oldCollNode
		local locName = GetString(locNode)
		SetString(newNode, locName)
		for _, oldMod in pairs(ListKeys(locNode)) do SetString(newNode.."."..oldMod) end
	end
	ClearKey(oldCollectionNode)
end

function initLoc()
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
	locUiScaleUpFactor = 1.0
    if showLargeUI then
		locUiScaleUpFactor = 1.2
	end

	locInitCalled = true
end

function string.split(str, splitAt)
	local splitted = {}
	(str..splitAt):gsub("(.-)"..splitAt.."%s*", function(s) splitted[#splitted+1] = s end)
	return splitted
end

function updateMods()
	Command("mods.refresh")

	gMods[1].items = {}
	gMods[2].items = {}
	gMods[3].items = {}

	local mods = ListKeys("mods.available")
	local foundSelected = false
	for i=1,#mods do
		local mod = {}
		local modNode = mods[i]
		mod.id = modNode
		mod.name = GetString("mods.available."..modNode..".listname")
		mod.override = GetBool("mods.available."..modNode..".override") and not GetBool("mods.available."..modNode..".playable")
		mod.active = GetBool("mods.available."..modNode..".active") or GetBool(modNode..".active")
		mod.steamtime = GetInt("mods.available."..modNode..".steamtime")
		mod.subscribetime = GetInt("mods.available."..modNode..".subscribetime")
		mod.showbold = false

		local iscontentmod = GetBool("mods.available."..modNode..".playable")
		local modPrefix = (mod.id):match("^(%w+)-")
		local index = categoryLookup[modPrefix]
		if index then
			if index == 2 then
				mod.showbold = GetBool("mods.available."..modNode..".showbold")
				if not newList.modNode and mod.showbold then newList[modNode] = true end
			end
			if gMods[index].filter == 0 or
				(gMods[index].filter == 2 and not iscontentmod) or
				(gMods[index].filter == 3 and iscontentmod) or
				(gMods[index].filter == 4 and mod.active) or
				(gMods[index].filter == 1 and newList[modNode]) then
				gMods[index].items[#gMods[index].items+1] = mod
			end
		end
		if gModSelected ~= "" and gModSelected == modNode then
			foundSelected = true
		end
	end
	if gModSelected ~= "" and not foundSelected then
		gModSelected = ""
	end

	for i=1,3 do
		if gMods[i].sort == 0 then
			if gMods[i].sortInv then
				table.sort(gMods[i].items, function(a, b) return string.lower(a.name) > string.lower(b.name) end)
			else
				table.sort(gMods[i].items, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
			end
		elseif gMods[i].sort == 1 then
			if gMods[i].sortInv then
				table.sort(gMods[i].items, function(a, b) return a.steamtime < b.steamtime end)
			else
				table.sort(gMods[i].items, function(a, b) return a.steamtime > b.steamtime end)
			end
		else
			if gMods[i].sortInv then
				table.sort(gMods[i].items, function(a, b) return a.subscribetime < b.subscribetime end)
			else
				table.sort(gMods[i].items, function(a, b) return a.subscribetime > b.subscribetime end)
			end
		end
	end
end

function newCollection(name)
	local newID = ""
	local idLength = 0
	local dupIndex = 0
	for str in name:gmatch("([%w-]+)") do
		idLength = idLength + #str
		if newID == "" then
			newID = str
		else
			newID = newID.."-"..str
		end
	end
	if #name < 3 or idLength < 3 then return true, 2 end
	if #name > 20 then return true, 3 end
	newID = newID:lower()
	if HasKey(collectionNode.."."..newID) then
		repeat
			dupIndex = dupIndex + 1
		until not HasKey(collectionNode.."."..newID.."-"..dupIndex)
		newID = newID.."-"..dupIndex
	end
	SetString(collectionNode.."."..newID, name)
end

function renameCollection(id, name)
	if #name < 3 then return true, 2 end
	if #name > 20 then return true, 3 end
	SetString(collectionNode.."."..id, name)
end

function collectionReset()
	gCollectionList = {
		pos = 0,
		possmooth = 0,
		sort = 0,
		sortInv = false,
		filter = 0,
		dragstarty = 0,
		isdragging = false,
	}
end

function updateCollections(noReset)
	gCollections = {}
	if not noReset then collectionReset() end

	for i, collection in ipairs(ListKeys(collectionNode)) do
		gCollections[i] = {}
		gCollections[i].lookup = collection
		gCollections[i].name = GetString(collectionNode.."."..collection)
		gCollections[i].items = {}
		gCollections[i].itemLookup = {}
	end

	for i=1, #gCollections do
		updateCollectMods(i)
	end
	table.sort(gCollections, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
end

function updateCollectMods(id)
	if not gCollections[id] then return end

	gCollections[id].items = {}
	gCollections[id].itemLookup = {}
	local lookupID = gCollections[id].lookup
	local itemList = ListKeys(collectionNode.."."..lookupID)
	for index, item in ipairs(itemList) do
		local mod = {}
		local nameCheck = GetString("mods.available."..item..".listname")
		mod.id = item
		mod.name = #nameCheck > 0 and nameCheck or "Unknown"
		mod.override = GetBool("mods.available."..item..".override") and not GetBool("mods.available."..item..".playable")
		mod.active = GetBool("mods.available."..item..".active") or GetBool(item..".active")
		local iscontentmod = GetBool("mods.available."..item..".playable")
		if gCollectionList.filter == 0 or
			(gCollectionList.filter == 2 and not iscontentmod) or
			(gCollectionList.filter == 3 and iscontentmod) or
			(gCollectionList.filter == 4 and mod.active) then
			table.insert(gCollections[id].items, mod)
		end
		gCollections[id].itemLookup[item] = 1
	end
	if gCollectionList.sortInv then
		table.sort(gCollections[id].items, function(a, b) return string.lower(a.name) > string.lower(b.name) end)
	else
		table.sort(gCollections[id].items, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
	end
end

function handleModCollect(collection)
	local modKey = collectionNode.."."..collection.."."..gModSelected
	if HasKey(modKey) then
		ClearKey(modKey)
		return
	end
	SetString(modKey)
end

function handleCollectionDuplicate(collection)
	local collKey = collectionNode.."."..collection
	local collName = GetString(collKey)
	local dupIndex = 0
	local colMods = ListKeys(collKey)
	repeat
		dupIndex = dupIndex + 1
	until not HasKey(collKey.."-"..dupIndex)
	SetString(collKey.."-"..dupIndex, collName)
	for i, mod in ipairs(colMods) do
		SetString(collKey.."-"..dupIndex.."."..mod)
	end
end

function getActiveModCountCollection()
	local count = 0
	local collection = gCollections[gCollectionSelected].lookup
	for i, mod in ipairs(ListKeys(collectionNode.."."..collection)) do
		if GetBool("mods.available."..mod..".active") or GetBool(mod..".active") then count = count+1 end
	end

	return count
end

function getGlobalModCountCollection()
	if not gCollections[gCollectionSelected] then return 0 end
	local collection = gCollections[gCollectionSelected].lookup
	return #ListKeys(collectionNode.."."..collection)
end

function activeCollection()
	DebugWatch("run")
	local collection = gCollections[gCollectionSelected].lookup
	for i, mod in ipairs(ListKeys(collectionNode.."."..collection)) do
		DebugWatch("test"..i, mod)
		if not GetBool("mods.available."..mod..".active") or not GetBool(mod..".active") then Command("mods.activate", mod) end
	end
	updateMods()
	updateCollections(true)
end

function onlyActiveCollection()
	local collection = gCollections[gCollectionSelected].lookup
	local mods = ListKeys("mods.available")
	for i=1,#mods do
		local mod = mods[i]
		local active = GetBool("mods.available."..mod..".active") or GetBool(mod..".active")
		if active then Command("mods.deactivate", mod) end
	end
	for i, mod in ipairs(ListKeys(collectionNode.."."..collection)) do
		if not GetBool("mods.available."..mod..".active") or not GetBool(mod..".active") then Command("mods.activate", mod) end
	end
	updateMods()
	updateCollections(true)
end

function deactiveCollection()
	local collection = gCollections[gCollectionSelected].lookup
	for i, mod in ipairs(ListKeys(collectionNode.."."..collection)) do
		if GetBool("mods.available."..mod..".active") or GetBool(mod..".active") then Command("mods.deactivate", mod) end
	end
	updateMods()
	updateCollections(true)
end

function deleteCollectionCallback()
	if yesNoPopup.item ~= "" then
		ClearKey(collectionNode.."."..(yesNoPopup.item))
		updateCollections()
	end
end

function deleteModCallback()
	if yesNoPopup.item ~= "" then
		Command("mods.delete", yesNoPopup.item)
		updateCollections(true)
		updateMods()
	end
end

function getActiveModCount(category)
	local count = 0
	local mods = ListKeys("mods.available")
	for i=1,#mods do
		local mod = mods[i]
		local active = GetBool("mods.available."..mod..".active") or GetBool(mod..".active")
		if active then
			local modPrefix = mod:match("^(%w+)-")
			if categoryLookup[modPrefix] == category then
				count = count+1
			end
		end
	end

	return count
end

function deactivateMods(category)
	local mods = ListKeys("mods.available")
	for i=1,#mods do
		local mod = mods[i]
		local active = GetBool("mods.available."..mod..".active") or GetBool(mod..".active")
		if active then
			local modPrefix = mod:match("^(%w+)-")
			if categoryLookup[modPrefix] == category then
				Command("mods.deactivate", mod)
			end
		end
	end
end

function contextMenuCommon(sel_mod, category)
	local open = true
	UiModalBegin()
	UiPush()
		local w = 135
		local h = 38
		if category == 2 and sel_mod ~= "" then h = 63 end
		if category == 3 then
			w = 177
			h = 128
			if sel_mod == "" then h = 85 end
		end

		local x = contextPosX
		local y = contextPosY
		UiTranslate(x, y)
		UiAlign("left top")
		UiScale(1, contextScale)
		UiWindow(w, h, true)
		UiColor(0.2,0.2,0.2,1)
		UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
		UiColor(1, 1, 1)
		UiImageBox("ui/common/box-outline-6.png", w, h, 6, 6, 1)

		--lmb click outside
		if InputPressed("esc") or (not UiIsMouseInRect(w, h) and InputPressed("lmb")) then open = false end

		--rmb click outside
		if InputPressed("esc") or (not UiIsMouseInRect(w, h) and InputPressed("rmb")) then return false end

		--Indent 12,8
		w = w - 24
		h = h - 16
		UiTranslate(12, 8)
		UiFont("regular.ttf", 22)
		UiColor(1,1,1,0.5)

		if category == 2 and sel_mod ~= "" then
			--Unsubscribe
			if UiIsMouseInRect(w, 22) then
				UiColor(1,1,1,0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					Command("mods.unsubscribe", sel_mod)
					updateCollections(true)
					updateMods()
					open = false
				end
			end
			UiColor(1,1,1,1)
			UiText("Unsubscribe")
			UiTranslate(0, 22)
		end
		if category == 3 then
			--New global mod
			if UiIsMouseInRect(w, 22) then
				UiColor(1,1,1,0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					Command("mods.new", "global")
					updateMods()
					open = false
				end
			end
			UiColor(1,1,1,1)
			UiText("New global mod")
			UiTranslate(0, 22)
	
			--New content mod
			if UiIsMouseInRect(w, 22) then
				UiColor(1,1,1,0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					Command("mods.new", "content")
					updateMods()
					open = false
				end
			end
			UiColor(1,1,1,1)
			UiText("New content mod")
	
			if sel_mod ~= "" then
				--Duplicate mod
				UiTranslate(0, 22)
				if UiIsMouseInRect(w, 22) then
					UiColor(1,1,1,0.2)
					UiRect(w, 22)
					if InputPressed("lmb") then
						Command("mods.makelocalcopy", sel_mod)
						updateMods()
						open = false
					end
				end
				UiColor(1,1,1,1)
				UiText("Duplicate mod")
	
				--Delete mod
				UiTranslate(0, 22)
				if UiIsMouseInRect(w, 22) then
					UiColor(1,1,1,0.2)
					UiRect(w, 22)
					if InputPressed("lmb") then
						yesNoInit("Are you sure you want to delete this mod?",sel_mod,deleteModCallback)
						open = false
					end
				end
				UiColor(1,1,1,1)
				UiText("Delete mod")
			end
			UiTranslate(0, 22)
		end

		--Disable all
		local count = getActiveModCount(category)
		if count > 0 then
			if UiIsMouseInRect(w, 22) then
				UiColor(1,1,1,0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					deactivateMods(category)
					updateCollections(true)
					updateMods()
					open = false
				end
			end
			UiColor(1,1,1,1)
		else
			UiColor(0.8,0.8,0.8,1)
		end
		UiText("Disable All")
	UiPop()
	UiModalEnd()

	return open
end

function contextMenuCollection(sel_collect)
	if sel_collect == "" then return false end
	gSearchClick = false
	gSearchFocus = false
	local open = true
	UiModalBegin()
	UiPush()
		local w = contextIsCollection and 170 or 115
		local h = contextIsCollection and 22*5+16 or 22*2+16

		local x = contextPosX
		local y = contextPosY
		UiTranslate(x, y)
		UiAlign("left top")
		UiScale(1, contextScale)
		UiWindow(w, h, true)
		UiColor(0.2,0.2,0.2,1)
		UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
		UiColor(1, 1, 1)
		UiImageBox("ui/common/box-outline-6.png", w, h, 6, 6, 1)

		--lmb click outside
		if InputPressed("esc") or (not UiIsMouseInRect(w, h) and InputPressed("lmb")) then
			open = false
		end

		--rmb click outside
		if InputPressed("esc") or (not UiIsMouseInRect(w, h) and InputPressed("rmb")) then
			return false
		end

		--Indent 12,8
		w = w - 24
		h = h - 16
		UiTranslate(12, 8)
		UiFont("regular.ttf", 22)
		UiColor(1,1,1,0.5)

		if contextIsCollection then
			--Rename collection
			if UiIsMouseInRect(w, 22) then
				UiColor(1,1,1,0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					gSearchClick = false
					gSearchFocus = false
					gCollectionClick = true
					gCollectionFocus = true
					gCollectionRename = true
					open = false
				end
			end
			UiColor(1,1,1,1)
			UiText("Rename")
			UiTranslate(0, 22)

			--Duplicate collection
			if UiIsMouseInRect(w, 22) then
				UiColor(1,1,1,0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					handleCollectionDuplicate(sel_collect)
					updateCollections(true)
					open = false
				end
			end
			UiColor(1,1,1,1)
			UiText("Duplicate")
			UiTranslate(0, 22)

			--Delete collection
			if UiIsMouseInRect(w, 22) then
				UiColor(1,1,1,0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					yesNoInit("Are you sure you want to delete this collection?",sel_collect,deleteCollectionCallback)
					open = false
				end
			end
			UiColor(1,1,1,1)
			UiText("Delete")
			UiTranslate(0, 22)
		end

		--Enable mods in collection
		if UiIsMouseInRect(w, 22) then
			UiColor(1,1,1,0.2)
			UiRect(w, 22)
			if InputPressed("lmb") then
				yesNoInit("Do you want to disable all unlisted mods at the same time?",sel_collect,onlyActiveCollection,activeCollection)
				open = false
			end
		end
		UiColor(1,1,1,1)
		UiText(contextIsCollection and "Apply collection" or "Enable all")
		UiTranslate(0, 22)

		--Disable mods in collection
		local count = getActiveModCountCollection()
		if count > 0 then
			if UiIsMouseInRect(w, 22) then
				UiColor(1,1,1,0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					deactiveCollection()
					open = false
				end
			end
			UiColor(1,1,1,1)
		else
			UiColor(0.8,0.8,0.8,1)
		end
		UiText(contextIsCollection and "Disuse collection" or "Disable all")
		UiTranslate(0, 22)
	UiPop()
	UiModalEnd()

	return open
end

function updateSearch()
	gSearch.items = {}

	local mods = ListKeys("mods.available")
	for i=1,#mods do
		local mod = {}
		local modNode = mods[i]
		local modName = GetString("mods.available."..modNode..".listname")
		local matchSearch = modName:lower():match(gSearchText)
		mod.id = modNode
		mod.name = modName
		mod.override = GetBool("mods.available."..modNode..".override") and not GetBool("mods.available."..modNode..".playable")
		mod.active = GetBool("mods.available."..modNode..".active") or GetBool(modNode..".active")

		local iscontentmod = GetBool("mods.available."..modNode..".playable")
		local modPrefix = (mod.id):match("^(%w+)-")
		local index = categoryLookup[modPrefix]
		if matchSearch and index then
			if gSearch.filter == 0 or (gSearch.filter == 1 and not iscontentmod) or (gSearch.filter == 2 and iscontentmod) or (gSearch.filter == 3 and mod.active) then
				gSearch.items[#gSearch.items+1] = mod
			end
		end
	end
	
	if gSearch.sortInv then
		table.sort(gSearch.items, function(a, b) return string.lower(a.name) > string.lower(b.name) end)
	else
		table.sort(gSearch.items, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
	end
end

function browseOperation(value, pageSize, listMax)
	local wheelValue = InputValue("mousewheel")
	if wheelValue ~= 0 then
		value = value + wheelValue*(InputDown("shift") and 10 or 1)
	else
		local press = 0
		if InputPressed("pgup") then press = press + 1 end
		if InputPressed("pgdown") then press = press - 1 end
		value = value + press*pageSize
		press = 0
		if InputPressed("home") then press = press + 1 end
		if InputPressed("end") then press = press - 1 end
		value = ((press == 1) and 0) or ((press == -1) and -listMax) or value
	end
	if value > 0 then value = 0 end
	return value
end

function listMods(list, w, h, issubscribedlist)
	local needUpdate = false
	local ret = ""
	local rmb_pushed = false
	local listingVal = math.ceil((h-10)/22)-1
	local totalVal = #list.items
	if list.isdragging and InputReleased("lmb") then
		list.isdragging = false
	end
	UiPush()
		UiAlign("top left")
		UiFont("regular.ttf", 22)

		local mouseOver = UiIsMouseInRect(w+12, h)
		if mouseOver then list.pos = browseOperation(list.pos, listingVal, totalVal) end
		if not UiReceivesInput() then mouseOver = false end

		local itemsInView = math.floor(h/UiFontHeight())
		if totalVal > itemsInView then
			w = w-14
			local scrollCount = (totalVal-itemsInView)
			if scrollCount < 0 then scrollCount = 0 end

			local frac = itemsInView / totalVal
			local pos = -list.possmooth / totalVal
			if list.isdragging then
				local posx, posy = UiGetMousePos()
				local dy = 0.0445 * (posy - list.dragstarty)
				list.pos = -dy / frac
			end

			UiPush()
				UiTranslate(w, 0)
				UiColor(1,1,1, 0.07)
				UiImageBox("ui/common/box-solid-4.png", 14, h, 4, 4)
				UiColor(1,1,1, 0.2)

				local bar_posy = 2 + pos*(h-4)
				local bar_sizey = (h-4)*frac
				UiPush()
					UiTranslate(2,2)
					if bar_posy > 2 and UiIsMouseInRect(8, bar_posy-2) and InputPressed("lmb") then
						list.pos = list.pos + frac * totalVal
					end
					local h2 = h - 4 - bar_sizey - bar_posy
					UiTranslate(0,bar_posy + bar_sizey)
					if h2 > 0 and UiIsMouseInRect(10, h2) and InputPressed("lmb") then
						list.pos = list.pos - frac * totalVal
					end
				UiPop()

				UiTranslate(2,bar_posy)
				UiImageBox("ui/common/box-solid-4.png", 10, bar_sizey, 4, 4)
				--UiRect(10, bar_sizey)
				if UiIsMouseInRect(10, bar_sizey) and InputPressed("lmb") then
					local posx, posy = UiGetMousePos()
					list.dragstarty = posy
					list.isdragging = true
				end
			UiPop()
			list.pos = clamp(list.pos, -scrollCount, 0)
		else
			list.pos = 0
			list.possmooth = 0
		end

		UiWindow(w, h, true)
		UiColor(1,1,1,0.07)
		UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)

		UiTranslate(10, 24)
		list.possmooth = list.pos
		-- if list.isdragging then
		-- 	list.possmooth = list.pos
		-- else
		-- 	list.possmooth = list.possmooth + (list.pos-list.possmooth) * 10 * GetTimeStep()
		-- end
		if math.abs(list.possmooth) < 0.001 then list.possmooth = 0 end
		-- UiTranslate(0, (-list.possmooth)%1*-22)
		-- UiTranslate(0, list.possmooth*22)

		UiAlign("left")
		UiColor(0.95,0.95,0.95,1)
		local listStart = math.floor(1-list.pos or 1)
		for i=listStart, math.min(totalVal, listStart+listingVal) do
			-- for i=1, totalVal do
			UiPush()
				UiTranslate(10, -18)
				UiColor(0,0,0,0)
				local id = list.items[i].id
				if gModSelected == id then
					UiColor(1,1,1,0.1)
				else
					if mouseOver and UiIsMouseInRect(228, 22) then
						UiColor(0,0,0,0.1)
						if InputPressed("lmb") then
							UiSound("terminal/message-select.ogg")
							ret = id
						end
					end
				end
				if mouseOver and UiIsMouseInRect(228, 22) and InputPressed("rmb") then
					ret = id
					rmb_pushed = true
				end
				UiRect(w, 22)
			UiPop()

			if list.items[i].override then
				UiPush()
				UiTranslate(-10, -18)
				if mouseOver and UiIsMouseInRect(22, 22) and InputPressed("lmb") then
					if list.items[i].active then
						list.items[i].active = false
						Command("mods.deactivate", list.items[i].id)
						needUpdate = true
					else
						list.items[i].active = true
						Command("mods.activate", list.items[i].id)
						needUpdate = true
					end
				end
				UiPop()

				UiPush()
					UiTranslate(2, -6)
					UiAlign("center middle")
					UiScale(0.5)
					if list.items[i].active then
						UiColor(1, 1, 0.5)
						UiImage("ui/menu/mod-active.png")
					else
						UiImage("ui/menu/mod-inactive.png")
					end
				UiPop()
			end
			UiPush()
				UiTranslate(10, 0)
				if issubscribedlist and list.items[i].showbold then
					UiFont("bold.ttf", 20)
				end
				UiText(list.items[i].name)
			UiPop()
			UiTranslate(0, 22)
		end

		if not rmb_pushed and mouseOver and InputPressed("rmb") then
			rmb_pushed = true
		end
	UiPop()

	if needUpdate then
		updateCollections(true)
		updateMods()
	end

	return ret, rmb_pushed
end

function listSearchMods(list, w, h)
	local needUpdate = false
	local ret = ""
	local listingVal = math.ceil((h-10)/22)-1
	local totalVal = #list.items
	if list.isdragging and InputReleased("lmb") then
		list.isdragging = false
	end
	UiPush()
		UiAlign("top left")
		UiFont("regular.ttf", 22)

		local mouseOver = UiIsMouseInRect(w+12, h)
		if mouseOver then list.pos = browseOperation(list.pos, listingVal, totalVal) end
		if not UiReceivesInput() then mouseOver = false end

		local itemsInView = math.floor(h/UiFontHeight())
		if totalVal > itemsInView then
			w = w-14
			local scrollCount = (totalVal-itemsInView)
			if scrollCount < 0 then scrollCount = 0 end

			local frac = itemsInView / totalVal
			local pos = -list.possmooth / totalVal
			if list.isdragging then
				local posx, posy = UiGetMousePos()
				local dy = 0.0445 * (posy - list.dragstarty)
				list.pos = -dy / frac
			end

			UiPush()
				UiTranslate(w, 0)
				UiColor(1,1,1, 0.07)
				UiImageBox("ui/common/box-solid-4.png", 14, h, 4, 4)
				UiColor(1,1,1, 0.2)

				local bar_posy = 2 + pos*(h-4)
				local bar_sizey = (h-4)*frac
				UiPush()
					UiTranslate(2,2)
					if bar_posy > 2 and UiIsMouseInRect(8, bar_posy-2) and InputPressed("lmb") then
						list.pos = list.pos + frac * totalVal
					end
					local h2 = h - 4 - bar_sizey - bar_posy
					UiTranslate(0,bar_posy + bar_sizey)
					if h2 > 0 and UiIsMouseInRect(10, h2) and InputPressed("lmb") then
						list.pos = list.pos - frac * totalVal
					end
				UiPop()

				UiTranslate(2,bar_posy)
				UiImageBox("ui/common/box-solid-4.png", 10, bar_sizey, 4, 4)
				--UiRect(10, bar_sizey)
				if UiIsMouseInRect(10, bar_sizey) and InputPressed("lmb") then
					local posx, posy = UiGetMousePos()
					list.dragstarty = posy
					list.isdragging = true
				end
			UiPop()
			list.pos = clamp(list.pos, -scrollCount, 0)
		else
			list.pos = 0
			list.possmooth = 0
		end

		UiWindow(w, h, true)
		UiColor(1,1,1,0.07)
		UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)

		UiTranslate(10, 24)
		list.possmooth = list.pos
		if math.abs(list.possmooth) < 0.001 then list.possmooth = 0 end

		UiAlign("left")
		UiColor(0.95,0.95,0.95,1)
		local listStart = math.floor(1-list.pos or 1)
		for i=listStart, math.min(totalVal, listStart+listingVal) do
			UiPush()
				UiTranslate(10, -18)
				UiColor(0,0,0,0)
				local id = list.items[i].id
				if gModSelected == id then
					UiColor(1,1,1,0.1)
				else
					if mouseOver and UiIsMouseInRect(228, 22) then
						UiColor(0,0,0,0.1)
						if InputPressed("lmb") then
							UiSound("terminal/message-select.ogg")
							ret = id
						end
					end
				end
				UiRect(w, 22)
			UiPop()

			if list.items[i].override then
				UiPush()
					UiTranslate(-10, -18)
					if UiIsMouseInRect(22, 22) and InputPressed("lmb") then
						if list.items[i].active then
							list.items[i].active = false
							Command("mods.deactivate", list.items[i].id)
							needUpdate = true
						else
							list.items[i].active = true
							Command("mods.activate", list.items[i].id)
							needUpdate = true
						end
					end
				UiPop()
				UiPush()
					UiTranslate(2, -6)
					UiAlign("center middle")
					UiScale(0.5)
					if list.items[i].active then
						UiColor(1, 1, 0.5)
						UiImage("ui/menu/mod-active.png")
					else
						UiImage("ui/menu/mod-inactive.png")
					end
				UiPop()
			end
			UiPush()
				UiTranslate(10, 0)
				UiText(list.items[i].name)
			UiPop()
			UiTranslate(0, 22)
		end
	UiPop()

	if needUpdate then
		updateCollections(true)
		updateMods()
	end

	return ret
end

function listCollections(list, w, h)
	local ret = gCollectionSelected
	local rmb_pushed = false
	local listingVal = math.ceil((h-10)/22)-1
	local totalVal = #list
	if gCollectionMain.isdragging and InputReleased("lmb") then
		gCollectionMain.isdragging = false
	end

	UiPush()
		UiAlign("top left")
		UiFont("regular.ttf", 22)

		local mouseOver = UiIsMouseInRect(w+12, h)
		if mouseOver then gCollectionMain.pos = browseOperation(gCollectionMain.pos, listingVal, totalVal) end
		if not UiReceivesInput() then mouseOver = false end

		local itemsInView = math.floor(h/UiFontHeight())
		if totalVal > itemsInView then
			w = w-14
			local scrollCount = (totalVal-itemsInView)
			if scrollCount < 0 then scrollCount = 0 end

			local frac = itemsInView / totalVal
			local pos = -gCollectionMain.possmooth / totalVal
			if gCollectionMain.isdragging then
				local posx, posy = UiGetMousePos()
				local dy = 0.0445 * (posy - gCollectionMain.dragstarty)
				gCollectionMain.pos = -dy / frac
			end

			UiPush()
				UiTranslate(w, 0)
				UiColor(1,1,1, 0.07)
				UiImageBox("ui/common/box-solid-4.png", 14, h, 4, 4)
				UiColor(1,1,1, 0.2)

				local bar_posy = 2 + pos*(h-4)
				local bar_sizey = (h-4)*frac
				UiPush()
					UiTranslate(2,2)
					if bar_posy > 2 and UiIsMouseInRect(8, bar_posy-2) and InputPressed("lmb") then
						gCollectionMain.pos = gCollectionMain.pos + frac * totalVal
					end
					local h2 = h - 4 - bar_sizey - bar_posy
					UiTranslate(0,bar_posy + bar_sizey)
					if h2 > 0 and UiIsMouseInRect(10, h2) and InputPressed("lmb") then
						gCollectionMain.pos = gCollectionMain.pos - frac * totalVal
					end
				UiPop()

				UiTranslate(2,bar_posy)
				UiImageBox("ui/common/box-solid-4.png", 10, bar_sizey, 4, 4)
				if UiIsMouseInRect(10, bar_sizey) and InputPressed("lmb") then
					local posx, posy = UiGetMousePos()
					gCollectionMain.dragstarty = posy
					gCollectionMain.isdragging = true
				end
			UiPop()
			gCollectionMain.pos = clamp(gCollectionMain.pos, -scrollCount, 0)
		else
			gCollectionMain.pos = 0
			gCollectionMain.possmooth = 0
		end

		UiWindow(w, h, true)
		UiColor(1,1,1,0.07)
		UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)

		UiTranslate(10, 24)
		gCollectionMain.possmooth = gCollectionMain.pos
		if math.abs(gCollectionMain.possmooth) < 0.001 then gCollectionMain.possmooth = 0 end

		UiAlign("left")
		UiColor(0.95,0.95,0.95,1)
		local listStart = math.floor(1-gCollectionMain.pos or 1)
		for i=listStart, math.min(totalVal, listStart+listingVal) do
			UiPush()
				UiTranslate(20, -18)
				UiColor(0,0,0,0)
				if gCollectionSelected == i then
					UiColor(1,1,1,0.1)
				else
					if mouseOver and UiIsMouseInRect(228, 22) then
						UiColor(0,0,0,0.1)
						if InputPressed("lmb") then
							UiSound("terminal/message-select.ogg")
							collectionReset()
							ret = i
						end
					end
				end
				if mouseOver and UiIsMouseInRect(228, 22) and InputPressed("rmb") then
					ret = i
					rmb_pushed = true
				end
				UiRect(w, 22)
			UiPop()

			UiPush()
				UiAlign("left middle")
				UiTranslate(0, -7)
				UiButtonImageBox("ui/common/box-outline-4.png", 16, 16, 1, 1, 1, 0.75)
				UiScale(0.5)
				if list[i].itemLookup[gModSelected] then
					if UiImageButton("ui/hud/checkmark.png", 36, 36) then
						handleModCollect(list[i].lookup)
						updateCollections(true)
					end
				else
					if UiBlankButton(36, 36) then
						handleModCollect(list[i].lookup)
						updateCollections(true)
					end
				end
			UiPop()
			UiPush()
				UiTranslate(20, 0)
				if gCollectionRename and gCollectionSelected == i then
					if gCollectionName == "" then
						UiColor(1, 1, 1, 0.5)
					end
					UiText(gCollectionName ~= "" and gCollectionName or "[rename]")
				else
					UiText(list[i].name)
				end
			UiPop()
			UiTranslate(0, 22)
		end

		if not rmb_pushed and mouseOver and InputPressed("rmb") then
			rmb_pushed = true
		end
	UiPop()

	return ret, rmb_pushed
end

function listCollectionMods(mainList, w, h, selected)
	local needUpdate = false
	local list = mainList[selected]
	local ret = ""
	local rmb_pushed = false
	local listingVal = math.ceil((h-10)/22)-1
	if gCollectionList.isdragging and InputReleased("lmb") then
		gCollectionList.isdragging = false
	end

	UiPush()
		UiAlign("top left")
		UiFont("regular.ttf", 22)
		local itemsInView = math.floor(h/UiFontHeight())
		if not list then
			UiPush()
				UiColor(1,1,1,0.07)
				UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
			UiPop()
			UiPop()
			return ret, rmb_pushed
		end

		local totalVal = #list.items
		local mouseOver = UiIsMouseInRect(w+12, h)
		if mouseOver then gCollectionList.pos = browseOperation(gCollectionList.pos, listingVal, totalVal) end
		if not UiReceivesInput() then mouseOver = false end

		if totalVal > itemsInView then
			w = w-14
			local scrollCount = (totalVal-itemsInView)
			if scrollCount < 0 then scrollCount = 0 end

			local frac = itemsInView / totalVal
			local pos = -gCollectionList.possmooth / totalVal
			if gCollectionList.isdragging then
				local posx, posy = UiGetMousePos()
				local dy = 0.0445 * (posy - gCollectionList.dragstarty)
				gCollectionList.pos = -dy / frac
			end

			UiPush()
				UiTranslate(w, 0)
				UiColor(1,1,1, 0.07)
				UiImageBox("ui/common/box-solid-4.png", 14, h, 4, 4)
				UiColor(1,1,1, 0.2)

				local bar_posy = 2 + pos*(h-4)
				local bar_sizey = (h-4)*frac
				UiPush()
					UiTranslate(2,2)
					if bar_posy > 2 and UiIsMouseInRect(8, bar_posy-2) and InputPressed("lmb") then
						gCollectionList.pos = gCollectionList.pos + frac * totalVal
					end
					local h2 = h - 4 - bar_sizey - bar_posy
					UiTranslate(0,bar_posy + bar_sizey)
					if h2 > 0 and UiIsMouseInRect(10, h2) and InputPressed("lmb") then
						gCollectionList.pos = gCollectionList.pos - frac * totalVal
					end
				UiPop()

				UiTranslate(2,bar_posy)
				UiImageBox("ui/common/box-solid-4.png", 10, bar_sizey, 4, 4)
				--UiRect(10, bar_sizey)
				if UiIsMouseInRect(10, bar_sizey) and InputPressed("lmb") then
					local posx, posy = UiGetMousePos()
					gCollectionList.dragstarty = posy
					gCollectionList.isdragging = true
				end
			UiPop()
			gCollectionList.pos = clamp(gCollectionList.pos, -scrollCount, 0)
		else
			gCollectionList.pos = 0
			gCollectionList.possmooth = 0
		end

		UiWindow(w, h, true)
		UiColor(1,1,1,0.07)
		UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)

		UiTranslate(10, 24)
		gCollectionList.possmooth = gCollectionList.pos
		if math.abs(gCollectionList.possmooth) < 0.001 then gCollectionList.possmooth = 0 end

		UiAlign("left")
		UiColor(0.95,0.95,0.95,1)
		local listStart = math.floor(1-gCollectionList.pos or 1)
		for i=listStart, math.min(totalVal, listStart+listingVal) do
			UiPush()
				UiTranslate(10, -18)
				UiColor(0,0,0,0)
				local id = list.items[i].id
				if gModSelected == id then
					UiColor(1,1,1,0.1)
				else
					if mouseOver and UiIsMouseInRect(228, 22) then
						UiColor(0,0,0,0.1)
						if InputPressed("lmb") then
							UiSound("terminal/message-select.ogg")
							ret = id
						end
					end
				end
				if mouseOver and UiIsMouseInRect(228, 22) and InputPressed("rmb") then
					ret = id
					rmb_pushed = true
				end
				UiRect(w, 22)
			UiPop()

			if list.items[i].override then
				UiPush()
				UiTranslate(-10, -18)
				if UiIsMouseInRect(22, 22) and InputPressed("lmb") then
					if list.items[i].active then
						list.items[i].active = false
						Command("mods.deactivate", list.items[i].id)
						needUpdate = true
					else
						list.items[i].active = true
						Command("mods.activate", list.items[i].id)
						needUpdate = true
					end
				end
				UiPop()

				UiPush()
					UiTranslate(2, -6)
					UiAlign("center middle")
					UiScale(0.5)
					if list.items[i].active then
						UiColor(1, 1, 0.5)
						UiImage("ui/menu/mod-active.png")
					else
						UiImage("ui/menu/mod-inactive.png")
					end
				UiPop()
			end
			UiPush()
				UiTranslate(10, 0)
				UiText(list.items[i].name)
			UiPop()
			UiTranslate(0, 22)
		end

		if not rmb_pushed and mouseOver and InputPressed("rmb") then
			rmb_pushed = true
		end
	UiPop()

	if needUpdate then
		updateCollections(true)
		updateMods()
		updateSearch()
	end

	return ret, rmb_pushed
end

function drawFilter(filter, sort, order, isWorkshop)
	local needUpdate = false
	local categoryText = {
		"All",
		"New",
		"Global",
		"Content",
		"Enabled"
	}
	local sortText = {
		"Alphabetical",
		"Updated",
		"Subscribed"
	}
	UiPush()
		UiTranslate(40, -11)
		UiFont("regular.ttf", 19)
		UiAlign("center")
		UiColor(1,1,1,0.8)
		UiButtonImageBox("ui/common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)
		if UiTextButton(categoryText[filter+1], 80, 26) then
			filter = (filter+1)%5
			if not isWorkshop and filter == 1 then filter = 2 end
			needUpdate = true
		end
	UiPop()
	UiPush()
		UiTranslate(80+55+1, -11)
		UiFont("regular.ttf", 19)
		UiAlign("center")
		UiColor(1,1,1,0.8)
		UiButtonImageBox("ui/common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)
		if isWorkshop then
			if UiTextButton(sortText[sort+1], 110, 26) then
				sort = (sort+1)%3
				needUpdate = true
			end
		else
			UiTextButton(sortText[1], 110, 26)
		end
	UiPop()
	UiPush()
		UiTranslate(80+110+2, -11)
		UiFont("regular.ttf", 19)
		UiAlign("center")
		UiColor(1,1,1,0.8)
		UiButtonImageBox("ui/common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)
		UiPush()
			UiTranslate(14, -6)
			UiAlign("center middle")
			UiRotate(order and 90 or -90)
			if UiImageButton("ui/common/play.png", 26, 28) then
				order = not order
				needUpdate = true
			end
		UiPop()
	UiPop()
	return filter, sort, order, needUpdate
end

function drawCreate(scale)
	if not locInitCalled then initLoc() end
	local open = true
	if initSelect then
		if gModSelected == "" and GetBool(settingsNode..".rememberlast") then gModSelected = GetString(settingsNode..".rememberlast.last") end
		if not HasKey("mods.available."..gModSelected) then gModSelected = "" end
		initSelect = false
	end
	UiPush()
		local w = 758 + 1*610
		local h = 880
		local listW = 334
		local listH = 22*28+10
		local mainW = 610
		local mainH = listH
		local buttonW = 180
		UiTranslate(UiCenter(), UiMiddle())
		UiScale(scale*locUiScaleUpFactor)
		UiColorFilter(1, 1, 1, scale)
		UiColor(0,0,0, 0.5)
		UiAlign("center middle")
		UiImageBox("ui/common/box-solid-shadow-50.png", w, h, -50, -50)
		UiWindow(w, h)
		UiAlign("left top")
		UiColor(0.96,0.96,0.96)
		local quitCondA = (gLargePreview or 0) <= 0 and InputPressed("esc")
		local quitCondB = not (UiIsMouseInRect(UiWidth(), UiHeight())) and InputPressed("lmb")
		if not (gCollectionTyping or gSearchTyping) and (quitCondA or quitCondB) then
			open = false
			gMods[1].isdragging = false;
			gMods[2].isdragging = false;
			gMods[3].isdragging = false;
		end
		if quitCondB then
			gCollectionTyping = false
			gCollectionFocus = false
			gCollectionClick = false
			gSearchTyping = false
			gSearchFocus = false
			gSearchClick = false
		end

		UiPush()
			UiFont("bold.ttf", 48)
			UiColor(1,1,1)
			UiAlign("center")
			UiTranslate(UiCenter(), 60)
			if refreshFade > 0.1 then
				UiPush()
					UiTranslate(0, -36)
					UiFont("bold.ttf", 24)
					UiColorFilter(0.8, 0.8, 0.8, refreshFade)
					UiText("Mods Refreshed")
				UiPop()
			end
			if UiTextButton("MODS", 134, 44) then
				refreshFade = 1
				SetValue("refreshFade", 0, "easein", 1.5)
				updateMods()
				updateCollections()
			end
		UiPop()
		
		UiPush()
			UiPush()
				UiFont("regular.ttf", 22)
				UiTranslate(UiCenter()-580, 90)
				UiAlign("left")
				UiColor(0.8, 0.8, 0.8)
				UiText("Create your own mods using Lua scripting and the free voxel modeling program MagicaVoxel.", true)
				UiTranslate(0, 4)
				UiText("We have provided example mods that you can modify or replace with your own creations.", true)
				UiTranslate(0, 4)
				local infw = UiText("Find out more on our web page:")
				UiTranslate(infw+5, 0)
				UiFont("bold.ttf", 22)
				UiColor(1, 0.95, .7)
				if UiTextButton("www.teardowngame.com/modding") then Command("game.openurl", "http://www.teardowngame.com/modding") end
			UiPop()

			UiPush()
				UiTranslate(UiCenter()+202, 90)
				UiAlign("left")
				UiPush()
					UiTranslate(0, -10)
					UiColor(0.8, 0.8, 0.8, 0.75)
					UiRect(2, 80)
				UiPop()
				UiColor(0.85, 0.85, 0.85)
				UiTranslate(26, 0)
				UiFont("bold.ttf", 25)
				UiText("Settings")
				UiTranslate(105, 0)
				UiFont("regular.ttf", 23)
				for _, setting in ipairs(optionSettings) do
					local xOff = 0
					if setting[3] == "bool" then
						UiPush()
							UiAlign("left middle")
							UiTranslate(0, -5)
							UiButtonImageBox("ui/common/box-outline-4.png", 16, 16, 1, 1, 1, 0.75)
							UiScale(0.5)
							local currSetting = GetBool(settingsNode.."."..setting[2])
							if currSetting then
								if UiImageButton("ui/hud/checkmark.png", 36, 36) then SetBool(settingsNode.."."..setting[2], not currSetting) end
							else
								if UiBlankButton(36, 36) then SetBool(settingsNode.."."..setting[2], not currSetting) end
							end
						UiPop()
						UiPush()
							UiAlign("left middle")
							UiColor(0.85, 0.85, 0.85)
							UiTranslate(20, -5)
							local txw = UiText(setting[1])
						UiPop()
						xOff = xOff + 20 + txw + 5
					end
					if setting[3] == "int" then
						UiPush()
							UiAlign("left middle")
							UiTranslate(0, -5)
							UiPush()
								UiColor(1, 1, 1, 0.15)
								UiImageBox("ui/common/box-solid-4.png", 98, 25, 1, 1)
							UiPop()
							UiColor(0.95, 0.95, 0.95)
							local currSetting = GetInt(settingsNode.."."..setting[2])
							if UiTextButton(categoryInvertLookup[currSetting+1], 80, 23) then SetInt(settingsNode.."."..setting[2], (currSetting+1)%3) end
						UiPop()
						UiPush()
							UiAlign("left middle")
							UiColor(0.85, 0.85, 0.85)
							UiTranslate(100, -5)
							local txw = UiText(setting[1])
						UiPop()
						xOff = xOff + 100 + txw + 5
					end
					if setting[5] then
						UiPush()
							UiAlign("left middle")
							UiFont("regular.ttf", 17)
							UiColor(0.95, 0.45, 0)
							UiTranslate(xOff, -3)
							UiText(setting[5])
						UiPop()
					end
					UiTranslate(0, 23)
				end
			UiPop()

			UiTranslate(30, 200)
			UiPush()
				UiPush()
					UiFont("bold.ttf", 22)
					UiAlign("left")
					UiPush()
						UiButtonHoverColor(0.77, 0.77, 0.77)
						UiButtonPressDist(0.5)
						UiPush()
							UiTranslate(0, -8)
							UiButtonImageBox("ui/common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)
							UiBlankButton(110, 30)
						UiPop()
						UiButtonImageBox("ui/common/box-outline-4.png", 4, 4, 1, 1, 1, 0.9)
						if gSearchText ~= "" then
							if UiTextButton("Search", 110, 30) then
								gSearchText = ""
								local modPrefix = gModSelected:match("^(%w+)-")
								local index = categoryLookup[modPrefix]
								category = index and index or category
							end
						else
							if UiTextButton(gMods[category].title, 110, 30) then
								category = category%3+1
								gModSelected = ""
							end
						end
					UiPop()
					UiTranslate(0, 10)
					local h = category == 2 and listH-44 or listH
					local selected, rmb_pushed

					if gSearchText ~= "" then
						selected = listSearchMods(gSearch, listW, h)
						if selected ~= "" then selectMod(selected) end
					else
						selected, rmb_pushed = listMods(gMods[category], listW, h, category==2)
						if selected ~= "" then
							selectMod(selected)
							if category==2 then
								updateMods()
								updateCollections(true)
							end
						end
					end

					-- filter
					UiPush()
						UiTranslate(114, 0)
						if gSearchText == "" then
							local needUpdate = false
							gMods[category].filter, gMods[category].sort, gMods[category].sortInv, needUpdate
							= drawFilter(gMods[category].filter, gMods[category].sort, gMods[category].sortInv, category == 2)
							if needUpdate then updateMods() end
						else
							local needUpdate = false
							gSearch.filter, gSearch.sort, gSearch.sortInv, needUpdate = drawFilter(gSearch.filter, gSearch.sort, gSearch.sortInv)
							if needUpdate then updateSearch() end
						end
					UiPop()

					if gSearchText == "" and rmb_pushed then
						contextMenu.show = true
						contextMenu.type = category
						SetValue("contextScale", 1, "bounce", 0.35)
						contextItem = selected
						getContextMousePos = true
					end
				UiPop()
				if category==2 then
					UiPush()
						if not GetBool("game.workshop") then 
							UiPush()
								UiFont("regular.ttf", 20)
								UiTranslate(50, 110)
								UiColor(0.7, 0.7, 0.7)
								UiText("Steam Workshop is\ncoming soon")
							UiPop()
							UiDisableInput()
							UiColorFilter(1,1,1,0.5)
						end
						UiTranslate(0, listH-30)
						UiFont("regular.ttf", 24)
						UiButtonImageBox("ui/common/box-solid-6.png", 6, 6, 1, 1, 1, 0.1)
						if UiTextButton("Manage subscribed...", listW, 38) then
							Command("mods.browse")
						end
					UiPop()
				end
				if InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and (InputPressed("lmb") or InputPressed("rmb"))) then contextMenu.show = false end
			UiPop()

			UiColor(0,0,0,0.1)
			UiTranslate(listW+15, 10)

			UiPush()
				local modKey = "mods.available."..gModSelected
				local modKeyShort = gModSelected
				UiAlign("left")
				UiColor(1,1,1, 0.07)
				UiImageBox("ui/common/box-solid-6.png", mainW, mainH, 6, 6)
				UiWindow(mainW, mainH)
				if gModSelected ~= "" then
					UiPush()
						local modPrefix = gModSelected:match("^(%w+)-")
						local modCategory = categoryLookup[modPrefix]
						local unknownMod = false
						local name = GetString(modKey..".name")
						if gModSelected ~= "" and name == "" then name = "Unknown" unknownMod = true end
						local author = GetString(modKey..".author")
						if gModSelected ~= "" and author == "" then author = "Unknown" end
						local authorList = string.split(author, ",")
						local tags = GetString(modKey..".tags")
						local tagList = string.split(tags, ",")
						local description = GetString(modKey..".description")
						local timestamp = GetString(modKey..".timestamp")
						local modPath = GetString(modKey..".path")
						if modCategory == 1 then modPath = GetString("game.path").."/"..modPath end
						local previewPath = "RAW:"..modPath.."/preview.jpg"
						if not HasFile(previewPath) then previewPath = "RAW:"..modPath.."/preview.png" end
						local hasPreview = HasFile(previewPath)
						local idPath = "RAW:"..modPath.."/id.txt"
						local hasId = HasFile(idPath)
						local isLocal = GetBool(modKey..".local")

						UiAlign("top left")
						UiTranslate(30, 16)
						UiColor(1,1,1,1)
						UiFont("bold.ttf", 32)
						UiText(name)
						UiFont("regular.ttf", 20)
						UiTranslate(0, 40)

						UiPush()
							local poW, poH = 270, 270
							local textWmax = mainW-30*2-poW-18
							if hasPreview then
								local pw,ph = UiGetImageSize(previewPath)
								local Pscale = math.min(poW/pw, poH/ph)
								if UiIsMouseInRect(poW, poH) then
									UiPush()
										UiTranslate(poW/2, poH/2)
										UiAlign("center middle")
										UiRect(poW+14, poH+14)
										UiColor(0.1, 0.1, 0.1)
										UiRect(poW+6, poH+6)
									UiPop()
									if InputPressed("lmb") then
										gLoadedPreview = previewPath
										gQuitLarge = false
										SetValue("gLargePreview", 1, "easeout", 0.1)
									end
								end
								UiPush()
									UiTranslate(poW/2, poH/2)
									UiAlign("center middle")
									UiColor(1,1,1)
									UiScale(Pscale)
									UiImage(previewPath)
								UiPop()
							else
								UiPush()
									UiFont("regular.ttf", 20)
									UiColor(0.1, 0.1, 0.1)
									UiRect(poW, poH)
									UiTranslate(poW/2, poH/2)
									UiColor(1, 0.2, 0.2)
									UiAlign("center middle")
									UiText("No preview image")
								UiPop()
							end

							UiTranslate(poW+18, 0)
							UiWindow(textWmax, poH, true)

							if author ~= "" then
								UiText("Author:")
								UiAlign("top left")
								UiTranslate(68, 0)
								local countDist = 0
								for i, auth in ipairs(authorList) do
									UiWordWrap(textWmax-68)
									local authW, authH = UiGetTextSize(auth)
									local transX, transY = authW+8, 0
									if authH > 26 then
										if countDist > 0 then
											UiTranslate(-countDist, 24)
										end
										countDist = 0
										transX, transY = 0, authH
									elseif countDist + authW+8 > textWmax-68 then
										UiTranslate(-countDist, 24)
										countDist = 0
										transX = authW+8
									end
									UiText(auth)
									UiTranslate(transX, transY)
									countDist = countDist + transX
								end
								UiTranslate(-68-countDist, 24)
							end
							if tags ~= "" then
								UiText("Tags:", true)
								UiTranslate(0, 4)
								UiButtonImageBox("ui/common/box-outline-4.png", 8, 8, 1, 1, 1, 0.7)
								UiButtonHoverColor(1, 1, 1)
								UiButtonPressColor(1, 1, 1)
								UiButtonPressDist(0)
								local countDist = 0
								for i, tag in ipairs(tagList) do
									local tagW, tagH = UiGetTextSize(tag)
									if countDist + tagW+14 > textWmax then
										UiTranslate(-countDist, 26)
										countDist = 0
									end
									UiTextButton(tag, tagW+6, 24)
									UiTranslate(tagW+14)
									countDist = countDist + tagW+14
								end
							end
						UiPop()
						UiTranslate(0, poH+16)

						UiWindow(mainW-30*3-180, 240, true)
						UiWordWrap(mainW-30*3-195)
						UiFont("regular.ttf", 20)
						UiColor(.9, .9, .9)
						UiText(description)
					UiPop()

					UiPush()
						UiColor(1,1,1,1)
						UiFont("regular.ttf", 16)
						UiTranslate(30, mainH - 24)
						if timestamp ~= "" then
							UiColor(0.5, 0.5, 0.5)
							UiText("Updated " .. timestamp, true)
						end
					UiPop()

					UiColor(1, 1, 1)
					UiFont("regular.ttf", 24)
					UiButtonImageBox("ui/common/box-outline-6.png", 6, 6, 1, 1, 1, 0.7)
					UiAlign("center middle")

					-- play & enable
					if GetBool(modKey..".playable") then
						UiPush()
							UiTranslate(mainW-buttonW/2-30,mainH-40)
							UiPush()
								UiColor(.7, 1, .8, 0.2)
								UiImageBox("ui/common/box-solid-6.png", 200, 40, 6, 6)
							UiPop()
							if UiTextButton("Play", 200, 40) then
								Command("mods.play", gModSelected)
							end
						UiPop()
					else
						if GetBool(modKey..".override") then
							UiPush()
								UiTranslate(mainW-buttonW/2-30,mainH-40)
								if GetBool(modKey..".active") or GetBool(modKeyShort..".active") then
									if UiTextButton("Enabled", 200, 40) then
										Command("mods.deactivate", gModSelected)
										updateMods()
										updateCollections(true)
										updateSearch()
									end
									UiColor(1, 1, 0.5)
									UiTranslate(-60, 0)
									UiImage("ui/menu/mod-active.png")
								else
									if UiTextButton("Disabled", 200, 40) then
										Command("mods.activate", gModSelected)
										updateMods()
										updateCollections(true)
										updateSearch()
									end
									UiTranslate(-60, 0)
									UiImage("ui/menu/mod-inactive.png")
								end
							UiPop()
						end
					end
					-- options
					if GetBool(modKey..".options") then
						UiPush()
							UiTranslate(mainW-buttonW/2-30,mainH-90)
							if UiTextButton("Options", 200, 40) then
								Command("mods.options", gModSelected)
							end
						UiPop()
					end
					-- edit & copy
					if isLocal then
						if GetBool(modKey..".playable") then
							UiPush()
								UiTranslate(mainW-buttonW/2-30,mainH-260)
								if UiTextButton("Edit", 200, 40) then
									Command("mods.edit", gModSelected)
								end
							UiPop()
						end
					elseif not unknownMod then
						UiPush()
							UiTranslate(mainW-buttonW/2-30,mainH-260)
							if UiTextButton("Make local copy", 200, 40) then
								Command("mods.makelocalcopy", gModSelected)
								updateMods()
								updateSearch()
							end
						UiPop()
					end
					-- details & publish
					if isLocal or GetBool(settingsNode..".showpath."..modCategory) then
						if isLocal then
							UiPush()
								UiTranslate(mainW-buttonW/2-30,mainH-210)
								if not GetBool("game.workshop")or not GetBool("game.workshop.publish") then 
									UiDisableInput()
									UiColorFilter(1,1,1,0.5)
								end
								if UiTextButton("Publish...", 200, 40) then
									SetValue("gPublishScale", 1, "cosine", 0.25)
									Command("mods.publishbegin", gModSelected)
								end
								if not GetBool("game.workshop.publish") then
									UiTranslate(0, 30)
									UiFont("regular.ttf", 18)
									UiText("Unavailable in experimental")
								end
							UiPop()
						elseif hasId then
							UiPush()
								UiTranslate(mainW-buttonW/2-30,mainH-210)
								if UiTextButton("Details...", 200, 40) then Command("mods.browsesubscribed", gModSelected) end
							UiPop()
						end
						UiPush()
							UiTranslate(UiCenter(),mainH+5)
							UiColor(0.5, 0.5, 0.5)
							UiFont("regular.ttf", 18)
							UiAlign("center top")
							local w,h = UiGetTextSize(modPath)
							if UiIsMouseInRect(w, h) then
								UiColor(1, 0.8, 0.5)
								if InputPressed("lmb") then Command("game.openfolder", modPath) end
							end
							UiText(modPath, true)
						UiPop()
					end
				end
			UiPop()

			-- search mods
			UiPush()
				UiFont("bold.ttf", 22)
				UiAlign("left")
				local tw = mainW
				local th = 28
				UiTranslate(0, -32)
				UiColor(1,1,1,0.07)
				UiImageBox("ui/common/box-solid-4.png", tw, th, 4, 4)
				if InputPressed("lmb") or InputPressed("rmb") then
					gSearchClick = UiIsMouseInRect(tw, th) or gSearchClick
					gSearchFocus = UiIsMouseInRect(tw, th)
					gCollectionFocus = UiIsMouseInRect(tw, th) and false or gCollectionFocus
					gCollectionTyping = UiIsMouseInRect(tw, th) and false or gCollectionTyping
				end
				UiColor(1,1,1)
				UiFont("regular.ttf", 22)
				local newSearch = ""
				if gSearchClick then
					if gCollectionClick then gCollectionClick = false else
						newSearch, gSearchTyping = UiTextInput(gSearchText, tw, th, gSearchFocus)
					end
				end
				if string.len(newSearch) > 40 then
					newSearch = string.sub(newSearch, 1, 40)
				end
				gSearchFocus = false
				if gSearchText == "" then
					UiColor(1,1,1,0.5)
					UiTranslate(0, 20)
					UiText("[search mod]")
					local modPrefix = gModSelected:match("^(%w+)-")
					local index = categoryLookup[modPrefix]
					category = index and index or category
				else
					UiTranslate(tw-24, 5)
					UiColor(1,1,1)
					if UiImageButton("ui/common/clearinput.png") then
						newSearch = ""
						gSearchFocus = true
					end
				end
				if newSearch ~= gSearchText then
					gSearchText = newSearch
					gSearchFocus = true
					updateSearch()
				end
				if gSearchTyping and InputLastPressedKey() == "esc" then
					gSearchClick = false
					gSearchFocus = false
				end
			UiPop()

			UiColor(0,0,0,0.1)
			UiTranslate(mainW+15, 0)

			UiPush()
				UiFont("bold.ttf", 22)
				UiAlign("left")
				UiPush()
					local tw = listW
					local th = 28
					UiTranslate(0, -32)
					if errFade > 0.05 then
						UiPush()
							UiAlign("bottom left")
							UiTranslate(0, -4)
							UiWordWrap(tw-14)
							UiFont("regular.ttf", 20)
							UiColor(1, 0.4, 0.4, errFade)
							UiText(errList[errCode])
						UiPop()
					end
					UiColor(1,1,1,0.07)
					UiImageBox("ui/common/box-solid-4.png", tw, th, 4, 4)
					if InputPressed("lmb") or InputPressed("rmb") then
						gCollectionClick = UiIsMouseInRect(tw, th)
						gCollectionFocus = UiIsMouseInRect(tw, th)
						gSearchFocus = UiIsMouseInRect(tw, th) and false or gSearchFocus
						gSearchTyping = UiIsMouseInRect(tw, th) and false or gSearchTyping
						gCollectionRename = UiIsMouseInRect(tw, th) and gCollectionRename or false
					end
					UiColor(1,1,1)
					UiFont("regular.ttf", 22)
					local newText = ""
					if gCollectionClick then
						if gSearchClick then gSearchClick = false else
							newText, gCollectionTyping = UiTextInput(gCollectionName, tw, th, gCollectionFocus)
						end
					end
					if string.len(newText) > 20 then
						newText = string.sub(newText, 1, 20)
					end
					gCollectionFocus = false
					if gCollectionName == "" then
						UiColor(1,1,1,0.5)
						UiTranslate(0, 20)
						UiText(gCollectionRename and "[rename]" or "[new collection]")
					else
						UiTranslate(tw-24, 5)
						UiColor(1,1,1)
						if UiImageButton("ui/common/clearinput.png") then
							newText = ""
							gCollectionFocus = true
						end
					end
					if newText ~= gCollectionName then
						gCollectionName = newText
						gCollectionFocus = true
					end
					if gCollectionTyping and InputLastPressedKey() == "return" then
						local failed
						if gCollectionRename then
							local id = gCollections[gCollectionSelected].lookup
							failed, errCode = renameCollection(id, gCollectionName)
						else
							failed, errCode = newCollection(gCollectionName)
						end
						if failed then
							errShow = true
							errFade = 1
							SetValue("errFade", 0, "easein", 2.5)
						else
							gCollectionName = ""
							gCollectionClick = false
							gCollectionFocus = false
							gCollectionRename = false
							updateCollections()
						end
					end
					if gCollectionTyping and InputLastPressedKey() == "esc" then
						gCollectionClick = false
						gCollectionFocus = false
						gCollectionRename = false
					end
				UiPop()
				local hcl = 9*22+10
				local hcm = 17*22+10
				local rmb_pushedC
				local prevSelect = gCollectionSelected

				gCollectionSelected, rmb_pushedC = listCollections(gCollections, listW, hcl)
				local validCollection = gCollections[gCollectionSelected]
				if prevSelect ~= gCollectionSelected then updateCollectMods(gCollectionSelected) end

				UiTranslate(0, listH-hcm)
				UiPush()
					UiPush()
						UiTranslate(0, -10)
						UiFont("bold.ttf", 22)
						UiAlign("left")
						UiColor(0.96,0.96,0.96,0.9)
						UiText("Collection")
					UiPop()

					-- filter
					UiTranslate(114, 0)
					local needUpdate = false
					gCollectionList.filter, gCollectionList.sort, gCollectionList.sortInv, needUpdate
					= drawFilter(gCollectionList.filter, gCollectionList.sort, gCollectionList.sortInv)
					if needUpdate then updateCollectMods(gCollectionSelected) end
				UiPop()
				local selected, rmb_pushedM = listCollectionMods(gCollections, listW, hcm, gCollectionSelected)

				if selected ~= "" then
					selectMod(selected)
					local modPrefix = selected:match("^(%w+)-")
					category = categoryLookup[modPrefix] or category
				end

				if validCollection and (rmb_pushedC or (rmb_pushedM and getGlobalModCountCollection() > 0 )) then
					collectionPop = true
					SetValue("contextScale", 1, "bounce", 0.35)
					contextItem = gCollections[gCollectionSelected].lookup
					contextIsCollection = rmb_pushedC
					getContextMousePos = true
				end
			UiPop()
		UiPop()
	UiPop()

	--------------------------------- LARGE PREVIEW -------------------------------------------
	if gLargePreview > 0 then
		local largeW, largeH = UiHeight()*0.9, UiHeight()*0.9
		local pw, ph = UiGetImageSize(gLoadedPreview)
		UiPush()
			UiAlign("center middle")
			UiTranslate(UiCenter(), UiMiddle())
			UiModalBegin()
			UiBlur(gLargePreview)
			UiScale(gLargePreview)
			UiScale(math.min(largeW/pw, largeH/ph))
			UiColor(1, 1, 1, gLargePreview)
			UiImage(gLoadedPreview)
			if not gQuitLarge and InputPressed("esc") or InputPressed("lmb") or InputPressed("rmb") then
				SetValue("gLargePreview", 0, "easein", 0.1)
				gQuitLarge = true
			end
		UiPop()
	end

	------------------------------------ PUBLISH ----------------------------------------------
	if gPublishScale > 0 then
		open = true
		UiModalBegin()
		UiBlur(gPublishScale)
		UiPush()
			local w = 700
			local h = 800
			UiTranslate(UiCenter(), UiMiddle())
			UiScale(gPublishScale)
			UiColorFilter(1, 1, 1, scale)
			UiColor(0,0,0, 0.5)
			UiAlign("center middle")
			UiImageBox("ui/common/box-solid-shadow-50.png", w, h, -50, -50)
			UiWindow(w, h)
			UiAlign("left top")
			UiColor(1,1,1)

			local publish_state = GetString("mods.publish.state")
			local canEsc = publish_state ~= "uploading"
			if canEsc and (InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and InputPressed("lmb"))) then
				SetValue("gPublishScale", 0, "cosine", 0.25)
				Command("mods.publishend")
			end
			
			UiPush()
				UiFont("bold.ttf", 48)
				UiColor(1,1,1)
				UiAlign("center")
				UiTranslate(UiCenter(), 60)
				UiText("PUBLISH MOD")
			UiPop()
			
			local modKey = "mods.available."..gModSelected
			UiPush()
				UiTranslate(50, 100)
				local mw = 335
				local mh = mw
				UiPush()
					UiTranslate((w-100-mw)/2, 0)
					UiPush()
						UiColor(1, 1, 1, 0.05)
						UiRect(mw, mh)
					UiPop()
					local id = GetString("mods.publish.id")
					local name = GetString(modKey..".name")
					local author = GetString(modKey..".author")
					local tags = GetString(modKey..".tags")
					local description = GetString(modKey..".description")
					local previewPath = "RAW:"..GetString(modKey..".path").."/preview.jpg"
					if not HasFile(previewPath) then previewPath = "RAW:"..GetString(modKey..".path").."/preview.png" end
					local hasPreview = HasFile(previewPath)
					local missingInfo = false
					if hasPreview then
						local pw,ph = UiGetImageSize(previewPath)
						local scale = math.min(mw/pw, mh/ph)
						UiPush()
							UiTranslate(mw/2, mh/2)
							UiAlign("center middle")
							UiColor(1,1,1)
							UiScale(scale)
							UiImage(previewPath)
						UiPop()
					else
						UiPush()
							UiFont("regular.ttf", 20)
							UiTranslate(mw/2, mh/2)
							UiColor(1, 0.2, 0.2)
							UiAlign("center middle")
							UiText("No preview image", true)
						UiPop()
					end
				UiPop()
				UiTranslate(0, 400)
				UiFont("bold.ttf", 32)
				UiAlign("left")
				if name ~= "" then
					UiText(name)
				else
					UiColor(1,0.2,0.2)
					UiText("Name not specified")
					UiColor(1,1,1)
					missingInfo = true
				end

				UiTranslate(0, 20)
				UiFont("regular.ttf", 20)

				if id ~= "0" then
					UiText("Workshop ID: "..id, true)
				end
				if author ~= "" then
					UiText("By " .. author, true)
				else
					UiColor(1,0.2,0.2)
					UiText("Author not specified", true)
					UiColor(1,1,1)
					missingInfo = true
				end

				UiAlign("left top")
				if tags ~= "" then
					UiTranslate(0, -16)
					UiWindow(mw,22,true)
					UiText("Tags: " .. tags, true)
					UiTranslate(0, 16)
				end
				UiWordWrap(mw)
				UiFont("regular.ttf", 20)
				UiColor(.8, .8, .8)

				if description ~= "" then
					UiWindow(mw,104,true)
					UiText(description, true)
				else
					UiColor(1,0.2,0.2)
					UiText("Description not specified", true)
					UiColor(1,1,1)
					missingInfo = true
				end
			UiPop()
			UiPush()
				local state = GetString("mods.publish.state")
				local canPublish = (state == "ready" or state == "failed")
				local update = (id ~= "0")
				local done = (state == "done")
				local failMessage = GetString("mods.publish.message")
					
				if missingInfo then
					canPublish = false
					failMessage = "Incomplete information in info.txt"
				elseif not hasPreview then
					canPublish = false
					failMessage = "Preview image not found: preview.jpg"
				end

				UiTranslate(w-50, h-30)
				UiAlign("bottom right")
				UiFont("regular.ttf", 24)
				UiButtonImageBox("ui/common/box-outline-6.png", 6, 6, 1, 1, 1, 0.7)

				if state == "uploading" then
					if UiTextButton("Cancel", 200, 40) then
						Command("mods.publishcancel")
					end
					local progress = GetFloat("mods.publish.progress")
					if progress < 0.1 then
						progress = 0.1
					end
					if progress > 0.9 then
						progress = 0.9
					end
					UiTranslate(-600, -40)
					UiAlign("top left")
					UiColor(0,0,0)
					UiRect(350, 40)
					UiColor(1,1,1)
					UiTranslate(2,2)
					UiRect(346*progress, 36)
					UiColor(0.5, 0.5, 0.5)
					UiTranslate(175, 20)
					UiAlign("center middle")
					UiText("Uploading")
				else
					UiPush()
						if done then
							if UiTextButton("Done", 200, 40) then
								SetValue("gPublishScale", 0, "easein", 0.25)
								Command("mods.publishend")
							end				
						else
							if not canPublish then
								UiDisableInput()
								UiColorFilter(1,1,1,0.3)
							end
							local caption = "Publish"
							if update then
								caption = "Publish update"
							end
							UiPush()
								UiAlign("center middle")
								UiTranslate(-160, -65)
								UiText("Visibility")
								UiTranslate(55,5)
								UiColor(1,1,0.7)
								local val = GetInt("mods.publish.visibility")
								UiButtonImageBox()
								UiAlign("left")
								if val == -1 then

								elseif val == 0 then
									if UiTextButton("Public", 200, 40) then
										SetInt("mods.publish.visibility", 1)
									end
								elseif val == 1 then
									if UiTextButton("Friends", 200, 40) then
										SetInt("mods.publish.visibility", 2)
									end
								elseif val == 2 then
									if UiTextButton("Private", 200, 40) then
										SetInt("mods.publish.visibility", 3)
									end
								else
									if UiTextButton("Unlisted", 200, 40) then
										SetInt("mods.publish.visibility", 0)
									end
								end
							UiPop()
							if UiTextButton(caption, 200, 40) then
								Command("mods.publishupload")
							end				
						end
					UiPop()
					if failMessage ~= "" then
						UiColor(1, 0.2, 0.2)
						UiTranslate(-600, -20)
						UiAlign("left middle")
						UiFont("regular.ttf", 20)
						UiWordWrap(350)
						UiText(failMessage)
					end
				end
			UiPop()
		UiPop()
		UiModalEnd()
	end
	
	-- context menu
	if contextMenu.show then
		if getContextMousePos then
			contextPosX, contextPosY = UiGetMousePos()
			getContextMousePos = false
		end
		contextMenu.show = contextMenuCommon(contextItem, contextMenu.type)
		if not contextMenu.show then
			contextScale = 0
		end
	end

	if collectionPop then
		if getContextMousePos then
			contextPosX, contextPosY = UiGetMousePos()
			getContextMousePos = false
		end
		collectionPop = contextMenuCollection(contextItem)
		if not collectionPop then
			contextScale = 0
		end
	end

	-- yes-no popup
	if yesNoPopup.show and yesNo() then
		yesNoPopup.show = false
		if yesNoPopup.yes and yesNoPopup.yes_fn ~= nil then
			yesNoPopup.yes_fn()
		end
		if yesNoPopup.no and yesNoPopup.no_fn ~= nil then
			yesNoPopup.no_fn()
		end
	end

	-- last selected mod
	if prevSelectMod ~= gModSelected and gModSelected ~= "" then SetString(settingsNode..".rememberlast.last", gModSelected) prevSelectMod = gModSelected end

	return open
end