
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
	

	for typeName, typeEntry in pairs(vehicleTypeManager:getVehicleTypes()) do
		
		if typeName ~= "horse" and typeName ~= "pallet" then -- ignore pallets and horse 
			-- add simpleIC to everything except locomotives 
			if not SpecializationUtil.hasSpecialization(Locomotive, typeEntry.specializations) then
				vehicleTypeManager:addSpecialization(typeName, modName .. ".simpleIC")
				print("inserted simpleIC to "..tostring(typeName));
			end;
        end
    end

end

init()

function registerSimpleIC:mouseEvent(posX, posY, isDown, isUp, button)
	if isUp then
		local vehicle = g_currentMission.controlledVehicle

		--Check if this is the key assigned to INTERACT
		local action = g_inputBinding:getActionByName("INTERACT_IC_VEHICLE");
		for _, binding in ipairs(action.bindings) do
			if binding.axisNames[1] ~= nil and binding.axisNames[1] == Input.mouseButtonIdToIdName[button] then
				if vehicle ~= nil and vehicle.spec_simpleIC ~= nil then
					simpleIC.doInteraction(vehicle)
				end
			end
		end
	end
end

addModEventListener(registerSimpleIC)