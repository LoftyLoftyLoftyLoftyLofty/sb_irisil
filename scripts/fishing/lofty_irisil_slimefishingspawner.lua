require "/scripts/rect.lua"
require "/scripts/util.lua"

function FishingSpawner()
  local newSpawner = {}

  local spawnerConfig = root.assetJson("/scripts/fishing/lofty_irisil_slimefishingspawner.config")
  local spawnBias = spawnerConfig.initialBias

  local function spawnPositionNear(pos)
    if not world.liquidAt(pos) then return end
    for i = 1, 10 do
      local spawnPosition = vec2.add(pos, vec2.withAngle(math.random() * 2 * math.pi, util.randomInRange(spawnerConfig.distanceRange)))
      if world.liquidAt(spawnPosition) and spawnerConfig.allowedInstances[world.type()] and not world.lineTileCollision(pos, spawnPosition) then
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
    local shallow = true
	local deep = false
	
	local posDepth = spawnerConfig.allowedInstances[world.type()].oceanLevel - pos[2]
    if posDepth < spawnerConfig.minDepth then
      return
    elseif posDepth >= spawnerConfig.deepDepth then
      shallow, deep = false, true
    else
      shallow, deep = true, false
    end

    local timeOfDay = world.timeOfDay()
    local day = timeOfDay >= spawnerConfig.dayRange[1] and timeOfDay <= spawnerConfig.dayRange[2]
    local night = timeOfDay >= spawnerConfig.nightRange[1] and timeOfDay <= spawnerConfig.nightRange[2]

    local biome = world.type()
    if not spawnerConfig.pools[biome] then return end

    local roll = math.random() + spawnBias
    for i, rarity in ipairs(spawnerConfig.rarities) do
      if roll <= rarity[1] then
        local pool = spawnerConfig.pools[biome][rarity[2]]
        shuffle(pool)
        for j, spawnType in ipairs(pool) do
          if ((shallow and spawnType.shallow) or (deep and spawnType.deep)) and
              ((day and spawnType.day) or (night and spawnType.night)) then

            return spawnType.monster
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
    spawnBias = spawnerConfig.initialBias
  end

  return newSpawner
end
