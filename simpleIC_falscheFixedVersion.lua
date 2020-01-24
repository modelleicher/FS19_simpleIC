-- by modelleicher
-- 13.04.2019

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
end;


function simpleIC.onRegisterActionEvents(self, isActiveForInput)
	local spec = self.spec_simpleIC;
	spec.actionEvents = {}; 
	self:clearActionEventsTable(spec.actionEvents); 	

	if self:getIsActive() then
		self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_ONOFF, self, simpleIC.TOGGLE_ONOFF, true, true, false, true, nil);
		self:addActionEvent(spec.actionEvents, InputAction.INTERACT_IC_VEHICLE, self, simpleIC.INTERACT, true, false, false, true, nil);
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

	self.spec_simpleIC = {};
	
	local spec = self.spec_simpleIC; 
	
	-- for now all we have is animations, no other types of functions 
	spec.animations = {};
	
	-- load the animations from XML 
	local i = 0;
	while true do
		local key = "vehicle.simpleIC.animation("..i..")";
		
		local anim = {};
		anim.animationName = getXMLString(self.xmlFile, key.."#animationName");
		if anim.animationName == "" or anim.animationName == nil then
			break;
		end;
		anim.animationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, key.."#animationSpeed"), 1);
		anim.sharedAnimation = Utils.getNoNil(getXMLBool(self.xmlFile, key.."#sharedAnimation"), false);
		anim.currentState = false;
		
		if not anim.sharedAnimation then
			self:playAnimation(anim.animationName, -anim.animationSpeed, self:getAnimationTime(anim.animationName), true);
		end;
		
		anim.duration = self:getAnimationDuration(anim.animationName);
		
		
		anim.inTP = {};
		anim.inTP.triggerPoint = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key..".insideTrigger#triggerPoint"), self.i3dMappings);
		anim.inTP.triggerPointRadius = Utils.getNoNil(getXMLFloat(self.xmlFile, key..".insideTrigger#triggerPointSize"), 0.04);
		anim.inTP.triggerDistance = Utils.getNoNil(getXMLFloat(self.xmlFile, key..".insideTrigger#triggerDistance"), 1);
		
		anim.outTP = {};
		anim.outTP.triggerPoint = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key..".outsideTrigger#triggerPoint"), self.i3dMappings);
		anim.outTP.triggerPointRadius = Utils.getNoNil(getXMLFloat(self.xmlFile, key..".outsideTrigger#triggerPointSize"), 0.04);
		anim.outTP.triggerDistance = Utils.getNoNil(getXMLFloat(self.xmlFile, key..".outsideTrigger#triggerDistance"), 1);
		
		
		anim.soundVolumeIncreasePercentage = Utils.getNoNil(getXMLFloat(self.xmlFile, key.."#soundVolumeIncreasePercentage"), false);
		
		
		table.insert(spec.animations, anim);
		print("Simple IC Animation added "..tostring(anim.animationName));
		i = i+1;
	end;
	
	spec.outsideInteractionTrigger = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.simpleIC#outsideInteractionTrigger"), self.i3dMappings);
	
	spec.playerInOutsideInteractionTrigger = false;
	
	spec.interactionMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.simpleIC#interactionMarker"), self.i3dMappings)

	if spec.outsideInteractionTrigger ~= nil then
		spec.outsideInteractionTriggerId = addTrigger(spec.outsideInteractionTrigger, "outsideInteractionTriggerCallback", self);   
	end;
	
	spec.soundVolumeIncreasePercentageAll = 1;
   	spec.soundChangeIndexList = {};	



	-- 
	spec.icTurnedOn_inside = false; 
	spec.icTurnedOn_outside = false;

	spec.icTurnedOn_inside_backup = true;	




	spec.markerTurnedOn = true;

	for i, sample in pairs(self.spec_motorized.samples) do
		sample.indoorAttributes.volumeBackup = sample.indoorAttributes.volume;		
	end;
	for i, sample in pairs(self.spec_motorized.motorSamples) do
		sample.indoorAttributes.volumeBackup = sample.indoorAttributes.volume;
	end;	
	
end;

function simpleIC:onEnterVehicle(isControlling, playerStyle, farmId)
	local spec = self.spec_simpleIC;
	if self:getActiveCamera() ~= nil then
		if self:getActiveCamera().isInside then
			self:setICState(true, false);
		end;
		spec.lastCameraInside = self:getActiveCamera().isInside;
		print(tostring(spec.lastCameraInside))
	end;
	print("onEnter")
end;

-- indoor camera -> IC is always on by default
-- outdoor camera -> IC is on when button is pressed
-- inside IC can be turned off 
-- marker turn of "globally"


function simpleIC:INTERACT(actionName, inputValue)
	if self.spec_simpleIC.icTurnedOn_inside or self.spec_simpleIC.icTurnedOn_outside or self.spec_simpleIC.playerInOutsideInteractionTrigger then
		local i = 1;
		for _, animation in pairs(self.spec_simpleIC.animations) do
			if animation.canBeTriggered then
				-- trigger animation 
				self:setICAnimation(not animation.currentState, i);
			end;
			i = i+1;
		end;	
	end;
end;

function simpleIC:TOGGLE_ONOFF(actionName, inputValue)
	local spec = self.spec_simpleIC;

	if not self:getActiveCamera().isInside then
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
	end;

end;

function simpleIC:onUpdate(dt)

	if self.spec_simpleIC ~= nil then


		local spec = self.spec_simpleIC;
		if self.spec_simpleIC.playerInOutsideInteractionTrigger then
			self:checkInteraction()
			self:raiseActive() -- keep vehicle awake as long as player is in trigger 
		end;
		
        -- we need to track camera changes from inside to outside and adjust IC accordingly 
		if self:getIsActiveForInput(true) then
            -- if isInside is true and outside turned on or vice versa we changed camera 
			if self:getActiveCamera() ~= nil and self:getActiveCamera().isInside ~= spec.lastCameraInside then -- TO DO, fix nil bug here -- done I think 
				-- if we toggled from inside to outside, store inside state in backup variable and turn off inside 
				print("test2")
				if not self:getActiveCamera().isInside then
					spec.icTurnedOn_inside_backup = spec.icTurnedOn_inside;
                    self:setICState(false, true);
                else -- if we toggled to inside restore backup value 
                    self:setICState(spec.icTurnedOn_inside_backup, false);
				end;
				spec.lastCameraInside = self:getActiveCamera().isInside;
			end;
		end;
	
	end;
end;


function simpleIC:setICAnimation(wantedState, animationIndex, noEventSend)
    setICAnimationEvent.sendEvent(self, wantedState, animationIndex, noEventSend);
	local animation = self.spec_simpleIC.animations[animationIndex];
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
	
	spec.soundVolumeIncreasePercentageAll = math.max(1, spec.soundVolumeIncreasePercentageAll);
	spec.updateSoundAttributesFlag = true;

end;

-- goal
-- sound volume needs to change dynamically while the animation is playing 
-- sound volume needs to change globally with multiple animations playing at the same time 

-- so when we activate an animation we add that animation index to a sound update index list 

function simpleIC:addSoundChangeIndex(index)
	local animation =  self.spec_simpleIC.animations[index];
	if animation.soundVolumeIncreasePercentage ~= false then -- check if this even has sound change effects 
		-- now add it to the table 
		self.spec_simpleIC.soundChangeIndexList[index] = animation; -- we add it at the index of the animation that way if we try adding the same animation twice it does overwrite itself 
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
		local _ , eventId = g_currentMission.inputManager:registerActionEvent(InputAction.INTERACT_IC_ONFOOT, self, simpleIC.INTERACT, false, true, false, true);		
	elseif onLeave and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		spec.playerInOutsideInteractionTrigger = false;
	end;
end;

function simpleIC:onDraw()
	self:checkInteraction()
end;

function simpleIC:checkInteraction()
	if self.spec_simpleIC ~= nil then
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
			
			-- go through all the animations 
			local index = 0;
			for _, animation in pairs(spec.animations) do
				index = index + 1;
				-- get inside or outside trigger points depending on if we're inside or outside 
				local tp = animation.inTP;
				if not isInside then
					tp = animation.outTP;
				end;
				
				if tp.triggerPoint ~= nil then
					
					
					-- get world translation of our trigger point, then project it to the screen 
					local wX, wY, wZ = getWorldTranslation(tp.triggerPoint);
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

						-- set it to false by default 
						animation.canBeTriggered = false;
						-- check if our position is within the position of the triggerRadius
						if posX < (x + tp.triggerPointRadius) and posX > (x - tp.triggerPointRadius) then
							if posY < (y + tp.triggerPointRadius) and posY > (y - tp.triggerPointRadius) then
								print("true")
								if dist < 1.8 or spec.icTurnedOn_outside then
									-- can be clicked 
									animation.canBeTriggered = true;
									self:renderTextAtProjectedPosition(x,y,z, "X", size, 1, 0, 0)
								end;
							end;
						end;	
						if not animation.canBeTriggered then
							self:renderTextAtProjectedPosition(x,y,z, "X", size, 1, 1, 1)
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
function setICAnimationEvent:new(vehicle, state) 
    self.vehicle = vehicle;
    self.state = state;
    return self;
end;
function setICAnimationEvent:readStream(streamId, connection)  
    self.vehicle = NetworkUtil.readNodeObject(streamId); 
    self.state = streamReadBool(streamId); 
    self:run(connection);  
end;
function setICAnimationEvent:writeStream(streamId, connection)   
	NetworkUtil.writeNodeObject(streamId, self.vehicle);   
    streamWriteBool(streamId, self.state );   
end;
function setICAnimationEvent:run(connection) 
    self.vehicle:setICAnimation(self.state, true);
    if not connection:getIsServer() then  
        g_server:broadcastEvent(setICAnimationEvent:new(self.vehicle, self.state), nil, connection, self.object);
    end;
end;
function setICAnimationEvent.sendEvent(vehicle, state, noEventSend) 
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then   
            g_server:broadcastEvent(setICAnimationEvent:new(vehicle, state), nil, nil, vehicle);
        else 
            g_client:getServerConnection():sendEvent(setICAnimationEvent:new(vehicle, state));
        end;
    end;
end;













