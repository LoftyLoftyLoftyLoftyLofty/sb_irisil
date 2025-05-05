local oldRaceCheck = raceAvailable

function raceAvailable(raceName)	
	if raceName == "vesperian" then
		--we assume that if there is a vesperian flag, the vesperian race is installed
		if liu_itemExists("flagvesperian") then return true end
	end
	
	--otherwise fall through
	return oldRaceCheck(raceName)
end