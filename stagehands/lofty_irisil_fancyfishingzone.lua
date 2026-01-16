require "/scripts/stagehandutil.lua"
require "/scripts/lofty_irisil_util.lua"

function init()
  self.containsProjectiles = {}
  self.messageType = "lofty_irisil_setFishingZoneParameters"
  self.messageArgs = root.assetJson(config.getParameter("config"))

  if type(self.messageArgs) ~= "table" then
    self.messageArgs = {self.messageArgs}
  end
end

function update(dt)
  local newProjectiles = broadcastAreaQuery({ includedTypes = {"projectile"} })
  local currentSet = {}
  for _, id in ipairs(newProjectiles) do
    currentSet[id] = true
    if not self.containsProjectiles[id] then
      liu_SEM(id, self.messageType, {id = entity.id(), args = self.messageArgs})
	  --sb.logInfo("sending " .. self.messageType .. " to " .. id)
    end
  end
  self.containsProjectiles = currentSet
end