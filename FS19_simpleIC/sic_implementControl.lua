-- SimpleIC ImplementControl
-- to control Implements via SimpleIC

sic_implementControl = {};

function sic_implementControl.prerequisitesPresent(specializations)
    return true;
end;

function sic_implementControl.registerEventListeners(vehicleType)	
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", sic_implementControl);
end;

function sic_implementControl:onLoad(savegame)
	self.loadImplementControl = sic_implementControl.loadImplementControl;
    self.setImplementControl = sic_implementControl.setImplementControl;
    
    -- access tables
    if self.sic_at == nil then
        self.sic_at = {};
    end;
    self.sic_at.attacherIndex_implementControl = {};
    self.sic_at.implementControl = {};  
end;


function sic_implementControl:loadImplementControl(key, table)
    local implementControl = {};

    implementControl.attacherIndices = StringUtil.splitString(" ", getXMLString(self.xmlFile, key.."#attacherIndices")); 
    implementControl.controlSelf = getXMLBool(self.xmlFile, key.."#controlSelf")
    implementControl.isType = {}
    if #implementControl.attacherIndices > 0 or implementControl.controlSelf then

        for _ , attacherIndex in pairs(implementControl.attacherIndices) do
            self.sic_at.attacherIndex_implementControl[tonumber(attacherIndex)] = implementControl; 
        end;

        implementControl.types = StringUtil.splitString(" ", getXMLString(self.xmlFile, key.."#types"));

        for _, type in pairs(implementControl.types) do
            implementControl.isType[type] = true;
        end;
        
        local animationName = getXMLString(self.xmlFile, key..".leverAnimation#animationName");
        if animationName ~= "" and animationName ~= nil then
            implementControl.leverAnimation = {};
            implementControl.leverAnimation.animationName = animationName;
            implementControl.leverAnimation.doNotSynch = getXMLBool(self.xmlFile, key..".leverAnimation#doNotSynch");
        end;

        table.implementControl = implementControl;
        return true;
    end;

end;


function sic_implementControl:setImplementControl(wantedState, i)
    local implementControl = self.spec_simpleIC.icFunctions[i].implementControl;

    local currentObject = nil;

    -- if we are controlSelf than currentObject will be self 
    if implementControl.controlSelf then 
        currentObject = self;
    else
        -- cycle through all attacherIndices of the current function
        for _, attacherIndex in pairs(implementControl.attacherIndices) do
            -- cycle through all attacher implements to see if we find a match
            for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
                -- if we found a match, "secure" that as our current implement
                if tostring(implement.jointDescIndex) == attacherIndex then 
                    currentObject = implement.object;
                    break;
                end;

            end;
            if currentObject ~= nil then
                break;
            end;
        end;
    end;

    -- now that we find the prioritised object, find the priority function
    for _, type in pairs(implementControl.types) do

        if type == "fold" then
            -- try do the folding stuffs
            if currentObject.spec_foldable ~= nil then
                if #currentObject.spec_foldable.foldingParts > 0 then
                    local toggleDirection = Utils.getNoNil(wantedState, currentObject:getToggledFoldDirection());
                    if toggleDirection == currentObject.spec_foldable.turnOnFoldDirection then
                        currentObject:setFoldState(toggleDirection, true);
                    else
                        currentObject:setFoldState(toggleDirection, false);
                    end;
                    break; -- we done, we break
                end;
            end;
        end;

        if type == "tip" then

            print("tiiiiip")

        end;

    end;

end;


function sic_implementControl.setFoldStateAppend(self, superFunc, direction, moveToMiddle, noEventSend)

    local returnValues = superFunc(self, direction, moveToMiddle, noEventSend);

    -- if we are an implement, we need to get our attacherVehicle 
    if self.getAttacherVehicle ~= nil then
        local attacherVehicle = self:getAttacherVehicle()
        -- check if attacherVehicle has simpleIC
        if attacherVehicle ~= nil and attacherVehicle.spec_simpleIC ~= nil and attacherVehicle.spec_simpleIC.hasIC then
            -- run through implements attached to attacherVehicle to find out attacherIndex 
            for _, implement in pairs(attacherVehicle.spec_attacherJoints.attachedImplements) do
                if implement.object == self then
                    local implementControl = attacherVehicle.sic_at.attacherIndex_implementControl[implement.jointDescIndex];
                    if implementControl ~= nil and implementControl.isType["fold"] and implementControl.leverAnimation ~= nil then
                        -- run animation 
                        attacherVehicle:playAnimation(implementControl.leverAnimation.animationName, direction, attacherVehicle:getAnimationTime(implementControl.leverAnimation.animationName), true);
                    end;
                end;
            end;
        end;
    end;

    return returnValues;
end;

Foldable.setFoldState = Utils.overwrittenFunction(Foldable.setFoldState, sic_implementControl.setFoldStateAppend);