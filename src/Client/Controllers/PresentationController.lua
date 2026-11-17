local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local EngineConfig = require(ReplicatedStorage.Shared.Config.EngineConfig)

local PresentationController = {}
PresentationController.__index = PresentationController

function PresentationController.new(remotes, selectionController)
    return setmetatable({
        Remotes = remotes,
        SelectionController = selectionController,
        DurabilityLabels = {},
    }, PresentationController)
end

function PresentationController:Start()
    self.Remotes.ComponentUpdate.OnClientEvent:Connect(function(eventName, ...)
        self:HandleComponentEvent(eventName, ...)
    end)

    self.Remotes.BuildingUpdate.OnClientEvent:Connect(function(eventName, ...)
        self:HandleBuildingEvent(eventName, ...)
    end)
end

function PresentationController:HandleComponentEvent(eventName, ...)
    if eventName == "Durability" then
        local componentId, durability, maximumDurability, source = ...
        self:UpdateDurability(componentId, durability, maximumDurability)
        local color = source == "Repair" and EngineConfig.RepairColor or EngineConfig.DamageColor
        self:PulseComponent(componentId, color)
    elseif eventName == "Broken" then
        local componentId, position = ...
        self:CreateBurst(position, EngineConfig.DamageColor)
        self:RemoveDurabilityLabel(componentId)
    elseif eventName == "Created" then
        local componentData = ...
        self:CreateDurabilityLabel(componentData.Id)
    elseif eventName == "Removed" then
        local componentId = ...
        self:RemoveDurabilityLabel(componentId)
    end
end

function PresentationController:HandleBuildingEvent(eventName, ...)
    if eventName == "IntegrityChanged" then
        local buildingId, detachedIds = ...
        for _, componentId in ipairs(detachedIds) do
            self:PulseComponent(componentId, EngineConfig.DamageColor)
        end
    end
end

function PresentationController:FindComponent(componentId)
    for _, instance in ipairs(workspace:GetDescendants()) do
        if instance:IsA("BasePart") and instance:GetAttribute("ComponentId") == componentId then
            return instance
        end
    end

    return nil
end

function PresentationController:PulseComponent(componentId, color)
    local part = self:FindComponent(componentId)
    if not part then
        return
    end

    local originalColor = part.Color
    local tween = TweenService:Create(
        part,
        TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 1, true),
        {Color = color}
    )

    tween:Play()
    tween.Completed:Once(function()
        if part.Parent then
            part.Color = originalColor
        end
    end)
end

function PresentationController:CreateBurst(position, color)
    local attachmentPart = Instance.new("Part")
    attachmentPart.Name = "ImpactEffect"
    attachmentPart.Anchored = true
    attachmentPart.CanCollide = false
    attachmentPart.CanQuery = false
    attachmentPart.CanTouch = false
    attachmentPart.Transparency = 1
    attachmentPart.Size = Vector3.one
    attachmentPart.Position = position
    attachmentPart.Parent = workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = ColorSequence.new(color)
    emitter.Lifetime = NumberRange.new(0.2, 0.45)
    emitter.Speed = NumberRange.new(4, 9)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Rate = 0
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Parent = attachmentPart
    emitter:Emit(12)

    Debris:AddItem(attachmentPart, 1)
end

function PresentationController:CreateDurabilityLabel(componentId)
    local part = self:FindComponent(componentId)
    if not part or self.DurabilityLabels[componentId] then
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DurabilityDisplay"
    billboard.Size = UDim2.fromOffset(90, 18)
    billboard.StudsOffset = Vector3.new(0, part.Size.Y / 2 + 0.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Adornee = part
    billboard.Parent = part

    local background = Instance.new("Frame")
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.fromRGB(25, 28, 34)
    background.BorderSizePixel = 0
    background.Parent = billboard

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = EngineConfig.RepairColor
    fill.BorderSizePixel = 0
    fill.Parent = background

    self.DurabilityLabels[componentId] = billboard
end

function PresentationController:UpdateDurability(componentId, durability, maximumDurability)
    local billboard = self.DurabilityLabels[componentId]
    if not billboard then
        self:CreateDurabilityLabel(componentId)
        billboard = self.DurabilityLabels[componentId]
    end

    if not billboard then
        return
    end

    local background = billboard:FindFirstChildOfClass("Frame")
    local fill = background and background:FindFirstChild("Fill")
    if not fill then
        return
    end

    local ratio = math.clamp(durability / math.max(maximumDurability, 1), 0, 1)
    local targetColor = ratio > 0.55 and EngineConfig.RepairColor
        or ratio > 0.25 and Color3.fromRGB(245, 190, 80)
        or EngineConfig.DamageColor

    TweenService:Create(
        fill,
        TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = UDim2.fromScale(ratio, 1),
            BackgroundColor3 = targetColor,
        }
    ):Play()

    billboard.Enabled = true
    task.delay(2.5, function()
        if billboard.Parent then
            billboard.Enabled = false
        end
    end)
end

function PresentationController:RemoveDurabilityLabel(componentId)
    local billboard = self.DurabilityLabels[componentId]
    if billboard then
        billboard:Destroy()
        self.DurabilityLabels[componentId] = nil
    end
end

return PresentationController
