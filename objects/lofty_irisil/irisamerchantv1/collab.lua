require "/scripts/lofty_irisil_util.lua"

local oldInit = init
local oldUninit = uninit
local oldUpdate = update
local oldOnInteraction = onInteraction

function init()
	--this is mostly cargo cult programming, idk if i need this here
	if oldInit ~= nil then
		oldInit()
	end
	
end

function onInteraction(args)

	--this is mostly cargo cult programming, idk if i need this here
	if oldOnInteraction ~= nil then
		oldOnInteraction(args)
	end
	
	--get the default interact data
	local interactData = config.getParameter("interactData")
	
	--set up empty object i guess
	interactData.recipes = {}
	
	--util func for making recipes
	local addRecipes = 
		function(items, category)
			for i, item in ipairs(items) do
			  interactData.recipes[#interactData.recipes + 1] = generateRecipe(item, category)
			end
		end
	  
	--load default recipes
	local inv = config.getParameter("storeInventory")
	local defaultInv = root.assetJson("/objects/lofty_irisil/irisamerchantv1/irisamerchantv1.object").storeInventory
	
	--no store inventory found, this may be a legacy merchant someone placed, update it
	if inv == nil then
		inv = defaultInv
	else
		--we found a store inventory, does it match what we expect?
		
		--verify we have a default to load from
		if defaultInv ~= nil then
			--this isn't a perfect solution, but we basically dump both tables to string and verify equality
			if table.concat(inv) ~= table.concat(defaultInv) then
				inv = defaultInv
			end
		end
	end
	
	--if we found something to use, try to use it
	if inv ~= nil then
		--add default recipes
		if #inv > 0 then
			for i, name in ipairs(inv) do
				interactData.recipes[#interactData.recipes + 1] = name
			end
		end
	end
	
	--check for all of the necessary components from betabound we will need to make the codex
	if liu_itemExists("sb_meatballs") then
	
		--add recipe for it to the UI
		addRecipes( { "lofty_irisil_silvergoestothestore-codex" } , "lofty_irisil_irishop_codices")
	end
	
	--interactData.recipes = nil
	
	return { "OpenCraftingInterface", interactData }
end

--probably not the right name for this func but whatever
function generateRecipe(item, category)

	--Silver Goes to the Store Codex
	if item == "lofty_irisil_silvergoestothestore-codex" then
		return 
		{
			input = 
			{
				{ item = "lofty_irisileye", count = 1 },
				{ item = "sb_meatballs", count = 1 },
				{ item = "bookpiles", count = 1 }
			},
			output = item,
			groups = { category }
		}
	end
	
end

function update(dt)

	--this is mostly cargo cult programming, idk if i need this here
	if oldUpdate ~= nil then
		oldUpdate(dt)
	end
	
end

function uninit()
	
	--this is mostly cargo cult programming, idk if i need this here
	if oldUninit ~= nil then
		oldUninit()
	end
	
end