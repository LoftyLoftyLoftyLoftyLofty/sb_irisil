require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/scripts/vec2.lua"
require "/scripts/lofty_irisil_util.lua"

local lofty_irisil_dungeonmanager_morphtech_originalInit = init
local lofty_irisil_dungeonmanager_morphtech_originalUpdate = update
local lofty_irisil_dungeonmanager_morphtech_originalUninit = uninit

function init()

	lofty_irisil_dungeonmanager_morphtech_originalInit()
	
	--disable this script unless the player is in the appropriate dungeon for it
	if world.type() ~= "lofty_irisil_techchallenge_irisamorph" then
		return
	end
	
	message.setHandler
	(
		"lofty_irisil_triggerSound", 
		function(_, _, tbl)
			lofty_irisil_triggerSound_morphtech(tbl)
		end
	)
	
	message.setHandler
	(
		"lofty_irisil_enterArea", 
		function(_, _, tbl)
			lofty_irisil_enterArea_morphtech(tbl)
		end
	)
	
end

--triggered when player hits an area marker
function lofty_irisil_enterArea_morphtech(tbl)

	local areaName = tbl.areaName
	local uuid = player.serverUuid()

	--enter the dungeon dialog
	if areaName == "lockmorph" then
		if world.getProperty("lofty_irisil_lockmorph_sentDialog") ~= true then
			world.setProperty("lofty_irisil_lockmorph_sentDialog", true)
			player.radioMessage("lofty_irisil_morphtech_lockmorph")
		end
	end
	
	if areaName == "unlockmorph" then
		if world.getProperty("lofty_irisil_unlockmorph_sentDialog") ~= true then
			world.setProperty("lofty_irisil_unlockmorph_sentDialog", true)
			player.radioMessage("lofty_irisil_morphtech_unlockmorph")
		end
	end
end

--triggered when the player receives a sound command
function lofty_irisil_triggerSound_morphtech(sound)
	localAnimator.playAudio(sound)
end

--prettymuch just used for handling the timer gaps between broadcasted messages
function update(dt)

	lofty_irisil_dungeonmanager_morphtech_originalUpdate(dt)

	--disable this script unless the player is in the appropriate dungeon for it
	if world.type() ~= "lofty_irisil_techchallenge_irisamorph" then
		return
	end
	
end

function uninit()
	lofty_irisil_dungeonmanager_morphtech_originalUninit()
end