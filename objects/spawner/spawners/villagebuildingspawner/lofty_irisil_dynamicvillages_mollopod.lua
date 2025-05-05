local oldRaceCheck = raceAvailable

function raceAvailable(raceName)	
	if raceName == "mollopod" then
		--we assume that if there is a mollopod flag, the mollopod race is installed
		if liu_itemExists("flagmollopod") then return true end
	end
	
	--otherwise fall through
	return oldRaceCheck(raceName)
end