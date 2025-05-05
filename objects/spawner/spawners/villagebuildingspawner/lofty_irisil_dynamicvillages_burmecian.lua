local oldRaceCheck = raceAvailable

function raceAvailable(raceName)	
	if raceName == "burmecian" then
		--we assume that if there is a burmecian flag, the burmecian race is installed
		if liu_itemExists("flagburmecian") then return true end
	end
	
	--otherwise fall through
	return oldRaceCheck(raceName)
end