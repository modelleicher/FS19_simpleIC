--[[
Changelog
## V 0.9.2.3
- MP Server fix of vehicle not enterable
## V 0.9.2.2
- fix for line 102 error I think, couldn't reproduce but I found an issue with the table indexing and I think it worked fine for most mods but some may have caused the issue to show.
## V 0.9.2.1
- possibly fixed dedicated server issue 
- removed "cylinder" debug finally 
## V 0.9.2.0
- addition of SimpleIC-ImplementBalls
## V 0.9.1.9
- fixed the issue introduced in the version before last version and partially fixed in the last version. Now fixed completely. I hope.. again.
## V 0.9.1.8
- fixed Issue introduced in the last version of indoor buttons only working when the ingame-menu is on, fully removed issue with double-mapping of mouseButtons I hope
## V 0.9.1.7
- fixed Error: simpleIC.lua:488: attempt to index field 'spec_motorized' (a nil value)
- fixed Error: simpleIC.lua:318: attempt to call method 'getAttacherVehicle' (a nil value)
- reachDistance can be set per vehicle (optional, default 1.8) to specify how far away a player can reach an IC-point
## V 0.9.1.6
- fixed spec insertion so simpleIC now works in every implement, trailer etc. not just drivables
## V 0.9.1.5
- fixed Error: simpleIC.lua:248: attempt to index local 'spec' (a nil value)
- added cylinderAnimation for easy animation of struts on windows/doors etc.
## V 0.9.1.4
- fixed IC active on all vehicles bug (now only active if vehicle actually has IC functions)
- fixed bug Error: Running LUA method 'update' simpleIC.lua:292: attempt to index a nil value
- added default keymapping
## V 0.9.1.3
- multiplayer fix
- added triggerPoint_ON and triggerPoint_OFF as alternative to toggle via triggerPoint 

]]


registerSimpleIC = {};

registerSimpleIC.version = "0.9.2.2"

local modName = g_currentModName;
local modDirectory = g_currentModDirectory;

function init()
	VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, validateVehicleTypes)
	print("SimpleIC Version "..registerSimpleIC.version.." init.");
end


function validateVehicleTypes(vehicleTypeManager)
	registerSimpleIC.installSpecializations(g_vehicleTypeManager, g_specializationManager, modDirectory, modName)
end


function registerSimpleIC.installSpecializations(vehicleTypeManager, specializationManager, modDirectory, modName)
	specializationManager:addSpecialization("simpleIC", "simpleIC", modDirectory.."simpleIC.lua", nil)
	specializationManager:addSpecialization("simpleIC_implementBalls", "simpleIC_implementBalls", modDirectory.."simpleIC_implementBalls.lua", nil)
		
	
	for typeName, typeEntry in pairs(vehicleTypeManager:getVehicleTypes()) do
		
		if typeName ~= "horse" and typeName ~= "pallet" then -- ignore pallets and horse 
			-- add simpleIC to everything except locomotives 
			if not SpecializationUtil.hasSpecialization(Locomotive, typeEntry.specializations) then
				vehicleTypeManager:addSpecialization(typeName, modName .. ".simpleIC")
				print("inserted simpleIC to "..tostring(typeName));
				if SpecializationUtil.hasSpecialization(Attachable, typeEntry.specializations) then
					vehicleTypeManager:addSpecialization(typeName, modName .. ".simpleIC_implementBalls")
					print("inserted simpleIC_implementBalls to "..tostring(typeName));
				end;
			end;
        end
    end

end

init()

-- FIX for double-mapping of mouse buttons by Stephan-S
function registerSimpleIC:mouseEvent(posX, posY, isDown, isUp, button)
	if isUp or isDown then
		--Check if this is the key assigned to INTERACT
		local action = g_inputBinding:getActionByName("INTERACT_IC_VEHICLE");
		for _, binding in ipairs(action.bindings) do
			if binding.axisNames[1] ~= nil and binding.axisNames[1] == Input.mouseButtonIdToIdName[button] then
				local vehicle = g_currentMission.controlledVehicle
				if vehicle ~= nil and vehicle.spec_simpleIC ~= nil then
					if isDown then
						vehicle.spec_simpleIC.interact_present = true;
						if not vehicle.spec_simpleIC.interact_default then
							vehicle:doInteraction()
						end;
					elseif isUp then
						vehicle.spec_simpleIC.interact_present = false;
					end
				end			
			end
		end	
	end;
end;

function registerSimpleIC:update(dt)
	if g_currentMission.simpleIC_implementBalls ~= nil then -- check if we have implementBalls active 
		--print("simpleIC_implementBalls not nil")
		if g_currentMission.controlPlayer and g_currentMission.player ~= nil and not g_gui:getIsGuiVisible() then -- check if we are the player and no GUI is open
			--print("run player")
			local x, y, z = getWorldTranslation(g_currentMission.player.rootNode); -- get player pos 
			for index, spec in pairs(g_currentMission.simpleIC_implementBalls) do -- run through all implementBalls specs
				for _, implementJoint in pairs(spec.implementJoints) do -- run through all inputAttachers with implement type of this spec 
					local aX, aY, aZ = getWorldTranslation(implementJoint.node) -- get pos of implement joint node 

					local distance = MathUtil.vector3Length(x - aX, y - aY, z - aZ); -- get distance to player 

					--print("distance: "..tostring(distance))
					
					if distance < spec.maxDistance then -- if we're close enough activate stuffs 
						-- if we're in distance, show the X and activate inputBinding
						implementJoint.showX = true;
						spec.vehicle:raiseActive()

						if not spec.isInputActive then
							local specSIC = spec.vehicle.spec_simpleIC;
							specSIC.actionEvents = {}; -- create actionEvents table since in case we didn't enter the vehicle yet it does not exist 
							spec.vehicle:clearActionEventsTable(specSIC.actionEvents); -- also clear it for good measure 
							local _ , eventId = spec.vehicle:addActionEvent(specSIC.actionEvents, InputAction.INTERACT_IC_ONFOOT, spec.vehicle, simpleIC.INTERACT, false, true, false, true);	-- now add the actionEvent 	
							spec.isInputActive = true;
						end;					
					else
						if spec.isInputActive then
							spec.vehicle:removeActionEvent(spec.vehicle.spec_simpleIC.actionEvents, InputAction.INTERACT_IC_ONFOOT);
							spec.isInputActive = false;
							implementJoint.showX = false;
						end;
					end;	
				end;	
			end;
		end;
	end;

end;

addModEventListener(registerSimpleIC)