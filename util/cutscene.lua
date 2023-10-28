
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
    global.create_cutscene_next_tick = global.create_cutscene_next_tick or {}
    global.create_cutscene_next_tick[player_index] = { train, player_index, same_train }
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

    -- abort if the waypoint is on a different surface than the player. I know we've already checked this like a billion times before getting to this point, but just to make sure we're gonna check one more time just in case
    if player.surface_index ~= created_waypoints[1].target.surface.index then
        chatty_print(chatty_name .. "abort: waypoint is on different surface than player")
        return
    end

    -- save alt-mode so we can preserve it after cutscene controller resets it
    local transfer_alt_mode = player.game_view_settings.show_entity_info

    -- set the player controller to cutscene camera
    player.set_controller(
        {
            type = defines.controllers.cutscene,
            waypoints = created_waypoints,
            start_position = player.position,
            -- final_transition_time = tt
        }
    )
    -- chatty_print(chatty_name.."cutscene controller updated with "..#created_waypoints.." waypoints")

    -- reset alt-mode to what it was before cutscene controller reset it
    player.game_view_settings.show_entity_info = transfer_alt_mode
    toggle_gui(player, false)
    update_globals_new_cutscene(player, created_waypoints)

    if register_history then
        global.watch_history = global.watch_history or {}
        global.watch_history[player_index] = global.watch_history[player_index] or {}
        table.insert(global.watch_history[player_index], created_waypoints[1].target)
        local history_length = #global.watch_history[player_index]
        global.player_history_index = global.player_history_index or {}
        global.player_history_index[player_index] = history_length
        chatty_print(chatty_name .. "added [ " .. get_chatty_name(created_waypoints[1].target) .. " ] to watch history [ " .. history_length .. " of " .. history_length .. " ]")
        if history_length > 10000 then
            table.remove(global.watch_history[player_index], 1)
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
                    print_notable_event("[color=orange]trainsaver:[/color] " ..
                    player.name .. " saw " .. passenger.name .. " riding a train")
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
