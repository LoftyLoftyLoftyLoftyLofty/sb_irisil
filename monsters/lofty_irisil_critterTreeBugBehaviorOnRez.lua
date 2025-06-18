require "/monsters/lofty_irisil_monsterHooks.lua"

function li_initTreeBugBehavior(args, board)

	--yeek("(SERVER) LI-DefaultBehaviorFallthrough", entity.id() .. " - falling through to behavior type '" .. args.behavior .. "'")
	return li_initHooks(args,board)
	--  we don't care about setting a behavior for these mostly stationary insects
	--  return liu_setBehavior(args.behavior)
	
end

local _init = init
function init()
	_init()
	myTree = -1
end

local _update = update
function update(dt)
	_update(dt)
	if myTree == -1 then
		local trees = liu_scanForClimbableTrees(entity.position(),50,true)
		if trees then
			for k, v in pairs(trees) do
				myTree = k
				local avgX = (v.polyClimbable[1][1] + v.polyClimbable[2][1] + v.polyClimbable[3][1] + v.polyClimbable[4][1])/4
				local avgY = (v.polyClimbable[1][2] + v.polyClimbable[2][2] + v.polyClimbable[3][2] + v.polyClimbable[4][2])/4
				liu_setPos( { mode = "global", x = avgX, y = avgY } )
				break
			end
		end
	end
end