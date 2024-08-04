
local message_util = require("util.message")
local get_chatty_name = message_util.get_chatty_name
local chatty_print = message_util.chatty_print

local math_util = require("util.math")
local calculate_distance = math_util.calculate_distance
local convert_speed_into_time = math_util.convert_speed_into_time

local target_util = require("util.target")
local target_is_locomotive = target_util.target_is_locomotive
local target_is_spider = target_util.target_is_spider
local target_is_unit_group = target_util.target_is_unit_group

-- create a waypoint for given waypoint_target using player mod settings
---@param waypoint_target LuaEntity|LuaUnitGroup
---@param player_index uint
---@return CutsceneWaypoint[]
local function create_waypoint(waypoint_target, player_index)
    local player = game.get_player(player_index) --[[@as LuaPlayer]]
    local mod_settings = player.mod_settings
    local chatty_name = get_chatty_name(player)
    local transition_time = mod_settings["ts-transition-speed"].value --[[@as number]] --[[ kmph --]]
    local transition_time_2 = mod_settings["ts-transition-speed"].value --[[@as number]] --[[ kmph --]]
    local variable_zoom = mod_settings["ts-variable-zoom"].value --[[@as boolean]]
    local zoom = mod_settings["ts-zoom"].value --[[@as number]]
    local time_to_wait = mod_settings["ts-time-wait"].value * 60 * 60 --[[@as number]] --[[ convert minutes to ticks --]]

    -- we now prefer transition speed over transition time, but that means we need to do some calculations to convert speed (kmph) into time (ticks). However, if speed = 0, then default back to just using transition time
    if transition_time > 0 then
        local distance_in_meters = calculate_distance(player.position, waypoint_target.position)
        transition_time = convert_speed_into_time(transition_time, distance_in_meters)
    end

    -- if variable zoom is enabled, then we will randomly zoom in or out by 20%
    if variable_zoom == true then
        zoom = (math.random(((zoom - (zoom * .20)) * 1000), (((zoom + (zoom * .20))) * 1000))) / 1000
    end

    -- set transition time for final waypoint based on where we think the waypoint target will be when the cutscene is over
    local waypoint_2_start_entity = {} ---@type LuaEntity
    if target_is_locomotive(waypoint_target) then
        waypoint_2_start_entity = waypoint_target.train.path_end_stop or waypoint_target.train.path_end_rail or {}
    elseif target_is_spider(waypoint_target) then
        if waypoint_target.autopilot_destinations then
            waypoint_2_start_entity = {
                position = waypoint_target.autopilot_destinations[#waypoint_target.autopilot_destinations] } or {}
        end
    elseif target_is_unit_group(waypoint_target) then
        waypoint_2_start_entity = waypoint_target.command and waypoint_target.command.target or {}
    end
    local waypoint_2_end_entity = player.cutscene_character or player.character or {}
    local waypoint_2_end_entity_name = waypoint_2_end_entity.name
    if player.cutscene_character then waypoint_2_end_entity_name = "cutscene character" end
    if transition_time_2 > 0 then
        local waypoint_2_start_position = waypoint_2_start_entity.position or waypoint_target.position
        local waypoint_2_end_position = waypoint_2_end_entity.position or player.position
        local waypoint_2_distance_in_meters = calculate_distance(waypoint_2_start_position, waypoint_2_end_position)
        transition_time_2 = convert_speed_into_time(transition_time_2, waypoint_2_distance_in_meters)
    end

    -- finally let's assemble our waypints table!
    local created_waypoints = {
        {
            target = waypoint_target,
            transition_time = transition_time,
            time_to_wait = time_to_wait,
            zoom = zoom
        },
    }
    local message = chatty_name .. "created waypoint to [" .. get_chatty_name(waypoint_target) .. "] with no return waypoint"

    -- use the player character or cutscene character as the final waypoint so transition goes back to there instead of where cutscene started if trainsaver ends due to no new train activity, but if there isn't a cutscene_character or player.character then don't add the final waypoint because the player was probably in god mode when it started so character is on a different surface or doesn't even exist, meaning there's nowhere to "go back" to
    if waypoint_2_end_entity.valid and (waypoint_2_end_entity.surface_index == player.surface_index) then
        local waypoint_2 = {
            target = waypoint_2_end_entity,
            transition_time = transition_time_2,
            time_to_wait = 60,
            zoom = zoom
        }
        table.insert(created_waypoints, waypoint_2)
        message = chatty_name .. "created waypoint to [" .. get_chatty_name(waypoint_target) .. "] with return waypoint to " .. waypoint_2_end_entity_name
    end
    chatty_print(message)
    return created_waypoints
end

return {
    create_waypoint = create_waypoint
}
