require "/scripts/rect.lua"
require "/scripts/lofty_irisil_util.lua"

function li_initHooks(args, board)
  
  --this handler is used for trigger zones to register with a dungeon coordinator entity/monster
  message.setHandler
	(
		"lofty_irisil_registerWithCoordinator", 
		
		function(_, _, sender)
			--respond to SYN with ACK and our ID
			yeek("LI-MonsterHooks", entity.id() .. " - registered trigger zone with id: " .. sender)
			liu_SEM(sender, "lofty_irisil_registeredWithCoordinator", entity.id())
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
		
			--expected format is:
			--	monsterEntityID|monsterUniqueID|monsterType|behaviorName
			--  this should allow us to filter for 
			--		individual monsters by entity ID, 
			--		individual monsters by their unique ID, 
			--		or monsters by their species
			
			--example message:
			--	*|*|lofty_irisil_bunnykeycritter_blue|lofty_irisil_critterRunLeft
			--  tells all the blue glowbunny critters receiving the message to use the runLeft behavior
			
			--split incoming msg
			local splitsies = liu_split(b,"|")
			
			--minimum number params in msg
			if #splitsies >= 4 then
				
				--verify that the intended target of the behavior is the one we want
				
				--Entity ID check
				if splitsies[1] == entity.id() or splitsies[1] == "*" then
				
					--Entity UniqueID check
					if splitsies[2] == entity.uniqueId() or splitsies[2] == "*" then
					
						--Monster type check
						if splitsies[3] == monster.type() or splitsies[3] == "*" then
							
							liu_setBehavior(splitsies[4])
							yeek("LI-MonsterHooks", entity.id() .. " - setting behavior to '" .. splitsies[4] .. "'!")
							
						else
							
							yeek("LI-MonsterHooks", entity.id() .. " - monster type doesn't match. Skipping.")
							
						end
					else
					
						yeek("LI-MonsterHooks", entity.id() .. " - monster unique ID doesn't match. Skipping.")
						
					end
				else
				
					yeek("LI-MonsterHooks", entity.id() .. " - entity ID doesn't match. Skipping.")
					
				end
			else
			
				yeek("LI-MonsterHooks", entity.id() .. " - not enough parameters to set behavior with hook! See monsterHooks.lua for documentation")
				
			end
		end
	)
	
	yeek("LI-MonsterHooks", entity.id() .. " - Listener initialized!")
	return true
end