local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComponentConfig = require(ReplicatedStorage.Shared.Config.ComponentConfig)
local EngineConfig = require(ReplicatedStorage.Shared.Config.EngineConfig)

local BuildingService = {}
BuildingService.__index = BuildingService

function BuildingService.new(remoteService)
    local self = setmetatable({
        Buildings = {},
        Components = {},
        RemoteService = remoteService,
    }, BuildingService)

    self.BuildingsFolder = Workspace:FindFirstChild("Buildings")
    if not self.BuildingsFolder then
        self.BuildingsFolder = Instance.new("Folder")
        self.BuildingsFolder.Name = "Buildings"
        self.BuildingsFolder.Parent = Workspace
    end

    return self
end

function BuildingService:CreateBuilding(name, parent)
    local buildingId = HttpService:GenerateGUID(false)
    local model = Instance.new("Model")
    model.Name = name or "Building"
    model:SetAttribute("BuildingId", buildingId)
    model.Parent = parent or self.BuildingsFolder

    local state = {
        Id = buildingId,
        Name = model.Name,
        Model = model,
        Components = {},
        ComponentCount = 0,
        Revision = 0,
        IsProcessing = false,
    }

    self.Buildings[buildingId] = state
    return state
end

function BuildingService:CreateComponent(buildingId, componentType, cframe, size, options)
    local building = self.Buildings[buildingId]
    local definition = ComponentConfig.GetDefinition(componentType)

    if not building or not definition then
        return nil, "InvalidBuildingOrType"
    end

    if building.ComponentCount >= EngineConfig.MaximumComponentsPerBuilding then
        return nil, "ComponentLimitReached"
    end

    options = options or {}

    local componentId = HttpService:GenerateGUID(false)
    local part = Instance.new("Part")
    part.Name = componentType
    part.Anchored = options.Anchored ~= false
    part.Size = size or Vector3.new(4, 1, 4)
    part.CFrame = cframe
    part.Material = definition.Material
    part.Color = options.Color or definition.Color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part:SetAttribute("ComponentId", componentId)
    part:SetAttribute("BuildingId", buildingId)
    part:SetAttribute("ComponentType", componentType)
    part.Parent = building.Model

    local component = {
        Id = componentId,
        Type = componentType,
        Instance = part,
        Durability = definition.MaximumDurability,
        MaximumDurability = definition.MaximumDurability,
        Weight = definition.Weight,
        IsSupport = definition.IsSupport,
        IsGrounded = definition.IsSupport and options.Grounded ~= false,
        IsDetached = false,
        Connections = {},
        BuildingId = buildingId,
    }

    building.Components[componentId] = component
    building.ComponentCount += 1
    self.Components[componentId] = component
    building.Revision += 1

    part:SetAttribute("Durability", component.Durability)
    part:SetAttribute("MaximumDurability", component.MaximumDurability)

    self.RemoteService:FireAll("ComponentUpdate", "Created", self:SerializeComponent(component))
    return component
end

function BuildingService:ConnectComponents(firstId, secondId)
    local first = self.Components[firstId]
    local second = self.Components[secondId]

    if not first or not second or firstId == secondId then
        return false, "InvalidComponents"
    end

    if first.BuildingId ~= second.BuildingId then
        return false, "DifferentBuildings"
    end

    first.Connections[secondId] = true
    second.Connections[firstId] = true

    local building = self.Buildings[first.BuildingId]
    building.Revision += 1
    self.RemoteService:FireAll("ComponentUpdate", "Connected", firstId, secondId)

    return true
end

function BuildingService:DisconnectComponents(firstId, secondId)
    local first = self.Components[firstId]
    local second = self.Components[secondId]

    if not first or not second then
        return false
    end

    first.Connections[secondId] = nil
    second.Connections[firstId] = nil

    local building = self.Buildings[first.BuildingId]
    if building then
        building.Revision += 1
    end

    return true
end

function BuildingService:GetBuildingForComponent(componentId)
    local component = self.Components[componentId]
    if not component then
        return nil
    end

    return self.Buildings[component.BuildingId]
end

function BuildingService:RemoveComponent(componentId)
    local component = self.Components[componentId]
    if not component then
        return false
    end

    local building = self.Buildings[component.BuildingId]
    for connectedId in pairs(component.Connections) do
        local connected = self.Components[connectedId]
        if connected then
            connected.Connections[componentId] = nil
        end
    end

    if building then
        building.Components[componentId] = nil
        building.ComponentCount = math.max(0, building.ComponentCount - 1)
        building.Revision += 1
    end

    self.Components[componentId] = nil
    if component.Instance and component.Instance.Parent then
        component.Instance:Destroy()
    end

    self.RemoteService:FireAll("ComponentUpdate", "Removed", componentId)
    return true
end

function BuildingService:SerializeComponent(component)
    return {
        Id = component.Id,
        Type = component.Type,
        BuildingId = component.BuildingId,
        Durability = component.Durability,
        MaximumDurability = component.MaximumDurability,
        IsDetached = component.IsDetached,
        Position = component.Instance.Position,
        Size = component.Instance.Size,
    }
end

function BuildingService:SerializeBuilding(building)
    local components = {}
    for componentId, component in pairs(building.Components) do
        components[componentId] = self:SerializeComponent(component)
    end

    return {
        Id = building.Id,
        Name = building.Name,
        Revision = building.Revision,
        Components = components,
    }
end

function BuildingService:GetComponent(componentId)
    return self.Components[componentId]
end

return BuildingService
