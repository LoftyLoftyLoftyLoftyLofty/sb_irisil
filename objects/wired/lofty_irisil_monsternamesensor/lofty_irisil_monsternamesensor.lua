require "/scripts/util.lua"

function init()
  self.detectEntityNames = config.getParameter("detectEntityNames")
  self.detectBoundMode = config.getParameter("detectBoundMode", "CollisionArea")
  local detectArea = config.getParameter("detectArea")
  local pos = object.position()
  if type(detectArea[2]) == "number" then
    --center and radius
    self.detectArea = {
      {pos[1] + detectArea[1][1], pos[2] + detectArea[1][2]},
      detectArea[2]
    }
  elseif type(detectArea[2]) == "table" and #detectArea[2] == 2 then
    --rect corner1 and corner2
    self.detectArea = {
      {pos[1] + detectArea[1][1], pos[2] + detectArea[1][2]},
      {pos[1] + detectArea[2][1], pos[2] + detectArea[2][2]}
    }
  end

  object.setInteractive(config.getParameter("interactive", true))
  object.setAllOutputNodes(false)
  animator.setAnimationState("switchState", "off")
  self.triggerTimer = 0
end

function trigger()
  object.setAllOutputNodes(true)
  animator.setAnimationState("switchState", "on")
  object.setSoundEffectEnabled(true)
  self.triggerTimer = config.getParameter("detectDuration")
end

function onInteraction(args)
  trigger()
end

function update(dt) 
	
	if self.triggerTimer > 0 then
		self.triggerTimer = self.triggerTimer - dt
	
	elseif self.triggerTimer <= 0 then
	
		--sb.logInfo("firing")
	
		local entityIds = world.monsterQuery ( self.detectArea[1], self.detectArea[2], {
				withoutEntityId = entity.id(),
				includedTypes = self.detectEntityTypes,
				boundMode = self.detectBoundMode
			})
		
		local womp = false
	
		for i,v in ipairs(entityIds) do
			local mt = world.monsterType(v)
			--sb.logInfo(sb.print(v) .. " -> " .. sb.print(mt))
			for q, z in ipairs(self.detectEntityNames) do
				--sb.logInfo(" ->> " .. sb.print(z))
				if mt == z then
					womp = true;
				end
			end
		end
	  
		if womp == true then
			trigger()
		else
			object.setAllOutputNodes(false)
			object.setSoundEffectEnabled(false)
			animator.setAnimationState("switchState", "off")
		end
	end
end
