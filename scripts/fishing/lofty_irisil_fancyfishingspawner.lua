require "/scripts/rect.lua"
require "/scripts/util.lua"

function FishingSpawner()
  local newSpawner = {}

  local spawnerConfig = false
  local spawnBias, lureType

  local function spawnPositionNear(pos)
    if not spawnerConfig then 
		sb.logInfo("No spawner config")
		return 
	end
	
    if not world.liquidAt(pos) then 
		return 
	end
	
    for i = 1, 10 do
      local spawnPosition = vec2.add(pos, vec2.withAngle(math.random() * 2 * math.pi, util.randomInRange(spawnerConfig.distanceRange)))
      if world.liquidAt(spawnPosition) and not world.lineTileCollision(pos, spawnPosition) then
        local spawnRect = rect.translate(spawnerConfig.checkRegion, spawnPosition)
        if not world.rectCollision(spawnRect) then
          local liquid = world.liquidAt(spawnRect)
          if liquid and liquid[2] >= spawnerConfig.liquidThreshold then
            return spawnPosition
          end
        end
      end
    end
  end

  local function getSpawnType(pos)
  --sb.logInfo("getSpawnType")
	--establish time of day
    local timeOfDay = world.timeOfDay()
    local day = timeOfDay >= spawnerConfig.dayRange[1] and timeOfDay <= spawnerConfig.dayRange[2]
    local night = timeOfDay >= spawnerConfig.nightRange[1] and timeOfDay <= spawnerConfig.nightRange[2]

	--check the liquid at the spawn position
	local liquidData = world.liquidAt(pos)
	
	--iterate through all configured liquid ids for the fishing zone
	local liquids = spawnerConfig.liquidIds
	for liquidIndex, liquidEntry in ipairs(liquids) do
	
		--sb.logInfo("Checking liquid entry: " .. liquidEntry.liquidId)
		--if the liquid we're submerged in has an entry for the zone
		if tostring(liquidData[1]) == tostring(liquidEntry.liquidId) then
		
			--iterate all eligible lure types for the zone
			for lureIndex, lureEntry in ipairs(liquidEntry.eligibleLureTypes) do
				
				--sb.logInfo("Checking lure entry: " .. lureEntry.lureType)
				--if the lure we're using has an entry for this liquid type
				if lureType == lureEntry.lureType then
				
					--sb.logInfo("Rolling rarity...")
					--roll a rarity
					local roll = math.random() + spawnBias
					for i, rarity in ipairs(lureEntry.rarities) do
						if roll <= rarity[1] then
						
							--sb.logInfo("Congratulations, it's a " .. rarity[2])
							--dig up the fish list for this rarity tier
							local pool = lureEntry.availableFish[rarity[2]]
							
							--if this rarity tier has fish
							if #pool > 0 then
								--sb.logInfo("Pool has stuff")
								--randomize the pool
								shuffle(pool)
								
								--iterate through the pool until we hit a valid result
								for j, spawnType in ipairs(pool) do
									if ((day and spawnType.day) or (night and spawnType.night)) then
										--sb.logInfo("Returning spawn type: " .. spawnType.monster)
										return spawnType.monster
									end
								end
							end
						end
					end
				end
			end
		end
	end
  end

  function newSpawner.getSpawn(pos)
    local spawnPosition = spawnPositionNear(pos)
    if spawnPosition then
      local spawnType = getSpawnType(spawnPosition)
      if spawnType then
        spawnBias = math.max(0, spawnBias - spawnerConfig.biasDropPerSpawn)
        return spawnType, spawnPosition
      end
    end
  end

  function newSpawner.reset()
    if spawnerConfig then
      spawnBias = spawnerConfig.initialBias
	end
  end
  
  function newSpawner.setParams(params)
    spawnerConfig = params
  end
  
  function newSpawner.setLureType(lt)
    lureType = lt
  end

  return newSpawner
end
