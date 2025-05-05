local oldRaceCheck = raceAvailable

function raceAvailable(raceName)	
	if raceName == "neki" then
		--we assume that if there is a neki flag, the neki race is installed
		if liu_itemExists("flagneki") then return true end
	end
	
	--otherwise fall through
	return oldRaceCheck(raceName)
end