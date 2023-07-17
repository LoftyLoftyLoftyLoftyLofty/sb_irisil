require "/scripts/lofty_irisil_util.lua"

function init()

	object.setInteractive(true)
	animator.setAnimationState("firing", "off")
	storage.firing = false
	self.edge = false
	
end

function update(dt)

  --make interactive if not wired
  if object.isInputNodeConnected(0) == false then 
    object.setInteractive(true)
	
  --handle wired behavior
  else
    object.setInteractive(false)
	
	--wire on
	if object.getInputNodeLevel(0) then
	  if storage.firing ~= true then
	    if self.edge ~= true then
			storage.firing = true
			animator.setAnimationState("firing", "fire")
			self.edge = true
		end
	  end
	else 
	  self.edge = false
	end
  end
  
  handleFiringBehavior()
end

function onInteraction()
	if storage.firing ~= true then
		animator.setAnimationState("firing", "fire")
	end
end

function onNpcPlay(npcId)
	local interact = config.getParameter("npcToy.interactOnNpcPlayStart")
	if interact == nil or interact ~= false then
		onInteraction()
	end
end

function handleFiringBehavior()
	if storage.firing and animator.animationState("firing") == "off" then
		storage.firing = false
	end
end