require "/scripts/rect.lua"
require "/scripts/lofty_irisil_util.lua"

triggerZoneRegistrationForwarding = {}
dungeonManagerStagehandID = nil

function li_initHooks(args, board)
  
  --basically stagehands don't have a good way to find each other
  --what I did to work around this is have the stagehands all do an entity query for a coordinator mob
  --the coordinator mob then passes everything along to the scripted manager stagehand for the dungeon
  
  --this handler is used for dungeon manager stagehands to register with a dungeon coordinator entity/monster
  message.setHandler
	(
		"lofty_irisil_registerManager", 
		
		function(_, _, sender)
			--respond to SYN with ACK and our ID
			yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - coordinator received manager registration with id: " .. sender)
			
			dungeonManagerStagehandID = sender
			
			--acknowledge the manager so it quits polling us
			liu_SEM(sender, "lofty_irisil_managerAccepted", entity.id())
			
			--send any other queued messages too
			if #triggerZoneRegistrationForwarding > 0 then
				for i, v in pairs(triggerZoneRegistrationForwarding) do
					yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - dequeueing triggerZone id: " .. v)
					liu_SEM(dungeonManagerStagehandID, "lofty_irisil_stagehandRegistration", v)
				end
				triggerZoneRegistrationForwarding = {}
			end
			
		end
	)
	
  --this handler is used for trigger zones to register with a dungeon coordinator entity/monster
  message.setHandler
	(
		"lofty_irisil_registerWithCoordinator", 
		
		function(_, _, sender)
			--respond to SYN with ACK and our ID
			yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - coordinator queueing registration for trigger zone with id: " .. sender)
			
			--because this stuff can happen in whatever zany order it wants on dungeon init, we queue the request to pass it to the manager stagehand for the dungeon (if any)
			if dungeonManagerStagehandID == nil then
			
				table.insert(triggerZoneRegistrationForwarding,sender)
				
			else
			
				liu_SEM(dungeonManagerStagehandID, "lofty_irisil_stagehandRegistration", sender)
				
			end
			
			--we send a response immediately so that it stops polling
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
							yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - setting behavior to '" .. splitsies[4] .. "'!")
							
						else
							
							yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - monster type doesn't match. Skipping.")
							
						end
					else
					
						yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - monster unique ID doesn't match. Skipping.")
						
					end
				else
				
					yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - entity ID doesn't match. Skipping.")
					
				end
			else
			
				yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - not enough parameters to set behavior with hook! See monsterHooks.lua for documentation")
				
			end
		end
	)
	
	yeek("(SERVER) LI-MonsterHooks", entity.id() .. " - Listener initialized!")
	return true
end