require "utils.class"
require "utils.library"
require "utils.vscriptinit"
require "utils.utilsinit"
require "framework.frameworkinit"
require "framework.entities.entitiesinit"
require "game.globalsystems.timeofday_init"

local unarmedList = { 
"npc_antlion",
"npc_barnacle_tongue_tip",
"npc_antlionguard",
"npc_clawscanner",
"npc_concussiongrenade",
"npc_cscanner",
"npc_fastzombie",
"npc_headcrab",
"npc_headcrab_armored",
"npc_headcrab_black",
"npc_headcrab_fast",
"npc_headcrab_runner",
"npc_strider",
"npc_manhack",
"npc_poisonzombie",
"npc_zombie",
"npc_zombie_blind",           --杰夫
"npc_zombine",
"xen_foliage_bloater",
"env_explosion", 
"env_fire",
"env_laser",
"env_physexplosion",
"env_physimpact",
"env_spark"
}

local enemyList = {  
"npc_combine",
"npc_combine_s",
"npc_combinedropship",
"npc_combinegunship",
"npc_heli_nobomb",
"npc_helicopter",
"npc_helicoptersensor",
"npc_metropolice",
"npc_sniper",
"npc_strider",
"npc_hunter",
"npc_hunter_invincible",
"npc_turret_ceiling",
"npc_turret_ceiling_pulse",
"npc_turret_citizen",
"npc_turret_floor",
"xen_foliage_turret",
"xen_foliage_turret_projectile"
}

local weaponList = {
"hlvr_weapon_crowbar",
"hlvr_weapon_crowbar_physics",
"hlvr_weapon_energygun",
"hlvr_weapon_rapidfire",
"hlvr_weapon_shotgun"
}


local twoHandMode = 0
local menuOpen = 1
local lastPlayerHealth = 100
local mouthClosed = 0
local coughing = 0
local isDeath = 0
local leftHandUsed = 0
local isFastHeartBeat = false;
local isMidHeartBeat = false;
local isLowHeartBeat = false;
local lastPos = {
  x = 0,
  y = 0,
  z = 0
}



-- 字符串比对
local function startContrast(str, start)
   return str:sub(1, #start) == start
end

-- 表内容进行比对
local function inValue (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

-- 获得两点间的距离
local function pointDistance(a, b)
    local x, y, z = a.x-b.x, a.y-b.y, a.z-b.z;
    return x*x+y*y+z*z;
end


-- 确定玩家和特定物体的相对方向
local function getItemAngle(itemName, pos, distance)
  local angles = Entities:GetLocalPlayer():GetAngles()

    local closestPosition = pos
    local closestHandDist = distance*distance + 1

    local gloveEntities = Entities:FindAllByClassnameWithin(itemName, pos, distance)
    for k,v in pairs(gloveEntities) do    

      local dist = pointDistance(pos, v:GetCenter())

      if dist < closestHandDist then

        closestHandDist = dist
        closestPosition = v:GetCenter()
      end      
    end

  if closestHandDist == distance*distance+1 then
    return -1
  end

  local playerAngle = angles.y

  if playerAngle < 0 then
    playerAngle = (-1*playerAngle)+180    
  else 
     playerAngle = 180 - playerAngle    
  end

  local angle = (((math.atan2(closestPosition.y - pos.y, closestPosition.x - pos.x) - math.atan2(1, 0)) * (180/math.pi))*-1) + 90
  if (angle < 0) then
		angle = angle + 360;
  end

  angle = angle - playerAngle;

  angle = 360 - angle

  if angle < 0 then
    angle = angle + 360;
  elseif angle > 360 then
    angle = angle - 360;
  end  
  return angle;
end

function WriteToFlie(content)
  Msg("[TrueGear] :" .. content)
end


function PlayerLowHealth(Health)
  if Health <= 10 and isFastHeartBeat == false then
    isFastHeartBeat = true
    isMidHeartBeat = false
    isLowHeartBeat = false
    WriteToFlie("{StartFastHeartBeat}\n")
    WriteToFlie("{StopLowHeartBeat}\n")
    WriteToFlie("{StopMidHeartBeat}\n")
  elseif Health > 10 and Health <= 20 and isMidHeartBeat == false then
    isFastHeartBeat = false
    isMidHeartBeat = true
    isLowHeartBeat = false
    WriteToFlie("{StartMidHeartBeat}\n")
    WriteToFlie("{StopLowHeartBeat}\n")
    WriteToFlie("{StopFastHeartBeat}\n")
  elseif Health > 20 and Health <= 33 and isLowHeartBeat == false then
    isFastHeartBeat = false
    isMidHeartBeat = false
    isLowHeartBeat = true
    WriteToFlie("{StartLowHeartBeat}\n")
    WriteToFlie("{StopMidHeartBeat}\n")
    WriteToFlie("{StopFastHeartBeat}\n")    
  elseif Health > 33 and (isLowHeartBeat == true or isMidHeartBeat == true or isFastHeartBeat == true) then
  isFastHeartBeat = false
  isMidHeartBeat = false
  isLowHeartBeat = false
    WriteToFlie("{StopLowHeartBeat}\n")
    WriteToFlie("{StopMidHeartBeat}\n")
    WriteToFlie("{StopFastHeartBeat}\n")
  end
end

function OnPlayerHurt(dmginfo)
  
  local center = Entities:GetLocalPlayer():GetCenter()
  local angles = Entities:GetLocalPlayer():GetAngles()

  local closestDistance = 2499999999
  local closestEntityClass = "unknow"
  local closestEntityName = "unknow"
  local closestEntityDebugName = "unknow"

  local closestPosition = center;
  
  local allEntities = Entities:FindAllInSphere(center, 100000)
  
  for k,v in pairs(allEntities) do    
    local entpos = v:GetCenter()
    local dist = pointDistance(center, entpos)
    if v:IsAlive() == true then
      if inValue(enemyList, v:GetClassname()) or ( inValue(unarmedList, v:GetClassname()) and dist < 15000 ) or (startContrast(v:GetClassname(), "npc_antlion") and dist < 40000) or ((v:GetModelName() == nil or v:GetModelName() == "") and (string.match(v:GetClassname(), "item_hlvr_grenade") or string.match(v:GetClassname(), "npc_grenade") or string.match(v:GetClassname(), "npc_roller") or string.match(v:GetClassname(), "npc_concussiongrenade")) and dist < 50000) then 
        if dist < closestDistance then
          closestEntityClass = v:GetClassname()
          closestEntityName = v:GetName()
          closestEntityDebugName = v:GetDebugName()
          closestDistance = dist
          closestPosition = entpos
        end  
      end        
    end
  end
  
  local playerAngle = angles.y
  if playerAngle < 0 then
    playerAngle = (-1*playerAngle)+180    
  else 
     playerAngle = 180 - playerAngle    
  end
    
  local angle = (((math.atan2(closestPosition.y - center.y, closestPosition.x - center.x) - math.atan2(1, 0)) * (180/math.pi))*-1) + 90
  if (angle < 0) then
		angle = angle + 360;
  end
  angle = angle - playerAngle;
  angle = 360 - angle
  if angle < 0 then
    angle = angle + 360;
  elseif angle > 360 then
    angle = angle - 360;
  end

  local highZ = closestPosition.z - center.z
  local length = math.sqrt(closestDistance)
  local acosvalue = highZ / length
  local radian_value = math.acos(acosvalue)
  local degree_value = 90 - radian_value * (180 / math.pi)

  
  if string.find(tostring(closestEntityClass),"combine") or string.find(tostring(closestEntityClass),"strider") then
    WriteToFlie("{PlayerBulletDamage" .. "," .. tostring(math.floor(angle)) .. "," .. tostring(degree_value) .. "}\n")            --子弹
  elseif string.find(tostring(closestEntityClass),"grenade") or string.find(tostring(closestEntityClass),"foliage") or string.find(tostring(closestEntityClass),"explosion") or string.find(tostring(closestEntityClass),"physimpact") then
    WriteToFlie("{PlayerExplodeDamage" .. "," .. tostring(math.floor(angle)) .. "," .. tostring(degree_value) .. "}\n")           --爆炸
  elseif string.find(tostring(closestEntityClass),"zombie") then
    WriteToFlie("{PlayerZombieDamage" .. "," .. tostring(math.floor(angle)) .. "," .. tostring(degree_value) .. "}\n")            --僵尸
  elseif string.find(tostring(closestEntityClass),"barnacle") then
    WriteToFlie("{PlayerBarnacleDamage}\n")                                                                                       --藤壶
  elseif string.find(tostring(closestEntityClass),"headcrab") and not string.find(tostring(closestEntityClass),"headcrab_runner") then
    WriteToFlie("{ZhouZiheadcrabDamage" .. "," .. tostring(math.floor(angle)) .. "," .. tostring(degree_value) .. "}\n")          --抱头蟹
  elseif string.find(tostring(closestEntityClass),"headcrab_runner") then
    WriteToFlie("{PlayerFlashdogDamage" .. "," .. tostring(math.floor(angle)) .. "," .. tostring(degree_value) .. "}\n")          --闪电狗
  elseif string.find(tostring(closestEntityClass),"manhack") then
    WriteToFlie("{PlayerManhackDamage" .. "," .. tostring(math.floor(angle)) .. "," .. tostring(degree_value) .. "}\n")           --无人机
  elseif string.find(tostring(closestEntityClass),"laser") then
    WriteToFlie("{PlayerLaserDamage" .. "," .. tostring(math.floor(angle)) .. "," .. tostring(degree_value) .. "}\n")             --激光
  elseif string.find(tostring(closestEntityClass),"antlion") then
    WriteToFlie("{PlayerAntlionDamage" .. "," .. tostring(math.floor(angle)) .. "," .. tostring(degree_value) .. "}\n")           --蚁狮
  else
    WriteToFlie("{PlayerOtherDamage" .. "," .. tostring(math.floor(angle)) .. "," .. tostring(degree_value) .. "}\n")             --其他
  end


  local playerHealth = Entities:GetLocalPlayer():GetHealth()
  PlayerLowHealth(playerHealth)                                                                                                   --心跳



  if dmginfo["health"] ~= lastPlayerHealth then
    lastPlayerHealth = dmginfo["health"]
    if lastPlayerHealth <= 0 and isDeath == 0 then
      WriteToFlie("{PlayerDeath}\n")         
      isDeath = 1                                                                                    --死亡
    end
  end
end 


function OnPlayerShootWeapon(shootinfo)
  local pos = Entities:GetLocalPlayer():EyePosition()
  local hmd_avatar = Entities:GetLocalPlayer():GetHMDAvatar()
  local leftHand= hmd_avatar:GetVRHand(0)
  local leftHandPos = leftHand:GetCenter()
  local rightHand= hmd_avatar:GetVRHand(1)
  local rightHandPos = rightHand:GetCenter()

  local closestEntityClass = "unknow"  
  if lastWeapon == "unknow" then

    local closestDistance = 1000000
    local closestPosition = pos;

    local allEntities = Entities:FindAllInSphere(pos, 50)
    for k,v in pairs(allEntities) do    
      if v:IsAlive() == true then
        local entpos = v:GetCenter()
        if inValue(weaponList, v:GetClassname()) then 
          local dist = pointDistance(pos, entpos)
          if dist < closestDistance then
            closestEntityClass = v:GetClassname()
            closestDistance = dist
            closestPosition = entpos
          end
        end
      end
    end
    lastWeapon = closestEntityClass
  end
  -- *************手枪******************
  if string.find(lastWeapon,"energygun") then
    if leftHandUsed == 1 then
        WriteToFlie("{LeftPistolShoot}\n")
    else
        WriteToFlie("{RightPistolShoot}\n")
    end
-- *************霰弹枪******************
  elseif string.find(lastWeapon,"shotgun") then
    if leftHandUsed == 1 then
        WriteToFlie("{LeftShotgunShoot}\n")
    else
        WriteToFlie("{RightShotgunShoot}\n")
    end
-- *************冲锋枪******************
  elseif string.find(lastWeapon,"rapidfire") then
    if leftHandUsed == 1 then
        WriteToFlie("{LeftRapidShoot}\n")
    else
        WriteToFlie("{RightRapidShoot}\n")
    end
  else
    if leftHandUsed == 1 then
      WriteToFlie("{LeftPistolShoot}\n")
  else
      WriteToFlie("{RightPistolShoot}\n")
  end
end
end

function OnGrabbityGlovePull(content)
  if leftHandUsed == 1 then
    if content["hand_is_primary"] == 1 then 
      WriteToFlie("{LeftGrabbityGlovePull}\n")
    else
      WriteToFlie("{RightGrabbityGlovePull}\n")
    end
  else
    if content["hand_is_primary"] == 1 then 
      WriteToFlie("{RightGrabbityGlovePull}\n")
    else
      WriteToFlie("{LeftGrabbityGlovePull}\n")
    end
  end
end 

function OnGrabbityGloveLockStart(content)
end 

function OnGrabbityGloveLockStop(content)
end 

function OnGrabbedByBarnacle(content)
  WriteToFlie("{PlayerBarnacleDamage}\n")
end 

function OnReleasedByBarnacle(content)
end 

function OnWeaponSwitch(weaponInfo)
  lastWeapon = tostring(weaponInfo.item)
  if leftHandUsed == 1 then
    WriteToFlie("{PickUpLeftNormalItem}\n")
  else
    WriteToFlie("{PickUpRightNormalItem}\n")
  end
end

function OnGameNewMap(newMap)
  isDeath = 0
  local playerHealth = Entities:GetLocalPlayer():GetHealth()
  PlayerLowHealth(playerHealth)
end

-- function OnPlayerDeath(content)
--   WriteToFlie(content["entindex_killed"])
--   WriteToFlie(content["entindex_attacker"])
--   WriteToFlie(content["entindex_inflictor"])
--   WriteToFlie(content["damagebits"])
--   if content["entindex_killed"] == 1 then  
--     if isDeath == 0 then
--       WriteToFlie("{PlayerDeath}\n")
--       isDeath = 1
--     end  
--   end 
  
-- end


function 	OnItemPickup	(content) 
  if content["vr_tip_attachment"] == 2 then
    if string.find(content["item"],"prop_reviver_heart") then
        WriteToFlie("{StartLeftReviverHeartItem}\n")                --左手捡到闪电狗心脏
    else
        WriteToFlie("{PickUpLeftNormalItem}\n")                      --普通东西
    end
  else
    if string.find(content["item"],"prop_reviver_heart") then
        WriteToFlie("{StartRightReviverHeartItem}\n")
    else
        WriteToFlie("{PickUpRightNormalItem}\n")
    end
  end
end

local releasedHand = "Left"

function 	OnItemReleased	(content) 
  if content["vr_tip_attachment"] == 2 then
    releasedHand = "Left"
    if string.find(content["item"],"prop_reviver_heart") then
        WriteToFlie("{StopLeftReviverHeartItem}\n")
    end
  else
    releasedHand = "Right"
    if string.find(content["item"],"prop_reviver_heart") then
        WriteToFlie("{StopRightReviverHeartItem}\n")
    end
  end
end

function 	OnGrabbityGloveCatch	(content) 

end
function 	OnPlayerPistolClipInserted	(content)  end
function 	OnPlayerPistolChamberedRound	(content)  end

function 	OnPlayerRetrievedBackpackClip	(content) 
  local pos = Entities:GetLocalPlayer():EyePosition()

  local angle = getItemAngle("hl_prop_vr_hand", pos, 30)

  local leftShoulder = 1

  if angle > 180 then
    leftShoulder = 0
  end

  if leftShoulder == 1 then
    WriteToFlie("{LeftGetbackpackItem}\n")
  else
    WriteToFlie("{RightGetbackpackItem}\n")
  end
end


function 	OnPlayerDropAmmoInBackpack	(content) 

  local pos = Entities:GetLocalPlayer():EyePosition()

  local angle = getItemAngle("hl_prop_vr_hand", pos, 30)

  local leftShoulder = 1

  if angle > 180 then
    leftShoulder = 0
  end
 
  if leftShoulder == 1 then
    WriteToFlie("{LeftDropbackpackItem}\n")
  else
    WriteToFlie("{RightDropbackpackItem}\n")
  end

end


function 	OnPlayerDropResinInBackpack	(content) 

  local pos = Entities:GetLocalPlayer():EyePosition()

  local angle = getItemAngle("hl_prop_vr_hand", pos, 30)

  local leftShoulder = 1

  if angle > 180 then
    leftShoulder = 0
  end

  
  if leftShoulder == 1 then
    WriteToFlie("{LeftDropbackpackItem}\n")
  else
    WriteToFlie("{RightDropbackpackItem}\n")
  end
end


function OnPlayerHealthPenUsed(hpinfo)
  local pos = Entities:GetLocalPlayer():GetCenter()

  local angle = getItemAngle("item_healthvial", pos, 100)

  local playerHealth = Entities:GetLocalPlayer():GetHealth()

  if playerHealth ~= nil then
    if playerHealth ~= lastPlayerHealth then
      lastPlayerHealth = playerHealth    
    end    
    WriteToFlie("{PlayerUseHealthPen}\n")
  end
end

function 	OnPlayerUsingHealthstation	(content) 

  local pos = Entities:GetLocalPlayer():GetCenter()

  local healthLeftHandUsed = 0
  local hmd_avatar = Entities:GetLocalPlayer():GetHMDAvatar()

  local leftHand= hmd_avatar:GetVRHand(0)
  local leftHandPos = leftHand:GetCenter()

  local rightHand= hmd_avatar:GetVRHand(1)
  local rightHandPos = rightHand:GetCenter()

  local closestHealthStationPos; 
  local closestDist= 1000000;

  local healthStationEntities = Entities:FindAllByClassnameWithin("item_health_station_charger", pos, 1000)
  for k,v in pairs(healthStationEntities) do 
    local dist = pointDistance(pos, v:GetCenter())

    if dist < closestDist then

      closestDist = dist
      closestHealthStationPos = v:GetCenter()
    end
  end

  local distLeftHandToHealthStation = pointDistance(leftHandPos, closestHealthStationPos)
  local distRightHandToHealthStation = pointDistance(rightHandPos, closestHealthStationPos)

  if distRightHandToHealthStation > distLeftHandToHealthStation then
    healthLeftHandUsed = 1
  end

  local playerHealth = Entities:GetLocalPlayer():GetHealth()
  if playerHealth ~= nil then  
    lastPlayerHealth = playerHealth
    PlayerLowHealth(playerHealth)
  end

  local healingCount = (100 - playerHealth) / 20
  if(playerHealth == 100) then healingCount = 0 end  
  WriteToFlie("{PlayerUseHealthStation,".. healingCount .."}\n")
end

function OnHealthStationOpen()
  WriteToFlie("{PlayerOpenHealthStation}\n")
end

-- local function Explode()
--   print("---------------")
--   print("lai lo!")
--   local pos = Entities:GetLocalPlayer():EyePosition()

--   local allEntities = Entities:FindAllInSphere(pos, 50000)

--   for k,v in pairs(allEntities) do    
--     local dist = pointDistance(pos, v:GetCenter())
--       if dist < 2000 then
--         print(v:GetClassname())
--         --print(v:GetName())
--         --print(dist)
--       end
--   end
--   print("---------------")
-- end


local function PlayerCoughFunc()
  local pos = Entities:GetLocalPlayer():EyePosition()
  
  local poisonous = false
  local allEntities = Entities:FindAllInSphere(pos, 50)
  for k,v in pairs(allEntities) do    
    local dist = pointDistance(pos, v:GetCenter())
    if string.match(v:GetClassname(), "trigger") and string.match(v:GetName(), "cough_volume") then
      if dist < 2300 then
        poisonous = true 
      end
    end
  end
  
  if poisonous == true then
    local newMouthClosed = mouthClosed
    
    if newMouthClosed == 1 then
           
      local hmd_avatar = Entities:GetLocalPlayer():GetHMDAvatar()
  
      local leftHand= hmd_avatar:GetVRHand(0)
      local leftHandPos = leftHand:GetCenter()
      
      local rightHand= hmd_avatar:GetVRHand(1)
      local rightHandPos = rightHand:GetCenter()
        
      local distLeftHandToEye = pointDistance(leftHandPos, pos)
      local distRightHandToEye = pointDistance(rightHandPos, pos)
      
      if distLeftHandToEye > 100 and distRightHandToEye > 100 then
        newMouthClosed = 0
      end  
    end
    
    if newMouthClosed == 0 then
      local allstuff = Entities:FindAllByClassnameWithin("prop_physics", pos, 10)
      for k,v in pairs(allstuff) do    
        if string.match(v:GetModelName(), "respirator") then
          local dist = pointDistance(pos, v:GetCenter())
          if dist < 17 then
            newMouthClosed = 1
          end
        end
      end
    end
    
    mouthClosed = newMouthClosed

    if mouthClosed == 0 then
      if coughing == 0 then
        coughing = 1
        WriteToFlie("{StartPlayerCough}\n")
      end
    else
      if coughing == 1 then
        coughing = 0
        WriteToFlie("{StopPlayerCough}\n")
      end
    end  
  else
    if coughing == 1 then
      coughing = 0
      WriteToFlie("{StopPlayerCough}\n")
    end
  end
end

function 	OnPlayerShotgunShellLoaded	(content) end
function 	OnPlayerShotgunUpgradeGrenadeLauncherState	(content) end
function 	OnPlayerShotgunAutoloaderState	(content) end
function 	OnPlayerShotgunAutoloaderShellsAdded	(content) end
function 	OnPlayerShotgunLoadedShells	(content) end
function 	OnPlayerRapidfireCycledCapsule	(content) end
function 	OnPlayerRapidfireOpenedCasing	(content) end
function 	OnPlayerRapidfireClosedCasing	(content) end
function 	OnPlayerRapidfireInsertedCapsuleInChamber	(content) end
function 	OnPlayerRapidfireInsertedCapsuleInMagazine	(content) end
function 	OnPlayerRapidfireUpgradeFired	(content) end
function 	OnPlayerRapidfireExplodeButtonPressed	(content) end
function 	OnPlayerStarted2hLevitate	(content) 
  -- if leftHandUsed == 1 then
  --   WriteToFlie("{PickUpLeftNormalItem}\n")
  -- else
  --   WriteToFlie("{PickUpRightNormalItem}\n")
  -- end
end

local function GetItemHolderCloseToHand()
  local leftHolder = 0
  local hmd_avatar = Entities:GetLocalPlayer():GetHMDAvatar()

  local leftHand= hmd_avatar:GetVRHand(0)
  local leftHandPos = leftHand:GetCenter()
  local rightHand= hmd_avatar:GetVRHand(1)
  local rightHandPos = rightHand:GetCenter()
  
  local leftItemHolderPos;
  local rightItemHolderPos;
  local holderEntities = Entities:FindAllByClassname("hlvr_hand_item_holder")
  for k,v in pairs(holderEntities) do        
    local itemHolderPos = v:GetCenter()
    if v:GetDebugName() == "item_holder_l" then
      leftItemHolderPos =  v:GetCenter()
    elseif v:GetDebugName() == "item_holder_r" then
      rightItemHolderPos = v:GetCenter()
    end
  end

  local distLeftHandToRightHolder = pointDistance(leftHandPos, rightItemHolderPos)
  local distRightHandToLeftHolder = pointDistance(rightHandPos, leftItemHolderPos)

  if distRightHandToLeftHolder < distLeftHandToRightHolder then
    leftHolder = 1
  end

  return leftHolder
end



function 	OnPlayerStoredItemInItemholder	(content) 

  local leftHolder = GetItemHolderCloseToHand()
  if leftHolder == 0 and releasedHand == "Left" then
    WriteToFlie("{RightPutItemIntoHolder}\n")
  else
    WriteToFlie("{LeftPutItemIntoHolder}\n")
  end
end

function 	OnPlayerRemovedItemFromItemholder	(content) 

  local leftHolder = GetItemHolderCloseToHand()
  if leftHolder == 1 then
    WriteToFlie("{LeftGetItemIntoHolder}\n")
  else
    WriteToFlie("{RightGetItemIntoHolder}\n")
  end
end

function 	OnHealthPenTeachStorage	(content)  end
function 	OnHealthVialTeachStorage	(content)  end
function 	OnPlayerCoveredMouth	(content) 
  mouthClosed = 1 
  coughing = 0
  WriteToFlie("{StopPlayerCough}\n")
end
function 	OnTripmineHackStarted	(content)  
  if leftHandUsed == 1 then
    WriteToFlie("{PickUpLeftNormalItem}\n")
  else
    WriteToFlie("{PickUpRightNormalItem}\n")
  end
end
function 	OnTripmineHacked	(content)  end
function 	OnPrimaryHandChanged	(content) 
  leftHandUsed = tonumber((content["is_primary_left"]))
end
function 	OnSingleControllerModeChanged	(content)  end
function 	OnMovementHandChanged	(content)  end
function 	OnCombineTankMovedByPlayer	(content)  end
function 	OnPlayerContinuousJumpFinish	(content)  end
function 	OnPlayerContinuousMantleFinish	(content)  end
function 	OnPlayerGrabbedLadder	(content) 
  local leftHolder = GetItemHolderCloseToHand()
  if leftHolder == 1 then
    WriteToFlie("{PickUpLeftNormalItem}\n")
  else
    WriteToFlie("{PickUpRightNormalItem}\n")
  end
end

function 	OnTwoHandStart(content)
  if twoHandMode == 0 then
    twoHandMode = 1
  end
  mouthClosed = 0

  if Entities:GetLocalPlayer() ~= nil then
    local playerHealth = Entities:GetLocalPlayer():GetHealth()
    if playerHealth ~= nil then
      if playerHealth ~= lastPlayerHealth then
        lastPlayerHealth = playerHealth
        if lastPlayerHealth <=33 then
          PlayerLowHealth(lastPlayerHealth)
        end
      end
    end
  end
end
function 	OnTwoHandEnd	(content) 
  if twoHandMode == 1 then
    twoHandMode = 0
  end  
  PlayerCoughFunc()

  if lastWeapon == "unknow" then
    local closestEntityClass = "unknow"  

    local pos = Entities:GetLocalPlayer():GetCenter()
    local closestDistance = 1000000
    local closestPosition = pos;

    local allEntities = Entities:FindAllInSphere(pos, 1000)
    for k,v in pairs(allEntities) do    
      if v:IsAlive() == true then
        local entpos = v:GetCenter()
        if inValue(weaponList, v:GetClassname()) then 
          local dist = pointDistance(pos, entpos)
          if dist < closestDistance then
            closestEntityClass = v:GetClassname()
            closestDistance = dist
            closestPosition = entpos
          end  
        end        
      end
    end 

    lastWeapon = closestEntityClass
  end

  if Entities:GetLocalPlayer() ~= nil then
    local playerHealth = Entities:GetLocalPlayer():GetHealth()
    if playerHealth ~= nil then
      if playerHealth ~= lastPlayerHealth then
        lastPlayerHealth = playerHealth
        if lastPlayerHealth <=33 then
          PlayerLowHealth(lastPlayerHealth)
        end
      end
    end
  end
end

function 	OnPlayerOpenedGameMenu	(content) 
  if menuOpen == 0 then
    menuOpen = 1
    
  end
end


function 	OnPlayerClosedGameMenu	(content) 
  if menuOpen ~= 0 then
    menuOpen = 0
    
  end   
end


function 	OnPlayerTeleportStart	(content) 
  PlayerCoughFunc()

  if Entities:GetLocalPlayer() ~= nil then

    local playerHealth = Entities:GetLocalPlayer():GetHealth()
    if playerHealth ~= nil then

      if playerHealth ~= lastPlayerHealth then
        lastPlayerHealth = playerHealth
        PlayerLowHealth(lastPlayerHealth)
      end
    end
  end

  if lastWeapon == "unknow" then
    local closestEntityClass = "unknow"  

    local pos = Entities:GetLocalPlayer():GetCenter()
    local closestDistance = 1000000
    local closestPosition = pos;

    local allEntities = Entities:FindAllInSphere(pos, 1000)
    for k,v in pairs(allEntities) do    
      if v:IsAlive() == true then
        local entpos = v:GetCenter()
        if inValue(weaponList, v:GetClassname()) then 
          local dist = pointDistance(pos, entpos)
          if dist < closestDistance then
            closestEntityClass = v:GetClassname()
            closestDistance = dist
            closestPosition = entpos
          end  
        end        
      end
    end 
    lastWeapon = closestEntityClass
  end
end


function 	OnPlayerTeleportFinish	(content) 
  local playerHealth = Entities:GetLocalPlayer():GetHealth()
  PlayerLowHealth(playerHealth)
  PlayerCoughFunc()

  local nowPos = {
    x = 0,
    y = 0,
    z = 0
  }
  
  nowPos.x = content["positionX"]
  nowPos.y = content["positionY"]
  nowPos.z = content["positionZ"]

  if pointDistance(nowPos,lastPos) > 20 then
    WriteToFlie("{Teleport}\n")
  end

  lastPos.x = content["positionX"]
  lastPos.y = content["positionY"]
  lastPos.z = content["positionZ"]

  if Entities:GetLocalPlayer() ~= nil then
    local playerHealth = Entities:GetLocalPlayer():GetHealth()
    if playerHealth ~= nil then
      if playerHealth ~= lastPlayerHealth then
        lastPlayerHealth = playerHealth
        
      end
    end
  end

  if lastWeapon == "unknow" then
    local closestEntityClass = "unknow"  

    local pos = Entities:GetLocalPlayer():GetCenter()
    local closestDistance = 1000000
    local closestPosition = pos;
    local allEntities = Entities:FindAllInSphere(pos, 1000)
    for k,v in pairs(allEntities) do    
      if v:IsAlive() == true then
        local entpos = v:GetCenter()
        if inValue(weaponList, v:GetClassname()) then 
          local dist = pointDistance(pos, entpos)
          if dist < closestDistance then
            closestEntityClass = v:GetClassname()
            closestDistance = dist
            closestPosition = entpos
          end  
        end        
      end
    end 
    lastWeapon = closestEntityClass
  end
end

function OnPlayerQuickTurned()
  PlayerCoughFunc()
end

function OnPlayerConnect()
  WriteToFlie("{LinkStart}\n")
end

function OnDoorOpen()
end

function OnDoorClose()
end

function OnDoorUnlocked()
end

function OnItemAttachment()
end

function OnVrControllerHintCreate()
end

function OnPlayerCrouch()
  WriteToFlie("{Crouch}\n")
end



if IsServer() then   

  if onplayershoot_event ~= nil then
    StopListeningToGameEvent(onplayershootweapon_event)
    StopListeningToGameEvent(onplayercrouch_event)
    StopListeningToGameEvent(onplayerhurt_event)
    StopListeningToGameEvent(onplayergrabbityglovepull_event)
    StopListeningToGameEvent(onplayergrabbedbybarnacle_event)
    StopListeningToGameEvent(onplayerreleasedbybarnacle_event)
    StopListeningToGameEvent(onplayerhealthpenused_event)
    StopListeningToGameEvent(onweaponswitch_event)    
    StopListeningToGameEvent(ongamenewmap_event)        
    -- StopListeningToGameEvent(onplayerspawn_event)    
    StopListeningToGameEvent(onentity_killed_event)   
--    StopListeningToGameEvent(onentity_hurt_event)    

    StopListeningToGameEvent(	onplayer_teleport_start_event	)
    StopListeningToGameEvent(	onplayer_teleport_finish_event	)

    StopListeningToGameEvent(	onitem_pickup_event	)
    StopListeningToGameEvent(	onitem_released_event	)
    StopListeningToGameEvent(	onitem_attachment_event	)
    StopListeningToGameEvent(	ongrabbity_glove_catch_event	)
    StopListeningToGameEvent(	onplayer_picked_up_weapon_off_hand_event	)
    StopListeningToGameEvent(	onplayer_picked_up_weapon_off_hand_crafting_event	)
--    StopListeningToGameEvent(	onplayer_eject_clip_event	)
--    StopListeningToGameEvent(	onplayer_armed_grenade_event	)
--    StopListeningToGameEvent(	onplayer_health_pen_prepare_event	)
--    StopListeningToGameEvent(	onplayer_health_pen_retract_event	)
    StopListeningToGameEvent(	onplayer_pistol_clip_inserted_event	)
--    StopListeningToGameEvent(	onplayer_pistol_empty_chamber_event	)
    StopListeningToGameEvent(	onplayer_pistol_chambered_round_event	)
--    StopListeningToGameEvent(	onplayer_pistol_slide_lock_event	)
--    StopListeningToGameEvent(	onplayer_pistol_bought_lasersight_event	)
--    StopListeningToGameEvent(	onplayer_pistol_toggle_lasersight_event	)
--    StopListeningToGameEvent(	onplayer_pistol_bought_burstfire_event	)
--    StopListeningToGameEvent(	onplayer_pistol_toggle_burstfire_event	)
--    StopListeningToGameEvent(	onplayer_pistol_pickedup_charged_clip_event	)
--    StopListeningToGameEvent(	onplayer_pistol_armed_charged_clip_event	)
--    StopListeningToGameEvent(	onplayer_pistol_clip_charge_ended_event	)
    StopListeningToGameEvent(	onplayer_retrieved_backpack_clip_event	)
    StopListeningToGameEvent(	onplayer_drop_ammo_in_backpack_event	)
    StopListeningToGameEvent(	onplayer_drop_resin_in_backpack_event	)
    StopListeningToGameEvent(	onplayer_using_healthstation_event	)
--    StopListeningToGameEvent(	onhealth_station_open_event	)
--    StopListeningToGameEvent(	onplayer_looking_at_wristhud_event	)
    StopListeningToGameEvent(	onplayer_shotgun_shell_loaded_event	)
--    StopListeningToGameEvent(	onplayer_shotgun_state_changed_event	)
    StopListeningToGameEvent(	onplayer_shotgun_upgrade_grenade_launcher_state_event	)
    StopListeningToGameEvent(	onplayer_shotgun_autoloader_state_event	)
    StopListeningToGameEvent(	onplayer_shotgun_autoloader_shells_added_event	)
    StopListeningToGameEvent(	onplayer_shotgun_upgrade_quickfire_event	)
--    StopListeningToGameEvent(	onplayer_shotgun_is_ready_event	)
--    StopListeningToGameEvent(	onplayer_shotgun_open_event	)
    StopListeningToGameEvent(	onplayer_shotgun_loaded_shells_event	)
    StopListeningToGameEvent(	onplayer_shotgun_upgrade_grenade_long_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_capsule_chamber_empty_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_cycled_capsule_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_magazine_empty_event	)
    StopListeningToGameEvent(	onplayer_rapidfire_opened_casing_event	)
    StopListeningToGameEvent(	onplayer_rapidfire_closed_casing_event	)
    StopListeningToGameEvent(	onplayer_rapidfire_inserted_capsule_in_chamber_event	)
    StopListeningToGameEvent(	onplayer_rapidfire_inserted_capsule_in_magazine_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_upgrade_selector_can_use_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_upgrade_selector_used_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_upgrade_can_charge_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_upgrade_can_not_charge_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_upgrade_fully_charged_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_upgrade_not_fully_charged_event	)
    StopListeningToGameEvent(	onplayer_rapidfire_upgrade_fired_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_energy_ball_can_charge_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_energy_ball_fully_charged_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_energy_ball_not_fully_charged_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_energy_ball_can_pick_up_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_energy_ball_picked_up_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_stun_grenade_ready_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_stun_grenade_not_ready_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_stun_grenade_picked_up_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_explode_button_ready_event	)
--    StopListeningToGameEvent(	onplayer_rapidfire_explode_button_not_ready_event	)
    StopListeningToGameEvent(	onplayer_rapidfire_explode_button_pressed_event	)
    StopListeningToGameEvent(	onplayer_started_2h_levitate_event	)
    StopListeningToGameEvent(	onplayer_stored_item_in_itemholder_event	)
    StopListeningToGameEvent(	onplayer_removed_item_from_itemholder_event	)
--    StopListeningToGameEvent(	onplayer_attached_flashlight_event	)
    StopListeningToGameEvent(	onhealth_pen_teach_storage_event	)
    StopListeningToGameEvent(	onhealth_vial_teach_storage_event	)
--    StopListeningToGameEvent(	onplayer_pickedup_storable_clip_event	)
--    StopListeningToGameEvent(	onplayer_pickedup_insertable_clip_event	)
    StopListeningToGameEvent(	onplayer_covered_mouth_event	)
--    StopListeningToGameEvent(	onplayer_upgraded_weapon_event	)
    StopListeningToGameEvent(	ontripmine_hack_started_event	)
    StopListeningToGameEvent(	ontripmine_hacked_event	)
    StopListeningToGameEvent(	onprimary_hand_changed_event	)
    StopListeningToGameEvent(	onsingle_controller_mode_changed_event	)
    StopListeningToGameEvent(	onmovement_hand_changed_event	)
    StopListeningToGameEvent(	oncombine_tank_moved_by_player_event	)
    StopListeningToGameEvent(	onplayer_continuous_jump_finish_event	)
    StopListeningToGameEvent(	onplayer_continuous_mantle_finish_event	)
    StopListeningToGameEvent(	onplayer_grabbed_ladder_event	)

    StopListeningToGameEvent(	ontwo_hand_pistol_grab_start_event	)
    StopListeningToGameEvent(	ontwo_hand_pistol_grab_end_event	)
    StopListeningToGameEvent(	ontwo_hand_rapidfire_grab_start_event	)
    StopListeningToGameEvent(	ontwo_hand_rapidfire_grab_end_event	)
    StopListeningToGameEvent(	ontwo_hand_shotgun_grab_start_event	)
    StopListeningToGameEvent(	ontwo_hand_shotgun_grab_end_event	)
    StopListeningToGameEvent(	player_quick_turned_event	)
    -- StopListeningToGameEvent(	player_connnect_event	)
    StopListeningToGameEvent(	health_station_open_event	)

    StopListeningToGameEvent(	ondoor_open_event	)
    StopListeningToGameEvent(	ondoor_close_event	)
    StopListeningToGameEvent(	ondoor_unlocked_event	)
    StopListeningToGameEvent(	onitem_attachment_event	)

    StopListeningToGameEvent(	onvr_controller_hint_create_event	)
  end

  if ongamenewmap_event ~= nil then
    StopListeningToGameEvent(ongamenewmap_event)    
  end
  if ongamenewmap_event == nil then
    ongamenewmap_event = ListenToGameEvent("game_newmap", OnGameNewMap, nil)
  end

  if onplayershootweapon_event == nil then
    onplayershootweapon_event = ListenToGameEvent("player_shoot_weapon", OnPlayerShootWeapon, nil)
  end

  if onplayercrouch_event == nil then
    onplayercrouch_event = ListenToGameEvent("player_crouch_toggle_finish", OnPlayerCrouch, nil)
  end

  if onplayerhurt_event == nil then
    onplayerhurt_event = ListenToGameEvent("player_hurt", OnPlayerHurt, nil)
  end

  if onplayergrabbityglovepull_event == nil then
    onplayergrabbityglovepull_event = ListenToGameEvent("grabbity_glove_pull", OnGrabbityGlovePull, nil)
  end

  if onplayergrabbityglovelockstart_event == nil then
    onplayergrabbityglovelockstart_event = ListenToGameEvent("grabbity_glove_locked_on_start", OnGrabbityGloveLockStart, nil)
  end

  if onplayergrabbityglovelockstop_event == nil then
    onplayergrabbityglovelockstop_event = ListenToGameEvent("grabbity_glove_locked_on_stop", OnGrabbityGloveLockStop, nil)
  end

  if onplayergrabbedbybarnacle_event == nil then
    onplayergrabbedbybarnacle_event = ListenToGameEvent("player_grabbed_by_barnacle", OnGrabbedByBarnacle, nil)
  end

  if onplayerreleasedbybarnacle_event == nil then
    onplayerreleasedbybarnacle_event = ListenToGameEvent("player_released_by_barnacle", OnReleasedByBarnacle, nil)
  end

  if onplayerhealthpenused_event == nil then
    onplayerhealthpenused_event = ListenToGameEvent("player_health_pen_used", OnPlayerHealthPenUsed, nil)
  end

  if onweaponswitch_event == nil then
    onweaponswitch_event = ListenToGameEvent("weapon_switch", OnWeaponSwitch, nil)
  end

  if onentity_killed_event == nil then
    onentity_killed_event = ListenToGameEvent("entity_killed", OnPlayerDeath, nil)
  end

  if ondoor_open_event == nil then ondoor_open_event=ListenToGameEvent("door_open",OnDoorOpen, nil) end
  if ondoor_close_event == nil then ondoor_close_event=ListenToGameEvent("door_close",OnDoorClose, nil) end
  if ondoor_unlocked_event == nil then ondoor_unlocked_event=ListenToGameEvent("door_unlocked",OnDoorUnlocked, nil) end
  if onitem_attachment_event == nil then onitem_attachment_event=ListenToGameEvent("item_attachment",OnItemAttachment, nil) end
  if onvr_controller_hint_create_event == nil then onvr_controller_hint_create_event=ListenToGameEvent("vr_controller_hint_create",OnVrControllerHintCreate, nil) end

   if onplayer_teleport_start_event == nil then onplayer_teleport_start_event=ListenToGameEvent("player_teleport_start",OnPlayerTeleportStart, nil) end
   if onplayer_teleport_finish_event == nil then onplayer_teleport_finish_event=ListenToGameEvent("player_teleport_finish",OnPlayerTeleportFinish, nil) end
 if onitem_pickup_event == nil then onitem_pickup_event=ListenToGameEvent("item_pickup",OnItemPickup, nil) end
  if onitem_released_event == nil then onitem_released_event=ListenToGameEvent("item_released",OnItemReleased, nil) end
  if onweapon_switch_event == nil then onweapon_switch_event=ListenToGameEvent("weapon_switch",OnWeaponSwitch, nil) end
  if ongrabbity_glove_pull_event == nil then ongrabbity_glove_pull_event=ListenToGameEvent("grabbity_glove_pull",OnGrabbityGlovePull, nil) end
  if ongrabbity_glove_catch_event == nil then ongrabbity_glove_catch_event=ListenToGameEvent("grabbity_glove_catch",OnGrabbityGloveCatch, nil) end
  if ongrabbity_glove_locked_on_start_event == nil then ongrabbity_glove_locked_on_start_event=ListenToGameEvent("grabbity_glove_locked_on_start",OnGrabbityGloveLockedOnStart, nil) end
  if ongrabbity_glove_locked_on_stop_event == nil then ongrabbity_glove_locked_on_stop_event=ListenToGameEvent("grabbity_glove_locked_on_stop",OnGrabbityGloveLockedOnStop, nil) end
  if onplayer_picked_up_weapon_off_hand_event == nil then onplayer_picked_up_weapon_off_hand_event=ListenToGameEvent("player_picked_up_weapon_off_hand",OnPlayerPickedUpWeaponOffHand, nil) end
  if onplayer_picked_up_weapon_off_hand_crafting_event == nil then onplayer_picked_up_weapon_off_hand_crafting_event=ListenToGameEvent("player_picked_up_weapon_off_hand_crafting",OnPlayerPickedUpWeaponOffHandCrafting, nil) end
  if onplayer_health_pen_used_event == nil then onplayer_health_pen_used_event=ListenToGameEvent("player_health_pen_used",OnPlayerHealthPenUsed, nil) end
  if onplayer_pistol_clip_inserted_event == nil then onplayer_pistol_clip_inserted_event=ListenToGameEvent("player_pistol_clip_inserted",OnPlayerPistolClipInserted, nil) end
  if onplayer_pistol_chambered_round_event == nil then onplayer_pistol_chambered_round_event=ListenToGameEvent("player_pistol_chambered_round",OnPlayerPistolChamberedRound, nil) end
  if onplayer_retrieved_backpack_clip_event == nil then onplayer_retrieved_backpack_clip_event=ListenToGameEvent("player_retrieved_backpack_clip",OnPlayerRetrievedBackpackClip, nil) end
  if onplayer_drop_ammo_in_backpack_event == nil then onplayer_drop_ammo_in_backpack_event=ListenToGameEvent("player_drop_ammo_in_backpack",OnPlayerDropAmmoInBackpack, nil) end
  if onplayer_drop_resin_in_backpack_event == nil then onplayer_drop_resin_in_backpack_event=ListenToGameEvent("player_drop_resin_in_backpack",OnPlayerDropResinInBackpack, nil) end
  if onplayer_using_healthstation_event == nil then onplayer_using_healthstation_event=ListenToGameEvent("player_using_healthstation",OnPlayerUsingHealthstation, nil) end
  if onplayer_shotgun_shell_loaded_event == nil then onplayer_shotgun_shell_loaded_event=ListenToGameEvent("player_shotgun_shell_loaded",OnPlayerShotgunShellLoaded, nil) end
  if onplayer_shotgun_upgrade_grenade_launcher_state_event == nil then onplayer_shotgun_upgrade_grenade_launcher_state_event=ListenToGameEvent("player_shotgun_upgrade_grenade_launcher_state",OnPlayerShotgunUpgradeGrenadeLauncherState, nil) end
  if onplayer_shotgun_autoloader_state_event == nil then onplayer_shotgun_autoloader_state_event=ListenToGameEvent("player_shotgun_autoloader_state",OnPlayerShotgunAutoloaderState, nil) end
  if onplayer_shotgun_autoloader_shells_added_event == nil then onplayer_shotgun_autoloader_shells_added_event=ListenToGameEvent("player_shotgun_autoloader_shells_added",OnPlayerShotgunAutoloaderShellsAdded, nil) end
  if onplayer_shotgun_upgrade_quickfire_event == nil then onplayer_shotgun_upgrade_quickfire_event=ListenToGameEvent("player_shotgun_upgrade_quickfire",OnPlayerShotgunUpgradeQuickfire, nil) end
  if onplayer_shotgun_loaded_shells_event == nil then onplayer_shotgun_loaded_shells_event=ListenToGameEvent("player_shotgun_loaded_shells",OnPlayerShotgunLoadedShells, nil) end
  if onplayer_rapidfire_opened_casing_event == nil then onplayer_rapidfire_opened_casing_event=ListenToGameEvent("player_rapidfire_opened_casing",OnPlayerRapidfireOpenedCasing, nil) end
  if onplayer_rapidfire_closed_casing_event == nil then onplayer_rapidfire_closed_casing_event=ListenToGameEvent("player_rapidfire_closed_casing",OnPlayerRapidfireClosedCasing, nil) end
  if onplayer_rapidfire_inserted_capsule_in_chamber_event == nil then onplayer_rapidfire_inserted_capsule_in_chamber_event=ListenToGameEvent("player_rapidfire_inserted_capsule_in_chamber",OnPlayerRapidfireInsertedCapsuleInChamber, nil) end
  if onplayer_rapidfire_inserted_capsule_in_magazine_event == nil then onplayer_rapidfire_inserted_capsule_in_magazine_event=ListenToGameEvent("player_rapidfire_inserted_capsule_in_magazine",OnPlayerRapidfireInsertedCapsuleInMagazine, nil) end
  if onplayer_rapidfire_upgrade_fired_event == nil then onplayer_rapidfire_upgrade_fired_event=ListenToGameEvent("player_rapidfire_upgrade_fired",OnPlayerRapidfireUpgradeFired, nil) end
  if onplayer_rapidfire_explode_button_pressed_event == nil then onplayer_rapidfire_explode_button_pressed_event=ListenToGameEvent("player_rapidfire_explode_button_pressed",OnPlayerRapidfireExplodeButtonPressed, nil) end
  if onplayer_started_2h_levitate_event == nil then onplayer_started_2h_levitate_event=ListenToGameEvent("player_started_2h_levitate",OnPlayerStarted2hLevitate, nil) end
  if onplayer_stored_item_in_itemholder_event == nil then onplayer_stored_item_in_itemholder_event=ListenToGameEvent("player_stored_item_in_itemholder",OnPlayerStoredItemInItemholder, nil) end
  if onplayer_removed_item_from_itemholder_event == nil then onplayer_removed_item_from_itemholder_event=ListenToGameEvent("player_removed_item_from_itemholder",OnPlayerRemovedItemFromItemholder, nil) end
  if onhealth_pen_teach_storage_event == nil then onhealth_pen_teach_storage_event=ListenToGameEvent("health_pen_teach_storage",OnHealthPenTeachStorage, nil) end
  if onhealth_vial_teach_storage_event == nil then onhealth_vial_teach_storage_event=ListenToGameEvent("health_vial_teach_storage",OnHealthVialTeachStorage, nil) end
  if onplayer_covered_mouth_event == nil then onplayer_covered_mouth_event=ListenToGameEvent("player_covered_mouth",OnPlayerCoveredMouth, nil) end
  if ontripmine_hack_started_event == nil then ontripmine_hack_started_event=ListenToGameEvent("tripmine_hack_started",OnTripmineHackStarted, nil) end
  if ontripmine_hacked_event == nil then ontripmine_hacked_event=ListenToGameEvent("tripmine_hacked",OnTripmineHacked, nil) end
  if onprimary_hand_changed_event == nil then onprimary_hand_changed_event=ListenToGameEvent("primary_hand_changed",OnPrimaryHandChanged, nil) end
  if onsingle_controller_mode_changed_event == nil then onsingle_controller_mode_changed_event=ListenToGameEvent("single_controller_mode_changed",OnSingleControllerModeChanged, nil) end
  if onmovement_hand_changed_event == nil then onmovement_hand_changed_event=ListenToGameEvent("movement_hand_changed",OnMovementHandChanged, nil) end
  if oncombine_tank_moved_by_player_event == nil then oncombine_tank_moved_by_player_event=ListenToGameEvent("combine_tank_moved_by_player",OnCombineTankMovedByPlayer, nil) end
  if onplayer_continuous_jump_finish_event == nil then onplayer_continuous_jump_finish_event=ListenToGameEvent("player_continuous_jump_finish",OnPlayerContinuousJumpFinish, nil) end
  if onplayer_continuous_mantle_finish_event == nil then onplayer_continuous_mantle_finish_event=ListenToGameEvent("player_continuous_mantle_finish",OnPlayerContinuousMantleFinish, nil) end
  if onplayer_grabbed_ladder_event == nil then onplayer_grabbed_ladder_event=ListenToGameEvent("player_grabbed_ladder",OnPlayerGrabbedLadder, nil) end

  if ontwo_hand_pistol_grab_start_event == nil then ontwo_hand_pistol_grab_start_event=ListenToGameEvent("two_hand_pistol_grab_start",OnTwoHandStart, nil) end
  if ontwo_hand_pistol_grab_end_event == nil then ontwo_hand_pistol_grab_end_event=ListenToGameEvent("two_hand_pistol_grab_end",OnTwoHandEnd, nil) end
  if ontwo_hand_rapidfire_grab_start_event == nil then ontwo_hand_rapidfire_grab_start_event=ListenToGameEvent("two_hand_rapidfire_grab_start",OnTwoHandStart, nil) end
  if ontwo_hand_rapidfire_grab_end_event == nil then ontwo_hand_rapidfire_grab_end_event=ListenToGameEvent("two_hand_rapidfire_grab_end",OnTwoHandEnd, nil) end
  if ontwo_hand_shotgun_grab_start_event == nil then ontwo_hand_shotgun_grab_start_event=ListenToGameEvent("two_hand_shotgun_grab_start",OnTwoHandStart, nil) end
  if ontwo_hand_shotgun_grab_end_event == nil then ontwo_hand_shotgun_grab_end_event=ListenToGameEvent("two_hand_shotgun_grab_end",OnTwoHandEnd, nil) end
  if player_quick_turned_event == nil then player_quick_turned_event=ListenToGameEvent("player_quick_turned",OnPlayerQuickTurned, nil) end
  if player_connect_event == nil then player_connect_event=ListenToGameEvent("player_connect",OnPlayerConnect, nil) end
  if health_station_open_event == nil then health_station_open_event=ListenToGameEvent("health_station_open",OnHealthStationOpen, nil) end

  lastWeapon = "unknow"

--  Msg("Listeners registered. " .. _VERSION .. " \n")

-- else

--   if onplayer_opened_game_menu_event ~= nil then
--     StopListeningToGameEvent(	onplayer_opened_game_menu_event	)
--     StopListeningToGameEvent(	onplayer_closed_game_menu_event	)
--   end

--   if onplayer_opened_game_menu_event == nil then onplayer_opened_game_menu_event=ListenToGameEvent("player_opened_game_menu",OnPlayerOpenedGameMenu, nil) end
--   if onplayer_closed_game_menu_event == nil then onplayer_closed_game_menu_event=ListenToGameEvent("player_closed_game_menu",OnPlayerClosedGameMenu, nil) end

end