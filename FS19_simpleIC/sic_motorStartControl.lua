-- SimpleIC Motor Start Control 
-- to start/stop engine via IC and animate button/lever

sic_motorStartControl = {};

function sic_motorStartControl.prerequisitesPresent(specializations)
    return true;
end;

function sic_motorStartControl.registerEventListeners(vehicleType)	
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", sic_motorStartControl);
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", sic_motorStartControl)
end;


function sic_motorStartControl:onLoad(savegame)
	self.loadMotorStartControl = sic_motorStartControl.loadMotorStartControl;
    self.setMotorStartControl = sic_motorStartControl.setMotorStartControl;
    
    self.spec_sic_motorStartControl = {};

    local spec = self.spec_sic_motorStartControl;

    spec.turnKeyAnimationState = 0;
    spec.turnKeyAnimation = nil;

end;


function sic_motorStartControl:loadMotorStartControl(key, table)
	local motorStartControl ={};

    if hasXMLProperty(self.xmlFile, key) then

        local animationName = getXMLString(self.xmlFile, key..".leverAnimation#animationName");
        if animationName ~= "" and animationName ~= nil then
            motorStartControl.leverAnimation = {};
            motorStartControl.leverAnimation.animationName = animationName;
            motorStartControl.leverAnimation.isTurnKeyAnimation = getXMLBool(self.xmlFile, key..".leverAnimation#isTurnKeyAnimation")
        end;

        local animationNameStart = getXMLString(self.xmlFile, key..".leverAnimationStart#animationName");
        if animationNameStart ~= "" and animationNameStart ~= nil then
            motorStartControl.leverAnimationStart = {};
            motorStartControl.leverAnimationStart.animationName = animationNameStart;
        end;      

        local animationNameStop = getXMLString(self.xmlFile, key..".leverAnimationStop#animationName");
        if animationNameStop ~= "" and animationNameStop ~= nil then
            motorStartControl.leverAnimationStop = {};
            motorStartControl.leverAnimationStop.animationName = animationNameStop;
        end;            
    
		table.motorStartControl = motorStartControl;
		return true;

    end;

end;

function sic_motorStartControl:setMotorStartControl(wantedState, i)
    local motorStartControl = self.spec_simpleIC.icFunctions[i].motorStartControl;

    if wantedState == nil then
        wantedState = not self:getIsMotorStarted();
    end;

    if not wantedState then
        self:stopMotor();
    elseif wantedState and self:getCanMotorRun() then
        self:startMotor()
    end;

end;

function sic_motorStartControl:onUpdateTick(dt)
    if self:getIsActive() then
        local spec = self.spec_sic_motorStartControl;
        if spec.turnKeyAnimation ~= nil and spec.turnKeyAnimationState == 1 then
            if g_currentMission.time > self:getMotorStartTime() then
                self:playAnimation(spec.turnKeyAnimation.animationName, -1, self:getAnimationTime(spec.turnKeyAnimation.animationName), true);	
                self:setAnimationStopTime(spec.turnKeyAnimation.animationName, 0.7);
                spec.turnKeyAnimationState = 2;
                spec.turnKeyAnimation = nil;
            end;
        end;
        if spec.leverAnimationStart ~= nil then
            local animTime = self:getAnimationTime(spec.leverAnimationStart.animationName);
            if animTime == 1 then
                self:playAnimation(spec.leverAnimationStart.animationName, -1, self:getAnimationTime(spec.leverAnimationStart.animationName), true);	
                spec.leverAnimationStart = nil;
            end;
        end;
        if spec.leverAnimationStop ~= nil then
            local animTime = self:getAnimationTime(spec.leverAnimationStop.animationName);
            if animTime < 1 then
                self:raiseActive();
            else
                self:playAnimation(spec.leverAnimationStop.animationName, -1, self:getAnimationTime(spec.leverAnimationStop.animationName), true);	
                spec.leverAnimationStop = nil;
            end;
        end;       
    end;
end;

function sic_motorStartControl.startMotorAppend(self, superFunc, noEventSend)
    superFunc(self, noEventSend);

    if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then
        for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do
            if icFunction.motorStartControl ~= nil then

                local spec = self.spec_sic_motorStartControl;

                local leverAnimation = icFunction.motorStartControl.leverAnimation;
                if leverAnimation ~= nil then
                    self:playAnimation(leverAnimation.animationName, 1, self:getAnimationTime(leverAnimation.animationName), true);	
                    if leverAnimation.isTurnKeyAnimation then
                        spec.turnKeyAnimationState = 1;
                        spec.turnKeyAnimation = leverAnimation;
                    end;
                end;

                local leverAnimationStart = icFunction.motorStartControl.leverAnimationStart;
                if leverAnimationStart ~= nil then
                    self:playAnimation(leverAnimationStart.animationName, 1, self:getAnimationTime(leverAnimationStart.animationName), true);	
                    spec.leverAnimationStart = leverAnimationStart;
                end;
            end;
        end;
    end;
end;
Motorized.startMotor = Utils.overwrittenFunction(Motorized.startMotor, sic_motorStartControl.startMotorAppend)

function sic_motorStartControl.stopMotor(self, superFunc, noEventSend)
    superFunc(self, noEventSend);

    if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then
        for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do
            if icFunction.motorStartControl ~= nil then

                if icFunction.motorStartControl.leverAnimation ~= nil then
                    local leverAnimation = icFunction.motorStartControl.leverAnimation;
                    self:playAnimation(leverAnimation.animationName, -1, self:getAnimationTime(leverAnimation.animationName), true);	
                end;

                local leverAnimationStop = icFunction.motorStartControl.leverAnimationStop;
                if leverAnimationStop ~= nil then
                    self:playAnimation(leverAnimationStop.animationName, 1, self:getAnimationTime(leverAnimationStop.animationName), true);	
                    self.spec_sic_motorStartControl.leverAnimationStop = leverAnimationStop;
                    self:raiseActive();
                end;               
            end;
        end;
    end;
end;
Motorized.stopMotor = Utils.overwrittenFunction(Motorized.stopMotor, sic_motorStartControl.stopMotor)