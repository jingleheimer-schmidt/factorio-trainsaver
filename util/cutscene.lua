
local message_util = require("util.message")
local get_chatty_name = message_util.get_chatty_name
local chatty_print = message_util.chatty_print
local print_notable_event = message_util.print_notable_event

local target_util = require("util.target")
local target_is_locomotive = target_util.target_is_locomotive

local globals_util = require("util.globals")
local update_globals_new_cutscene = globals_util.update_globals_new_cutscene

local gui_util = require("util.gui")
local toggle_gui = gui_util.toggle_gui

---@class player_data
---@field position MapPosition
---@field physical_position MapPosition
---@field surface SurfaceIdentification
---@field physical_surface SurfaceIdentification
---@field zoom number
---@field controller_type defines.controllers
---@field character LuaEntity?

-- get the intended cutscene surface from waypoints (most common surface among waypoints)
---@param waypoints CutsceneWaypoint[]
---@return SurfaceIdentification
local function get_intended_cutscene_surface(waypoints)
    local surface_names = {}
    for _, waypoint in pairs(waypoints) do
        local surface_name = nil
        if waypoint.target and waypoint.target.valid then
            surface_name = waypoint.target.surface.name
        end
        if surface_name then
            surface_names[surface_name] = (surface_names[surface_name] or 0) + 1
        end
    end
    local max_count, surface_name = 0, nil
    for name, count in pairs(surface_names) do
        if count > max_count then
            max_count = count
            surface_name = name
        end
    end
    -- if no surface was found in waypoints, return the first waypoint's target surface
    if not surface_name and waypoints[1] and waypoints[1].target and waypoints[1].target.valid then
        surface_name = waypoints[1].target.surface.name
    end
    return surface_name
end

-- add data to global so a cutscene is created for a given player the following tick
---@param player_index uint
---@param train LuaTrain
---@param same_train "same train"?
local function create_cutscene_next_tick(player_index, train, same_train)
    ---@class CreateCutsceneNextTickData
    ---@field [1] LuaTrain
    ---@field [2] uint -- player index
    ---@field [3] "same train"?
    ---@field [4] number -- attempts
    ---@type table<uint, CreateCutsceneNextTickData>
    storage.create_cutscene_next_tick = storage.create_cutscene_next_tick or {}
    storage.create_cutscene_next_tick[player_index] = { train, player_index, same_train }
end

-- play cutscene from given waypoints
---@param created_waypoints CutsceneWaypoint[]
---@param player_index uint
---@param register_history boolean
local function play_cutscene(created_waypoints, player_index, register_history)
    local player = game.get_player(player_index)
    if not player then return end
    local chatty_name = get_chatty_name(player)
    -- chatty_print(chatty_name.."initiating cutscene")
    if remote.interfaces["cc_check"] and remote.interfaces["cc_check"]["cc_status"] then
        if remote.call("cc_check", "cc_status", player_index) == "active" then
            return
        end
    end

    -- check if cutscene is on a different surface than the player
    local intended_surface = get_intended_cutscene_surface(created_waypoints)
    local is_cross_surface = intended_surface and (player.surface.name ~= intended_surface)
    
    if is_cross_surface then
        -- store player data for cross-surface cutscene
        storage.player_data = storage.player_data or {}
        storage.player_data[player_index] = {
            position = player.position,
            physical_position = player.physical_position,
            surface = player.surface_index,
            physical_surface = player.physical_surface_index,
            zoom = player.zoom,
            controller_type = player.controller_type,
            character = player.character,
        }
        chatty_print(chatty_name .. "cross-surface cutscene: player on " .. player.surface.name .. ", target on " .. intended_surface)
        -- set player to spectator and teleport to target surface
        player.set_controller { type = defines.controllers.spectator }
        player.teleport(player.position, intended_surface, true)
        player.zoom = storage.player_data[player_index].zoom
    end

    -- save alt-mode so we can preserve it after cutscene controller resets it
    local transfer_alt_mode = player.game_view_settings.show_entity_info

    -- set the player controller to cutscene camera
    player.set_controller(
        {
            type = defines.controllers.cutscene,
            waypoints = created_waypoints,
            start_position = player.position,
            start_zoom = created_waypoints[1].zoom, -- temporary until zoom issue is fixed
            -- final_transition_time = tt
        }
    )
    -- chatty_print(chatty_name.."cutscene controller updated with "..#created_waypoints.." waypoints")

    -- reset alt-mode to what it was before cutscene controller reset it
    player.game_view_settings.show_entity_info = transfer_alt_mode
    toggle_gui(player, false)
    update_globals_new_cutscene(player, created_waypoints)

    if register_history then
        storage.watch_history = storage.watch_history or {}
        storage.watch_history[player_index] = storage.watch_history[player_index] or {}
        table.insert(storage.watch_history[player_index], created_waypoints[1].target)
        local history_length = #storage.watch_history[player_index]
        storage.player_history_index = storage.player_history_index or {}
        storage.player_history_index[player_index] = history_length
        chatty_print(chatty_name .. "added [ " .. get_chatty_name(created_waypoints[1].target) .. " ] to watch history [ " .. history_length .. " of " .. history_length .. " ]")
        if history_length > 10000 then
            table.remove(storage.watch_history[player_index], 1)
        end
    end

    -- unlock any achievements if possible
    local waypoint_target = created_waypoints[1].target
    if waypoint_target and target_is_locomotive(waypoint_target) and waypoint_target.train then
        local train = waypoint_target.train
        local passengers = train and train.passengers
        if passengers then
            for _, passenger in pairs(passengers) do
                --[[
                if passenger.index == player.index then
                    player.unlock_achievement("trainsaver-self-reflection")
                    print_notable_event("[color=orange]trainsaver:[/color] " ..
                    player.name .. " saw themself riding a train")
                end
                --]]
                if passenger.index ~= player.index then
                    player.unlock_achievement("trainsaver-find-a-friend")
                    print_notable_event("[color=orange]trainsaver:[/color] " .. player.name .. " saw " .. passenger.name .. " riding a train")
                end
            end
        end
        local path = train and train.path
        if path then
            local remaining_path_distance = path.total_distance - path.travelled_distance
            if remaining_path_distance > 10000 then
                player.unlock_achievement("trainsaver-long-haul")
            end
        end
    end
end

return {
    create_cutscene_next_tick = create_cutscene_next_tick,
    play_cutscene = play_cutscene
}
