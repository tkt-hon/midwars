local _G = getfenv(0)
local object = _G.object

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog

object.generics = {}
local generics = object.generics

BotEcho("loading default generics ..")

--alunperin tämä oli 250, voisi ehkä olla isompi kuin 500
behaviorLib.nPositionSelfAllySeparation = 700




--tsekkaa montako open slottia stashish on
local function NumberSlotsOpenStash(inventory)

  local numOpen = 0
  --laske stash slotit
  for slot = 7, 12, 1 do
    curItem = inventory[slot]
    if curItem == nil then
      --nil on free slot --> lisää numOpen + 1
      numOpen = numOpen + 1
    end
  end
  return numOpen
end

local count = 0
--Send items with courier
local function CourierUtility(botBrain)
--Jos stashissä itemeitä palauta korkea arvo


local inventory = core.unitSelf:GetInventory(true)
local openSlots = NumberSlotsOpenStash(inventory)

  --käydään kaikki unitit läpi, jos on olemassa oma courier, niin palautetaan 0, koska silloin courier on liikkellä
  --jos haluat optimoida, laita katsomaan pienemmältä alueelta kuin 100000 :D silloin pitää tosin pistää muistiin courierin state

  for id,unit in pairs (HoN.GetUnitsInRadius(core.allyWell:GetPosition(), 100000, core.UNIT_MASK_ALIVE + core.UNIT_MASK_UNIT)) do
    local nimi = unit:GetTypeName()
    local id = unit:GetOwnerPlayerID()
    
    if nimi == "Pet_AutomatedCourier" and id == core.unitSelf:GetOwnerPlayerID() then 

      return 0
      
    end

 end
  
  if openSlots ~= 6 then 
    return 100
  end

  return 0
end



local function CourierExecute(botBrain)
  --lähettää itemit courierilla
  
  return core.OrderAbility(botBrain, skills.courier)

end


local CourierBehavior = {}
CourierBehavior["Utility"] = CourierUtility
CourierBehavior["Execute"] = CourierExecute
CourierBehavior["Name"] = "Courier"
tinsert(behaviorLib.tBehaviors, CourierBehavior)






-------- Behavior Fns --------
local function ShopUtilityOverride(botBrain)
  behaviorLib.DetermineBuyState(botBrain)

  --tarkastetaan, onko tarpeeksi rahaa ostaa item
  local nextItemDef = behaviorLib.DetermineNextItemDef(botBrain)
  local kultaMaara = botBrain:GetGold()
  local itemCost = core.unitSelf:GetItemCostRemaining(nextItemDef)


  
  if nextItemDef and itemCost > 0 and kultaMaara > itemCost and NumberSlotsOpenStash(core.unitSelf:GetInventory(true)) > 0  then  
    return 100
  end

  return 0
end


local function ShopExecuteOverride(botBrain)

--[[
Current algorithm:
    A) Buy items from the list
    B) Swap items to complete recipes
    C) Swap items to fill inventory, prioritizing...
       1. Boots / +ms
       2. Magic Armor
       4. Most Expensive Item(s) (price decending)
       --]]
       if object.bUseShop == false then
        return
      end

  -- Space out your buys
  if behaviorLib.nextBuyTime > HoN.GetGameTime() then
    return
  end

  behaviorLib.nextBuyTime = HoN.GetGameTime() + behaviorLib.buyInterval

  --Determine where in the pattern we are (mostly for reloads)
  if behaviorLib.buyState == behaviorLib.BuyStateUnknown then
    behaviorLib.DetermineBuyState(botBrain)
  end
  
  local unitSelf = core.unitSelf
  local bShuffled = false
  local bGoldReduced = false
  local tInventory = core.unitSelf:GetInventory(true)
  local nextItemDef = behaviorLib.DetermineNextItemDef(botBrain)
  local bMyTeamHasHuman = core.MyTeamHasHuman()
  local bBuyTPStone = (core.nDifficulty ~= core.nEASY_DIFFICULTY) or bMyTeamHasHuman

  if behaviorLib.printShopDebug then
    BotEcho("============ BuyItems ============")
    if nextItemDef then
      BotEcho("BuyItems - nextItemDef: "..nextItemDef:GetName())
    else
      BotEcho("ERROR: BuyItems - Invalid ItemDefinition returned from DetermineNextItemDef")
    end
  end

  if nextItemDef ~= nil then
    core.teamBotBrain.bPurchasedThisFrame = true
    
    --open up slots if we don't have enough room in the stash + inventory
    local componentDefs = unitSelf:GetItemComponentsRemaining(nextItemDef)
    local slotsOpen = behaviorLib.NumberSlotsOpen(tInventory)

    if behaviorLib.printShopDebug then
      BotEcho("Component defs for "..nextItemDef:GetName()..":")
      core.printGetNameTable(componentDefs)
      BotEcho("Checking if we need to sell items...")
      BotEcho("  #components: "..#componentDefs.."  slotsOpen: "..slotsOpen)
    end

    if #componentDefs > slotsOpen + 1 then --1 for provisional slot
      behaviorLib.SellLowestItems(botBrain, #componentDefs - slotsOpen - 1)
      elseif #componentDefs == 0 then
        behaviorLib.ShuffleCombine(botBrain, nextItemDef, unitSelf)
      end

      local nGoldAmountBefore = botBrain:GetGold()

      if nextItemDef ~= nil and unitSelf:GetItemCostRemaining(nextItemDef) < nGoldAmountBefore then
        unitSelf:PurchaseRemaining(nextItemDef)
      end

      local nGoldAmountAfter = botBrain:GetGold()
      bGoldReduced = (nGoldAmountAfter < nGoldAmountBefore)

    --Check to see if this purchased item has uncombined parts
    componentDefs = unitSelf:GetItemComponentsRemaining(nextItemDef)
    if #componentDefs == 0 then
      behaviorLib.ShuffleCombine(botBrain, nextItemDef, unitSelf)
    end
    behaviorLib.addItemBehavior(nextItemDef:GetName())
  end

  bShuffled = behaviorLib.SortInventoryAndStash(botBrain)
  
  if not bGoldReduced and not bShuffled then
    if behaviorLib.printShopDebug then
      BotEcho("Finished Buying!")
    end
    
    behaviorLib.finishedBuying = true
  end
  
  return true
end



behaviorLib.ShopBehavior["Utility"] = ShopUtilityOverride
behaviorLib.ShopBehavior["Execute"] = ShopExecuteOverride









function generics.IsFreeLine(pos1, pos2)
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
      return false
    end
  end
  return true
end

function generics.CustomHarassUtility(target)
  local nUtil = 0
  local creepLane = core.GetFurthestCreepWavePos(core.tMyLane, core.bTraverseForward)
  local unitSelf = core.unitSelf
  local myPos = unitSelf:GetPosition()


  local enemyWellPos = core.enemyWell:GetPosition()
  local etaisyys = Vector3.Distance2DSq(myPos, enemyWellPos)

 
  
  if etaisyys < 2081*2037 then
    
    nUtil = nUtil - 10000
  end


  nUtil = nUtil - (1 - unitSelf:GetHealthPercent()) * 100

  if unitSelf:GetHealth() > target:GetHealth() then
   nUtil = nUtil + 10
 end

 if target:IsChanneling() or target:IsDisarmed() or target:IsImmobilized() or target:IsPerplexed() or target:IsSilenced() or target:IsStunned() or unitSelf:IsStealth() then
  nUtil = nUtil + 50
end

local unitsNearby = core.AssessLocalUnits(object, myPos,100)


if core.NumberElements(unitsNearby.AllyHeroes) == 0 then

  if core.GetClosestEnemyTower(myPos, 720) then
    nUtil = nUtil - 100
  end

  for id, creep in pairs(unitsNearby.EnemyCreeps) do
    local creepPos = creep:GetPosition()
    if(creep:GetAttackType() == "ranged" or Vector3.Distance2D(myPos, creepPos) < 20) then
      nUtil = nUtil - 20
    end 
  end
end

return nUtil
end


local function PositionSelfExecuteFix(botBrain)
  local nCurrentTimeMS = HoN.GetGameTime()
  local unitSelf = core.unitSelf
  local vecMyPosition = unitSelf:GetPosition()
  
  if core.unitSelf:IsChanneling() then 
    return
  end

  local vecDesiredPos = vecMyPosition
  local unitTarget = nil
  vecDesiredPos, unitTarget = behaviorLib.PositionSelfLogic(botBrain)

  if vecDesiredPos then
    behaviorLib.MoveExecute(botBrain, vecDesiredPos)
  else
    BotEcho("PositionSelfExecute - nil desired position")
    return false
  end

end
behaviorLib.PositionSelfBehavior["Execute"] = PositionSelfExecuteFix

local function PushExecuteFix(botBrain)
  if core.unitSelf:IsChanneling() then 
    return
  end

  local unitSelf = core.unitSelf
  local bActionTaken = false

  --Attack creeps if we're in range
  if bActionTaken == false then
    local unitTarget = core.unitEnemyCreepTarget
    if unitTarget then
      local nRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
      if unitSelf:GetAttackType() == "melee" then
        --override melee so they don't stand *just* out of range
        nRange = 250
      end

      if unitSelf:IsAttackReady() and core.IsUnitInRange(unitSelf, unitTarget, nRange) then
        bActionTaken = core.OrderAttackClamp(botBrain, unitSelf, unitTarget)
      end

    end
  end
  
  if bActionTaken == false then
    local vecDesiredPos = behaviorLib.PositionSelfLogic(botBrain)
    if vecDesiredPos then
      bActionTaken = behaviorLib.MoveExecute(botBrain, vecDesiredPos)
      
    end
  end
  
  if bActionTaken == false then
    return false
  end
end
behaviorLib.PushBehavior["Execute"] = PushExecuteFix

local sheepstick = nil
function behaviorLib.SheepStickUtil(botBrain)
  local unitSelf = core.unitSelf
  sheepstick = core.GetItem("Item_Morph")


  local hero = behaviorLib.heroTarget

  if sheepstick and sheepstick:CanActivate() and hero then --only when we have a target
    local nRange = sheepstick:GetRange()
    local nDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), hero:GetPosition())
    
    if hero:IsValid() and hero:IsAlive() and nDistanceSq < nRange * nRange and not hero:IsStunned() and not hero:HasState("State_Item4K")then
      return 100
    end
  end
  return 0
end

function behaviorLib.SheepStickExecute(botBrain)
  local unitSelf = core.unitSelf
  return core.OrderItemEntityClamp(botBrain, unitSelf, sheepstick, behaviorLib.heroTarget, false)
end


behaviorLib.tItemBehaviors["Item_Morph"] = {}
behaviorLib.tItemBehaviors["Item_Morph"]["Utility"] = behaviorLib.SheepStickUtil
behaviorLib.tItemBehaviors["Item_Morph"]["Execute"] = behaviorLib.SheepStickExecute
behaviorLib.tItemBehaviors["Item_Morph"]["Name"] = "UseSheepStick"



BotEcho("default generics done.")