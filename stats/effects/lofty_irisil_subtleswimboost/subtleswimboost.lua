function init()
  self.movementParameters = config.getParameter("movementParameters", {})
end

function update(dt)
 
  --if the user is running the improved swim physics mod, just apply the swimboost status effect and let isp handle it
  if status.statusProperty("ispEnabled", false) then
    status.addEphemeralEffect("swimboost")
	
  --if the user is running vanilla swim physics, reduce their fluid friction and increase their movespeed
  else
    mcontroller.controlParameters(self.movementParameters)
  end
end

function uninit()
  
end
