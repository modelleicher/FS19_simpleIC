-- SimpleIC Light Control
-- to control Vehicle Lights via SimpleIC

sic_lightControl = {};

function sic_lightControl.prerequisitesPresent(specializations)
    return true;
end;

function sic_lightControl.registerEventListeners(vehicleType)	
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", sic_lightControl);
end;


function sic_lightControl:onLoad(savegame)
	self.loadLightControl = sic_lightControl.loadLightControl;
    self.setLightControl = sic_lightControl.setLightControl;
    self.getBinaryFromDecimal = sic_lightControl.getBinaryFromDecimal;
end;


function sic_lightControl:loadLightControl(key, table)

    local type = getXMLString(self.xmlFile, key.."#type");
    if type ~= "" and type ~= nil then
        local lightControl = {};
        lightControl.type = type;

        lightControl.lightTypes = { StringUtil.getVectorFromString(getXMLString(self.xmlFile, key.."#lightTypes")) }

        local animationName = getXMLString(self.xmlFile, key..".leverAnimation#animationName");
        if animationName ~= "" and animationName ~= nil then
            lightControl.leverAnimation = {};
            lightControl.leverAnimation.animationName = animationName;
            --lightControl.leverAnimation.doNotSynch = getXMLBool(self.xmlFile, key..".leverAnimation#doNotSynch");
            lightControl.leverAnimation.isTurnlightSharedAnimation = getXMLBool(self.xmlFile, key..".leverAnimation#isTurnlightSharedAnimation")

            if lightControl.type == "toggle" then
                lightControl.leverAnimation.animStops = {};
                for i = 1, self.spec_lights.numLightTypes do
                    local animStop = getXMLFloat(self.xmlFile, key..".leverAnimation#animStopLightTypes"..i-1);
                    if animStop ~= nil then
                        lightControl.leverAnimation.animStops[i] = animStop;
                    end;
                end;
            end;

        end;

        table.lightControl = lightControl;
		return true;
    end;


end;

function sic_lightControl:setLightControl(wantedState, i)
    local lightControl = self.spec_simpleIC.icFunctions[i].lightControl;

    if lightControl ~= nil then

        local spec = self.spec_lights;

        -- get type and set
        if lightControl.type == "state" and #lightControl.lightTypes ~= 0 then
            local lightsTypesMask = 0;
            for i=1, #lightControl.lightTypes do
                lightsTypesMask = bitXOR(spec.lightsTypesMask, 2^lightControl.lightTypes[i]);
            end;
            --print(tostring(lightsTypesMask))
            self:setLightsTypesMask(lightsTypesMask);

        elseif lightControl.type == "toggle" then
            self:setNextLightsState();

        elseif lightControl.type == "turnLightLeft" then
            local state = Lights.TURNLIGHT_OFF;
            if spec.turnLightState ~= Lights.TURNLIGHT_LEFT then
                state = Lights.TURNLIGHT_LEFT;
            end;
            if wantedState ~= nil then
                if wantedState then
                    state = Lights.TURNLIGHT_LEFT;
                else
                    state = Lights.TURNLIGHT_OFF;
                end;
            end;
            self:setTurnLightState(state);

        elseif lightControl.type == "turnLightRight" then
            local state = Lights.TURNLIGHT_OFF;
            if spec.turnLightState ~= Lights.TURNLIGHT_RIGHT then
                state = Lights.TURNLIGHT_RIGHT;
            end;
            if wantedState ~= nil then
                if wantedState then
                    state = Lights.TURNLIGHT_RIGHT;
                else
                    state = Lights.TURNLIGHT_OFF;
                end;
            end;           
            self:setTurnLightState(state); 

        elseif lightControl.type == "turnLightHazard" then
            local state = Lights.TURNLIGHT_OFF;
            if spec.turnLightState ~= Lights.TURNLIGHT_HAZARD then
                state = Lights.TURNLIGHT_HAZARD;
            end;
            if wantedState ~= nil then
                if wantedState then
                    state = Lights.TURNLIGHT_HAZARD;
                else
                    state = Lights.TURNLIGHT_OFF;
                end;
            end;               
            self:setTurnLightState(state);  

        elseif lightControl.type == "beaconLights" then
            wantedState = Utils.getNoNil(wantedState, not spec.beaconLightsActive)
            self:setBeaconLightsVisibility(not spec.beaconLightsActive);
        end;

    end;
end;


function sic_lightControl:getBinaryFromDecimal(decimal)
    local quot = decimal;
    local binary = {};
    local i = 1;
    while quot ~= 0 do
        local remainder = math.fmod(quot, 2);
        quot = math.floor(quot / 2);
        binary[i] = remainder;
        i = i+1;
    end;
    return binary;
end;

function sic_lightControl.setLightsTypesMaskAppend(self, superFunc, lightsTypesMask, force, noEventSend)
    superFunc(self, lightsTypesMask, force, noEventSend);
    local spec = self.spec_lights;

    if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then
        for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do   
            if icFunction.lightControl ~= nil and icFunction.lightControl.leverAnimation ~= nil then
                local lightControl = icFunction.lightControl;
                local binary = self:getBinaryFromDecimal(lightsTypesMask);
                
                if lightControl.type == "state" and #lightControl.lightTypes ~= 0 then
                    local isOn = false;
                    for i=1, #lightControl.lightTypes do
                        if binary[lightControl.lightTypes[i]+1] ~= nil and binary[lightControl.lightTypes[i]+1] ~= 0 then
                            --print("lightTypes("..i.."): "..tostring(lightControl.lightTypes[i]))
                            --print("binary Index: "..tostring(binary[lightControl.lightTypes[i]]+1))
                            isOn = true;
                        end;
                    end;
                    if isOn then
                        self:playAnimation(lightControl.leverAnimation.animationName, 1, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                    else
                        self:playAnimation(lightControl.leverAnimation.animationName, -1, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                    end;
                end;

                if lightControl.type == "toggle" then
                    if #binary > 0 then

                        local wantedStopTime = 0;

                        for i = 1, spec.numLightTypes do
                            if binary[i] ~= nil and binary[i] ~= 0 then
                                if lightControl.leverAnimation.animStops[i] ~= nil then
                                    wantedStopTime = lightControl.leverAnimation.animStops[i];
                                end;
                            end;
                        end;

                        if wantedStopTime ~= 0 then
                            local animTime = self:getAnimationTime(lightControl.leverAnimation.animationName)
                            if animTime > wantedStopTime then
                                self:playAnimation(lightControl.leverAnimation.animationName, -1, animTime, true);
                                self:setAnimationStopTime(lightControl.leverAnimation.animationName, wantedStopTime);
                            elseif animTime < wantedStopTime then
                                self:playAnimation(lightControl.leverAnimation.animationName, 1, animTime, true);
                                self:setAnimationStopTime(lightControl.leverAnimation.animationName, wantedStopTime);
                            end;
                        end;
                    else
                        self:playAnimation(lightControl.leverAnimation.animationName, -1, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                    end;
                end;
            end;
        end;
    end;

end;
Lights.setLightsTypesMask = Utils.overwrittenFunction(Lights.setLightsTypesMask, sic_lightControl.setLightsTypesMaskAppend);


-- beaconlights animation
function sic_lightControl.setBeaconLightsVisibilityAppend(self, superFunc, visibility, force, noEventSend)
    superFunc(self, visibility, force, noEventSend);

    if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then
        for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do
            if icFunction.lightControl ~= nil and icFunction.lightControl.leverAnimation ~= nil then
                if icFunction.lightControl.type == "beaconLights" then
                    if visibility then
                        self:playAnimation(lightControl.leverAnimation.animationName, 1, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                    else
                        self:playAnimation(lightControl.leverAnimation.animationName, -1, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                    end;
                end;
            end;
        end;
    end;
end;
Lights.setBeaconLightsVisibility = Utils.overwrittenFunction(Lights.setBeaconLightsVisibility, sic_lightControl.setBeaconLightsVisibilityAppend);


-- Turnlight Animations
function sic_lightControl.setTurnLightStateAppend(self, superFunc, state, force, noEventSend)
    superFunc(self, state, foce, noEventSend);

    if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then
        for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do
            if icFunction.lightControl ~= nil and icFunction.lightControl.leverAnimation ~= nil then
                local lightControl = icFunction.lightControl;

                local isSharedAnim = lightControl.leverAnimation.isTurnlightSharedAnimation;

                -- animation is shared for left and right turnlight 
                if isSharedAnim then
                    if lightControl.type == "turnLightLeft" then
                        if state == Lights.TURNLIGHT_LEFT then
                            self:playAnimation(lightControl.leverAnimation.animationName, 1, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                        elseif state == Lights.TURNLIGHT_OFF then
                            local animTime = self:getAnimationTime(lightControl.leverAnimation.animationName);
                            if animTime > 0.5 then
                                self:playAnimation(lightControl.leverAnimation.animationName, -1, animTime, true);
                                self:setAnimationStopTime(lightControl.leverAnimation.animationName, 0.5); 
                            end;           
                        end;              
                    end;
                    if lightControl.type == "turnLightRight" then
                        if state == Lights.TURNLIGHT_RIGHT then
                            self:playAnimation(lightControl.leverAnimation.animationName, -1, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                        elseif state == Lights.TURNLIGHT_OFF then
                            local animTime = self:getAnimationTime(lightControl.leverAnimation.animationName);
                            if animTime < 0.5 then
                                self:playAnimation(lightControl.leverAnimation.animationName, 1, animTime, true);
                                self:setAnimationStopTime(lightControl.leverAnimation.animationName, 0.5); 
                            end;              
                        end;              
                    end;
                else -- if animation isn't shared animate normally and independently
                    if lightControl.type == "turnLightLeft" then
                        if state == Lights.TURNLIGHT_LEFT then
                            self:playAnimation(lightControl.leverAnimation.animationName, 1, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                        elseif state == Lights.TURNLIGHT_OFF then
                            self:playAnimation(lightControl.leverAnimation.animationName, -1, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                        end;
                    end;
                    if lightControl.type == "turnLightRight" then
                        if state == Lights.TURNLIGHT_RIGHT then
                            self:playAnimation(lightControl.leverAnimation.animationName, 1, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                        elseif state == Lights.TURNLIGHT_OFF then
                            self:playAnimation(lightControl.leverAnimation.animationName, -1, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                        end;
                    end;                  
                end;
                
                -- hazards animation is independent
                if lightControl.type == "turnLightHazard" then
                    if state == Lights.TURNLIGHT_HAZARD then
                        self:playAnimation(lightControl.leverAnimation.animationName, 1, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                    elseif state == Lights.TURNLIGHT_OFF then
                        self:playAnimation(lightControl.leverAnimation.animationName, -1, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                    end;
                end;
            end;
        end;
    end;

end;
Lights.setTurnLightState = Utils.overwrittenFunction(Lights.setTurnLightState, sic_lightControl.setTurnLightStateAppend);