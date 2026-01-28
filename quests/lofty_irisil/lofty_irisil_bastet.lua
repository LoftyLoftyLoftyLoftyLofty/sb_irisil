require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require("/quests/scripts/portraits.lua")

function init()
	setPortraits()
end

function questStart()
	quest.setObjectiveList({{"Defeat the monsters in the Scrying Room.", false}})
	quest.setCompassDirection(nil)
end

function questComplete()
	quest.setObjectiveList({{"Defeat the monsters in the Scrying Room.", true}})
	setPortraits()
	questutil.questCompleteActions()
end

function update(dt)  
	if world.getProperty("lofty_irisil_bastetDungeonComplete") then
		quest.complete()
	end
end