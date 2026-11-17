local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EngineConfig = require(ReplicatedStorage.Shared.Config.EngineConfig)

local IntegrityService = {}
IntegrityService.__index = IntegrityService

function IntegrityService.new(buildingService, remoteService)
    return setmetatable({
        BuildingService = buildingService,
        RemoteService = remoteService,
        PendingBuildings = {},
    }, IntegrityService)
end

function IntegrityService:Evaluate(building)
    if not building or building.IsProcessing then
        return
    end

    building.IsProcessing = true

    local reachable = {}
    local queue = {}
    local queueIndex = 1

    for componentId, component in pairs(building.Components) do
        if component.IsSupport and component.IsGrounded and component.Durability > 0 then
            reachable[componentId] = true
            table.insert(queue, componentId)
        end
    end

    while queueIndex <= #queue do
        local currentId = queue[queueIndex]
        queueIndex += 1

        local current = building.Components[currentId]
        if current then
            for connectedId in pairs(current.Connections) do
                local connected = building.Components[connectedId]
                if connected and connected.Durability > 0 and not reachable[connectedId] then
                    reachable[connectedId] = true
                    table.insert(queue, connectedId)
                end
            end
        end
    end

    local detached = {}
    for componentId, component in pairs(building.Components) do
        local shouldDetach = EngineConfig.SupportReachabilityRequired
            and component.Durability > 0
            and component.IsSupport == false
            and not reachable[componentId]

        if component.IsDetached ~= shouldDetach then
            component.IsDetached = shouldDetach
            component.Instance:SetAttribute("IsDetached", shouldDetach)
            component.Instance.Transparency = shouldDetach
                and EngineConfig.DetachedComponentTransparency or 0
            table.insert(detached, componentId)
        end
    end

    building.IsProcessing = false

    if #detached > 0 then
        building.Revision += 1
        self.RemoteService:FireAll("BuildingUpdate", "IntegrityChanged", building.Id, detached)
    end

    return reachable, detached
end

function IntegrityService:Schedule(building)
    if not building then
        return
    end

    if self.PendingBuildings[building.Id] then
        return
    end

    self.PendingBuildings[building.Id] = true

    task.defer(function()
        self.PendingBuildings[building.Id] = nil
        self:Evaluate(building)
    end)
end

return IntegrityService
