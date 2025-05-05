--This is how big each map tile for biome checking is
--200x200 is about half the size of a hylotl ocean city
--Smaller = finer detail, but bigger data storage

--This should create a reasonable probability of biome checks within a grid to accurately determine
--what is in a general area, and be able to reasonably-reliably (it will never be 100%) accurately
--apply biome restrictions for spawning or blocking microdungeons placed into village templates

--This grid is populated for each world you visit as you explore,
--so if you choose to make this number smaller, the grid will take up more space
GRID_SIZE_IN_TILES = 200

require "/scripts/lofty_irisil_util.lua"

function liu_biome_initBiomeGrid()
	--this system splits planets into a grid of chunks that are 200 tiles wide and 200 tiles tall
	--if the planet width is 6000 (large planet) this means 30 wide
	--if the planet height is 3000 (large planet) this means 15 high
	--this means that on a vanilla planet we ultimately have 450 cells to populate data for
	
	--...but we won't be using most of them, on most planets
	
	local bigScaryGrid = {}
	
	local worldSize = world.size()
	local xCells = math.ceil(worldSize[1] / GRID_SIZE_IN_TILES) - 1
	local yCells = math.ceil(worldSize[2] / GRID_SIZE_IN_TILES) - 1
	
	for x = 0, xCells do
	
		local col = {}
		local yCell = {}
		for y = 0, yCells do
			table.insert(col, yCell)
		end
		table.insert(bigScaryGrid, col)
	end
	
	world.setProperty("lofty_irisil_worldBiomeZones", bigScaryGrid)
	return bigScaryGrid
end

function liu_biome_getBiomesAt(position)
	local worldBiomeZones = world.getProperty("lofty_irisil_worldBiomeZones")
	if worldBiomeZones == nil then
		worldBiomeZones = liu_biome_initBiomeGrid()
	end
	local xIndex = math.ceil(position[1] / GRID_SIZE_IN_TILES)
	local yIndex = math.ceil(position[2] / GRID_SIZE_IN_TILES)
	return worldBiomeZones[xIndex][yIndex]
end

function liu_biome_saveBiomeAt(biomeType, position)
	
	if biomeType == nil then return nil end
	
	--sanitize incoming x position
	position = world.xwrap(position)
	
	--attempt to retrieve the planet's biome grid
	local worldBiomeZones = world.getProperty("lofty_irisil_worldBiomeZones")
	
	--if we don't have a biome grid for the planet yet, initialize one
	if worldBiomeZones == nil then
		worldBiomeZones = liu_biome_initBiomeGrid()
	end
	
	--this shouldn't happen, but if it does, give up and let the next critter populate the cell
	if worldBiomeZones == nil then return nil end
	if (#worldBiomeZones) < 1 then return nil end
	
	--translate world position to a grid cell
	local xIndex = math.ceil(position[1] / GRID_SIZE_IN_TILES)
	local yIndex = math.ceil(position[2] / GRID_SIZE_IN_TILES)
	
	--sanitize weird one-offs
	if xIndex > (#worldBiomeZones) then xIndex = 1 end
	if xIndex < 1 then xIndex = (#worldBiomeZones) end
	
	if yIndex > (#(worldBiomeZones[1])) then yIndex = (#(worldBiomeZones[1])) end
	if yIndex < 1 then yIndex = 1 end
	
	--get the cell we care about
	if xIndex and yIndex then
	
		--yeek("xy: " .. tostring(xIndex) .. " / " .. tostring(yIndex))
		local gridCell = worldBiomeZones[xIndex][yIndex]
		--yeek("grid: " .. tostring(gridCell))
		gridCell[biomeType] = true
		worldBiomeZones[xIndex][yIndex] = gridCell
		world.setProperty("lofty_irisil_worldBiomeZones", worldBiomeZones)
	end
end