require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/async.lua"
require "/scripts/lofty_irisil_util.lua"

--startup
function init()
	--store our starting position to return to later
	storage.spawnPosition = storage.spawnPosition or mcontroller.position()
	--enable touch damage
	monster.setDamageOnTouch(true)
	--reset anything else that doesn't need to be reinitialized later
	reinit()
end

function reinit()
	--invulnerable
	status.addEphemeralEffect("invulnerable", 999999999)
	--refill health bar
	status.setResourcePercentage("health", 1.0)
	--hide damage bar
	monster.setDamageBar(config.getParameter("damageBar"))
	--pls no die
	self.shouldDie = false
	--clear targets list
	self.targets = {}
	
	--get behavior config
	local attackConfig = config.getParameter("attackConfig")
	--reset rollSpeed
	self.rollSpeed = attackConfig.roll.minimumRollSpeed
	
	--set behavior
	self.behavior = fatGleapBehavior(attackConfig)
	
	--set idle anim
	animator.setAnimationState( "body", "idle" )
	mcontroller.controlFace(-1)
	
	--be aggressive
	monster.setAggressive(true)
end

function scalePower(power)
  return power * root.evalFunction("monsterLevelPowerMultiplier", monster.level())
end

function shouldDie()
  return self.shouldDie and status.resource("health") <= 0
end

function die()
end

function damage(damageSource)
end

function updateTargets()
  local validTarget = function(e)
    local pos = world.entityPosition(e)
    if pos == nil then
      return false
    end

    return world.magnitude(pos, mcontroller.position()) < 100 and not world.lineTileCollision(mcontroller.position(), pos)
  end
  self.targets = util.filter(self.targets, validTarget)

  if #self.targets == 0 then
    local players = world.entityQuery(mcontroller.position(), 50, {includedTypes={"player"}, orderBy="nearest"})
    self.targets = util.filter(players, validTarget)
  end
  self.target = self.targets[1]
end

function update(dt)
	updateTargets()
	tick(self.behavior)
end

fatGleapBehavior = async(function(attackConfig)

	--do nothing while we have no targets
	while self.target == nil do
		coroutine.yield()
	end
	
	--move to initializer position
	while status.resource("health") > 0 or self.shouldDie == false do
		
		--show health bar
		monster.setDamageBar("Special")
		
		--remove invulnerability once we initialize
		status.removeEphemeralEffect("invulnerable")
		
		while self.target == nil do
		  coroutine.yield()
		end
		
		--see you, get angry
		animator.playSound("loolpingpic0hei")

		local active = activeState(attackConfig) -- coroutine for the active state
		while self.target ~= nil do
		  coroutine.yield(tick(active)) -- we don't expect the active state to finish
		end
		
		await(resetBoss())
	end
end)

-- resets the boss back to its original idle state
resetBoss = async(function()
	animator.setEffectActive("teleport", true)
	await(delay(0.5))
	mcontroller.setPosition(storage.spawnPosition)
	await(delay(0.5))
	animator.setEffectActive("teleport", false)
	reinit()
end)

queryGleaps = async(function()
  local gleaps = world.entityQuery(mcontroller.position(), 80, {includedTypes = {"monster"}})
  storage.lookAtAllTheseGleaps = util.filter(gleaps, function(entityId)
      return world.monsterType(entityId) == "gleap"
    end)
end)

--run while the boss has targets
activeState = async(function(attackConfig)

	local attackSequence = async(function()
		--loop the attack sequence
		while true do
		
			--hop 3 times at the target
			await(hopTowardTarget(attackConfig))
			await(hopTowardTarget(attackConfig))
			await(hopTowardTarget(attackConfig))
		
			--try to roll them over
			await(targetedRoll(attackConfig))--targetedRoll will mutate the value of storage.rollResult
			
			--if there wasn't enough room to roll at them, spawn a gleap instead
			if storage.rollResult == false then
				await(queryGleaps())--queryGleaps will mutate the value of storage.lookAtAllTheseGleaps
				if #storage.lookAtAllTheseGleaps < attackConfig.maxAdds then
					world.spawnMonster("gleap", mcontroller.position(), {dropPools={"lofty_irisil_noTreasure"}})
				end
			end
			
			--each time we finish an attack loop, roll a little faster (actually don't it gets annoying)
			if self.rollSpeed < attackConfig.roll.maximumRollSpeed then
				self.rollSpeed = self.rollSpeed + attackConfig.roll.rollSpeedIncrement
			end
			
			--give melee players a chance to do some damage
			await(delay(0.75))
			
			coroutine.yield()
			
		end
	end)
	
	-- Run phase 1 until health is 0
	self.shouldDie = false --we set this to false here because we expect a death sequence to play when we hit 0 hp
	local mainAttacks = attackSequence()
	while status.resource("health") > 0 do
		coroutine.yield(tick(mainAttacks))
	end
	
	--boss is dead, set world properties
	local w = config.getParameter("lofty_irisil_setWorldPropertyBool_onDeath")
	while world.getProperty(w.flag) ~= w.value do
		world.setProperty(w.flag, w.value)
	end
	
	--try to gracefully exit the loop above if we get here somehow
	self.target = nil
	
	--todo death animation
	
	--ok NOW you can die
	self.shouldDie = true
end)

testBehavior = async(function()
	animator.setEffectActive("teleport", true)
	await(delay(1.0))
	animator.setEffectActive("teleport", false)
	await(delay(1.0))
end)

function gleapSplats(attackConfig)
	local angle = math.random() * math.pi
	world.spawnProjectile
	(
		"lofty_irisil_gleapgoop", 
		vec2.add(mcontroller.position(), {(math.random() * 6) -3, -7}),
		entity.id(), 
		{ math.cos(angle), math.sin(angle) + 0.25}, 
		false, 
		{
			speed = attackConfig.gleapGoop.projectileVel,
			power = scalePower(attackConfig.gleapGoop.power)
		}
	)
end

hopTowardTarget = async(function(attackConfig)

	--valid target
	if self.target ~= nil then
	
		--face the target
		local position = mcontroller.position()
		local targetPosition = world.entityPosition(self.target)
		local direction = 1
		
		if targetPosition[1] > position[1] then
			mcontroller.controlFace(1)
		else
			mcontroller.controlFace(-1)
			direction = -1
		end
		
		--set x vel toward target
		mcontroller.setXVelocity(self.rollSpeed * direction * .25)
		
		--set y vel upward
		mcontroller.setYVelocity(56)
	end
	
	--we are now jumping
	animator.setAnimationState( "body", "jump" )
	
	--wait until our velocity is negative to enter the falling state
	while mcontroller.velocity()[2] > 0 do
		coroutine.yield()
	end
	
	--we are now falling
	animator.setAnimationState( "body", "fall" )
	
	--wait until we hit the ground to exit the falling state
	while mcontroller.onGround() == false do
		coroutine.yield()
	end
	
	--TODO: do a bunch of damage to anything caught under the fat boi
	for i=1,8 do
		gleapSplats(attackConfig)
	end
		
	await(delay(0.5))
end)

--roll left or right depending on where the target is
targetedRoll = async(function(attackConfig)
	if self.target ~= nil then
		local position = mcontroller.position()
		local targetPosition = world.entityPosition(self.target)
		if targetPosition[1] > position[1] then
			await(fatGleapRoll(attackConfig, 1))
		else
			await(fatGleapRoll(attackConfig, -1))
		end
	end
end)

--returns true if the roll was a success
fatGleapRoll = async(function(attackConfig, direction)
	
	local position = mcontroller.position()
	local bounds = mcontroller.boundBox()
	liu_debugRect(rect.translate(bounds, position), "white")
	
	--before we commit to a roll, check to make sure we have room to do so
	--we expect fatgleap to be 8 tiles wide, and we expect a roll to be at least 1 fatgleap wide
	local minimumDistance = 8
	local testDistance = 0
	
	--basically we are trying to make sure we can roll even if we are going up or down slopes
	
	--get our current position - this needs to happen outside the loop so that the loop actually tests iteratively instead of reseting to the boss pos every pass lol
	local newPos = position
	
	local colors = {"red", "yellow", "green"}
	local alt = 0
	
	--debug bounding box verification
		--while true do
		--testDistance = 0
		--newPos = position
	
	--try to go the minimum roll distance
	while testDistance < minimumDistance do

		--debug only
		alt = (alt + 1) % (#colors)
		local validNextStep = false
		
		--as we move forward, check up one tile and down one tile for valid motion options
		for _,yDir in pairs({-1, 0, 1}) do
			--applying y offset to position that we are testing
			local testPos = vec2.add(newPos, {direction, yDir})
			
			--path searching debug
			--world.debugLine(newPos,testPos,colors[1+alt])
			
			--if no collision happens
			if not world.rectTileCollision(rect.translate(bounds, testPos)) then
			
				--debuggin
				--liu_debugRect(rect.translate(bounds, testPos), "green")
				
				--we found a spot where we "fit" (hopefully)
				validNextStep = true
				--update 'newPos' so that when we test the distance again it's from the next iterative step
				newPos = testPos
				break
			else
				--debuggin
				--liu_debugRect(rect.translate(bounds, testPos), "red")
			end
		end
		
		--after checking forward, up one tile, and down one tile, can we move forward?
		if validNextStep then
			testDistance = testDistance + 1
		else
			--break --debug bounding box verification
			storage.rollResult = false
			return false
		end
	end
	
	--debug bounding box verification
		--coroutine.yield()
		--end
	
	--if we made it this far, we have room to roll
	local coolSplatsBro = mcontroller.position()[1]
	
	--turn left
	mcontroller.controlFace(direction)
	animator.setAnimationState( "body", "roll" )
	
	--keep rollin rollin rollin
	while true do
	
		--these need to be kept up-to-date
		position = mcontroller.position()
		bounds = mcontroller.boundBox()
		
		-- Check for walls. we allow going up or down one block here
		local move = false
		for _,yDir in pairs({-1, 0, 1}) do
		  if not world.rectTileCollision(rect.translate(bounds, vec2.add(position, {direction * 0.2, yDir}))) then
			move = true
		  end
		end
	
		if move then
			mcontroller.setXVelocity(self.rollSpeed * direction)
			local curX = mcontroller.position()[1]
			if math.abs(coolSplatsBro - curX) > 1 then
				gleapSplats(attackConfig)
				coolSplatsBro = curX
			end
		else
			
			--clear velocity
			mcontroller.setXVelocity(0)
			
			--cargo cult, donno what this does, copypasted from swanswong code
			mcontroller.clearControls()
			
			--face the target
			if self.target ~= nil then
				local targetPosition = world.entityPosition(self.target)
				if targetPosition[1] > position[1] then
					mcontroller.controlFace(1)
				else
					mcontroller.controlFace(-1)
				end
			end
			
			--go idle
			animator.setAnimationState( "body", "idle" )
			
			--chill for a moment
			await(delay(0.5))
			
			--exit loop
			storage.rollResult = true
			return true
		end
		coroutine.yield()
	end
end)