function init()
end

function update(dt)
  --yoimk
  local timeofDay = world.timeOfDay()

  --day
  if timeofDay <= 0.5 then
    object.setOutputNodeLevel(0, false)
	
  --night
  else
    object.setOutputNodeLevel(0, true)
  end
  
end