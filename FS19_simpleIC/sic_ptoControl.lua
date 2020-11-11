-- SimpleIC PTO Control
-- to control PTO Implements e.g. TurnOnVehicle via simpleIC

sic_ptoControl = {};

function sic_ptoControl.prerequisitesPresent(specializations)
    return true;
end;

function sic_ptoControl.registerEventListeners(vehicleType)	
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", sic_ptoControl);
end;


function sic_ptoControl:onLoad(savegame)
	self.loadPTOControl = sic_ptoControl.loadPTOControl;
	self.setPTOControl = sic_ptoControl.setPTOControl;
end;

function sic_ptoControl:loadPTOControl(key, table)
	local ptoControl ={};
    ptoControl.attacherIndex = getXMLInt(self.xmlFile, key.."#attacherIndex");
    ptoControl.turnOnSelf = getXMLBool(self.xmlFile, key.."#turnOnSelf");
	if ptoControl.attacherIndex ~= nil or ptoControl.turnOnSelf then

        local animationName = getXMLString(self.xmlFile, key..".leverAnimation#animationName");
        if animationName ~= "" and animationName ~= nil then
            ptoControl.leverAnimation = {};
            ptoControl.leverAnimation.animationName = animationName;
            ptoControl.leverAnimation.doNotSynch = getXMLBool(self.xmlFile, key..".leverAnimation#doNotSynch");
        end;
    
		table.ptoControl = ptoControl;
		return true;
	end;
end;

function sic_ptoControl:setPTOControl(wantedState, i)
    local ptoControl = self.spec_simpleIC.icFunctions[i].ptoControl;
    
    if ptoControl.turnOnSelf then
        if wantedState == nil then
            wantedState = not self.spec_turnOnVehicle.isTurnedOn;
        end;
        self:setIsTurnedOn(wantedState);
    end;

    -- cycle through all attached implements to find the implement attached to the attacherIndex of this icFunction ptoControl
    if ptoControl.attacherIndex ~= nil then
        for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
            if implement.jointDescIndex == ptoControl.attacherIndex then
                if implement.object.spec_turnOnVehicle ~= nil then
                    
                    -- wantedState is either true or false when there is a _ON and _OFF trigger, otherwise its nil so we need the != of the current state  
                    if wantedState == nil then
                        wantedState = not implement.object.spec_turnOnVehicle.isTurnedOn;
                    end;
                    -- apply state 
                    implement.object:setIsTurnedOn(wantedState)

                    -- run animation if doNotSynch is true, otherwise animation will be run by setIsTurnedOn Append function
                    if ptoControl.leverAnimation ~= nil and ptoControl.leverAnimation.doNotSynch then
                        local speed = 1;
                        if not wantedState then
                            speed = -1;
                        end;
                        self:playAnimation(ptoControl.leverAnimation.animationName, speed, self:getAnimationTime(ptoControl.leverAnimation.animationName), true);	
                    end;
                end;
            end;
        end;
    end;
end;

function sic_ptoControl.setIsTurnedOnAppend(self, superFunc, isTurnedOn, noEventSend)
    superFunc(self, isTurnedOn, noEventSend);

    -- check if we have simpleIC ourselfes 
    if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then
        for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do
            if icFunction.ptoControl ~= nil then
                if icFunction.ptoControl.turnOnSelf then
                    if icFunction.ptoControl.leverAnimation ~= nil then
                        local speed = -1;
                        if isTurnedOn then
                            speed = 1;
                        end;
                        self:playAnimation(icFunction.ptoControl.leverAnimation.animationName, speed, nil, false);
                    end;
                end;
            end;
        end;
    end;

    -- TO DO -> make this less horrible..

    -- if we are an implement, we need to get our attacherVehicle 
    if self.getAttacherVehicle ~= nil then
        local attacherVehicle = self:getAttacherVehicle()
        if attacherVehicle ~= nil then
            -- check if attacherVehicle has simpleIC
            if attacherVehicle.spec_simpleIC ~= nil and attacherVehicle.spec_simpleIC.hasIC then
                -- cycle through SIC functions to find ptoControl ones 
                for _, icFunction in pairs(attacherVehicle.spec_simpleIC.icFunctions) do
                    -- found ptoControl 
                    if icFunction.ptoControl ~= nil then
                        -- check if ptoControl has leverAnimation 
                        if icFunction.ptoControl.leverAnimation ~= nil then
                            -- now check if ptoControl has attacherIndex 
                            if icFunction.ptoControl.attacherIndex ~= nil then
                                -- run through implements attached to attacherVehicle to find out attacherIndex 
                                for _, implement in pairs(attacherVehicle.spec_attacherJoints.attachedImplements) do
                                    -- compare attacherIndex 
                                    if implement.jointDescIndex == icFunction.ptoControl.attacherIndex then
                                        -- now see if we are this implement 
                                        if implement.object == self then
                                            -- run animation 
                                            local speed = -1;
                                            if isTurnedOn then
                                                speed = 1;
                                            end;
                                            attacherVehicle:playAnimation(icFunction.ptoControl.leverAnimation.animationName, speed, attacherVehicle:getAnimationTime(icFunction.ptoControl.leverAnimation.animationName), true);
                                        end;
                                    end;
                                end;
                            end;
                        end;
                    end;
                end;
            end;    
        end;
    end;
end;

TurnOnVehicle.setIsTurnedOn = Utils.overwrittenFunction(TurnOnVehicle.setIsTurnedOn, sic_ptoControl.setIsTurnedOnAppend);

