require "/scripts/rect.lua"
require "/scripts/lofty_irisil_util.lua"

function init()
  self.containsPlayers = {}
  self.broadcastArea = rect.translate(config.getParameter("broadcastArea", {-8, -8, 8, 8}), entity.position())
  self.signalRegion = rect.translate(config.getParameter("signalRegion", {-8, -8, 8, 8}), entity.position())
  
  message.setHandler
	(
		"lofty_irisil_stagehandRegistration", 
		
		function(_, _, sender)
			yeek("(SERVER) LI-MGR-PickMeUp", entity.id() .. " - received stagehand registration for entity with ID: " .. sb.print(sender))
			--this is the part where we ping the stagehand to figure out what type the stagehand is
		end
	)
  
  message.setHandler
	(
		"lofty_irisil_pickmeup_requestDungeonFlags", 
		
		function(_, _, sender)
			liu_SEM(sender, "lofty_irisil_pickmeup_dungeonFlags", dungeonFlags())
			yeek("(SERVER) LI-MGR-PickMeUp", entity.id() .. " - sent dungeon flags to " .. sb.print(sender))
		end
	)
	
  message.setHandler
	(
		"lofty_irisil_managerAccepted", 
		
		function(_, _, sender)
			coordinatorACK = true
			yeek("(SERVER) LI-MGR-PickMeUp", entity.id() .. " - got ACK from coordinator: " .. sb.print(sender))
		end
	)
	
	yeek("(SERVER) LI-MGR-PickMeUp", entity.id() .. " - manager stagehand initialized!")
end

function update(dt)
  world.loadRegion(self.signalRegion)
  queryPlayers()
  findCoordinator()
  SYNcoordinator()
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

coordinator = nil
coordinatorACK = false
function findCoordinator()
	
	if coordinator ~= nil then return end
	
	yeek("LI-MGR-PickMeUp", entity.id() .. " - seeking coordinator")
	local finder = world.entityQuery({-9999,-9999}, {9999,9999}, {includedTypes = {"monster"}})
	for _, id in pairs(finder) do
		if world.entityUniqueId(id) == "coordinator" then
			yeek("(SERVER) LI-MGR-PickMeUp", entity.id() .. " - coordinator identified: " .. id)
			coordinator = id
			break
		end
	end
end

function SYNcoordinator()
	if coordinatorACK == true then return end
	
	if coordinator ~= nil then
		yeek("(SERVER) LI-MGR-PickMeUp", entity.id() .. " - SYNing coordinator")
		liu_SEM(coordinator, "lofty_irisil_registerManager", entity.id())
	end
end
