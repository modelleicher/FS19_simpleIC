
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































