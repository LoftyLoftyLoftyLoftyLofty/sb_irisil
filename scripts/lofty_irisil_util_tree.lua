function liu_stemAndFoliageFromDescription(desc)
	--  break the description of the plant into parts
	--  trees/vines usually have a description that says: "x with y" (some vines do not conform to this)
	--  where x is the stem and y is the foliage
	--  smaller decorative plants won't usually have this style of description
	
	local stem = "none"
	local foliage = "none"
	if desc then
		local count = 0
		local foundWith = false
		for i in string.gmatch(desc, "%S+") do
			count = count + 1
			if count == 1 then
				stem = i
			end
			if count == 2 then
				if i == "with" then
					foundWith = true
				end
			end
			if count == 3 then
				foliage = i
			end
		end
		if count == 3 and foundWith == true then
			return { stem, foliage }
		end
	end
	
	if stem == "darkrock" then 
		return { "darkrock", "none" }
	end
	
	return nil
end

function liu_scanForClimbableTrees( position, radius, logInfo )

	local result = {}
	
	--  Scan for all types of plants
	local q = world.entityQuery(position, radius, { includedTypes = { "plant" } }) --, "plantDrop"
	
	--  Found something/anything
	if q then
	
		--  iterate all results
		for k, v in pairs(q) do
		
			--  filter for just trees
			if world.entityType(v) == "plant" then
			
				--  if this returns a non-nil value, it means it is probably either a tree or a vine
				local stemAndFoliage = liu_stemAndFoliageFromDescription(world.entityDescription(v))
				
				--  so if the entry is probably a tree, start measuring it
				if stemAndFoliage then
				
					--  extract info
					local stem = stemAndFoliage[1]
					local foliage = stemAndFoliage[2]
					
					--  get the position of the tree
					local treePos = world.entityPosition(v)
					
					--  we're able to use world.objectSpaces on trees
					local obj = world.objectSpaces(v)
					local treeHeight = 0
					local stumpWidth = 0
					
					--  this function only scans for trees, so if we detect vines, exclude them
					local vine = false
					
					--  iterate all the spaces
					if obj then 
						local lowY = 9999
						local highY = -9999
						for sk, sv in pairs(obj) do
						
							--  order here is important
							
							--  increment stump width if we're on a "lowest" tile
							if sv[2] == lowY then
								stumpWidth = stumpWidth + 1
							end
						
							--  reset stump width if we find lower tiles
							if sv[2] < lowY then
								lowY = sv[2]
								stumpWidth = 1
							end
							
							--  set stump max height if we find higher tiles
							if sv[2] > highY then
								highY = sv[2]
							end
						end
						--  measure total tree height - unfortunately this doesn't give full info we need
						treeHeight = highY - lowY
						
						--  trees won't ever have negative Y value spaces, but vines will
						if lowY < 0 then
							vine = true
						end
						
						--  this covers a weird edge case where a player has chopped most of a vine but not all of it
						if lowY == highY then
							vine = true
						end
					end
					
					--  assume that we want at least 10 blocks of tree away from the top
					treeHeight = treeHeight - 10
					
					if (not vine) and (treeHeight >0)  then
					
						--  debug the trunk, which is what we care about for now
						local ll = vec2.add(treePos, { ( -1 * ( stumpWidth / 2) ) + 1, 0 } )
						local lr = vec2.add(ll, {stumpWidth,0})
						local ur = vec2.add(ll, {stumpWidth,treeHeight})
						local ul = vec2.add(ll, {0,treeHeight})
						
						local treePoly = { ll, lr, ur, ul }
						world.debugPoly( treePoly, { 255, 0, 0, 255 } )
						
						--  attempt load the root asset for the stem to get offsets
						local averageTrunkXOffset = 0
						local averageTrunkYOffset = 0
						local averageMiddleXOffset = 0
						local averageMiddleYOffset = 0
						local minimumNumberOfMiddleSegments = 0
						local maximumNumberOfMiddleSegments = 0
						local stemDir = root.treeStemDirectory( stem )
						if stemDir then
							local rootStem = root.assetJson( stemDir .. stem .. ".modularstem" )
							if rootStem then
							
								--  tree trunk offsets will usually be within 1 or 2 pixels of a center
								--  so if we get the average of all the trunk bases
								--  it will usually give a sane result
						
								if rootStem.base then
									local cumulativeXOffset = 0
									local cumulativeYOffset = 0
									local baseCount = 0
									for k_b, v_b in pairs( rootStem.base ) do
										cumulativeXOffset = cumulativeXOffset + v_b.attachment.x + v_b.attachment.bx
										cumulativeYOffset = cumulativeYOffset + v_b.attachment.y + v_b.attachment.by
										baseCount = baseCount + 1
									end
									if baseCount > 0 then
										--  this is measured in pixels, so we convert to tiles here
										averageTrunkXOffset = (cumulativeXOffset / baseCount) / 8
										averageTrunkYOffset = (cumulativeYOffset / baseCount) / 8
									end
								end
								
								--  we also want to determine a sane minimum and maximum Y climb range
								
								--  as a minimum value, we get the vertical offset average of the bases (we get this above)
								--  the maximum value is the vertical offset average of the middles * minimum # of middle segments
								
								if rootStem.middle then
									local cumulativeXOffset = 0
									local cumulativeYOffset = 0
									local middleCount = 0
									for k_m, v_m in pairs( rootStem.middle ) do
										cumulativeXOffset = cumulativeXOffset + v_m.attachment.x + v_m.attachment.bx
										cumulativeYOffset = cumulativeYOffset + v_m.attachment.y + v_m.attachment.by
										middleCount = middleCount + 1
									end
									if middleCount > 0 then
										averageMiddleXOffset = (cumulativeXOffset / middleCount) / 8
										averageMiddleYOffset = (cumulativeYOffset / middleCount) / 8
									end
								end
								
								if rootStem.middleMinSize then
									minimumNumberOfMiddleSegments = rootStem.middleMinSize
									maximumNumberOfMiddleSegments = rootStem.middleMaxSize
								end
							end
						end
						
						--  use the current height of the tree to figure out a reasomable estimate of midsegments
						local verticalStitching = averageTrunkYOffset
						local reasonableEstimateOfMiddleSegments = 0
						while (reasonableEstimateOfMiddleSegments < maximumNumberOfMiddleSegments) and (verticalStitching < treeHeight) do
							reasonableEstimateOfMiddleSegments = reasonableEstimateOfMiddleSegments + 1
							verticalStitching = verticalStitching + averageMiddleYOffset
						end
						
						local reasonableCenterOffset = averageTrunkXOffset + averageMiddleXOffset 
						local maxClimbHeight = averageMiddleYOffset * reasonableEstimateOfMiddleSegments
						
						ll = vec2.add(treePos, {reasonableCenterOffset ,averageTrunkYOffset})
						lr = vec2.add(ll, {stumpWidth - (stumpWidth / 2) ,0})
						ur = vec2.add(ll, {stumpWidth - (stumpWidth / 2) + (averageMiddleXOffset * minimumNumberOfMiddleSegments),maxClimbHeight})
						ul = vec2.add(ll, {(averageMiddleXOffset * minimumNumberOfMiddleSegments),maxClimbHeight})
						
						local climbablePoly = { ll, lr, ur, ul }
						world.debugPoly( climbablePoly, { 0, 255, 0, 255 } )
						
						if logInfo then
							sb.logInfo("pushing result")
						end
						
						result[v] = 
						{ 
							position = treePos, 
							stemType = stem, 
							foliageType = foliage,
							polyTree = treePoly,
							polyClimbable = climbablePoly
						}
					end
				end
			end
		end
	end
	
	return result
end