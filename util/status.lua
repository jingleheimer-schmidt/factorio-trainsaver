
-- return true if player has been watching an active train for longer than the driving minimum
---@param player LuaPlayer
---@return boolean
local function exceeded_driving_minimum(player)
    local driving_until_tick = global.driving_until_tick and global.driving_until_tick[player.index]
    if driving_until_tick and (driving_until_tick < game.tick) then
        return true
    else
        return false
    end
end

-- return true if player has been watching a stopped train at a station for longer than the station minimum
---@param player LuaPlayer
---@return boolean
local function exceeded_station_minimum(player)
    local stationed_until_tick = global.wait_station_until_tick and global.wait_station_until_tick[player.index]
    if stationed_until_tick and (stationed_until_tick < game.tick) then
        return true
    else
        return false
    end
end

-- return true if player has been watching a train that has been waiting at a signal for longer than the wait at signal minimum
---@param player LuaPlayer
---@return boolean
local function exceeded_signal_minimum(player)
    local wait_signal_until_tick = global.wait_signal_until_tick and global.wait_signal_until_tick[player.index]
    if wait_signal_until_tick and (wait_signal_until_tick < game.tick) then
        return true
    else
        return false
    end
end

-- return true if player has been watching a spidertron for longer than the driving minimum
---@param player LuaPlayer
---@return boolean
local function exceeded_spider_walking_minimum(player)
    local spider_walking_until_tick = global.spider_walking_until_tick and global.spider_walking_until_tick
    [player.index]
    if spider_walking_until_tick and (spider_walking_until_tick < game.tick) then
        return true
    else
        return false
    end
end

-- return true if player has been watching a stopped spidertron for longer than the station minimum
---@param player LuaPlayer
---@return boolean
local function exceeded_spider_idle_minimum(player)
    local spider_idle_until_tick = global.spider_idle_until_tick and global.spider_idle_until_tick[player.index]
    if spider_idle_until_tick and (spider_idle_until_tick < game.tick) then
        return true
    else
        return false
    end
end

-- return true if trainsaver is active for given player, or false if not
---@param player LuaPlayer
---@return boolean
local function trainsaver_is_active(player)
    if not (player.controller_type == defines.controllers.cutscene) then
        return false
    end
    if global.trainsaver_status and global.trainsaver_status[player.index] then
        return true
    else
        return false
    end
end

return {
    exceeded_driving_minimum = exceeded_driving_minimum,
    exceeded_station_minimum = exceeded_station_minimum,
    exceeded_signal_minimum = exceeded_signal_minimum,
    exceeded_spider_walking_minimum = exceeded_spider_walking_minimum,
    exceeded_spider_idle_minimum = exceeded_spider_idle_minimum,
    trainsaver_is_active = trainsaver_is_active
}
