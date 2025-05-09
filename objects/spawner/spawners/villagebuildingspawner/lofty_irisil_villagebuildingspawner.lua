--	VILLAGE / MICRODUNGEON SPAWNER
--	LOFTY 2025-05-02
--
--	WTFPLV2
--
--	This spawner is intended to facilitate the un-abandonment of race mods
--	by allowing modders to dynamically insert microdungeons and villages into templates.
--
--  Checking for races at runtime allows me to just make content for all the races I enjoy,
--	without requiring subscribers to Project Irisil to also subscribe to the races I like.
--	If they have the race installed, good. It'll just work.
--	If they don't have the race installed, then the dynamic spawner won't spawn that race's stuff.
--
--	You are allowed to reuse redistribute etc this software
--	Make your universe a better place
--  Love you
--
------------------------------------------------------
--
--	BASIC OVERVIEW OF HOW THIS WORKS
--
--	When a player comes within range to activate the spawner, 
--	it will check to see if any other spawners have saved info for its dungeonId.
--
--	If info hasn't been saved to the planet yet, the spawner goes into hosting mode.
--	A spawner in hosting mode will determine the appropriate type of town to spawn.
--
--	A spawner that is not hosting will simply wait for a host to finish, 
--	then use whatever configuration parameters the host determined were appropriate.
--
--	This is set up this way to allow different types of towns to spawn
--	on the same planet without interfering with each other or mixing up requirements.
--	(As long as each town has its own dungeonId)
--
------------------------------------------------------
--
--	HOW TO SET UP THIS SPAWNER IN TILED:
--
--	In Tiled, place any 1x1 object (doesn't matter which one, I used a Wall-B)
--  Change the object field to lofty_irisil_villagebuildingspawner (or whatever you named your version)
--  Add a parameters field. Here is an example of the data to put in it:
--  	{ "sizeCategory" : "40x40" }
--
--  This example data sets up the following:
--
--		sizeCategory : This is used to make sure your templates fit in the allocated spaces for a structure
--
------------------------------------------------------
--
--	IF YOU WANT BIOME-LEVEL SPAWNING GRANULARITY,
--	YOU NEED TO ADD THE BIOME OBSERVER CRITTER TO YOUR BIOME'S SPAWN TABLES
--
--	Templates can be planet-based or biome-based.
--	If you want to restrict microdungeon spawning to a particular biome,
--	that biome needs to spawn lofty_irisil_biomeobserver critters.
--
------------------------------------------------------
--
--	HOW TO HOOK INTO THIS SPAWNER WITH A SCRIPT:
--
--		See lofty_irisil_dynamicvillages_lamia for an example script
--		Patch the object file and add your hotpatch script to the scripts list
--			or
--		Patch the tiled file and add your hotpatch script to the scripts list and/or make any other params changes you need to make
--
------------------------------------------------------

require "/scripts/util.lua"
require "/scripts/lofty_irisil_util.lua"
require "/scripts/lofty_irisil_util_biome.lua"

function init()
  object.setInteractive(false)
  animator.setAnimationState("switchState", "on")
end

---------

function raceAvailable(raceName)
	if raceName == "human" then return true end
	if raceName == "hylotl" then return true end
	if raceName == "apex" then return true end
	if raceName == "floran" then return true end
	if raceName == "novakid" then return true end
	if raceName == "glitch" then return true end
	if raceName == "avian" then return true end
	return false
end

hosting = false
pipeRegex = "[^\\|]+"
newlineRegex = "[^\\\n]+"
unrecoverableError = false

function tableWeightSorter(entryA, entryB)
	local weightA = 0
	local weightB = 0
	
	for k, v in pairs(entryA.dspVal) do
		if k == "weight" then
			weightA = v
			break
		end
	end
	
	for k, v in pairs(entryB.dspVal) do
		if k == "weight" then
			weightB = v
			break
		end
	end
	
	return weightA < weightB
end

function update(dt)

	if unrecoverableError then
		object.smash()
		return nil
	end

	--optional parameter: if player can see spawner, do nothing
	--sometimes this can create awkward situations if you /placedungeon in view distance
	--feel free to edit/patch offscreenOnly if you want the spawner to always fire

	if config.getParameter("offscreenOnly") == true then
		if world.isVisibleToPlayer(object.boundBox()) then
			return nil
		end
	end

	--the dynamic spawners expect buildings to fit within certain size templates - if one isn't provided, abort
	local sizeCategory = config.getParameter("sizeCategory", nil)
	if not sizeCategory then 
		yeek( "Dynamic village spawner error: No sizeCategory specified in spawner" )
		object.smash()
		return nil
	end

	--force the RNG to do stuff several times across several ticks to make sure it gets seeded properly
	if not storage.multiplayer then
		storage.multiplayer = 1
	else
		storage.multiplayer = storage.multiplayer + math.random(1,10)
	end

	if storage.multiplayer < 99 then
		return nil
	end
  
	-- BEGIN CODE THAT WE CAN ASSUME HAS INITIALIZED PROPERLY AND SEEDED RNG PROPERLY
  
	--get some useful info here once
	local myPos = object.toAbsolutePosition({0,0})
	local myXpos = myPos[1]
	local myYpos = myPos[2]
	local myDungeonId = ("" .. world.dungeonId({myXpos, myYpos}))
	
	--the type of village we're filling in the template with
	local villageTypeWorldFlag = world.getProperty("lofty_irisil_villageTypes")
  
	--if this is the first object to go live, it becomes the one that chooses the village type
	if villageTypeWorldFlag == nil then
		villageTypeWorldFlag = myDungeonId .. "|building"
		world.setProperty("lofty_irisil_villageTypes", villageTypeWorldFlag )
		hosting = true
	end
  
	--if the world property for village locations is already set
	if villageTypeWorldFlag ~= nil then
		--if we are not hosting
		if not hosting then
			--figure out the current status of the type selection process
			local currentStatus = "???"
			local flags = {}
			
			--split the world property into a list
			for i in string.gmatch(villageTypeWorldFlag, pipeRegex) do
				table.insert(flags, i)
			end
			
			--iterate over the list
			for i = 1, #flags, 1 do
				if (i % 2) == 1 then
					if ("" .. flags[i]) == myDungeonId then
						currentStatus = flags[i+1]
						break
					end
				end
			end
			
			--if we don't know the status of our dungeon id at this point,
			--we need to become a host
			if currentStatus == "???" then
				
				--update our current flags info locally
				villageTypeWorldFlag = villageTypeWorldFlag .. "|" .. myDungeonId .. "|building"
				
				--push to the server
				world.setProperty("lofty_irisil_villageTypes", villageTypeWorldFlag )
				
				hosting = true
			end
		end
	end
  
	--initialize these before we start jumping around, 
	--we'll need them regardless of whether or not we're hosting
	local chosenCategory = "???"
	local chosenConfig = "???"
	local dungeonConfig = "???"
  
	--if we are not hosting, we need to just sit and wait for the host to pick a village type
	--othwerise, start the selection process
	if hosting then
		
		--if we are hosting, we can evaluate the village type options we have available now
		--yeek("BEGIN VILLAGE SELECTION")
		
		-- STEP 1
		--yeek("STEP 1")
		-- we need to figure out what kind of npc village we are spawning
		-- dynamic villages are sorted by BIOME and not by planet type
		-- this is partially because biomes give much finer control
		-- and partially because modders have thoroughly mangled the planetary dungeon tables
		-- and also the planetary biome zones
		-- so depending on the mods used, we can't rely on a jungle planet to even be a jungle, etc
		
		-- very sad
		
		local myBiomes = liu_biome_getBiomesAt( object.toAbsolutePosition({-0.99,0.99}))
		if not myBiomes then 
			myBiomes = {}
		end
		
		--allow evaluation for 'any' biome
		myBiomes["any"] = true
		
		-- once we have our biome(s), attempt to figure out what we're able to spawn
		local validCategories = {}
		
		--grab the big list of biomes
		local biomeConfig = root.assetJson("/objects/spawner/spawners/villagebuildingspawner/dynamicVillages.config").biomeTypes
			
		--iterate biomes
		for worldBiomeKey, worldBiomeVal in pairs(myBiomes) do
			yeek("Evaluating for biome: " .. worldBiomeKey)
		
			--iterate through all biomes
			for biomeName, biomeCategories in pairs(biomeConfig) do
				
				--found a match
				if (biomeName == worldBiomeKey) then -- or (biomeName == "any") then
				
					--v will be a bunch of categories
					for biomeCategoryName, biomeCategoryDetails in pairs(biomeCategories) do
						
						--evaluate their rules
						
						-- RACE INSTALLATION
						
						--check to make sure all required races are installed
						local raceFailure = false
						if biomeCategoryDetails.requiredRaces then
							local raceIterator = 0
							for raceIterator, raceVal in ipairs(biomeCategoryDetails.requiredRaces) do
								if raceAvailable( raceVal ) == false then
									raceFailure = true
									break
								end
							end
						end
							
						--required races are unavailable, skip this category
						if raceFailure then 
							--yeek("raceFailure")
							goto continue_evalBiomes 
						end
						
						-- DESIGN TAGS
						
						--design tags are in unique config files for each template type
						--these config files are linked in the parameters of the spawner
						--which is slightly clunky but it's a lot easier for people to just
						--patch the config for the template
						
						--handle required tags
						local worldTemplateTags = root.assetJson(config.getParameter("designTagsConfig")).designTags
						local tagsFailure = false
						if biomeCategoryDetails.requiredDesignTags then
							if #biomeCategoryDetails.requiredDesignTags > 0 then
							local tagsIterator = 0
								for tagsIterator, tagsVal in ipairs(biomeCategoryDetails.requiredDesignTags) do
									local foundTag = false
									for wtagsIterator, wtagsVal in ipairs(worldTemplateTags) do
										if tagsVal == wtagsVal then
											foundTag = true
										end
									end
									if foundTag == false then
										--yeek("failed to find required design tag: " .. tagsVal)
										tagsFailure = true
										break
									end
								end
							end
						end
						
						--handle blacklisted tags
						if biomeCategoryDetails.blacklistedDesignTags then
							local tagsIterator = 0
							for tagsIterator, tagsVal in ipairs(biomeCategoryDetails.blacklistedDesignTags) do
								local foundTag = false
								for wtagsIterator, wtagsVal in ipairs(worldTemplateTags) do
									if tagsVal == wtagsVal then
										--yeek("found blacklisted design tag: " .. tagsVal)
										foundTag = true
									end
								end
								if foundTag == true then
									tagsFailure = true
									break
								end
							end
						end
						
						--failed to meet tag requirements
						if tagsFailure then 
							--yeek("tagsFailure")
							goto continue_evalBiomes 
						end
						
						-- PLANET TYPES
						local planetFailure = false
						local checkBlacklistedPlanets = true
						if biomeCategoryDetails.allowedPlanetTypes then
							--don't bother checking blacklisted planets if we're already using a whitelist
							if #biomeCategoryDetails.allowedPlanetTypes > 0 then
								
								checkBlacklistedPlanets = false
								
								local planetIterator = 0
								local foundPlanet = false
								for planetIterator, planetVal in ipairs(biomeCategoryDetails.allowedPlanetTypes) do
									if world.type() == planetVal then
										foundPlanet = true
										break
									end
								end
								
								if foundPlanet == false then
									planetFailure = true
								end
							end
						end
						
						if checkBlacklistedPlanets then
							if biomeCategoryDetails.disallowedPlanetTypes then
								local planetIterator = 0
								local foundPlanet = false
								for planetIterator, planetVal in ipairs(biomeCategoryDetails.disallowedPlanetTypes) do
									if world.type() == planetVal then
										foundPlanet = true
										break
									end
								end
								
								if foundPlanet == true then
									planetFailure = true
								end
							end
						end
						
						--failed to spawn on an appropriate planet
						if planetFailure then 
							--yeek("planetFailure")
							goto continue_evalBiomes 
						end
						
						-- BIOME TYPES
							
						local biomeFailure = false
						local checkBlacklistedBiomes = true
						if biomeCategoryDetails.allowedBiomeTypes then
							
							if #biomeCategoryDetails.allowedBiomeTypes > 0 then
							
								local biomeIterator = 0
								local foundBiome = false
								for biomeIterator, biomeVal in ipairs(biomeCategoryDetails.allowedBiomeTypes) do
									if worldBiomeKey == biomeVal then
										foundBiome = true
										break
									end
								end
								
								if foundBiome == false then
									biomeFailure = true
								end
							end
						end
						
						if biomeCategoryDetails.disallowedBiomeTypes then
							local biomeIterator = 0
							local foundBiome = false
							for biomeIterator, biomeVal in ipairs(biomeCategoryDetails.disallowedBiomeTypes) do
								if worldBiomeKey == biomeVal then
									foundBiome = true
									break
								end
							end
							
							if foundBiome == true then
								biomeFailure = true
							end
						end
						
						--failed to spawn in an appropriate biome
						if biomeFailure then 
							--yeek("planetFailure")
							goto continue_evalBiomes 
						end
							
						-- PASSED ALL RULE CHECKS
							
						--add the biome category config to our list of valid options
						table.insert(validCategories, { name = biomeCategoryName, details = biomeCategoryDetails.dungeonPartsConfigFile})
							
						--lua has a break but not a continue. how weird
						::continue_evalBiomes::
						
					end	
					
					--allow the loop to finish to support 'any' biome alongside specialized biome villages
					
				end
			
			end
			
		end
		
		if #validCategories <= 0 then
			unrecoverableError = true
			return nil
		end
	  
		-- STEP 2
		--yeek("STEP 2")
		--now that we've determined which config files are valid to pull from, choose one
		chosenCategory = validCategories[1].name;
		yeek("Host spawner chosen category: " .. chosenCategory)
		chosenConfig = validCategories[1].details;
		dungeonConfig = root.assetJson(chosenConfig)
		
		--set world properties with the chosen config
		local villageConfigWorldFlag = world.getProperty("lofty_irisil_villageConfigs")
		
		--hasn't been set yet, this one is easy
		if villageConfigWorldFlag == nil then
		
			--update world property
			world.setProperty("lofty_irisil_villageConfigs", myDungeonId .. "|" .. chosenConfig)
			
		--something has already populated this so we need to figure out if it's us or not
		else
		
			--figure out the current config for any dungeon ids stored in the world flags
			local currentConfig = "???"
			local flags = {}
			
			--split the world property into a list
			for i in string.gmatch(villageConfigWorldFlag, pipeRegex) do
				table.insert(flags, i)
			end
			
			--iterate over the list
			for i = 1, #flags, 1 do
				if (i % 2) == 1 then
					if ("" .. flags[i]) == myDungeonId then
						currentConfig = flags[i+1]
						break
					end
				end
			end
			
			--if we don't know the status of our dungeon id at this point,
			--it's safe to add our dungeon id to the list
			if currentConfig == "???" then
				world.setProperty("lofty_irisil_villageConfigs", villageConfigWorldFlag .. "|" .. myDungeonId .. "|" .. chosenConfig)
			end
			
		end
		
	end
	
	--if we don't know what our current config is, it's because we're not hosting
	--attempt to retrieve it
	if chosenConfig == "???" then
	
		--get world property
		local villageConfigWorldFlag = world.getProperty("lofty_irisil_villageConfigs")
		
		--if we're nil at this stage it's because we're not hosting and the host failed to place anything
		--this can also happen if the host object gets destroyed after failing to place and another dungeon spawns
		if villageConfigWorldFlag == nil then return nil end
		
		--some locals. copypasted code is in vogue
		local currentConfig = "???"
		local flags = {}
		
		--split the world property into a list
		for i in string.gmatch(villageConfigWorldFlag, pipeRegex) do
			table.insert(flags, i)
		end
		
		--iterate over the list
		for i = 1, #flags, 1 do
			if (i % 2) == 1 then
				if ("" .. flags[i]) == myDungeonId then
					currentConfig = flags[i+1]
					chosenConfig = currentConfig
					dungeonConfig = root.assetJson(chosenConfig)
					break
				end
			end
		end
		
		--at this point we should have a currentConfig
		--if not, exit, wait for the host to fix it
		if currentConfig == "???" then
			return nil
		end
	end
	
	-- STEP 3
	--yeek("STEP 3")
	--we should have a valid sizeCategory, so try to find a matching entry for the category
	--the plan here is to put all the valid entries into a pool, verify their rules, then spawn them by weight
	--the successfully spawned items will be placed into a world property so other scripts can see what's going on
	
	--list of valid options
	local dungeonSpawnPool = {}
	
	--get the items that have been spawned already
	local villageSpawnsWorldFlag = world.getProperty("lofty_irisil_villageSpawns");
	
	--nothing has spawned yet, initialize the spawned items "list"
	if villageSpawnsWorldFlag == nil then
		villageSpawnsWorldFlag = ""
	end
	
	--we basically just shove a bunch of data into lines in the following format:
	--
	--	A|B|C|D|E
	--
	--	A: the dungeon id
	--	B: the partName of the villageconfig
	--	C: the dungeonName of the microdungeon
	--	D: the x position
	--	E: the y position
	
	local lines = {}
	--split the world property into a list, separate by newlines
	for i in string.gmatch(villageSpawnsWorldFlag, newlineRegex) do
		table.insert(lines, i)
	end
	
	--iterate all of the size categories in the config
	for sizes, dungeonOptionsBySize in pairs( dungeonConfig ) do
	
		--found a match for our spawner
		if sizes == sizeCategory then
		
			--iterate all the options for the size category
			for partName, microdetails in pairs(dungeonOptionsBySize) do
			
				local okToSpawnThisItem = true
				
				--iterate the properties for the entry and check its rules
				for microdungeonProperty, microdungeonValue in pairs(microdetails) do
				
					--maximum spawn count for this item per village
					if microdungeonProperty == "maxSpawnCount" then
					
						--iterate the things we've spawned and verify we haven't hit max
						if microdungeonValue > 0 then
						
							--used to track how many we've spawned
							local numSpawned = 0
							--walk through the lines from our world value
							for lineIndex, lineValue in ipairs(lines) do
							
								--break into tokens separated by pipes
								local tokens = {}
								for i in string.gmatch(lineValue, pipeRegex) do
									table.insert(tokens,i)
								end
								
								--if dungeon id matches
								if tokens[1] == myDungeonId then
									--and partName matches
									if tokens[2] == partName then
										numSpawned = numSpawned + 1
									end
								end
							end
							
							--if we've hit the limit, don't use this item
							if numSpawned >= microdungeonValue then
								okToSpawnThisItem = false
							end
						else
							okToSpawnThisItem = false
						end
					
					end
					
					--handling parts we shouldn't mix together
					if microdungeonProperty == "doNotCombineWith" then
					
						--if the array is empty, skip it
						if #microdungeonValue > 0 then
						
							for noMixIndex, noMixValue in ipairs(microdungeonValue) do
							
								for lineIndex, lineValue in ipairs(lines) do
								
									--break into tokens separated by pipes
									local tokens = {}
									for i in string.gmatch(lineValue, pipeRegex) do
										table.insert(tokens,i)
									end
									
									--if dungeon id matches
									if tokens[1] == myDungeonId then
										--and partName matches
										if tokens[2] == noMixValue then
											okToSpawnThisItem = false
											--yeek(partName .. " not allowed to mix with " .. noMixValue)
											break
										end
										
									end
									
								end
								
							end
							
						end
					
					end
					
					--need one or more races installed for this particular house
					if microdungeonProperty == "requiredRaces" then
					
						if #microdungeonValue > 0 then
						
							for reqRaceIndex, reqRaceName in ipairs(microdungeonValue) do
							
								if raceAvailable( reqRaceName ) == false then
								
									okToSpawnThisItem = false
									--yeek(partName .. " requires race " .. reqRaceName)
									break
									
								end
							
							end
						
						end
					
					end
					
					--need one or more template design tags for this particular house
					if microdungeonProperty == "requiredDesignTags" then
					
						if #microdungeonValue > 0 then
						
							local worldTemplateTags = root.assetJson(config.getParameter("designTagsConfig")).designTags
							for reqTagIndex, reqTagName in ipairs(microdungeonValue) do
							
								local foundTag = false
								for tagIndex, tagValue in pairs(worldTemplateTags) do
								
									if tagValue == reqTagName then
										foundTag = true
										break
									end
									
								end
								
								if foundTag == false then
									yeek("missing required design tag: " .. reqTagName)
									okToSpawnThisItem = false
									break
								end
							
							end
						
						end
					
					end
					
					--disallow one or more template design tags for this particular house
					if microdungeonProperty == "blacklistedDesignTags" then
					
						if #microdungeonValue > 0 then
						
							local worldTemplateTags = root.assetJson(config.getParameter("designTagsConfig")).designTags
							for bTagIndex, bTagName in ipairs(microdungeonValue) do
							
								local foundTag = false
								for tagIndex, tagValue in pairs(worldTemplateTags) do
								
									if tagValue == bTagName then
										foundTag = true
										break
									end
									
								end
								
								if foundTag == true then
									--yeek("detected blacklisted design tag: " .. bTagName)
									okToSpawnThisItem = false
									break
								end
							
							end
						
						end
					
					end
					
					--planet whitelisting
					if microdungeonProperty == "allowedPlanetTypes" then
					
						if #microdungeonValue > 0 then
						
							local curPlanetType = world.type()
							local validPlanet = false
							
							for planetKey, planetVal in pairs(microdungeonValue) do
							
								if planetVal == curPlanetType then
								
									validPlanet = true
									break
									
								end
							
							end
							
							if validPlanet == false then
								--yeek("failed to find current planet type in whitelist")
								okToSpawnThisItem = false
							end
						
						end
					
					end
					
					--planet blacklisting
					if microdungeonProperty == "disallowedPlanetTypes" then
					
						if #microdungeonValue > 0 then
						
							local curPlanetType = world.type()
							local validPlanet = true
							
							for planetKey, planetVal in pairs(microdungeonValue) do
							
								if planetVal == curPlanetType then
								
									validPlanet = false
									break
									
								end
							
							end
							
							if validPlanet == false then
								--yeek("planet type is blacklisted")
								okToSpawnThisItem = false
							end
						
						end
					
					end
					
					--biome whitelisting
					if microdungeonProperty == "allowedBiomeTypes" then
					
						if #microdungeonValue > 0 then
						
							--get biomes for our position
							local biomes = liu_biome_getBiomesAt( object.toAbsolutePosition({-0.99,0.99}))
							if biomes == nil then 
								biomes = {}
							end
							biomes["any"] = true

							local foundgoodbiome = false
													
							--check all of the allowed biomes, if we find any of them, we're good to spawn
							for reqbiomekey, reqbiomeval in pairs(microdungeonValue) do
							
								--against known current biomes
								for mdbkey, mdbval in pairs(biomes) do
								
									if mdbkey == reqbiomeval then
										foundgoodbiome = true
										break
									end
							
								end
								
							end
							
							--didn't find any of the allowed biomes in the biomes list for this area
							if foundgoodbiome == false then
								okToSpawnThisItem = false
							end
						
						end
					
					end
					
					--biome blacklisting
					if microdungeonProperty == "disallowedBiomeTypes" then
					
						if #microdungeonValue > 0 then
						
							--get biomes for our position
							local biomes = liu_biome_getBiomesAt( object.toAbsolutePosition({-0.99,0.99}))
							if biomes == nil then 
								biomes = {}
							end
							biomes["any"] = true
													
							--check each blocked biome
							for reqbiomekey, reqbiomeval in pairs(microdungeonValue) do
							
								local foundreqbiome = false
							
								--against known current biomes
								for mdbkey, mdbval in pairs(biomes) do
								
									if mdbkey == reqbiomeval then
										foundreqbiome = true
										break
									end
							
								end
								
								--a blacklisted biome was found, disallow spawn
								if foundreqbiome == true then
									okToSpawnThisItem = false
								end
							
							end
						
						end
					
					end
					
					--don't spawn two copies of the same microdungeon too close to each other
					if microdungeonProperty == "maxRadius" then
					
						--verify positive radius
						if microdungeonValue > 0 then
						
							--walk through the lines from our world value
							for lineIndex, lineValue in ipairs(lines) do
							
								--break into tokens separated by pipes
								local tokens = {}
								for i in string.gmatch(lineValue, pipeRegex) do
									table.insert(tokens,i)
								end
								
								--if dungeon id matches
								if tokens[1] == myDungeonId then
									--and partName matches
									if tokens[2] == partName then
										--and distance too small
										local spawnedPos = { tokens[4], tokens[5] }
										if world.magnitude(spawnedPos, myPos) < microdungeonValue then
											okToSpawnThisItem = false
											break
										end
									end
								end
							end
						else
							okToSpawnThisItem = false
						end
					
					end
				
				end
				
				--no failures, put this in the pool of things to pick from
				if okToSpawnThisItem then
					local dspEntry = {}
					dspEntry["dspName"] = partName
					dspEntry["dspVal"] = microdetails
					table.insert(dungeonSpawnPool, dspEntry )
				end
			
			end
			
		end
		
	end
  
	--if for some reason we don't find anything, throw an error so someone can fix it
	if #dungeonSpawnPool <= 0 then
		yeek("Unable to find an appropriately-sized dungeon to spawn for dynamic village!")
		yeek("Dynamic village category is: " .. chosenCategory )
		if chosenCategory == "???" then
			yeek("??? as a category is not an error. The category is only needed if this spawner is a host")
		end
		yeek("sizeCategory is: " .. sizeCategory)
		yeek("Relevant config file is: " .. chosenConfig)
		object.smash()
		return nil
	end
	
	-- STEP 4
	--yeek("STEP 4")
	--now that we've narrowed down the village category, size category, and valid spawning options
	--we can finally select the microdungeon we want and place it
	
	--sort microdungeons by weight to make sure anything with weight <= 0 is only selected as a last resort
	table.sort(dungeonSpawnPool, tableWeightSorter)
	
	--evaluate weights here
	local totalWeights = 0.0
	for twName, twVal in pairs(dungeonSpawnPool) do
		local entryWeight = 0
		for extrKey, extrVal in pairs(twVal.dspVal) do
			if extrKey == "weight" then
				entryWeight = extrVal
				break
			end
		end
		
		yeek("Evaluating weight: " .. twVal.dspName .. " (" .. tostring(entryWeight) .. ")")
		--don't add negative weights
		if entryWeight > 0 then
			totalWeights = totalWeights + entryWeight
		end
	end
	
	local randFloat = math.random() --between 0 and 1, don't allow 0
	local emergencyExit = 0
	while (randFloat == 0.0) or (randFloat == 1.0) do
		randFloat = math.random()
		emergencyExit = emergencyExit + 1
		if emergencyExit > 10 then
			--should never happen but you know whatever
			return nil
		end
	end
	
	randFloat = randFloat * totalWeights
	--yeek("chosen value: " .. tostring(randFloat))
	
	--local spawnIndex = math.random(#dungeonSpawnPool)
	local spawnIndex = 0
	local accumulatedWeight = 0.0
	local accumulatedIndex = 1
	for twName, twVal in pairs(dungeonSpawnPool) do
	
		for extrKey, extrVal in pairs(twVal.dspVal) do
			if extrKey == "weight" then
				accumulatedWeight = accumulatedWeight + extrVal
				break
			end
		end
	
		if randFloat < accumulatedWeight then
			spawnIndex = accumulatedIndex
		else
			accumulatedIndex = accumulatedIndex + 1
		end
	end
	
	--yeek("totalWeight = " .. totalWeights)
	--yeek("accumulatedWeight = " .. accumulatedWeight)
	--yeek("accumulatedIndex = " .. accumulatedIndex)
	
	--choose an item
	if spawnIndex <= 0 then
		spawnIndex = math.random(#dungeonSpawnPool)
		--yeek("Something went wrong attempting to pick a weighted item from the spawn pool")
	end
	
	local dungeonData = dungeonSpawnPool[spawnIndex]
	local dungeonParameters = {}
	local partName = "???"
	
	--slightly awkward because there should only be one pair but whatever
	partName = dungeonData.dspName
	dungeonParameters = dungeonData.dspVal
	local dungeonName = dungeonParameters.dungeonName
	
	--spawn the dungeon and smash the spawner
	local finalPos = object.toAbsolutePosition({(1.01),0.99})
	local finalXPos = finalPos[1]
	local finalYPos = finalPos[2]
	world.placeDungeon(dungeonName, {finalXPos, finalYPos});
	
	--update the world properties now that we've spawned something
	if villageSpawnsWorldFlag == "" then
		villageSpawnsWorldFlag = myDungeonId .. "|" .. partName .. "|" .. dungeonName .. "|" .. finalXPos .. "|" .. finalYPos
	else
		villageSpawnsWorldFlag = villageSpawnsWorldFlag .. "\n" .. myDungeonId .. "|" .. partName .. "|" .. dungeonName .. "|" .. finalXPos .. "|" .. finalYPos
	end
	world.setProperty("lofty_irisil_villageSpawns", villageSpawnsWorldFlag)
	
	--destroy spawner
	object.smash()
  
end
