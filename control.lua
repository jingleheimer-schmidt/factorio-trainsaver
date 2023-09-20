
--[[ factorio mod trainsaver control script created by asher_sky --]]

require "util"

local constants = require("util.constants")
local verbose_states = constants.verbose_states
local active_states = constants.active_states
local idle_states = constants.idle_states
local wait_station_states = constants.wait_station_states
local wait_signal_states = constants.wait_signal_states
local always_accept_new_target_states = constants.always_accept_new_target_states

local messages = require("util.messages")
local toggle_chatty = messages.toggle_chatty
local chatty_print = messages.chatty_print
local chatty_player_name = messages.chatty_player_name
local chatty_target_train_name = messages.chatty_target_train_name
local chatty_target_entity_name = messages.chatty_target_entity_name
local get_chatty_name = messages.get_chatty_name
local print_notable_event = messages.print_notable_event

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
      waypoint_2_start_entity = {position = waypoint_target.autopilot_destinations[#waypoint_target.autopilot_destinations]} or {}
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
  local waypoint_target = player.cutscene_character or player.character --[[@as LuaEntity because it was already checked earlier]]
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
  chatty_print(chatty_name.."created ending transition waypoints to " .. character_name)
  if player.surface_index ~= created_waypoints[1].target.surface_index then
    chatty_print(chatty_name.."ending transition target on different surface than player. immediate exit requested")
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
    table.sort(active_trains_sorted_by_remaining_path_length, function(a,b) return (a.path.total_distance - a.path.travelled_distance) > (b.path.total_distance - b.path.travelled_distance) end)
    create_cutscene_next_tick(player_index, active_trains_sorted_by_remaining_path_length[1])
    chatty_print(chatty_name.."requested cutscene for " .. player.name .. ", following train with longest remaining path")
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

-- remove any globals we saved for the player when trainsaver ends
---@param player_index uint
local function cutscene_ended_nil_globals(player_index)
  global.create_cutscene_next_tick = global.create_cutscene_next_tick or {}
  global.create_cutscene_next_tick[player_index] = nil
  global.wait_at_signal = global.wait_at_signal or {}
  global.wait_at_signal[player_index] = nil
  global.entity_destroyed_registration_numbers = global.entity_destroyed_registration_numbers or {}
  global.entity_destroyed_registration_numbers[player_index] = nil
  global.rocket_positions = global.rocket_positions or {}
  global.rocket_positions[player_index] = nil
  global.trainsaver_status = global.trainsaver_status or {}
  global.trainsaver_status[player_index] = nil
  global.current_continuous_duration = global.current_continuous_duration or {}
  global.current_continuous_duration[player_index] = nil
  global.current_target = global.current_target or {}
  global.current_target[player_index] = nil
  global.cutscene_ending = global.cutscene_ending or {}
  global.cutscene_ending[player_index] = nil
  global.number_of_waypoints = global.number_of_waypoints or {}
  global.number_of_waypoints[player_index] = nil
  global.driving_until_tick = global.driving_until_tick or {}
  global.driving_until_tick[player_index] = nil
  global.wait_signal_until_tick = global.wait_signal_until_tick or {}
  global.wait_signal_until_tick[player_index] = nil
  global.wait_station_until_tick = global.wait_station_until_tick or {}
  global.wait_station_until_tick[player_index] = nil
  global.wait_station_since_tick = global.wait_station_since_tick or {}
  global.wait_station_since_tick[player_index] = nil
  global.spider_idle_until_tick = global.spider_idle_until_tick or {}
  global.spider_idle_until_tick[player_index] = nil
  global.spider_walking_until_tick = global.spider_walking_until_tick or {}
  global.spider_walking_until_tick[player_index] = nil

  -- gobals that aren't supposed to be used any more, but might still exist from older versions of the mod
  global.followed_loco = global.followed_loco or {}
  global.followed_loco[player_index] = nil
  global.driving_since_tick = global.driving_since_tick or {}
  global.driving_since_tick[player_index] = nil
  global.wait_signal_since_tick = global.wait_signal_since_tick or {}
  global.wait_signal_since_tick[player_index] = nil
  global.station_minimum = global.station_minimum or {}
  global.station_minimum[player_index] = nil
  global.driving_minimum = global.driving_minimum or {}
  global.driving_minimum[player_index] = nil
end

-- when a cutscene is cancelled with player.exit_cutscene(), nil out any globals we saved for them
---@param event EventData.on_cutscene_cancelled
local function cutscene_cancelled(event)
  cutscene_ended_nil_globals(event.player_index)
end

---@param event EventData.on_cutscene_finished
local function cutscene_finished(event)
  cutscene_ended_nil_globals(event.player_index)
end

-- nil the globals when we get to the final waypoint of the cutscene bringing player back to their character. Still need to deal with how to nil globals when cutscene finishes on its own (inactivity timeout) but hopefully they add a on_cutscene_ended() event so I can just use that for both...
---@param event EventData.on_cutscene_waypoint_reached
local function cutscene_waypoint_reached(event)
  if global.chatty then
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    local chatty_name = get_chatty_name(player)
    game.print(chatty_name.."arrived at waypoint [index "..event.waypoint_index.."]")
  end
  local player_index = event.player_index
  global.cutscene_ending = global.cutscene_ending or {}
  local cutscene_ending = global.cutscene_ending[player_index]
  global.number_of_waypoints = global.number_of_waypoints or {}
  local number_of_waypoints = global.number_of_waypoints[player_index]
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

-- update all the globals for a newly created cutscene
---@param player LuaPlayer
---@param created_waypoints CutsceneWaypoint[]
local function update_globals_new_cutscene(player, created_waypoints)
  local player_index = player.index
  local waypoint_target = created_waypoints[1].target
  local waypoint_position = created_waypoints[1].position
  local mod_settings = player.mod_settings
  local chatty_name = get_chatty_name(player)
  -- local station_minimum = mod_settings["ts-station-minimum"].value * 60
  local driving_minimum = mod_settings["ts-driving-minimum"].value * 60 * 60
  local current_tick = game.tick
  -- update trainsaver status global
  global.trainsaver_status = global.trainsaver_status or {} ---@type table<uint, "active"|nil>
  global.trainsaver_status[player_index] = "active"
  -- register the followed target so we get an event if it's destroyed, then save the registration number in global so we can know if the destroyed event is for our target or not
  if target_is_entity(waypoint_target) then
    global.entity_destroyed_registration_numbers = global.entity_destroyed_registration_numbers or {} ---@type table<uint, uint64>
    global.entity_destroyed_registration_numbers[player_index] = script.register_on_entity_destroyed(waypoint_target --[[@as LuaEntity]])
  end
  -- update the current_target global
  global.current_target = global.current_target or {} ---@type table<uint, LuaEntity|LuaUnitGroup>
  global.current_target[player_index] = waypoint_target
  -- update number of waypoints global
  global.number_of_waypoints = global.number_of_waypoints or {} ---@type table<uint, integer>
  global.number_of_waypoints[player_index] = #created_waypoints
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
    global.followed_loco = global.followed_loco or {} ---@type table<uint, FollowedLocomotiveData>
    global.followed_loco[player_index] = followed_locomotive_data
    -- update driving minimum global
    local state = locomotive.train.state
    if active_states[state] then
      global.driving_until_tick = global.driving_until_tick or {} ---@type table<uint, uint|number>
      global.driving_until_tick[player_index] = current_tick + driving_minimum
      chatty_print(chatty_name .. "acquired new target [" .. get_chatty_name(current_trainsaver_target(player)) .. "]. set driving_until_tick to [" .. global.driving_until_tick[player.index] .. "]")
    end
    if wait_station_states[state] then
      global.wait_station_until_tick = global.wait_station_until_tick or {} ---@type table<uint, uint|number>
      global.wait_station_until_tick[player_index] = current_tick + driving_minimum
      chatty_print(chatty_name .. "acquired new target [" .. get_chatty_name(current_trainsaver_target(player)) .. "]. set wait_station_until_tick to [" .. global.wait_station_until_tick[player.index] .. "]")
    end
    if wait_signal_states[state] then
      global.wait_signal_until_tick = global.wait_signal_until_tick or {} ---@type table<uint, uint|number>
      global.wait_signal_until_tick[player_index] = current_tick + driving_minimum
      chatty_print(chatty_name .. "acquired new target [" .. get_chatty_name(current_trainsaver_target(player)) .. "]. set wait_signal_until_tick to [" .. global.wait_signal_until_tick[player.index] .. "]")
    end
    global.spider_walking_until_tick = global.spider_walking_until_tick or {}
    global.spider_walking_until_tick[player_index] = nil
    global.spider_idle_until_tick = global.spider_idle_until_tick or {}
    global.spider_idle_until_tick[player_index] = nil
  end
  -- update the spider_walking_until_tick global
  if target_is_spider(waypoint_target) then
    global.spider_walking_until_tick = global.spider_walking_until_tick or {} ---@type table<uint, uint>
    global.spider_walking_until_tick[player_index] = current_tick + driving_minimum
    chatty_print(chatty_name .. "acquired new target [" .. get_chatty_name(current_trainsaver_target(player)) .. "]. set spider_walking_until_tick to [" .. global.spider_walking_until_tick[player.index] .. "]")
    global.spider_idle_until_tick = global.spider_idle_until_tick or {}
    global.spider_idle_until_tick[player_index] = nil
    global.wait_signal_until_tick = global.wait_signal_until_tick or {}
    global.wait_signal_until_tick[player_index] = nil
    global.driving_until_tick = global.driving_until_tick or {}
    global.driving_until_tick[player_index] = nil
    global.wait_station_until_tick = global.wait_station_until_tick or {}
    global.wait_station_until_tick[player_index] = nil
  end
end

-- play cutscene from given waypoints
---@param created_waypoints CutsceneWaypoint[]
---@param player_index uint
local function play_cutscene(created_waypoints, player_index)
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
    chatty_print(chatty_name.."abort: waypoint is on different surface than player")
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
  update_globals_new_cutscene(player, created_waypoints)

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
          print_notable_event("[color=orange]trainsaver:[/color] "..player.name.." saw themself riding a train")
        end
        --]]
        if passenger.index ~= player.index then
          player.unlock_achievement("trainsaver-find-a-friend")
          print_notable_event("[color=orange]trainsaver:[/color] "..player.name.." saw "..passenger.name.." riding a train")
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
    if not (train.id == current_target_train.id)then goto next_player end
    global.wait_station_until_tick = global.wait_station_until_tick or {}
    global.wait_station_until_tick[player_index] = game.tick + player.mod_settings["ts-station-minimum"].value * 60
    if global.chatty then
      -- local target_name = chatty_target_train_name(train)
      local target_name = get_chatty_name(global.followed_loco[player_index].loco)
      local chatty_name = get_chatty_name(player)
      game.print(chatty_name.."current target [".. target_name .."] changed to state ["..verbose_states[train.state].."]. wait_station_until_tick set to [" .. global.wait_station_until_tick[player_index] .. "]")
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
  -- if camera train is waiting at signal, update the global.wait_at_signal global if necessary, then continue creating the cutscene (cutscene will not be constructed next tick if untill_tick is greater than current tick)
  if --[[(old_state == defines.train_state.arrive_signal) and --]](new_state == defines.train_state.wait_signal) then
    for _, player in pairs(game.connected_players) do
      if not trainsaver_is_active(player) then goto next_player end
      local current_target = current_trainsaver_target(player)
      if not target_is_locomotive(current_target) then goto next_player end
      local current_target_train = current_target and current_target.train --[[@as LuaTrain]]
      if not (train.id == current_target_train.id) then goto next_player end
      global.wait_signal_until_tick = global.wait_signal_until_tick or {}
      global.wait_signal_until_tick[player.index] = game.tick + (player.mod_settings["ts-wait-at-signal"].value * 60)
      if global.chatty then
        local target_name = get_chatty_name(train)
        local chatty_name = get_chatty_name(player)
        chatty_print(chatty_name.."current target [" .. target_name .. "] changed to state [" .. verbose_states[train.state] .. "]. wait_signal_until_tick set to [" .. global.wait_signal_until_tick[player.index] .. "]")
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
      global.wait_signal_until_tick = global.wait_signal_until_tick or {}
      global.wait_signal_until_tick[player.index] = nil
      if global.chatty then
        local chatty_name = get_chatty_name(player)
        local target_name = get_chatty_name(train)
        game.print(chatty_name.."current target [" .. target_name .. "] changed to state [" .. verbose_states[train.state] .. "]. wait_signal_until_tick set to [nil]")
      end
      ::next_player::
    end
  end
end

-- 
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
    if not (current_target and target_is_entity(current_target))then goto next_player end
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
      local current_target_id = script.register_on_entity_destroyed(current_target --[[@as LuaEntity]]) -- carefull... might be a unitgroup
      local spider_id = script.register_on_entity_destroyed(spider --[[@as LuaEntity]])
      if current_target_id == spider_id then
        global.spider_idle_until_tick = global.spider_idle_until_tick or {}
        global.spider_idle_until_tick[player.index] = game.tick + mod_settings["ts-station-minimum"].value * 60
        chatty_print(chatty_name .. "current target [" .. chatty_target_name .. "] reached its final destination. set spider_idle_until_tick to [" .. global.spider_idle_until_tick[player.index] .. "]")
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
        play_cutscene(waypoints, player.index)
        goto next_player
      else
        goto next_player
      end
    elseif target_is_spider(current_target) then
      local spider_id = script.register_on_entity_destroyed(spider)
      local current_target_id = script.register_on_entity_destroyed(current_target --[[@as LuaEntity]])
      if (spider_id == current_target_id) then
        chatty_print(chatty_name .. "denied. current target [" .. current_target_name .. "] is the potential target")
        goto next_player
      elseif waypoint_target_passes_inactivity_checks(player, current_target) then
        local waypoints = create_waypoint(spider, player.index)
        if waypoints[1].zoom then
          waypoints[1].zoom = waypoints[1].zoom * 1.75
        end
        play_cutscene(waypoints, player.index)
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
      play_cutscene(waypoints, player_index)
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
      if event.cause and event.cause.train and event.cause.train.id and global.followed_loco[player.index] and global.followed_loco[player.index].train_id and (event.cause.train.id == global.followed_loco[player.index].train_id) then
        player.unlock_achievement("trainsaver-damaged-by-followed-train")
        print_notable_event("[color=orange]trainsaver:[/color] "..player.name.." was hit by the train they were watching")
      elseif event.cause and event.cause.name then
        print_notable_event("[color=orange]trainsaver:[/color] "..player.name.." was hurt by "..event.cause.name.." while watching the trains")
      else
        print_notable_event("[color=orange]trainsaver:[/color] "..player.name.." was hurt while watching the trains")
      end
      local command = {player_index = player.index}
      end_trainsaver(command)
    end
  end
end

-- restart trainsaver when the currently followed locomotive is destroyed
---@param event EventData.on_entity_died | EventData.on_robot_mined_entity | EventData.on_player_mined_entity
local function locomotive_gone(event)
  local locomotive = event.entity
  for _,player in pairs(game.connected_players) do
    if not trainsaver_is_active(player) then goto next_player end
    local player_index = player.index
    if not (global.followed_loco and global.followed_loco[player_index]) then goto next_player end
    if not (global.followed_loco[player_index].unit_number == locomotive.unit_number) then goto next_player end
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
---@param event EventData.on_entity_destroyed
local function entity_destroyed(event)
  local registration_number = event.registration_number
  if not global.entity_destroyed_registration_numbers then return end
  for player_index, current_target_registration_number in pairs(global.entity_destroyed_registration_numbers) do
    if not (current_target_registration_number == registration_number) then goto next_player end
    if event.unit_number then
      local simulated_event = {
        entity = {
          unit_number = event.unit_number,
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
      player.teleport(global.rocket_positions[player_index][rocket_destroyed_location_index])
      global.rocket_positions[player_index] = nil
      --]]
      player.unlock_achievement("trainsaver-a-spectacular-view")
      print_notable_event("[color=orange]trainsaver:[/color] "..player.name.." saw something spectacular")
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
  if not global.create_cutscene_next_tick then return end
  for _, data in pairs(global.create_cutscene_next_tick) do
    local target_train = data[1]
    local player_index = data[2]
    local same_train = data[3]
    local attempts = data[4]
    local player = game.get_player(player_index)
    if not player then goto next_player end
    local chatty_name = get_chatty_name(player)

    -- don't create the cutscene if they've requested to end and we're going back to their character
    if global.cutscene_ending and global.cutscene_ending[player_index] and global.cutscene_ending[player_index] == true then
      chatty_print(chatty_name.."new target request denied by ending_transition")
      global.create_cutscene_next_tick[player_index] = nil
      goto next_player
    end

    -- make sure the player is still connected
    if not player.connected then
      chatty_print(chatty_name.."new target request denied by disconnected player")
      global.create_cutscene_next_tick[player_index] = nil
      goto next_player
    end

    -- make sure things are still valid. restart trainsaver if target was invalid
    if not target_train.valid then
      global.create_cutscene_next_tick[player_index] = nil
      local command = { name = "trainsaver", player_index = player_index }
      chatty_print(chatty_name.."new target is invalid, restarting trainsaver")
      global.create_cutscene_next_tick[player_index] = nil
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
        chatty_print(chatty_name.."new target request denied by surface mismatch, player is on "..player.surface.name..", target is on "..mover.surface.name)
        global.create_cutscene_next_tick[player_index] = nil
        goto next_player
      end

      local created_waypoints = create_waypoint(mover, player_index)

      -- If the train is bi-directional and we're just switching from one end to the other,
      -- set transition time to 15 ticks per carriage so it's nice and smooth. Also remove zoom so it stays the same
      if same_train then
        created_waypoints[1].transition_time = table_size(target_train.carriages) * 15
        created_waypoints[1].zoom = nil
      end

      play_cutscene(created_waypoints, player_index)
      global.create_cutscene_next_tick[player_index] = nil
    else
      attempts = attempts and attempts + 1 or 0
      if attempts > 30 then
        chatty_print(chatty_name .. "new target request accepted with state [" .. verbose_states[state] .. "] and speed [" .. speed .. "]")
        local created_waypoints = create_waypoint(target_train.carriages[1], player_index)
        play_cutscene(created_waypoints, player_index)
        global.create_cutscene_next_tick[player_index] = nil
      else
        chatty_print(chatty_name .. "new target request delayed by state [" .. verbose_states[state] .. "] and speed [" .. speed .. "]")
        global.create_cutscene_next_tick[player_index][4] = attempts
      end
    end
    ::next_player::
  end
end

-- while trainsaver is active, update current and total duration player has been viewing the screensaver, and unlock achievements as needed
local function check_achievements()
  if not global.trainsaver_status then return end
  for player_index, status in pairs(global.trainsaver_status) do
    if not (status == "active") then goto next_player end
    local player = game.get_player(player_index)
    if not (player and player.connected) then goto next_player end
    -- update continuous duration timer global data
    global.current_continuous_duration = global.current_continuous_duration or {}
    global.current_continuous_duration[player_index] = global.current_continuous_duration[player_index] or 0
    local continuous_duration = global.current_continuous_duration[player_index]
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
    global.total_duration = global.total_duration or {}
    global.total_duration[player_index] = global.total_duration[player_index] or 0
    local total_duration = global.total_duration[player_index]
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
    local command = {name = "trainsaver", player_index = player.index}
    start_trainsaver(command)
    ::next_player::
  end
end

---start or end trainsaver depending on player controller type
---@param event EventData.CustomInputEvent | EventData.on_console_command
local function start_or_end_trainsaver(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  if ((player.controller_type == defines.controllers.character) or (player.controller_type == defines.controllers.god)) then
    local command = {name = "trainsaver", player_index = event.player_index}
    start_trainsaver(command)
  elseif player.controller_type == defines.controllers.cutscene then
    -- local command = {player_index = event.player_index, ending_transition = true}
    local command = {player_index = event.player_index}
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
  local command = {player_index = event.player_index}
  end_trainsaver(command, true)
end

---end trainsaver when the game menu is opened
---@param event EventData.CustomInputEvent
local function toggle_menu_pressed(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  if not trainsaver_is_active(player) then return end
  if not (player.mod_settings["ts-menu-hotkey"].value == true) then return end
  local command = {player_index = event.player_index}
  end_trainsaver(command)
end

---end trainsaver when a game control keybind is pressed
---@param event EventData.CustomInputEvent
local function game_control_pressed(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  if not trainsaver_is_active(player) then return end
  if not (player.mod_settings["ts-linked-game-control-hotkey"].value == true) then return end
  local command = {player_index = event.player_index}
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
-- script.on_event(defines.events.on_cutscene_finished, cutscene_finished) -- gotta wait until factorio 1.1.82 becomes stable, and then release a version of trainsaver that makes that as minimum version.

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
script.on_event(defines.events.on_entity_destroyed, entity_destroyed)

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
    global.trainsaver_status = global.trainsaver_status or {}
    global.trainsaver_status[player_index] = "active"
    global.followed_loco = global.followed_loco or {}
    global.followed_loco[player_index] = nil
    global.current_target = global.current_target or {}
    global.current_target[player_index] = created_waypoints[1].target
    global.entity_destroyed_registration_numbers = global.entity_destroyed_registration_numbers or {}
    global.entity_destroyed_registration_numbers[player_index] = script.register_on_entity_destroyed(rocket)
  ::next_player::
  end
end)

local function add_commands()
  commands.add_command("trainsaver", "- toggles a dynamic screensaver that follows active trains.", start_or_end_trainsaver)
  commands.add_command("end-trainsaver","- ends the screensaver and immediately returns control to the player", end_trainsaver)
  commands.add_command("verbose-trainsaver","- toggles trainsaver console debug messages", toggle_chatty)
end

script.on_init(add_commands)
script.on_load(add_commands)

--[[
Remote Interface:
  remote.call("trainsaver", "trainsaver_status", player_index) --> returns the status of trainsaver for a given player, either "active" or "inactive"
  remote.call("trainsaver", "trainsaver_target", player_index) --> returns the current target (locomotive or other entity) trainsaver is following for a given player or nil if none
--]]

local interface_functions = {}
interface_functions.trainsaver_status = function(player_index)
  if global.trainsaver_status and global.trainsaver_status[player_index] then
    return global.trainsaver_status[player_index]
  else
    return "inactive"
  end
end
interface_functions.trainsaver_target = function(player_index)
  if global.current_target and global.current_target[player_index] then
    return global.current_target[player_index]
  else
    return nil
  end
end

remote.add_interface("trainsaver", interface_functions)
