--	MOD-FRIENDLY NPC SPAWNER
--	LOFTY 2023-07-25
--  updated 2025-04-21
--
--	WTFPLV2
--
--	This spawner is intended to make it easier for modders to hook into each others' content.
--  I originally created this to make spawners that:
--		-> Could spawn more than one race type
--		-> Could detect modded races and spawn those too (with special params if necessary)
--
--	You are allowed to reuse redistribute etc this software
--	Make your universe a better place
--  Love you
--
------------------------------------------------------
--
--	HOW TO SET UP THIS SPAWNER:
--
--	In Tiled, place one of the NPC spawners (doesn't matter which one, I used the wizard spawner)
--  Change the object field to lofty_irisil_modfriendlynpcspawner (or whatever you named your version)
--  Add a parameters field. Here is an example of the data to put in it:
--  	{ "spawner" : { "possibleVariations" : [ { "intendedUsage" : "Hylotl Post Office - any species", "scriptedTargetTags" : [ "faction:lofty_irisil_hylotlpostoffice", "species:any", "friendly"], "npcSpeciesOptions" : [ "apex", "avian", "floran", "glitch", "human", "hylotl", "novakid" ], "npcTypeOptions" : [ "lofty_irisil_hylotlpostoffice" ], "npcParameterOptions" : [], "npcSeedOptions" : [] } ] } }
--
--  This example data sets up the following:
--
--		intendedUsage 		-> simple description of what you want the spawner to be used for. makes your intent clear to other modders when looking at the json for a dungeon
--
--		scriptedTargetTags 	-> add some tags that might be helpful for other modders to hook into. or don't. whatever. be responsible
--			developer note: "species:any" is the tag that I use to inject more races into spawners with my hotpatch scripts
--
--		npcSpeciesOptions	-> the races that this spawner will try to make. it chooses one at random. (required)
--
--		npcTypeOptions		-> the types of npc that this spawner will try to make. it chooses one at random. (required)
--
--		npcParameterOptions	-> you can put entire npc parameter dumps in here if you want using { and }. it chooses one of these parameter sets at random (optional)
--
--		npcSeedOptions		-> if you want to spawn particularly-seeded npcs you can put your seed numbers here. it chooses one of these at random. (optional)
--
------------------------------------------------------
--
--	HOW TO HOOK INTO THIS SPAWNER WITH A SCRIPT:
--
--		See lofty_irisil_mfnpcs_hotpatch_postoffice_neki for an example script
--		Patch the object file and add your hotpatch script to the scripts list
--			or
--		Patch the tiled file and add your hotpatch script to the scripts list and/or make any other params changes you need to make
--
------------------------------------------------------

require "/scripts/util.lua"

function init()
  object.setInteractive(false)
  animator.setAnimationState("switchState", "on")
end

--template functions intended to be hijacked by hotpatch scripts
function possibleVariationsScriptHook(args)
	return args
end

function selectedVariationScriptHook(args)
	return args
end

function finalResultScriptHook(args)
	return args
end
---------

function update(dt)

  --if player can see spawner, do nothing
  --sometimes this can create awkward situations if you /placedungeon in view distance
  --feel free to edit/patch offscreenOnly if you want the spawner to always fire
  
  if config.getParameter("offscreenOnly") == true then
	  if world.isVisibleToPlayer(object.boundBox()) then
		return nil
	  end
  end
  
  --force the RNG to do stuff several times across several ticks to make sure it gets seeded properly
  if not storage.multiplayer then
    storage.multiplayer = 1
  else
    storage.multiplayer = storage.multiplayer + math.random(1,10)
  end
  
  if storage.multiplayer < 49 then
    return nil
  end
  
  --grab the list of possible variations this spawner can make, use script hooks to dynamically modify
  local options = possibleVariationsScriptHook(config.getParameter("spawner.possibleVariations"))
  
  --choose one of our available options
  local selectedOption = options[math.random(1,#options)]
  
  --pipe the selected option through a scripted hook in case this particular variation needs additional changes
  selectedOption = selectedVariationScriptHook(selectedOption)
  
  --set up spawn parameters for our new NPC
  
  local npcSpecies = "notInstalled"
  if #selectedOption.npcSpeciesOptions > 0 then
	npcSpecies = selectedOption.npcSpeciesOptions[math.random(1,#selectedOption.npcSpeciesOptions)]
  end
  
  --trying to spawn a variant we don't have a race for - abort mission
  if npcSpecies == "notInstalled" then return nil end
  
  local npcType = "villager"
  if #selectedOption.npcTypeOptions > 0 then
    npcType = selectedOption.npcTypeOptions[math.random(1,#selectedOption.npcTypeOptions)]
  end
  
  local npcParameter = nil
  if #selectedOption.npcParameterOptions > 0 then
    npcParameter = selectedOption.npcParameterOptions[math.random(1,#selectedOption.npcParameterOptions)]
  end
  
  local npcSeed = nil;
  if #selectedOption.npcSeedOptions > 0 then
	npcSeed = selectedOption.npcSeedOptions[math.random(1,#selectedOption.npcSeedOptions)]
  end
  
  --now that we've set up our spawn parameters, do one final script-hook sanitycheck for our params
  local finalResult = { fnpcSpecies = npcSpecies, fnpcType = npcType, fnpcParameter = npcParameter, fnpcSeed = npcSeed }
  finalResult = finalResultScriptHook(finalResult)
  
  npcSpecies = finalResult.fnpcSpecies
  npcType = finalResult.fnpcType
  npcParameter = finalResult.fnpcParameter
  npcSeed = finalResult.fnpcSeed
  
  --preserved (slightly modified, possibly vestigial) code from vanilla spawners
  --originally this overwrote the scriptconfig for the npc entirely which was annoying. bug? who knows. fixed now.
  if fnpcParameter ~= nil then
	if fnpcParameter.scriptConfig ~= nil then
		--i'm not sure what this spawnedBy param is even used for, if anything
		fnpcParameter.scriptConfig.spawnedBy = object.position()
	end
  end
  
  --spawn the NPC and smash the spawner
  local worldPos = object.toAbsolutePosition({ 0.0, 2.0 })
  local offset = config.getParameter("spawner.offset")
  if offset then 
	worldPos[1] = worldPos[1] + offset[1]
	worldPos[2] = worldPos[2] + offset[2]
  end
  world.spawnNpc(worldPos, npcSpecies, npcType, math.max(object.level(), 1), npcSeed, npcParameter);
  object.smash()
  
end
