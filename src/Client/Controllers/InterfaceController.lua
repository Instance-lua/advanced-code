local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InterfaceController = {}
InterfaceController.__index = InterfaceController

function InterfaceController.new(selectionController)
    return setmetatable({
        Player = Players.LocalPlayer,
        SelectionController = selectionController,
    }, InterfaceController)
end

function InterfaceController:CreateButton(parent, name, text, position, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Position = position
    button.Size = UDim2.fromOffset(112, 38)
    button.BackgroundColor3 = Color3.fromRGB(35, 42, 54)
    button.TextColor3 = Color3.fromRGB(240, 244, 250)
    button.TextSize = 14
    button.Font = Enum.Font.GothamMedium
    button.AutoButtonColor = true
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    button.Activated:Connect(callback)
    return button
end

function InterfaceController:Start()
    local playerGui = self.Player:WaitForChild("PlayerGui")
    local existing = playerGui:FindFirstChild("ArchitectureInterface")
    if existing then
        existing:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ArchitectureInterface"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Name = "ActionPanel"
    panel.AnchorPoint = Vector2.new(0, 1)
    panel.Position = UDim2.new(0, 18, 1, -18)
    panel.Size = UDim2.fromOffset(250, 112)
    panel.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = panel

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Position = UDim2.fromOffset(12, 7)
    title.Size = UDim2.new(1, -24, 0, 22)
    title.BackgroundTransparency = 1
    title.Text = "BUILDING TOOLS"
    title.TextColor3 = Color3.fromRGB(190, 205, 225)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.Parent = panel

    self:CreateButton(panel, "DamageButton", "Damage  [F]", UDim2.fromOffset(12, 38), function()
        self.SelectionController:RequestAction("Damage")
    end)

    self:CreateButton(panel, "RepairButton", "Repair  [R]", UDim2.fromOffset(130, 38), function()
        self.SelectionController:RequestAction("Repair")
    end)

    self:CreateButton(panel, "BuildButton", "Place  [B]", UDim2.fromOffset(12, 72), function()
        ReplicatedStorage.Remotes.BuildingUpdate:FireServer("Build")
    end)

    local hint = Instance.new("TextLabel")
    hint.Name = "Hint"
    hint.Position = UDim2.fromOffset(130, 77)
    hint.Size = UDim2.fromOffset(108, 24)
    hint.BackgroundTransparency = 1
    hint.Text = "Click a part"
    hint.TextColor3 = Color3.fromRGB(150, 160, 175)
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 11
    hint.Parent = panel
end

return InterfaceController
