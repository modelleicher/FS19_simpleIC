-- SimpleIC Attacher Control
-- to control lowering/raising of implements attached to vehicles attacher

sic_attacherControl = {};

function sic_attacherControl.prerequisitesPresent(specializations)
    return true;
end;

function sic_attacherControl.registerEventListeners(vehicleType)	
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", sic_attacherControl);
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", sic_attacherControl);
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", sic_attacherControl);

    SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", sic_attacherControl);    
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", sic_attacherControl);    
end;

function sic_attacherControl:onPreDetachImplement(implement)
    for _ , icFunction in pairs(self.spec_simpleIC.icFunctions) do
        if icFunction.attacherControl ~= nil and icFunction.attacherControl.attacherIndex == implement.jointDescIndex then
            icFunction.attacherControl.isImplementAttached = false;

            if icFunction.leverAnimation ~= nil then
                local leverAnimation = icFunction.leverAnimation;
        
                local animTime = self:getAnimationTime(leverAnimation.animationName);
        
                if animTime > leverAnimation.detachedAnimTime then
                    self:playAnimation(leverAnimation.animationName, -1, animTime, true);
                    self:setAnimationStopTime(leverAnimation.animationName, leverAnimation.detachedAnimTime);
                elseif animTime < leverAnimation.detachedAnimTime then
                    self:playAnimation(leverAnimation.animationName, 1, animTime, true);
                    self:setAnimationStopTime(leverAnimation.animationName, leverAnimation.detachedAnimTime);           
                end;
            end;      
        end;
    end;
end;

function sic_attacherControl:onPostAttachImplement(inputJointDescIndex, jointDescIndex)

    for _ , icFunction in pairs(self.spec_simpleIC.icFunctions) do
        if icFunction.attacherControl ~= nil and icFunction.attacherControl.attacherIndex == jointDescIndex then
            icFunction.attacherControl.isImplementAttached = true;
            
            if icFunction.leverAnimation ~= nil then
                local leverAnimation = icFunction.leverAnimation;
        
                local animTime = self:getAnimationTime(leverAnimation.animationName);
                self:playAnimation(leverAnimation.animationName, -1, animTime, true);
            end;                  
        end;
    end;

end;

function sic_attacherControl:onLoad(savegame)
	self.loadAttacherControl = sic_attacherControl.loadAttacherControl;
    self.setAttacherControl = sic_attacherControl.setAttacherControl;

    self.sic_attacherControl = {};

    self.sic_attacherControl.attacherIndexToICFunction = {};
    
end;

function sic_attacherControl:onPostLoad(savegame)
    for _ , icFunction in pairs(self.spec_simpleIC.icFunctions) do
        if icFunction.attacherControl and icFunction.attacherControl.leverAnimation ~= nil and not icFunction.attacherControl.isImplementAttached then
            local leverAnimation = icFunction.attacherControl.leverAnimation;
            local animTime = self:getAnimationTime(leverAnimation.animationName);
            if animTime > leverAnimation.detachedAnimTime then
                self:playAnimation(leverAnimation.animationName, -1, animTime, true);
                self:setAnimationStopTime(leverAnimation.animationName, leverAnimation.detachedAnimTime);
            elseif animTime < leverAnimation.detachedAnimTime then
                self:playAnimation(leverAnimation.animationName, 1, animTime, true);
                self:setAnimationStopTime(leverAnimation.animationName, leverAnimation.detachedAnimTime);           
            end;          
        end;
    end;
end;


function sic_attacherControl:onUpdateTick(dt)
    if self:getIsActive() then

        -- code for centering lever after lowering or raising depending on setting in XML 
        for _ , icFunction in pairs(self.spec_simpleIC.icFunctions) do
            if icFunction.attacherControl and icFunction.attacherControl.leverAnimation ~= nil then
                if icFunction.attacherControl.attacherIndex ~= nil then
                    local jointDesc = self.spec_attacherJoints.attacherJoints[icFunction.attacherControl.attacherIndex]

                    if jointDesc.moveAlpha ~= nil then
                    
                        local moveAlpha = Utils.getMovedLimitedValue(jointDesc.moveAlpha, jointDesc.lowerAlpha, jointDesc.upperAlpha, jointDesc.moveTime, dt, not jointDesc.moveDown)

                        local leverAnimation = icFunction.attacherControl.leverAnimation;

                        if moveAlpha ~= leverAnimation.moveAlpha then
                            if (moveAlpha == 1 or moveAlpha == 0) and leverAnimation.returnToCenter then

                                local animTime = self:getAnimationTime(leverAnimation.animationName);
                                if animTime > 0.5 then
                                    self:playAnimation(leverAnimation.animationName, -1, animTime, true);
                                    self:setAnimationStopTime(leverAnimation.animationName, 0.5)
                                elseif animTime < 0.5 then
                                    self:playAnimation(leverAnimation.animationName, 1, animTime, true);
                                    self:setAnimationStopTime(leverAnimation.animationName, 0.5)                               
                                end;

                            elseif moveAlpha == 0 and leverAnimation.returnToCenterRaised then
                                local animTime = self:getAnimationTime(leverAnimation.animationName);

                                if animTime < 0.5 then
                                    self:playAnimation(leverAnimation.animationName, 1, animTime, true);
                                    self:setAnimationStopTime(leverAnimation.animationName, 0.5)
                                end;
                            elseif moveAlpha == 1 and leverAnimation.returnToCenterLowered then
                                local animTime = self:getAnimationTime(leverAnimation.animationName);

                                if animTime > 0.5 then
                                    self:playAnimation(leverAnimation.animationName, -1, animTime, true);
                                    self:setAnimationStopTime(leverAnimation.animationName, 0.5)
                                end;
                            end;
                            leverAnimation.moveAlpha = moveAlpha;
                        end;
                    end;
                end;
            end;
        end;
    end;
end;





function sic_attacherControl:loadAttacherControl(key, table)
    -- load attacherControl attributes
	local attacherControl = {}
	attacherControl.attacherIndex = getXMLInt(self.xmlFile, key.."#attacherIndex");
	if attacherControl.attacherIndex ~= nil then

		local animationName = getXMLString(self.xmlFile, key..".leverAnimation#animationName");
        if animationName ~= "" and animationName ~= nil then

            attacherControl.leverAnimation = {};
			attacherControl.leverAnimation.animationName = animationName;
            attacherControl.leverAnimation.doNotSynch = getXMLBool(self.xmlFile, key..".leverAnimation#doNotSynch");
            
            attacherControl.leverAnimation.returnToCenter = getXMLBool(self.xmlFile, key..".leverAnimation#returnToCenter");
            attacherControl.leverAnimation.returnToCenterRaised = getXMLBool(self.xmlFile, key..".leverAnimation#returnToCenterRaised");
            attacherControl.leverAnimation.returnToCenterLowered = getXMLBool(self.xmlFile, key.."leverAnimation#returnToCenterLowered");

            attacherControl.leverAnimation.detachedAnimTime = Utils.getNoNil(getXMLFloat(self.xmlFile, key..".leverAnimation#detachedAnimTime"), 1);

            attacherControl.leverAnimation.moveAlpha = 0.5;

        end;

        self.sic_attacherControl.attacherIndexToICFunction[attacherControl.attacherIndex] = table;
        
		table.attacherControl = attacherControl;
		return true;
	end;

end;

function sic_attacherControl:setAttacherControl(wantedState, i)
    -- gets called when IC trigger is triggered
	local attacherControl = self.spec_simpleIC.icFunctions[i].attacherControl;
	local spec_attacherJoints = self.spec_attacherJoints;

	if spec_attacherJoints.attacherJoints[attacherControl.attacherIndex] ~= nil and attacherControl.isImplementAttached then
		if wantedState == nil then
			wantedState = not spec_attacherJoints.attacherJoints[attacherControl.attacherIndex].moveDown
		end;

		self:setJointMoveDown(attacherControl.attacherIndex, wantedState)

        if attacherControl.leverAnimation ~= nil and attacherControl.leverAnimation.doNotSynch then
			local speed = 1;
			if not wantedState then
				speed = -1;
			end;
			self:playAnimation(attacherControl.leverAnimation.animationName, speed, self:getAnimationTime(attacherControl.leverAnimation.animationName), true);	
		end;

	end;
end;

function sic_attacherControl.setJointMoveDownAppend(self, superFunc, jointDescIndex, moveDown, noEventSend)

    superFunc(self, jointDescIndex, moveDown, noEventSend);


    -- code for running animation if attacher is raised/lowered
    if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then
        for _ , icFunction in pairs(self.spec_simpleIC.icFunctions) do
            if icFunction.attacherControl and icFunction.attacherControl.leverAnimation ~= nil then
                if icFunction.attacherControl.attacherIndex == jointDescIndex then
                    local speed = -1;
                    if moveDown then
                        speed = 1;
                    end;
                    self:playAnimation(icFunction.attacherControl.leverAnimation.animationName, speed, self:getAnimationTime(icFunction.attacherControl.leverAnimation.animationName), true);         
                end;
            end;
        end;
    end;

end;
AttacherJoints.setJointMoveDown = Utils.overwrittenFunction(AttacherJoints.setJointMoveDown, sic_attacherControl.setJointMoveDownAppend);
