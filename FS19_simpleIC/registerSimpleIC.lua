
registerSimpleIC = {};

local modName = g_currentModName;
local modDirectory = g_currentModDirectory;
print("TEST");
function init()
	print("INIT");
	VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, validateVehicleTypes)
end


function validateVehicleTypes(vehicleTypeManager)
	print("validateVehicleTypes");
    registerSimpleIC.installSpecializations(g_vehicleTypeManager, g_specializationManager, modDirectory, modName)
end


function registerSimpleIC.installSpecializations(vehicleTypeManager, specializationManager, modDirectory, modName)
	specializationManager:addSpecialization("simpleIC", "simpleIC", modDirectory.."simpleIC.lua", nil)
	
    for typeName, typeEntry in pairs(vehicleTypeManager:getVehicleTypes()) do

        if SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) then
			if not SpecializationUtil.hasSpecialization(Locomotive, typeEntry.specializations) then
				vehicleTypeManager:addSpecialization(typeName, modName .. ".simpleIC")
				print("inserted simpleIC to "..tostring(typeName));
			end;
        end
    end

end



init()































