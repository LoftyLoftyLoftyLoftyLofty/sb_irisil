require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/scripts/vec2.lua"
require "/scripts/lofty_irisil_util.lua"

function initDialogSequences()
	self.msgSet1Index = 0
	self.msgSet1Timer = 4.0
end

function init()

	initDialogSequences()
	
	message.setHandler
	(
		"lofty_irisil_pickmeup_dungeonFlags", 
		
		function(_, _, f)
			self.pickMeUp_dungeonFlags = f
			yeek("(PLAYER) LI-RM-PickMeUp", "Got dungeon flags: " .. sb.print(f))
		end
	)

	message.setHandler
	(
		"lofty_irisil_pickmeup_manager_ID", 
		
		function(_, _, id)
			initDialogSequences()
			self.pickMeUp_managerID = id
			yeek("(PLAYER) LI-RM-PickMeUp", "Got dungeon mgr ID: " .. sb.print(id))
			liu_SEM(self.pickMeUp_managerID, "lofty_irisil_pickmeup_requestDungeonFlags",entity.id())
		end
	)

	message.setHandler
	(
		"lofty_irisil_enterArea", 
		function(_, _, areaName)
			stageEnterArea(areaName)
			yeek("(PLAYER) LI-RM-PickMeUp", "Area triggered: " .. areaName)
		end
	)
	
	yeek("(PLAYER) LI-RM-PickMeUp", "Player script initialized!")

end

--triggered when player hits an area marker
function stageEnterArea(areaName)

  if areaName == "entryway" then
      player.radioMessage("lofty_irisil_pickMeUp_welcomeToOurHome_1")
	  self.msgSet1Index = 1
	  self.msgSet1Timer = 4.0
  end
  
end

--prettymuch just used for handling the timer gaps between broadcasted messages
function update(dt)

	--disable this script unless the player is in the appropriate dungeon for it
	if world.type() ~= "lofty_irisil_challengerooms_pickmeup" then
		return
	end

	updateMsgSequence1(dt)
end

--welcome messages
function updateMsgSequence1(dt)

	--we only care about the msg sequence timers if we're in a nonzero message state
	if self.msgSet1Index > 0 then
		
		--first set of messages welcoming the player to the dungeon
		if self.msgSet1Timer > 0 then
		
			--handle time difference
			self.msgSet1Timer = self.msgSet1Timer - dt
		
			--if it's been 4 seconds
			if self.msgSet1Timer <= 0 then
			
				--reset the timer
				self.msgSet1Timer = 4.0
				
				--increment the set index
				self.msgSet1Index = self.msgSet1Index + 1
				
				--this is ugly but easy to read
				if self.msgSet1Index == 2 then
					player.radioMessage("lofty_irisil_pickMeUp_welcomeToOurHome_2")
					
				elseif self.msgSet1Index == 3 then
					player.radioMessage("lofty_irisil_pickMeUp_welcomeToOurHome_3")
					
				elseif self.msgSet1Index == 4 then
					player.radioMessage("lofty_irisil_pickMeUp_welcomeToOurHome_4")
					
				elseif self.msgSet1Index == 5 then
					player.radioMessage("lofty_irisil_pickMeUp_welcomeToOurHome_5")
				end
			end
		end
	end
end