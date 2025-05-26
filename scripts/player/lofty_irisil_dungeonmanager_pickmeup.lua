--  I know this is very ugly and inefficient
--  I am still learning Lua 
--  Perhaps someday I will come back and clean up this code

require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/scripts/vec2.lua"
require "/scripts/lofty_irisil_util.lua"

local lofty_irisil_dungeonmanager_pickmeup_originalInit = init
local lofty_irisil_dungeonmanager_pickmeup_originalUpdate = update
local lofty_irisil_dungeonmanager_pickmeup_originalUninit = uninit

function lofty_irisil_initDialogSequences()

	self.lofty_irisil_msgSet1Index = 0
	self.lofty_irisil_msgSet1Timer = 4.5
	
	self.lofty_irisil_msgSetSecretCactusIndex = 0
	self.lofty_irisil_msgSetSecretCactusTimer = 4.5
	
	self.lofty_irisil_msgSetSecretTunnelIndex = 0
	self.lofty_irisil_msgSetSecretTunnelTimer = 4.5
	
	self.lofty_irisil_msgSetKatamariIndex = 0
	self.lofty_irisil_msgSetKatamariTimer = 4.5
	
	self.lofty_irisil_msgSetBlueWingIndex = 0
	self.lofty_irisil_msgSetBlueWingTimer = 4.5
	
	self.lofty_irisil_msgSetEnterPuzzleWingIndex = 0
	self.lofty_irisil_msgSetEnterPuzzleWingTimer = 4.5
	
	self.lofty_irisil_msgSetGreenTimeAttackSuccessIndex = 0
	self.lofty_irisil_msgSetGreenTimeAttackSuccessTimer = 4.5
	
	self.lofty_irisil_msgSetGreenTimeAttackFailIndex = 0
	self.lofty_irisil_msgSetGreenTimeAttackFailTimer = 4.5
	
	self.lofty_irisil_timerSpeed_short = 3.0
	self.lofty_irisil_timerSpeed_medium = 4.5
	self.lofty_irisil_timerSpeed_long = 6.0
end

--WORLD STATE VARIABLES
--  lidpmu_welcome_sentDialog- .. uuid
--	lidpmu_completedTutorialGrappleRoom- .. uuid
--	lidpmu_R_enter-
--	lidpmu_R_completed
--	lidpmu_R_completed_sentDialog- .. uuid
--	lidpmu_R_secretSwitch
--	lidpmu_R_timeAttack
--	lidpmu_R_timeAttack_sentDialog- .. uuid
--  lidpmu_R_putMeOnThePedestal_sentDialog- .. uuid
--
--  lidpmu_noSecretInTheOilChamber- .. uuid
--  lidpmu_secretCactus
--  
--  lidpmu_G_enterGreenWing_sentDialog- .. uuid
--  lidpmu_G_completed
--  lidpmu_G_gravityChatter_sentDialog- .. uuid
--  lidpmu_G_greenSwitchChatter_sentDialog- .. uuid
--  lidpmu_G_timeAttack
--  lidpmu_G_timeAttack_sentDialog- .. uuid
--	lidpmu_G_secretSwitch
--  lidpmu_G_greenillVerticalShaft_sentDialog- .. uuid
--  lidpmu_G_greenillVerticalShaft2_sentDialog- .. uuid
--  lidpmu_G_greenillVerticalShaft3_sentDialog- .. uuid
--  lidpmu_G_entered_sentDialog- .. uuid
--  lidpmu_G_completed_sentDialog- .. uuid
--  lidpmu_G_completeGreenRoom
--
--  lidpmu_B_enterBlueWing_sentDialog- .. uuid
--  lidpmu_fennixInstructions_sentDialog- .. uuid
--  lidpmu_runFennixRun
--  lidpmu_fennixStayStill
--  lidpmu_B_secretFennix
--  lidpmu_B_completed
--  lidpmu_fennixResult_sentDialog- .. uuid
--  lidpmu_fennixCapturable_sentDialog- .. uuid
--  lidpmu_letsRoll_sentDialog- .. uuid
--  lidpmu_letsRoll_sentDialog2- .. uuid
--	lidpmu_B_TA_f- .. uuid
--	lidpmu_B_TA1_w1- .. uuid
--	lidpmu_B_TA2_w2- .. uuid
--
--  lidpmu_enterPuzzle_sentDialog- .. uuid
--  lidpmu_easyStuff_sentDialog- .. uuid
--  lidpmu_P_redInstructions_sentDialog- .. uuid
--  lidpmu_P_completeRed- .. uuid
--  lidpmu_P_completeWing- .. uuid
--  lidpmu_P_teamwork- .. uuid
--
--	lidpmu_COMPLETE_KEY_CIRCUIT
--	lidpmu_COMPLETE_KEY_CIRCUIT_sendDialog
--	lidpmu_COMPLETE_KEY_CIRCUIT_sentDialog- .. uuid
--
--  lidpmu_secretTunnel_sentDialog- .. uuid

function init()

	player.setUniverseFlag("lofty_irisil_fixoutpostteleporter")
	lofty_irisil_dungeonmanager_pickmeup_originalInit()
	
	--disable this script unless the player is in the appropriate dungeon for it
	if world.type() ~= "lofty_irisil_challengerooms_pickmeup" then
		return
	end
	
	lofty_irisil_initDialogSequences()
	
	message.setHandler
	(
		"lofty_irisil_triggerSound", 
		function(_, _, tbl)
			lofty_irisil_triggerSound_pickMeUp(tbl)
		end
	)
	
	message.setHandler
	(
		"lofty_irisil_enterArea", 
		function(_, _, tbl)
			lofty_irisil_enterArea_pickMeUp(tbl)
		end
	)
	
	message.setHandler
	(
		"lidpmu_R_timeAttackDialog", 
		function(_, _, tbl)
			lofty_irisil_handleTimeAttackDialog_RED()
		end
	)
	
	message.setHandler
	(
		"lidpmu_R_dontLeaveMeHere", 
		function(_, _, tbl)
			lofty_irisil_dontLeaveMeHere_RED()
		end
	)
	
	message.setHandler
	(
		"lidpmu_G_dontLeaveMeHere", 
		function(_, _, tbl)
			lofty_irisil_dontLeaveMeHere_GREEN()
		end
	)
	
	message.setHandler
	(
		"lidpmu_B_dontLeaveMeHere", 
		function(_, _, tbl)
			lofty_irisil_dontLeaveMeHere_BLUE()
		end
	)
	
	message.setHandler
	(
		"lidpmu_B_easyStuff", 
		function(_, _, tbl)
			lofty_irisil_easyStuff()
		end
	)
	
	
	message.setHandler
	(
		"lidpmu_B_goodTeamwork", 
		function(_, _, tbl)
			lofty_irisil_goodTeamwork()
		end
	)
	
	message.setHandler
	(
		"lidpmu_completeRedBunnyPuzzle", 
		function(_, _, tbl)
			lofty_irisil_completeRedBunnyPuzzle()
		end
	)
	
	message.setHandler
	(
		"lidpmu_completePuzzleWing", 
		function(_, _, tbl)
			lofty_irisil_completePuzzleWing()
		end
	)
	
	message.setHandler
	(
		"lidpmu_fennixInstructions", 
		function(_, _, tbl)
			lofty_irisil_fennixInstructionsDialog()
		end
	)
	
	message.setHandler
	(
		"lidpmu_B_fennixDead", 
		function(_, _, tbl)
			lofty_irisil_fennixResultDialog(false)
		end
	)
	
	message.setHandler
	(
		"lidpmu_B_fennixLiving", 
		function(_, _, tbl)
			lofty_irisil_fennixResultDialog(true)
		end
	)
	
	message.setHandler
	(
		"lidpmu_fennixCapturable", 
		function(_, _, tbl)
			lofty_irisil_fennixCapturable()
		end
	)
	
	message.setHandler
	(
		"lidpmu_B_letsRoll", 
		function(_, _, tbl)
			lofty_irisil_blueLetsRollDialog()
		end
	)
	
	message.setHandler
	(
		"lidpmu_B_letsRoll2", 
		function(_, _, tbl)
			lofty_irisil_blueLetsRollDialog2()
		end
	)
	
	message.setHandler
	(
		"lidpmu_B_TA1_fail", 
		function(_, _, tbl)
			lofty_irisil_blueFailTA1()
		end
	)
	
	message.setHandler
	(
		"lidpmu_B_TA2_fail", 
		function(_, _, tbl)
			lofty_irisil_blueFailTA2()
		end
	)
	
	message.setHandler
	(
		"lidpmu_B_TA1_win", 
		function(_, _, tbl)
			lofty_irisil_blueWinTA1()
		end
	)
	
	message.setHandler
	(
		"lidpmu_B_TA2_win", 
		function(_, _, tbl)
			lofty_irisil_blueWinTA2()
		end
	)
	
	message.setHandler
	(
		"lidpmu_G_timeAttackDialog", 
		function(_, _, tbl)
			lofty_irisil_handleTimeAttackDialog_GREEN()
		end
	)
	
	message.setHandler
	(
		"lidpmu_fat",
		function(_, _, tbl)
			lofty_irisil_wayTooFat()
		end
	)
	
end

function lofty_irisil_wayTooFat()
	status.setResource("health",0)
end

--triggered when the player receives a sound command
function lofty_irisil_triggerSound_pickMeUp(sound)
	localAnimator.playAudio(sound)
end

--triggered when player hits an area marker
function lofty_irisil_enterArea_pickMeUp(tbl)

	local areaName = tbl.areaName
	local uuid = player.serverUuid()

	--enter the dungeon dialog
	if areaName == "entryway" then
		if world.getProperty("lidpmu_welcome_sentDialog-" .. uuid) ~= true then
			world.setProperty("lidpmu_welcome_sentDialog-" .. uuid, true)
			player.radioMessage("lofty_irisil_pickMeUp_welcomeToOurHome_1")
			self.lofty_irisil_msgSet1Index = 1
			self.lofty_irisil_msgSet1Timer = self.lofty_irisil_timerSpeed_medium
		end
	end

	--disable easter egg below
	if areaName == "disableYouSuckMessage" then
		world.setProperty("lidpmu_completedTutorialGrappleRoom-" .. uuid, true)
	end
	
	--easter egg message that pops if you dunk in the lava in the first room on your first pass
	if areaName == "youAreBadAtGrapplingHook" then
		if world.getProperty("lidpmu_completedTutorialGrappleRoom-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_youAreBadAtGrapplingHook")
			world.setProperty("lidpmu_completedTutorialGrappleRoom-" .. uuid, true)
		end
	end
	
	--easter egg message if player climbs into the oil chamber
	if areaName == "nothingInThereSorry" then
		if world.getProperty("lidpmu_noSecretInTheOilChamber-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_nothingInThereSorry")
			world.setProperty("lidpmu_noSecretInTheOilChamber-" .. uuid, true)
			self.lofty_irisil_msgSetSecretCactusIndex = 1
			self.lofty_irisil_msgSetSecretCactusTimer = self.lofty_irisil_timerSpeed_medium
		end
	end
	
	--easter egg message if player manages to get into the rabbit tunnel
	if areaName == "secretTunnel" then
		if world.getProperty("lidpmu_secretTunnel_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lidpmu_secretTunnel1")
			world.setProperty("lidpmu_secretTunnel_sentDialog-" .. uuid, true)
			self.lofty_irisil_msgSetSecretTunnelIndex = 1
			self.lofty_irisil_msgSetSecretTunnelTimer = self.lofty_irisil_timerSpeed_medium
		end
	end

	--entering the red rabbit's chamber
	if areaName == "redriaRoom" then
	
		--if this area has not been completed
		if world.getProperty("lidpmu_R_completed") ~= true then
		
			--if we haven't sent the message to this uuid yet
			if world.getProperty("lidpmu_R_enter-" .. uuid) ~= true then
				player.radioMessage("lofty_irisil_pickMeUp_enterRedRoom")
				world.setProperty("lidpmu_R_enter-" .. uuid, true)
			end
			
		--area has been completed
		else
		
			--have we sent the letsgo message yet?
			if world.getProperty("lidpmu_R_completed_sentDialog-" .. uuid) ~= true then
				player.radioMessage("lofty_irisil_pickMeUp_completeRedRoom")
				world.setProperty("lidpmu_R_completed_sentDialog-" .. uuid, true)
			end
		
		end
		
	end
	
	--exiting red rabbit's chamber, display tutorial message for placing on pedestal
	if areaName == "redriaPedestalTutorial" then
	
		--if redria's circuit has been completed
		if world.getProperty("lidpmu_R_completed") == true then
		
			--if we haven't sent the message to this uuid yet
			if world.getProperty("lidpmu_R_putMeOnThePedestal_sentDialog-" .. uuid) ~= true then
				player.radioMessage("lofty_irisil_pickMeUp_putRedOnPedestal")
				world.setProperty("lidpmu_R_putMeOnThePedestal_sentDialog-" .. uuid, true)
			end
			
		end
	end
	
	--entering or exiting greenill's wing
	if areaName == "greenillPedestalTutorial" then
	
		--if greenill's circuit has not yet been completed
		if world.getProperty("lidpmu_G_completed") ~= true then
		
			--if we haven't sent the message to this uuid yet
			if world.getProperty("lidpmu_G_enterGreenWing_sentDialog-" .. uuid) ~= true then
				player.radioMessage("lofty_irisil_pickMeUp_enterGreenWing")
				world.setProperty("lidpmu_G_enterGreenWing_sentDialog-" .. uuid, true)
			end
			
		--greenill's circuit completed
		else
			
			--if we haven't sent the message to this uuid yet
			if world.getProperty("lidpmu_G_putMeOnThePedestal_sentDialog-" .. uuid) ~= true then
				player.radioMessage("lofty_irisil_pickMeUp_putGreenOnPedestal")
				world.setProperty("lidpmu_G_putMeOnThePedestal_sentDialog-" .. uuid, true)
			end
			
		end
	
	end
	
	--greenill being chatty about gravity
	if areaName == "greenillGravityChatter" then
	
		--if we haven't sent the message to this uuid yet
		if world.getProperty("lidpmu_G_gravityChatter_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_gravityChatter")
			world.setProperty("lidpmu_G_gravityChatter_sentDialog-" .. uuid, true)
			self.lofty_irisil_msgSetKatamariIndex = 1
			self.lofty_irisil_msgSetKatamariTimer = self.lofty_irisil_timerSpeed_medium
		end
	
	end
	
	--greenill telling the player to go quickly
	if areaName == "greenillSwitchChatter" then 
		--if we haven't sent the message to this uuid yet
		if world.getProperty("lidpmu_G_greenSwitchChatter_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_youShouldGoFast")
			world.setProperty("lidpmu_G_greenSwitchChatter_sentDialog-" .. uuid, true)
		end
	end
	
	if areaName == "greenillVerticalShaft" then
		--if we haven't sent the message to this uuid yet
		if world.getProperty("lidpmu_G_greenillVerticalShaft_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_greenillVerticalShaft")
			world.setProperty("lidpmu_G_greenillVerticalShaft_sentDialog-" .. uuid, true)
		end
	end
	
	if areaName == "greenillVerticalShaft2" then
		--if we haven't sent the message to this uuid yet
		if world.getProperty("lidpmu_G_greenillVerticalShaft2_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_greenillVerticalShaft2")
			world.setProperty("lidpmu_G_greenillVerticalShaft2_sentDialog-" .. uuid, true)
		end
	end
	
	if areaName == "greenillVerticalShaft3" then
		--if we haven't sent the message to this uuid yet
		if world.getProperty("lidpmu_G_greenillVerticalShaft3_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_greenillVerticalShaft3")
			world.setProperty("lidpmu_G_greenillVerticalShaft3_sentDialog-" .. uuid, true)
		end
	end
	
	--entering the green rabbit's chamber
	if areaName == "greenillRoom" then

		--have we sent the letsgo message yet?
		if world.getProperty("lidpmu_G_entered_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_enterGreenRoom")
			world.setProperty("lidpmu_G_entered_sentDialog-" .. uuid, true)
		end
		
	end
	
	--completing the green rabbit's chamber
	if areaName == "greenillRoomCompleted" then

		--have we sent the letsgo message yet?
		if world.getProperty("lidpmu_G_completed_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_completeGreenRoom")
			world.setProperty("lidpmu_G_completed_sentDialog-" .. uuid, true)
		end
		
	end
	
	--entering or exiting bluefull's wing
	if areaName == "bluefullPedestalTutorial" then
	
		--if bluefull's circuit has not yet been completed
		if world.getProperty("lidpmu_B_completed") ~= true then
		
			--if we haven't sent the message to this uuid yet
			if world.getProperty("lidpmu_B_enterBlueWing_sentDialog-" .. uuid) ~= true then
				player.radioMessage("lofty_irisil_pickMeUp_enterBlueWing1")
				world.setProperty("lidpmu_B_enterBlueWing_sentDialog-" .. uuid, true)
				self.lofty_irisil_msgSetBlueWingIndex = 1
				self.lofty_irisil_msgSetBlueWingTimer = self.lofty_irisil_timerSpeed_medium
			end
			
		--bluefull's circuit completed
		else
			
			--if we haven't sent the message to this uuid yet
			if world.getProperty("lidpmu_B_putMeOnThePedestal_sentDialog-" .. uuid) ~= true then
				player.radioMessage("lofty_irisil_pickMeUp_putBlueOnPedestal")
				world.setProperty("lidpmu_B_putMeOnThePedestal_sentDialog-" .. uuid, true)
			end
			
		end
	
	end
	
	--entering bunny puzzle gauntlet
	if areaName == "beginPuzzleArea" then
	
		--have we sent the letsgo message yet?
		if world.getProperty("lidpmu_enterPuzzle_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_enterPuzzleWing1")
			world.setProperty("lidpmu_enterPuzzle_sentDialog-" .. uuid, true)
			self.lofty_irisil_msgSetEnterPuzzleWingIndex = 1
			self.lofty_irisil_msgSetEnterPuzzleWingTimer = self.lofty_irisil_timerSpeed_medium
		end
	
	end
	
	--red bunny puzzle
	if areaName == "redBunnyDropPuzzleInstructions" then
	
		--if we haven't sent the message to this uuid yet
		if world.getProperty("lidpmu_P_redInstructions_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_redBunnyPuzzleInstructions")
			world.setProperty("lidpmu_P_redInstructions_sentDialog-" .. uuid, true)
		end
	end
end

function lofty_irisil_dontLeaveMeHere_RED()

	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_R_dontLeaveMeHere_sentDialog-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_dontLeaveMeHere_RED")
		world.setProperty("lidpmu_R_dontLeaveMeHere_sentDialog-" .. uuid, true)
	end
	
end

function lofty_irisil_dontLeaveMeHere_GREEN()

	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_G_dontLeaveMeHere_sentDialog-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_dontLeaveMeHere_GREEN")
		world.setProperty("lidpmu_G_dontLeaveMeHere_sentDialog-" .. uuid, true)
	end
	
end

function lofty_irisil_dontLeaveMeHere_BLUE()

	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_B_dontLeaveMeHere_sentDialog-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_dontLeaveMeHere_BLUE")
		world.setProperty("lidpmu_B_dontLeaveMeHere_sentDialog-" .. uuid, true)
	end
	
end

function lofty_irisil_completeRedBunnyPuzzle()
	
	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_P_completeRed-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_redBunnyPuzzleComplete")
		world.setProperty("lidpmu_P_completeRed-" .. uuid, true)
	end
end

function lofty_irisil_completePuzzleWing()
	
	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_P_completeWing-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_completePuzzleWing")
		world.setProperty("lidpmu_P_completeWing-" .. uuid, true)
	end
end

function lofty_irisil_goodTeamwork()

	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_P_teamwork-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_goodTeamwork")
		world.setProperty("lidpmu_P_teamwork-" .. uuid, true)
	end
end

function lofty_irisil_fennixResultDialog(living)

	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_fennixResult_sentDialog-" .. uuid) ~= true then
		if living then
			player.radioMessage("lofty_irisil_pickMeUp_fennixRoomSafe")
		else
			player.radioMessage("lofty_irisil_pickMeUp_fennixRoomDead")
		end
		world.setProperty("lidpmu_fennixResult_sentDialog-" .. uuid, true)
	end
	
end

function lofty_irisil_fennixInstructionsDialog()

	local uuid = player.serverUuid()

	--if we haven't sent the message to this uuid yet
	if world.getProperty("lidpmu_fennixInstructions_sentDialog-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_fennixRoomInstructions")
		world.setProperty("lidpmu_fennixInstructions_sentDialog-" .. uuid, true)
	end

end

function lofty_irisil_fennixCapturable()

	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_fennixCapturable_sentDialog-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_fennixCapturable")
		world.setProperty("lidpmu_fennixCapturable_sentDialog-" .. uuid, true)
	end
	
end

function lofty_irisil_easyStuff()

	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_easyStuff_sentDialog-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_enterPuzzleWing5")
		world.setProperty("lidpmu_easyStuff_sentDialog-" .. uuid, true)
	end

end

function lofty_irisil_blueLetsRollDialog()

	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_letsRoll_sentDialog-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_B_letsGo")
		world.setProperty("lidpmu_letsRoll_sentDialog-" .. uuid, true)
	end
	
end

function lofty_irisil_blueLetsRollDialog2()

	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_letsRoll_sentDialog2-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_B_letsRoll")
		world.setProperty("lidpmu_letsRoll_sentDialog2-" .. uuid, true)
	end
	
end

function lofty_irisil_blueFailTA1()

	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_B_TA_f-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_B_TA_fail")
		world.setProperty("lidpmu_B_TA_f-" .. uuid, true)
	end

end

function lofty_irisil_blueFailTA2()

	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_B_TA_f-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_B_TA_fail")
		world.setProperty("lidpmu_B_TA_f-" .. uuid, true)
	end

end

function lofty_irisil_blueWinTA1()

	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_B_TA1_w1-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_B_TA1_success")
		world.setProperty("lidpmu_B_TA1_w1-" .. uuid, true)
	end

end

function lofty_irisil_blueWinTA2()

	local uuid = player.serverUuid()

	--send players message if it hasn't been sent yet
	if world.getProperty("lidpmu_B_TA1_w2-" .. uuid) ~= true then
		player.radioMessage("lofty_irisil_pickMeUp_B_TA2_success")
		world.setProperty("lidpmu_B_TA1_w2-" .. uuid, true)
	end

end

--our wire switches may fire multiple times as they load or unload so it's important to close the gate behind ourselves
function lofty_irisil_handleTimeAttackDialog_RED()

	local uuid = player.serverUuid()

	--successfully completed time attack
	if world.getProperty("lidpmu_R_timeAttack") == true then
	
		--send player success message if it hasn't been sent yet
		if world.getProperty("lidpmu_R_timeAttack_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_succeedRedTimeAttack")
			world.setProperty("lidpmu_R_timeAttack_sentDialog-" .. uuid, true)
		end
		
	--failed time attack
	else
		
		--send player fail message if it hasn't been sent yet
		if world.getProperty("lidpmu_R_timeAttack_sentDialog-") ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_failRedTimeAttack")
			world.setProperty("lidpmu_R_timeAttack_sentDialog-" .. uuid, true)
		end
		
	end
end

--our wire switches may fire multiple times as they load or unload so it's important to close the gate behind ourselves
function lofty_irisil_handleTimeAttackDialog_GREEN()

	local uuid = player.serverUuid()

	--successfully completed time attack
	if world.getProperty("lidpmu_G_timeAttack") == true then
	
		--send player success message if it hasn't been sent yet
		if world.getProperty("lidpmu_G_timeAttack_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_succeedGreenTimeAttack")
			world.setProperty("lidpmu_G_timeAttack_sentDialog-" .. uuid, true)
			self.lofty_irisil_msgSetGreenTimeAttackSuccessIndex = 1
			self.lofty_irisil_msgSetGreenTimeAttackSuccessTimer = self.lofty_irisil_timerSpeed_medium
		end
		
	--failed time attack
	else
		
		--send player fail message if it hasn't been sent yet
		if world.getProperty("lidpmu_G_timeAttack_sentDialog-" .. uuid) ~= true then
			player.radioMessage("lofty_irisil_pickMeUp_failGreenTimeAttack")
			world.setProperty("lidpmu_G_timeAttack_sentDialog-" .. uuid, true)
			self.lofty_irisil_msgSetGreenTimeAttackFailIndex = 1
			self.lofty_irisil_msgSetGreenTimeAttackFailTimer = self.lofty_irisil_timerSpeed_medium
		end
		
	end
end

--prettymuch just used for handling the timer gaps between broadcasted messages
function update(dt)

	lofty_irisil_dungeonmanager_pickmeup_originalUpdate(dt)

	--disable this script unless the player is in the appropriate dungeon for it
	if world.type() ~= "lofty_irisil_challengerooms_pickmeup" then
		return
	end
	
	local uuid = player.serverUuid()

	lofty_irisil_updateMsgSequence1(dt)
	lofty_irisil_updateMsgSequenceSecretCactus(dt)
	lofty_irisil_updateMsgSequenceSecretTunnel(dt)
	lofty_irisil_updateMsgSequenceKatamari(dt)
	lofty_irisil_updateMsgSequenceBlueWing(dt)
	lofty_irisil_updateMsgSequenceGreenTimeAttackSuccess(dt)
	lofty_irisil_updateMsgSequenceGreenTimeAttackFail(dt)
	lofty_irisil_updateMsgSequenceEnterPuzzleWing(dt)
	
	if world.getProperty("lidpmu_COMPLETE_KEY_CIRCUIT_sendDialog") == true then
		if world.getProperty("lidpmu_COMPLETE_KEY_CIRCUIT_sendDialog-" .. uuid) ~= true then
			player.radioMessage("lidpmu_COMPLETE_KEY_CIRCUIT_sendDialog")
			world.setProperty("lidpmu_COMPLETE_KEY_CIRCUIT_sentDialog-" .. uuid, true)
		end
	end
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
					world.setProperty("lidpmu_secretCactus", true)
				end
				
				if self.lofty_irisil_msgSetSecretCactusIndex == 6 then
					self.lofty_irisil_msgSetSecretCactusTimer = self.lofty_irisil_timerSpeed_long
				end
			end
		end
	end
end

--list format in case other radio messages need to be inserted later
lofty_irisil_enterPuzzleWingMessages = 
{
	"lofty_irisil_pickMeUp_enterPuzzleWing1",
	"lofty_irisil_pickMeUp_enterPuzzleWing2",
	"lofty_irisil_pickMeUp_enterPuzzleWing3",
	"lofty_irisil_pickMeUp_enterPuzzleWing4"
}

function lofty_irisil_updateMsgSequenceEnterPuzzleWing(dt)
	--we only care about the msg sequence timers if we're in a nonzero message state
	if self.lofty_irisil_msgSetEnterPuzzleWingIndex > 0 then
		
		--begin sequence
		if self.lofty_irisil_msgSetEnterPuzzleWingTimer > 0 then
		
			--handle time difference
			self.lofty_irisil_msgSetEnterPuzzleWingTimer = self.lofty_irisil_msgSetEnterPuzzleWingTimer - dt
		
			--if it's been 4 seconds
			if self.lofty_irisil_msgSetEnterPuzzleWingTimer <= 0 then
			
				--reset the timer
				self.lofty_irisil_msgSetEnterPuzzleWingTimer = self.lofty_irisil_timerSpeed_medium
				
				--increment the set index
				self.lofty_irisil_msgSetEnterPuzzleWingIndex = self.lofty_irisil_msgSetEnterPuzzleWingIndex + 1
				
				--send message
				if lofty_irisil_enterPuzzleWingMessages[self.lofty_irisil_msgSetEnterPuzzleWingIndex] ~= nil then
					player.radioMessage(lofty_irisil_enterPuzzleWingMessages[self.lofty_irisil_msgSetEnterPuzzleWingIndex])					
				end
			end
		end
	end
end

--list format in case other radio messages need to be inserted later
lofty_irisil_secretTunnelMessages = 
{
	"lidpmu_secretTunnel1",
	"lidpmu_secretTunnel2",
	"lidpmu_secretTunnel3"
}

function lofty_irisil_updateMsgSequenceSecretTunnel(dt)
	--we only care about the msg sequence timers if we're in a nonzero message state
	if self.lofty_irisil_msgSetSecretTunnelIndex > 0 then
		
		--begin sequence
		if self.lofty_irisil_msgSetSecretTunnelTimer > 0 then
		
			--handle time difference
			self.lofty_irisil_msgSetSecretTunnelTimer = self.lofty_irisil_msgSetSecretTunnelTimer - dt
		
			--if it's been 4 seconds
			if self.lofty_irisil_msgSetSecretTunnelTimer <= 0 then
			
				--reset the timer
				self.lofty_irisil_msgSetSecretTunnelTimer = self.lofty_irisil_timerSpeed_medium
				
				--increment the set index
				self.lofty_irisil_msgSetSecretTunnelIndex = self.lofty_irisil_msgSetSecretTunnelIndex + 1
				
				--send message
				if lofty_irisil_secretCactusMessages[self.lofty_irisil_msgSetSecretTunnelIndex] ~= nil then
					player.radioMessage(lofty_irisil_secretTunnelMessages[self.lofty_irisil_msgSetSecretTunnelIndex])					
				end
			end
		end
	end
end

--list format in case other radio messages need to be inserted later
lofty_irisil_blueWingMessages = 
{
	"lofty_irisil_pickMeUp_enterBlueWing1",
	"lofty_irisil_pickMeUp_enterBlueWing2",
	"lofty_irisil_pickMeUp_enterBlueWing3",
	"lofty_irisil_pickMeUp_enterBlueWing4"
}

function lofty_irisil_updateMsgSequenceBlueWing(dt)
	--we only care about the msg sequence timers if we're in a nonzero message state
	if self.lofty_irisil_msgSetBlueWingIndex > 0 then
		
		--first set of messages welcoming the player to the dungeon
		if self.lofty_irisil_msgSetBlueWingTimer > 0 then
		
			--handle time difference
			self.lofty_irisil_msgSetBlueWingTimer = self.lofty_irisil_msgSetBlueWingTimer - dt
		
			--if it's been 4 seconds
			if self.lofty_irisil_msgSetBlueWingTimer <= 0 then
			
				--reset the timer
				self.lofty_irisil_msgSetBlueWingTimer = self.lofty_irisil_timerSpeed_medium
				
				--increment the set index
				self.lofty_irisil_msgSetBlueWingIndex = self.lofty_irisil_msgSetBlueWingIndex + 1
				
				--send message
				if lofty_irisil_blueWingMessages[self.lofty_irisil_msgSetBlueWingIndex] ~= nil then
					player.radioMessage(lofty_irisil_blueWingMessages[self.lofty_irisil_msgSetBlueWingIndex])					
				end
				
				--special triggers
				if self.lofty_irisil_msgSetBlueWingIndex == -1 then
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
	lofty_irisil_dungeonmanager_pickmeup_originalUninit()
end