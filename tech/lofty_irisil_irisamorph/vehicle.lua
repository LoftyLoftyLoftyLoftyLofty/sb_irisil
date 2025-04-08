require "/scripts/vec2.lua"
function init()
  active = false
  fireTimer = 0
  tech.setVisible(false)
  lastAction = {}
  flipped = false
  energyCostPerSecond = config.getParameter("energyCostPerSecond")
  mechCustomMovementParameters = config.getParameter("mechCustomMovementParameters")
  mechTransformPositionChange = config.getParameter("mechTransformPositionChange")
  polySize = #mechCustomMovementParameters.collisionPoly
  parentOffset = config.getParameter("parentOffset", {0, 0})
  mechCollisionTest = config.getParameter("mechCollisionTest")
  mechAimLimit = config.getParameter("mechAimLimit") * math.pi / 180
  mechFrontRotationPoint = config.getParameter("mechFrontRotationPoint")
  mechFrontFirePosition = config.getParameter("mechFrontFirePosition")
  mechBackRotationPoint = config.getParameter("mechBackRotationPoint")
  mechBackFirePosition = config.getParameter("mechBackFirePosition")
  mechFireCycle = config.getParameter("mechFireCycle")
  
  mechProjectileL = config.getParameter("mechProjectileL")
  mechProjectileL = type(mechProjectileL) == "string" and {mechProjectileL, mechProjectileL} or mechProjectileL
  
  mechProjectileR = config.getParameter("mechProjectileR")
  mechProjectileR = type(mechProjectileR) == "string" and {mechProjectileR, mechProjectileR} or mechProjectileR
  
  mechProjectileConfig = config.getParameter("mechProjectileConfig", {})
  suppressTools = config.getParameter("suppressTools", false)
  mechBackGunAngle = config.getParameter("mechBackGunAngle")
  animator.setGlobalTag("mechType", config.getParameter("mechType", ""))
  animator.setGlobalTag("mechGunType", config.getParameter("mechGunType", ""))
  --animator.translateTransformationGroup("guns",config.getParameter("mechArmOffset"))
  animator.setLightActive("headlightBeam", config.getParameter("lightActive"))
  mechStats = config.getParameter("mechStats")
  liquidStats = config.getParameter("liquidMechStats")
  liquidStatsSubmersionLevel = config.getParameter("liquidStatsSubmersionLevel", 1)
  mechActionL = config.getParameter("mechAction", "mechFireL")
  mechActionR = config.getParameter("mechAction", "mechFireR")
  aquatic = 1 + (config.getParameter("aquatic", 0) and 1)
  hasGuns = mechActionL == "mechFireL" or mechActionR == "mechFireR"
  walkTimer = 1
  walkOffset = config.getParameter("walkOffset", {{0, 0.375}, {0, 0.125}, {0, 0}, {0, 0.125}, {0, 0.25}, {0, 0.375}, {0, 0.125}, {0, 0}, {0, 0.125}, {0, 0.25}})
  baseOffset = {0, 0}
  e = true
  
  eyeSFX = "fire"
  cloudSFX = "hiss"
end

function uninit()
  if active then
    status.clearPersistentEffects("movementAbility")
    mcontroller.translate({-mechTransformPositionChange[1], -mechTransformPositionChange[2]})
    tech.setParentOffset({0, 0})
    active = false
    animator.playSound("warp")
    tech.setVisible(false)
    tech.setParentState()
    tech.setToolUsageSuppressed(false)
    walkTimer = 1
  end
  status.clearPersistentEffects("sb_mech")
  status.clearPersistentEffects("sb_liquidMech")
end

function input(args)
  if args.moves["special1"] and not lastAction["special1"] then
    return active and "mechDeactivate" or "mechActivate"
  elseif args.moves["primaryFire"] then
    return mechActionL
  elseif args.moves["altFire"] then
    return mechActionR
  end
  return nil
end

function flipMech()
  for i = 1, polySize do
    mechCustomMovementParameters.collisionPoly[i][1] = -mechCustomMovementParameters.collisionPoly[i][1]
  end
  mcontroller.controlParameters(mechCustomMovementParameters)
  flipped = not flipped
  animator.setFlipped(flipped)
  parentOffset[1] = -parentOffset[1]
  tech.setParentOffset(parentOffset)
end

function update(args)
  local currentInput = input(args)
  for i = 1, polySize do
    world.debugText("^shadow;" .. i, {entity.position()[1] + mechCustomMovementParameters.collisionPoly[i][1], entity.position()[2] + mechCustomMovementParameters.collisionPoly[i][2]}, "green")
  end
  if
    not active and not status.statPositive("activeMovementAbilities") and currentInput == "mechActivate" and
      not world.gravity(mcontroller.position()) ~= 0 and --need world gravity rather than player gravity because improved swim physics
      not (mcontroller.liquidPercentage() >= aquatic) and
      not tech.parentLounging()
   then
    mechCollisionTest = config.getParameter("mechCollisionTest")
    local entityPosition = entity.position()
    mechCollisionTest[1] = mechCollisionTest[1] + entityPosition[1]
    mechCollisionTest[2] = mechCollisionTest[2] + entityPosition[2]
    mechCollisionTest[3] = mechCollisionTest[3] + entityPosition[1]
    mechCollisionTest[4] = mechCollisionTest[4] + entityPosition[2]
    if not world.rectCollision(mechCollisionTest) then
      animator.burstParticleEmitter("mechActivateParticles")
      mcontroller.translate(mechTransformPositionChange)
      animator.playSound("warp")
      tech.setVisible(true)
      tech.setParentState("sit")
      tech.setParentOffset(parentOffset)
      tech.setToolUsageSuppressed(suppressTools)
      active = true
      status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
      if mechStats then
        status.setPersistentEffects("sb_mech", mechStats)
      end
    else
      --  animator.playSound("fail")
    end
  elseif active and ((currentInput == "mechDeactivate") or tech.parentLounging()) then
    uninit()
  end

  if active then
    if liquidStats and mcontroller.liquidPercentage() >= liquidStatsSubmersionLevel then
      status.setPersistentEffects("sb_liquidMech", liquidStats)
    else
      status.clearPersistentEffects("sb_liquidMech")
    end
    local diff = world.distance(tech.aimPosition(), mcontroller.position())
    diff = flipped and diff or {-diff[1], -diff[2]}
    local aimAngle = math.atan(diff[2], diff[1])
    local flip = aimAngle > math.pi / 2 or aimAngle < -math.pi / 2
    if not flip then
      flipMech()
    end

    if hasGuns then
      if flipped then
        aimAngle =
          aimAngle > 0 and math.max(aimAngle, math.pi - mechAimLimit) or
          math.min(aimAngle, -math.pi + mechAimLimit)
        animator.rotateGroup("guns", math.pi - aimAngle)
      else
        aimAngle = -aimAngle
        aimAngle =
          aimAngle > 0 and -math.max(aimAngle, math.pi - mechAimLimit) or
          -math.min(aimAngle, -math.pi + mechAimLimit)
        animator.rotateGroup("guns", math.pi + aimAngle)
      end
    end

    if currentInput == "mechFireL" then
      local aimRotation =
        flipped and {math.cos(aimAngle), math.sin(aimAngle)} or
        vec2.rotate({math.cos(aimAngle), math.sin(aimAngle)}, mechBackGunAngle)
      if fireTimer <= 0 then
        spawnProjectile(mechProjectileL, 1, "front", aimRotation, eyeSFX)
        fireTimer = fireTimer + mechFireCycle
      else
        local oldFireTimer = fireTimer
        fireTimer = fireTimer - args.dt
        if oldFireTimer > mechFireCycle / 2 and fireTimer <= mechFireCycle / 2 then
          spawnProjectile(mechProjectileL, 1, "back", aimRotation, eyeSFX)
        end
      end
    end

    if currentInput == "mechFireR" then
      local aimRotation =
        flipped and {math.cos(aimAngle), math.sin(aimAngle)} or
        vec2.rotate({math.cos(aimAngle), math.sin(aimAngle)}, mechBackGunAngle)
      if fireTimer <= 0 then
        spawnProjectile(mechProjectileR, 1, "front", aimRotation, cloudSFX)
        fireTimer = fireTimer + mechFireCycle
      else
        local oldFireTimer = fireTimer
        fireTimer = fireTimer - args.dt
        if oldFireTimer > mechFireCycle / 2 and fireTimer <= mechFireCycle / 2 then
          spawnProjectile(mechProjectileR, 1, "back", aimRotation, cloudSFX)
        end
      end
    end
	
	animator.setParticleEmitterActive("mechNoEnergy", status.resourceLocked("energy"))
    local moving =
      ((mcontroller.walking() or mcontroller.running() or
      (math.floor(mcontroller.xVelocity()) < -1 or math.floor(mcontroller.xVelocity()) > 1)) and
      mcontroller.onGround())
    if not hasGuns then
      animator.setParticleEmitterActive("mechSmokeB", moving)
      animator.setParticleEmitterActive("mechSmokeF", moving)
    end
	
	--pretty sure this is what's making the energy bar blink while transformed (\_/)
	
    --if moving then
    --  status.overConsumeResource("energy", 0.001)
    --end

    mcontroller.controlParameters(mechCustomMovementParameters)
    mcontroller.controlFace(flipped and -1 or 1)

    if not mcontroller.onGround() then
      if mcontroller.jumping() then
        --tech.setParentOffset(parentOffset["jump"] or {0,0})
        animator.setAnimationState("movement", "jump")
      elseif mcontroller.falling() then
        animator.setAnimationState("movement", "fall")
      --tech.setParentOffset(parentOffset["fall"] or {0,0})
      end
    elseif mcontroller.walking() or mcontroller.running() then
      if flipped and mcontroller.movingDirection() == 1 or not flipped and mcontroller.movingDirection() == -1 then
        --tech.setParentOffset(parentOffset["backWalk"] or {0,0})
        animator.setAnimationState("movement", "backWalk")
      else
        --tech.setParentOffset(vec2.add(parentOffset,walkOffset[math.floor(walkTimer)]))
        --animator.translateTransformationGroup("body",e and walkOffset[math.floor(walkTimer)] or {-walkOffset[math.floor(walkTimer)][1],-walkOffset[math.floor(walkTimer)][2]})
        --e = not e
        --walkTimer=walkTimer+0.11
        --if walkTimer > #walkOffset then walkTimer = 1 end
        --tech.setParentOffset(parentOffset["walk"] or {0,0})
        animator.setAnimationState("movement", "walk")
      end
      if not mcontroller.movingDirection() then
      --walkTimer = 1
      --tech.setParentOffset(parentOffset)
      end
    else
      --tech.setParentOffset(parentOffset["idle"] or {0,0}) --setting this every cycle doesn't seem that good of an idea!
      animator.setAnimationState("movement", "idle")
    end
  end
  lastAction = args.moves
end

function spawnProjectile(projectileList, projectile, gun, aimRotation, sfx)
  world.spawnProjectile(
    projectileList[projectile],
    vec2.add(animator.partPoint(gun .. "Gun", gun .. "GunFirePoint"), mcontroller.position()),
    entity.id(),
    aimRotation,
    false,
    sb.jsonMerge(mechProjectileConfig, {powerMultiplier = status.stat("powerMultiplier")})
  )
  animator.playSound(sfx, 0)
  animator.setAnimationState(gun .. "Firing", "fire")
end
