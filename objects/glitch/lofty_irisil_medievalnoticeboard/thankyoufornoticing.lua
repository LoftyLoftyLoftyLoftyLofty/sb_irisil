function init()
  animator.setAnimationState("noticeState", "noNotice")
end

function update(dt) 
  updateAnimationState()
end

function updateAnimationState()
  local containerItems = world.containerItems(entity.id())
  
  local containsNotice = false
  
  if containerItems then
	for _, item in pairs(containerItems) do
	  local itemType = root.itemType(item.name)
	  
	  --If we have no configured whitelist, check if there is any type codex in the container
	  if itemType == "codex" and not config.getParameter("codexWhitelist") then
		containsNotice = true
		
	  --If we have a configured whitelist, check if the item in the container matches any of the configured codex items
	  elseif config.getParameter("codexWhitelist") then
		local acceptedCodices = config.getParameter("codexWhitelist")
		for _, codex in ipairs(acceptedCodices) do
		  if item.name == codex then
			containsNotice = true
		  end
		end
	  end
	end
  end
  
  --Update the object's animation state
  if containsNotice then
	animator.setAnimationState("noticeState", "hasNotice")
  else
	animator.setAnimationState("noticeState", "noNotice")
  end
end
