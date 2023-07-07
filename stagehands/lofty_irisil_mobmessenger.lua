require "/scripts/stagehandutil.lua"
require "/scripts/lofty_irisil_util.lua"

function init()
  self.containsPlayers = {}
  self.messageType = config.getParameter("messageType")
  self.messageArgs = config.getParameter("messageArgs", {})
  if type(self.messageArgs) ~= "table" then
    self.messageArgs = {self.messageArgs}
  end
  
  message.setHandler
	(
		"lofty_irisil_ACK", 
		
		function(_, _, sender)
		
			yeek("(SERVER) LI-MobMessenger", entity.id() .. " received ACK from ID " .. sender)
			
			for k, entry in pairs(queue) do
			
				if k == sender then
				
					--send the initial message
					liu_SEM(k, entry[QUEUE_MSG_TYPE], entry[QUEUE_MSG_PAYLOAD])
					
					--dequeue
					table.liu_removeKey(queue,k)
					
					break
					
				end
				
			end
			
		end

	)
	
	message.setHandler
	(
		"lofty_irisil_registeredWithCoordinator", 
		
		function(_, _, sender)
			yeek("(SERVER) LI-MobMessenger", entity.id() .. " registered with coordinator.")
			registered = true
		end
	)
	
	yeek("(SERVER) LI-MobMessenger", entity.id() .. " initialized trigger area!")
  
end

queue = {}
QUEUE_MSG_TYPE = 1
QUEUE_MSG_PAYLOAD = 2

function update(dt)
  local newPlayers = broadcastAreaQuery({ includedTypes = {"monster"} })
  local oldPlayers = table.concat(self.containsPlayers, ",")
  for _, id in pairs(newPlayers) do
    if not string.find(oldPlayers, id) then
	  queue[id] = { self.messageType, table.unpack(self.messageArgs) }
	  yeek("(SERVER) LI-MobMessenger", entity.id() .. " queueing ID " .. id)
      --world.sendEntityMessage(id, self.messageType, table.unpack(self.messageArgs))
    end
  end
  self.containsPlayers = newPlayers
  
  pumpQueue()
  findCoordinator()
  registerWithCoordinator()
end

function pumpQueue()

	local oldPlayers = table.concat(self.containsPlayers, ",")
	
	--cull dead entries (entities queued that are no longer in our known entities table)
	local found = true
	while found == true do
		found = false
		for k, _ in pairs(queue) do
			if not string.find(oldPlayers, k) then
				yeek("(SERVER) LI-MobMessenger", entity.id() .. " - culling ID " .. k)
				table.liu_removeKey(queue, k)
				found = true
				break
			end
		end
	end

	local mID = entity.id()
	
	for k, entry in pairs(queue) do
		yeek("(SERVER) LI-MobMessenger", entity.id() .. " - SYNing ID " .. k)
		--spam SYN each tick, we'll dequeue the message if/when we get an ACK
		liu_SEM(k, "lofty_irisil_SYN", mID)
	end
end

coordinator = nil
function findCoordinator()
	
	if coordinator ~= nil then return end
	
	yeek("(SERVER) LI-MobMessenger", entity.id() .. " - seeking coordinator")
	local finder = world.entityQuery({-9999,-9999}, {9999,9999}, {includedTypes = {"monster"}})
	for _, id in pairs(finder) do
		if world.entityUniqueId(id) == "coordinator" then
			yeek("(SERVER) LI-MobMessenger", entity.id() .. " - coordinator identified: " .. id)
			coordinator = id
			break
		end
	end
end

registered = false
function registerWithCoordinator()
	if registered == false then
		if coordinator ~= nil then 
			yeek("(SERVER) LI-MobMessenger", entity.id() .. " - registering...")
			liu_SEM(coordinator, "lofty_irisil_registerWithCoordinator", entity.id())
		end
	end
end