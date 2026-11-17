local Players = game:GetService("Players")

local InterfaceController = {}
InterfaceController.__index = InterfaceController

function InterfaceController.new(selectionController)
    return setmetatable({
        Player = Players.LocalPlayer,
        SelectionController = selectionController,
        Connections = {},
    }, InterfaceController)
end

function InterfaceController:FindInterface()
    local PlayerGui = self.Player:WaitForChild("PlayerGui")
    return PlayerGui:WaitForChild("MainGUI")
end

function InterfaceController:ConnectButton(Button, Callback)
    if not Button or not Button:IsA("GuiButton") then
        warn("InterfaceController: Invalid button")
        return
    end

    local Connection = Button.Activated:Connect(Callback)
    table.insert(self.Connections, Connection)
end

function InterfaceController:Start()
    local MainGUI = self:FindInterface()

    local DamageButton = MainGUI:WaitForChild("DamageButton")
    local RepairButton = MainGUI:WaitForChild("RepairButton")
    local BuildButton = MainGUI:WaitForChild("BuildButton")

    self:ConnectButton(DamageButton, function()
        self.SelectionController:RequestAction("Damage")
    end)

    self:ConnectButton(RepairButton, function()
        self.SelectionController:RequestAction("Repair")
    end)

    self:ConnectButton(BuildButton, function()
        self.SelectionController.Remotes.BuildingUpdate:FireServer("Build")
    end)
end

function InterfaceController:Destroy()
    for _, Connection in ipairs(self.Connections) do
        Connection:Disconnect()
    end

    table.clear(self.Connections)
end

return InterfaceController
