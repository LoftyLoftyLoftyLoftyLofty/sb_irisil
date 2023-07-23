require "/scripts/util.lua"

function init()
	self.invisible = false
	if config.getParameter("invisible") == true then
		self.invisible = true
	end
end

function update(dt)
  --yoimk
  local timeofDay = world.timeOfDay()

  --day
  if timeofDay <= 0.5 then
    object.setOutputNodeLevel(0, false)
	
	if self.invisible == false then
		animator.setAnimationState("switchState", "day")
	else
		animator.setAnimationState("switchState", "invisible")
	end
	
  --night
  else
    object.setOutputNodeLevel(0, true)
	
	if self.invisible == false then
		animator.setAnimationState("switchState", "night")
	else
		animator.setAnimationState("switchState", "invisible")
	end
  end
  
end