-- SimpleIC Drivable Control
-- to control stuff that is generally found in drivable vehicles 


sic_drivableControl = {};

function sic_drivableControl.prerequisitesPresent(specializations)
    return true;
end;

function sic_drivableControl.registerEventListeners(vehicleType)	
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", sic_drivableControl);
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", sic_drivableControl);
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", sic_drivableControl);   
end;

function sic_drivableControl:onLoad(savegame)
	self.loadDrivableControl = sic_drivableControl.loadDrivableControl;
    self.setDrivableControl = sic_drivableControl.setDrivableControl;
    
    -- access tables
    if self.sic_at == nil then
        self.sic_at = {};
    end;
    self.sic_at.drivableControl = {};

    self.spec_sic_drivableControl = {};



end;

function sic_drivableControl:onPostLoad(savegame)
    local spec = self.spec_sic_drivableControl;

    spec.tsx_enhancedVehicleLoaded = g_modIsLoaded.TSX_EnhancedVehicle;
    spec.tsx_enhancedVehicle_diffEnabled = TSX_EnhancedVehicle.TSX_EnhancedVehicle.functionDifferentialIsEnabled;
    spec.tsx_enhancedVehicle_shuttleEnabled = TSX_EnhancedVehicle.TSX_EnhancedVehicle.functionShuttleIsEnabled;

    if spec.tsx_enhancedVehicleLoaded then
        spec.vDataBackup = {nil, nil, nil, nil, nil, nil};
    end;
end;

function sic_drivableControl:loadDrivableControl(key, table)
    local drivableControl = {};

    drivableControl.type = getXMLString(self.xmlFile, key.."#type");
    drivableControl.specific = getXMLString(self.xmlFile, key.."#specific");

    if drivableControl.type ~= nil and drivableControl.type ~= "" then
        
        local animationName = getXMLString(self.xmlFile, key..".leverAnimation#animationName");
        if animationName ~= "" and animationName ~= nil then
            drivableControl.leverAnimation = {};
            drivableControl.leverAnimation.animationName = animationName;
            drivableControl.leverAnimation.doNotSynch = getXMLBool(self.xmlFile, key..".leverAnimation#doNotSynch");
        end;

        table.drivableControl = drivableControl;
        self.sic_at.drivableControl[#self.sic_at.drivableControl+1] = drivableControl;
        return true;
    end;

end;

-- get access to TSX functions 
function sic_drivableControl.tsx_onRegisterActionEventsAppend(self, superFunc, isSelected, isOnActiveVehicle)

    local returnValues = superFunc(self, isSelected, isOnActiveVehicle);

    self.onActionCall = TSX_EnhancedVehicle.TSX_EnhancedVehicle.onActionCall;
end;
TSX_EnhancedVehicle.TSX_EnhancedVehicle.onRegisterActionEvents = Utils.overwrittenFunction(TSX_EnhancedVehicle.TSX_EnhancedVehicle.onRegisterActionEvents, sic_drivableControl.tsx_onRegisterActionEventsAppend);


function sic_drivableControl:onUpdate(dt)
    if self:getIsActive() then
        local spec = self.spec_sic_drivableControl;

        for _, drivableControl in pairs(self.sic_at.drivableControl) do
            local leverAnimation = drivableControl.leverAnimation;
            if leverAnimation ~= nil then
                if spec.tsx_enhancedVehicleLoaded then
                    local speed = -1;
                    if spec.tsx_enhancedVehicle_diffEnabled then
                        if drivableControl.type == "diffLock" and (drivableControl.specific == "front" or drivableControl.specific == "all")  then
                            if spec.vDataBackup[1] ~= self.vData.want[1] then
                                if self.vData.want[1] then
                                    speed = 1;
                                end;
                                self:playAnimation(leverAnimation.animationName, speed, self:getAnimationTime(leverAnimation.animationName), true);
                            end;
                        end;
                        if drivableControl.type == "diffLock" and (drivableControl.specific == "rear" or drivableControl.specific == "all")  then
                            if spec.vDataBackup[2] ~= self.vData.want[2] then
                                if self.vData.want[2] then
                                    speed = 1;
                                end;
                                self:playAnimation(leverAnimation.animationName, speed, self:getAnimationTime(leverAnimation.animationName), true);
                            end;
                        end;          
                        if drivableControl.type == "4wd" then
                            
                            if spec.vDataBackup[3] ~= self.vData.want[3] then
                                if self.vData.want[3] then
                                    speed = 1;
                                end;
                                print("4wd do")
                                self:playAnimation(leverAnimation.animationName, speed, self:getAnimationTime(leverAnimation.animationName), true);
                            end;
                        end;         
                    end;
                    if spec.tsx_enhancedVehicle_shuttleEnabled then
                        if drivableControl.type == "shuttle" then
                            if spec.vDataBackup[4] ~= self.vData.want[4] then
                                if self.vData.want[4] then
                                    speed = 1;
                                end;
                                self:playAnimation(leverAnimation.animationName, speed, self:getAnimationTime(leverAnimation.animationName), true);
                            end;
                        end;  
                        if drivableControl.type == "handbrake" then
                            if spec.vDataBackup[6] ~= self.vData.want[6] then
                                if self.vData.want[6] then
                                    speed = 1;
                                end;
                                self:playAnimation(leverAnimation.animationName, speed, self:getAnimationTime(leverAnimation.animationName), true);
                            end;
                        end;           
                    end;                                                            
                end;
            end;
        end;
    end;
end;




function sic_drivableControl:setDrivableControl(wantedState, i)
    local drivableControl = self.spec_simpleIC.icFunctions[i].drivableControl;

    local spec = self.spec_sic_drivableControl;

    -- try use TSX 4wd
    if spec.tsx_enhancedVehicleLoaded then 

        if spec.tsx_enhancedVehicle_diffEnabled then
            if drivableControl.type == "4wd" then
                self:onActionCall("TSX_EnhancedVehicle_DM");
            end;
            if drivableControl.type == "diffLock" then
                if drivableControl.specific == "all" then
                    self:onActionCall("TSX_EnhancedVehicle_BD");
                elseif drivableControl.specific == "front" then
                    self:onActionCall("TSX_EnhancedVehicle_FD");
                elseif drivableControl.specific == "rear" then
                    self:onActionCall("TSX_EnhancedVehicle_RD");
                end;
            end;
        end;
        if spec.tsx_enhancedVehicle_shuttleEnabled then
            if drivableControl.type == "handbrake" then
                self:onActionCall("TSX_EnhancedVehicle_SHUTTLE_PARK");
            end;
            if drivableControl.type == "shuttle" then
                if drivableControl.specific == "toggle" then
                    self:onActionCall("TSX_EnhancedVehicle_SHUTTLE_SWITCH");
                elseif drivableControl.specific == "forward" then
                    self:onActionCall("TSX_EnhancedVehicle_SHUTTLE_FWD");
                elseif drivableControl.specific == "reverse" then
                    self:onActionCall("TSX_EnhancedVehicle_SHUTTLE_REV");
                end;
            end;
        end;
    end;

end;