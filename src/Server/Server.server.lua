local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EngineConfig = require(ReplicatedStorage.Shared.Config.EngineConfig)
local Guid = require(ReplicatedStorage.Shared.Utilities.Guid)
local RateLimiter = require(ReplicatedStorage.Shared.Utilities.RateLimiter)

local RemoteService = require(script.Parent.Services.RemoteService)
local BuildingService = require(script.Parent.Services.BuildingService)
local IntegrityService = require(script.Parent.Services.IntegrityService)
local DamageService = require(script.Parent.Services.DamageService)
local ConstructionService = require(script.Parent.Services.ConstructionService)

local remoteService = RemoteService.new()
local buildingService = BuildingService.new(remoteService)
local integrityService = IntegrityService.new(buildingService, remoteService)
local damageService = DamageService.new(buildingService, integrityService, remoteService)
local constructionService = ConstructionService.new(buildingService, integrityService)
local rateLimiter = RateLimiter.new()

local sampleBuilding = constructionService:CreateSampleBuilding(EngineConfig.SampleBuildingOrigin)

local function getRoot(player)
    local character = player.Character
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

local function isInRange(player, component)
    local root = getRoot(player)
    if not root or not component or not component.Instance.Parent then
        return false
    end

    return (root.Position - component.Instance.Position).Magnitude <= EngineConfig.InteractionDistance
end

local function findNearestBuildingComponent(position)
    local nearest
    local nearestDistance = EngineConfig.InteractionDistance

    for _, component in pairs(buildingService.Components) do
        local part = component.Instance
        if part and part.Parent then
            local distance = (position - part.Position).Magnitude
            if distance < nearestDistance then
                nearest = component
                nearestDistance = distance
            end
        end
    end

    return nearest
end

local function handleComponentAction(player, action, componentId)
    if typeof(action) ~= "string" or typeof(componentId) ~= "string" then
        return
    end

    local component = buildingService:GetComponent(componentId)
    if not component or not isInRange(player, component) then
        return
    end

    if action == "Damage" then
        if not rateLimiter:Allow(player, "Damage", EngineConfig.DamageCooldown) then
            return
        end
        damageService:ApplyDamage(componentId, EngineConfig.DamageAmount, player.UserId)
    elseif action == "Repair" then
        if not rateLimiter:Allow(player, "Repair", EngineConfig.RepairCooldown) then
            return
        end
        damageService:Repair(componentId, EngineConfig.RepairAmount)
    end
end

local function handleBuildRequest(player)
    if not rateLimiter:Allow(player, "Build", EngineConfig.BuildCooldown) then
        return
    end

    local root = getRoot(player)
    if not root then
        return
    end

    local targetPosition = root.Position + root.CFrame.LookVector * 8
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {player.Character}

    local result = Workspace:Raycast(
        targetPosition + Vector3.new(0, 8, 0),
        Vector3.new(0, -24, 0),
        raycastParams
    )

    local placePosition = result and result.Position or targetPosition
    local component = constructionService:Place(
        sampleBuilding.Id,
        "Pillar",
        CFrame.new(placePosition + Vector3.new(0, 2, 0)),
        Vector3.new(1, 4, 1)
    )

    if component then
        local closest = findNearestBuildingComponent(component.Instance.Position + Vector3.new(0, 2, 0))
        if closest and closest.Id ~= component.Id then
            constructionService:Connect(component.Id, closest.Id)
        end
    end
end

remoteService:Get("ComponentAction").OnServerEvent:Connect(handleComponentAction)
remoteService:Get("RequestSelection").OnServerEvent:Connect(function(player, componentId)
    if typeof(componentId) ~= "string" then
        return
    end

    local component = buildingService:GetComponent(componentId)
    if component and isInRange(player, component) then
        remoteService:FireClient(player, "ComponentUpdate", "Selected", buildingService:SerializeComponent(component))
    end
end)

remoteService:Get("BuildingUpdate").OnServerEvent:Connect(function(player, action)
    if action == "Build" then
        handleBuildRequest(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    rateLimiter:RemovePlayer(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.defer(function()
        remoteService:FireClient(player, "BuildingUpdate", "Snapshot", buildingService:SerializeBuilding(sampleBuilding))
    end)
end

Players.PlayerAdded:Connect(function(player)
    task.delay(2, function()
        if player.Parent then
            remoteService:FireClient(player, "BuildingUpdate", "Snapshot", buildingService:SerializeBuilding(sampleBuilding))
        end
    end)
end)
