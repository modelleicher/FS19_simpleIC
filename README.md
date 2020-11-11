# FS19_simpleIC
 New Interactive Control Script for FS19
 
# Changelog:

###### V 0.9.2.7
- separated attacherControl into seperate lua
- synchronized attacherControl with setJointMoveDown so its always in synch
- fixed doNotSynch for ptoControl
- added returnToCenter, returnToCenterRaised, returnToCenterLowered for attacherControl leverAnimation
###### V 0.9.2.6 
- separated ptoControl into seperate lua
- synchronized ptoControl animation with turnOnVehicle so its always in synch
- fixed version numbering mishap (yes this is 0.9.2.6 not 0.9.1.6)
###### V 0.9.2.5
- added attacherControl 
- added ptoControl 
###### V 0.9.2.4 
- made icFunctions more universally usable for future additions
- icFunction can be "turned off" by setting visibility of triggerPoint to false 
###### V 0.9.2.3
- MP Server fix of vehicle not enterable
###### V 0.9.2.2
- fix for line 102 error I think, couldn't reproduce but I found an issue with the table indexing and I think it worked fine for most mods but some may have caused the issue to show.
###### V 0.9.2.1
- possibly fixed dedicated server issue 
- removed "cylinder" debug finally 
###### V 0.9.2.0
- addition of SimpleIC-ImplementBalls
###### V 0.9.1.9
- fixed the issue introduced in the version before last version and partially fixed in the last version. Now fixed completely. I hope.. again.
###### V 0.9.1.8
- fixed Issue introduced in the last version of indoor buttons only working when the ingame-menu is on, fully removed issue with double-mapping of mouseButtons I hope
###### V 0.9.1.7
- fixed Error: simpleIC.lua:488: attempt to index field 'spec_motorized' (a nil value)
- fixed Error: simpleIC.lua:318: attempt to call method 'getAttacherVehicle' (a nil value)
- reachDistance can be set per vehicle (optional, default 1.8) to specify how far away a player can reach an IC-point
###### V 0.9.1.6
- fixed spec insertion so simpleIC now works in every implement, trailer etc. not just drivables
###### V 0.9.1.5
- fixed Error: simpleIC.lua:248: attempt to index local 'spec' (a nil value)
- added cylinderAnimation for easy animation of struts on windows/doors etc.
###### V 0.9.1.4
- fixed IC active on all vehicles bug (now only active if vehicle actually has IC functions)
- fixed bug Error: Running LUA method 'update' simpleIC.lua:292: attempt to index a nil value
- added default keymapping
###### V 0.9.1.3
- multiplayer fix
- added triggerPoint_ON and triggerPoint_OFF as alternative to toggle via triggerPoint 
 
# the most important thing:
How do I test this?
1. download FS19_simpleIC.zip and add to modfolder
2. download my Agrostar 6.61 Edit I released for christmas, it already has simpleIC added. https://youtu.be/lsEg6T7XOkE
(by now there are a lot of SimpleIC ready mods out there already so just find the next best one you like)
3. go ingame and have fun :D 

# What this is:
This is a new take on the well known Interactive Control Scripts in Farming Simulator. Since there hasn't been a well-working bug-free version of the old scripts in FS19, and since I always didn't like the way the Mouse is used, I created this alternative.

- This is a global script, which means that it doesn't have to be added to each Mod seperately, no additional modDesc.xml changes like l10n Texts etc. neccessary.
- Obviously the vehicle-xml and i3d still has to be edited, the script can't magically seperate doors and add trigger-points. But as soon as the needed lines are added, IC will be active as long as you have this mod active.
- this also means that people who don't like IC don't have to remove it all vehicle-mods, just not activate this mod.
- this also means that there's only one IC version and not 50 different ones that get into conflict with each other 
- updates to IC are global and useable in all mods

Now for the bad parts
- still Beta
- still Bugs
- not even close to the amount of features the original IC Script had in FS17. (But I'm working on that ;) )

# How to add this to my Mod:
- I will create videos explaining the process of adding simpleIC to your vehicle. 

- There is an examples.xml explaining all the current possible XML entrys and what they do. If you're not brandnew to modding this should be enough to get going :) 

If you already know modding well, here's a short explanation:
(look at the linked Deutz Agrostar above to see the full XML lines)

- outsideInteractionTrigger = playerTrigger in which the player can open doors and other outside-stuff from the outside
- animationName = name of the animation for the door
- animationSpeed = speed of the animation (obvious) 
- shared animation = not added yet
- soundVolumeIncreasePercentage = by how much will the sound-volume increase if that door is opened. Values will be added together for more than one door, max is outdoorSoundVolume 
- insideTrigger and outsideTrigger = "Triggerpoints" e.g. transformGroups that mark the spot where the IC component can be clicked
- triggerPoint = index / i3dMapping name for the transformGroup
- triggerPointSize = size/radius around the triggerPoint where it still registeres as being clicked


