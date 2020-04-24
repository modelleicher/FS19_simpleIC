
registerSimpleIC = {};

local modName = g_currentModName;
local modDirectory = g_currentModDirectory;

function init()
	VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, validateVehicleTypes)
end


function validateVehicleTypes(vehicleTypeManager)
	print("validateVehicleTypes");
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