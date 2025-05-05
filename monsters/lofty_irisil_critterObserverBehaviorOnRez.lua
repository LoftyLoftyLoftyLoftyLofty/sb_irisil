require "/scripts/lofty_irisil_util.lua"
require "/scripts/lofty_irisil_util_biome.lua"

function li_initObserverBehavior(args, board)
	--this will be inherited from the spawntypes file
	local biomeType = config.getParameter("biomeType")
	--save biome data
	liu_biome_saveBiomeAt(biomeType, monster.toAbsolutePosition({0,0}))
	--quietly despawn
	monster.setDeathSound()
	monster.setDeathParticleBurst()
	monster.setDropPool("lofty_irisil_noTreasure")
	status.setResource("health", 0)
	--required for behaviors to work
	return true
end