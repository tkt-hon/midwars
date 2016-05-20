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


local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading monkeyking_main...')

object.heroName = 'Hero_MonkeyKing'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 0, LongSolo = 0, ShortSupport = 0, LongSupport = 0, ShortCarry = 0, LongCarry = 0}

--------------------------------
-- Skills
--------------------------------
-- table listing desired skillbuild. 0=Q(dash), 1=W(vault), 2=E(slam), 3=R(ulti), 4=AttributeBoost
object.tSkills = {
0, 1, 1, 2, 1,
3, 1, 2, 2, 2,
3, 0, 0, 0, 4,
3, 4, 4, 4, 4,
4, 4, 4, 4, 4,
}

local bSkillsValid = false
function object:SkillBuild()

  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.dash = unitSelf:GetAbility(0)
    skills.vault = unitSelf:GetAbility(1)
    skills.slam = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.courier = unitSelf:GetAbility(12)
    if skills.dash and skills.vault and skills.slam and skills.ulti then
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

local function GetLowestHPEnemy() 
  local tLocalEnemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  local HP = 1
  local unitTarget = nil
  for _, unitEnemy in pairs(tLocalEnemies) do
    local enemyHP = unitEnemy:GetHealthPercent()
    if enemyHP < HP or not unitTarget then
      unitTarget = unitEnemy
      HP = enemyHP
    end 
  end
  return unitTarget
end

local function CustomHarassHeroUtilityFnOverride(hero)
  local nUtil = 0
  local unitEnemy = GetLowestHPEnemy()
  behaviorLib.heroTarget = unitEnemy
  if unitEnemy and unitEnemy:GetHealthPercent() < 0.5 then
    core.BotEcho("LET'S GOOOO")
    nUtil = 70
    return nUtil
  end
  return object.HarassUtilityOld(hero)
end
-- assisgn custom Harrass function to the behaviourLib object
object.HarassUtilityOld = behaviorLib.HarassHeroBehavior["Utility"]
behaviorLib.HarassHeroBehavior["Utility"] = CustomHarassHeroUtilityFnOverride 

local function HarassHeroExecuteOverride(botBrain)
  return object.harassExecuteOld(botBrain)
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

local function DetermineClosestEnemy(skill) 
  local tLocalEnemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  local maxDistance = skill:GetRange()
  local maxDistanceSq = maxDistance * maxDistance
  local myPos = core.unitSelf:GetPosition()
  local unitTarget = nil
  local distanceTarget = 9999999
  for _, unitEnemy in pairs(tLocalEnemies) do
    local enemyPos = unitEnemy:GetPosition()
    local distanceEnemy = Vector3.Distance2dSq(myPos, enemyPos)
    if distanceEnemy < maxDistanceSq then
      if distanceEnemy < distanceTarget then
        unitTarget = unitEnemy
        distanceTarget = distanceEnemy
      end
    end
  end
  return unitTarget
end

local function GetClosestCreep()
  local enemyCreeps = core.localUnits["EnemyCreeps"]
  local myPos = core.unitSelf:GetPosition()
  local target = nil
  local distanceTarget = 999999
  for _, unitEnemy in pairs(enemyCreeps) do
    local enemyPos = unitEnemy:GetPosition()
    local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
    if distanceEnemy < distanceTarget then
        target = unitEnemy
        distanceTarget = distanceEnemy
    end
  end
  return target
end

local function ComboUtility(botBrain)
  local dash = skills.dash
  local vault = skills.vault
  local heroTarget = behaviorLib.heroTarget
  local manacost = dash:GetManaCost() + vault:GetManaCost()
  if dash:CanActivate() and vault:CanActivate() and heroTarget and core.unitSelf:GetMana() >= manacost then 
    local maxDistance = dash:GetRange()
    local maxDistanceSq = maxDistance * maxDistance
    local myPos = core.unitSelf:GetPosition()
    local enemyPos = heroTarget:GetPosition()
    local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
    if distanceEnemy < maxDistanceSq then
      core.BotEcho("CO-CO-COMBOO")
      return 100
    end
  end
  return 0
end

local function ComboExecute(botBrain)
  local dash = skills.dash
  local vault = skills.vault
  local slam = skills.slam
  local heroTarget = behaviorLib.heroTarget
  local myUnit = core.unitSelf
  if heroTarget then
    core.OrderMoveToPos(botBrain, myUnit, heroTarget:GetPosition())
    core.OrderAbility(botBrain, dash)
    core.OrderAbilityEntity(botBrain, vault, heroTarget)
    core.OrderMoveToPos(botBrain, myUnit, heroTarget:GetPosition())
    core.OrderMoveToPos(botBrain, myUnit, heroTarget:GetPosition())
    core.OrderMoveToPos(botBrain, myUnit, heroTarget:GetPosition())
    core.OrderMoveToPos(botBrain, myUnit, heroTarget:GetPosition())
    core.OrderMoveToPos(botBrain, myUnit, heroTarget:GetPosition())
    core.OrderMoveToPos(botBrain, myUnit, heroTarget:GetPosition())
    if dash:CanActivate() and vault:CanActivate() then 
      core.OrderAbility(botBrain, dash)
      core.OrderAbilityEntity(botBrain, vault, heroTarget)
    end
  end
end
local ComboBehavior = {}
ComboBehavior["Utility"] = ComboUtility
ComboBehavior["Execute"] = ComboExecute
ComboBehavior["Name"] = "Combo like a motherfucker"
tinsert(behaviorLib.tBehaviors, ComboBehavior)

local function SlamUtility(botBrain)
  local slam = skills.slam
  local dash = skills.dash
  local vault = skills.vault
  local myMana = core.unitSelf:GetMana()
  local fullMana = slam:GetManaCost() + dash:GetManaCost() + vault:GetManaCost() + 100
  if myMana > fullMana and slam:GetLevel() > 2 and slam:CanActivate() then
    local target = GetClosestCreep()
    if target then
      local distanceEnemy = Vector3.Distance2DSq(core.unitSelf:GetPosition(), target:GetPosition())
      if distanceEnemy < 100000 then
        core.BotEcho("should slam")
        return 50
      end
    end
  end
  return 0
end

local function SlamExecute(botBrain)
  local slam = skills.slam
  local myUnit = core.unitSelf
  local target = GetClosestCreep()
  core.OrderMoveToPos(botBrain, myUnit, target:GetPosition())
  core.OrderAbility(botBrain, slam)
end
local SlamBehavior = {}
SlamBehavior["Utility"] = SlamUtility
SlamBehavior["Execute"] = SlamExecute
SlamBehavior["Name"] = "Slam"
tinsert(behaviorLib.tBehaviors, SlamBehavior)

--items
behaviorLib.StartingItems = {"Item_IronBuckler", "Item_HealthPotion", "Item_DuckBoots"}
behaviorLib.LaneItems =
        {"Item_Bottle", "Item_Marchers", "Item_Soulscream"} -- Shield2 is HotBL
        behaviorLib.MidItems =
        {"Item_EnhancedMarchers", "Item_Beastheart" , "Item_Shield2"}
        behaviorLib.LateItems =
        {"Item_Sicarius", "Item_Strength6", "Item_DaemonicBreastplate", "Item_Wingbow", "Item_Doombringer"}

BotEcho('finished loading monkeyking_main')
