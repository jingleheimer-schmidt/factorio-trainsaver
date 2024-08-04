
local constants = require("util.constants")
local verbose_states = constants.verbose_states
local active_states = constants.active_states
local wait_station_states = constants.wait_station_states
local wait_signal_states = constants.wait_signal_states
local always_accept_new_target_states = constants.always_accept_new_target_states

local message_util = require("util.message")
local get_chatty_name = message_util.get_chatty_name
local chatty_print = message_util.chatty_print

local target_util = require("util.target")
local target_is_locomotive = target_util.target_is_locomotive
local target_is_spider = target_util.target_is_spider
local target_is_rocket_silo = target_util.target_is_rocket_silo
local current_trainsaver_target = target_util.current_trainsaver_target

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
    local spider_walking_until_tick = global.spider_walking_until_tick and global.spider_walking_until_tick[player.index]
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

---@param player LuaPlayer
---@param waypoint_target LuaEntity|LuaUnitGroup?
---@return boolean
local function waypoint_target_passes_inactivity_checks(player, waypoint_target)
    local bool = false
    waypoint_target = waypoint_target or current_trainsaver_target(player)
    if not waypoint_target then return true end
    local current_target_name = get_chatty_name(waypoint_target)
    local chatty_name = get_chatty_name(player)
    global.cutscene_ending = global.cutscene_ending or {}
    if global.cutscene_ending[player.index] then
        chatty_print(chatty_name .. "denied. trainsaver is ending")
        bool = false
    elseif target_is_locomotive(waypoint_target) then
        local locomotive = waypoint_target
        local state = locomotive.train.state
        local exceeds_driving = active_states[state] and exceeded_driving_minimum(player)
        local exceeds_station = wait_station_states[state] and exceeded_station_minimum(player)
        local exceeds_signal = wait_signal_states[state] and exceeded_signal_minimum(player)
        if exceeds_driving or exceeds_station or exceeds_signal then
            chatty_print(chatty_name .. "accepted. current target [" .. current_target_name .. "] has exceeded the minimum for state [" .. verbose_states[state] .. "]")
            bool = true
        elseif always_accept_new_target_states[state] then
            chatty_print(chatty_name .. "accepted. current target [" .. current_target_name .. "] has state [" .. verbose_states[state] .. "]")
            bool = true
        else
            chatty_print(chatty_name .. "denied. current target [" .. current_target_name .. "] has not exceeded the minimum for state [" .. verbose_states[state] .. "]")
            bool = false
        end
    elseif target_is_spider(waypoint_target) then
        local next_destination = waypoint_target.autopilot_destinations[1]
        local speed = waypoint_target.speed
        local spider_is_walking = speed > 0
        local spider_is_still = speed == 0
        if spider_is_walking and next_destination then
            if exceeded_spider_walking_minimum(player) then
                chatty_print(chatty_name .. "accepted. current target [" .. current_target_name .. "] has exceeded the minimum for walking spidertron")
                bool = true
            else
                chatty_print(chatty_name .. "denied. current target [" .. current_target_name .. "] has not exceeded the minimum for walking spidertron")
                bool = false
            end
        elseif spider_is_still then
            if exceeded_spider_idle_minimum(player) then
                chatty_print(chatty_name .. "accepted. current target [" .. current_target_name .. "] has exceeded the minimum for idle spidertron")
                bool = true
            else
                chatty_print(chatty_name .. "denied. current target [" .. current_target_name .. "] has not exceeded the minimum for idle spidertron")
                bool = false
            end
        else
            chatty_print(chatty_name .. "denied. current target [" .. current_target_name .. "] is settling down")
            bool = false -- when would this happen??
        end
    elseif target_is_rocket_silo(waypoint_target) then
        chatty_print(chatty_name .. "denied. current target [" .. current_target_name .. "] is launching a rocket")
        bool = false
    end
    return bool
end

return {
    exceeded_driving_minimum = exceeded_driving_minimum,
    exceeded_station_minimum = exceeded_station_minimum,
    exceeded_signal_minimum = exceeded_signal_minimum,
    exceeded_spider_walking_minimum = exceeded_spider_walking_minimum,
    exceeded_spider_idle_minimum = exceeded_spider_idle_minimum,
    trainsaver_is_active = trainsaver_is_active,
    waypoint_target_passes_inactivity_checks = waypoint_target_passes_inactivity_checks,
}
