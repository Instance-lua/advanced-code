local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local EngineConfig = require(ReplicatedStorage.Shared.Config.EngineConfig)

local SelectionController = {}
SelectionController.__index = SelectionController

function SelectionController.new(remotes)
    return setmetatable({
        Player = Players.LocalPlayer,
        Remotes = remotes,
        SelectedPart = nil,
        SelectedId = nil,
        Highlight = nil,
    }, SelectionController)
end

function SelectionController:Start()
    self.Highlight = Instance.new("Highlight")
    self.Highlight.Name = "ComponentSelection"
    self.Highlight.FillTransparency = 0.78
    self.Highlight.OutlineTransparency = 0
    self.Highlight.OutlineColor = EngineConfig.SelectionColor
    self.Highlight.Enabled = false
    self.Highlight.Parent = self.Player:WaitForChild("PlayerGui")

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:SelectFromMouse()
        elseif input.KeyCode == Enum.KeyCode.F then
            self:RequestAction("Damage")
        elseif input.KeyCode == Enum.KeyCode.R then
            self:RequestAction("Repair")
        elseif input.KeyCode == Enum.KeyCode.B then
            self.Remotes.BuildingUpdate:FireServer("Build")
        end
    end)
end

function SelectionController:SelectFromMouse()
    local mouse = self.Player:GetMouse()
    local target = mouse.Target
    if not target then
        self:ClearSelection()
        return
    end

    local componentId = target:GetAttribute("ComponentId")
    if not componentId then
        self:ClearSelection()
        return
    end

    self.SelectedPart = target
    self.SelectedId = componentId
    self.Highlight.Adornee = target
    self.Highlight.Enabled = true
    self.Remotes.RequestSelection:FireServer(componentId)
end

function SelectionController:ClearSelection()
    self.SelectedPart = nil
    self.SelectedId = nil
    if self.Highlight then
        self.Highlight.Adornee = nil
        self.Highlight.Enabled = false
    end
end

function SelectionController:RequestAction(action)
    if not self.SelectedId then
        return
    end

    self.Remotes.ComponentAction:FireServer(action, self.SelectedId)
end

function SelectionController:GetSelectedId()
    return self.SelectedId
end

return SelectionController
