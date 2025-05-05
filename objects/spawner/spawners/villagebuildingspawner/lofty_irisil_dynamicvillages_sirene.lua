local oldRaceCheck = raceAvailable

function raceAvailable(raceName)	
	if raceName == "sirene" then
		--we assume that if there is a sirene chest masking cosmetic, the sirene race is installed
		if liu_itemExists("sirenemaskchest") then return true end
	end
	
	--otherwise fall through
	return oldRaceCheck(raceName)
end