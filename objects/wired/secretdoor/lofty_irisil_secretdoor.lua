-- this is the same as the regular secret door script except it doesn't set output nodes if there aren't any, which is relevant for 1x1 secret doors
require "/scripts/vec2.lua"

function init()
  self.doorDirection = config.getParameter("doorDirection", "vertical")
  self.doorRate = config.getParameter("doorRate", 0)

  if not storage.doorStages then
    setupMaterialSpaces()
  end

  object.setMaterialSpaces(storage.state and {} or storage.doorStages[#storage.doorStages])
  animator.setAnimationState("doorState", storage.state and "open" or "closed")

  self.doorStageTimer = 0
  
  if storage.locked == nil then
    storage.locked = config.getParameter("locked", false)
  end

  object.setInteractive(not storage.locked and not object.isInputNodeConnected(0) and config.getParameter("interactive", true))
  if object.outputNodeCount() > 0 then
    object.setOutputNodeLevel(0, storage.state)
  end

  message.setHandler("openDoor", function() openDoor() end)
  message.setHandler("closeDoor", function() closeDoor() end)
end

function update(dt)
  if self.doorStage then
    self.doorStageTimer = self.doorStageTimer - dt
    if self.doorStageTimer <= 0 then
      advanceDoorStage()
      self.doorStageTimer = self.doorRate
    end
  elseif object.isInputNodeConnected(0) and object.getInputNodeLevel(0) ~= storage.state then
    triggerSwitch()
  end
end

function onInteraction(args)
  if not storage.locked then
    triggerSwitch()
  end
end

function triggerSwitch()
  if not self.doorStage then
    storage.state = not storage.state
	if object.outputNodeCount() > 0 then
      object.setOutputNodeLevel(0, storage.state)
	end
    animator.playSound(storage.state and "open" or "close")
    if self.doorRate > 0 then
      self.doorStage = storage.state and #storage.doorStages or 0
      self.doorStageTimer = self.doorRate
    else
      object.setMaterialSpaces(storage.state and {} or storage.doorStages[#storage.doorStages])
    end
  end
end

function advanceDoorStage()
  if storage.state then
    self.doorStage = self.doorStage - 1
  else
    self.doorStage = self.doorStage + 1
  end

  if self.doorStage == 0 or self.doorStage >= #storage.doorStages then
    self.doorStage = nil
    object.setMaterialSpaces(storage.state and {} or storage.doorStages[#storage.doorStages])
    animator.setAnimationState("doorState", storage.state and "open" or "closed")
  else
    object.setMaterialSpaces(storage.doorStages[self.doorStage])
    animator.setAnimationState("doorState", "open")
  end
end

function setupMaterialSpaces()
  local spaces = object.spaces()

  local pos = entity.position()
  local materials = {}
  for i, space in ipairs(spaces) do
    local mat = world.material(vec2.add(pos, space), "background")
    if not mat then
      mat = "metamaterial:empty"
    end
    table.insert(materials, mat)
  end

  storage.doorStages = {}
  local di = self.doorDirection == "vertical" and 2 or 1
  local min = 1000
  local max = -1000
  for i, space in ipairs(spaces) do
    min = math.min(min, space[di])
    max = math.max(max, space[di])
  end

  repeat
    local doorStage = {}
    for i, space in ipairs(spaces) do
      if space[di] <= min or space[di] >= max then
        table.insert(doorStage, {space, materials[i]})
      end
    end
    table.insert(storage.doorStages, doorStage)

    min = min + 1
    max = max - 1
  until min > max
end

function onNodeConnectionChange()
  object.setInteractive(not storage.locked and not object.isInputNodeConnected(0) and config.getParameter("interactive", true))
end

function openDoor()
  storage.locked = false
  if not storage.state and not self.doorStage then
    triggerSwitch()
  end
end

function closeDoor()
  if storage.state and not self.doorStage then
    triggerSwitch()
  end
end
