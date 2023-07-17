require "/scripts/rect.lua"
require "/scripts/lofty_irisil_util.lua"
require "/scripts/companions/capturable.lua"

--oldCapturableInit = capturable.init or function() end
--function capturable.init()
--	oldCapturableInit()
--end

function li_disableRelocation()
	storage.lofty_irisil_relocatable = false
	message.setHandler("pet.attemptRelocate", function (_, _, ...)
      return nil
    end)
end

function li_enableRelocation()
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
					li_enableRelocation()
				else
					li_disableRelocation()
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
	
	if storage.relocatable ~= nil then
		if storage.relocatable then
			li_enableRelocation()
		else
			li_disableRelocation()
		end
	end
	
	storage.lofty_irisil_relocatable = config.getParameter("relocatable", false)
	
	--yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - Listener initialized! " .. monster.type())
	return true
end