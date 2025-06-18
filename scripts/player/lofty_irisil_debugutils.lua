require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/scripts/vec2.lua"
require "/scripts/lofty_irisil_util.lua"
require "/scripts/lofty_irisil_util_tree.lua"

local _init = init
local _update = update
local _uninit = uninit

function init()
	_init()
end

function update(dt)
	_update(dt)
	liu_scanForClimbableTrees( world.entityPosition(player.id()), 50)
end

function uninit()
	_uninit()
end