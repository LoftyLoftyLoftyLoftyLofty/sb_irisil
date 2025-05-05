local oldRaceCheck = raceAvailable

function raceAvailable(raceName)	
	if raceName == "renamonlk" then
		--we assume that if there is a renamon flag, the renamon race is installed
		if liu_itemExists("flagrenamonlk") then return true end
	end
	
	--otherwise fall through
	return oldRaceCheck(raceName)
end