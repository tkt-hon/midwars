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

BotEcho('loading devourer_main...')

object.heroName = 'Hero_Devourer'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 0, LongSolo = 0, ShortSupport = 0, LongSupport = 0, ShortCarry = 0, LongCarry = 0}

---------------------------------------------------
--                   Utilities                   --
---------------------------------------------------
-- bonus aggression points if a skill/item is available for use
object.hook = 20
object.rot = 20
object.ulti = 35
-- bonus aggression points that are applied to the bot upon successfully using a skill/item
object.hookUse = 20
object.rotUse = 20
object.ultiUse = 35
--thresholds of aggression the bot must reach to use these abilities
object.hookThreshold = 22
object.rotThreshold = 22
object.ultiThreshold = 37



local function AbilitiesUpUtilityFn()
  local val = 0

  if skills.hook:CanActivate() then
    val = val + object.hold
  end

  if skills.rot:CanActivate() then
    val = val + object.show
  end

  if skills.ulti:CanActivate() then
    val = val + object.ulti
  end

  return val
end

--------------------------------
-- Skills
--------------------------------
-- table listing desired skillbuild. 0=Q(hook), 1=W(rot), 2=E(passive), 3=R(ulti), 4=AttributeBoost
object.tSkills = {
1, 0, 0, 1, 0,
3, 0, 1, 1, 2,
3, 2, 2, 2, 4,
3, 4, 4, 4, 4,
4, 4, 4, 4, 4,
}



local bSkillsValid = false
function object:SkillBuild()

  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.hook = unitSelf:GetAbility(0)
    skills.rot = unitSelf:GetAbility(1)
    skills.skin = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.courier = unitSelf:GetAbility(12)
    if skills.hook and skills.rot and skills.skin and skills.ulti then
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

local function IsFreeLine(pos1, pos2)
  core.DrawDebugLine(pos1, pos2, "yellow")
  local tAllies = core.CopyTable(core.localUnits["AllyUnits"])
  local tEnemies = core.CopyTable(core.localUnits["EnemyCreeps"])
  local distanceLine = Vector3.Distance2DSq(pos1, pos2)
  local x1, x2, y1, y2 = pos1.x, pos2.x, pos1.y, pos2.y
  local spaceBetween = 50 * 50
  for _, ally in pairs(tAllies) do
    local posAlly = ally:GetPosition()
    local x3, y3 = posAlly.x, posAlly.y
    local calc = x1*y2 - x2*y1 + x2*y3 - x3*y2 + x3*y1 - x1*y3
    local calc2 = calc * calc
    local actual = calc2 / distanceLine
    if actual < spaceBetween then
      core.DrawXPosition(posAlly, "red", 25)
      return false
    end
  end
  for _, creep in pairs(tEnemies) do
    local posCreep = creep:GetPosition()
    local x3, y3 = posCreep.x, posCreep.y
    local calc = x1*y2 - x2*y1 + x2*y3 - x3*y2 + x3*y1 - x1*y3
    local calc2 = calc * calc
    local actual = calc2 / distanceLine
    if actual < spaceBetween then
      core.DrawXPosition(posCreep, "red", 25)
      return false
    end
  end
  core.DrawDebugLine(pos1, pos2, "green")
  return true
end

local function DetermineHookTarget(hook)
  local tLocalEnemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  local maxDistance = hook:GetRange()
  local maxDistanceSq = maxDistance * maxDistance
  local myPos = core.unitSelf:GetPosition()
  local unitTarget = nil
  local distanceTarget = 999999999
  for _, unitEnemy in pairs(tLocalEnemies) do
    local enemyPos = unitEnemy:GetPosition()
    local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
    core.DrawXPosition(enemyPos, "yellow", 50)
    if distanceEnemy < maxDistanceSq then
      if distanceEnemy < distanceTarget and IsFreeLine(myPos, enemyPos) then
        unitTarget = unitEnemy
        distanceTarget = distanceEnemy
      end
    end
  end
  return unitTarget
end

local hookTarget = nil
local function HookUtility(botBrain)
  local hook = skills.hook
  if hook and hook:CanActivate() then
    local unitTarget = DetermineHookTarget(hook)
    if unitTarget then
      hookTarget = unitTarget:GetPosition()
      core.DrawXPosition(hookTarget, "green", 50)
      return 0
    end
  end
  hookTarget = nil
  return 0
end
local function HookExecute(botBrain)
  local hook = skills.hook
  if hook and hook:CanActivate() and hookTarget then
    return core.OrderAbilityPosition(botBrain, hook, hookTarget)
  end
  return false
end
local HookBehavior = {}
HookBehavior["Utility"] = HookUtility
HookBehavior["Execute"] = HookExecute
HookBehavior["Name"] = "Hooking"
tinsert(behaviorLib.tBehaviors, HookBehavior)

local RotEnableBehavior = {}
local function HasEnemiesInRange(unit, range)
  local enemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  local rangeSq = range * range
  local myPos = unit:GetPosition()
  for _, enemy in pairs(enemies) do
    if Vector3.Distance2DSq(enemy:GetPosition(), myPos) < rangeSq then
      return true
    end
  end
  return false
end
local function RotEnableUtility(botBrain)
  local rot = skills.rot
  local rotRange = rot:GetTargetRadius()
  local hasEffect = core.unitSelf:HasState("State_Devourer_Ability2_Self")
  local hasEnemiesClose = HasEnemiesInRange(core.unitSelf, rotRange)
  if rot:CanActivate() and hasEnemiesClose and not hasEffect then
    return 50
  end
  return 0
end
local function RotEnableExecute(botBrain)
  local rot = skills.rot
  if rot and rot:CanActivate() then
    return core.OrderAbility(botBrain, rot)
  end
  return false
end
RotEnableBehavior["Utility"] = RotEnableUtility
RotEnableBehavior["Execute"] = RotEnableExecute
RotEnableBehavior["Name"] = "Rot enable"
tinsert(behaviorLib.tBehaviors, RotEnableBehavior)

local RotDisableBehavior = {}
local function RotDisableUtility(botBrain)
  local rot = skills.rot
  local rotRange = rot:GetTargetRadius()
  local hasEffect = core.unitSelf:HasState("State_Devourer_Ability2_Self")
  local hasEnemiesClose = HasEnemiesInRange(core.unitSelf, rotRange)
  if rot:CanActivate() and hasEffect and not hasEnemiesClose then
    --muutin tätä oli ennen 1000
    return 100
  end
  return 0
end
local function RotDisableExecute(botBrain)
  local rot = skills.rot
  if rot and rot:CanActivate() then
    return core.OrderAbility(botBrain, rot)
  end
  return false
end
RotDisableBehavior["Utility"] = RotDisableUtility
RotDisableBehavior["Execute"] = RotDisableExecute
RotDisableBehavior["Name"] = "Rot disable"
tinsert(behaviorLib.tBehaviors, RotDisableBehavior)



local UltiBehavior = {}
local function UltiUtility(botBrain)
  local ulti = skills.ulti
  -- Tarkista tornirange jossain vaiheessa 
  if ulti:CanActivate() and ulti:GetManaCost() < core.unitSelf:GetMana() then
    return 0
  end
  return 0
end

local function UltiExecute(botBrain)
  local hook = skills.hook
  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil or not unitTarget:IsValid() then
    return false --can not execute, move on to the next behavior
  end

  local unitSelf = core.unitSelf

  if unitSelf:IsChanneling() then
    return
  end

  local bActionTaken = false

  --since we are using an old pointer, ensure we can still see the target for entity targeting
  if core.CanSeeUnit(botBrain, unitTarget) then
    local dist = Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition())
    local attkRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget);

    local itemGhostMarchers = core.itemGhostMarchers

    local ulti = skills.ulti
    local ultiRange = ulti and (ulti:GetRange() + core.GetExtraRange(unitSelf) + core.GetExtraRange(unitTarget)) or 0

    local bUseUlti = true

    if ulti and ulti:CanActivate() and bUseUlti and dist < ultiRange then
      bActionTaken = core.OrderAbilityEntity(botBrain, ulti, unitTarget)

      if hook and hook:CanActivate()
        then
        core.OrderAbilityPosition(botBrain, hook, unitTarget:GetPosition(), true)
        core.BotEcho("HOOKKASIN")
      end

      elseif (ulti and ulti:CanActivate() and bUseUlti and dist > ultiRange) then
      --move in when we want to ult
      local desiredPos = unitTarget:GetPosition()
      bActionTaken = core.OrderMoveToPosClamp(botBrain, unitSelf, desiredPos, false)
    end
  end

  if not bActionTaken then
    return object.harassExecuteOld(botBrain)
  end
end  

--not core.unitSelf:IsChanneling() and not core.unitSelf:HasState("State_Devourer_Ability4_Self")

UltiBehavior["Utility"] = UltiUtility
UltiBehavior["Execute"] = UltiExecute
UltiBehavior["Name"] = "Ulti enable"
tinsert(behaviorLib.tBehaviors, UltiBehavior)


local function CustomHarassUtilityOverride(target)
  local nUtility = 0

  if skills.hook:CanActivate() then
    nUtility = nUtility + 10
  end

  if skills.ulti:CanActivate() then
    nUtility = nUtility + 40
  end

  return generics.CustomHarassUtility(target) + nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride





  -- Harass hero
  local function HarassHeroExecuteOverride(botBrain)
    local hook = skills.hook
    local unitTarget = behaviorLib.heroTarget
    if unitTarget == nil or not unitTarget:IsValid() then
      return false --can not execute, move on to the next behavior
    end

    local unitSelf = core.unitSelf

    if unitSelf:IsChanneling() then
      return
    end

    local bActionTaken = false

    --since we are using an old pointer, ensure we can still see the target for entity targeting
    if core.CanSeeUnit(botBrain, unitTarget) then
      local dist = Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition())
      local attkRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget);

      local itemGhostMarchers = core.itemGhostMarchers

      local ulti = skills.ulti
      local ultiRange = ulti and (ulti:GetRange() + core.GetExtraRange(unitSelf) + core.GetExtraRange(unitTarget)) or 0


      if ulti and ulti:CanActivate() then
        if dist < ultiRange then
          bActionTaken = core.OrderAbilityEntity(botBrain, ulti, unitTarget)


        else 
        --move in when we want to ult
        local desiredPos = unitTarget:GetPosition()
        bActionTaken = core.OrderMoveToPosClamp(botBrain, unitSelf, desiredPos, false)
      end
    end
    if not bActionTaken and hook and hook:CanActivate() then 
     core.OrderAbilityPosition(botBrain, hook, unitTarget:GetPosition())
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

 -- for id,unit in pairs (HoN.GetUnitsInRadius(core.allyWell:GetPosition(), 100000, core.UNIT_MASK_ALIVE + core.UNIT_MASK_UNIT)) do
 --    BotEcho(id, unit)
 --    local nimi = unit:GetTypeName()
 --    local id = unit:GetOwnerPlayerID()
 -- end

 self:onthinkOld(tGameVariables)

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
  local addBonus = 0
  self:oncombateventOld(EventData)
  --eventsLib.printCombatEvent(EventData)
  --core.BotEcho(EventData.SourceUnit:GetUniqueID())
  
  if EventData.Type == "Ability" and EventData.SourceUnit:GetUniqueID() == core.unitSelf:GetUniqueID() and  EventData.InflictorName == "Ability_Devourer4"  then
    addBonus = addBonus + 100
  end

  if addBonus > 0 then
    core.nHarassBonus = core.nHarassBonus + addBonus
  end

  if EventData.InflictorName == "Projectile_Devourer_Ability1" and EventData.SourceUnit:GetUniqueID() == core.unitSelf:GetUniqueID() then
    if EventData.Type == "Attack" then
      local victim = EventData.TargetUnit
      if victim:IsHero() then
                unitHooked = victim
      end
      elseif EventData.Type == "Projectile_Target" and EventData.TargetUnit:GetUniqueID() == core.unitSelf:GetUniqueID() then
        if unitHooked then
          local teamBotBrain = core.teamBotBrain
          if teamBotBrain.SetTeamTarget then
            core.BotEcho("SENT TARGET!")
            teamBotBrain:SetTeamTarget(unitHooked)
          end
        end
        unitHooked = nil
      end
    end
  end

-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride


local function AttackCreepsUtilityOverride(botBrain)  
  local nDenyVal = -100
  local nLastHitVal = -100
  local nUtility = 0

  -- Don't deny while pushing
  local unitDenyTarget = core.unitAllyCreepTarget
  if core.GetCurrentBehaviorName(botBrain) == "Push" then
    unitDenyTarget = nil
  end
  
  local unitTarget = behaviorLib.GetCreepAttackTarget(botBrain, core.unitEnemyCreepTarget, unitDenyTarget)
  
  if unitTarget then --[[and core.unitSelf:IsAttackReady() then]]
    if unitTarget:GetTeam() == core.myTeam then
      nUtility = nDenyVal
    else
      nUtility = nLastHitVal
    end
    
    core.unitCreepTarget = unitTarget
  end

  if botBrain.bDebugUtility == true and nUtility ~= 0 then
    BotEcho(format("  AttackCreepsUtility: %g", nUtility))
  end

  return nUtility
end

behaviorLib.AttackCreepsBehavior["Utility"] = AttackCreepsUtilityOverride



--items
behaviorLib.StartingItems = {"Item_IronBuckler", "Item_ManaBattery", "Item_MinorTotem", "Item_HealthPotion"}
behaviorLib.LaneItems =
        {"Item_PowerSupply", "Item_Marchers", "Item_MysticVestments"} -- Shield2 is HotBL
        behaviorLib.MidItems =
        {"Item_Steamboots", "Item_Shield2", "Item_SolsBulwark"}
        behaviorLib.LateItems =
        {"Item_DaemonicBreastplate", "Item_BehemothsHeart", "Item_Wingbow", "Item_Evasion", "Item_Protect", "Item_Morph"}

        BotEcho('finished loading devourer_main')
