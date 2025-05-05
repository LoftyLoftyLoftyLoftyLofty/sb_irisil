local oldRaceCheck = raceAvailable

function raceAvailable(raceName)	
	if raceName == "satkyterran" then
		--we assume that if there is a lamia fancy bed, the lamia race is installed
		if liu_itemExists("flagkyterran") then return true end
	end
	
	--otherwise fall through
	return oldRaceCheck(raceName)
end