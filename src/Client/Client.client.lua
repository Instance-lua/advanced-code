local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SelectionController = require(script.Parent.Controllers.SelectionController)
local PresentationController = require(script.Parent.Controllers.PresentationController)
local InterfaceController = require(script.Parent.Controllers.InterfaceController)

local remoteFolder = ReplicatedStorage:WaitForChild("Remotes")

local remotes = {
    ComponentAction = remoteFolder:WaitForChild("ComponentAction"),
    ComponentUpdate = remoteFolder:WaitForChild("ComponentUpdate"),
    BuildingUpdate = remoteFolder:WaitForChild("BuildingUpdate"),
    RequestSelection = remoteFolder:WaitForChild("RequestSelection"),
}

local selectionController = SelectionController.new(remotes)
local presentationController = PresentationController.new(remotes, selectionController)
local interfaceController = InterfaceController.new(selectionController)

selectionController:Start()
presentationController:Start()
interfaceController:Start()
