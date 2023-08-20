require "/scripts/lofty_irisil_util.lua"

function init()

	self.triggered = false
	self.triggeredMessage = false

	--cargo cult
	object.setInteractive(false)
	self.variableHook = config.getParameter("variableHook")
	self.messageAllPlayers = config.getParameter("messageAllPlayers")
	self.messageArgs = config.getParameter("messageArgs") or {}
	self.desiredValue = config.getParameter("value")
	
	if self.desiredValue == nil then
		self.desiredValue = true
	end
	
	--if we have a variableHook defined in the object parameters
	if self.variableHook ~= nil then
	
		--if the variable isn't already true or false in our global registry
		if world.getProperty(self.variableHook) == nil then
		
			--set it false
			while world.getProperty(self.variableHook) ~= false do
				world.setProperty(self.variableHook, false)
			end
		end
	else
		self.variableHook = "none"
	end
	
	if storage.state then
		animator.setAnimationState("switchState", "on")
		
	else
		animator.setAnimationState("switchState", "off")
	end
end

function update(dt)

	if self.variableHook ~= nil then

		if object.getInputNodeLevel(0) then
			if self.triggered == false then
				self.triggered = true
				while world.getProperty(self.variableHook) ~= self.desiredValue do
					world.setProperty(self.variableHook, self.desiredValue)
				end
				yeek("Scripted Input Switch", "SET VAR -> " .. self.variableHook .. " -> " .. sb.print(self.desiredValue))
			end

			if self.messageAllPlayers ~= nil then
				if self.triggeredMessage == false then
					self.triggeredMessage = true
					local players = world.players()
					if players ~= nil then
						for k, v in pairs(players) do
							liu_SEM(v, self.messageAllPlayers, self.messageArgs)
						end
					end
				end
			end

		else
			self.triggered = false
			self.triggeredMessage = false
		end
	end
end
