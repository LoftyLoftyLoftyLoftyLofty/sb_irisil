require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/async.lua"

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
	--set idle
	local attackConfig = config.getParameter("attackConfig")
	self.behavior = fatGleapBehavior(attackConfig)
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

--run while the boss has targets
activeState = async(function(attackConfig)

	local attackSequence = async(function()
		--loop the attack sequence
		while true do
			await(testBehavior())
		end
	end)
	
	-- Run phase 1 until health is 0
	self.shouldDie = false
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
	
	--ok NOW you can die
	self.shouldDie = false
end)

testBehavior = async(function()
	animator.setEffectActive("teleport", true)
	await(delay(1.0))
	animator.setEffectActive("teleport", false)
	await(delay(1.0))
end)