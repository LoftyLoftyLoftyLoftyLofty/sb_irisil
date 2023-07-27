require "/scripts/lofty_irisil_util.lua"

function init()
  if storage.state == nil then storage.state = config.getParameter("defaultLightState", true) end

  self.interactive = config.getParameter("interactive", true)
  object.setInteractive(self.interactive)

  if config.getParameter("inputNodes") then
    processWireInput()
  end

  setLightState(storage.state)
end

function onNodeConnectionChange(args)
  processWireInput()
end

function onInputNodeChange(args)
  processWireInput()
end

function onInteraction(args)
  if not config.getParameter("inputNodes") or not object.isInputNodeConnected(0) then
    storage.state = not storage.state
    setLightState(storage.state)
  end
end

function processWireInput()
  if object.isInputNodeConnected(0) then
    object.setInteractive(false)
	
	--only send sound pings to players if the state actually changed
	if storage.state ~= object.getInputNodeLevel(0) then
	
		--only send sound pings to players if the state is also on
		if object.getInputNodeLevel(0) ~= false then
			for _, k in pairs( world.players()) do
				liu_SEM(k, "lofty_irisil_triggerSound", config.getParameter("sfx"))
			end
		end
		
	end
	
    storage.state = object.getInputNodeLevel(0)
    setLightState(storage.state)
  elseif self.interactive then
    object.setInteractive(true)
  end
end

function setLightState(newState)
  if newState then
    animator.setAnimationState("light", "on")
  else
    animator.setAnimationState("light", "off")
  end
end
