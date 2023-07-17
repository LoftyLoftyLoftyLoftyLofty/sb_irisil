require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/scripts/vec2.lua"
require "/scripts/lofty_irisil_util.lua"

local originalInit = init
local originalUpdate = update
local originalUninit = uninit

function lofty_irisil_initDialogSequences()

	self.lofty_irisil_msgSet1Index = 0
	self.lofty_irisil_msgSet1Timer = 4.5
	
	self.lofty_irisil_msgSetSecretCactusIndex = 0
	self.lofty_irisil_msgSetSecretCactusTimer = 4.5
	
	self.lofty_irisil_msgSetKatamariIndex = 0
	self.lofty_irisil_msgSetKatamariTimer = 4.5
	
	self.lofty_irisil_msgSetGreenTimeAttackSuccessIndex = 0
	self.lofty_irisil_msgSetGreenTimeAttackSuccessTimer = 4.5
	
	self.lofty_irisil_msgSetGreenTimeAttackFailIndex = 0
	self.lofty_irisil_msgSetGreenTimeAttackFailTimer = 4.5
	
	self.lofty_irisil_timerSpeed_short = 3.0
	self.lofty_irisil_timerSpeed_medium = 4.5
	self.lofty_irisil_timerSpeed_long = 6.0
end

--WORLD STATE VARIABLES
--  lofty_irisil_dungeon_pickMeUp_welcome_sentDialog- .. uuid
--	lofty_irisil_dungeon_pickMeUp_completedTutorialGrappleRoom- .. uuid
--	lofty_irisil_dungeon_pickMeUp_RED_enter-
--	lofty_irisil_dungeon_pickMeUp_RED_completed
--	lofty_irisil_dungeon_pickMeUp_RED_completed_sentDialog- .. uuid
--	lofty_irisil_dungeon_pickMeUp_RED_secretSwitch
--	lofty_irisil_dungeon_pickMeUp_RED_timeAttack
--	lofty_irisil_dungeon_pickMeUp_RED_timeAttack_sentDialog- .. uuid
--  lofty_irisil_dungeon_pickMeUp_RED_putMeOnThePedestal_sentDialog- .. uuid
--
--  lofty_irisil_dungeon_pickMeUp_noSecretInTheOilChamber- .. uuid
--  lofty_irisil_dungeon_pickMeUp_secretCactus
--  
--  lofty_irisil_dungeon_pickMeUp_GREEN_enterGreenWing_sentDialog- .. uuid
--  lofty_irisil_dungeon_pickMeUp_GREEN_completed
--  lofty_irisil_dungeon_pickMeUp_GREEN_gravityChatter_sentDialog- .. uuid
--  lofty_irisil_dungeon_pickMeUp_GREEN_greenSwitchChatter_sentDialog- .. uuid
--  lofty_irisil_dungeon_pickMeUp_GREEN_timeAttack
--  lofty_irisil_dungeon_pickMeUp_GREEN_timeAttack_sentDialog- .. uuid
--	lofty_irisil_dungeon_pickMeUp_GREEN_secretSwitch
--  lofty_irisil_dungeon_pickMeUp_GREEN_greenillVerticalShaft_sentDialog- .. uuid
--  lofty_irisil_dungeon_pickMeUp_GREEN_greenillVerticalShaft2_sentDialog- .. uuid
--  lofty_irisil_dungeon_pickMeUp_GREEN_greenillVerticalShaft3_sentDialog- .. uuid

function init()

	originalInit()
	
	lofty_irisil_initDialogSequences()
	
	message.setHandler
	(
		"lofty_irisil_enterArea", 
		function(_, _, tbl)
			lofty_irisil_enterArea_pickMeUp(tbl)
		end
	)
	
	message.setHandler
	(
		"lofty_irisil_dungeon_pickMeUp_RED_timeAttackDialog", 
		function(_, _, tbl)
			lofty_irisil_handleTimeAttackDialog_RED()
		end
	)
	
	message.setHandler
	(
		"lofty_irisil_dungeon_pickMeUp_GREEN_timeAttackDialog", 
		function(_, _, tbl)
			lofty_irisil_handleTimeAttackDialog_GREEN()
		end
	)
	
end

--triggered when player hits an area marker
function lofty_irisil_enterArea_pickMeUp(tbl)

	local areaName = tbl.areaName
	local uuid = player.serverUuid()

	--enter the dungeon dialog
	if areaName == "entryway" then
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_welcome_sentDialog-" .. uuid) ~= true then
			world.setProperty("lofty_irisil_dungeon_pickMeUp_welcome_sentDialog-" .. uuid, true)
			player.radioMessage("lofty_irisil_pickMeUp_welcomeToOurHome_1")
			self.lofty_irisil_msgSet1Index = 1
			self.lofty_irisil_msgSet1Timer = self.lofty_irisil_timerSpeed_medium
		end
	end

	--disable easter egg below
	if areaName == "disableYouSuckMessage" then
		world.setProperty("lofty_irisil_dungeon_pickMeUp_completedTutorialGrappleRoom-" .. uuid, true)
	end
	
	--easter egg message that pops if you dunk in the lava in the first room on your first pass
	if areaName == "youAreBadAtGrapplingHook" then
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_completedTutorialGrappleRoom-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_youAreBadAtGrapplingHook")
			world.setProperty("lofty_irisil_dungeon_pickMeUp_completedTutorialGrappleRoom-" .. uuid, true)
		end
	end
	
	--easter egg message if player climbs into the oil chamber
	if areaName == "nothingInThereSorry" then
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_noSecretInTheOilChamber-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_nothingInThereSorry")
			world.setProperty("lofty_irisil_dungeon_pickMeUp_noSecretInTheOilChamber-" .. uuid, true)
			self.lofty_irisil_msgSetSecretCactusIndex = 1
			self.lofty_irisil_msgSetSecretCactusTimer = self.lofty_irisil_timerSpeed_medium
		end
	end

	--entering the red rabbit's chamber
	if areaName == "redriaRoom" then
	
		--if this area has not been completed
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_RED_completed") ~= true then
		
			--if we haven't sent the message to this uuid yet
			if world.getProperty("lofty_irisil_dungeon_pickMeUp_RED_enter-" .. uuid) ~= true then
				player.radioMessage("lofty_irisil_pickMeUp_enterRedRoom")
				world.setProperty("lofty_irisil_dungeon_pickMeUp_RED_enter-" .. uuid, true)
			end
			
		--area has been completed
		else
		
			--have we sent the letsgo message yet?
			if world.getProperty("lofty_irisil_dungeon_pickMeUp_RED_completed_sentDialog-" .. uuid) ~= true then
				player.radioMessage("lofty_irisil_pickMeUp_completeRedRoom")
				world.setProperty("lofty_irisil_dungeon_pickMeUp_RED_completed_sentDialog-" .. uuid, true)
			end
		
		end
		
	end
	
	--exiting red rabbit's chamber, display tutorial message for placing on pedestal
	if areaName == "redriaPedestalTutorial" then
	
		--if redria's circuit has been completed
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_RED_completed") == true then
		
			--if we haven't sent the message to this uuid yet
			if world.getProperty("lofty_irisil_dungeon_pickMeUp_RED_putMeOnThePedestal_sentDialog-" .. uuid) ~= true then
				player.radioMessage("lofty_irisil_pickMeUp_putRedOnPedestal")
				world.setProperty("lofty_irisil_dungeon_pickMeUp_RED_putMeOnThePedestal_sentDialog-" .. uuid, true)
			end
			
		end
	end
	
	--entering or exiting greenill's wing
	if areaName == "greenillPedestalTutorial" then
	
		--if greenill's circuit has not yet been completed
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_GREEN_completed") ~= true then
		
			--if we haven't sent the message to this uuid yet
			if world.getProperty("lofty_irisil_dungeon_pickMeUp_GREEN_enterGreenWing_sentDialog-" .. uuid) ~= true then
				player.radioMessage("lofty_irisil_pickMeUp_enterGreenWing")
				world.setProperty("lofty_irisil_dungeon_pickMeUp_GREEN_enterGreenWing_sentDialog-" .. uuid, true)
			end
			
		--greenill's circuit completed
		else
			
		end
	
	end
	
	--greenill being chatty about gravity
	if areaName == "greenillGravityChatter" then
	
		--if we haven't sent the message to this uuid yet
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_GREEN_gravityChatter_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_gravityChatter")
			world.setProperty("lofty_irisil_dungeon_pickMeUp_GREEN_gravityChatter_sentDialog-" .. uuid, true)
			self.lofty_irisil_msgSetKatamariIndex = 1
			self.lofty_irisil_msgSetKatamariTimer = self.lofty_irisil_timerSpeed_medium
		end
	
	end
	
	--greenill telling the player to go quickly
	if areaName == "greenillSwitchChatter" then 
		--if we haven't sent the message to this uuid yet
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_GREEN_greenSwitchChatter_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_youShouldGoFast")
			world.setProperty("lofty_irisil_dungeon_pickMeUp_GREEN_greenSwitchChatter_sentDialog-" .. uuid, true)
		end
	end
	
	if areaName == "greenillVerticalShaft" then
		--if we haven't sent the message to this uuid yet
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_GREEN_greenillVerticalShaft_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_greenillVerticalShaft")
			world.setProperty("lofty_irisil_dungeon_pickMeUp_GREEN_greenillVerticalShaft_sentDialog-" .. uuid, true)
		end
	end
	
	if areaName == "greenillVerticalShaft2" then
		--if we haven't sent the message to this uuid yet
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_GREEN_greenillVerticalShaft2_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_greenillVerticalShaft2")
			world.setProperty("lofty_irisil_dungeon_pickMeUp_GREEN_greenillVerticalShaft2_sentDialog-" .. uuid, true)
		end
	end
	
	if areaName == "greenillVerticalShaft3" then
		--if we haven't sent the message to this uuid yet
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_GREEN_greenillVerticalShaft3_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_greenillVerticalShaft3")
			world.setProperty("lofty_irisil_dungeon_pickMeUp_GREEN_greenillVerticalShaft3_sentDialog-" .. uuid, true)
		end
	end
	
end

--our wire switches may fire multiple times as they load or unload so it's important to close the gate behind ourselves
function lofty_irisil_handleTimeAttackDialog_RED()

	local uuid = player.serverUuid()

	--successfully completed time attack
	if world.getProperty("lofty_irisil_dungeon_pickMeUp_RED_timeAttack") == true then
	
		--send player success message if it hasn't been sent yet
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_RED_timeAttack_sentDialog") ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_succeedRedTimeAttack")
			world.setProperty("lofty_irisil_dungeon_pickMeUp_RED_timeAttack_sentDialog-" .. uuid, true)
		end
		
	--failed time attack
	else
		
		--send player fail message if it hasn't been sent yet
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_RED_timeAttack_sentDialog") ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_failRedTimeAttack")
			world.setProperty("lofty_irisil_dungeon_pickMeUp_RED_timeAttack_sentDialog-" .. uuid, true)
		end
		
	end
end

--our wire switches may fire multiple times as they load or unload so it's important to close the gate behind ourselves
function lofty_irisil_handleTimeAttackDialog_GREEN()

	local uuid = player.serverUuid()

	--successfully completed time attack
	if world.getProperty("lofty_irisil_dungeon_pickMeUp_GREEN_timeAttack") == true then
	
		--send player success message if it hasn't been sent yet
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_GREEN_timeAttack_sentDialog") ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_succeedGreenTimeAttack")
			world.setProperty("lofty_irisil_dungeon_pickMeUp_GREEN_timeAttack_sentDialog-" .. uuid, true)
			self.lofty_irisil_msgSetGreenTimeAttackSuccessIndex = 1
			self.lofty_irisil_msgSetGreenTimeAttackSuccessTimer = self.lofty_irisil_timerSpeed_medium
		end
		
	--failed time attack
	else
		
		--send player fail message if it hasn't been sent yet
		if world.getProperty("lofty_irisil_dungeon_pickMeUp_GREEN_timeAttack_sentDialog") ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_failGreenTimeAttack")
			world.setProperty("lofty_irisil_dungeon_pickMeUp_GREEN_timeAttack_sentDialog-" .. uuid, true)
			self.lofty_irisil_msgSetGreenTimeAttackFailIndex = 1
			self.lofty_irisil_msgSetGreenTimeAttackFailTimer = self.lofty_irisil_timerSpeed_medium
		end
		
	end
end

--prettymuch just used for handling the timer gaps between broadcasted messages
function update(dt)

	originalUpdate(dt)

	--disable this script unless the player is in the appropriate dungeon for it
	if world.type() ~= "lofty_irisil_challengerooms_pickmeup" then
		return
	end

	lofty_irisil_updateMsgSequence1(dt)
	lofty_irisil_updateMsgSequenceSecretCactus(dt)
	lofty_irisil_updateMsgSequenceKatamari(dt)
	lofty_irisil_updateMsgSequenceGreenTimeAttackSuccess(dt)
	lofty_irisil_updateMsgSequenceGreenTimeAttackFail(dt)
end

--welcome messages
function lofty_irisil_updateMsgSequence1(dt)

	--we only care about the msg sequence timers if we're in a nonzero message state
	if self.lofty_irisil_msgSet1Index > 0 then
		
		--first set of messages welcoming the player to the dungeon
		if self.lofty_irisil_msgSet1Timer > 0 then
		
			--handle time difference
			self.lofty_irisil_msgSet1Timer = self.lofty_irisil_msgSet1Timer - dt
		
			--if it's been 4 seconds
			if self.lofty_irisil_msgSet1Timer <= 0 then
			
				--reset the timer
				self.lofty_irisil_msgSet1Timer = self.lofty_irisil_timerSpeed_medium
				
				--increment the set index
				self.lofty_irisil_msgSet1Index = self.lofty_irisil_msgSet1Index + 1
				
				--this is ugly but easy to read
				if self.lofty_irisil_msgSet1Index == 2 then
					player.radioMessage("lofty_irisil_pickMeUp_welcomeToOurHome_2")
					
				elseif self.lofty_irisil_msgSet1Index == 3 then
					player.radioMessage("lofty_irisil_pickMeUp_welcomeToOurHome_3")
					
				elseif self.lofty_irisil_msgSet1Index == 4 then
					player.radioMessage("lofty_irisil_pickMeUp_welcomeToOurHome_4")
					
				end
			end
		end
	end
end

--list format in case other radio messages need to be inserted later
lofty_irisil_secretCactusMessages = 
{
	"lofty_irisil_pickMeUp_nothingInThereSorry",
	"lofty_irisil_pickMeUp_nothingInThereSorry2",
	"lofty_irisil_pickMeUp_nothingInThereSorry3",
	"lofty_irisil_pickMeUp_nothingInThereSorry4",
	"lofty_irisil_pickMeUp_nothingInThereSorry5",
	"lofty_irisil_pickMeUp_nothingInThereSorry6",
	"lofty_irisil_pickMeUp_nothingInThereSorry7",
	"lofty_irisil_pickMeUp_nothingInThereSorry8",
	"lofty_irisil_pickMeUp_nothingInThereSorry9",
	"lofty_irisil_pickMeUp_nothingInThereSorry10",
	"lofty_irisil_pickMeUp_nothingInThereSorry11",
	"lofty_irisil_pickMeUp_nothingInThereSorry12",
	"lofty_irisil_pickMeUp_nothingInThereSorry13",
	"lofty_irisil_pickMeUp_nothingInThereSorry14",
	"lofty_irisil_pickMeUp_nothingInThereSorry15"
}

function lofty_irisil_updateMsgSequenceSecretCactus(dt)
	--we only care about the msg sequence timers if we're in a nonzero message state
	if self.lofty_irisil_msgSetSecretCactusIndex > 0 then
		
		--first set of messages welcoming the player to the dungeon
		if self.lofty_irisil_msgSetSecretCactusTimer > 0 then
		
			--handle time difference
			self.lofty_irisil_msgSetSecretCactusTimer = self.lofty_irisil_msgSetSecretCactusTimer - dt
		
			--if it's been 4 seconds
			if self.lofty_irisil_msgSetSecretCactusTimer <= 0 then
			
				--reset the timer
				self.lofty_irisil_msgSetSecretCactusTimer = self.lofty_irisil_timerSpeed_medium
				
				--increment the set index
				self.lofty_irisil_msgSetSecretCactusIndex = self.lofty_irisil_msgSetSecretCactusIndex + 1
				
				--send message
				if lofty_irisil_secretCactusMessages[self.lofty_irisil_msgSetSecretCactusIndex] ~= nil then
					player.radioMessage(lofty_irisil_secretCactusMessages[self.lofty_irisil_msgSetSecretCactusIndex])					
				end
				
				--special triggers
				if self.lofty_irisil_msgSetSecretCactusIndex == 5 then
					self.lofty_irisil_msgSetSecretCactusTimer = self.lofty_irisil_timerSpeed_short
					world.setProperty("lofty_irisil_dungeon_pickMeUp_secretCactus", true)
				end
				
				if self.lofty_irisil_msgSetSecretCactusIndex == 6 then
					self.lofty_irisil_msgSetSecretCactusTimer = self.lofty_irisil_timerSpeed_long
				end
			end
		end
	end
end

--list format in case other radio messages need to be inserted later
lofty_irisil_katamariMessages = 
{
	"lofty_irisil_pickMeUp_gravityChatter",
	"lofty_irisil_pickMeUp_gravityChatter2",
	"lofty_irisil_pickMeUp_gravityChatter3"
}

function lofty_irisil_updateMsgSequenceKatamari(dt)
	--we only care about the msg sequence timers if we're in a nonzero message state
	if self.lofty_irisil_msgSetKatamariIndex > 0 then
		
		--first set of messages welcoming the player to the dungeon
		if self.lofty_irisil_msgSetKatamariTimer > 0 then
		
			--handle time difference
			self.lofty_irisil_msgSetKatamariTimer = self.lofty_irisil_msgSetKatamariTimer - dt
		
			--if it's been 4 seconds
			if self.lofty_irisil_msgSetKatamariTimer <= 0 then
			
				--reset the timer
				self.lofty_irisil_msgSetKatamariTimer = self.lofty_irisil_timerSpeed_medium
				
				--increment the set index
				self.lofty_irisil_msgSetKatamariIndex = self.lofty_irisil_msgSetKatamariIndex + 1
				
				--send message
				if lofty_irisil_katamariMessages[self.lofty_irisil_msgSetKatamariIndex] ~= nil then
					player.radioMessage(lofty_irisil_katamariMessages[self.lofty_irisil_msgSetKatamariIndex])					
				end
				
				--special triggers
				if self.lofty_irisil_msgSetKatamariIndex == -1 then
				end
			end
		end
	end
end

--list format in case other radio messages need to be inserted later
lofty_irisil_greenTimeAttackSuccessMessages = 
{
	"lofty_irisil_pickMeUp_succeedGreenTimeAttack",
	"lofty_irisil_pickMeUp_succeedGreenTimeAttack2"
}

function lofty_irisil_updateMsgSequenceGreenTimeAttackSuccess(dt)
	--we only care about the msg sequence timers if we're in a nonzero message state
	if self.lofty_irisil_msgSetGreenTimeAttackSuccessIndex > 0 then
		
		--first set of messages welcoming the player to the dungeon
		if self.lofty_irisil_msgSetGreenTimeAttackSuccessTimer > 0 then
		
			--handle time difference
			self.lofty_irisil_msgSetGreenTimeAttackSuccessTimer = self.lofty_irisil_msgSetGreenTimeAttackSuccessTimer - dt
		
			--if it's been 4 seconds
			if self.lofty_irisil_msgSetGreenTimeAttackSuccessTimer <= 0 then
			
				--reset the timer
				self.lofty_irisil_msgSetGreenTimeAttackSuccessTimer = self.lofty_irisil_timerSpeed_medium
				
				--increment the set index
				self.lofty_irisil_msgSetGreenTimeAttackSuccessIndex = self.lofty_irisil_msgSetGreenTimeAttackSuccessIndex + 1
				
				--send message
				if lofty_irisil_greenTimeAttackSuccessMessages[self.lofty_irisil_msgSetGreenTimeAttackSuccessIndex] ~= nil then
					player.radioMessage(lofty_irisil_greenTimeAttackSuccessMessages[self.lofty_irisil_msgSetGreenTimeAttackSuccessIndex])					
				end
				
				--special triggers
				if self.lofty_irisil_msgSetGreenTimeAttackSuccessIndex == -1 then
				end
			end
		end
	end
end

--list format in case other radio messages need to be inserted later
lofty_irisil_greenTimeAttackFailMessages = 
{
	"lofty_irisil_pickMeUp_failGreenTimeAttack",
	"lofty_irisil_pickMeUp_failGreenTimeAttack2",
	"lofty_irisil_pickMeUp_failGreenTimeAttack3",
	"lofty_irisil_pickMeUp_failGreenTimeAttack4",
	"lofty_irisil_pickMeUp_failGreenTimeAttack5"
}

function lofty_irisil_updateMsgSequenceGreenTimeAttackFail(dt)
	--we only care about the msg sequence timers if we're in a nonzero message state
	if self.lofty_irisil_msgSetGreenTimeAttackFailIndex > 0 then
		
		--first set of messages welcoming the player to the dungeon
		if self.lofty_irisil_msgSetGreenTimeAttackFailTimer > 0 then
		
			--handle time difference
			self.lofty_irisil_msgSetGreenTimeAttackFailTimer = self.lofty_irisil_msgSetGreenTimeAttackFailTimer - dt
		
			--if it's been 4 seconds
			if self.lofty_irisil_msgSetGreenTimeAttackFailTimer <= 0 then
			
				--reset the timer
				self.lofty_irisil_msgSetGreenTimeAttackFailTimer = self.lofty_irisil_timerSpeed_medium
				
				--increment the set index
				self.lofty_irisil_msgSetGreenTimeAttackFailIndex = self.lofty_irisil_msgSetGreenTimeAttackFailIndex + 1
				
				--send message
				if lofty_irisil_greenTimeAttackFailMessages[self.lofty_irisil_msgSetGreenTimeAttackFailIndex] ~= nil then
					player.radioMessage(lofty_irisil_greenTimeAttackFailMessages[self.lofty_irisil_msgSetGreenTimeAttackFailIndex])					
				end
				
				--special triggers
				if self.lofty_irisil_msgSetGreenTimeAttackFailIndex == -1 then
				end
			end
		end
	end
end

function uninit()
	originalUninit()
end