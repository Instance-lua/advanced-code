local HttpService = game:GetService("HttpService")

local Guid = {}

function Guid.Create()
    return HttpService:GenerateGUID(false)
end

return Guid
