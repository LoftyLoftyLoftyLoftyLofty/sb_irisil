function init()
  animator.setAnimationState("movement", "idle")
end

function update(dt)
  
  --testing
  --local seconds = (os.time{year=2000, month=1, day=1, hour=6, sec=0}) % 86400
  
  local seconds = (os.time() - os.time{year=2000, month=1, day=1, hour=0, sec=0}) % 86400
  local hour = (math.floor(seconds / 3600) % 12) + 1
  local minute = (math.floor(seconds / 60) % 60)
  
  local hourAngle = ((math.pi * 2) / 12) * hour * -1
  local minuteAngle = ((math.pi * 2) / 60) * minute * -1
  
  --adjust hour hand in small increments between hours as minute hand increments
  local ittybitty = minuteAngle / 12
  hourAngle = hourAngle + ittybitty
  
  animator.rotateGroup("hour", hourAngle)
  animator.rotateGroup("minute", minuteAngle)
end