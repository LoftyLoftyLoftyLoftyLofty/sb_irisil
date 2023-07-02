function liu_SEM(target, msgType, payload)
	if world.entityExists(target) then
		if payload ~= nil then
			world.sendEntityMessage(target,msgType,payload)
		else
			world.sendEntityMessage(target,msgType)
		end
	end
end