local _G = getfenv(0)
local object = _G.object

runfile 'bots/teambot/teambotbrain.lua'

local core = object.core

object.myName = 'Default Team'

local function MarkProjectiles(botBrain)
  local units = HoN.GetUnitsInRadius(Vector3.Create(7500,7500,0), 7500, core.UNIT_MASK_ALIVE + core.UNIT_MASK_GADGET)
  for _, unit in pairs(units) do
    --core.BotEcho(unit:GetTypeName())
    if unit:GetTypeName() == "Gadget_Valkyrie_Ability2_Reveal" and unit:GetTeam() ~= core.myTeam then
      local arrowPos = unit:GetPosition()
      local heading = unit:GetHeading()
      local headingPos = arrowPos + unit:GetHeading() * 100
      core.DrawDebugArrow(arrowPos, headingPos, "red")
    end
  end
  for _, hero in pairs(botBrain.tEnemyHeroes) do
    local beha = hero:GetBehavior()
    if beha and beha:GetType() == "Ability" then
      local goalPos = beha:GetGoalPosition()
      if goalPos then
        core.DrawXPosition(goalPos, "red", 500)
      end
      --core.BotEcho(beha:GetType())
    end
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
  MarkProjectiles(object)
  -- custom code here
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride

local unitTeamTarget = nil

function object:GetTeamTarget()
  if unitTeamTarget and unitTeamTarget:IsValid() then
    if self:CanSeeUnit(unitTeamTarget) then
      return self:GetMemoryUnit(unitTeamTarget)
    else
      unitTeamTarget = nil
    end
  end
  return nil
end

function object:SetTeamTarget(target)
  local old = self:GetTeamTarget()
  if old then
    local basePos = core.allyMainBaseStructure:GetPosition()
    if Vector3.Distance2D(basePos, old:GetPosition()) < Vector3.Distance2D(basePos, target:GetPosition()) then
      return
    end
  end
  unitTeamTarget = target
end

local STATE_IDLE      = 0
local STATE_GROUPING  = 1
local STATE_PUSHING   = 2
object.nPushState = STATE_IDLE
function object:GroupAndPushLogic()
  self:BuildLanes()
  self.nPushState = STATE_PUSHING
  self.unitPushTarget = core.enemyMainBaseStructure
end
