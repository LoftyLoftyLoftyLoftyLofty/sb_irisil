--function hijacks
local oldInit = init
local oldUninit = uninit
local oldUpdate = update
local oldPossibleVariationsScriptHook = possibleVariationsScriptHook
local oldSelectedVariationScriptHook = selectedVariationScriptHook
local oldFinalResultScriptHook = finalResultScriptHook

--used to verify we're not inserting the same thing twice
function tableContains(tbl, val)
	for _, value in pairs(tbl) do
		if value == val then
			return true
		end
	end
	return false
end

--special thanks to Silver Sokolova for this snippet
function liu_itemExists(itemName)
	return root.itemConfig(itemName) ~= nil
end

--expected value for args is config.getParameter("spawner.possibleVariations")
function possibleVariationsScriptHook(args)

	--this function is intended to be called when you need to (potentially) make changes to all of the possible variations of NPCs a spawner can produce
	--example: adding races to anything set as species:any
	--at this stage we are able to look at all of the possible npc archetypes the spawner might pick from and make changes / add / remove archetypes
	
	--run the (original or modified by someone else) script hook chain for this func
	args = oldPossibleVariationsScriptHook(args)
	
	--we assume that if there is a burmecian flag, the burmecian race is installed
	if liu_itemExists("flagburmecian") then
		
		--go through all of the possible variations this spawner can produce
		for _, variation in pairs(args) do
			
			--look at the scripted tags for the variation
			for __, tag in pairs(variation.scriptedTargetTags) do
			
				--if the tag is species:any, add burmecian
				if tag == "species:any" then
				
					--don't put burmecian in the list twice
					if tableContains( variation.npcSpeciesOptions, "burmecian" ) == false then
					
						table.insert( variation.npcSpeciesOptions, "burmecian" )
						--variation.npcSpeciesOptions = { "burmecian" }
					
					end
					
				end
			
				--the useVariantIfRaceInstalled is intended for spawner variants that only use the specific race
			
				--if the tag is useVariantIfRaceInstalled:burmecian, adjust the variant
				if tag == "useVariantIfRaceInstalled:burmecian" then
				
					--don't put burmecian in the list twice
					if tableContains( variation.npcSpeciesOptions, "burmecian" ) == false then
					
						--table.insert( variation.npcSpeciesOptions, "burmecian" )
						
						--swap out "notInstalled" for "burmecian" so the spawner has a valid race to use
						variation.npcSpeciesOptions = { "burmecian" }
					
					end
					
				end
			
			end
			
		end
		
	end
	
	return args
end

--expected value for args is one variation object from the possibleVariations list
function selectedVariationScriptHook(args)

	--this function is intended to be called when you want to make changes to one particular variation of NPC, regardless of what its final parameters may be
	--example: adding a weapon or hat for the NPC regardless of what race it might be
	--at this stage we don't know the specific details of the NPC yet, only the category it will choose traits from
		
	--run the (original or modified by someone else) script hook chain for this func
	args = oldSelectedVariationScriptHook(args)
	
		--make any changes to the specific variation here
	
	return args
end

function finalResultScriptHook(args)

	--this function is intended to be called when you want to make fine-tuned changes to an NPC before spawning it
	--example: change the crew member graduation types for neki to the neki-specific crew types
	--at this stage we have the details that will be used to spawn the NPC and we can adjust special exception cases
	
	--expected format for args: { fnpcSpecies, fnpcType, fnpcParameter, fnpcSeed }
	
	--run the (original or modified by someone else) script hook chain for this func
	args = oldFinalResultScriptHook(args)

	--if we are spawning a post office employee
	if args.fnpcType == "lofty_irisil_hylotlpostoffice" then
	
		--and it's a burmecian
		if args.fnpcSpecies == "burmecian" then
		
			--nil params, load defaults
			if args.fnpcParameter == nil then
				args.fnpcParameter = root.assetJson("/npcs/dungeon/hylotloceancity/lofty_irisil_hylotlpostoffice.npctype")
			end
			
			--plug in the script config from the hylotl post office template
			args.fnpcParameter.scriptConfig = root.assetJson("/npcs/dungeon/hylotloceancity/lofty_irisil_hylotlpostoffice.npctype").scriptConfig
			
			--patch outfit changes into the .npctype file
			
			--allow burmecians to promote to soldier
			table.insert(args.fnpcParameter.scriptConfig.questGenerator.graduation.nextNpcType, {0.5, "crewmember"})
		end
		
	end
	
	return args
end

function init()

	if oldInit ~= nil then
		oldInit()
	end
	
end

function update(dt)

	if oldUpdate ~= nil then
		oldUpdate(dt)
	end
	
end

function uninit()
	
	if oldUninit ~= nil then
		oldUninit()
	end
	
end