#include "ui_extensions.lua"
#include "ui_helpers.lua"
#include "buttons.lua"
#include "game.lua"

#include "mod_manager_locLang.lua"

function locLangReset()
	locLang = locLang or {}
	locLang.INDEX =					0
	locLang.new = 					"New"
	locLang.rename = 				"Rename"
	locLang.duplicate = 			"Duplicate"
	locLang.delete = 				"Delete"
	locLang.enableAll = 			"Enable all"
	locLang.disableAll = 			"Disable all"
	locLang.modsRefreshed = 		"Mods Refreshed"
	locLang.renameCol = 			"[rename]"
	locLang.searchMod = 			"[search mod]"
	locLang.newCol = 				"[new collection]"
	locLang.collection = 			"Collection"
	locLang.delColConfirm = 		"Are you sure you want to delete this collection?"
	locLang.disableModsColAsk = 	"Do you want to disable all unlisted mods at the same time?"
	locLang.applyCol = 				"Apply collection"
	locLang.disuseCol = 			"Disuse collection"
	locLang.errorColShort = 		"Name too short, min 3 charactors"
	locLang.errorColLong = 			"Name too long, max 20 charactors"
	locLang.settings = 				"Settings"
	locLang.setting1 = 				"Built-in mod path"
	locLang.setting2 = 				"Workshop mod path"
	locLang.setting3 = 				"Initial category"
	locLang.setting4 = 				"Remember last selected mod"
	locLang.setting4ex = 			"overwrite previous"
	locLang.cateLocalShort =		"Local"
	locLang.cateWorkshopShort =		"Workshop"
	locLang.cateBuiltInShort =		"Built-in"
	locLang.filterModeAlphabet =	"Alphabetical"
	locLang.filterModeUpdate =		"Updated"
	locLang.filterModeSubscribe =	"Subscribed"
end

function updateLocLangStr()
	UiPush()
		locLangReset()

		local pouncStr = GetTranslatedStringByKey("UI_TEXT_TAGS")
		local pouncStrLen = UiGetSymbolsCount(pouncStr)
		locLangStrAuthor = GetTranslatedStringByKey("UI_TEXT_AUTHOR")..UiTextSymbolsSub(pouncStr, pouncStrLen, pouncStrLen)
		locLangStrUpdateAt = GetTranslatedStringByKey("UI_TEXT_UPDATED").." "
		locLangStrWorkshopID = GetTranslatedStringByKey("UI_TEXT_WORKSHOP_ID").." "
		locLangStrByAuthor = GetTranslatedStringByKey("UI_TEXT_BY")..UiTextSymbolsSub(pouncStr, pouncStrLen, pouncStrLen).." "
		locLangStrModTags = pouncStr.." "

		local langIndex = UiGetLanguage()+1
		for locStrKey, locStrVal in pairs(locLangLookup) do
			repeat
				if not locLang[locStrKey] then break end
				if not locStrVal then break end
				if not locStrVal[langIndex] then break end
				locLang[locStrKey] = locStrVal[langIndex]
			until true
		end

		errorData = {
			Code = 0,
			Show = false,
			Fade = 1,
			List = {
				nil,
				locLang.errorColShort,
				locLang.errorColLong
			}
		}
		optionSettings = {
			{locLang.setting1,	"showpath.1",	"bool"},
			{locLang.setting2,	"showpath.2", 	"bool"},
			{locLang.setting3,	"startcategory","int", 	3},
			{locLang.setting4,	"rememberlast",	"bool", 0, locLang.setting4ex}
		}
		categoryTextLookup = {
			locLang.cateBuiltInShort,
			locLang.cateWorkshopShort,
			locLang.cateLocalShort
		}
		gMods = gMods or {}
		for i=1, 3 do gMods[i]= gMods[i] or {} end
		gMods[1].title = locLang.cateBuiltInShort
		gMods[2].title = locLang.cateWorkshopShort
		gMods[3].title = locLang.cateLocalShort
		filterCategoryText = {
			"loc@UI_BUTTON_ALL",
			locLang.new,
			"loc@UI_BUTTON_GLOBAL",
			"loc@UI_BUTTON_CONTENT",
			"loc@UI_BUTTON_ENABLED"
		}
		filterSortText = {
			locLang.filterModeAlphabet,
			locLang.filterModeUpdate,
			locLang.filterModeSubscribe
		}

		UiFont("regular.ttf", 22)
		contextMenu.MenuWidth = {
			-- collection listing
			collectionW = UiMeasureText(0, locLang.rename, locLang.duplicate, locLang.delete, locLang.applyCol, locLang.disuseCol) + 24,
			-- collected mods
			colModsW = UiMeasureText(0, locLang.enableAll, locLang.disableAll) + 24,
			-- common listing
			listCommonW = UiMeasureText(0, "loc@UI_TEXT_DISABLE_ALL") + 24,
			-- workshop listing
			listWorkshopW = UiMeasureText(0, "loc@UI_TEXT_UNSUBSCRIBE", "loc@UI_TEXT_DISABLE_ALL") + 24,
			-- local listing
			listLocalW = UiMeasureText(0, "loc@UI_TEXT_NEW_GLOBAL", "loc@UI_TEXT_NEW_CONTENT", "loc@UI_TEXT_DISABLE_ALL") + 24,
			-- local selected listing
			listLocalSelW = UiMeasureText(0, "loc@UI_TEXT_NEW_GLOBAL", "loc@UI_TEXT_NEW_CONTENT", "loc@UI_TEXT_DUPLICATE_MOD", "loc@UI_TEXT_DELETE_MOD", "loc@UI_TEXT_DISABLE_ALL") + 24
		}

		gPublishLangIndex = locLang.INDEX
	UiPop()
end

contextMenu = {
	Show = false,
	Type = 1,
	IsCollection = false,
	PosX = 0,
	PosY = 0,
	Scale = 0,
	Item = nil,
	GetMousePos = false
}

contextMenu.Collection = function(sel_collect)
	if sel_collect == "" then return false end
	gSearchClick = false
	gSearchFocus = false
	local open = true
	UiModalBegin()
	UiPush()
		local w = contextMenu.IsCollection and contextMenu.MenuWidth.collectionW or contextMenu.MenuWidth.colModsW
		local h = contextMenu.IsCollection and 22*5+16 or 22*2+16
		local x = contextMenu.PosX
		local y = contextMenu.PosY

		UiTranslate(x, y)
		UiAlign("left top")
		UiScale(1, contextMenu.Scale)
		UiWindow(w, h, true)
		UiColor(0.2, 0.2, 0.2, 1)
		UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
		UiColor(1, 1, 1)
		UiImageBox("ui/common/box-outline-6.png", w, h, 6, 6, 1)

		if InputPressed("esc") or (not UiIsMouseInRect(w, h) and InputPressed("lmb")) then open = false end
		if InputPressed("esc") or (not UiIsMouseInRect(w, h) and InputPressed("rmb")) then return false end

		--Indent 12, 8
		w = w - 24
		h = h - 16
		UiTranslate(12, 8)
		UiFont("regular.ttf", 22)
		UiColor(1, 1, 1, 0.5)

		if contextMenu.IsCollection then
			--Rename collection
			if UiIsMouseInRect(w, 22) then
				UiColor(1, 1, 1, 0.2)
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
			UiColor(1, 1, 1, 1)
			UiText(locLang.rename)
			UiTranslate(0, 22)

			--Duplicate collection
			if UiIsMouseInRect(w, 22) then
				UiColor(1, 1, 1, 0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					handleCollectionDuplicate(sel_collect)
					updateCollections(true)
					open = false
				end
			end
			UiColor(1, 1, 1, 1)
			UiText(locLang.duplicate)
			UiTranslate(0, 22)

			--Delete collection
			if UiIsMouseInRect(w, 22) then
				UiColor(1, 1, 1, 0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					yesNoPopInit(locLang.delColConfirm, sel_collect, callback.DeleteCollection)
					open = false
				end
			end
			UiColor(1, 1, 1, 1)
			UiText(locLang.delete)
			UiTranslate(0, 22)
		end

		--Enable mods in collection
		if UiIsMouseInRect(w, 22) then
			UiColor(1, 1, 1, 0.2)
			UiRect(w, 22)
			if InputPressed("lmb") then
				yesNoPopInit(locLang.disableModsColAsk, sel_collect, onlyActiveCollection, activeCollection)
				open = false
			end
		end
		UiColor(1, 1, 1, 1)
		UiText(contextMenu.IsCollection and locLang.applyCol or locLang.enableAll)
		UiTranslate(0, 22)

		--Disable mods in collection
		local count = getActiveModCountCollection()
		if count > 0 then
			if UiIsMouseInRect(w, 22) then
				UiColor(1, 1, 1, 0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					deactiveCollection()
					open = false
				end
			end
			UiColor(1, 1, 1, 1)
		else
			UiColor(0.8, 0.8, 0.8, 1)
		end
		UiText(contextMenu.IsCollection and locLang.disuseCol or locLang.disableAll)
		UiTranslate(0, 22)
	UiPop()
	UiModalEnd()

	return open
end

contextMenu.Common = function(sel_mod, fnCategory)
	local open = true
	UiModalBegin()
	UiPush()
		local w =	(fnCategory == 2 and sel_mod ~= "") and contextMenu.MenuWidth.listWorkshopW or
					(fnCategory == 3) and (sel_mod ~= "" and contextMenu.MenuWidth.listLocalSelW or contextMenu.MenuWidth.listLocalW) or
					contextMenu.MenuWidth.listCommonW
		local h =	(fnCategory == 2 and sel_mod ~= "") and 63 or (fnCategory == 3) and (sel_mod ~= "" and 128 or 85) or 38
		local x = contextMenu.PosX
		local y = contextMenu.PosY

		UiTranslate(x, y)
		UiAlign("left top")
		UiScale(1, contextMenu.Scale)
		UiWindow(w, h, true)
		UiColor(0.2, 0.2, 0.2, 1)
		UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
		UiColor(1, 1, 1)
		UiImageBox("ui/common/box-outline-6.png", w, h, 6, 6, 1)

		if InputPressed("esc") or (not UiIsMouseInRect(w, h) and InputPressed("lmb")) then open = false end
		if InputPressed("esc") or (not UiIsMouseInRect(w, h) and InputPressed("rmb")) then return false end

		--Indent 12, 8
		w = w - 24
		h = h - 16
		UiTranslate(12, 8)
		UiFont("regular.ttf", 22)
		UiColor(1, 1, 1, 0.5)

		if fnCategory == 2 and sel_mod ~= "" then
			--Unsubscribe
			if UiIsMouseInRect(w, 22) then
				UiColor(1, 1, 1, 0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					Command("mods.unsubscribe", sel_mod)
					updateCollections(true)
					updateMods()
					open = false
				end
			end
			UiColor(1, 1, 1, 1)
			UiText("loc@UI_TEXT_UNSUBSCRIBE")
			UiTranslate(0, 22)
		end
		if fnCategory == 3 then
			--New global mod
			if UiIsMouseInRect(w, 22) then
				UiColor(1, 1, 1, 0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					Command("mods.new", "global")
					updateMods()
					open = false
				end
			end
			UiColor(1, 1, 1, 1)
			UiText("loc@UI_TEXT_NEW_GLOBAL")
			UiTranslate(0, 22)
	
			--New content mod
			if UiIsMouseInRect(w, 22) then
				UiColor(1, 1, 1, 0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					Command("mods.new", "content")
					updateMods()
					open = false
				end
			end
			UiColor(1, 1, 1, 1)
			UiText("loc@UI_TEXT_NEW_CONTENT")
	
			if sel_mod ~= "" then
				--Duplicate mod
				UiTranslate(0, 22)
				if UiIsMouseInRect(w, 22) then
					UiColor(1, 1, 1, 0.2)
					UiRect(w, 22)
					if InputPressed("lmb") then
						Command("mods.makelocalcopy", sel_mod)
						updateMods()
						open = false
					end
				end
				UiColor(1, 1, 1, 1)
				UiText("loc@UI_TEXT_DUPLICATE_MOD")
	
				--Delete mod
				UiTranslate(0, 22)
				if UiIsMouseInRect(w, 22) then
					UiColor(1, 1, 1, 0.2)
					UiRect(w, 22)
					if InputPressed("lmb") then
						yesNoPopInit("loc@ARE_YOU", sel_mod, callback.DeleteMod)
						open = false
					end
				end
				UiColor(1, 1, 1, 1)
				UiText("loc@UI_TEXT_DELETE_MOD")
			end
			UiTranslate(0, 22)
		end

		--Disable all
		local count = getActiveModCount(fnCategory)
		if count > 0 then
			if UiIsMouseInRect(w, 22) then
				UiColor(1, 1, 1, 0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					deactivateMods(fnCategory)
					updateCollections(true)
					updateMods()
					open = false
				end
			end
			UiColor(1, 1, 1, 1)
		else
			UiColor(0.8, 0.8, 0.8, 1)
		end
		UiText("loc@UI_TEXT_DISABLE_ALL")
	UiPop()
	UiModalEnd()

	return open
end

callback = {}

callback.DeleteCollection = function()
	if yesNoPopPopup.item ~= "" then
		ClearKey(nodes.Collection.."."..(yesNoPopPopup.item))
		updateCollections()
	end
end

callback.DeleteMod = function()
	if yesNoPopPopup.item ~= "" then
		Command("mods.delete", yesNoPopPopup.item)
		updateCollections(true)
		updateMods()
	end
end

nodes = {
	OldCollection = "savegame.collection",
	Collection = "options.collection",
	Settings = "options.modmenu"
}

collectionPop = false
newList = {}
prevSelectMod = ""
initSelect = true
menuVer = "v1.4.1"

webLinks = {
	gameModding = "https://www.teardowngame.com/modding",
	projectGithub = "https://github.com/YuLun-bili/Mod-Menu-Revamped",
	projectCrowdin = "https://crowdin.com/project/yulun-td-mmre"
}

initSettings = {
	["showpath.1"] = {"bool", false},
	["showpath.2"] = {"bool", false},
	["startcategory"] = {"int", 0},
	["rememberlast"] = {"bool", false}
}

category = {
	Index = (GetInt(nodes.Settings..".startcategory")+1),
	Lookup = {
		builtin = 1,
		steam = 2,
		["local"] = 3
	}
}

-- Yes-No popup
yesNoPopPopup = {
	show	= false,
	yes		= false,
	no		= false,
	text	= "",
	item	= "",
	yes_fn	= nil,
	no_fn	= nil
}

function yesNoPopInit(text, item, fn, fn1)
	yesNoPopPopup.show		= true
	yesNoPopPopup.yes		= false
	yesNoPopPopup.no		= false
	yesNoPopPopup.text		= text
	yesNoPopPopup.item		= item
	yesNoPopPopup.yes_fn	= fn
	yesNoPopPopup.no_fn		= fn1
end

function yesNoPop()
	local clicked = false
	UiModalBegin()
	UiPush()
		local w = yesNoPopPopup.no_fn and 530 or 500
		local h = 160
		UiTranslate(UiCenter()-w/2, UiMiddle()-85)
		UiAlign("top left")
		UiWindow(w, h)
		UiColor(0.2, 0.2, 0.2)
		UiImageBox("common/box-solid-6.png", w, h, 6, 6)
		UiColor(1, 1, 1)
		UiImageBox("common/box-outline-6.png", w, h, 6, 6)

		if InputPressed("esc") then
			yesNoPopPopup.yes = false
			yesNoPopPopup.no = false
			return true
		end

		UiColor(1, 1, 1, 1)
		UiTranslate(16, 16)
		UiPush()
			UiAlign("top center")
			UiTranslate(w/2-16, 20)
			UiFont("regular.ttf", 22)
			UiColor(1, 1, 1)
			UiText(yesNoPopPopup.text)
		UiPop()
		
		UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1)
		UiTranslate(77, 70)
		if yesNoPopPopup.no_fn then
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
		UiColor(1, 1, 1, 1)
		if yesNoPopPopup.no_fn then
			if UiTextButton("loc@UI_BUTTON_YES", 80, 40) then
				yesNoPopPopup.yes = true
				clicked = true
			end

			UiTranslate(80+35, 0)
			if UiTextButton("loc@UI_BUTTON_NO", 80, 40) then
				yesNoPopPopup.no = true
				clicked = true
			end

			UiTranslate(80+35, 0)
			if UiTextButton("loc@UI_BUTTON_CANCEL", 80, 40) then
				clicked = true
			end
		else
			if UiTextButton("loc@UI_BUTTON_YES", 140, 40) then
				yesNoPopPopup.yes = true
				clicked = true
			end

			UiTranslate(170, 0)
			if UiTextButton("loc@UI_BUTTON_NO", 140, 40) then
				yesNoPopPopup.no = true
				clicked = true
			end
		end
	UiPop()
	UiModalEnd()
	return clicked
end

function strSplit(str, splitAt)
	local splitted = {}
	(str..splitAt):gsub("(.-)"..splitAt.."%s*", function(s) splitted[#splitted+1] = s end)
	return splitted
end

function selectMod(mod)
	gModSelected = mod
	if mod ~= "" then
		Command("mods.updateselecttime", gModSelected)
		Command("game.selectmod", gModSelected)
		SetString("dev.modmanager.selectedmodmod", gModSelected)
	end
end

function initModMenuSettings()
	if GetString(nodes.Settings) == menuVer then return end
	for setNode, setVal in pairs(initSettings) do
		local settingNode = nodes.Settings.."."..setNode
		repeat
			if HasKey(settingNode) then break end
			if setVal[1] == "bool" then SetBool(settingNode, setVal[2]) end
			if setVal[1] == "int" then SetInt(settingNode, setVal[2]) end
		until true
	end
	SetString(nodes.Settings, menuVer)
end

function transferCollection()
	if not HasKey(nodes.OldCollection) or HasKey(nodes.Collection) then return end
	for _, oldCollNode in pairs(ListKeys(nodes.OldCollection)) do
		local locNode = nodes.OldCollection.."."..oldCollNode
		local newNode = nodes.Collection.."."..oldCollNode
		local locName = GetString(locNode)
		SetString(newNode, locName)
		for _, oldMod in pairs(ListKeys(locNode)) do SetString(newNode.."."..oldMod) end
	end
	ClearKey(nodes.OldCollection)
end

function initLoc()
	transferCollection()
	initModMenuSettings()
	updateLocLangStr()
	RegisterListenerTo("LanguageChanged", "updateLocLangStr")
	RegisterListenerTo("LanguageChanged", "updateMods")
	RegisterListenerTo("LanguageChanged", "updateCollections")
	RegisterListenerTo("LanguageChanged", "collectionReset")

	gMods = gMods or {}
	for i=1, 3 do
		gMods[i] = gMods[i] or {}
		gMods[i].items = {}
		gMods[i].pos = 0
		gMods[i].sort = 0
		gMods[i].sortInv = false
		gMods[i].filter = 0
		gMods[i].dragstarty = 0
		gMods[i].isdragging = false
	end
	gModSelected = ""
	updateMods()

	gCollections = {}
	updateCollections()
	gCollectionList = {}
	collectionReset()
	gCollectionMain = {
		pos = 0,
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

	gSearchTyping = false
	gSearchFocus = false
	gSearchClick = false
	gSearchText = ""
	gSearch = {
		items = {},
		pos = 0,
		sortInv = false,
		filter = 0,
		dragstarty = 0,
		isdragging = false
	}

	gLoadedPreview = ""
	gLargePreview = 0
	gQuitLarge = false

	gPublishScale = 0
	gPublishDropdown = false
	gPublishLangIndex = 0
	gPublishLangReload = false
	gPublishLangTitle = nil
	gPublishLangDesc = nil
	
	gRefreshFade = 0
	gShowSetting = false
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
		local index = category.Lookup[modPrefix]
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
		if gModSelected ~= "" and gModSelected == modNode then foundSelected = true end
	end
	if gModSelected ~= "" and not foundSelected then gModSelected = "" end

	for i=1, 3 do
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
	local newID = "col"
	local dupIndex = 0
	local nameLength = UiGetSymbolsCount(name)
	for str in name:gmatch("([%w-]+)") do newID = newID.."-"..str end
	if nameLength < 3 then return true, 2 end
	if nameLength > 20 then return true, 3 end
	newID = newID:lower()
	if HasKey(nodes.Collection.."."..newID) then
		repeat dupIndex = dupIndex + 1 until not HasKey(nodes.Collection.."."..newID.."-"..dupIndex)
		newID = newID.."-"..dupIndex
	end
	SetString(nodes.Collection.."."..newID, name)
end

function renameCollection(id, name)
	local nameLength = UiGetSymbolsCount(name)
	if nameLength < 3 then return true, 2 end
	if nameLength > 20 then return true, 3 end
	SetString(nodes.Collection.."."..id, name)
end

function collectionReset()
	gCollectionList = {
		pos = 0,
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

	for i, collection in ipairs(ListKeys(nodes.Collection)) do
		gCollections[i] = {}
		gCollections[i].lookup = collection
		gCollections[i].name = GetString(nodes.Collection.."."..collection)
		gCollections[i].items = {}
		gCollections[i].itemLookup = {}
	end

	for i=1, #gCollections do updateCollectMods(i) end
	table.sort(gCollections, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
end

function updateCollectMods(id)
	if not gCollections[id] then return end

	gCollections[id].items = {}
	gCollections[id].itemLookup = {}
	local lookupID = gCollections[id].lookup
	local itemList = ListKeys(nodes.Collection.."."..lookupID)
	for index, item in ipairs(itemList) do
		local mod = {}
		local nameCheck = GetString("mods.available."..item..".listname")
		mod.id = item
		mod.name = #nameCheck > 0 and nameCheck or "loc@NAME_UNKNOWN"
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
	local modKey = nodes.Collection.."."..collection.."."..gModSelected
	if HasKey(modKey) then ClearKey(modKey) return end
	SetString(modKey)
end

function handleCollectionDuplicate(collection)
	local collKey = nodes.Collection.."."..collection
	local collName = GetString(collKey)
	local dupIndex = 0
	local colMods = ListKeys(collKey)
	repeat dupIndex = dupIndex + 1 until not HasKey(collKey.."-"..dupIndex)
	SetString(collKey.."-"..dupIndex, collName)
	for i, mod in ipairs(colMods) do SetString(collKey.."-"..dupIndex.."."..mod) end
end

function getActiveModCountCollection()
	local count = 0
	local collection = gCollections[gCollectionSelected].lookup
	for i, mod in ipairs(ListKeys(nodes.Collection.."."..collection)) do
		if GetBool("mods.available."..mod..".active") or GetBool(mod..".active") then count = count+1 end
	end
	return count
end

function getGlobalModCountCollection()
	if not gCollections[gCollectionSelected] then return 0 end
	local collection = gCollections[gCollectionSelected].lookup
	return #ListKeys(nodes.Collection.."."..collection)
end

function activeCollection()
	local collection = gCollections[gCollectionSelected].lookup
	for i, mod in ipairs(ListKeys(nodes.Collection.."."..collection)) do
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
	for i, mod in ipairs(ListKeys(nodes.Collection.."."..collection)) do
		if not GetBool("mods.available."..mod..".active") or not GetBool(mod..".active") then Command("mods.activate", mod) end
	end
	updateMods()
	updateCollections(true)
end

function deactiveCollection()
	local collection = gCollections[gCollectionSelected].lookup
	for i, mod in ipairs(ListKeys(nodes.Collection.."."..collection)) do
		if GetBool("mods.available."..mod..".active") or GetBool(mod..".active") then Command("mods.deactivate", mod) end
	end
	updateMods()
	updateCollections(true)
end

function getActiveModCount(fnCategory)
	local count = 0
	local mods = ListKeys("mods.available")
	for i=1,#mods do
		local mod = mods[i]
		local active = GetBool("mods.available."..mod..".active") or GetBool(mod..".active")
		if active then
			local modPrefix = mod:match("^(%w+)-")
			if category.Lookup[modPrefix] == fnCategory then count = count+1 end
		end
	end
	return count
end

function deactivateMods(fnCategory)
	local mods = ListKeys("mods.available")
	for i=1,#mods do
		local mod = mods[i]
		local active = GetBool("mods.available."..mod..".active") or GetBool(mod..".active")
		if active then
			local modPrefix = mod:match("^(%w+)-")
			if category.Lookup[modPrefix] == fnCategory then Command("mods.deactivate", mod) end
		end
	end
end

function toggleMod(id, state)
	if not state then
		Command("mods.activate", id)
		return true
	end
	Command("mods.deactivate", id)
	return false
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
		local index = category.Lookup[modPrefix]
		local filter = gSearch.filter
		if matchSearch and index then
			if filter == 0 or (filter == 2 and not iscontentmod) or (filter == 3 and iscontentmod) or (filter == 4 and mod.active) then gSearch.items[#gSearch.items+1] = mod end
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

function listMods(list, w, h, issubscribedlist, noRmb)
	local needUpdate = false
	local ret = ""
	local rmb_pushed = false
	local listingVal = math.ceil((h-10)/22)-1
	local totalVal = #list.items
	if list.isdragging and InputReleased("lmb") then list.isdragging = false end
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
			if list.isdragging then
				local posx, posy = UiGetMousePos()
				local dy = 0.0445 * (posy - list.dragstarty)
				list.pos = -dy / frac
			end
			list.pos = clamp(list.pos, -scrollCount, 0)
			local pos = -list.pos / totalVal

			UiPush()
				UiTranslate(w, 0)
				UiColor(1, 1, 1, 0.07)
				UiImageBox("ui/common/box-solid-4.png", 14, h, 4, 4)
				UiColor(1, 1, 1, 0.2)

				local bar_posy = 2 + pos*(h-4)
				local bar_sizey = (h-4)*frac
				UiPush()
					UiTranslate(2, 2)
					if bar_posy > 2 and UiIsMouseInRect(8, bar_posy-2) and InputPressed("lmb") then list.pos = list.pos + frac * totalVal end
					local h2 = h - 4 - bar_sizey - bar_posy
					UiTranslate(0, bar_posy + bar_sizey)
					if h2 > 0 and UiIsMouseInRect(10, h2) and InputPressed("lmb") then list.pos = list.pos - frac * totalVal end
				UiPop()

				UiTranslate(2, bar_posy)
				UiImageBox("ui/common/box-solid-4.png", 10, bar_sizey, 4, 4)
				if UiIsMouseInRect(10, bar_sizey) and InputPressed("lmb") then
					local posx, posy = UiGetMousePos()
					list.dragstarty = posy
					list.isdragging = true
				end
			UiPop()
		else
			list.pos = 0
		end

		UiWindow(w, h, true)
		UiColor(1, 1, 1, 0.07)
		UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)

		UiTranslate(10, 24)

		UiAlign("left")
		UiColor(0.95, 0.95, 0.95, 1)
		local listStart = math.floor(1-list.pos or 1)
		for i=listStart, math.min(totalVal, listStart+listingVal) do
			UiPush()
				UiTranslate(10, -18)
				UiColor(0, 0, 0, 0)
				local id = list.items[i].id
				if gModSelected == id then UiColor(1, 1, 1, 0.1) end
				if mouseOver and UiIsMouseInRect(228, 22) then
					UiColor(0, 0, 0, 0.1)
					if InputPressed("lmb") and gModSelected ~= id then
						UiSound("terminal/message-select.ogg")
						ret = id
					elseif InputPressed("rmb") and not noRmb then
						ret = id
						rmb_pushed = true
					end
				end
				UiRect(w, 22)
			UiPop()

			if list.items[i].override then
				UiPush()
					UiTranslate(-10, -18)
					if mouseOver and UiIsMouseInRect(22, 22) and InputPressed("lmb") then
						list.items[i].active = toggleMod(list.items[i].id, list.items[i].active)
						needUpdate = true
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
				if issubscribedlist and list.items[i].showbold then UiFont("bold.ttf", 20) end
				UiText(list.items[i].name)
			UiPop()
			UiTranslate(0, 22)
		end
		if not rmb_pushed and mouseOver and InputPressed("rmb") then rmb_pushed = true end
	UiPop()

	if needUpdate then updateCollections(true) updateMods() end
	return ret, rmb_pushed
end

function listCollections(list, w, h)
	local ret = gCollectionSelected
	local rmb_pushed = false
	local listingVal = math.ceil((h-10)/22)-1
	local totalVal = #list
	if gCollectionMain.isdragging and InputReleased("lmb") then gCollectionMain.isdragging = false end

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
			if gCollectionMain.isdragging then
				local posx, posy = UiGetMousePos()
				local dy = 0.0445 * (posy - gCollectionMain.dragstarty)
				gCollectionMain.pos = -dy / frac
			end
			gCollectionMain.pos = clamp(gCollectionMain.pos, -scrollCount, 0)
			local pos = -gCollectionMain.pos / totalVal

			UiPush()
				UiTranslate(w, 0)
				UiColor(1, 1, 1, 0.07)
				UiImageBox("ui/common/box-solid-4.png", 14, h, 4, 4)
				UiColor(1, 1, 1, 0.2)

				local bar_posy = 2 + pos*(h-4)
				local bar_sizey = (h-4)*frac
				UiPush()
					UiTranslate(2, 2)
					if bar_posy > 2 and UiIsMouseInRect(8, bar_posy-2) and InputPressed("lmb") then gCollectionMain.pos = gCollectionMain.pos + frac * totalVal end
					local h2 = h - 4 - bar_sizey - bar_posy
					UiTranslate(0, bar_posy + bar_sizey)
					if h2 > 0 and UiIsMouseInRect(10, h2) and InputPressed("lmb") then gCollectionMain.pos = gCollectionMain.pos - frac * totalVal end
				UiPop()

				UiTranslate(2, bar_posy)
				UiImageBox("ui/common/box-solid-4.png", 10, bar_sizey, 4, 4)
				if UiIsMouseInRect(10, bar_sizey) and InputPressed("lmb") then
					local posx, posy = UiGetMousePos()
					gCollectionMain.dragstarty = posy
					gCollectionMain.isdragging = true
				end
			UiPop()
		else
			gCollectionMain.pos = 0
		end

		UiWindow(w, h, true)
		UiColor(1, 1, 1, 0.07)
		UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)

		UiTranslate(10, 24)

		UiAlign("left")
		UiColor(0.95, 0.95, 0.95, 1)
		local listStart = math.floor(1-gCollectionMain.pos or 1)
		for i=listStart, math.min(totalVal, listStart+listingVal) do
			UiPush()
				UiTranslate(20, -18)
				UiColor(0, 0, 0, 0)
				if gCollectionSelected == i then UiColor(1, 1, 1, 0.1) end
				if mouseOver and UiIsMouseInRect(228, 22) then
					UiColor(0, 0, 0, 0.1)
					if InputPressed("lmb") and gCollectionSelected ~= i then
						UiSound("terminal/message-select.ogg")
						collectionReset()
						ret = i
					elseif InputPressed("rmb") then
						ret = i
						rmb_pushed = true
					end
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
					if gCollectionName == "" then UiColor(1, 1, 1, 0.5) end
					UiText(gCollectionName ~= "" and gCollectionName or locLang.renameCol)
				else
					UiText(list[i].name)
				end
			UiPop()
			UiTranslate(0, 22)
		end

		if not rmb_pushed and mouseOver and InputPressed("rmb") then rmb_pushed = true end
	UiPop()
	return ret, rmb_pushed
end

function listCollectionMods(mainList, w, h, selected)
	local needUpdate = false
	local list = mainList[selected]
	local ret = ""
	local rmb_pushed = false
	local listingVal = math.ceil((h-10)/22)-1
	if gCollectionList.isdragging and InputReleased("lmb") then gCollectionList.isdragging = false end

	UiPush()
		UiAlign("top left")
		UiFont("regular.ttf", 22)
		local itemsInView = math.floor(h/UiFontHeight())
		if not list then
			UiPush()
				UiColor(1, 1, 1, 0.07)
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
			if gCollectionList.isdragging then
				local posx, posy = UiGetMousePos()
				local dy = 0.0445 * (posy - gCollectionList.dragstarty)
				gCollectionList.pos = -dy / frac
			end
			gCollectionList.pos = clamp(gCollectionList.pos, -scrollCount, 0)
			local pos = -gCollectionList.pos / totalVal

			UiPush()
				UiTranslate(w, 0)
				UiColor(1, 1, 1, 0.07)
				UiImageBox("ui/common/box-solid-4.png", 14, h, 4, 4)
				UiColor(1, 1, 1, 0.2)

				local bar_posy = 2 + pos*(h-4)
				local bar_sizey = (h-4)*frac
				UiPush()
					UiTranslate(2, 2)
					if bar_posy > 2 and UiIsMouseInRect(8, bar_posy-2) and InputPressed("lmb") then gCollectionList.pos = gCollectionList.pos + frac * totalVal end
					local h2 = h - 4 - bar_sizey - bar_posy
					UiTranslate(0, bar_posy + bar_sizey)
					if h2 > 0 and UiIsMouseInRect(10, h2) and InputPressed("lmb") then gCollectionList.pos = gCollectionList.pos - frac * totalVal end
				UiPop()

				UiTranslate(2, bar_posy)
				UiImageBox("ui/common/box-solid-4.png", 10, bar_sizey, 4, 4)
				if UiIsMouseInRect(10, bar_sizey) and InputPressed("lmb") then
					local posx, posy = UiGetMousePos()
					gCollectionList.dragstarty = posy
					gCollectionList.isdragging = true
				end
			UiPop()
		else
			gCollectionList.pos = 0
		end

		UiWindow(w, h, true)
		UiColor(1, 1, 1, 0.07)
		UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)

		UiTranslate(10, 24)

		UiAlign("left")
		UiColor(0.95, 0.95, 0.95, 1)
		local listStart = math.floor(1-gCollectionList.pos or 1)
		for i=listStart, math.min(totalVal, listStart+listingVal) do
			UiPush()
				UiTranslate(10, -18)
				UiColor(0, 0, 0, 0)
				local id = list.items[i].id
				if gModSelected == id then UiColor(1, 1, 1, 0.1) end
				if mouseOver and UiIsMouseInRect(228, 22) then
					UiColor(0, 0, 0, 0.1)
					if InputPressed("lmb") and gModSelected ~= id then
						UiSound("terminal/message-select.ogg")
						ret = id
					elseif InputPressed("rmb") then
						ret = id
						rmb_pushed = true
					end
				end
				UiRect(w, 22)
			UiPop()

			if list.items[i].override then
				UiPush()
				UiTranslate(-10, -18)
				if UiIsMouseInRect(22, 22) and InputPressed("lmb") then
					list.items[i].active = toggleMod(list.items[i].id, list.items[i].active)
					needUpdate = true
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
		if not rmb_pushed and mouseOver and InputPressed("rmb") then rmb_pushed = true end
	UiPop()

	if needUpdate then updateCollections(true) updateMods() updateSearch() end
	return ret, rmb_pushed
end

function drawFilter(filter, sort, order, isWorkshop)
	local button1w = 120
	local button2w = 184
	local button3w = 28
	local buttonH = 26
	local verticalOff = -11
	local needUpdate = false
	UiPush()
		UiAlign("top left")
		UiFont("regular.ttf", 19)
		UiColor(1, 1, 1, 0.8)
		UiPush()
			UiTranslate(button1w/2, verticalOff)
			UiAlign("center")
			UiButtonImageBox("ui/common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)
			if UiTextButton(filterCategoryText[filter+1], button1w, buttonH) then
				filter = (filter+1)%5
				if not isWorkshop and filter == 1 then filter = 2 end
				needUpdate = true
			end
		UiPop()
		UiPush()
			UiTranslate(button1w+button2w/2+1, verticalOff)
			UiAlign("center")
			UiButtonImageBox("ui/common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)
			if isWorkshop then
				if UiTextButton(filterSortText[sort+1], button2w, buttonH) then
					sort = (sort+1)%3
					needUpdate = true
				end
			else
				UiTextButton(filterSortText[1], button2w, buttonH)
			end
		UiPop()
		UiPush()
			UiTranslate(button1w+button2w+2, verticalOff)
			UiAlign("center")
			UiButtonImageBox("ui/common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)
			UiPush()
				UiTranslate(button3w/2, -6)
				UiAlign("center middle")
				UiRotate(order and 90 or -90)
				if UiImageButton("ui/common/play.png", buttonH, button3w) then order = not order needUpdate = true end
			UiPop()
		UiPop()
	UiPop()
	return filter, sort, order, needUpdate
end

function drawCreate()
	local open = true
	if initSelect then
		if gModSelected == "" and GetBool(nodes.Settings..".rememberlast") then gModSelected = GetString(nodes.Settings..".rememberlast.last") end
		if not HasKey("mods.available."..gModSelected) then gModSelected = "" end
		initSelect = false
	end

	local w = 758 + 810
	local h = 940
	local listW = 334
	local listH = 22*28+10
	local mainW = 810
	local mainH = listH+28
	local buttonW = 270
	UiPush()
		UiTranslate(UiCenter(), UiMiddle())
		UiColor(0, 0, 0, 0.5)
		UiAlign("center middle")
		UiImageBox("ui/common/box-solid-shadow-50.png", w, h, -50, -50)
		UiWindow(w, h)
		UiAlign("left top")
		UiColor(0.96, 0.96, 0.96)
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
			-- title
			UiPush()
				UiAlign("top left")
				UiColor(1, 1, 1)
				if gRefreshFade > 0.1 then
					UiPush()
						UiTranslate(38, 100)
						UiFont("bold.ttf", 24)
						UiColorFilter(0.8, 0.8, 0.8, gRefreshFade)
						UiText(locLang.modsRefreshed)
					UiPop()
				end
				UiPush()
					UiFont("bold.ttf", 80)
					UiTranslate(26, 26)
					if UiTextButton("loc@UI_TEXT_MODS", 134, 44) then
						gRefreshFade = 1
						SetValue("gRefreshFade", 0, "easein", 1.5)
						updateMods()
						updateCollections()
					end
				UiPop()
				UiPush()
					UiTranslate(30, 136)
					UiFont("bold.ttf", 25)
					if gShowSetting then UiColor(0.95, 0.8, 0.5) end
					if UiTextButton(locLang.settings) then gShowSetting = not gShowSetting end
				UiPop()
				UiTranslate(listW+30, 40)
				UiColor(0.8, 0.8, 0.8, 0.75)
				UiRect(2, 120)
			UiPop()

			-- desc&link / settings
			if not gShowSetting then
				UiPush()
					UiFont("regular.ttf", 22)
					UiTranslate(UiCenter(), 70)
					UiAlign("center")
					UiColor(0.8, 0.8, 0.8)
					UiWordWrap(780)
					UiText("loc@UI_TEXT_CREATE_YOUR", true)
					UiFont("bold.ttf", 22)
					UiColor(0.95, 0.8, 0.5)
					if UiTextButton("www.teardowngame.com/modding") then Command("game.openurl", webLinks.gameModding) end
				UiPop()
			else
				local boxSize = 36
				UiPush()
					UiTranslate(UiCenter()-370, 68)
					UiAlign("left")
					UiColor(0.85, 0.85, 0.85)
					UiFont("regular.ttf", 22)
					for _, setting in ipairs(optionSettings) do
						local xOff = 0
						if setting[3] == "bool" then
							UiPush()
								UiAlign("left middle")
								UiTranslate(-6, -5)
								UiButtonImageBox("ui/common/box-outline-4.png", 16, 16, 1, 1, 1, 0.75)
								UiScale(0.5)
								local currSetting = GetBool(nodes.Settings.."."..setting[2])
								if currSetting then
									if UiImageButton("ui/hud/checkmark.png", boxSize, boxSize) then SetBool(nodes.Settings.."."..setting[2], not currSetting) end
								else
									if UiBlankButton(boxSize, boxSize) then SetBool(nodes.Settings.."."..setting[2], not currSetting) end
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
								UiTranslate(-6, -5)
								UiPush()
									UiColor(1, 1, 1, 0.15)
									UiImageBox("ui/common/box-solid-4.png", 138, 25, 1, 1)
								UiPop()
								UiColor(0.95, 0.95, 0.95)
								local currSetting = GetInt(nodes.Settings.."."..setting[2])
								if UiTextButton(categoryTextLookup[currSetting+1], 140, boxSize-3) then SetInt(nodes.Settings.."."..setting[2], (currSetting+1)%3) end
							UiPop()
							UiPush()
								UiAlign("left middle")
								UiColor(0.85, 0.85, 0.85)
								UiTranslate(150, -5)
								local txw = UiText(setting[1])
							UiPop()
							xOff = xOff + 150 + txw + 5
						end
						if setting[5] then
							UiPush()
								UiAlign("left middle")
								UiFont("regular.ttf", 22)
								UiColor(0.95, 0.45, 0)
								UiTranslate(xOff, -3)
								UiText(setting[5])
							UiPop()
						end
						UiTranslate(0, 22)
					end
				UiPop()
			end

			-- project related
			UiPush()
				UiAlign("top right")
				UiPush()
					UiTranslate(w-38, 40)
					UiFont("bold.ttf", 32)
					UiColor(0.94, 0.94, 0.94)
					UiText("Mod Menu Revamped", true)
					UiFont("regular.ttf", 20)
					UiColor(0.8, 0.8, 0.8)
					UiText(menuVer)
				UiPop()
				UiPush()
					UiTranslate(w-30, 136)
					UiFont("bold.ttf", 22)
					UiColor(0.95, 0.8, 0.5)
					if UiTextButton("Github") then Command("game.openurl", webLinks.projectGithub) end
					UiTranslate(-80, 0)
					if UiTextButton("Crowdin") then Command("game.openurl", webLinks.projectCrowdin) end
				UiPop()
				UiTranslate(w-listW-30, 40)
				UiColor(0.8, 0.8, 0.8, 0.75)
				UiRect(2, 120)
			UiPop()

			UiTranslate(30, 224)

			-- mod listing
			UiPush()
				-- category / search
				UiPush()
					UiAlign("left bottom")
					UiTranslate(0, -4)
					UiFont("bold.ttf", 28)
					UiButtonHoverColor(0.77, 0.77, 0.77)
					UiButtonPressDist(0.5)
					UiButtonImageBox("ui/common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)
					if gSearchText ~= "" then
						if UiTextButton("loc@UI_TEXT_SEARCH", listW, 36) then
							gSearchText = ""
							local modPrefix = gModSelected:match("^(%w+)-")
							local index = category.Lookup[modPrefix]
							category.Index = index and index or category.Index
						end
					else
						if UiTextButton(gMods[category.Index].title, listW, 36) then
							category.Index = category.Index%3+1
							gModSelected = ""
						end
					end
				UiPop()

				UiTranslate(0, 28)

				-- filter
				UiPush()
					UiTranslate(0, 2)
					if gSearchText == "" then
						local needUpdate = false
						gMods[category.Index].filter, gMods[category.Index].sort, gMods[category.Index].sortInv, needUpdate
						= drawFilter(gMods[category.Index].filter, gMods[category.Index].sort, gMods[category.Index].sortInv, category.Index == 2)
						if needUpdate then updateMods() end
					else
						local needUpdate = false
						gSearch.filter, gSearch.sort, gSearch.sortInv, needUpdate = drawFilter(gSearch.filter, gSearch.sort, gSearch.sortInv)
						if needUpdate then updateSearch() end
					end
				UiPop()
				local h = category.Index == 2 and listH-44 or listH
				local selected, rmb_pushed

				if gSearchText ~= "" then
					selected = listMods(gSearch, listW, h, false, true)
					if selected ~= "" then selectMod(selected) end
				else
					selected, rmb_pushed = listMods(gMods[category.Index], listW, h, category.Index==2)
					if selected ~= "" then
						selectMod(selected)
						if category.Index==2 then updateMods() updateCollections(true) end
					end
				end

				if gSearchText == "" and rmb_pushed then
					contextMenu.Show = true
					contextMenu.Type = category.Index
					SetValueInTable(contextMenu, "Scale", 1, "bounce", 0.35)
					contextMenu.Item = selected
					contextMenu.GetMousePos = true
				end

				if category.Index==2 then
					UiPush()
						if not GetBool("game.workshop") then 
							UiPush()
								UiFont("regular.ttf", 20)
								UiTranslate(50, 110)
								UiColor(0.7, 0.7, 0.7)
								UiText("loc@UI_TEXT_STEAM_WORKSHOP")
							UiPop()
							UiDisableInput()
							UiColorFilter(1, 1, 1, 0.5)
						end
						UiTranslate(0, listH-38)
						UiFont("regular.ttf", 24)
						UiButtonImageBox("ui/common/box-solid-6.png", 6, 6, 1, 1, 1, 0.1)
						if UiTextButton("loc@UI_BUTTON_MANAGE_SUBSCRIBED", listW, 38) then Command("mods.browse") end
					UiPop()
				end
				if InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and (InputPressed("lmb") or InputPressed("rmb"))) then contextMenu.Show = false end
			UiPop()

			UiColor(0, 0, 0, 0.1)
			UiTranslate(listW+15, 0)

			-- mod info
			UiPush()
				local modKey = "mods.available."..gModSelected
				local modKeyShort = gModSelected
				UiAlign("left")
				UiColor(1, 1, 1, 0.07)
				UiImageBox("ui/common/box-solid-6.png", mainW, mainH, 6, 6)
				UiWindow(mainW, mainH)
				if gModSelected ~= "" then
					local modPrefix = gModSelected:match("^(%w+)-")
					local modCategory = category.Lookup[modPrefix]
					local unknownMod = false
					local name = GetString(modKey..".name")
					if gModSelected ~= "" and name == "" then name = "loc@NAME_UNKNOWN" unknownMod = true end
					local author = GetString(modKey..".author")
					if gModSelected ~= "" and author == "" then author = "loc@NAME_UNKNOWN" end
					local authorList = strSplit(author, ",")
					local tags = GetString(modKey..".tags")
					local tagList = strSplit(tags, ",")
					local description = GetString(modKey..".description")
					local timestamp = GetString(modKey..".timestamp")
					local modPath = GetString(modKey..".path")
					if modCategory == 1 then modPath = GetString("game.path").."/"..modPath end
					local previewPath = "RAW:"..modPath.."/preview.jpg"
					if not HasFile(previewPath) then previewPath = "RAW:"..modPath.."/preview.png" end
					local hasPreview = HasFile(previewPath)
					local idPath = "RAW:"..modPath.."/id.txt"
					local hasId = modPrefix == "steam"
					if not hasId then hasId = HasFile(idPath) end
					local isLocal = GetBool(modKey..".local")
					
					UiPush()
						UiAlign("top left")
						UiTranslate(30, 16)
						UiColor(1, 1, 1, 1)
						UiFont("bold.ttf", 32)
						UiText(name)
						UiFont("regular.ttf", 20)
						UiTranslate(0, 40)

						UiPush()
							local poW, poH = 270, 270
							local textWmax = mainW-30*2-poW-35
							local authGap = 12
							if hasPreview then
								local pw, ph = UiGetImageSize(previewPath)
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
									UiColor(1, 1, 1)
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
									UiWordWrap(200)
									UiTextAlignment("center")
									UiText("loc@UI_TEXT_NO_PREVIEW")
								UiPop()
							end

							UiTranslate(poW+30, 0)
							UiWindow(textWmax, poH, true)

							if author ~= "" then
								UiText(locLangStrAuthor)
								UiAlign("top left")
								UiTranslate(68, 0)
								local countDist = 0
								for i, auth in ipairs(authorList) do
									UiWordWrap(textWmax-68)
									local authW, authH = UiGetTextSize(auth)
									local transX, transY = authW+authGap, 0
									if authH > 26 then
										if countDist > 0 then UiTranslate(-countDist, 24) end
										countDist = 0
										transX, transY = 0, authH
									elseif countDist + authW+authGap > textWmax-68 then
										UiTranslate(-countDist, 24)
										countDist = 0
										transX = authW+authGap
									end
									UiTextButton(auth)
									UiTranslate(transX, transY)
									countDist = countDist + transX
								end
								UiTranslate(-68-countDist, 24)
							end
							if tags ~= "" then
								UiText("loc@UI_TEXT_TAGS", true)
								UiTranslate(0, 4)
								UiButtonImageBox("ui/common/box-outline-4.png", 8, 8, 1, 1, 1, 0.7)
								UiButtonHoverColor(1, 1, 1)
								UiButtonPressColor(1, 1, 1)
								UiButtonPressDist(0)
								local countDist = 0
								for i, tag in ipairs(tagList) do
									local tagW, tagH = UiGetTextSize(tag)
									if countDist + tagW+24 > textWmax then
										UiTranslate(-countDist, 26)
										countDist = 0
									end
									UiTextButton(tag, tagW+6, 24)
									UiTranslate(tagW+24)
									countDist = countDist + tagW+24
								end
							end
						UiPop()
						UiTranslate(0, poH+16)

						UiWindow(mainW-30*3-buttonW, 240, true)
						UiWordWrap(mainW-30*3-buttonW-5)
						UiFont("regular.ttf", 20)
						UiColor(.9, .9, .9)
						UiText(description)
					UiPop()

					UiPush()
						UiColor(1, 1, 1, 1)
						UiFont("regular.ttf", 16)
						UiTranslate(30, mainH - 24)
						if timestamp ~= "" then
							UiColor(0.5, 0.5, 0.5)
							UiText(locLangStrUpdateAt..timestamp, true)
						end
					UiPop()

					UiColor(1, 1, 1)
					UiFont("regular.ttf", 24)
					UiButtonImageBox("ui/common/box-outline-6.png", 6, 6, 1, 1, 1, 0.7)
					UiAlign("center middle")

					local modButtonH = 40
					local modButtonT = 50
					-- redesign (webpages)
					-- damn you saber for spending so long only to failed in implmenting UiButtonTextHandling() mode 1

					-- edit/copy, details, publish
					UiPush()
						UiTranslate(mainW-buttonW/2-30, mainH-340)
						if isLocal then
							if GetBool(modKey..".playable") then
								UiTranslate(0, modButtonT)
								UiPush()
									if UiTextButton("loc@UI_BUTTON_EDIT", buttonW, modButtonH) then Command("mods.edit", gModSelected) end
								UiPop()
							end
							UiTranslate(0, modButtonT)
							UiPush()
								if not GetBool("game.workshop")or not GetBool("game.workshop.publish") then 
									UiDisableInput()
									UiColorFilter(1, 1, 1, 0.5)
								end
								if UiTextButton("loc@UI_BUTTON_PUBLISH", buttonW, modButtonH) then
									gPublishLangTitle = nil
									gPublishLangDesc = nil
									gPublishLangIndex = locLang.INDEX
									gPublishDropdown = false
									gPublishLangReload = false
									SetValue("gPublishScale", 1, "cosine", 0.25)
									Command("mods.publishbegin", gModSelected)
								end
								if not GetBool("game.workshop.publish") then
									UiTranslate(0, 30)
									UiFont("regular.ttf", 18)
									UiText("loc@UI_TEXT_UNAVAILABLE_IN")
								end
							UiPop()
						end
						if not isLocal and not unknownMod then
							UiTranslate(0, modButtonT)
							UiPush()
								if UiTextButton("loc@UI_BUTTON_MAKE_LOCAL", buttonW, modButtonH) then
									Command("mods.makelocalcopy", gModSelected)
									updateMods()
									updateSearch()
								end
							UiPop()
						end
						if hasId then
							UiTranslate(0, modButtonT)
							UiPush()
								if isLocal then
									if prevSelectMod ~= gModSelected then Command("mods.publishbegin", gModSelected) end
									if UiTextButton("loc@UI_TEXT_DETAILS", buttonW, modButtonH) then Command("game.openurl", "https://steamcommunity.com/sharedfiles/filedetails/?id="..GetString("mods.publish.id")) end
								else
									if UiTextButton("loc@UI_TEXT_DETAILS", buttonW, modButtonH) then Command("mods.browsesubscribed", gModSelected) end
								end
							UiPop()
						end
					UiPop()

					-- play/enable, options
					UiPush()
						UiTranslate(mainW-buttonW/2-30, mainH+10)
						if GetBool(modKey..".playable") then
							UiTranslate(0, -modButtonT)
							UiPush()
								UiPush()
									UiColor(.7, 1, .8, 0.2)
									UiImageBox("ui/common/box-solid-6.png", buttonW, modButtonH, 6, 6)
								UiPop()
								if UiTextButton("loc@UI_BUTTON_PLAY", buttonW, modButtonH) then
									Command("mods.play", gModSelected)
								end
							UiPop()
						elseif GetBool(modKey..".override") then
							UiTranslate(0, -modButtonT)
							UiPush()
								if GetBool(modKey..".active") or GetBool(modKeyShort..".active") then
									if UiTextButton("loc@UI_BUTTON_ENABLED", buttonW, modButtonH) then
										Command("mods.deactivate", gModSelected)
										updateMods()
										updateCollections(true)
										updateSearch()
									end
									UiColor(1, 1, 0.5)
									UiTranslate(-60, 0)
									UiImage("ui/menu/mod-active.png")
								else
									if UiTextButton("loc@UI_BUTTON_DISABLED", buttonW, modButtonH) then
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
						if GetBool(modKey..".options") then
							UiTranslate(0, -modButtonT)
							UiPush()
								if UiTextButton("loc@UI_BUTTON_OPTIONS", buttonW, modButtonH) then Command("mods.options", gModSelected) end
							UiPop()
						end
					UiPop()

					-- path
					if isLocal or GetBool(nodes.Settings..".showpath."..modCategory) then
						UiPush()
							UiTranslate(UiCenter(), mainH+5)
							UiColor(0.5, 0.5, 0.5)
							UiFont("regular.ttf", 18)
							UiAlign("center top")
							local w, h = UiGetTextSize(modPath)
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
				UiTranslate(0, -4)
				UiAlign("left")
				local tw = mainW
				local th = 36
				UiTranslate(0, -th)
				UiColor(1, 1, 1, 0.07)
				UiImageBox("ui/common/box-solid-4.png", tw, th, 4, 4)
				if InputPressed("lmb") or InputPressed("rmb") then
					gSearchClick = UiIsMouseInRect(tw, th) or gSearchClick
					gSearchFocus = UiIsMouseInRect(tw, th)
					gCollectionFocus = UiIsMouseInRect(tw, th) and false or gCollectionFocus
					gCollectionTyping = UiIsMouseInRect(tw, th) and false or gCollectionTyping
				end
				UiColor(1, 1, 1)
				UiFont("regular.ttf", 22)
				local newSearch = ""
				if gSearchClick then
					if gCollectionClick then gCollectionClick = false else newSearch, gSearchTyping = UiTextInput(gSearchText, tw, th, gSearchFocus) end
				end
				if string.len(newSearch) > 40 then newSearch = string.sub(newSearch, 1, 40) end
				gSearchFocus = false
				if gSearchText == "" then
					UiColor(1, 1, 1, 0.5)
					UiTranslate(4, 26)
					UiText(locLang.searchMod)
					local modPrefix = gModSelected:match("^(%w+)-")
					local index = category.Lookup[modPrefix]
					category.Index = index and index or category.Index
				else
					UiTranslate(tw-24, 9)
					UiColor(1, 1, 1)
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

			UiColor(0, 0, 0, 0.1)
			UiTranslate(mainW+15, 0)

			-- collections
			UiPush()
				UiFont("bold.ttf", 22)
				UiAlign("left")
				UiPush()
					local tw = listW
					local th = 36
					UiTranslate(0, -th-4)
					if errorData.Fade > 0.05 then
						UiPush()
							UiAlign("bottom left")
							UiTranslate(0, -4)
							UiWordWrap(tw-14)
							UiFont("regular.ttf", 20)
							UiColor(1, 0.4, 0.4, errorData.Fade)
							UiText(errorData.List[errorData.Code])
						UiPop()
					end
					UiColor(1, 1, 1, 0.07)
					UiImageBox("ui/common/box-solid-4.png", tw, th, 4, 4)
					if InputPressed("lmb") or InputPressed("rmb") then
						gCollectionClick = UiIsMouseInRect(tw, th)
						gCollectionFocus = UiIsMouseInRect(tw, th)
						gSearchFocus = UiIsMouseInRect(tw, th) and false or gSearchFocus
						gSearchTyping = UiIsMouseInRect(tw, th) and false or gSearchTyping
						gCollectionRename = UiIsMouseInRect(tw, th) and gCollectionRename or false
					end
					UiColor(1, 1, 1)
					UiFont("regular.ttf", 22)
					local newText = ""
					if gCollectionClick then
						if gSearchClick then gSearchClick = false else newText, gCollectionTyping = UiTextInput(gCollectionName, tw, th, gCollectionFocus) end
					end
					if string.len(newText) > 20 then newText = string.sub(newText, 1, 20) end
					gCollectionFocus = false
					if gCollectionName == "" then
						UiColor(1, 1, 1, 0.5)
						UiTranslate(4, 26)
						UiText(gCollectionRename and locLang.renameCol or locLang.newCol)
					else
						UiTranslate(tw-24, 9)
						UiColor(1, 1, 1)
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
							failed, errorData.Code = renameCollection(id, gCollectionName)
						else
							failed, errorData.Code = newCollection(gCollectionName)
						end
						if failed then
							errorData.Show = true
							errorData.Fade = 1
							SetValueInTable(errorData, "Fade", 0, "easein", 2.5)
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

				UiTranslate(0, listH-hcm+28)
				UiPush()
					UiPush()
						UiTranslate(0, -36)
						UiFont("bold.ttf", 22)
						UiAlign("left")
						UiColor(0.96, 0.96, 0.96, 0.9)
						UiText(locLang.collection)
						if validCollection then
							UiAlign("right")
							UiTranslate(listW, 0)
							UiText(validCollection.name)
						end
					UiPop()

					UiTranslate(0, 2)
					-- filter
					local needUpdate = false
					gCollectionList.filter, gCollectionList.sort, gCollectionList.sortInv, needUpdate
					= drawFilter(gCollectionList.filter, gCollectionList.sort, gCollectionList.sortInv)
					if needUpdate then updateCollectMods(gCollectionSelected) end
				UiPop()
				local selected, rmb_pushedM = listCollectionMods(gCollections, listW, hcm, gCollectionSelected)

				if selected ~= "" then
					selectMod(selected)
					local modPrefix = selected:match("^(%w+)-")
					category.Index = category.Lookup[modPrefix] or category.Index
				end

				if validCollection and (rmb_pushedC or (rmb_pushedM and getGlobalModCountCollection() > 0 )) then
					collectionPop = true
					SetValueInTable(contextMenu, "Scale", 1, "bounce", 0.35)
					contextMenu.Item = gCollections[gCollectionSelected].lookup
					contextMenu.IsCollection = rmb_pushedC
					contextMenu.GetMousePos = true
				end
			UiPop()
		UiPop()
	UiPop()
	return open
end

function drawLargePreview(show)
	if not show then return end
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

function drawPublish(show)
	if not show then return nil end
	UiModalBegin()
	UiBlur(gPublishScale)
	UiPush()
		local w = 900
		local h = 740
		UiTranslate(UiCenter(), UiMiddle())
		UiScale(gPublishScale)
		UiColor(0, 0, 0, 0.5)
		UiAlign("center middle")
		UiImageBox("ui/common/box-solid-shadow-50.png", w, h, -50, -50)
		UiWindow(w, h)
		UiAlign("left top")
		UiColor(1, 1, 1)

		local publish_state = GetString("mods.publish.state")
		local canEsc = publish_state ~= "uploading"
		if canEsc and (InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and InputPressed("lmb"))) then
			SetValue("gPublishScale", 0, "cosine", 0.25)
			Command("mods.publishend")
		end
		
		UiPush()
			UiFont("bold.ttf", 55)
			UiColor(1, 1, 1)
			UiAlign("center")
			UiTranslate(UiCenter(), 64)
			UiText("loc@UI_TEXT_PUBLISH_MOD")
		UiPop()
		
		local mw, mh = 320, 320
		local descW = 460
		local gap = 40

		local id = GetString("mods.publish.id")
		local modKey = "mods.available."..gModSelected
		local name = gPublishLangTitle or GetString(modKey..".name")
		local author = GetString(modKey..".author")
		local tags = GetString(modKey..".tags")
		local description = gPublishLangDesc or GetString(modKey..".description")
		local previewPath = "RAW:"..GetString(modKey..".path").."/preview.jpg"
		if not HasFile(previewPath) then previewPath = "RAW:"..GetString(modKey..".path").."/preview.png" end
		local hasPreview = HasFile(previewPath)
		local missingInfo = false

		if gPublishLangReload then
			gPublishLangReload = false
			local orgIndex = locLang.INDEX
			local selectIndex = gPublishLangIndex
			LoadLanguageTable(gPublishLangIndex)
			gPublishLangTitle = GetString(modKey..".name")
			gPublishLangDesc = GetString(modKey..".description")
			LoadLanguageTable(orgIndex)
			name = gPublishLangTitle
			description = gPublishLangDesc
			gPublishLangIndex = selectIndex
		end

		UiPush()
			UiTranslate(gap, 120)
			UiPush()
				UiWordWrap(descW)
				UiFont("bold.ttf", 40)
				UiAlign("left top")
				if name ~= "" then UiText(name) else
					UiColor(1, 0.2, 0.2)
					UiText("loc@UI_TEXT_NAME_NOT")
					UiColor(1, 1, 1)
					missingInfo = true
				end

				UiTranslate(0, 90)
				UiFont("regular.ttf", 20)

				if id ~= "0" then UiText(locLangStrWorkshopID..id, true) end
				if author ~= "" then UiText(locLangStrByAuthor..author, true) else
					UiColor(1, 0.2, 0.2)
					UiText("loc@UI_TEXT_AUTHOR_NOT", true)
					UiColor(1, 1, 1)
					missingInfo = true
				end
				if tags ~= "" then
					UiWindow(descW, 22, true)
					UiText(locLangStrModTags..tags, true)
					UiTranslate(0, 16)
				end

				UiFont("regular.ttf", 20)
				UiColor(.8, .8, .8)

				if description ~= "" then
					UiWindow(descW, 104, true)
					UiText(description, true)
				else
					UiColor(1, 0.2, 0.2)
					UiText("loc@UI_TEXT_DESCRIPTION_NOT", true)
					UiColor(1, 1, 1)
					missingInfo = true
				end
			UiPop()
			UiPush()
				UiTranslate(w-gap*2-mw, 0)
				UiPush()
					UiColor(1, 1, 1, 0.05)
					UiRect(mw, mh)
				UiPop()
				if hasPreview then
					local pw, ph = UiGetImageSize(previewPath)
					local scale = math.min(mw/pw, mh/ph)
					UiPush()
						UiTranslate(mw/2, mh/2)
						UiAlign("center middle")
						UiColor(1, 1, 1)
						UiScale(scale)
						UiImage(previewPath)
					UiPop()
				else
					UiPush()
						UiFont("regular.ttf", 20)
						UiTranslate(mw/2, mh/2)
						UiColor(1, 0.2, 0.2)
						UiAlign("center middle")
						UiText("loc@UI_TEXT_NO_PREVIEW", true)
					UiPop()
				end
			UiPop()
		UiPop()
		
		local state = GetString("mods.publish.state")
		local canPublish = (state == "ready" or state == "failed")
		local update = (id ~= "0")
		local failMessage = GetString("mods.publish.message")

		local buttonW, buttonH, buttonGap = 190, 45, 10

		UiPush()
			if missingInfo then
				canPublish = false
				failMessage = "loc@FAILMESSAGE_INCOMPLETE_INFORMATION"
			elseif not hasPreview then
				canPublish = false
				failMessage = "loc@FAILMESSAGE_PREVIEW_IMAGE"
			end

			UiAlign("bottom right")
			UiFont("regular.ttf", 24)
			UiButtonImageBox("ui/common/box-outline-6.png", 6, 6, 1, 1, 1, 0.7)

			if state == "uploading" then
				UiPush()
					UiButtonImageBox("ui/common/box-outline-6.png", 6, 6, 1, 0.55, 0.15, 0.7)
					UiColor(1, 0.55, 0.15)
					UiTranslate(w-50, h-30)
					if UiTextButton("loc@UI_BUTTON_CANCEL", buttonW, buttonH) then Command("mods.publishcancel") end
				UiPop()
				local progress = GetFloat("mods.publish.progress")
				if progress < 0.1 then progress = 0.1 end
				if progress > 0.9 then progress = 0.9 end
				UiPush()
					UiTranslate((w-350)/2, h-30-40)
					UiAlign("top left")
					UiColor(0, 0, 0)
					UiRect(350, 36)
					UiColor(1, 1, 1)
					UiTranslate(2, 2)
					UiRect(346*progress, 32)
					UiColor(0.5, 0.5, 0.5)
					UiTranslate(175, 18)
					UiAlign("center middle")
					UiText("loc@UI_TEXT_UPLOADING")
				UiPop()
			elseif state == "done" then
				UiPush()
					UiTranslate(w-50, h-30)
					if UiTextButton("loc@UI_BUTTON_DONE", buttonW, buttonH) then
						SetValue("gPublishScale", 0, "easein", 0.25)
						Command("mods.publishend")
					end
				UiPop()			
			else
				UiPush()
					local caption = update and "loc@CAPTION_PUBLISH_UPDATE" or "loc@CAPTION_PUBLISH"
					local val = GetInt("mods.publish.visibility")
					local buttonTextLookup = {
						"loc@UI_BUTTON_PUBLIC",
						"loc@UI_BUTTON_FRIENDS",
						"loc@UI_BUTTON_PRIVATE",
						"loc@UI_BUTTON_UNLISTED"
					}
					local indexLookup = {
						"loc@UI_ENGLISH",
						"loc@UI_FRENCH",
						"loc@UI_SPANISH",
						"loc@UI_ITALIAN",
						"loc@UI_GERMAN",
						"loc@UI_SCHINESE",
						"loc@UI_JAPANESE",
						"loc@UI_RUSSIAN",
						"loc@UI_POLISH",
					}

					UiTranslate(w-50, h-30)
					if not canPublish then
						UiDisableInput()
						UiColorFilter(1, 1, 1, 0.3)
					end

					if UiTextButton(caption, buttonW, buttonH) then Command("mods.publishupload") end

					UiTranslate(0, -(buttonH+buttonGap))
					if val == -1 then UiTextButton("loc@NAME_UNKNOWN", buttonW, buttonH) elseif UiTextButton(buttonTextLookup[val+1], buttonW, buttonH) then SetInt("mods.publish.visibility", (val+1)%4) end
					
					UiTranslate(0, -150)
					if UiTextButton(indexLookup[gPublishLangIndex+1], buttonW, buttonH) then gPublishDropdown = not gPublishDropdown end
					
					if gPublishDropdown then
						local dropH, dropGap = 30, 2
						local dropListH = buttonH+dropH*9+dropGap
						local close = false

						UiPush()
							UiModalBegin()
							UiAlign("center middle")
							UiTranslate(-buttonW/2, dropListH/2-buttonH)
							
							if InputPressed("esc") then gPublishDropdown, close = false, true end
							if not UiIsMouseInRect(buttonW, dropListH) and InputPressed("lmb") or InputPressed("rmb") then gPublishDropdown, close = false, true end

							UiColor(0.25, 0.25, 0.25, 0.875)
							UiImageBox("ui/common/box-solid-6.png", buttonW, dropListH, 6, 6)
							UiPush()
								UiTranslate(0, (buttonH-dropListH)/2)
								UiColor(1, 1, 1, 1)
								UiButtonImageBox("", 0, 0)
								if UiTextButton(indexLookup[gPublishLangIndex+1]) and not close then gPublishDropdown = not gPublishDropdown end
								UiTranslate(0, buttonH/2-1)
								UiColor(1, 1, 1, 0.7)
								UiRect(buttonW-4, 1)
							UiPop()
							UiColor(1, 1, 1, 0.7)
							UiImageBox("ui/common/box-outline-6.png", buttonW, dropListH, 6, 6)

							UiColor(1, 1, 1, 1)
							UiTranslate(0, buttonH-dropListH/2+dropH/2)

							for i=0, 8 do
								local rectW = buttonW-2*dropGap
								UiPush()
									UiButtonImageBox("ui/common/box-2.png", 0, 0, 0, 0, 0, 0)
									if i%2 == 0 then UiButtonImageBox("ui/common/box-2.png", 1, 1, 0.5, 0.5, 0.5, 0.125) end
									if UiTextButton(indexLookup[i+1], buttonW-dropGap*2, dropH) and not close then
										gPublishDropdown = false
										gPublishLangReload = true
										gPublishLangIndex = i
									end
								UiPop()
								UiTranslate(0, dropH)
							end
						UiPop()
					end
				UiPop()
				UiPush()
					if failMessage ~= "" then
						UiColor(1, 0.2, 0.2)
						UiTranslate(w/2, h-30-40)
						UiAlign("center middle")
						UiFont("regular.ttf", 20)
						UiWordWrap(370)
						UiText(failMessage)
					end
				UiPop()
			end
		UiPop()
	UiPop()
	UiModalEnd()
	return true
end

function drawPopElements()
	-- context menu
	if contextMenu.Show then
		if contextMenu.GetMousePos then
			contextMenu.PosX, contextMenu.PosY = UiGetMousePos()
			contextMenu.GetMousePos = false
		end
		contextMenu.Show = contextMenu.Common(contextMenu.Item, contextMenu.Type)
		if not contextMenu.Show then contextMenu.Scale = 0 end
	end

	if collectionPop then
		if contextMenu.GetMousePos then
			contextMenu.PosX, contextMenu.PosY = UiGetMousePos()
			contextMenu.GetMousePos = false
		end
		collectionPop = contextMenu.Collection(contextMenu.Item)
		if not collectionPop then contextMenu.Scale = 0 end
	end

	-- yes-no popup
	if yesNoPopPopup.show and yesNoPop() then
		yesNoPopPopup.show = false
		if yesNoPopPopup.yes and yesNoPopPopup.yes_fn ~= nil then yesNoPopPopup.yes_fn() end
		if yesNoPopPopup.no and yesNoPopPopup.no_fn ~= nil then yesNoPopPopup.no_fn() end
	end

	-- last selected mod
	if prevSelectMod ~= gModSelected and gModSelected ~= "" then SetString(nodes.Settings..".rememberlast.last", gModSelected) prevSelectMod = gModSelected end
end


ModManager = {}
ModManager.Window = Ui.Window
{
	w = 1920,
	h = 1080,
	animator = { playTime = 0.2 },

	onPreDraw = 	function(self)
		if not self.animator.isFinished then UiIgnoreNavigation() end
		SetFloat("game.music.volume", (1.0 - 0.8 * self.animator.factor))
		UiSetCursorState(UI_CURSOR_SHOW)
	end,

	onDraw = 		function(self)
		local menuOpen = false
		UiPush()
			-- if tonumber(InputLastPressedKey()) then LoadLanguageTable(InputLastPressedKey()) end
			menuOpen = drawCreate()
			drawPopElements()
			drawLargePreview(gLargePreview > 0)
			menuOpen = drawPublish(gPublishScale > 0) or menuOpen
			if not menuOpen then self:hide() end
		UiPop()
	end,

	onCreate = 		function(self) initLoc() end,

	onShow = 		function(self)
		self:refresh()
		initSelect = true
		ModManager.WindowAnimation.duration = 0.2
		ModManager.WindowAnimation:init(self)
	end,

	canRestore = 	function(self) return GetString("dev.modmanager.selectedmod") ~= "" end,

	onRestore = 	function(self)
		self:refresh()
		initSelect = true
		ModManager.WindowAnimation.duration = 0.0
		ModManager.WindowAnimation:init(self)
	end,

	onClose = 		function(self)
		ModManager.WindowAnimation.duration = 0.2
		ModManager.WindowAnimation:init(self)
		SetString("dev.modmanager.selectedmod", "")
	end,

	refresh = 		function(self)
		Command("mods.refresh")
		updateMods()
		updateCollections()
	end
}


ModManager.WindowAnimation = 
{
	duration = 0.25,
	curve = "cosine",
	progress = 0.0,


	init = 		function(self, window)
		self.duration = 0.25
		self.curve = "cosine"
		self.progress = 0.0
	end,

	play = 		function(self)
		self:reset()
		SetValueInTable(self, "progress", 1, self.curve, self.duration)
	end,

	reset = 	function(self)
		self.progress = 0.0
	end
}