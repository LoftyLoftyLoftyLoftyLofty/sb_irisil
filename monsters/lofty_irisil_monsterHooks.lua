require "/scripts/rect.lua"
require "/scripts/lofty_irisil_util.lua"
require "/scripts/companions/capturable.lua"

--oldCapturableInit = capturable.init or function() end
--function capturable.init()
--	oldCapturableInit()
--end

function liu_disableRelocation()
	storage.lofty_irisil_relocatable = false
	message.setHandler("pet.attemptRelocate", function (_, _, ...)
      return nil
    end)
end

function liu_enableRelocation()
	storage.lofty_irisil_relocatable = true
	message.setHandler("pet.attemptRelocate", function (_, _, ...)
      return capturable.attemptRelocate(...)
    end)
end

function liu_disableCapture()
	storage.lofty_irisil_capturable = false
	message.setHandler("pet.attemptCapture", function (_, _, ...)
      return nil
    end)
end

function liu_enableCapture()
	storage.lofty_irisil_capturable = true
	message.setHandler("pet.attemptCapture", function (_, _, ...)
      return capturable.attemptCapture(...)
    end)
end

triggerZoneRegistrationForwarding = {}
dungeonManagerStagehandID = nil

function validTarget(b)
	--Entity ID check
	if b.monsterEntityId == entity.id() or b.monsterEntityId == "*" then
		--Entity UniqueID check
		if b.monsterUniqueId == entity.uniqueId() or b.monsterUniqueId == "*" then
			--Monster type check
			if b.monsterType == monster.type() or b.monsterType == "*" then
				return true
			else
				--yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - monster type doesn't match. Skipping.")
			end
		else	
			--yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - monster unique ID doesn't match. Skipping.")
		end
	else
		--yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - entity ID doesn't match. Skipping.")
	end
	return false
end

function li_initHooks(args, board)
  
  --enable or disable relocator
  message.setHandler
	(
		"lofty_irisil_monsterHook_setRelocatable", 
		
		function(_, _, b)
			if validTarget(b) then
				if b.relocatable then
					liu_enableRelocation()
				else
					liu_disableRelocation()
				end
			end
		end
	)
	
  --enable or disable capture
  message.setHandler
	(
		"lofty_irisil_monsterHook_setCapturable", 
		
		function(_, _, b)
			if validTarget(b) then
				if b.capturable then
					liu_enableCapture()
				else
					liu_disableCapture()
				end
			end
		end
	)
  
  --this handler is used for trigger zones to verify that a monster can receive the message they are meant to send
  --it is currently used to make sure relocating critters into trigger zones doesn't cause a race condition
  message.setHandler
	(
		"lofty_irisil_SYN", 
		
		function(_, _, sender)
			--respond to SYN with ACK and our ID
			liu_SEM(sender, "lofty_irisil_ACK", entity.id())
		end
	)
  
    --sets behavior on a monster
    message.setHandler
	(
		"lofty_irisil_monsterHook_setBehavior", 
		
		--hook for behavior
		function(_, _, b)
			if validTarget(b) then
				liu_setBehavior(b.behaviorType)
			end
		end
	)
	
	--begone thot
    message.setHandler
	(
		"lofty_irisil_monsterHook_despawn", 
		
		--hook for behavior
		function(_, _, b)
			if validTarget(b) then
				liu_despawn()
			end
		end
	)
	
	--util stuff
	message.setHandler
	(
		"lofty_irisil_monsterHook_setPos", 
		
		--hook for behavior
		function(_, _, b)
			if validTarget(b) then
				liu_setPos(b)
			end
		end
	)
	
	--if this mob was saved as not being relocatable, when it re-inits, disable relocation
	if storage.lofty_irisil_relocatable ~= nil then
		if storage.lofty_irisil_relocatable then
			liu_enableRelocation()
		else
			liu_disableRelocation()
		end
	--mob was not saved with relocatable data
	else
		--check to see if it should be relocatable by default
		local d = config.getParameter("relocatable", false)
		
		--assume the default behavior if any
		storage.lofty_irisil_reloctable = d
		if d then
			liu_enableRelocation()
		else
			liu_disableRelocation()
		end
		
		--check to see if we have an override
		local c = config.getParameter("lofty_irisil_reloctable")
		
		if c ~= nil then
			if c then
				liu_enableRelocation()
			else
				liu_disableRelocation()
			end
		end
	end
	
	--if this mob was saved as not being capturable, when it re-inits, disable capture
	if storage.lofty_irisil_capturable ~= nil then
		if storage.lofty_irisil_capturable then
			liu_enableCapture()
		else
			liu_disableCapture()
		end
	--mob was not saved with capturable data
	else
		--check to see if it should be capturable by default
		local d = config.getParameter("capturable", false)
		
		--assume default behavior if any
		storage.lofty_irisil_capturable = d
		if d then
			liu_enableCapture()
		else
			liu_disableCapture()
		end
		
		--check to see if we have an override
		local c = config.getParameter("lofty_irisil_capturable")
		if c ~= nil then
			if c then
				liu_enableCapture()
			else
				liu_disableCapture()
			end
		end
	end
	
	--yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - Listener initialized! " .. monster.type())
	return true
end

function liu_despawn(args)
	monster.setDeathSound()
	monster.setDeathParticleBurst()
	monster.setDropPool("lofty_irisil_noTreasure")
	status.setResource("health", 0)
end

--{ 
--	"messageType" : "lofty_irisil_monsterHook_setPos", 
--	"messageArgs" : 
--	{ 
--		"monsterEntityId" : "*", 
--		"monsterUniqueId" : "*", 
--		"monsterType" : "*", 
--		"x": 80, 
--		"y": 32, 
--		"mode": "offsetFromSender",
--		"senderID": "<SENDER_ID>"
--	}, 
--	"requiredVariableHook" : "lofty_irisil_dungeon_pickMeUp_COMPLETE_KEY_CIRCUIT"
--}

function liu_setPos(args)

	--"move to my pos + xy"
	if args.mode == "offsetFromSender" then
	
		--requires a senderID to get a position duh
		if args.senderID ~= nil then
			
			sb.logInfo(sb.print(args))
			
			--grab position, sanity check it
			local p = world.entityPosition(args.senderID)
			if p ~= nil then
			
				--set new position
				local targetPos = { p[1] + args.x, p[2] + args.y }
				mcontroller.setPosition(targetPos)
			end
		end
		
	--"move to your pos + xy"
	elseif args.mode == "offsetFromReceiver" then
		
		--get own pos, offset it
		local p = entity.position()
		mcontroller.setPosition( { p[1] + args.x, p[2] + args.y } )
		
	--"just go where i say"
	elseif args.mode == "global" then
		mcontroller.setPosition( { args.x, args.y } )
	end
end

-- passing params through this one in particular was being a pain in my ass so we do it this way instead
function li_setWorldPropertyBool(args, board, node)
	local w = config.getParameter("lofty_irisil_setWorldPropertyBool_onDeath")
	world.setProperty(w.flag, w.value)
end

--makes monster face a given direction
-- param direction
function li_face(args, board, node)
	controlFace(args.direction)
	
	--not sure how to sanity check this correctly
	--for now there's just a gate here for the one monster that uses this
	if monster.type() == "lofty_irisil_holographicfennix" then
		animator.setAnimationState("body","idle",false)
	end
	
	return false
end

--makes monster move until it hits a wall
-- param direction
-- param run
-- param respectLedges
function li_move(args, board, node)
  local bounds = mcontroller.boundBox()

  while true do
  
    local direction = util.toDirection(args.direction)
    local run = args.run
    if config.getParameter("pathing.forceWalkingBackwards", false) then
      if run == true then run = mcontroller.movingDirection() == mcontroller.facingDirection() end
    end

    if args.direction == nil then return false end
    local position = mcontroller.position()
    position = {position[1], math.ceil(position[2]) - (bounds[2] % 1)} -- align bottom of the bound box with the ground

    local move = false
    -- Check for walls
    for _,yDir in pairs({0, -1, 1}) do
      --util.debugRect(rect.translate(bounds, vec2.add(position, {direction * 0.2, yDir})), "yellow")
      if not world.rectTileCollision(rect.translate(bounds, vec2.add(position, {direction * 0.2, yDir}))) then
        move = true
        break
      end
    end

    -- Also specifically check for a dumb collision geometry edge case where the ground goes like:
    --
    --        #
    -- ###### ######
    -- #############
    local boundsEnd = direction > 0 and bounds[3] or bounds[1]
    local wallPoint = {position[1] + boundsEnd + direction * 0.5, position[2] + bounds[2] + 0.5}
    local groundPoint = {position[1] + boundsEnd - direction * 0.5, position[2] + bounds[2] - 0.5}
    if world.pointTileCollision(wallPoint) and not world.pointTileCollision(groundPoint) then
      move = false
    end

	if args.respectLedges then
		-- Check for ground for the entire length of the bound box
		-- Makes it so the entity can stop before a ledge
		if move then
		  local boundWidth = bounds[3] - bounds[1]
		  local groundRect = rect.translate({bounds[1], bounds[2] - 1.0, bounds[3], bounds[2]}, position)
		  local y = 0
		  for x = boundWidth % 1, math.ceil(boundWidth) do
			move = false
			for _,yDir in pairs({0, -1, 1}) do
			  --util.debugRect(rect.translate(groundRect, {direction * x, y + yDir}), "blue")
			  if world.rectTileCollision(rect.translate(groundRect, {direction * x, y + yDir}), {"Null", "Block", "Dynamic", "Platform"}) then
				move = true
				y = y + yDir
				break
			  end
			end
			if move == false then break end
		  end
		end
	end

    if move then
      moved = true
      mcontroller.controlMove(direction, run)
      if not self.setFacingDirection then controlFace(direction) end
    else
      if moved then
        mcontroller.setXVelocity(0)
        mcontroller.clearControls()
      end
      return false
    end
    coroutine.yield()
  end
end