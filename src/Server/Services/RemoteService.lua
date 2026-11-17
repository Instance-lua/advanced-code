local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = {}
RemoteService.__index = RemoteService

local RemoteNames = {
    "ComponentAction",
    "ComponentUpdate",
    "BuildingUpdate",
    "RequestSelection",
}

function RemoteService.new()
    local self = setmetatable({
        Remotes = {},
    }, RemoteService)

    self:CreateRemotes()
    return self
end

function RemoteService:CreateRemotes()
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "Remotes"
        folder.Parent = ReplicatedStorage
    end

    for _, remoteName in ipairs(RemoteNames) do
        local remote = folder:FindFirstChild(remoteName)
        if not remote then
            remote = Instance.new("RemoteEvent")
            remote.Name = remoteName
            remote.Parent = folder
        end
        self.Remotes[remoteName] = remote
    end
end

function RemoteService:Get(remoteName)
    return self.Remotes[remoteName]
end

function RemoteService:FireAll(remoteName, ...)
    local remote = self:Get(remoteName)
    if remote then
        remote:FireAllClients(...)
    end
end

function RemoteService:FireClient(player, remoteName, ...)
    local remote = self:Get(remoteName)
    if remote then
        remote:FireClient(player, ...)
    end
end

return RemoteService
