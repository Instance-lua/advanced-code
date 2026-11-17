local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EngineConfig = require(ReplicatedStorage.Shared.Config.EngineConfig)

local DamageService = {}
DamageService.__index = DamageService

function DamageService.new(buildingService, integrityService, remoteService)
    return setmetatable({
        BuildingService = buildingService,
        IntegrityService = integrityService,
        RemoteService = remoteService,
    }, DamageService)
end

function DamageService:ApplyDamage(componentId, amount, source)
    local component = self.BuildingService:GetComponent(componentId)
    if not component or component.Durability <= 0 then
        return false, "Unavailable"
    end

    amount = math.clamp(amount, 1, 100)
    local previous = component.Durability
    component.Durability = math.max(EngineConfig.MinimumDurability, previous - amount)
    component.Instance:SetAttribute("Durability", component.Durability)

    local building = self.BuildingService:GetBuildingForComponent(componentId)
    if building then
        building.Revision += 1
    end

    self.RemoteService:FireAll(
        "ComponentUpdate",
        "Durability",
        componentId,
        component.Durability,
        component.MaximumDurability,
        source
    )

    if previous > 0 and component.Durability <= 0 then
        self:BreakComponent(component)
    end

    if building then
        self.IntegrityService:Schedule(building)
    end

    return true, component.Durability
end

function DamageService:Repair(componentId, amount)
    local component = self.BuildingService:GetComponent(componentId)
    if not component then
        return false, "Unavailable"
    end

    if component.Durability >= component.MaximumDurability then
        return false, "AlreadyRepaired"
    end

    amount = math.clamp(amount, 1, 100)
    component.Durability = math.min(component.MaximumDurability, component.Durability + amount)
    component.Instance:SetAttribute("Durability", component.Durability)

    local building = self.BuildingService:GetBuildingForComponent(componentId)
    if building then
        building.Revision += 1
        self.IntegrityService:Schedule(building)
    end

    self.RemoteService:FireAll(
        "ComponentUpdate",
        "Durability",
        componentId,
        component.Durability,
        component.MaximumDurability,
        "Repair"
    )

    return true, component.Durability
end

function DamageService:BreakComponent(component)
    local building = self.BuildingService:GetBuildingForComponent(component.Id)
    if not building then
        return
    end

    self.RemoteService:FireAll("ComponentUpdate", "Broken", component.Id, component.Instance.Position)

    if component.Type == "Foundation" then
        component.IsGrounded = false
    end

    if component.Type == "Pillar" then
        component.IsGrounded = false
    end

    if component.Type == "Wall" or component.Type == "Roof" or component.Type == "Floor" then
        component.Instance.CanCollide = false
        component.Instance.Anchored = false
    end

    if component.Type == "Beam" or component.Type == "Pillar" then
        component.Instance.CanCollide = true
        component.Instance.Anchored = false
    end

    task.delay(EngineConfig.CollapseDelay, function()
        if component.Instance and component.Instance.Parent and component.Durability <= 0 then
            component.Instance:Destroy()
            self.BuildingService:RemoveComponent(component.Id)
        end
    end)
end

return DamageService
