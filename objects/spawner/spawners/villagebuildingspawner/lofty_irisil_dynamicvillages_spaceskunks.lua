local oldRaceCheck = raceAvailable

function raceAvailable(raceName)	
	if raceName == "skumks" then
		--we assume that if there is a space skunks flag, the space skunks race is installed
		if liu_itemExists("flagskumks") then return true end
	end
	
	--otherwise fall through
	return oldRaceCheck(raceName)
end