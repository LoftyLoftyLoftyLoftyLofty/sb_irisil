require "/scripts/rect.lua"
require "/scripts/lofty_irisil_util.lua"

function init()
  self.containsPlayers = {}
  self.broadcastArea = rect.translate(config.getParameter("broadcastArea", {-8, -8, 8, 8}), entity.position())
  self.signalRegion = rect.translate(config.getParameter("signalRegion", {-8, -8, 8, 8}), entity.position())
  
  message.setHandler
	(
		"lofty_irisil_pickmeup_requestDungeonFlags", 
		
		function(_, _, sender)
			liu_SEM(sender, "lofty_irisil_pickmeup_dungeonFlags", dungeonFlags())
			yeek("(SERVER) LI-MGR-PickMeUp", entity.id() .. " - sent dungeon flags to " .. sb.print(sender))
		end
	)
	
	yeek("(SERVER) LI-MGR-PickMeUp", entity.id() .. " - manager stagehand initialized!")
end

function update(dt)
  world.loadRegion(self.signalRegion)
  queryPlayers()
end

function queryPlayers()
  local newPlayerList = world.entityQuery(rect.ll(self.broadcastArea), rect.ur(self.broadcastArea), {includedTypes = {"player"}})
  local newPlayers = {}
  for _, id in pairs(newPlayerList) do
    if not self.containsPlayers[id] then
      liu_SEM(id, "lofty_irisil_pickmeup_manager_ID", entity.id())
	  yeek("(SERVER) LI-MGR-PickMeUp", entity.id() .. " - sent dungeon mgr ID to " .. sb.print(id))
    end
    newPlayers[id] = true
  end
  self.containsPlayers = newPlayers
end

function dungeonFlags()
	return 1
end