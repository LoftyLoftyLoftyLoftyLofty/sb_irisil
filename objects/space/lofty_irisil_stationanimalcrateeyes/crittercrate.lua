require "/scripts/lofty_irisil_util.lua"

function init()

	object.setInteractive(true)
	animator.setAnimationState("firing", "off")
	storage.firing = false
	
end

function update(dt)
  object.setInteractive(true)
  handleFiringBehavior()
end

function onInteraction()
	if storage.firing ~= true then
	    --disabling this allows the player to spam it which is more fun
	    --storage.firing = true
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