local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic = true
object.bRunBehaviors = true
object.bUpdates = true
object.bUseShop = true

object.bRunCommands = true
object.bMoveCommands = true
object.bAttackCommands = true
object.bAbilityCommands = true
object.bOtherCommands = true

object.bReportBehavior = false
object.bDebugUtility = false
object.bDebugExecute = false

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core = {}
object.eventsLib = {}
object.metadata = {}
object.behaviorLib = {}
object.skills = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"
runfile "bots/teams/3_guys_and_5_bots/generics.lua"


local core, eventsLib, behaviorLib, metadata, skills, generics = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills, object.generics

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading puppetmaster_main...')

object.heroName = 'Hero_PuppetMaster'


---------------------------------------------------
--                   Utilities                   --
---------------------------------------------------
-- bonus aggression points if a skill/item is available for use
object.hold = 20
object.show = 20
object.ulti = 35
-- bonus aggression points that are applied to the bot upon successfully using a skill/item
object.holdUse = 20
object.showUse = 20
object.ultiUse = 35
--thresholds of aggression the bot must reach to use these abilities
object.holdThreshold = 22
object.showThreshold = 22
object.ultiThreshold = 37



local function AbilitiesUpUtilityFn()
  local val = 0

  if skills.hold:CanActivate() then
    val = val + object.hold
  end

  if skills.show:CanActivate() then
    val = val + object.show
  end

  if skills.ulti:CanActivate() then
    val = val + object.ulti
  end

  return val
end
--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 4, LongSolo = 0, ShortSupport = 0, LongSupport = 0, ShortCarry = 4, LongCarry = 3}

--------------------------------
-- Skills
--------------------------------

-- table listing desired skillbuild. 0=Q(hold), 1=W(show), 2=E(whip), 3=R(ulti), 4=AttributeBoost
object.tSkills = {
1, 0, 2, 2, 2,
3, 2, 1, 1, 1,
3, 0, 0, 0, 4,
3, 4, 4, 4, 4,
4, 4, 4, 4, 4,
}

local bSkillsValid = false
function object:SkillBuild()

  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.hold = unitSelf:GetAbility(0)
    skills.show = unitSelf:GetAbility(1)
    skills.whip = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.courier = unitSelf:GetAbility(12)
    if skills.hold and skills.show and skills.whip and skills.ulti then
      bSkillsValid = true
    else
      return
    end
  end
  
  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  local nlev = unitSelf:GetLevel()
  local nlevpts = unitSelf:GetAbilityPointsAvailable()
  for i = nlev, nlev+nlevpts do
    unitSelf:GetAbility( object.tSkills[i] ):LevelUp()
  end
end

local function DetermineOwnTarget(skill)  
  local tLocalEnemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  local myPos = core.unitSelf:GetPosition()
  local unitTarget = nil
  local maxDistance = skill:GetRange()
  local distanceTarget = 999999999
  for _, unitEnemy in pairs(tLocalEnemies) do
    local enemyPos = unitEnemy:GetPosition()
    local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
    if distanceEnemy < maxDistance then
      if distanceEnemy < distanceTarget then
        unitTarget = unitEnemy
        distanceTarget = distanceEnemy
      end
    end
  end
  return unitTarget
end

local function CustomHarassUtilityFnOverride(hero)
  local nUtility = 0

  if skills.ulti:CanActivate() and skills.ulti:GetManaCost() < core.unitSelf:GetMana() then
    nUtility = nUtility + 60
  end


  if skills.hold:CanActivate()then
    nUtility = nUtility + 20
  end

  return nUtility
end
-- assisgn custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride 




-- Harass hero
local function HarassHeroExecuteOverride(botBrain)
  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil or not unitTarget:IsValid() then
    return false --can not execute, move on to the next behavior
  end

  local unitSelf = core.unitSelf


  local bActionTaken = false

  --since we are using an old pointer, ensure we can still see the target for entity targeting
  if core.CanSeeUnit(botBrain, unitTarget) then
    local dist = Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition())
    local attkRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget);


    local ulti = skills.ulti
    local ultiRange = ulti and (ulti:GetRange() + core.GetExtraRange(unitSelf) + core.GetExtraRange(unitTarget)) or 0


    if ulti and ulti:CanActivate() then
      if dist < ultiRange then
        
        bActionTaken = core.OrderAbilityEntity(botBrain, ulti, unitTarget)
      end
    end

    if not bActionTaken and skills.hold and skills.hold:CanActivate() then 
      
     core.OrderAbilityEntity(botBrain, skills.hold, unitTarget)
   end
 end


 if not bActionTaken then
  return object.harassExecuteOld(botBrain)
end
end
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)
  -- custom code here
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function object:oncombateventOverride(EventData)



  self:oncombateventOld(EventData)

  -- custom code here
end


-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride


local function CustomHarassUtilityFnOverride(target)
  local nUtility = 0
  
  if skills.show:CanActivate() then
    nUtility = nUtility + 10
  end

  if skills.hold:CanActivate() then
    nUtility = nUtility + 10
  end

  if skills.ulti:CanActivate() then 
     nUtility = nUtility + 20
  end

  return generics.CustomHarassUtility(target) + nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride


local function HarassHeroExecuteOverride(botBrain)
  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil or not unitTarget:IsValid() then
    return false --can not execute, move on to the next behavior
  end
  
  local unitSelf = core.unitSelf
  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then
  
    local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
    
    local hold = skills.hold
    local nRange = hold:GetRange()
    if hold:CanActivate() and not unitTarget:HasState("State_PuppetMaster_Ability2") and nTargetDistanceSq < (nRange * nRange) then
      bActionTaken = core.OrderAbilityEntity(botBrain, hold, unitTarget)
    end

    local show = skills.show
    nRange = show:GetRange()
    local unitsNearby = core.AssessLocalUnits(botBrain, unitTarget, 400)
    
    local nEnemies = core.NumberElements(unitsNearby.Enemies)

    if not bActionTaken and not unitTarget:HasState("State_PuppetMaster_Ability1") and show:CanActivate() and nTargetDistanceSq < (nRange * nRange) and nEnemies > 0 then
      bActionTaken = core.OrderAbilityEntity(botBrain, show, unitTarget)
    end
  end

  if not bActionTaken then
    return core.harassExecuteOld(botBrain)
  end
end
core.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

--items
behaviorLib.StartingItems = {"2 Item_MinorTotem", "Item_HealthPotion", "Item_ManaBattery"}
behaviorLib.LaneItems =
        {"Item_PowerSupply", "Item_Marchers", "Item_Steamboots"}
        behaviorLib.MidItems =
        {"Item_Voltstone", "Item_Glowstone", "Item_Lifetube", "Item_Protect"}
        behaviorLib.LateItems =
        {"Item_Warpcleft 2", "Item_ArclightCrown", "Item_Voulge", "Item_Weapon3", "Item_Morph", "Item_BehemothsHeart"}


BotEcho('finished loading puppetmaster_main')
