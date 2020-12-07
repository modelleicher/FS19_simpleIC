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
    
    -- access tables
    if self.sic_at == nil then
        self.sic_at = {};
    end;
    self.sic_at.attacherIndex_ptoControl = {};
    self.sic_at.ptoControl = {};
end;

function sic_ptoControl:loadPTOControl(key, table)
    local ptoControl ={};
    -- load xml attributes for ptoControl, attacherIndex is for backwards-compatability, use attacherIndices instead
    local attacherIndex = getXMLInt(self.xmlFile, key.."#attacherIndex");
    ptoControl.turnOnSelf = getXMLBool(self.xmlFile, key.."#turnOnSelf");
    local attacherIndices = getXMLString(self.xmlFile, key.."#attacherIndices")

    -- if we turn on self we don't need attacherIndices
    if attacherIndex ~= nil or (attacherIndices ~= "" and attacherIndices ~= nil) or ptoControl.turnOnSelf then
        
        -- split attacherIndices string into attacherIndices/add attacherIndex to table. Also add to create access tables
        if attacherIndices ~= nil then
            ptoControl.attacherIndices = StringUtil.splitString(" ", attacherIndices);
            for _, attacherIndex in pairs(ptoControl.attacherIndices) do
                self.sic_at.attacherIndex_ptoControl[tonumber(attacherIndex)] = ptoControl;
            end;
        else
            ptoControl.attacherIndices = {tostring(attacherIndex)};
            self.sic_at.attacherIndex_ptoControl[attacherIndex] = ptoControl;
        end;

        -- load optional animation
        local animationName = getXMLString(self.xmlFile, key..".leverAnimation#animationName");
        if animationName ~= "" and animationName ~= nil then
            ptoControl.leverAnimation = {};
            ptoControl.leverAnimation.animationName = animationName;
            ptoControl.leverAnimation.doNotSynch = getXMLBool(self.xmlFile, key..".leverAnimation#doNotSynch");
        end;
        
        -- add table and access table
        table.ptoControl = ptoControl;
        self.sic_at.ptoControl[#self.sic_at.ptoControl+1] = ptoControl;
		return true;
	end;
end;

function sic_ptoControl:setPTOControl(wantedState, i)
    local ptoControl = self.spec_simpleIC.icFunctions[i].ptoControl;
    
    -- if turnOnSelf its easy just turn on ourselfes lol 
    if ptoControl.turnOnSelf then
        if wantedState == nil then
            wantedState = not self.spec_turnOnVehicle.isTurnedOn;
        end;
        self:setIsTurnedOn(wantedState);
    end;

    -- cycle through all attached implements to find the implement attached to the attacherIndex of this icFunction ptoControl
    for _ , attacherIndex in pairs(ptoControl.attacherIndices) do
        for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
            if tostring(implement.jointDescIndex) == attacherIndex then
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



-- override setIsTurnedOn for playing animation when turned on/off even if it isn't done via SIC Input
function sic_ptoControl.setIsTurnedOnAppend(self, superFunc, isTurnedOn, noEventSend)
    superFunc(self, isTurnedOn, noEventSend);

    -- check if we have simpleIC ourselfes 
    if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then
        for _, ptoControl in pairs(self.sic_at.ptoControl) do
            if ptoControl.turnOnSelf then
                if ptoControl.leverAnimation ~= nil then
                    local speed = -1;
                    if isTurnedOn then
                        speed = 1;
                    end;
                    self:playAnimation(ptoControl.leverAnimation.animationName, speed, nil, false);
                end;
            end;
        end;
    end;

    -- if we are an implement, we need to get our attacherVehicle 
    if self.getAttacherVehicle ~= nil then
        local attacherVehicle = self:getAttacherVehicle()
        -- check if attacherVehicle has simpleIC
        if attacherVehicle ~= nil and attacherVehicle.spec_simpleIC ~= nil and attacherVehicle.spec_simpleIC.hasIC then
            -- run through implements attached to attacherVehicle to find out attacherIndex 
            for _, implement in pairs(attacherVehicle.spec_attacherJoints.attachedImplements) do
                local ptoControl = attacherVehicle.sic_at.attacherIndex_ptoControl[implement.jointDescIndex];
                -- check if ptoControl has leverAnimation 
                if ptoControl ~= nil and ptoControl.leverAnimation ~= nil then
                    if implement.object == self then
                        -- run animation 
                        local speed = -1;
                        if isTurnedOn then
                            speed = 1;
                        end;
                        attacherVehicle:playAnimation(ptoControl.leverAnimation.animationName, speed, attacherVehicle:getAnimationTime(ptoControl.leverAnimation.animationName), true);
                    end;
                end;
            end;
        end;
    end;

end;

TurnOnVehicle.setIsTurnedOn = Utils.overwrittenFunction(TurnOnVehicle.setIsTurnedOn, sic_ptoControl.setIsTurnedOnAppend);

