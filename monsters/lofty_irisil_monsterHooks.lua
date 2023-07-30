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
	
	if storage.relocatable ~= nil then
		if storage.relocatable then
			liu_enableRelocation()
		else
			liu_disableRelocation()
		end
	end
	
	storage.lofty_irisil_relocatable = config.getParameter("relocatable", false)
	
	--yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - Listener initialized! " .. monster.type())
	return true
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

-- param flag
-- param value
function li_setWorldPropertyBool(args, board, node)
	world.setProperty(args.flag, args.value)
end

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