--NOTES:
-- enabling the activeMovementAbilities status effect prevents multiple jumps and sprint from working

require "/scripts/vec2.lua"
function init()
  initParams()
end

function initParams()

  CMD_ACTIVATE = "morphActivate"
  CMD_DEACTIVATE = "morphDeactivate"
  
  --This is used for making sure the morph doesn't clip the ground
  collisionSet = {"Null", "Block", "Dynamic", "Slippery"}
  
  --for fading in and out of morph
  transformFadeTimer = 0
  transformFadeTime = config.getParameter("transformFadeTime", 0.3)
  
  --whether or not the morph is currently active
  active = false
  
  --hide the irisa overlay
  tech.setVisible(false)
  
  --edges/levels
  lastAction = {}
  
  --allow jump noise
  goodToPlayJumpSound = true
  
  --collision and motion params
  mechCustomMovementParameters = config.getParameter("mechCustomMovementParameters")
  
  --whether or not the morph needs to flip on x axis
  flipped = false
  --used to flip the collision poly, initialized once
  polySize = #mechCustomMovementParameters.collisionPoly
  
  --how much energy the morph consumes per second while active
  energyCostPerSecond = config.getParameter("energyCostPerSecond")
  
  --used for determining whether or not there's room to unmorph
  basePoly = mcontroller.baseParameters().standingPoly

  --Links to the .animation file to use specific sfx lists when firing weapons
  eyeSFX = "fire"
  cloudSFX = "hiss"
  
  --LEFT CLICK - throw eyes at the target
  mechProjectileL = config.getParameter("mechProjectileL")
  mechProjectileL = type(mechProjectileL) == "string" and {mechProjectileL, mechProjectileL} or mechProjectileL
  mechActionL = config.getParameter("mechAction", "mechFireL")
  
  --RIGHT CLICK - make dander puffs
  mechProjectileR = config.getParameter("mechProjectileR")
  mechProjectileR = type(mechProjectileR) == "string" and {mechProjectileR, mechProjectileR} or mechProjectileR
  mechActionR = config.getParameter("mechAction", "mechFireR")
  
  --apply irisa elemental resistances while morphed
  mechStats = config.getParameter("mechStats")
  
  energyCostEye = config.getParameter("eyeEnergyCost")
  energyCostDander = config.getParameter("danderEnergyCost")
  cooldownEye = config.getParameter("eyeFireRate")
  cooldownDander = config.getParameter("danderFireRate")
  
  --when this value is <= 0, the leftclick OR rightclick can fire 
  fireTimerEye = 0
  fireTimerDander = 0
  
  powerMultiplierEye = config.getParameter("eyeDamage")
  powerMultiplierDander = config.getParameter("danderDamage")
  
  shakeit = false
  
end

function activate()
  if not active then 
    --make the noise
    animator.playSound("activate")
    --irisa on
    tech.setVisible(true)
    --hide the player
    tech.setParentHidden(true)
	--cargo cult code from distortion sphere
	tech.setParentOffset({0, 0})
	animator.translateTransformationGroup("body", {0,0.5})
    --turn the player's guns off (unfortunately this means we can't press buttons or open doors)
    tech.setToolUsageSuppressed(true)
    --set sctive flag
    active = true
    --apply elemental resistances
    status.setPersistentEffects("lofty_irisil_irisamorph", mechStats)
	--fzde timer
	transformFadeTimer = transformFadeTime
	--not required but i don't want to fix particle offsets for all the other techs rn
	status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  end
end

function deactivate()
  if active then
	--sound
	animator.playSound("deactivate")
	--hide irisa layer
    tech.setVisible(false)
	--show the player
	tech.setParentHidden(false)
	--cargo cult code from distortion sphere
	tech.setParentOffset({0, 0})
	animator.resetTransformationGroup("body")
	--enable guns and stuff again
    tech.setToolUsageSuppressed(false)
	--disable active flag
    active = false
	--clear elemental resistances when no longer morphed
	status.clearPersistentEffects("lofty_irisil_irisamorph")
	--clear morph directives
	animator.setGlobalTag("directives", "")
	--fzde timer
	transformFadeTimer = -transformFadeTime
	--womp
	status.clearPersistentEffects("movementAbility")
  end
end

--this seems to be a special use function
function uninit()
  storePosition()
  deactivate()
end

function inputF(args)
  --this is an edge trigger
  if args.moves["special1"] and not lastAction["special1"] then
    if active then 
	  return CMD_DEACTIVATE
	else 
	  return CMD_ACTIVATE
	end
  end
  return nil
end

function inputLClick(args)
  if args.moves["primaryFire"] then
    return mechActionL
  end
  return nil
end

function inputRClick(args)
  if args.moves["altFire"] then
    return mechActionR
  end
  return nil
end

function minY(poly)
  local lowest = 0
  for _,point in pairs(poly) do
    if point[2] < lowest then
      lowest = point[2]
    end
  end
  return lowest
end

function positionOffset()
  return minY(mechCustomMovementParameters.collisionPoly) - minY(basePoly)
end

function transformPosition(pos)
  pos = pos or mcontroller.position()
  local groundPos = world.resolvePolyCollision(mechCustomMovementParameters.collisionPoly, {pos[1], pos[2] - positionOffset()}, 1, collisionSet)
  if groundPos then
    return groundPos
  else
    return world.resolvePolyCollision(mechCustomMovementParameters.collisionPoly, pos, 1, collisionSet)
  end
end

function restorePosition(pos)
  pos = pos or mcontroller.position()
  local groundPos = world.resolvePolyCollision(basePoly, {pos[1], pos[2] + positionOffset()}, 1, collisionSet)
  if groundPos then
    return groundPos
  else
    return world.resolvePolyCollision(basePoly, pos, 1, collisionSet)
  end
end

function storePosition()
  if self.active then
    storage.restorePosition = restorePosition()

    -- try to restore position. if techs are being switched, this will work and the storage will
    -- be cleared anyway. if the client's disconnecting, this won't work but the storage will remain to
    -- restore the position later in update()
    if storage.restorePosition then
      storage.lastActivePosition = mcontroller.position()
      mcontroller.setPosition(storage.restorePosition)
    end
  end
end

function restoreStoredPosition()
  if storage.restorePosition then
    -- restore position if the player was logged out (in the same planet/universe) with the tech active
    if vec2.mag(vec2.sub(mcontroller.position(), storage.lastActivePosition)) < 1 then
      mcontroller.setPosition(storage.restorePosition)
    end
    storage.lastActivePosition = nil
    storage.restorePosition = nil
  end
end

function updateTransformFade(dt)
  if transformFadeTimer > 0 then
    transformFadeTimer = math.max(0, transformFadeTimer - dt)
    animator.setGlobalTag("directives", string.format("?fade=FFFFFFFF;%.1f", math.min(1.0, transformFadeTimer / (transformFadeTime - 0.15))))
  elseif transformFadeTimer < 0 then
    transformFadeTimer = math.min(0, transformFadeTimer + dt)
    tech.setParentDirectives(string.format("?fade=FFFFFFFF;%.1f", math.min(1.0, -transformFadeTimer / (transformFadeTime - 0.15))))
  else
    animator.setGlobalTag("directives", "")
    tech.setParentDirectives()
  end
end

function handleInputs(args)
   --get levels/edges
  local currentInputF = inputF(args)
  
  --if currentInputF then
    --sb.logInfo("F: " .. currentInputF)
  --end
  
  local currentInputLClick = inputLClick(args)
  local currentInputRClick = inputRClick(args)
  
  --handle the F button
  
  --Attempting to ACTIVATE
  if currentInputF == CMD_ACTIVATE or currentInputF == CMD_DEACTIVATE then
    if
	  --not already active
      not active and 
	  --not transformed into something else already - this should never happen unless someone puts tech in a dumb slot
	  not status.statPositive("activeMovementAbilities") and 
	  --pressing F. this 'morphActivate' value comes from input() func
	  currentInputF == CMD_ACTIVATE and
	  --no transform while sitting
      not tech.parentLounging()
    then
      
	  --get the transformed position for the ball
	  local pos = transformPosition()
	  
	  --valid position, attempt to activate
      if pos then
        mcontroller.setPosition(pos)
        activate()
      end
	  
    --Attempting to DEACTIVATE
    elseif 
        active and 
	    currentInputF == CMD_DEACTIVATE 
    then
	  --get the unmorphed position for the character
      local pos = restorePosition()

	  --handle activate and deactivate for the tech challenge
	  if world.type() == "lofty_irisil_techchallenge_irisamorph" then
	  	local locked = world.getProperty("lofty_irisil_lockmorph")
	  	if locked == false then
	  		if pos then
	  			mcontroller.setPosition(pos)
	  			deactivate()
	  		end
	  	else
	  		local unlocked = world.getProperty("lofty_irisil_unlockmorph")
	  		if unlocked then
	  			if pos then
	  				mcontroller.setPosition(pos)
	  				deactivate()
	  			end
	  		else
	  			animator.playSound("error")
	  		end
	  	end
	  	--if it's not a tech challenge world just deactivate
	  	else
	  	if pos then
	  		mcontroller.setPosition(pos)
	  		deactivate()
	  	end
	  end
    end
  end
  
  if active then 
  
    --if at any point we enter the jumping animation state, play the hop noise then set a latch
    if mcontroller.jumping() and not mcontroller.liquidMovement() then
      if goodToPlayJumpSound then 
	    goodToPlayJumpSound = false
        animator.playSound("jump")
	  end
    else
      goodToPlayJumpSound = true
    end
	
    --GUN
    local diff = world.distance(tech.aimPosition(), mcontroller.position())
    local aimAngle = math.atan(diff[2], diff[1])
    
	--[1, 0.35] <- offset for firing for later
	
	shakeit = false
	
    if currentInputLClick == "mechFireL" then
	  shakeit = true
	  if  not status.resourceLocked("energy") and
	  status.resourcePositive("energy") then
        local aimRotation = {math.cos(aimAngle), math.sin(aimAngle)}
        if fireTimerEye <= 0 then
          spawnProjectile(mechProjectileL, 1, aimRotation, eyeSFX, 25 + math.random(0,24))
          fireTimerEye = cooldownEye
	    end
	  end
    end
    
    if currentInputRClick == "mechFireR" then
	  shakeit = true
	  if not status.resourceLocked("energy") and
	  status.resourcePositive("energy") then
        local aimRotation = {math.cos(aimAngle), math.sin(aimAngle)}
        if fireTimerDander <= 0 then
		  puffCloud()
          fireTimerDander = cooldownDander
        end
	  end
    end
	
	--primitive animation overrider i guess
	mcontroller.controlParameters(mechCustomMovementParameters)
	
    --mcontroller.controlFace(leftways)
	if mcontroller.xVelocity() > 0.1 then
	  animator.setFlipped(false)
	elseif mcontroller.xVelocity() < -0.1 then
	  animator.setFlipped(true)
	else 
	  --this manually sets the facing direction
      local lookvector = tech.aimPosition()
	  local playerpos = mcontroller.position()
	  local delta = lookvector[1] - playerpos[1]
      local leftways = -1
      if delta >= 0 then
	    leftways = 1
      end
	  animator.setFlipped(leftways ~= 1)
	end
	
	--world.debugText("^shadow;" .. leftways, {entity.position()[1] + 4, entity.position()[2] + 4}, "green")
	
	if not shakeit then
	  
	  --jumping falling
      if not mcontroller.onGround() then
        if mcontroller.jumping() then
          animator.setAnimationState("body", "jump")
        elseif mcontroller.falling() then
          animator.setAnimationState("body", "fall")
        end
		
	  --walking
      elseif mcontroller.walking() then
          animator.setAnimationState("body", "walk")
		
	  --running
	  elseif mcontroller.running() then
          animator.setAnimationState("body", "run")

	  --idle
      else
        animator.setAnimationState("body", "idle")
      end
	  
	--attack higher prio animation
	else
	  animator.setAnimationState("body", "shakeit")
	end
  end
end

function update(args)

  --if the player walks into the trap room, lock their tech on
  if world.type() == "lofty_irisil_techchallenge_irisamorph" then
    if not active then
      if world.getProperty("lofty_irisil_lockmorph") == true then
	    if world.getProperty("lofty_irisil_unlockmorph") ~= true then
          activate()
		end
      end
    end
  end
  
  --if the player logged out morphed, restore them to their morph position
  --this doesn't seem to work i just kind of copypasted it from the spike sphere
  --the spike sphere doesn't work for this either
  --might be a modpack issue idk
  restoreStoredPosition()
  
  --graphics for transforming
  updateTransformFade(args.dt)
  
  if fireTimerEye > 0 then
    fireTimerEye = fireTimerEye - args.dt
  end
  
  if fireTimerDander > 0 then
    fireTimerDander = fireTimerDander - args.dt
  end
  
  --display polygon with debug numbers
  --for i = 1, polySize do
    --world.debugText("^shadow;" .. i, {entity.position()[1] + mechCustomMovementParameters.collisionPoly[i][1], entity.position()[2] + mechCustomMovementParameters.collisionPoly[i][2]}, "green")
  --end
  
  handleInputs(args)
  if mcontroller.groundMovement() then 
    goodToPlayJumpSound = true 
  end
  
  lastAction = args.moves
end

function spawnProjectile(projectileList, projectile, aimRotation, sfx, spd)
  world.spawnProjectile(
    projectileList[projectile],
    mcontroller.position(),
    entity.id(),
    {aimRotation[1] * spd, aimRotation[2] * spd},
    false,
    {speed = spd, powerMultiplierEye * status.stat("powerMultiplier") }
  )
  animator.playSound(sfx, 0)
  status.overConsumeResource("energy", energyCostEye) 
end

function puffCloud()
  local damageConfig = { power = powerMultiplierDander * status.stat("powerMultiplier"), speed = 1.5 }
  world.spawnProjectile("lofty_irisil_largeslowcloud", mcontroller.position(), entity.id(), {0, 1},   false, {})
  world.spawnProjectile("lofty_irisil_largeslowcloud", mcontroller.position(), entity.id(), {1, 1},   false, {})
  world.spawnProjectile("lofty_irisil_largeslowcloud", mcontroller.position(), entity.id(), {1, 0},   false, {})
  world.spawnProjectile("lofty_irisil_largeslowcloud", mcontroller.position(), entity.id(), {1, -1},  false, {})
  world.spawnProjectile("lofty_irisil_largeslowcloud", mcontroller.position(), entity.id(), {0, -1},  false, {})
  world.spawnProjectile("lofty_irisil_largeslowcloud", mcontroller.position(), entity.id(), {-1, -1}, false, {})
  world.spawnProjectile("lofty_irisil_largeslowcloud", mcontroller.position(), entity.id(), {-1, 0},  false, {})
  world.spawnProjectile("lofty_irisil_largeslowcloud", mcontroller.position(), entity.id(), {-1, 1},  false, {})
  animator.playSound(cloudSFX, 0)
  status.overConsumeResource("energy", energyCostDander)
end