function update(dt)  
	if config.getParameter("questPlacement") then
		if world.getProperty("lofty_irisil_bastetDungeonComplete") then
			object.smash()
		end
	else
		object.setInteractive(false)
	end
end