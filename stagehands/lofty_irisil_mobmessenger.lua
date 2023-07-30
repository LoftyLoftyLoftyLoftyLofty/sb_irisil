require "/scripts/stagehandutil.lua"
require "/scripts/lofty_irisil_util.lua"

function init()
  self.containsPlayers = {}
  self.messageType = config.getParameter("messageType")
  self.messageArgs = config.getParameter("messageArgs", {})
  self.requiredVariableHook = config.getParameter("requiredVariableHook")
  
  if config.getParameter("expectedVariableValue") ~= nil then
	self.expectedVariableValue = config.getParameter("expectedVariableValue")
  else
	self.expectedVariableValue = true
  end
  
  if type(self.messageArgs) ~= "table" then
    self.messageArgs = {self.messageArgs}
  end
  
  message.setHandler
	(
		"lofty_irisil_ACK", 
		
		function(_, _, sender)
		
			for k, entry in pairs(queue) do
			
				if k == sender then
				
					--send the initial message
					liu_SEM(k, self.messageType, preprocess(self.messageArgs))
					
					--dequeue
					table.liu_removeKey(queue,k)
					
					break
					
				end
				
			end
			
		end

	)

end

function preprocess(args)
	for k, v in pairs(args) do
		if v == "<SENDER_ID>" then
			args[k] = entity.id()
		end
	end
	
	return args
end

queue = {}

function update(dt)

  if self.requiredVariableHook ~= "none" then
	if world.getProperty(self.requiredVariableHook) ~= self.expectedVariableValue then
	  return
	end
  end

  local newPlayers = broadcastAreaQuery({ includedTypes = {"monster"} })
  local oldPlayers = table.concat(self.containsPlayers, ",")
  for _, id in pairs(newPlayers) do
    if not string.find(oldPlayers, id) then
	  queue[id] = true
    end
  end
  self.containsPlayers = newPlayers
  
  pumpQueue()
end

function pumpQueue()

	local oldPlayers = table.concat(self.containsPlayers, ",")
	
	--cull dead entries (entities queued that are no longer in our known entities table)
	local found = true
	while found == true do
		found = false
		for k, _ in pairs(queue) do
			if not string.find(oldPlayers, k) then
				table.liu_removeKey(queue, k)
				found = true
				break
			end
		end
	end

	local mID = entity.id()
	
	for k, entry in pairs(queue) do
		--spam SYN each tick, we'll dequeue the message if/when we get an ACK
		liu_SEM(k, "lofty_irisil_SYN", mID)
	end
end