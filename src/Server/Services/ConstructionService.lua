local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ComponentConfig = require(ReplicatedStorage.Shared.Config.ComponentConfig)

local ConstructionService = {}
ConstructionService.__index = ConstructionService

function ConstructionService.new(buildingService, integrityService)
    return setmetatable({
        BuildingService = buildingService,
        IntegrityService = integrityService,
    }, ConstructionService)
end

function ConstructionService:Place(buildingId, componentType, cframe, size)
    if not ComponentConfig.IsValid(componentType) then
        return nil, "UnknownComponent"
    end

    local component, reason = self.BuildingService:CreateComponent(
        buildingId,
        componentType,
        cframe,
        size
    )

    if not component then
        return nil, reason
    end

    local building = self.BuildingService:GetBuildingForComponent(component.Id)
    self.IntegrityService:Schedule(building)

    return component
end

function ConstructionService:Connect(firstId, secondId)
    local connected, reason = self.BuildingService:ConnectComponents(firstId, secondId)
    if not connected then
        return false, reason
    end

    local building = self.BuildingService:GetBuildingForComponent(firstId)
    self.IntegrityService:Schedule(building)

    return true
end

function ConstructionService:CreateSampleBuilding(origin)
    local building = self.BuildingService:CreateBuilding("Workshop")
    local components = {}

    local function add(componentType, offset, size)
        local component = self:Place(
            building.Id,
            componentType,
            CFrame.new(origin + offset),
            size
        )
        if component then
            table.insert(components, component)
        end
        return component
    end

    local foundation = add("Foundation", Vector3.new(0, 0, 0), Vector3.new(18, 1, 14))
    local leftPillar = add("Pillar", Vector3.new(-7, 4, -5), Vector3.new(1, 8, 1))
    local rightPillar = add("Pillar", Vector3.new(7, 4, -5), Vector3.new(1, 8, 1))
    local rearPillar = add("Pillar", Vector3.new(0, 4, 5), Vector3.new(1, 8, 1))
    local frontBeam = add("Beam", Vector3.new(0, 8, -5), Vector3.new(15, 1, 1))
    local rearBeam = add("Beam", Vector3.new(0, 8, 5), Vector3.new(15, 1, 1))
    local leftBeam = add("Beam", Vector3.new(-7, 8, 0), Vector3.new(1, 1, 11))
    local rightBeam = add("Beam", Vector3.new(7, 8, 0), Vector3.new(1, 1, 11))
    local roof = add("Roof", Vector3.new(0, 9, 0), Vector3.new(16, 1, 12))

    if foundation and leftPillar then self:Connect(foundation.Id, leftPillar.Id) end
    if foundation and rightPillar then self:Connect(foundation.Id, rightPillar.Id) end
    if foundation and rearPillar then self:Connect(foundation.Id, rearPillar.Id) end

    if leftPillar and frontBeam then self:Connect(leftPillar.Id, frontBeam.Id) end
    if rightPillar and frontBeam then self:Connect(rightPillar.Id, frontBeam.Id) end
    if rearPillar and rearBeam then self:Connect(rearPillar.Id, rearBeam.Id) end
    if leftPillar and leftBeam then self:Connect(leftPillar.Id, leftBeam.Id) end
    if rightPillar and rightBeam then self:Connect(rightPillar.Id, rightBeam.Id) end

    if frontBeam and roof then self:Connect(frontBeam.Id, roof.Id) end
    if rearBeam and roof then self:Connect(rearBeam.Id, roof.Id) end
    if leftBeam and roof then self:Connect(leftBeam.Id, roof.Id) end
    if rightBeam and roof then self:Connect(rightBeam.Id, roof.Id) end

    return building
end

return ConstructionService
