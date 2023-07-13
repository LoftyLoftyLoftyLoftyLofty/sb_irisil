--from here: https://www.tutorialspoint.com/how-to-remove-lua-table-entry-by-its-key
function table.liu_removeKey(table, key)
   local element = table[key]
   table[key] = nil
   return element
end

--basically the wiki's wrapper for sendEntityMessage as a util func
function liu_SEM(target, msgType, payload)
	if world.entityExists(target) then
		if payload ~= nil then
			world.sendEntityMessage(target,msgType,payload)
		else
			world.sendEntityMessage(target,msgType)
		end
	end
end

--string splitter from here: https://stackoverflow.com/questions/1426954/split-string-in-lua
function liu_split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function liu_setBehavior(b)

	--copypasted from monsters/monster.lua @ line 29
	self.behavior = behavior.behavior(b, sb.jsonMerge(config.getParameter("behaviorConfig", {}), skillBehaviorConfig()), _ENV)
    self.board = self.behavior:blackboard()
    self.board:setPosition("spawn", storage.spawnPosition)
	
	return true
end

--debug to log, expects the name of the debug source to be passed in, usually an identifier for the script
lofty_irisil_enableDebug = true
function yeek(n, s)
	if lofty_irisil_enableDebug then
		sb.logInfo(n .. " -> " .. s)
	end
end