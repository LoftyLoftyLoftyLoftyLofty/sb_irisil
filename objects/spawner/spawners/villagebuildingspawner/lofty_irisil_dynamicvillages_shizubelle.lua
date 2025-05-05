local oldRaceCheck = raceAvailable

function raceAvailable(raceName)	
	if raceName == "shizubelle" then
		--we assume that if there is a shizubelle flag, the shizubelle race is installed
		if liu_itemExists("flagshizubelle") then return true end
	end
	
	--otherwise fall through
	return oldRaceCheck(raceName)
end