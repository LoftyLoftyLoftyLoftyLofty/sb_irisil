require "/scripts/lofty_irisil_util.lua"

function init()

	--cargo cult
	object.setInteractive(false)
	self.variableHook = config.getParameter("variableHook")
	
	--if we have a variableHook defined in the object parameters
	if self.variableHook ~= nil then
	
		--if the variable isn't already true or false in our global registry
		if world.getProperty(self.variableHook) == nil then
		
			--set it false
			world.setProperty(self.variableHook, false)
		end
	else
		self.variableHook = "none"
	end
	
	--cargo cult
	if storage.state == nil then
		output(false)
		
	else
		object.setAllOutputNodes(storage.state)
		
	end
	
	if storage.state then
		animator.setAnimationState("switchState", "on")
		
	else
		animator.setAnimationState("switchState", "off")
		
	end
end

function output(state)
  if storage.state ~= state then
    storage.state = state
    object.setAllOutputNodes(state)
    if state then
	  yeek("(SERVER) Scripted Switch", entity.id() .. " ScriptedSwitch: '" .. self.variableHook .. "' -> ON")
      animator.setAnimationState("switchState", "on")
    else
	  yeek("(SERVER) Scripted Switch", entity.id() .. " ScriptedSwitch: '" .. self.variableHook .. "' -> OFF")
      animator.setAnimationState("switchState", "off")
    end
  end
end

function update(dt)
  if self.variableHook ~= nil then
    output(world.getProperty(self.variableHook, false))
  end
end
