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
            lightControl.leverAnimation.onTime = Utils.getNoNil(getXMLBool(self.xmlFile, key..".leverAnimation#onTime"), 1);
            lightControl.leverAnimation.offTime = Utils.getNoNil(getXMLFloat(self.xmlFile, key..".leverAnimation#offTime"), 0);
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
            print(tostring(lightsTypesMask))
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


function sic_lightControl.setTurnLightStateAppend(self, superFunc, state, force, noEventSend)
    superFunc(self, state, foce, noEventSend);

    if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then
        for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do
            if icFunction.lightControl ~= nil and icFunction.lightControl.leverAnimation ~= nil then
                print("has lever animation")
                local lightControl = icFunction.lightControl;

                if lightControl.type == "turnLightLeft" or lightControl.type == "turnLightRight" then

                    if state == Lights.TURNLIGHT_LEFT or state == Lights.TURNLIGHT_RIGHT then
                        local speed = 1;
                        if lightControl.leverAnimation.onTime == 0 then
                            speed = -1;
                        end;
                        self:playAnimation(lightControl.leverAnimation.animationName, speed, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                    end;
                    if state == Lights.TURNLIGHT_OFF then
                        local speed = 1;
                        local animTime = self:getAnimationTime(lightControl.leverAnimation.animationName);
                        if animTime > lightControl.leverAnimation.offTime then
                            speed = -1;
                        end;
                        self:playAnimation(lightControl.leverAnimation.animationName, speed, animTime, true);
                        self:setAnimationStopTime(lightControl.leverAnimation.animationName, lightControl.leverAnimation.offTime);
                    end;
                end;
                if lightControl.type == "turnLightHazard" then
                    if state == Lights.TURNLIGHT_HAZARD then
                        local speed = -1;
                        if lightControl.leverAnimation.onTime == 0 then
                            speed = 1;
                        end;
                        self:playAnimation(lightControl.leverAnimation.animationName, speed, self:getAnimationTime(lightControl.leverAnimation.animationName), true);
                    elseif state == Lights.TURNLIGHT_OFF then
                        local speed = -1;
                        if lightControl.leverAnimation.onTime == 0 then
                            speed = 1;
                        end;
                        self:playAnimation(lightControl.leverAnimation.animationName, speed, nil, true);
                        self:setAnimationStopTime(lightControl.leverAnimation.animationName, lightControl.leverAnimation.offTime);
                    end;
                end;
            end;
        end;
    end;

end;
Lights.setTurnLightState = Utils.overwrittenFunction(Lights.setTurnLightState, sic_lightControl.setTurnLightStateAppend);