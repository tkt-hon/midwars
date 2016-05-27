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

BotEcho('loading nymphora_main...')

object.heroName = 'Hero_Fairy'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 0, ShortSolo = 0, LongSolo = 0, ShortSupport = 5, LongSupport = 5, ShortCarry = 0, LongCarry = 0}

--------------------------------
-- Skills
--------------------------------
-- table listing desired skillbuild. 0=Q(heal), 1=W(mana), 2=E(stun), 3=R(ulti), 4=AttributeBoost
object.tSkills = {
2, 0, 2, 1, 0,
0, 0, 1, 1, 1,
2, 4, 2, 4, 4,
4, 4, 4, 4, 4,
4, 4, 3, 3, 3
}

local bSkillsValid = false
function object:SkillBuild()

  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.heal = unitSelf:GetAbility(0)
    skills.mana = unitSelf:GetAbility(1)
    skills.stun = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.courier = unitSelf:GetAbility(12)
    if skills.heal and skills.mana and skills.stun and skills.ulti then
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





local function ComboUtility(botBrain)
  local heal = skills.heal
  local stun = skills.stun
  local heroTarget = behaviorLib.heroTarget
  local manacost = heal:GetManaCost() + stun:GetManaCost()
  if heal:CanActivate() and stun:CanActivate() and heroTarget and core.unitSelf:GetMana() >= manacost then 
    local maxDistance = stun:GetRange()
    local maxDistanceSq = maxDistance * maxDistance
    local myPos = core.unitSelf:GetPosition()
    local enemyPos = core.unitSelf:GetPosition()
    local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
    if distanceEnemy < maxDistanceSq then
      return 60
    end
  end
  return 0
end

local function ComboExecute(botBrain)
  local heal = skills.heal
  local stun = skills.stun
  local heroTarget = behaviorLib.heroTarget
  local myUnit = core.unitSelf
  if heroTarget then 
    core.OrderAbilityPosition(botBrain, stun, heroTarget:GetPosition())
    return core.OrderAbilityPosition(botBrain, heal, heroTarget:GetPosition())
  end
  return false
end
local ComboBehavior = {}
ComboBehavior["Utility"] = ComboUtility
ComboBehavior["Execute"] = ComboExecute
ComboBehavior["Name"] = "Combo like a motherfucker"
tinsert(behaviorLib.tBehaviors, ComboBehavior)




local function CustomHarassUtilityFnOverride(target)
  local nUtility = 0

  

  return generics.CustomHarassUtility(target) + nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride






local manaTarget = nil
local function FindManaTarget(botBrain, mana)
  if core.unitSelf:GetManaPercent() < 0.6 then
    return core.unitSelf
  end
  local range = mana:GetRange()
  local unitsNearby = core.AssessLocalUnits(botBrain, core.unitSelf, range)
  local heroes = unitsNearby.AllyHeroes
  local target = nil
  local missing = 0
  for _, hero in pairs(heroes) do
    local curMissing = 1 - hero:GetManaPercent()
    if curMissing > missing then
      missing = curMissing
      target = hero
    end
  end
  return target
end


local function ManaUtility(botBrain)
  local mana = skills.mana
  local heal = skills.heal
  local stun = skills.stun
  manaTarget = FindManaTarget(botBrain, mana)
  if mana:CanActivate() and manaTarget and core.unitSelf:GetMana() > 100 then
     return 50
  end
  return 0
end

local function ManaExecute(botBrain)
  local mana = skills.mana
  if mana and mana:CanActivate() then
    return core.OrderAbilityEntity(botBrain, mana, manaTarget)
  end
  return false
end
local ManaBehavior = {}
ManaBehavior["Utility"] = ManaUtility
ManaBehavior["Execute"] = ManaExecute
ManaBehavior["Name"] = "Mana"
tinsert(behaviorLib.tBehaviors, ManaBehavior)

--items
behaviorLib.StartingItems = {"Item_MinorTotem", "Item_MinorTotem", "Item_ManaBattery", "Item_GuardianRing", "Item_HealthPotion"}
behaviorLib.LaneItems =
        {"Item_ManaRegen3", "Item_Marchers", "Item_PowerSupply", "Item_Steamboots"}
        behaviorLib.MidItems =
        {"Item_MysticVestments", "Item_Manatube", "Item_NomesWisdom", "Item_Glowstone", "Item_Lifetube", "Item_Protect"}
        behaviorLib.LateItems =
        {"Item_Protect", "Item_Lightning1", "Item_Morph", "Item_BehemothsHeart", "Item_Critical1 4"}


BotEcho('finished loading nymphora_main')
