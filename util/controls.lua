
local status_util = require("util.status")
local trainsaver_is_active = status_util.trainsaver_is_active

local message_util = require("util.message")
local chatty_print = message_util.chatty_print
local get_chatty_name = message_util.get_chatty_name

local math_util = require("util.math")
local calculate_distance = math_util.calculate_distance
local convert_speed_into_time = math_util.convert_speed_into_time

local cutscene_util = require("util.cutscene")
local create_cutscene_next_tick = cutscene_util.create_cutscene_next_tick
local play_cutscene = cutscene_util.play_cutscene

local target_util = require("util.target")
local current_trainsaver_target = target_util.current_trainsaver_target
local target_is_locomotive = target_util.target_is_locomotive

local waypoint_util = require("util.waypoint")
local create_waypoint = waypoint_util.create_waypoint

local gui_util = require("util.gui")
local toggle_gui = gui_util.toggle_gui

-- end the screensaver
---@param command EventData.on_console_command
---@param ending_transition boolean?
local function end_trainsaver(command, ending_transition)
    local player_index = command.player_index
    if not player_index then return end
    local player = game.get_player(player_index)
    if not player then return end
    if not trainsaver_is_active(player) then return end
    local chatty_name = get_chatty_name(player)
    -- if the cutscene creator mod created the cutscene, don't cancel it
    if remote.interfaces["cc_check"] and remote.interfaces["cc_check"]["cc_status"] then
        if remote.call("cc_check", "cc_status", player_index) == "active" then return end
    end
    -- if we're not doing a transition, then just exit the cutscene immediately
    if not ending_transition then
        chatty_print(chatty_name .. "exit trainsaver (instant) requested")
        player.exit_cutscene()
        return
    end
    -- if we're already in the process of exiting, then just exit immediately
    if (global.cutscene_ending and (global.cutscene_ending[player_index] and (global.cutscene_ending[player_index] == true))) then
        chatty_print(chatty_name .. "trainsaver is currently exiting. immediate exit requested")
        player.exit_cutscene()
        return
    end
    -- if player doesn't have a character or cutscene_character to return to, then just exit immediately
    if not (player.cutscene_character or player.character) then
        chatty_print(chatty_name .. "has no character or cutscene_character. immediate exit requested")
        player.exit_cutscene()
        return
    end
    -- create a new cutscene from current position back to cutscene character position so the exit is nice and smooth
    chatty_print(chatty_name .. "exit trainsaver (transition) requested")
    local mod_settings = player.mod_settings
    local waypoint_target = player.cutscene_character or
    player.character --[[@as LuaEntity because it was already checked earlier]]
    local transition_time = mod_settings["ts-transition-speed"].value --[[@as number]]
    local variable_zoom = mod_settings["ts-variable-zoom"].value --[[@as boolean]]
    local zoom = mod_settings["ts-zoom"].value --[[@as number]]
    local wait_time = 30
    if transition_time > 0 then
        local distance_in_meters = calculate_distance(player.position, waypoint_target.position)
        transition_time = convert_speed_into_time(transition_time, distance_in_meters)
    end
    if variable_zoom then
        zoom = (math.random(((zoom - (zoom * .20)) * 1000), (((zoom + (zoom * .20))) * 1000))) / 1000
    end
    local created_waypoints = {
        {
            target = waypoint_target,
            transition_time = transition_time,
            time_to_wait = wait_time,
            zoom = zoom
        },
    }
    local character_name = player.character and player.character.name or "cutscene character"
    chatty_print(chatty_name .. "created ending transition waypoints to " .. character_name)
    if player.surface_index ~= created_waypoints[1].target.surface_index then
        chatty_print(chatty_name .. "ending transition target on different surface than player. immediate exit requested")
        player.exit_cutscene()
        return
    end
    local transfer_alt_mode = player.game_view_settings.show_entity_info
    player.set_controller(
        {
            type = defines.controllers.cutscene,
            waypoints = created_waypoints,
            start_position = player.position,
        }
    )
    toggle_gui(player, false)
    player.game_view_settings.show_entity_info = transfer_alt_mode
    -- update globals for a cutscene ending
    ---@type table<uint, boolean>
    global.cutscene_ending = global.cutscene_ending or {}
    global.cutscene_ending[player_index] = true
    ---@type table<uint, number|uint>
    global.wait_signal_until_tick = global.wait_signal_until_tick or {}
    global.wait_signal_until_tick[player_index] = nil
    ---@type table<uint, number|uint>
    global.wait_station_until_tick = global.wait_station_until_tick or {}
    global.wait_station_until_tick[player_index] = nil
    ---@type table<uint, number|uint>
    global.driving_until_tick = global.driving_until_tick or {}
    global.driving_until_tick[player_index] = nil

    -- these ones aren't used any more, but we'll keep them around for a while just because
    global.driving_since_tick = global.driving_since_tick or {}
    global.driving_since_tick[player_index] = nil
    global.wait_station_since_tick = global.wait_station_since_tick or {}
    global.wait_station_since_tick[player_index] = nil
    global.wait_at_signal = global.wait_at_signal or {}
    global.wait_at_signal[player_index] = nil
end

-- start the screensaver :D
---@param command EventData.on_console_command
---@param train_to_ignore LuaTrain?
---@param entity_gone_restart boolean?
local function start_trainsaver(command, train_to_ignore, entity_gone_restart)
    local chatty = global.chatty
    local player_index = command.player_index
    if not player_index then return end
    local player = game.get_player(player_index)
    if not player then return end
    local chatty_name = get_chatty_name(player)
    local name = command.name
    chatty_print(chatty_name .. "starting trainsaver")
    local controller_type = player.controller_type
    local allowed_controller_types = {
        [defines.controllers.character] = true,
        [defines.controllers.god] = true,
    }
    if not ((name == "trainsaver") and (allowed_controller_types[controller_type] or entity_gone_restart)) then return end

    -- create a table of all trains
    local all_trains = player.surface.get_trains()

    -- create a table of all trains that have any "movers" and are not in manual mode and are not the train that just died or was mined
    local eligable_trains_with_movers = {} --[=[@type LuaTrain[]]=]
    if not train_to_ignore then train_to_ignore = { id = -999999 } end
    for _, train in pairs(all_trains) do
        if ((train.locomotives.front_movers[1] or train.locomotives.back_movers[1]) and (not ((train.state == defines.train_state.manual_control) or (train.state == defines.train_state.manual_control_stop) or (train.id == train_to_ignore.id)))) then
            table.insert(eligable_trains_with_movers, train)
        end
    end
    chatty_print(chatty_name .. "created table of trains [" .. #eligable_trains_with_movers .. " total]")

    -- if there's no eligable trains, exit trainsaver
    if not eligable_trains_with_movers[1] then
        chatty_print(chatty_name .. "no eligable trains found")
        end_trainsaver(command)
        return
    end

    -- if there are any trains, make a table of all the active (on_the_path) ones
    local active_trains = {} --[=[@type LuaTrain[]]=]
    for _, train in pairs(eligable_trains_with_movers) do
        if train.state == defines.train_state.on_the_path then
            table.insert(active_trains, train)
        end
    end
    chatty_print(chatty_name .. "created table of active trains [" .. #active_trains .. " total]")

    -- sort the table of active trains by how much of their path is remaining so we can focus on the one with the longest remaining path
    if active_trains[1] then
        local active_trains_sorted_by_remaining_path_length = util.table.deepcopy(active_trains)
        table.sort(active_trains_sorted_by_remaining_path_length,
            function(a, b) return (a.path.total_distance - a.path.travelled_distance) >
                (b.path.total_distance - b.path.travelled_distance) end)
        create_cutscene_next_tick(player_index, active_trains_sorted_by_remaining_path_length[1])
        chatty_print(chatty_name ..
        "requested cutscene for " .. player.name .. ", following train with longest remaining path")
        return
    end

    -- if there are no trains on_the_path then make a table of trains waiting at stations
    chatty_print(chatty_name .. "no trains are on_the_path")
    local trains_at_stations = {} --[=[@type LuaTrain[]]=]
    for _, train in pairs(eligable_trains_with_movers) do
        if train.state == defines.train_state.wait_station then
            table.insert(trains_at_stations, train)
        end
    end
    chatty_print(chatty_name .. "created table of trains waiting at stations [" .. #trains_at_stations .. " total]")

    -- if there are any trains waiting at stations, pick a random one to request a cutscene with
    if trains_at_stations[1] then
        local random_train_index = math.random(table_size(trains_at_stations))
        local waypoint_target = trains_at_stations[random_train_index]
        create_cutscene_next_tick(player_index, waypoint_target)
        chatty_print(chatty_name .. "chose a random train waiting at a station")
        return
    end

    -- if there are no trains on_the_path or waiting at stations, then pick a random train from the eligible ones to request a cutscene with
    chatty_print(chatty_name .. "no trains on_the_path or waiting at stations")
    local random_train_index = math.random(table_size(eligable_trains_with_movers))
    local waypoint_target = eligable_trains_with_movers[random_train_index]
    create_cutscene_next_tick(player_index, waypoint_target)
    chatty_print(chatty_name .. "chose a random train")
end

---start or end trainsaver depending on player controller type
---@param event EventData.CustomInputEvent | EventData.on_console_command
local function start_or_end_trainsaver(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if ((player.controller_type == defines.controllers.character) or (player.controller_type == defines.controllers.god)) then
        local command = { name = "trainsaver", player_index = event.player_index }
        start_trainsaver(command)
    elseif player.controller_type == defines.controllers.cutscene then
        -- local command = {player_index = event.player_index, ending_transition = true}
        local command = { player_index = event.player_index }
        end_trainsaver(command, true)
    end
end

---end trainsaver when the /end-trainsaver command is used
---@param event EventData.on_console_command
local function end_trainsaver_on_command(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if not trainsaver_is_active(player) then return end
    -- local command = {player_index = event.player_index, ending_transition = true}
    local command = { player_index = event.player_index }
    end_trainsaver(command, true)
end

---focus trainsaver on a new target
---@param event EventData.CustomInputEvent
local function focus_new_target(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local current_target = current_trainsaver_target(player)
    if not current_target then return end
    if target_is_locomotive(current_target) then
        local chatty_name = get_chatty_name(player)
        chatty_print(chatty_name .. "focusing new target")
        local command = { name = "trainsaver", player_index = event.player_index }
        start_trainsaver(command, current_target.train, true)
    else
        local chatty_name = get_chatty_name(player)
        chatty_print(chatty_name .. "focusing new target")
        local command = { name = "trainsaver", player_index = event.player_index }
        start_trainsaver(command, nil, true)
    end
end

---focus trainsaver on the next target from watch history
---@param event EventData.CustomInputEvent
local function focus_next_target(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local current_target = current_trainsaver_target(player)
    if not current_target then return end
    local watch_histories = global.watch_history
    local watch_history = watch_histories and watch_histories[player.index]
    if not watch_history then
        focus_new_target(event)
    else
        global.player_history_index = global.player_history_index or {}
        local player_history_index = global.player_history_index[player.index] or 1
        local next_index = player_history_index + 1
        if not watch_history[next_index] then
            focus_new_target(event)
        else
            for i = player_history_index + 1, #watch_history do
                local target = watch_history[i]
                if target and target.valid then
                    local chatty_name = get_chatty_name(player)
                    chatty_print(chatty_name .. "focusing next target in watch history [" .. i .. " of " .. #watch_history .. "]")
                    if target_is_locomotive(target) then
                        local train = target.train
                        target = train.speed < 0 and train.back_stock or train.front_stock
                    end
                    local waypoints = create_waypoint(target, player.index)
                    play_cutscene(waypoints, player.index, false)
                    global.player_history_index[player.index] = i
                    player.create_local_flying_text({ text = "[ " .. i .. " / " .. #watch_history .. " ]", create_at_cursor = true })
                    return
                end
                if i == #watch_history then
                    focus_new_target(event)
                end
            end
        end
    end
end

-- focus trainsaver on the previous target from watch history
---@param event EventData.CustomInputEvent
local function focus_previous_target(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local current_target = current_trainsaver_target(player)
    if not current_target then return end
    local watch_histories = global.watch_history
    local watch_history = watch_histories and watch_histories[player.index]
    if not watch_history then return end
    global.player_history_index = global.player_history_index or {}
    local player_history_index = global.player_history_index[player.index] or 1
    for i = player_history_index - 1, 1, -1 do
        local target = watch_history[i]
        if target and target.valid then
            local chatty_name = get_chatty_name(player)
            chatty_print(chatty_name .. "focusing previous target in watch history [" .. i .. " of " .. #watch_history .. "]")
            if target_is_locomotive(target) then
                local train = target.train
                target = train.speed < 0 and train.back_stock or train.front_stock
            end
            local waypoints = create_waypoint(target, player.index)
            play_cutscene(waypoints, player.index, false)
            global.player_history_index[player.index] = i
            player.create_local_flying_text({ text = "[ " .. i .. " / " .. #watch_history .. " ]", create_at_cursor = true })
            return
        end
    end
end

-- reset the watch history for a player
---@param event EventData.on_console_command
local function reset_player_history(event)
    local player_index = event.player_index
    if not player_index then return end
    global.watch_history = global.watch_history or {}
    global.watch_history[player_index] = nil
    global.player_history_index = global.player_history_index or {}
    global.player_history_index[player_index] = nil
end

return {
    start_trainsaver = start_trainsaver,
    end_trainsaver = end_trainsaver,
    start_or_end_trainsaver = start_or_end_trainsaver,
    end_trainsaver_on_command = end_trainsaver_on_command,
    focus_new_target = focus_new_target,
    focus_next_target = focus_next_target,
    focus_previous_target = focus_previous_target,
    reset_player_history = reset_player_history,
}
