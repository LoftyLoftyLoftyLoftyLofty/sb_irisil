require "/scripts/lofty_irisil_util.lua"

function li_initDefaultBehavior(args, board)

	yeek("(SERVER) LI-DefaultBehaviorFallthrough", entity.id() .. " - falling through to behavior type '" .. args.behavior .. "'")
	return liu_setBehavior(args.behavior)
	
end