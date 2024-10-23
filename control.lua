
--[[ factorio mod trainsaver control script created by asher_sky --]]

require("util")

local constants = require("util.constants")
local verbose_states = constants.verbose_states
local active_states = constants.active_states
local idle_states = constants.idle_states
local wait_station_states = constants.wait_station_states
local wait_signal_states = constants.wait_signal_states
local always_accept_new_target_states = constants.always_accept_new_target_states

local message = require("util.message")
local toggle_chatty = message.toggle_chatty
local chatty_print = message.chatty_print
local chatty_player_name = message.chatty_player_name
local chatty_target_train_name = message.chatty_target_train_name
local chatty_target_entity_name = message.chatty_target_entity_name
local get_chatty_name = message.get_chatty_name
local print_notable_event = message.print_notable_event

local target_util = require("util.target")
local current_trainsaver_target = target_util.current_trainsaver_target
local target_is_entity = target_util.target_is_entity
local target_is_locomotive = target_util.target_is_locomotive
local target_is_spider = target_util.target_is_spider
local target_is_rocket_silo = target_util.target_is_rocket_silo
local target_is_unit_group = target_util.target_is_unit_group
local waypoint_target_has_idle_state = target_util.waypoint_target_has_idle_state

local math_util = require("util.math")
local calculate_distance = math_util.calculate_distance
local convert_speed_into_time = math_util.convert_speed_into_time

local status_util = require("util.status")
local exceeded_driving_minimum = status_util.exceeded_driving_minimum
local exceeded_station_minimum = status_util.exceeded_station_minimum
local exceeded_signal_minimum = status_util.exceeded_signal_minimum
local exceeded_spider_walking_minimum = status_util.exceeded_spider_walking_minimum
local exceeded_spider_idle_minimum = status_util.exceeded_spider_idle_minimum
local trainsaver_is_active = status_util.trainsaver_is_active
local waypoint_target_passes_inactivity_checks = status_util.waypoint_target_passes_inactivity_checks

local waypoint_util = require("util.waypoint")
local create_waypoint = waypoint_util.create_waypoint

local controls_util = require("util.controls")
local end_trainsaver = controls_util.end_trainsaver
local start_trainsaver = controls_util.start_trainsaver
local start_or_end_trainsaver = controls_util.start_or_end_trainsaver
local end_trainsaver_on_command = controls_util.end_trainsaver_on_command
local focus_new_target = controls_util.focus_new_target
local focus_next_target = controls_util.focus_next_target
local focus_previous_target = controls_util.focus_previous_target
local reset_history = controls_util.reset_player_history

local cutscene_util = require("util.cutscene")
local create_cutscene_next_tick = cutscene_util.create_cutscene_next_tick
local play_cutscene = cutscene_util.play_cutscene

local globals_util = require("util.globals")
local update_globals_new_cutscene = globals_util.update_globals_new_cutscene
local cutscene_ended_nil_globals = globals_util.cutscene_ended_nil_globals
local update_wait_at_signal = globals_util.update_wait_at_signal
local update_wait_at_station = globals_util.update_wait_at_station

local gui_util = require("util.gui")
local toggle_gui = gui_util.toggle_gui

local interface_util = require("util.interface")
local interface_functions = interface_util.interface_functions
remote.add_interface("trainsaver", interface_functions)

-- when a cutscene is cancelled with player.exit_cutscene(), nil out any globals we saved for them
---@param event EventData.on_cutscene_cancelled
local function cutscene_cancelled(event)
    cutscene_ended_nil_globals(event.player_index)
    local player = game.get_player(event.player_index)
    if not player then return end
    toggle_gui(player, true)
    -- chatty_print(chatty_player_name(player) .. "cutscene cancelled")
end

---@param event EventData.on_cutscene_finished
local function cutscene_finished(event)
    cutscene_ended_nil_globals(event.player_index)
    local player = game.get_player(event.player_index)
    if not player then return end
    toggle_gui(player, true)
    -- chatty_print(chatty_player_name(player) .. "cutscene finished")
end

-- nil the globals when we get to the final waypoint of the cutscene bringing player back to their character. Still need to deal with how to nil globals when cutscene finishes on its own (inactivity timeout) but hopefully they add a on_cutscene_ended() event so I can just use that for both...
---@param event EventData.on_cutscene_waypoint_reached
local function cutscene_waypoint_reached(event)
    if storage.chatty then
        local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
        local chatty_name = get_chatty_name(player)
        game.print(chatty_name .. "arrived at waypoint [index " .. event.waypoint_index .. "]")
    end
    local player_index = event.player_index
    storage.cutscene_ending = storage.cutscene_ending or {}
    local cutscene_ending = storage.cutscene_ending[player_index]
    storage.number_of_waypoints = storage.number_of_waypoints or {}
    local number_of_waypoints = storage.number_of_waypoints[player_index]
    if cutscene_ending then
        cutscene_ended_nil_globals(player_index)
    elseif number_of_waypoints and (number_of_waypoints == event.waypoint_index) then
        cutscene_ended_nil_globals(player_index)
    end
end

-- set character color to player color so it's the same when controller switches from character to cutscene. This is no longer used since the introduction of cutscene character now handles this, but we're keeping it here for the memories :)
---@param player_index uint
local function sync_color(player_index)
    game.players[player_index].character.color = game.players[player_index].color
end

-- update the trainsaver cutscene target to the train that just became active for any players that meet the inactivity requirements
---@param event EventData.on_train_changed_state
local function train_changed_state(event)
    local new_target = event.train
    local old_state = event.old_state
    local new_state = event.train.state
    if not (wait_station_states[old_state] and active_states[new_state]) then return end
    local new_target_name = get_chatty_name(new_target)
    chatty_print("[" .. game.tick .. "] potential target [" .. new_target_name .. "] changed state from [" .. verbose_states[old_state] .. "] to [" .. verbose_states[new_state] .. "]")
    for _, player in pairs(game.connected_players) do
        if not trainsaver_is_active(player) then goto next_player end
        if not (player.surface_index == new_target.carriages[1].surface_index) then
            chatty_print(chatty_player_name(player) .. "denied. cannot change from current surface [" .. player.surface.name .. "] to target surface [" .. new_target.carriages[1].surface.name .. "]")
            goto next_player
        end
        local current_target = current_trainsaver_target(player)
        if not (current_target and target_is_entity(current_target)) then goto next_player end
        local chatty_name = get_chatty_name(player)
        local current_target_name = get_chatty_name(current_target)
        local player_index = player.index
        local current_target_train, current_target_state = current_target.train, current_target.train and current_target.train.state
        if not target_is_locomotive(current_target) then goto spider_handling end
        if active_states[current_target_state] then -- not certain this check is necessary
            if current_target_train and (current_target_train.id == new_target.id) then
                chatty_print(chatty_name .. "accepted. current target [" .. current_target_name .. "] is the train that changed state. targeting lead locomotive")
                create_cutscene_next_tick(player_index, new_target, "same train")
                goto next_player
            end
        end
        if waypoint_target_passes_inactivity_checks(player, current_target) then
            create_cutscene_next_tick(player_index, new_target)
            goto next_player
        end
        ::spider_handling::
        if not target_is_spider(current_target) then goto rocket_handling end
        if waypoint_target_passes_inactivity_checks(player, current_target) then
            create_cutscene_next_tick(player_index, new_target)
            goto next_player
        end
        ::rocket_handling::
        if not target_is_rocket_silo(current_target) then goto next_player end
        -- chatty_print(chatty_name .. "denied. current target [" .. current_target_name .. "] is launching a rocket")
        ::next_player::
    end
end

-- returns the total length of any remaining waypoints in a spidertron's autopilot_destinations queue
---@param spidertron LuaEntity
---@return number
local function total_spider_path_remaining(spidertron)
    local total_distance = 0
    local autopilot_destinations = spidertron.autopilot_destinations
    for index, waypoint in pairs(autopilot_destinations) do
        if index == 1 then
            local distance_to_first_waypoint = calculate_distance(spidertron.position, waypoint)
            total_distance = total_distance + distance_to_first_waypoint
        elseif autopilot_destinations[index - 1] then
            local distance_from_previous_waypoint = calculate_distance(waypoint, autopilot_destinations[index - 1])
            total_distance = total_distance + distance_from_previous_waypoint
        end
    end
    return total_distance
end

-- when a spidertron is given a command, or reaches a waypoint destination, add it as a potential trainsaver target
---@param event EventData.on_spider_command_completed|EventData.on_player_used_spider_remote
local function spidertron_changed_state(event)
    local spider = event.vehicle
    -- if not spider.autopilot_destinations[1] then return end -- filter for spidertrons with at least one more waypoint to go to
    if spider.name == "companion" then return end -- don't target klonan's companion drone mod spidertrons
    local destinations = spider.autopilot_destinations
    local chatty_target_name = get_chatty_name(spider)
    local remaining_path_distance = total_spider_path_remaining(spider)
    if destinations[1] and (remaining_path_distance < 100) then return end -- filter for spidertrons with at least 100 tiles of path remaining
    if destinations[1] then
        chatty_print("[" .. game.tick .. "] potential target [" .. chatty_target_name .. "] going to destination " .. serpent.line(destinations[1]) .. "")
    end
    for _, player in pairs(game.connected_players) do
        local mod_settings = player.mod_settings
        if (mod_settings["ts-secrets"].value == false) then goto next_player end
        if not trainsaver_is_active(player) then goto next_player end
        local chatty_name = get_chatty_name(player)
        if not destinations[1] then
            local current_target = current_trainsaver_target(player)
            if not current_target then goto next_player end
            local current_target_id = script.register_on_object_destroyed(current_target --[[@as LuaEntity]]) -- carefull... might be a unitgroup
            local spider_id = script.register_on_object_destroyed(spider --[[@as LuaEntity]])
            if current_target_id == spider_id then
                storage.spider_idle_until_tick = storage.spider_idle_until_tick or {}
                storage.spider_idle_until_tick[player.index] = game.tick + mod_settings["ts-station-minimum"].value * 60
                chatty_print(chatty_name .. "current target [" .. chatty_target_name .. "] reached its final destination. set spider_idle_until_tick to [" .. storage.spider_idle_until_tick[player.index] .. "]")
            end
            goto next_player
        end
        local current_target = current_trainsaver_target(player)
        if not current_target then goto next_player end
        local current_target_name = get_chatty_name(current_target)
        if not (spider.surface_index == player.surface_index) then
            chatty_print(chatty_name .. "denied. cannot change from [" .. spider.surface.name .. "] to [" .. player.surface.name .. "]")
            goto next_player
        end
        if target_is_locomotive(current_target) then
            if waypoint_target_passes_inactivity_checks(player, current_target) then
                local waypoints = create_waypoint(spider, player.index)
                if waypoints[1].zoom then
                    waypoints[1].zoom = waypoints[1].zoom * 1.75
                end
                play_cutscene(waypoints, player.index, true)
                goto next_player
            else
                goto next_player
            end
        elseif target_is_spider(current_target) then
            local spider_id = script.register_on_object_destroyed(spider)
            local current_target_id = script.register_on_object_destroyed(current_target --[[@as LuaEntity]])
            if (spider_id == current_target_id) then
                chatty_print(chatty_name .. "denied. current target [" .. current_target_name .. "] is the potential target")
                goto next_player
            elseif waypoint_target_passes_inactivity_checks(player, current_target) then
                local waypoints = create_waypoint(spider, player.index)
                if waypoints[1].zoom then
                    waypoints[1].zoom = waypoints[1].zoom * 1.75
                end
                play_cutscene(waypoints, player.index, true)
            end
        elseif target_is_rocket_silo(current_target) then
            -- chatty_print(chatty_name .. "denied. current target [" .. current_target_name .. "] is launching a rocket")
        end
        ::next_player::
    end
end

--
---@param event EventData.on_spider_command_completed
local function spider_command_completed(event)
    spidertron_changed_state(event)
end

--
---@param event EventData.on_player_used_spider_remote
local function player_used_spider_remote(event)
    if not event.success then return end
    spidertron_changed_state(event)
end

script.on_event(defines.events.on_player_used_spider_remote, player_used_spider_remote)
script.on_event(defines.events.on_spider_command_completed, spider_command_completed)

-- when a group of biters finishes gathering adn beins execuring their command
---@param event EventData.on_unit_group_finished_gathering
local function on_unit_group_finished_gathering(event)
    local group = event.group
    local command = group.command
    chatty_print("[" .. game.tick .. "] potential target [" .. get_chatty_name(group) .. "] has finished gathering")
    if not command then return end
    if not command.type == defines.command.attack then return end
    chatty_print("[" .. game.tick .. "] potential target [" .. get_chatty_name(group) .. "] has begun an attack command")
    for _, player in pairs(game.connected_players) do
        if not trainsaver_is_active(player) then goto next_player end
        if not (player.surface_index == group.surface.index) then
            chatty_print(chatty_player_name(player) .. "denied. cannot change from current surface [" .. player.surface.name .. "] to target surface [" .. group.surface.name .. "]")
            goto next_player
        end
        local current_target = current_trainsaver_target(player)
        local player_index = player.index
        if waypoint_target_passes_inactivity_checks(player, current_target) then
            local waypoints = create_waypoint(group, player_index)
            waypoints[1].zoom = waypoints[1].zoom * 1.75
            play_cutscene(waypoints, player_index, true)
            goto next_player
        end
        ::next_player::
    end
end

-- script.on_event(defines.events.on_unit_group_finished_gathering, on_unit_group_finished_gathering)

-- when a train changes state, see if any players are eligable to transfer focus to it
---@param event EventData.on_train_changed_state
local function on_train_changed_state(event)
    train_changed_state(event)
    update_wait_at_signal(event)
    update_wait_at_station(event)
end

---end trainsaver if the cutscene character takes any damage
---@param event EventData.on_entity_damaged
local function character_damaged(event)
    local damaged_entity = event.entity
    for _, player in pairs(game.connected_players) do
        if (trainsaver_is_active(player) and player.cutscene_character == damaged_entity) then
            player.unlock_achievement("trainsaver-character-damaged")
            if event.cause and event.cause.train and event.cause.train.id and storage.followed_loco[player.index] and storage.followed_loco[player.index].train_id and (event.cause.train.id == storage.followed_loco[player.index].train_id) then
                player.unlock_achievement("trainsaver-damaged-by-followed-train")
                print_notable_event("[color=orange]trainsaver:[/color] " .. player.name .. " was hit by the train they were watching")
            elseif event.cause and event.cause.name then
                print_notable_event("[color=orange]trainsaver:[/color] " .. player.name .. " was hurt by " .. event.cause.name .. " while watching the trains")
            else
                print_notable_event("[color=orange]trainsaver:[/color] " .. player.name .. " was hurt while watching the trains")
            end
            local command = { player_index = player.index }
            end_trainsaver(command)
        end
    end
end

-- restart trainsaver when the currently followed locomotive is destroyed
---@param event EventData.on_entity_died | EventData.on_robot_mined_entity | EventData.on_player_mined_entity
local function locomotive_gone(event)
    local locomotive = event.entity
    for _, player in pairs(game.connected_players) do
        if not trainsaver_is_active(player) then goto next_player end
        local player_index = player.index
        if not (storage.followed_loco and storage.followed_loco[player_index]) then goto next_player end
        if not (storage.followed_loco[player_index].unit_number == locomotive.unit_number) then goto next_player end
        local command = {
            name = "trainsaver",
            player_index = player_index,
            -- entity_gone_restart = "yes",
            -- train_to_ignore = event.entity.train
        }
        -- start_trainsaver(command)
        start_trainsaver(command, event.entity.train, true)
        ::next_player::
    end
end

-- restart trainsaver when the currently followed cutscene target is destroyed
---@param event EventData.on_object_destroyed
local function entity_destroyed(event)
    local registration_number = event.registration_number
    if not storage.entity_destroyed_registration_numbers then return end
    for player_index, current_target_registration_number in pairs(storage.entity_destroyed_registration_numbers) do
        if not (current_target_registration_number == registration_number) then goto next_player end
        if event.useful_id then
            local simulated_event = {
                entity = {
                    unit_number = event.useful_id,
                    train = {
                        id = -999999
                    },
                },
            }
            locomotive_gone(simulated_event)
        else
            -- if we just watched a rocket launch, restart trainsaver to find a new train to follow
            local player = game.get_player(player_index)
            if not player then goto next_player end
            if not trainsaver_is_active(player) then goto next_player end
            --[[
            local rocket_destroyed_location_index = game.tick - 1
            player.teleport(storage.rocket_positions[player_index][rocket_destroyed_location_index])
            storage.rocket_positions[player_index] = nil
            --]]
            player.unlock_achievement("trainsaver-a-spectacular-view")
            print_notable_event("[color=orange]trainsaver:[/color] " .. player.name .. " saw something spectacular")
            local command = {
                name = "trainsaver",
                player_index = player_index,
                -- entity_gone_restart = "yes",
            }
            start_trainsaver(command, nil, true)
        end
        ::next_player::
    end
end

-- create a new cutscene for any players that need one. cutscenes need to be delayed one tick because trains that change state don't have a speed yet so we need to wait one tick for them to start moving so we can determine which locomotive is the "leader".
local function cutscene_next_tick_function()
    -- check if any players need a new cutscene
    if not storage.create_cutscene_next_tick then return end
    for _, data in pairs(storage.create_cutscene_next_tick) do
        local target_train = data[1]
        local player_index = data[2]
        local same_train = data[3]
        local attempts = data[4]
        local player = game.get_player(player_index)
        if not player then goto next_player end
        local chatty_name = get_chatty_name(player)

        -- don't create the cutscene if they've requested to end and we're going back to their character
        if storage.cutscene_ending and storage.cutscene_ending[player_index] and storage.cutscene_ending[player_index] == true then
            chatty_print(chatty_name .. "new target request denied by ending_transition")
            storage.create_cutscene_next_tick[player_index] = nil
            goto next_player
        end

        -- make sure the player is still connected
        if not player.connected then
            chatty_print(chatty_name .. "new target request denied by disconnected player")
            storage.create_cutscene_next_tick[player_index] = nil
            goto next_player
        end

        -- make sure things are still valid. restart trainsaver if target was invalid
        if not target_train.valid then
            storage.create_cutscene_next_tick[player_index] = nil
            local command = { name = "trainsaver", player_index = player_index }
            chatty_print(chatty_name .. "new target is invalid, restarting trainsaver")
            storage.create_cutscene_next_tick[player_index] = nil
            start_trainsaver(command, nil, true)
            goto next_player
        end

        -- if the target train has both front and back movers, then figure out which is leading the train based on if speed is + or -
        local front_movers = target_train.locomotives.front_movers
        local back_movers = target_train.locomotives.back_movers
        local state = target_train.state
        local speed = target_train.speed
        local movers = nil
        local mover = nil

        if front_movers[1] and back_movers[1] then
            -- chatty_print(chatty_name .. "speed: " .. speed)
            -- chatty_print(chatty_name .. "state: " .. verbose_states[state])
            if active_states[state] and speed ~= 0 then
                movers = speed > 0 and front_movers or back_movers
                mover = movers[1]
            end
        elseif front_movers[1] or back_movers[1] then
            mover = front_movers[1] or back_movers[1]
        end

        if mover then
            -- Abort if the potential waypoint is on a different surface than the player
            if player.surface_index ~= mover.surface_index then
                chatty_print(chatty_name .. "new target request denied by surface mismatch, player is on " .. player.surface.name .. ", target is on " .. mover.surface.name)
                storage.create_cutscene_next_tick[player_index] = nil
                goto next_player
            end

            local created_waypoints = create_waypoint(mover, player_index)

            local record_history = true

            -- If the train is bi-directional and we're just switching from one end to the other,
            -- set transition time to 15 ticks per carriage so it's nice and smooth
            -- also remove zoom so it stays the same
            -- also don't add it to watch history
            if same_train then
                created_waypoints[1].transition_time = table_size(target_train.carriages) * 15
                created_waypoints[1].zoom = nil
                record_history = false
            end

            play_cutscene(created_waypoints, player_index, record_history)
            storage.create_cutscene_next_tick[player_index] = nil
        else
            attempts = attempts and attempts + 1 or 0
            if attempts > 30 then
                chatty_print(chatty_name .. "new target request accepted with state [" .. verbose_states[state] .. "] and speed [" .. speed .. "]")
                local created_waypoints = create_waypoint(target_train.carriages[1], player_index)
                local record_history = true
                if same_train then
                    created_waypoints[1].transition_time = table_size(target_train.carriages) * 15
                    created_waypoints[1].zoom = nil
                    record_history = false
                end
                play_cutscene(created_waypoints, player_index, record_history)
                storage.create_cutscene_next_tick[player_index] = nil
            else
                chatty_print(chatty_name .. "new target request delayed by state [" .. verbose_states[state] .. "] and speed [" .. speed .. "]")
                storage.create_cutscene_next_tick[player_index][4] = attempts
            end
        end
        ::next_player::
    end
end

-- while trainsaver is active, update current and total duration player has been viewing the screensaver, and unlock achievements as needed
local function check_achievements()
    if not storage.trainsaver_status then return end
    for player_index, status in pairs(storage.trainsaver_status) do
        if not (status == "active") then goto next_player end
        local player = game.get_player(player_index)
        if not (player and player.connected) then goto next_player end
        -- update continuous duration timer global data
        storage.current_continuous_duration = storage.current_continuous_duration or {}
        storage.current_continuous_duration[player_index] = storage.current_continuous_duration[player_index] or 0
        local continuous_duration = storage.current_continuous_duration[player_index]
        continuous_duration = continuous_duration + 1
        if continuous_duration == (60 * 60 * 10) then
            player.unlock_achievement("trainsaver-continuous-10-minutes")
        end
        if continuous_duration == (60 * 60 * 30) then
            player.unlock_achievement("trainsaver-continuous-30-minutes")
        end
        if continuous_duration == (60 * 60 * 60) then
            player.unlock_achievement("trainsaver-continuous-60-minutes")
        end
        -- update total duration timer global data
        storage.total_duration = storage.total_duration or {}
        storage.total_duration[player_index] = storage.total_duration[player_index] or 0
        local total_duration = storage.total_duration[player_index]
        total_duration = total_duration + 1
        if total_duration == (60 * 60 * 60 * 1) then
            player.unlock_achievement("trainsaver-1-hours-total")
        end
        if total_duration == (60 * 60 * 60 * 2) then
            player.unlock_achievement("trainsaver-2-hours-total")
        end
        if total_duration == (60 * 60 * 60 * 5) then
            player.unlock_achievement("trainsaver-5-hours-total")
        end
        ::next_player::
    end
end

-- create any requested cutscenes and update achievement progress
local function on_tick()
    cutscene_next_tick_function()
    check_achievements()
end

-- auto-start the screensaver if player AFK time is greater than what is specified in mod settings
local function on_nth_tick()
    for _, player in pairs(game.connected_players) do
        local controller_type = player.controller_type
        if not ((controller_type == defines.controllers.character) or (controller_type == defines.controllers.god)) then goto next_player end
        local mod_settings = player.mod_settings
        local auto_start = mod_settings["ts-afk-auto-start"].value
        local auto_start_while_viewing_map = mod_settings["ts-autostart-while-viewing-map"].value
        local auto_start_while_gui_is_open = mod_settings["ts-autostart-while-gui-is-open"].value
        local opened_gui_type = player.opened_gui_type
        if auto_start == 0 then goto next_player end
        if ((player.render_mode ~= defines.render_mode.game) and (auto_start_while_viewing_map == false)) then goto next_player end
        if (opened_gui_type and (opened_gui_type ~= defines.gui_type.none) and (auto_start_while_gui_is_open == false)) then goto next_player end
        if player.afk_time < (auto_start * 60 * 60) then goto next_player end
        local command = { name = "trainsaver", player_index = player.index }
        start_trainsaver(command)
        ::next_player::
    end
end

---end trainsaver when the game menu is opened
---@param event EventData.CustomInputEvent
local function toggle_menu_pressed(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if not trainsaver_is_active(player) then return end
    if not (player.mod_settings["ts-menu-hotkey"].value == true) then return end
    local command = { player_index = event.player_index }
    end_trainsaver(command)
end

---end trainsaver when a game control keybind is pressed
---@param event EventData.CustomInputEvent
local function game_control_pressed(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if not trainsaver_is_active(player) then return end
    if not (player.mod_settings["ts-linked-game-control-hotkey"].value == true) then return end
    local command = { player_index = event.player_index }
    end_trainsaver(command)
end

--| event registration section |--

-- afk autostart
script.on_nth_tick(600, on_nth_tick)

-- create any requested cutscenes and update achievement progress
script.on_event(defines.events.on_tick, on_tick)

-- deal with global data when a cutscene ends
script.on_event(defines.events.on_cutscene_cancelled, cutscene_cancelled)
script.on_event(defines.events.on_cutscene_waypoint_reached, cutscene_waypoint_reached)
script.on_event(defines.events.on_cutscene_finished, cutscene_finished)

-- when any train changes state, check a whole bunch of stuff and tell trainsaver to focus on it depending on if various conditions are met
script.on_event(defines.events.on_train_changed_state, on_train_changed_state)

-- if cutscene character takes any damage, immediately end cutscene so player can deal with that or see death screen message. Also unlock any achievements if available
local character_damaged_filter = { { filter = "type", type = "character" } }
script.on_event(defines.events.on_entity_damaged, character_damaged, character_damaged_filter)

-- start a new cutscene if the followed locomotive dies or is mined or is destoryed
local locomotive_filter = { { filter = "type", type = "locomotive" } }
script.on_event(defines.events.on_entity_died, locomotive_gone, locomotive_filter)
script.on_event(defines.events.on_player_mined_entity, locomotive_gone, locomotive_filter)
script.on_event(defines.events.on_robot_mined_entity, locomotive_gone, locomotive_filter)
script.on_event(defines.events.on_object_destroyed, entity_destroyed)

-- start or end trainsaver based on various hotkeys and settings
script.on_event("toggle-trainsaver", start_or_end_trainsaver)
script.on_event("start-trainsaver", start_or_end_trainsaver)
script.on_event("end-trainsaver", end_trainsaver_on_command)
script.on_event("open-inventory-trainsaver", game_control_pressed)
script.on_event("open-research-trainsaver", game_control_pressed)
script.on_event("open-production-stats-trainsaver", game_control_pressed)
script.on_event("open-logistic-netowrk-trainsaver", game_control_pressed)
script.on_event("open-train-gui-trainsaver", game_control_pressed)
script.on_event("toggle-driving-trainsaver", game_control_pressed)
script.on_event("move-up-trainsaver", game_control_pressed)
script.on_event("move-down-trainsaver", game_control_pressed)
script.on_event("move-right-trainsaver", game_control_pressed)
script.on_event("move-left-trainsaver", game_control_pressed)
script.on_event("toggle-map-trainsaver", game_control_pressed)
script.on_event("shoot-enemy-trainsaver", game_control_pressed)
script.on_event("toggle-menu-trainsaver", toggle_menu_pressed)

script.on_event("next-target-trainsaver", focus_next_target)
script.on_event("previous-target-trainsaver", focus_previous_target)

--[[ s e c r e t s --]]
script.on_event(defines.events.on_rocket_launch_ordered, function(event)
    local rocket = event.rocket
    local silo = event.rocket_silo
    chatty_print("[" .. game.tick .. "] potential target [" .. get_chatty_name(rocket) .. "] ordered to launch at [" .. get_chatty_name(silo) .. "]")
    for _, player in pairs(game.connected_players) do
        if not trainsaver_is_active(player) then goto next_player end
        if player.mod_settings["ts-secrets"].value == false then goto next_player end
        local player_index = player.index
        local current_target = current_trainsaver_target(player)
        if not current_target then goto next_player end
        -- if not waypoint_target_has_idle_state(player) then goto next_player end
        if not waypoint_target_passes_inactivity_checks(player, current_target) then goto next_player end
        if remote.interfaces["cc_check"] and remote.interfaces["cc_check"]["cc_status"] then
            if remote.call("cc_check", "cc_status", player_index) == "active" then
                goto next_player
            end
        end
        -- abort if the potential waypoint is on a different surface than the player
        if player.surface_index ~= silo.surface_index then
            goto next_player
        end
        -- create the waypoints
        local created_waypoints = create_waypoint(silo, player_index)
        local silo_rocket_waypoint_2 = util.table.deepcopy(created_waypoints[1])
        table.insert(created_waypoints, 2, silo_rocket_waypoint_2)

        -- set waypoint 1 to proper settings (goal: get to rocket silo before rocket starts leaving)--]]
        if created_waypoints[1].transition_time > 440 then
            -- created_waypoints[1].transition_time = 440
            created_waypoints[1].transition_time = 0
        end
        created_waypoints[1].time_to_wait = 1
        created_waypoints[1].zoom = 0.6

        -- set waypoint 2 to proper settings (goal: zoom out from silo until rocket disapears from view and is destoryed.)
        created_waypoints[2].transition_time = 1161 - created_waypoints[1].transition_time + 10
        created_waypoints[2].zoom = 0.25

        local transfer_alt_mode = player.game_view_settings.show_entity_info
        player.set_controller(
            {
                type = defines.controllers.cutscene,
                waypoints = created_waypoints,
                --[[
                start_position = player.position,
                final_transition_time = player.mod_settings["ts-transition-time"].value * 60
                --]]
            }
        )
        player.game_view_settings.show_entity_info = transfer_alt_mode
        storage.trainsaver_status = storage.trainsaver_status or {}
        storage.trainsaver_status[player_index] = "active"
        storage.followed_loco = storage.followed_loco or {}
        storage.followed_loco[player_index] = nil
        storage.current_target = storage.current_target or {}
        storage.current_target[player_index] = created_waypoints[1].target
        storage.entity_destroyed_registration_numbers = storage.entity_destroyed_registration_numbers or {}
        storage.entity_destroyed_registration_numbers[player_index] = script.register_on_object_destroyed(rocket)
        ::next_player::
    end
end)

local function add_commands()
    commands.add_command("trainsaver", "- toggles a dynamic screensaver that follows active trains.", start_or_end_trainsaver)
    commands.add_command("end-trainsaver", "- ends the screensaver and immediately returns control to the player", end_trainsaver)
    commands.add_command("verbose-trainsaver", "- toggles trainsaver console debug messages", toggle_chatty)
    commands.add_command("reset-trainsaver-history", "- clears the history log", reset_history)
end

script.on_init(add_commands)
script.on_load(add_commands)
