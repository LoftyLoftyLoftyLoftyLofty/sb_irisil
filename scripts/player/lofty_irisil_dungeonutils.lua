require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/scripts/vec2.lua"
require "/scripts/lofty_irisil_util.lua"

local originalInit = init
local originalUpdate = update
local originalUninit = uninit

function init()

	originalInit()
	
	message.setHandler
	(
		"lofty_irisil_SYN", 
		function(_, _, sender)
			liu_SEM(sender,"lofty_irisil_ACK",entity.id())
		end
	)
	
	yeek("(PLAYER) LI-DungeonUtils", "Player script initialized!")

end

--prettymuch just used for handling the timer gaps between broadcasted messages
function update(dt)
	originalUpdate(dt)
end

function uninit()
	originalUninit()
end