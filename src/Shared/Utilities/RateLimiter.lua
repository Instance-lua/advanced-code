local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new()
    return setmetatable({
        LastAction = {},
    }, RateLimiter)
end

function RateLimiter:Allow(player, actionName, cooldown)
    local now = os.clock()
    local playerActions = self.LastAction[player]

    if not playerActions then
        playerActions = {}
        self.LastAction[player] = playerActions
    end

    local lastAction = playerActions[actionName] or 0
    if now - lastAction < cooldown then
        return false
    end

    playerActions[actionName] = now
    return true
end

function RateLimiter:RemovePlayer(player)
    self.LastAction[player] = nil
end

return RateLimiter
