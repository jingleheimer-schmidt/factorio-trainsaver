
local constants = require("util.constants")
local active_states = constants.active_states
local wait_station_states = constants.wait_station_states
local wait_signal_states = constants.wait_signal_states
local verbose_states = constants.verbose_states

local message_util = require("util.message")
local get_chatty_name = message_util.get_chatty_name
local chatty_print = message_util.chatty_print

local target_util = require("util.target")
local target_is_entity = target_util.target_is_entity
local target_is_locomotive = target_util.target_is_locomotive
local target_is_spider = target_util.target_is_spider
local target_is_rocket_silo = target_util.target_is_rocket_silo
local current_trainsaver_target = target_util.current_trainsaver_target

local status_util = require("util.status")
local trainsaver_is_active = status_util.trainsaver_is_active


-- remove any globals we saved for the player when trainsaver ends
---@param player_index uint
local function cutscene_ended_nil_globals(player_index)
    storage.create_cutscene_next_tick = storage.create_cutscene_next_tick or {}
    storage.create_cutscene_next_tick[player_index] = nil
    storage.wait_at_signal = storage.wait_at_signal or {}
    storage.wait_at_signal[player_index] = nil
    storage.entity_destroyed_registration_numbers = storage.entity_destroyed_registration_numbers or {}
    storage.entity_destroyed_registration_numbers[player_index] = nil
    storage.rocket_positions = storage.rocket_positions or {}
    storage.rocket_positions[player_index] = nil
    storage.trainsaver_status = storage.trainsaver_status or {}
    storage.trainsaver_status[player_index] = nil
    storage.current_continuous_duration = storage.current_continuous_duration or {}
    storage.current_continuous_duration[player_index] = nil
    storage.current_target = storage.current_target or {}
    storage.current_target[player_index] = nil
    storage.cutscene_ending = storage.cutscene_ending or {}
    storage.cutscene_ending[player_index] = nil
    storage.number_of_waypoints = storage.number_of_waypoints or {}
    storage.number_of_waypoints[player_index] = nil
    storage.driving_until_tick = storage.driving_until_tick or {}
    storage.driving_until_tick[player_index] = nil
    storage.wait_signal_until_tick = storage.wait_signal_until_tick or {}
    storage.wait_signal_until_tick[player_index] = nil
    storage.wait_station_until_tick = storage.wait_station_until_tick or {}
    storage.wait_station_until_tick[player_index] = nil
    storage.wait_station_since_tick = storage.wait_station_since_tick or {}
    storage.wait_station_since_tick[player_index] = nil
    storage.spider_idle_until_tick = storage.spider_idle_until_tick or {}
    storage.spider_idle_until_tick[player_index] = nil
    storage.spider_walking_until_tick = storage.spider_walking_until_tick or {}
    storage.spider_walking_until_tick[player_index] = nil

    -- gobals that aren't supposed to be used any more, but might still exist from older versions of the mod
    storage.followed_loco = storage.followed_loco or {}
    storage.followed_loco[player_index] = nil
    storage.driving_since_tick = storage.driving_since_tick or {}
    storage.driving_since_tick[player_index] = nil
    storage.wait_signal_since_tick = storage.wait_signal_since_tick or {}
    storage.wait_signal_since_tick[player_index] = nil
    storage.station_minimum = storage.station_minimum or {}
    storage.station_minimum[player_index] = nil
    storage.driving_minimum = storage.driving_minimum or {}
    storage.driving_minimum[player_index] = nil
end

-- update all the globals for a newly created cutscene
---@param player LuaPlayer
---@param created_waypoints CutsceneWaypoint[]
local function update_globals_new_cutscene(player, created_waypoints)
    local player_index = player.index
    local waypoint_target = created_waypoints[1].target
    local waypoint_position = created_waypoints[1].position
    local mod_settings = player.mod_settings
    local chatty_name = get_chatty_name(player)
    local signal_minimum = mod_settings["ts-wait-at-signal"].value * 60
    local station_minimum = mod_settings["ts-station-minimum"].value * 60
    local driving_minimum = mod_settings["ts-driving-minimum"].value * 60 * 60
    local current_tick = game.tick
    -- update trainsaver status global
    storage.trainsaver_status = storage.trainsaver_status or {} ---@type table<uint, "active"|nil>
    storage.trainsaver_status[player_index] = "active"
    -- register the followed target so we get an event if it's destroyed, then save the registration number in global so we can know if the destroyed event is for our target or not
    if target_is_entity(waypoint_target) then
        storage.entity_destroyed_registration_numbers = storage.entity_destroyed_registration_numbers or {} ---@type table<uint, uint64>
        storage.entity_destroyed_registration_numbers[player_index] = script.register_on_object_destroyed(waypoint_target --[[@as LuaEntity]])
    end
    -- update the current_target global
    storage.current_target = storage.current_target or {} ---@type table<uint, LuaEntity|LuaCommandable>
    storage.current_target[player_index] = waypoint_target
    -- update number of waypoints global
    storage.number_of_waypoints = storage.number_of_waypoints or {} ---@type table<uint, integer>
    storage.number_of_waypoints[player_index] = #created_waypoints
    -- update the followed_loco global
    if target_is_locomotive(waypoint_target) then
        local locomotive = waypoint_target --[[@as LuaEntity]]
        ---@class FollowedLocomotiveData
        ---@field unit_number uint
        ---@field train_id uint
        ---@field loco LuaEntity
        local followed_locomotive_data = {
            unit_number = locomotive.unit_number,
            train_id = locomotive.train.id,
            loco = locomotive,
        }
        storage.followed_loco = storage.followed_loco or {} ---@type table<uint, FollowedLocomotiveData>
        storage.followed_loco[player_index] = followed_locomotive_data
        -- update driving minimum global
        local state = locomotive.train.state
        if active_states[state] then
            storage.driving_until_tick = storage.driving_until_tick or {} ---@type table<uint, uint|number>
            storage.driving_until_tick[player_index] = current_tick + driving_minimum
            chatty_print(chatty_name .. "acquired new target [" .. get_chatty_name(current_trainsaver_target(player)) .. "]. set driving_until_tick to [" .. storage.driving_until_tick[player.index] .. "]")
        end
        if wait_station_states[state] then
            storage.wait_station_until_tick = storage.wait_station_until_tick or {} ---@type table<uint, uint|number>
            storage.wait_station_until_tick[player_index] = current_tick + station_minimum
            chatty_print(chatty_name .. "acquired new target [" .. get_chatty_name(current_trainsaver_target(player)) .. "]. set wait_station_until_tick to [" .. storage.wait_station_until_tick[player.index] .. "]")
        end
        if wait_signal_states[state] then
            storage.wait_signal_until_tick = storage.wait_signal_until_tick or {} ---@type table<uint, uint|number>
            storage.wait_signal_until_tick[player_index] = current_tick + signal_minimum
            chatty_print(chatty_name .. "acquired new target [" .. get_chatty_name(current_trainsaver_target(player)) .. "]. set wait_signal_until_tick to [" .. storage.wait_signal_until_tick[player.index] .. "]")
        end
        storage.spider_walking_until_tick = storage.spider_walking_until_tick or {}
        storage.spider_walking_until_tick[player_index] = nil
        storage.spider_idle_until_tick = storage.spider_idle_until_tick or {}
        storage.spider_idle_until_tick[player_index] = nil
    end
    -- update the spider_walking_until_tick global
    if target_is_spider(waypoint_target) then
        storage.spider_walking_until_tick = storage.spider_walking_until_tick or {} ---@type table<uint, uint>
        storage.spider_walking_until_tick[player_index] = current_tick + driving_minimum
        storage.spider_idle_until_tick = storage.spider_idle_until_tick or {}
        storage.spider_idle_until_tick[player_index] = current_tick + station_minimum
        chatty_print(chatty_name .. "acquired new target [" .. get_chatty_name(current_trainsaver_target(player)) .. "]. set spider_walking_until_tick to [" .. storage.spider_walking_until_tick[player.index] .. "]")
        storage.wait_signal_until_tick = storage.wait_signal_until_tick or {}
        storage.wait_signal_until_tick[player_index] = nil
        storage.driving_until_tick = storage.driving_until_tick or {}
        storage.driving_until_tick[player_index] = nil
        storage.wait_station_until_tick = storage.wait_station_until_tick or {}
        storage.wait_station_until_tick[player_index] = nil
    end
end

-- if the train that just changed state was the train the camera is following, and it just stopped at a station, then update the station_minimum global
---@param event EventData.on_train_changed_state
local function update_wait_at_station(event)
    local train = event.train
    local new_state = event.train.state
    local old_state = event.old_state
    if not wait_station_states[new_state] then return end
    -- if not active_states[old_state] then return end
    for _, player in pairs(game.connected_players) do
        if not trainsaver_is_active(player) then goto next_player end
        local player_index = player.index
        local current_target = current_trainsaver_target(player)
        if not target_is_locomotive(current_target) then goto next_player end
        local current_target_train = current_target and current_target.train --[[@as LuaTrain]]
        if not (train.id == current_target_train.id) then goto next_player end
        storage.wait_station_until_tick = storage.wait_station_until_tick or {}
        storage.wait_station_until_tick[player_index] = game.tick + player.mod_settings["ts-station-minimum"].value * 60
        if storage.chatty then
            -- local target_name = chatty_target_train_name(train)
            local target_name = get_chatty_name(storage.followed_loco[player_index].loco)
            local chatty_name = get_chatty_name(player)
            game.print(chatty_name .. "current target [" .. target_name .. "] changed to state [" .. verbose_states[train.state] .. "]. wait_station_until_tick set to [" .. storage.wait_station_until_tick[player_index] .. "]")
        end
        ::next_player::
    end
end

-- update the wait_at_signal global
---@param train_changed_state_event EventData.on_train_changed_state
local function update_wait_at_signal(train_changed_state_event)
    local train = train_changed_state_event.train
    local old_state = train_changed_state_event.old_state
    local new_state = train_changed_state_event.train.state
    -- if camera train is waiting at signal, update the storage.wait_at_signal global if necessary, then continue creating the cutscene (cutscene will not be constructed next tick if untill_tick is greater than current tick)
    if --[[(old_state == defines.train_state.arrive_signal) and --]] (new_state == defines.train_state.wait_signal) then
        for _, player in pairs(game.connected_players) do
            if not trainsaver_is_active(player) then goto next_player end
            local current_target = current_trainsaver_target(player)
            if not target_is_locomotive(current_target) then goto next_player end
            local current_target_train = current_target and current_target.train --[[@as LuaTrain]]
            if not (train.id == current_target_train.id) then goto next_player end
            storage.wait_signal_until_tick = storage.wait_signal_until_tick or {}
            storage.wait_signal_until_tick[player.index] = game.tick + (player.mod_settings["ts-wait-at-signal"].value * 60)
            if storage.chatty then
                local target_name = get_chatty_name(train)
                local chatty_name = get_chatty_name(player)
                chatty_print(chatty_name .. "current target [" .. target_name .. "] changed to state [" .. verbose_states[train.state] .. "]. wait_signal_until_tick set to [" .. storage.wait_signal_until_tick[player.index] .. "]")
            end
            ::next_player::
        end
    end
    -- if camera train has switched from waiting at a signal to moving on the path, nil out the waiting at signal global timer thing
    if (old_state == defines.train_state.wait_signal) --[[and ((new_state == defines.train_state.on_the_path) or (new_state == defines.train_state.arrive_signal) or (new_state == defines.train_state.arrive_station))]] then
        for _, player in pairs(game.connected_players) do
            if not trainsaver_is_active(player) then goto next_player end
            local current_target = current_trainsaver_target(player)
            if not target_is_locomotive(current_target) then goto next_player end
            local current_target_train = current_target and current_target.train --[[@as LuaTrain]]
            if not (train.id == current_target_train.id) then goto next_player end
            storage.wait_signal_until_tick = storage.wait_signal_until_tick or {}
            storage.wait_signal_until_tick[player.index] = nil
            if storage.chatty then
                local chatty_name = get_chatty_name(player)
                local target_name = get_chatty_name(train)
                game.print(chatty_name .. "current target [" .. target_name .. "] changed to state [" .. verbose_states[train.state] .. "]. wait_signal_until_tick set to [nil]")
            end
            ::next_player::
        end
    end
end

return {
    cutscene_ended_nil_globals = cutscene_ended_nil_globals,
    update_globals_new_cutscene = update_globals_new_cutscene,
    update_wait_at_station = update_wait_at_station,
    update_wait_at_signal = update_wait_at_signal,
}
