-- by modelleicher
-- 13.04.2019

-- Script for Interactive Control. Released on Github January 2020.


simpleIC = {};

function simpleIC.prerequisitesPresent(specializations)
    return true;
end;



function simpleIC.registerEventListeners(vehicleType)	
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", simpleIC);
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", simpleIC);
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", simpleIC);
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", simpleIC);
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", simpleIC);	
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", simpleIC);
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", simpleIC);	
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", simpleIC);
	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", simpleIC);	
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", simpleIC);	
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", simpleIC);		
end;


function simpleIC.onRegisterActionEvents(self, isActiveForInput)
	local spec = self.spec_simpleIC;
	spec.actionEvents = {}; 
	self:clearActionEventsTable(spec.actionEvents); 	

	if self:getIsActive() and self.spec_simpleIC.hasIC then
		self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_ONOFF, self, simpleIC.TOGGLE_ONOFF, true, true, false, true, nil);
		if spec.icTurnedOn_inside then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.INTERACT_IC_VEHICLE, self, simpleIC.INTERACT, true, true, false, true, nil);
			g_inputBinding:setActionEventTextVisibility(actionEventId, false);
			spec.interactionButtonActive = true;
		end;
	end;	
end;

function simpleIC:onLoad(savegame)
	self.setICAnimation = simpleIC.setICAnimation;
	self.outsideInteractionTriggerCallback = simpleIC.outsideInteractionTriggerCallback;
	self.updateSoundAttributes = simpleIC.updateSoundAttributes;
	self.addSoundChangeIndex = simpleIC.addSoundChangeIndex;
	self.renderTextAtProjectedPosition = simpleIC.renderTextAtProjectedPosition;
	self.checkInteraction = simpleIC.checkInteraction;
	self.updateActionEventsSIC = simpleIC.updateActionEventsSIC;
	self.setICState = simpleIC.setICState;
	self.resetCanBeTriggered = simpleIC.resetCanBeTriggered;
	self.doInteraction = simpleIC.doInteraction;
	self.isCameraInsideCheck = simpleIC.isCameraInsideCheck;
	self.loadAnimation = simpleIC.loadAnimation;
	self.loadAttacherControl = simpleIC.loadAttacherControl;	
	self.loadICFunctions = simpleIC.loadICFunctions;
	self.setAttacherControl = simpleIC.setAttacherControl;
	self.loadPTOControl = simpleIC.loadPTOControl;
	self.setPTOControl = simpleIC.setPTOControl;

	self.spec_simpleIC = {};
	
	local spec = self.spec_simpleIC; 
	
	-- for now all we have is animations, no other types of functions 
	spec.icFunctions = {};
	
	-- load the animations from XML 
	self:loadICFunctions("vehicle.simpleIC.animation", self.loadAnimation)

	-- load attacherControl 
	self:loadICFunctions("vehicle.simpleIC.attacherControl", self.loadAttacherControl)

	-- load pto control 
	self:loadICFunctions("vehicle.simpleIC.ptoControl", self.loadPTOControl)

	
	if #spec.icFunctions > 0 then
		spec.hasIC = true;

		spec.outsideInteractionTrigger = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.simpleIC#outsideInteractionTrigger"), self.i3dMappings);
		
		spec.playerInOutsideInteractionTrigger = false;
		
		spec.interactionMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.simpleIC#interactionMarker"), self.i3dMappings)

		if spec.outsideInteractionTrigger ~= nil then
			spec.outsideInteractionTriggerId = addTrigger(spec.outsideInteractionTrigger, "outsideInteractionTriggerCallback", self);   
		end;
		
		spec.soundVolumeIncreasePercentageAll = 1;
		spec.soundChangeIndexList = {};	

		spec.reachDistance = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.simpleIC#reachDistance"), 1.8)


		-- 
		spec.icTurnedOn_inside = false; 
		spec.icTurnedOn_outside = false;

		spec.icTurnedOn_inside_backup = false;	
		
		spec.interact_present = false;
		spec.interact_default = false;

		if self.spec_motorized ~= nil then -- back up samples if we are a motorized vehicle
			for i, sample in pairs(self.spec_motorized.samples) do
				sample.indoorAttributes.volumeBackup = sample.indoorAttributes.volume;		
			end;
			for i, sample in pairs(self.spec_motorized.motorSamples) do
				sample.indoorAttributes.volumeBackup = sample.indoorAttributes.volume;
			end;	
		end;
	end;

	spec.cylinderAnimations = {};
	local c = 0;
	while true do
		local node1 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.simpleIC.cylinderAnimations.cylinder("..c..")#node1"), self.i3dMappings)
		local node2 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.simpleIC.cylinderAnimations.cylinder("..c..")#node2"), self.i3dMappings)
		if node1 ~= nil and node2 ~= nil then
			spec.cylinderAnimations[c+1] = {node1 = node1, node2 = node2}
		else	
			break;
		end;

		c = c + 1;
	end;
end;

function simpleIC:loadICFunctions(keyOrig, loadFunc)
	local spec = self.spec_simpleIC;
	local i = 0;
	while true do
		local icFunction = {};
		local hasFunction = false;
		local key = keyOrig.."("..i..")"

		print(key)
	
		hasFunction = loadFunc(self, key, icFunction);

		print(hasFunction)

		if hasFunction then
			icFunction.currentState = false;
	
			icFunction.inTP = {};
			icFunction.inTP.triggerPoint = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key..".insideTrigger#triggerPoint"), self.i3dMappings);
			icFunction.inTP.triggerPointRadius = Utils.getNoNil(getXMLFloat(self.xmlFile, key..".insideTrigger#triggerPointSize"), 0.04);
			icFunction.inTP.triggerDistance = Utils.getNoNil(getXMLFloat(self.xmlFile, key..".insideTrigger#triggerDistance"), 1);
			
			if icFunction.inTP.triggerPoint == nil then
				icFunction.inTP.triggerPoint_ON = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key..".insideTrigger#triggerPoint_ON"), self.i3dMappings);
				icFunction.inTP.triggerPoint_OFF = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key..".insideTrigger#triggerPoint_OFF"), self.i3dMappings);
			end;
			
			
			icFunction.outTP = {};
			icFunction.outTP.triggerPoint = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key..".outsideTrigger#triggerPoint"), self.i3dMappings);
			icFunction.outTP.triggerPointRadius = Utils.getNoNil(getXMLFloat(self.xmlFile, key..".outsideTrigger#triggerPointSize"), 0.04);
			icFunction.outTP.triggerDistance = Utils.getNoNil(getXMLFloat(self.xmlFile, key..".outsideTrigger#triggerDistance"), 1);
		
			if icFunction.outTP.triggerPoint == nil then
				icFunction.outTP.triggerPoint_ON = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key..".outsideTrigger#triggerPoint_ON"), self.i3dMappings);
				icFunction.outTP.triggerPoint_OFF = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key..".outsideTrigger#triggerPoint_OFF"), self.i3dMappings);
			end;
			
			table.insert(spec.icFunctions, icFunction);
		else
			break;
		end;
		i = i+1;
	end;

end;

function simpleIC:loadPTOControl(key, table)
	local ptoControl ={};
	ptoControl.attacherIndex = getXMLInt(self.xmlFile, key.."#attacherIndex");
	if ptoControl.attacherIndex ~= nil then

		local leverAnimation = getXMLString(self.xmlFile, key.."#leverAnimation");
		if leverAnimation ~= "" and leverAnimation ~= nil then
			ptoControl.leverAnimation = leverAnimation;
			ptoControl.leverAnimationState = false;
		end;

		table.ptoControl = ptoControl;
		return true;
	end;
end;

function simpleIC:loadAttacherControl(key, table)

	local attacherControl = {}
	attacherControl.attacherIndex = getXMLInt(self.xmlFile, key.."#attacherIndex");
	if attacherControl.attacherIndex ~= nil then

		local leverAnimation = getXMLString(self.xmlFile, key.."#leverAnimation");
		if leverAnimation ~= "" and leverAnimation ~= nil then
			attacherControl.leverAnimation = leverAnimation;
			attacherControl.leverAnimationState = false;
		end;

		table.attacherControl = attacherControl;
		return true;
	end;

end;

function simpleIC:loadAnimation(key, table)

	local anim = {};
	anim.animationName = getXMLString(self.xmlFile, key.."#animationName");
	if anim.animationName ~= "" and anim.animationName ~= nil then
		
		anim.animationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, key.."#animationSpeed"), 1);
		anim.sharedAnimation = Utils.getNoNil(getXMLBool(self.xmlFile, key.."#sharedAnimation"), false);
		anim.currentState = false;
		
		if not anim.sharedAnimation then
			self:playAnimation(anim.animationName, -anim.animationSpeed, self:getAnimationTime(anim.animationName), true);
		end;
		
		anim.duration = self:getAnimationDuration(anim.animationName);
		anim.soundVolumeIncreasePercentage = Utils.getNoNil(getXMLFloat(self.xmlFile, key.."#soundVolumeIncreasePercentage"), false);
		
		table.animation = anim;
		return true;
	end;

	return false;
end;

function simpleIC:onEnterVehicle(isControlling, playerStyle, farmId)
	local spec = self.spec_simpleIC;
	if self.spec_enterable ~= nil and spec.hasIC then

		local inside = self:isCameraInsideCheck();
		if inside then
			self:setICState(spec.icTurnedOn_inside, false);
		end;
		spec.lastCameraInside = Utils.getNoNil(inside, false);
	end;
end;

-- indoor camera -> IC is always on by default
-- outdoor camera -> IC is on when button is pressed
-- inside IC can be turned off 
-- marker turn of "globally"

function simpleIC:onPostLoad(savegame)
	if self.spec_simpleIC ~= nil and savegame ~= nil and self.spec_simpleIC.hasIC then
		local spec = self.spec_simpleIC;
		local xmlFile = savegame.xmlFile;
		
		local i = 1;
		local key1 = savegame.key..".FS19_simpleIC.simpleIC.icFunctions"
		for _, icFunction in pairs(spec.icFunctions) do
			
			-- load animation state 
			if icFunction.animation ~= nil then
				local state = getXMLBool(xmlFile, key1..".icFunction"..i.."#animationState");
				if state ~= nil then
					self:setICAnimation(state, i, true)
				end;
			end;

			if icFunction.attacherControl ~= nil then
				if icFunction.attacherControl.leverAnimation ~= nil then
					if self.spec_attacherJoints.attacherJoints[icFunction.attacherControl.attacherIndex] ~= nil then
						local wantedState = self.spec_attacherJoints.attacherJoints[icFunction.attacherControl.attacherIndex].moveDown
						local speed = 1;
						if not wantedState then
							speed = -1;
						end;
						self:playAnimation(icFunction.attacherControl.leverAnimation, speed, self:getAnimationTime(icFunction.attacherControl.leverAnimation), true);
						icFunction.attacherControl.leverAnimationState = wantedState;	
					end;
				end;
			end;
			
			i = i+1;
		end;
	end;
end;

function simpleIC:saveToXMLFile(xmlFile, key)
	if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then
		local spec = self.spec_simpleIC;
		
		local i = 1;
		local key1 = key..".icFunctions";
		for _, icFunction in pairs(spec.icFunctions) do
			-- save animations state 
			if icFunction.animation ~= nil then
				setXMLBool(xmlFile, key1..".icFunction"..i.."#animationState", icFunction.animation.currentState);
			end;
			i = i+1;
		end;

	end;
end;

function simpleIC:onReadStream(streamId, connection)
	local spec = self.simpleIC
	if spec ~= nil and spec.hasIC then
		if connection:getIsServer() then
			for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do
				if icFunction.animation ~= nil then
					local state = streamReadBool(streamId)
					icFunction.animation.currentState = state;
				end;	
			end;	
		end;
	end;
end

function simpleIC:onWriteStream(streamId, connection)
	local spec = self.simpleIC;
	if spec ~= nil and spec.hasIC then
		if not connection:getIsServer() then
			for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do
				if icFunction.animation ~= nil then
					streamWriteBool(streamId, icFunction.animation.currentState)
				end;
			end;
		end;
	end;
end

function simpleIC:onDelete()
	local spec = self.spec_simpleIC;
	if spec.outsideInteractionTrigger ~= nil then
		removeTrigger(spec.outsideInteractionTrigger)
	end;
end;

function simpleIC:INTERACT(actionName, inputValue)
	if inputValue > 0.5 then
		self.spec_simpleIC.interact_default = true;
		if not self.spec_simpleIC.interact_present then 
			self:doInteraction()
		end;	
	else
		self.spec_simpleIC.interact_default = false;
	end;
end;

function simpleIC:setPTOControl(wantedState, i)
	local ptoControl = self.spec_simpleIC.icFunctions[i].ptoControl;

	for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
		if implement.jointDescIndex == ptoControl.attacherIndex then
			if implement.object.spec_turnOnVehicle ~= nil then
				if wantedState == nil then
					wantedState = not implement.object.spec_turnOnVehicle.isTurnedOn;
				end;
				implement.object:setIsTurnedOn(wantedState)
				if ptoControl.leverAnimation ~= nil and speed ~= 0 then
					local speed = 1;
					if not wantedState then
						speed = -1;
					end;
					self:playAnimation(ptoControl.leverAnimation, speed, self:getAnimationTime(ptoControl.leverAnimation), true);
					ptoControl.leverAnimationState = wantedState;			
				end;				
			end;
		end;
	end;
end;

function simpleIC:setAttacherControl(wantedState, i)
	local attacherControl = self.spec_simpleIC.icFunctions[i].attacherControl;
	local spec_attacherJoints = self.spec_attacherJoints;

	if spec_attacherJoints.attacherJoints[attacherControl.attacherIndex] ~= nil then

		if wantedState == nil then
			wantedState = not spec_attacherJoints.attacherJoints[attacherControl.attacherIndex].moveDown
		end;

		self:setJointMoveDown(attacherControl.attacherIndex, wantedState)

		if attacherControl.leverAnimation ~= nil and speed ~= 0 then
			local speed = 1;
			if not wantedState then
				speed = -1;
			end;
			self:playAnimation(attacherControl.leverAnimation, speed, self:getAnimationTime(attacherControl.leverAnimation), true);
			attacherControl.leverAnimationState = wantedState;			
		end;

	end;
end;

		
function simpleIC:doInteraction()
	local spec = self.spec_simpleIC;

	if spec ~= nil and spec.hasIC then
		if spec.icTurnedOn_inside or spec.icTurnedOn_outside or spec.playerInOutsideInteractionTrigger then
			local i = 1;
			for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do
				if icFunction.canBeTriggered then
					-- trigger animation 
					if icFunction.animation ~= nil then
						self:setICAnimation(not icFunction.animation.currentState, i);
					end;

					if icFunction.attacherControl ~= nil then
						self:setAttacherControl(nil, i)
					end;

					if icFunction.ptoControl ~= nil then
						self:setPTOControl(nil, i)
					end;
				end;
				if icFunction.canBeTriggered_ON then
					if icFunction.animation ~= nil then
						self:setICAnimation(true, i);
					end;
					if icFunction.attacherControl ~= nil then
						self:setAttacherControl(true, i)
					end;
					if icFunction.ptoControl ~= nil then
						self:setPTOControl(true, i)
					end;										
				end;			
				if icFunction.canBeTriggered_OFF then
					if icFunction.animation ~= nil then
						self:setICAnimation(false, i);
					end;
					if icFunction.attacherControl ~= nil then
						self:setAttacherControl(false, i)
					end;	
					if icFunction.ptoControl ~= nil then
						self:setPTOControl(false, i)
					end;										
				end;			
				i = i+1;
			end;	
		end;
	end;

	-- implement balls
	if self.spec_implementBalls ~= nil then
		local spec1 = self.spec_implementBalls;
		for index, implementJoint in pairs(spec1.implementJoints) do
			if implementJoint.canBeClicked then
				self:setImplementBalls(index)
			end;
		end;
	end;
end

-- returns true if camera is inside, returns false if camera is not inside, returns nil if active camera is nil
function simpleIC:isCameraInsideCheck()
	if self.spec_enterable ~= nil and self.getActiveCamera ~= nil then
		local activeCamera = self:getActiveCamera();
		if activeCamera ~= nil then
			return activeCamera.isInside;
		end;
	end;
	return nil;
end;

function simpleIC:TOGGLE_ONOFF(actionName, inputValue)
	local spec = self.spec_simpleIC;
	if spec ~= nil and spec.hasIC and self.getAttacherVehicle == nil then 
		if not self:isCameraInsideCheck() then
			if inputValue == 1 then
				self:setICState(true, true);
			else
				self:setICState(false, true);
			end;
		else
			if inputValue == 1 then
				self:setICState(not spec.icTurnedOn_inside, false);
			end;
		end;
	end;
end;


function simpleIC:setICState(wantedState, wantedOutside)
	local spec = self.spec_simpleIC;

	if wantedState ~= nil and wantedOutside ~= nil then
		if wantedOutside then
			spec.icTurnedOn_inside = false;
			spec.icTurnedOn_outside = wantedState;
			g_inputBinding:setShowMouseCursor(wantedState)
			self.spec_enterable.cameras[self.spec_enterable.camIndex].isActivated = not wantedState;
		else
			spec.icTurnedOn_outside = false;
			spec.icTurnedOn_inside = wantedState;
			g_inputBinding:setShowMouseCursor(false)
			self.spec_enterable.cameras[self.spec_enterable.camIndex].isActivated = true;			
		end;

		if wantedState then 
			if not spec.interactionButtonActive then
				local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.INTERACT_IC_VEHICLE, self, simpleIC.INTERACT, true, false, false, true, nil);
				g_inputBinding:setActionEventTextVisibility(actionEventId, false);
				spec.interactionButtonActive = true;
			end;	
		else
			if spec.interactionButtonActive then
				self:removeActionEvent(spec.actionEvents, InputAction.INTERACT_IC_VEHICLE);
				spec.interactionButtonActive = false;
			end;		
		end;
	end;

end;

function simpleIC:onUpdate(dt)

	if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then

		local spec = self.spec_simpleIC;
		if self.spec_simpleIC.playerInOutsideInteractionTrigger then
			self:checkInteraction()
			self:raiseActive() -- keep vehicle awake as long as player is in trigger 
		end;
		
        -- we need to track camera changes from inside to outside and adjust IC accordingly 
		if self:getIsActiveForInput(true) then
			-- if isInside is true and outside turned on or vice versa we changed camera 
			local inside = self:isCameraInsideCheck()
			if inside ~= nil and inside ~= spec.lastCameraInside then 
				-- if we toggled from inside to outside, store inside state in backup variable and turn off inside 
				if not inside then
					spec.icTurnedOn_inside_backup = spec.icTurnedOn_inside;
                    self:setICState(false, true);
                else -- if we toggled to inside restore backup value 
                    self:setICState(spec.icTurnedOn_inside_backup, false);
				end;
				spec.lastCameraInside = inside;
				self:resetCanBeTriggered();
			end;
		end;

		if #spec.cylinderAnimations > 0 then
			for i=1, #spec.cylinderAnimations do
				local node1 = spec.cylinderAnimations[i].node1;
				local node2 = spec.cylinderAnimations[i].node2;

				local ax, ay, az = getWorldTranslation(node1);
				local bx, by, bz = getWorldTranslation(node2);	
				x, y, z = worldDirectionToLocal(getParent(node1), bx-ax, by-ay, bz-az);

				local ux, uy, uz = localDirectionToWorld(node1, 0,1,0)
				ux, uy, uz = worldDirectionToLocal(getParent(node1), ux, uy, uz)

				setDirection(node1, x, y, z, ux, uy, uz);

				local ax2, ay2, az2 = getWorldTranslation(node2);
				local bx2, by2, bz2 = getWorldTranslation(node1);
				x2, y2, z2 = worldDirectionToLocal(getParent(node2), bx2-ax2, by2-ay2, bz2-az2);
				
				local ux2, uy2, uz2 = localDirectionToWorld(node2, 0,1,0)
				ux2, uy2, uz2 = worldDirectionToLocal(getParent(node2), ux2, uy2, uz2)		
				
				setDirection(node2, x2, y2, z2, ux2, uy2, uz2); 				
			end;
		end;
	end;
end;

function simpleIC:resetCanBeTriggered()
	for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do -- reset all the IC-Functions so they can't be triggered 
		icFunction.canBeTriggered = false;
		icFunction.canBeTriggered_ON = false;
		icFunction.canBeTriggered_OFF = false;
	end;
end;

function simpleIC:onLeaveVehicle()
	if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then
		self:resetCanBeTriggered();
		self.spec_simpleIC.interactionButtonActive = false;
	end;
end;

function simpleIC:setICAnimation(wantedState, animationIndex, noEventSend)
    setICAnimationEvent.sendEvent(self, wantedState, animationIndex, noEventSend);
	local animation = self.spec_simpleIC.icFunctions[animationIndex].animation;
	local spec = self.spec_simpleIC;
	
    if wantedState then -- if currentState is true (max) then play animation to min
        self:playAnimation(animation.animationName, animation.animationSpeed, self:getAnimationTime(animation.animationName), true);
        animation.currentState = true;
		self:addSoundChangeIndex(animationIndex);
    else    
        self:playAnimation(animation.animationName, -animation.animationSpeed, self:getAnimationTime(animation.animationName), true);
        animation.currentState = false;	
		self:addSoundChangeIndex(animationIndex);
    end;
	
	if self.spec_motorized ~= nil then
		spec.soundVolumeIncreasePercentageAll = math.max(1, spec.soundVolumeIncreasePercentageAll);
	end;

end;

-- goal
-- sound volume needs to change dynamically while the animation is playing 
-- sound volume needs to change globally with multiple animations playing at the same time 

-- so when we activate an animation we add that animation index to a sound update index list 

function simpleIC:addSoundChangeIndex(index)
	if self.spec_motorized ~= nil then
		local animation =  self.spec_simpleIC.icFunctions[index].animation;
		if animation.soundVolumeIncreasePercentage ~= false then -- check if this even has sound change effects 
			-- now add it to the table 
			self.spec_simpleIC.soundChangeIndexList[index] = animation; -- we add it at the index of the animation that way if we try adding the same animation twice it does overwrite itself 
		end;
	end;
end;

-- next we want to run through that list, get the current animation status of that animation and update the sound volume value 
-- if the animation stopped playing, remove it from the list 

function simpleIC:updateSoundAttributes()
	local spec = self.spec_simpleIC;
	local soundVolumeIncreaseAll = 0;
	local updateSound = false;
	for _, animation in pairs(spec.soundChangeIndexList) do
		-- get time
		local animationTime = self:getAnimationTime(animation.animationName);
		-- get current sound volume increase 
		local soundVolumeIncrease = animation.soundVolumeIncreasePercentage * (animationTime ^ 0.5);
		soundVolumeIncreaseAll = soundVolumeIncreaseAll + soundVolumeIncrease;
		if animationTime == 1 or animationTime == 0 then
			animation = nil; -- delete animation from index table if we reached max pos or min pos 
		end;
		updateSound = true;
	end;
	
	if updateSound then
		for i, sample in pairs(self.spec_motorized.samples) do
			sample.indoorAttributes.volume = math.min(sample.indoorAttributes.volumeBackup * (1 + soundVolumeIncreaseAll), sample.outdoorAttributes.volume);
		end;
		for i, sample in pairs(self.spec_motorized.motorSamples) do
			sample.indoorAttributes.volume =  math.min(sample.indoorAttributes.volumeBackup * (1 + soundVolumeIncreaseAll), sample.outdoorAttributes.volume);
		end;	
	end;
end;

function simpleIC:outsideInteractionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local spec = self.spec_simpleIC;

	if onEnter and g_currentMission.controlPlayer and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		spec.playerInOutsideInteractionTrigger = true;	
		self:raiseActive()
		spec.actionEvents = {}; -- create actionEvents table since in case we didn't enter the vehicle yet it does not exist 
		self:clearActionEventsTable(spec.actionEvents); -- also clear it for good measure 
		local _ , eventId = self:addActionEvent(spec.actionEvents, InputAction.INTERACT_IC_ONFOOT, self, simpleIC.INTERACT, false, true, false, true);	-- now add the actionEvent 	
	elseif onLeave and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		spec.playerInOutsideInteractionTrigger = false;
		self:removeActionEvent(spec.actionEvents, InputAction.INTERACT_IC_ONFOOT);	-- remove the actionEvent again once we leave the trigger 
	end;
end;

function simpleIC:onDraw()
	self:checkInteraction()
end;

function simpleIC:checkInteraction()
	if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then
		local spec = self.spec_simpleIC;
		
		self:updateSoundAttributes(); 
		
		-- we need to check the positions of our triggerPoints if 
		-- + somebody is in the outsideInteractionTrigger
		-- + the vehicle is active and simpleIC is active 
		if (self:getIsActive() and spec.icTurnedOn_inside) or (self:getIsActive() and spec.icTurnedOn_outside) or spec.playerInOutsideInteractionTrigger then -- check the points 
			
			-- see if we need to check the outside or the inside points 
			-- see if we are inside the vehicle or not 
			local isInside = false;
			local isPlayerTrigger = false;
			if spec.playerInOutsideInteractionTrigger then 
				isPlayerTrigger = true;
			end;

			if not isPlayerTrigger then
				if self:getActiveCamera() ~= nil and self:getActiveCamera().isInside then
					isInside = true;
				end;
			end;
			
			if not spec.playerInOutsideInteractionTrigger and not spec.icTurnedOn_outside then -- don't render the crosshair if we are outside 
				renderText(0.5, 0.5, 0.02, "+");
			end;
			
			-- go through all the functions 
			local index = 0;
			for _, icFunction in pairs(spec.icFunctions) do
				index = index + 1;
				-- get inside or outside trigger points depending on if we're inside or outside 
				local tp = icFunction.inTP;
				if not isInside then
					tp = icFunction.outTP;
				end;
				


				if tp.triggerPoint ~= nil or tp.triggerPoint_ON ~= nil or tp.triggerPoint_OFF ~= nil then
					
					local triggerPoint = {};
					triggerPoint[1] = tp.triggerPoint;

					if tp.triggerPoint_OFF ~= nil and tp.triggerPoint_ON ~= nil then -- multiple trigger points 
						triggerPoint[2] = tp.triggerPoint_ON;
						triggerPoint[3] = tp.triggerPoint_OFF;
					end;

					-- set it to false by default 
					icFunction.canBeTriggered = false;
					icFunction.canBeTriggered_ON = false;
					icFunction.canBeTriggered_OFF = false;					

					for index , triggerPoint in pairs(triggerPoint) do 

						-- get visibility of our trigger-point, if it is invisible its deactivated 
						if getVisibility(triggerPoint) then

							-- get world translation of our trigger point, then project it to the screen 
							local wX, wY, wZ = getWorldTranslation(triggerPoint);
							local cameraNode = 0;
							if spec.playerInOutsideInteractionTrigger then
								cameraNode = g_currentMission.player.cameraNode
							else
								cameraNode = self:getActiveCamera().cameraNode
							end;
							local cX, cY, cZ = getWorldTranslation(cameraNode);
							local x, y, z = project(wX, wY, wZ);
							
							local dist = MathUtil.vector3Length(wX-cX, wY-cY, wZ-cZ); 
							

							if x > 0 and y > 0 and z > 0 then
							
								-- the higher the number the smaller the text should be to keep it the same size in 3d space 
								-- base size is 0.025 
								-- if the number is higher than 1, make smaller
								-- if the number is smaller than 1, make bigger
					
								local size = 0.028 / dist;
									
								-- default posX and posY is 0.5 e.g. middle of the screen for selection 
								local posX, posY, posZ = 0.5, 0.5, 0.5;
								
								-- if we have MOUSE_Mode enabled, use mouse position instead 
								if spec.icTurnedOn_outside then
									posX, posY, posZ = g_lastMousePosX, g_lastMousePosY, 0;				
								end;

								
								-- check if our position is within the position of the triggerRadius
								if posX < (x + tp.triggerPointRadius) and posX > (x - tp.triggerPointRadius) then
									if posY < (y + tp.triggerPointRadius) and posY > (y - tp.triggerPointRadius) then
										if dist < spec.reachDistance or spec.icTurnedOn_outside then
											-- can be clicked 
											if index == 1 then -- toggle mark 
												icFunction.canBeTriggered = true;
											elseif index == 2 then -- on mark 
												icFunction.canBeTriggered_ON = true;
											elseif index == 3 then -- off mark 
												icFunction.canBeTriggered_OFF = true;
											end;
											self:renderTextAtProjectedPosition(x,y,z, "X", size, 1, 0, 0)
										end;
									end;
								end;	
								if (index == 1 and not icFunction.canBeTriggered) or (index == 2 and not icFunction.canBeTriggered_ON) or (index == 3 and not icFunction.canBeTriggered_OFF) then
									self:renderTextAtProjectedPosition(x,y,z, "X", size, 1, 1, 1)
								end;
							end;
						end;
					end;
				end;
			end;
		end;
	end;

end;

function simpleIC:renderTextAtProjectedPosition(projectX,projectY,projectZ, text, textSize, r, g, b) 
    --local projectX,projectY,projectZ = project(x,y,z);
    if projectX > -1 and projectX < 2 and projectY > -1 and projectY < 2 and projectZ <= 1 then
        setTextAlignment(RenderText.ALIGN_CENTER);
        setTextBold(false);
        setTextColor(r, g, b, 1.0);
        renderText(projectX, projectY, textSize, text);
        setTextAlignment(RenderText.ALIGN_LEFT);
    end
end



setICAnimationEvent = {};
setICAnimationEvent_mt = Class(setICAnimationEvent, Event);
InitEventClass(setICAnimationEvent, "setICAnimationEvent");

function setICAnimationEvent:emptyNew()  
    local self = Event:new(setICAnimationEvent_mt );
    self.className="setICAnimationEvent";
    return self;
end;
function setICAnimationEvent:new(vehicle, wantedState, animationIndex) 
    self.vehicle = vehicle;
	self.wantedState = wantedState;
	self.animationIndex = animationIndex;
    return self;
end;
function setICAnimationEvent:readStream(streamId, connection)  
    self.vehicle = NetworkUtil.readNodeObject(streamId); 
	self.wantedState = streamReadBool(streamId); 
	self.animationIndex = streamReadUIntN(streamId, 6);
    self:run(connection);  
end;
function setICAnimationEvent:writeStream(streamId, connection)   
	NetworkUtil.writeNodeObject(streamId, self.vehicle);   
	streamWriteBool(streamId, self.wantedState ); 
	streamWriteUIntN(streamId, self.animationIndex, 6); 
end;
function setICAnimationEvent:run(connection) 
    self.vehicle:setICAnimation(self.wantedState, self.animationIndex, true);
    if not connection:getIsServer() then  
        g_server:broadcastEvent(setICAnimationEvent:new(self.vehicle, self.wantedState, self.animationIndex), nil, connection, self.object);
    end;
end;
function setICAnimationEvent.sendEvent(vehicle, wantedState, animationIndex, noEventSend) 
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then   
            g_server:broadcastEvent(setICAnimationEvent:new(vehicle, wantedState, animationIndex), nil, nil, vehicle);
        else 
            g_client:getServerConnection():sendEvent(setICAnimationEvent:new(vehicle, wantedState, animationIndex));
        end;
    end;
end;













