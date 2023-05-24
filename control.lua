
--[[ factorio mod trainsaver control script created by asher_sky --]]

require "util"

local verbose_states = {
  [0] = "[color=green]on_the_path[/color]",	-- Normal state, following the path.
  [1] = "[color=purple]path_lost[/color]",	-- Had path and lost it, must stop.
  [2] = "[color=purple]no_schedule[/color]", -- Doesn't have anywhere to go.
  [3] = "[color=purple]no_path[/color]", -- Has no path and is stopped.
  [4] = "[color=yellow]arrive_signal[/color]", -- Braking before a rail signal.
  [5] = "[color=orange]wait_signal[/color]", -- Waiting at a signal.
  [6] = "[color=yellow]arrive_station[/color]", -- Braking before a station.
  [7] = "[color=red]wait_station[/color]", -- Waiting at a station.
  [8] = "[color=pink]manual_control_stop[/color]", -- Switched to manual control and has to stop.
  [9] = "[color=pink]manual_control[/color]", -- Can move if user explicitly sits in and rides the train.
  [10] = "[color=blue]destination_full[/color]", -- Same as no_path but all candidate train stops are full
}

local function toggle_chatty()
  if not global.chatty then
    global.chatty = true
    game.print("verbose trainsaver enabled")
  else
    global.chatty = false
    game.print("verbose trainsaver disabled")
  end
end

-- return a string with the current game tick and the name of a player colored with the player's color;
-- i.e. "[123456] [[color=1,1,1]player_name[/color]]"
---@param player LuaPlayer
---@return string
local function chatty_player_name(player)
  return "["..game.tick.."] [[color=" .. player.color.r .. "," .. player.color.g .. "," .. player.color.b .. "]" .. player.name .. "[/color]]: "
end

-- return a string with the name of the train, colored if possible with color of a locomotive on the train
---@param train LuaTrain
---@return string
local function chatty_target_train_name(train)
  local target_name = "train " .. train.id
  local front_mover = train.locomotives["front_movers"][1]
  local back_mover = train.locomotives["back_movers"][1]
  local color = front_mover.color or back_mover.color
  if color then
    target_name = "[color=" .. color.r .. "," .. color.g .. "," .. color.b .. "]" .. target_name .. "[/color]"
  end
  return target_name
end

---print a message to all players who have notable events enabled
---@param message string
local function print_notable_event(message)
  for _, player in pairs(game.connected_players) do
    if player.mod_settings["ts-notable-events"].value == true then
      player.print(message)
    end
  end
end

---comment
---@param position_1 MapPosition
---@param position_2 MapPosition
---@return integer
local function calculate_distance(position_1, position_2)
  local distance = math.floor(((position_1.x - position_2.x) ^ 2 + (position_1.y - position_2.y) ^ 2) ^ 0.5)
  return distance
end

---comment
---@param speed_kmph number
---@param distance_in_meters number
---@return number
local function convert_speed_into_time(speed_kmph, distance_in_meters)
  local speed = speed_kmph / 60 / 60 / 60 --[[ speed in km/tick --]]
  local distance = distance_in_meters / 1000 --[[ distance in kilometers --]]
  local time = 0
  if speed ~= 0 then
    time = distance / speed
  end
  return time
end

--[[ create a waypoint for given waypoint_target using player mod settings --]]
---@param waypoint_target LuaEntity
---@param player_index PlayerIndex
---@return table
local function create_waypoint(waypoint_target, player_index)
  local chatty = global.chatty
  local tt = nil
  local z = nil
  local player = game.get_player(player_index) --[[@as LuaPlayer]]
  local mod_settings = player.mod_settings
  local chatty_name = chatty_player_name(player)

  --[[ we now prefer transition speed over transition time, but that means we need to do some calculations to convert speed (kmph) into time (ticks). However, if speed = 0, then default back to just using transition time --]]
  if mod_settings["ts-transition-speed"].value > 0 then
    local speed_kmph = mod_settings["ts-transition-speed"].value --[[@as number]]
    local distance_in_meters = calculate_distance(player.position, waypoint_target.position)
    tt = convert_speed_into_time(speed_kmph, distance_in_meters)
  else
    tt = mod_settings["ts-transition-time"].value * 60 --[[ convert seconds to ticks --]]
  end

  --[[ set the waiting time and zoom variables to use later when creating the waypoint table --]]
  local wt = mod_settings["ts-time-wait"].value * 60 * 60
  if mod_settings["ts-variable-zoom"].value == true then
    local temp_zoom = mod_settings["ts-zoom"].value
    z = (math.random(((temp_zoom - (temp_zoom*.20))*1000),(((temp_zoom + (temp_zoom*.20)))*1000)))/1000
  else
    z = mod_settings["ts-zoom"].value
  end

  --[[ set transition time for final waypoint based on where we think the waypoint target will be when the cutscene is over --]]
  local tt_2 = util.table.deepcopy(tt)
  if mod_settings["ts-transition-speed"].value > 0 then
    local speed_kmph = mod_settings["ts-transition-speed"].value --[[@as number]]
    --[[ if train has a station at the end of the path, use the station location --]]
    if waypoint_target.train and waypoint_target.train.path_end_stop then
      if player.cutscene_character then
        local distance_in_meters = calculate_distance(waypoint_target.train.path_end_stop.position, player.cutscene_character.position)
        tt_2 = convert_speed_into_time(speed_kmph, distance_in_meters)
      elseif player.character then
        local distance_in_meters = calculate_distance(waypoint_target.train.path_end_stop.position, player.character.position)
        tt_2 = convert_speed_into_time(speed_kmph, distance_in_meters)
      else
        local distance_in_meters = calculate_distance(waypoint_target.train.path_end_stop.position, player.position)
        tt_2 = convert_speed_into_time(speed_kmph, distance_in_meters)
      end
    --[[ if train doesn't have a station at the end of the path but does have a rail, use the rail location instead --]]
    elseif waypoint_target.train and waypoint_target.train.path_end_rail then
      if player.cutscene_character then
        local distance_in_meters = calculate_distance(waypoint_target.train.path_end_rail.position, player.cutscene_character.position)
        tt_2 = convert_speed_into_time(speed_kmph, distance_in_meters)
      elseif player.character then
        local distance_in_meters = calculate_distance(waypoint_target.train.path_end_rail.position, player.character.position)
        tt_2 = convert_speed_into_time(speed_kmph, distance_in_meters)
      else
        local distance_in_meters = calculate_distance(waypoint_target.train.path_end_rail.position, player.position)
        tt_2 = convert_speed_into_time(speed_kmph, distance_in_meters)
      end
    --[[ if waypoint target doesn't have a path or isn't a train at all, just use its current position to calculate the final transition time instead--]]
    elseif waypoint_target.position then
      if player.cutscene_character then
        local distance_in_meters = calculate_distance(waypoint_target.position, player.cutscene_character.position)
        tt_2 = convert_speed_into_time(speed_kmph, distance_in_meters)
      elseif player.character then
        local distance_in_meters = calculate_distance(waypoint_target.position, player.character.position)
        tt_2 = convert_speed_into_time(speed_kmph, distance_in_meters)
      else
        local distance_in_meters = calculate_distance(waypoint_target.position, player.position)
        tt_2 = convert_speed_into_time(speed_kmph, distance_in_meters)
      end
    else
      tt_2 = 0
    end
  else
    tt_2 = mod_settings["ts-transition-time"].value * 60 --[[ convert seconds to ticks --]]
  end

  --[[ finally let's assemble our waypints table! --]]
  local created_waypoints = {
    {
      target = waypoint_target,
      transition_time = tt,
      time_to_wait = wt,
      zoom = z
    },
  }

  local target_name = ""
  if (waypoint_target.train and waypoint_target.train.id) then target_name = "train " .. waypoint_target.train.id else target_name = waypoint_target.name end
  if waypoint_target.color then 
    target_name = "[color="..waypoint_target.color.r..","..waypoint_target.color.g..","..waypoint_target.color.b.."]"..target_name.."[/color]"
  end

  --[[ use the player character or cutscene character as the final waypoint so transition goes back to there instead of where cutscene started if trainsaver ends due to no new train activity, but if there isn't a cutscene_character or player.character then don't add the final waypoint because the player was probably in god mode when it started so character is on a different surface or doesn't even exist, meaning there's nowhere to "go back" to --]]
  if (player.cutscene_character and (player.cutscene_character.surface.index == player.surface.index)) then
    local waypoint_2 = {
      target = player.cutscene_character,
      transition_time = tt_2,
      time_to_wait = 60,
      zoom = z
    }
    table.insert(created_waypoints, waypoint_2)

    if chatty then game.print(chatty_name.."created waypoint to "..target_name.." with return waypoint to cutscene_character") end

  elseif (player.character and (player.character.surface.index == player.surface.index)) then
    local waypoint_2 = {
      target = player.character,
      transition_time = tt_2,
      time_to_wait = 60,
      zoom = z
    }
    table.insert(created_waypoints, waypoint_2)

    if chatty then game.print(chatty_name.."created waypoint to "..target_name.." with return waypoint to player_character") end

  else
  end
  -- if chatty then game.print(chatty_name.."finalized " ..#created_waypoints .. " waypoints") end
  -- if chatty then game.print(serpent.block(created_waypoints)) end
  return created_waypoints
end

--[[ end the screensaver and nil out any globals saved for given player --]]
---comment
---@param command EventData.on_console_command
local function end_trainsaver(command)
  local chatty = global.chatty
  local player_index = command.player_index
  if not player_index then return end
  local player = game.get_player(player_index)
  if not player then return end
  local chatty_name = chatty_player_name(player)
  if player.controller_type == defines.controllers.cutscene then
    --[[ if the cutscene creator mod created the cutscene, don't cancel it --]]
    if remote.interfaces["cc_check"] and remote.interfaces["cc_check"]["cc_status"] then
      if remote.call("cc_check", "cc_status", player_index) == "active" then
        return
      end
    end

    --[[ create a new cutscene from current position back to cutscene character position so the exit is nice and smooth. If it's triggered while already going back to cutscene character, then exit immediately instead.  --]]
    if (command.ending_transition and (command.ending_transition == true)) then
      if chatty then game.print(chatty_name.."exit trainsaver (transition) requested") end
      if (global.cutscene_ending and (global.cutscene_ending[player_index] and (global.cutscene_ending[player_index] == true))) then
        if chatty then game.print(chatty_name.."trainsaver is currently exiting. immediatte exit requested") end
        player.exit_cutscene()
      elseif not (player.cutscene_character or player.character) then
        if chatty then game.print(chatty_name.."player has no character or cutscene_character. immediate exit requested") end
        player.exit_cutscene()
      else
        local mod_settings = player.mod_settings
        local waypoint_target = player.cutscene_character or player.character
        local tt = 0
        local wt = 30
        local z = 0
        if mod_settings["ts-transition-speed"].value > 0 then
          local speed_kmph = mod_settings["ts-transition-speed"].value --[[@as number]]
          local distance_in_meters = calculate_distance(player.position, waypoint_target.position)
          tt = convert_speed_into_time(speed_kmph, distance_in_meters)
        else
          tt = mod_settings["ts-transition-time"].value * 60
        end
        if mod_settings["ts-variable-zoom"].value == true then
          local temp_zoom = mod_settings["ts-zoom"].value
          z = (math.random(((temp_zoom - (temp_zoom*.20))*1000),(((temp_zoom + (temp_zoom*.20)))*1000)))/1000
        else
          z = mod_settings["ts-zoom"].value --[[@as number]]
        end
        local created_waypoints = {
          {
            target = waypoint_target,
            transition_time = tt,
            time_to_wait = wt,
            zoom = z
          },
        }
        if chatty then game.print(chatty_name.."created ending transition waypoints to player character or cutscene_character") end
        if player.surface.index ~= created_waypoints[1].target.surface.index then
          if chatty then game.print(chatty_name.."ending transition target on different surface than player. immediate exit requested") end
          player.exit_cutscene()
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
        if not global.cutscene_ending then
          global.cutscene_ending = {}
          global.cutscene_ending[player_index] = true
        else
          global.cutscene_ending[player_index] = true
        end
        if global.wait_at_signal and global.wait_at_signal[player_index] then
          global.wait_at_signal[player_index] = nil
        end
        if global.station_minimum and global.station_minimum[player_index] then
          global.station_minimum[player_index] = nil
        end
        if global.driving_minimum and global.driving_minimum[player_index] then
          global.driving_minimum[player_index] = nil
        end
      end
    else
      if chatty then game.print(chatty_name.."exit trainsaver (instant) requested") end
      player.exit_cutscene()
    end
  else
  end
end

---comment
---@param command EventData.on_console_command
local function start_trainsaver(command)
  local chatty = global.chatty
  local player_index = command.player_index
  if not player_index then return end
  local player = game.get_player(player_index)
  if not player then return end
  local chatty_name = chatty_player_name(player)
  local name = command.name
  if chatty then game.print(chatty_name.."starting trainsaver") end
  if (name == "trainsaver") and (((player.controller_type == defines.controllers.character) or (player.controller_type == defines.controllers.god)) or (command.entity_gone_restart == "yes")) then

    --[[ create a table of all trains --]]
    local table_of_all_trains = player.surface.get_trains()

    --[[ create a table of all trains that have any "movers" and are not in manual mode and are not the train that just died or was mined --]]
    local table_of_trains = {}
    if not command.train_to_ignore then
      command.train_to_ignore = {id = -999999}
    end
    for a,b in pairs(table_of_all_trains) do
      if ((b.locomotives.front_movers[1] or b.locomotives.back_movers[1]) and ( not ((b.state == defines.train_state.manual_control) or (b.state == defines.train_state.manual_control_stop) or (b.id == command.train_to_ignore.id)))) then
        table.insert(table_of_trains, b)
      end
    end
    if chatty then game.print(chatty_name.."created table of trains [" .. #table_of_trains .. " total]") end

    --[[ if there's no trains, end everything --]]
    if not table_of_trains[1] then
      if player.controller_type == defines.controllers.cutscene then
        local command = {player_index = player_index}
        if chatty then game.print(chatty_name.."no trains found") end
        end_trainsaver(command)
      end

    --[[ if there are any trains, make a table of all the active (on_the_path) ones --]]
    else
      local table_of_active_trains = {}
      for a,b in pairs(table_of_trains) do
        if b.state == defines.train_state.on_the_path then
          table.insert(table_of_active_trains, b)
        end
      end

      --[[ sort the table of active trains by how much of their path is remaining so we can focus on the one with the longest remaining path --]]
      if table_of_active_trains[1] then
        local table_of_trains_sorted_by_remaining_path_length = util.table.deepcopy(table_of_active_trains)
        table.sort(table_of_trains_sorted_by_remaining_path_length, function(a,b) return (a.path.total_distance - a.path.travelled_distance) > (b.path.total_distance - b.path.travelled_distance) end)
        if chatty then game.print(chatty_name.."created table of active trains [" .. #table_of_trains_sorted_by_remaining_path_length .. " total]") end

        if not global.create_cutscene_next_tick then
          global.create_cutscene_next_tick = {}
          global.create_cutscene_next_tick[player_index] = {table_of_trains_sorted_by_remaining_path_length[1], player_index}
        else
          global.create_cutscene_next_tick[player_index] = {table_of_trains_sorted_by_remaining_path_length[1], player_index}
        end
        if chatty then game.print(chatty_name.."requested cutscene for " .. player.name .. " next tick, following train with longest remaining path") end

      --[[ if there are any trains on_the_path, pick a random one and pass it through global.create_cutscene_next_tick global. This has been superceded by the find longest remaining path method, but we'll keep it here in comments just in case we need it at some point in the future. --]]
      --[[
      if table_of_active_trains[1] then
        local random_train_index = math.random(table_size(table_of_active_trains))
        if not global.create_cutscene_next_tick then
          global.create_cutscene_next_tick = {}
          global.create_cutscene_next_tick[player_index] = {table_of_active_trains[random_train_index], player_index}
        else
          global.create_cutscene_next_tick[player_index] = {table_of_active_trains[random_train_index], player_index}
        end
        --]]
        --[[
        if not command.entity_gone_restart == "yes" then
          sync_color(player_index)
        end
        --]]

      --[[ if there are no trains on_the_path then make a table of trains waiting at stations --]]
      else
        if chatty then game.print(chatty_name.."no trains are on_the_path") end
        local table_of_trains_at_the_station = {}
        for c,d in pairs(table_of_trains) do
          if d.state == defines.train_state.wait_station then
            table.insert(table_of_trains_at_the_station, d)
          end
        end
        if chatty then game.print(chatty_name.."created table of trains waiting at stations [" .. #table_of_trains_at_the_station .. " total]") end

        --[[ if there are any trains waiting at stations, pick a random one and play a cutscene from a front or back mover loco --]]
        if table_of_trains_at_the_station[1] then
          local random_train_index = math.random(table_size(table_of_trains_at_the_station))
          local waypoint_target = {}
          if table_of_trains_at_the_station[random_train_index].locomotives.front_movers[1] then
            waypoint_target = table_of_trains_at_the_station[random_train_index].locomotives.front_movers[1]
          elseif table_of_trains_at_the_station[random_train_index].locomotives.back_movers[1] then
            waypoint_target = table_of_trains_at_the_station[random_train_index].locomotives.back_movers[1]
          end
          if chatty then game.print(chatty_name.."chose a random train waiting at a station") end
          --[[ abort if the potential waypoint is on a different surface than the player --]]
          if player.surface.index ~= waypoint_target.surface.index then
            if chatty then game.print(chatty_name.."abort: the train is on a different surface than the player") end
            return
          end
          local created_waypoints = create_waypoint(waypoint_target, player_index)
          --[[
          if not command.entity_gone_restart == "yes" then
            sync_color(player_index)
          end
          --]]
          play_cutscene(created_waypoints, player_index)

        --[[ if there are no trains on_the_path or waiting at stations, then pick the first train from table_of_trains and play cutscene with either front or back mover as target --]]
        if chatty then game.print(chatty_name.."no trains on_the_path or waiting at stations") end
        elseif table_of_trains[1].locomotives.front_movers[1] then
          local waypoint_target = table_of_trains[1].locomotives.front_movers[1]
          if chatty then game.print(chatty_name.."chose front_mover of first train in table") end
          --[[ abort if the potential waypoint is on a different surface than the player --]]
          if player.surface.index ~= waypoint_target.surface.index then
            if chatty then game.print(chatty_name.."abort: the train is on a different surface than the player") end
            return
          end
          local created_waypoints = create_waypoint(waypoint_target, player_index)
          --[[
          if not command.entity_gone_restart == "yes" then
            sync_color(player_index)
          end
          --]]
          play_cutscene(created_waypoints, player_index)

        elseif table_of_trains[1].locomotives.back_movers[1] then
          local waypoint_target = table_of_trains[1].locomotives.back_movers[1]
          if chatty then game.print(chatty_name.."chose back_mover of first train in table") end
          --[[ abort if the potential waypoint is on a different surface than the player --]]
          if player.surface.index ~= waypoint_target.surface.index then
            if chatty then game.print(chatty_name.."abort: the train is on a different surface than the player") end
            return
          end
          local created_waypoints = create_waypoint(waypoint_target, player_index)
          --[[
          if not command.entity_gone_restart == "yes" then
            sync_color(player_index)
          end
          --]]
          play_cutscene(created_waypoints, player_index)

          --[[ if there are no trains on the path or waiting at station, and table_of_trains[1] didn't have a front or back mover (how could this happen?? a train with no locomotives that is somehow not in manual mode?? i declare haxxx) then end_trainsaver() --]]
        else
          player.print("trainsaver: something unexpected has occured. please report this event to the mod author. code: 909")
          local command = {
            player_index = player_index,
          }
          end_trainsaver(command)
        end
      end
    end
  end
end

-- remove any globals we saved for the player when trainsaver ends
---@param player_index PlayerIndex
local function cutscene_ended_nil_globals(player_index)
  if global.followed_loco and global.followed_loco[player_index] then
    global.followed_loco[player_index] = nil
  end
  if global.create_cutscene_next_tick and global.create_cutscene_next_tick[player_index] then
    global.create_cutscene_next_tick[player_index] = nil
  end
  if global.wait_at_signal and global.wait_at_signal[player_index] then
    global.wait_at_signal[player_index]= nil
  end
  if global.entity_destroyed_registration_numbers and global.entity_destroyed_registration_numbers[player_index] then
    global.entity_destroyed_registration_numbers[player_index] = nil
  end
  if global.rocket_positions and global.rocket_positions[player_index] then
    global.rocket_positions[player_index] = nil
  end
  if global.trainsaver_status and global.trainsaver_status[player_index] then
    global.trainsaver_status[player_index] = nil
  end
  if global.current_continuous_duration and global.current_continuous_duration[player_index] then
    global.current_continuous_duration[player_index] = nil
  end
  if global.current_target and global.current_target[player_index] then
    global.current_target[player_index] = nil
  end
  if global.cutscene_ending and global.cutscene_ending[player_index] then
    global.cutscene_ending[player_index] = nil
  end
  if global.number_of_waypoints and global.number_of_waypoints[player_index] then
    global.number_of_waypoints[player_index] = nil
  end
  if global.station_minimum and global.station_minimum[player_index] then
    global.station_minimum[player_index] = nil
  end
  if global.driving_minimum and global.driving_minimum[player_index] then
    global.driving_minimum[player_index] = nil
  end
end

--[[ when a cutscene is cancelled with player.exit_cutscene(), nil out any globals we saved for them. --]]
---@param event EventData.on_cutscene_cancelled
local function cutscene_cancelled(event)
  cutscene_ended_nil_globals(event.player_index)
end

--[[ nil the globals when we get to the final waypoint of the cutscene bringing player back to their character. Still need to deal with how to nil globals when cutscene finishes on its own (inactivity timeout) but hopefully they add a on_cutscene_ended() event so I can just use that for both.. --]]
---@param event EventData.on_cutscene_waypoint_reached
local function cutscene_waypoint_reached(event)
  if global.chatty then
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    local chatty_name = chatty_player_name(player)
    game.print(chatty_name.."arrived at waypoint [index "..event.waypoint_index.."]")
  end
  if global.cutscene_ending and global.cutscene_ending[event.player_index] and global.cutscene_ending[event.player_index] == true then
    cutscene_ended_nil_globals(event.player_index)
  elseif global.number_of_waypoints and global.number_of_waypoints[event.player_index] and global.number_of_waypoints[event.player_index] == event.waypoint_index then
    cutscene_ended_nil_globals(event.player_index)
  end
end

script.on_event(defines.events.on_cutscene_cancelled, cutscene_cancelled)
script.on_event(defines.events.on_cutscene_waypoint_reached, cutscene_waypoint_reached)

--[[ set character color to player color so it's the same when controller switches from character to cutscene. This is no longer used since the introduction of cutscene character now handles this, but we're keeping it here for the memories :) --]]
---@param player_index PlayerIndex
local function sync_color(player_index)
  game.players[player_index].character.color = game.players[player_index].color
end

---comment
---@param player_index PlayerIndex
---@param created_waypoints CutsceneWaypoint[]
local function update_globals_new_cutscene(player_index, created_waypoints)
  --[[ update trainsaver status global --]]
  if not global.trainsaver_status then
    global.trainsaver_status = {}
    global.trainsaver_status[player_index] = "active"
  else
    global.trainsaver_status[player_index] = "active"
  end
  --[[ update the followed_loco global --]]
  if created_waypoints[1].target.train then
    local folloco = {
      unit_number = created_waypoints[1].target.unit_number,
      train_id = created_waypoints[1].target.train.id,
      loco = created_waypoints[1].target,
    }
    if not global.followed_loco then
      global.followed_loco = {}
      global.followed_loco[player_index] = folloco
    else
      global.followed_loco[player_index] = folloco
    end
  end
  --[[ register the followed target so we get an event if it's destroyed, then save the registration number in global so we can know if the destroyed event is for our target or not --]]
  if not global.entity_destroyed_registration_numbers then
    global.entity_destroyed_registration_numbers = {}
    global.entity_destroyed_registration_numbers[player_index] = script.register_on_entity_destroyed(created_waypoints[1].target)
  else
    global.entity_destroyed_registration_numbers[player_index] = script.register_on_entity_destroyed(created_waypoints[1].target)
  end
  --[[ update the current_target global --]]
  if not global.current_target then
    global.current_target = {}
    global.current_target[player_index] = created_waypoints[1].target
  else
    global.current_target[player_index] = created_waypoints[1].target
  end
  --[[ update number of waypoints global --]]
  if not global.number_of_waypoints then
    global.number_of_waypoints = {}
    global.number_of_waypoints[player_index] = #created_waypoints
  else
    global.number_of_waypoints[player_index] = #created_waypoints
  end
  --[[ update driving minimum global --]]
  if not global.driving_minimum then
    global.driving_minimum = {}
    global.driving_minimum[player_index] = game.tick
  else
    global.driving_minimum[player_index] = game.tick
  end
end

--[[ play cutscene from given waypoints --]]
---@param created_waypoints CutsceneWaypoint[]
---@param player_index PlayerIndex
local function play_cutscene(created_waypoints, player_index)
  local chatty = global.chatty
  local player = game.get_player(player_index)
  if not player then return end
  local chatty_name = chatty_player_name(player)
  -- if chatty then game.print(chatty_name.."initiating cutscene") end
  if remote.interfaces["cc_check"] and remote.interfaces["cc_check"]["cc_status"] then
    if remote.call("cc_check", "cc_status", player_index) == "active" then
      return
    end
  end

  --[[ abort if the waypoint is on a different surface than the player. I know we've already checked this like a billion times before getting to this point, but just to make sure we're gonna check one more time just in case --]]
  if player.surface.index ~= created_waypoints[1].target.surface.index then
    if chatty then game.print(chatty_name.."abort: waypoint is on different surface than player") end
    return
  end

  --[[ save alt-mode so we can preserve it after cutscene controller resets it --]]
  local transfer_alt_mode = player.game_view_settings.show_entity_info

  --[[ set the player controller to cutscene camera --]]
  player.set_controller(
    {
      type = defines.controllers.cutscene,
      waypoints = created_waypoints,
      start_position = player.position,
      --[[ final_transition_time = tt --]]
    }
  )
  if chatty then game.print(chatty_name.."cutscene controller updated with "..#created_waypoints.." waypoints") end 

  --[[ reset alt-mode to what it was before cutscene controller reset it --]]
  player.game_view_settings.show_entity_info = transfer_alt_mode
  update_globals_new_cutscene(player_index, created_waypoints)

  --[[ unlock any achievements if possible --]]
  ----[[
    if created_waypoints[1].target.train.passengers then
      for a,b in pairs(created_waypoints[1].target.train.passengers) do
        --[[
        if b.index == player.index then
          player.unlock_achievement("trainsaver-self-reflection")
          for c,d in pairs(game.connected_players) do
            if d.mod_settings["ts-notable-events"].value == true then
              d.print("[color=orange]trainsaver:[/color] "..player.name.." saw themself riding a train")
            end
          end
        end
        --]]
        if b.index ~= player.index then
          player.unlock_achievement("trainsaver-find-a-friend")
          for c,d in pairs(game.connected_players) do
            if d.mod_settings["ts-notable-events"].value == true then
              d.print("[color=orange]trainsaver:[/color] "..player.name.." saw "..b.name.." riding a train")
            end
          end
        end
      end
    end
  if created_waypoints[1].target.train.path then
    local path = created_waypoints[1].target.train.path
    local remaining_path_distance = path.total_distance - path.travelled_distance
    if remaining_path_distance > 10000 then
      player.unlock_achievement("trainsaver-long-haul")
      -- for c,d in pairs(game.connected_players) do
      --   if d.mod_settings["ts-notable-events"].value == true then
      --     d.print("[color=orange]trainsaver:[/color] "..player.name.." is watching a train with ".. remaining_path_distance/1000 .."km remaining in its journey")
      --   end
      -- end
    end
  end
  --]]
end

-- add data to global so a cutscene is created for a given player the following tick
---@param player_index PlayerIndex
---@param train LuaTrain
local function create_cutscene_next_tick(player_index, train)
  if not global.create_cutscene_next_tick then
    global.create_cutscene_next_tick = {}
    global.create_cutscene_next_tick[player_index] = {train, player_index}
  else
    global.create_cutscene_next_tick[player_index] = {train, player_index}
  end
end

--[[ if the train that just changed state was the train the camera is following, and it just stopped at a station, then update the station_minimum global --]]
---@param event EventData.on_train_changed_state
local function update_wait_at_station(event)
  local train = event.train
  local new_state = event.train.state
  if not (new_state == defines.train_state.wait_station) then return end
  for _, player in pairs(game.connected_players) do
    if not (player.controller_type == defines.controllers.cutscene) then goto next_player end
    local player_index = player.index
    if not (global.followed_loco and global.followed_loco[player_index]) then goto next_player end
    if not (train.id == global.followed_loco[player_index].train_id )then goto next_player end
    if not global.station_minimum then
      global.station_minimum = {}
      global.station_minimum[player_index] = game.tick
    else
      global.station_minimum[player_index] = game.tick
    end
    if global.chatty then
      local target_name = chatty_target_train_name(train)
      local chatty_name = chatty_player_name(player)
      game.print(chatty_name.."current target [".. target_name .."] changed to state "..verbose_states[train.state]..". station_minimum tick saved")
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
  --[[ if camera train is waiting at signal, update the global.wait_at_signal global if necessary, then continue creating the cutscene (cutscene will not be constructed next tick if untill_tick is greater than current tick) --]]
  if --[[(old_state == defines.train_state.arrive_signal) and --]](new_state == defines.train_state.wait_signal) then
    for _, player in pairs(game.connected_players) do
      if not (player.controller_type == defines.controllers.cutscene) then goto next_player end
      if not (global.followed_loco and global.followed_loco[player.index]) then goto next_player end
      if not (train.id == global.followed_loco[player.index].train_id) then goto next_player end
      if not global.wait_at_signal then
        global.wait_at_signal = {}
        local until_tick = game.tick + (player.mod_settings["ts-wait-at-signal"].value * 60)
        global.wait_at_signal[player.index] = until_tick
      else
        if not global.wait_at_signal[player.index] then
          local until_tick = game.tick + (player.mod_settings["ts-wait-at-signal"].value * 60)
          global.wait_at_signal[player.index] = until_tick
        end
      end
      if global.chatty then
        local target_name = chatty_target_train_name(train)
        local chatty_name = chatty_player_name(player)
        game.print(chatty_name.."current target [" .. target_name .. "] changed to state " .. verbose_states[train.state] .. ". wait_at_signal tick saved")
      end
      ::next_player::
    end
  end
  --[[ if camera train has switched from waiting at a signal to moving on the path, nil out the waiting at signal global timer thing --]]
  if (old_state == defines.train_state.wait_signal) --[[and ((new_state == defines.train_state.on_the_path) or (new_state == defines.train_state.arrive_signal) or (new_state == defines.train_state.arrive_station))]] then
    for _, player in pairs(game.connected_players) do
      if not (player.controller_type == defines.controllers.cutscene) then goto next_player end
      if not (global.followed_loco and global.followed_loco[player.index]) then goto next_player end
      if not (train.id == global.followed_loco[player.index].train_id) then goto next_player end
      if global.wait_at_signal and global.wait_at_signal[player.index] then
        global.wait_at_signal[player.index] = nil
      end
      if global.chatty then
        local chatty_name = chatty_player_name(player)
        game.print(chatty_name.."current target is no longer waiting at a signal. wait_at_signal data cleared")
      end
      ::next_player::
    end
  end
end

-- when a train changes state, see if any players are eligable to transfer focus to it
---@param event EventData.on_train_changed_state
local function train_changed_state(event)
  local train = event.train
  local old_state = event.old_state
  local new_state = event.train.state
  local new_state_is_active = (new_state == defines.train_state.on_the_path) or (new_state == defines.train_state.arrive_signal)
  if not ((old_state == defines.train_state.wait_station) and new_state_is_active) then return end
  local chatty = global.chatty
  local target_name = chatty_target_train_name(train)
  if chatty then game.print("["..game.tick .. "] potential target: "..target_name.." changed state from "..verbose_states[old_state].." to "..verbose_states[new_state]) end
  for _, player in pairs(game.connected_players) do
    if not (player.controller_type == defines.controllers.cutscene) then goto next_player end
    local found_locomotive = {}
    if global.followed_loco and global.followed_loco[player.index] and global.followed_loco[player.index].loco and global.followed_loco[player.index].loco.valid then
      found_locomotive[1] = global.followed_loco[player.index].loco
    else
      found_locomotive = player.surface.find_entities_filtered({
        position = player.position,
        radius = 1,
        type = "locomotive",
        limit = 1
      })
    end
    if not found_locomotive[1] then goto next_player end
    local player_index = player.index
    local found_train = found_locomotive[1].train
    if not found_train then goto next_player end
    local found_state = found_train.state
    local chatty_name = chatty_player_name(player)
    local found_target_name = chatty_target_train_name(found_train)

    --[[ when a train changes from stopped at station to on the path or arriving at signal, and player controller is cutscene, and there's a locomotive within 1 tile of player, and that locomotive train state is on the path or arriving at signal or station, then if the train that changed state is the same train under the player, make sure we're following the leading locomotive. --]]
    if ((found_state == defines.train_state.on_the_path) or (found_state == defines.train_state.arrive_signal) or (found_state == defines.train_state.arrive_station) --[[or ((found_state == defines.train_state.manual_control) and (found_locomotive[1].train.speed ~= 0))--]]) then

      --[[ if camera is on train that changed state, switch to leading locomotive --]]
      if found_train.id == train.id then
        if not global.create_cutscene_next_tick then
          global.create_cutscene_next_tick = {}
          global.create_cutscene_next_tick[player_index] = {train, player_index, "same train"}
          if global.wait_at_signal and global.wait_at_signal[player_index] then
            global.wait_at_signal[player_index] = nil
          end
        else
          global.create_cutscene_next_tick[player_index] = {train, player_index, "same train"}
          if global.wait_at_signal and global.wait_at_signal[player_index] then
            global.wait_at_signal[player_index] = nil
          end
        end
        if chatty then game.print(chatty_name.."current target ["..found_target_name.."] is the train that changed state. targetting lead locomotive") end

      --[[ if the camera is not following the train that just changed state, and if the camera has been following the same train for a longer time than allowed by mod settings, then go ahead and find a new train to follow --]]
      elseif global.driving_minimum and global.driving_minimum[player_index] then
        local driving_since_tick = global.driving_minimum[player_index]
        local minimum_allowed_time = player.mod_settings["ts-driving-minimum"].value * 60 * 60 --[[ converting minutes to ticks --]]
        if (driving_since_tick + minimum_allowed_time) < game.tick then
          create_cutscene_next_tick(player_index, train)
          if chatty then game.print(chatty_name.."current target ["..found_target_name.."] has exceeded the "..minimum_allowed_time.." tick minimum for ".. verbose_states[found_state]) end
        else
          if chatty then game.print(chatty_name.."current target ["..found_target_name.."] is ".. verbose_states[found_state] .. ". new target request denied by driving_minimum") end
        end

      --   --[[ if the train the camera is following has any state other than on_the_path, arrive_signal, or arrive_station, and it's not the same train that just changed state, and the driving minimum has not been reached yet, then create a cutscene following the train that generated the change_state event on the next tick --]]
      -- else
      --   if not global.create_cutscene_next_tick then
      --     global.create_cutscene_next_tick = {}
      --     global.create_cutscene_next_tick[player_index] = {train, player_index}
      --   else
      --     global.create_cutscene_next_tick[player_index] = {train, player_index}
      --   end
      --   if chatty then game.print(chatty_name.."current target state is on_the_path, arrive_signal, or arrive_station, but it's not the same train that just changed state, and the driving minimum has not been reached yet. switching camera to follow new train") end
      end

    --[[ if the train the camera is following is waiting at a station, and the minimum time to wait at a station has been reached, then go create a new cutscene following the train that generated the change_state event on the next tick --]]
    elseif (found_state == defines.train_state.wait_station) and (global.station_minimum and global.station_minimum[player_index]) then
      local waiting_since_tick = global.station_minimum[player_index]
      local minimum_allowed_time = player.mod_settings["ts-station-minimum"].value * 60 --[[ converting seconds to ticks --]]
      if (waiting_since_tick + minimum_allowed_time) < game.tick then
        create_cutscene_next_tick(player_index, train)
        if chatty then game.print(chatty_name.."current target ["..found_target_name.."] has exceeded the "..minimum_allowed_time.." tick minimum for ".. verbose_states[found_state]) end
      else
        if chatty then game.print(chatty_name.."current target ["..found_target_name.."] is ".. verbose_states[found_state] .. ". new target request denied by station_minimum") end
      end

    --[[ if global.wait_at_signal untill_tick is greater than current game tick, then don't create a new cutscene: set create_cutscene_next_tick to nil and wait until next train state update. If we've passed the untill_tick, then set wait_at_signal to nill and continue creating the cutscene --]]
    elseif (found_state == defines.train_state.wait_signal) and (global.wait_at_signal and global.wait_at_signal[player_index]) then
      if global.wait_at_signal[player_index] > game.tick then
        global.create_cutscene_next_tick[player_index] = nil
        if chatty then game.print(chatty_name.."current target ["..found_target_name.."] is ".. verbose_states[found_state] .. ". new target request denied by signal_minimum") end
      else
        global.wait_at_signal[player_index] = nil
        create_cutscene_next_tick(player_index, train)
        if chatty then game.print(chatty_name.."current target ["..found_target_name.."] has exceeded the ".. player.mod_settings["ts-wait-at-signal"].value * 60 --[[ converting seconds to ticks --]].." tick minimum for ".. verbose_states[found_state]) end
      end

    --[[ if the train we're following is not on the path, or arriving at a station, or arriving at a signal, and it's not waiting at a station, then make go follow the new train that just left the station --]]
    else
      create_cutscene_next_tick(player_index, train)
      -- if chatty then game.print(chatty_name.."current target ["..found_train.id..", "..verbose_states[found_state].."] state is not on_the_path, arrive_signal, arrive_station, or wait_station") end
    end
    ::next_player::
  end
  update_wait_at_signal(event)
  update_wait_at_station(event)
end

---end trainsaver if the cutscene character takes any damage
---@param event EventData.on_entity_damaged
local function character_damaged(event)
  local damaged_entity = event.entity
  for _, player in pairs(game.connected_players) do
    if ((player.controller_type == defines.controllers.cutscene) and (player.cutscene_character == damaged_entity) and global.trainsaver_status and global.trainsaver_status[player.index] and (global.trainsaver_status[player.index] == "active")) then
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

--[[ restart trainsaver when the currently followed locomotive is destroyed --]]
---@param event EventData.on_entity_died | EventData.on_robot_mined_entity | EventData.on_player_mined_entity
local function locomotive_gone(event)
  local locomotive = event.entity
  for _,player in pairs(game.connected_players) do
    if not (player.controller_type == defines.controllers.cutscene) then goto next_player end
    local player_index = player.index
    if not (global.followed_loco and global.followed_loco[player_index]) then goto next_player end
    if not (global.followed_loco[player_index].unit_number == locomotive.unit_number) then goto next_player end
    local command = {
      name = "trainsaver",
      player_index = player_index,
      entity_gone_restart = "yes",
      train_to_ignore = event.entity.train
      }
    start_trainsaver(command)
    ::next_player::
  end
end

--[[ restart trainsaver when the currently followed cutscene target is destroyed --]]
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
      --[[ if we just watched a rocket launch, restart trainsaver to find a new train to follow --]]
      local player = game.get_player(player_index)
      if not player then goto next_player end
      if not (player.controller_type == defines.controllers.cutscene) then goto next_player end
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
        entity_gone_restart = "yes",
      }
      start_trainsaver(command)
    end
    ::next_player::
  end
end

--[[ create a new cutscene for any players that need one. cutscenes need to be delayed one tick because trains that change state don't have a speed yet so we need to wait one tick for them to start moving so we can determine which locomotive is the "leader". --]]
local function cutscene_next_tick_function()
  --[[ check if any players need a new cutscene --]]
  if not global.create_cutscene_next_tick then return end
  for _, data in pairs(global.create_cutscene_next_tick) do
    local target_train = data[1]
    local player_index = data[2]
    local player = game.get_player(player_index)
    if not player then goto next_player end
    local chatty = global.chatty
    local chatty_name, target_name = "", ""
    if chatty then
      chatty_name = "["..game.tick.."] [[color=" .. player.color.r .. "," .. player.color.g .. "," .. player.color.b .. "]" .. player.name .. "[/color]]: "
      target_name = "train " .. target_train.id
      if target_train.locomotives["front_movers"] and target_train.locomotives["front_movers"][1] and target_train.locomotives["front_movers"][1].color then
        target_name = "[color="..target_train.locomotives["front_movers"][1].color.r..","..target_train.locomotives["front_movers"][1].color.g..","..target_train.locomotives["front_movers"][1].color.b.."]"..target_name.."[/color]"
      elseif target_train.locomotives["back_movers"] and target_train.locomotives["back_movers"][1] and target_train.locomotives["back_movers"][1].color then
        target_name = "[color="..target_train.locomotives[2][1].color.r..","..target_train.locomotives[2][1].color.g..","..target_train.locomotives[2][1].color.b.."]"..target_name.."[/color]"
      end
    end

    --[[ don't create the cutscene if they've requested to end and we're going back to their character --]]
    if global.cutscene_ending and global.cutscene_ending[player_index] and global.cutscene_ending[player_index] == true then
      if chatty then game.print(chatty_name.."new target request denied by ending_transition") end
      global.create_cutscene_next_tick[player_index] = nil
      goto next_player
    end

    --[[ make sure the player is still connected --]]
    if not player.connected then
      if chatty then game.print(chatty_name.."new target request denied by disconnected player") end
      global.create_cutscene_next_tick[player_index] = nil
      goto next_player
    end

    --[[ make sure things are still valid. they should be but idk, i guess doesn't hurt too much to make sure? --]]
    if not (target_train.valid and (target_train.locomotives.front_movers[1].valid or target_train.locomotives.back_movers[1].valid)) then
      global.create_cutscene_next_tick[player_index] = nil
      --[[ trying this because idk what else to do. why does it go to 0,0 when a train is on a spaceship going to a different surface in space exploration mod? ahhhhhhhhh --]]
      local command = {
        name = "trainsaver",
        player_index = player_index,
        entity_gone_restart = "yes",
        -- train_to_ignore = event.entity.train
        }
      if chatty then game.print(chatty_name.."new target is invalid, restarting trainsaver") end
      global.create_cutscene_next_tick[player_index] = nil
      start_trainsaver(command)
      goto next_player
    end

    -- --[[ if global.wait_at_signal untill_tick is greater than current game tick, then don't create a new cutscene: set create_cutscene_next_tick to nil and wait until next train state update. If we've passed the untill_tick, then set wait_at_signal to nill and continue creating the cutscene --]]
    -- if global.wait_at_signal and global.wait_at_signal[player_index] then
    --   -- game.print("stored: " .. global.wait_at_signal[player_index] .. ", game: " .. game.tick)
    --   if global.wait_at_signal[player_index] > game.tick then
    --     global.create_cutscene_next_tick[player_index] = nil
    --     if chatty then game.print(chatty_name.."current target ["..target_name.."] is ".. verbose_states[target_train.state] .. ". new target request denied by signal_minimum") end
    --     return
    --   else
    --     global.wait_at_signal[player_index] = nil
    --     -- game.print("wait_at_signal cleared")
    --     if chatty then game.print(chatty_name.."current target ["..target_name.."] has exceeded the ".. game.players[player_index].mod_settings["ts-wait-at-signal"].value * 60 * 60 --[[ converting minutes to ticks --]].." tick minimum for ".. verbose_states[target_train.state]) end
    --   end
    -- end

    --[[ if the target train has both front and back movers, then figure out which is leading the train based on if speed is + or - --]]
    if ((target_train.locomotives.front_movers[1]) and (target_train.locomotives.back_movers[1])) then
      if target_train.speed > 0 then
        --[[ abort if the potential waypoint is on a different surface than the player --]]
        if player.surface.index ~= target_train.locomotives.front_movers[1].surface.index then
          goto next_player
        end
        local created_waypoints = create_waypoint(target_train.locomotives.front_movers[1], player_index)
        --[[ if the train is bi-directional and we're just switching from one end to the other, set transition time to 15 ticks per carriage so it's nice and smooth. Also nil out zoom so it doesn't go crazy --]]
        if data[3] then
          created_waypoints[1].transition_time = table_size(target_train.carriages) * 15
          created_waypoints[1].zoom = nil
        end
        play_cutscene(created_waypoints, player_index)
        global.create_cutscene_next_tick[player_index] = nil
      end
      if target_train.speed < 0 then
        --[[ abort if the potential waypoint is on a different surface than the player --]]
        if player.surface.index ~= target_train.locomotives.back_movers[1].surface.index then
          goto next_player
        end
        local created_waypoints = create_waypoint(target_train.locomotives.back_movers[1], player_index)
        --[[ if the train is bi-directional and we're just switching from one end to the other, set transition time to 15 ticks per carriage so it's nice and smooth. Also nil out zoom so it doesn't go crazy on us --]]
        if data[3] then
          created_waypoints[1].transition_time = table_size(target_train.carriages) * 15
          created_waypoints[1].zoom = nil
        end
        play_cutscene(created_waypoints, player_index)
        global.create_cutscene_next_tick[player_index] = nil
      end

    --[[ if target train doesn't have both front and back movers, then create waypoints/cutscene for whichever movers type it does have --]]
    elseif ((target_train.locomotives.front_movers[1]) or (target_train.locomotives.back_movers[1])) then
      if target_train.locomotives.front_movers[1] then
        --[[ abort if the potential waypoint is on a different surface than the player --]]
        if player.surface.index ~= target_train.locomotives.front_movers[1].surface.index then
          goto next_player
        end
        local created_waypoints = create_waypoint(target_train.locomotives.front_movers[1], player_index)
        --[[ if the train is bi-directional and we're just switching from one end to the other, set transition time to 15 ticks per carriage so it's nice and smooth. Also nil out zoom so it doesn't go crazy on us --]]
        if data[3] then
          created_waypoints[1].zoom = nil
        end
        play_cutscene(created_waypoints, player_index)
        global.create_cutscene_next_tick[player_index] = nil
      end
      if target_train.locomotives.back_movers[1] then
        --[[ abort if the potential waypoint is on a different surface than the player --]]
        if player.surface.index ~= target_train.locomotives.back_movers[1].surface.index then
          goto next_player
        end
        local created_waypoints = create_waypoint(target_train.locomotives.back_movers[1], player_index)
        --[[ if the train is bi-directional and we're just switching from one end to the other, set transition time to 15 ticks per carriage so it's nice and smooth. Also nil out zoom so it doesn't go crazy on us --]]
        if data[3] then
          created_waypoints[1].zoom = nil
        end
        play_cutscene(created_waypoints, player_index)
        global.create_cutscene_next_tick[player_index] = nil
      end
    end
    ::next_player::
  end
end

-- --[[ because the rocket destroyed event is not guarenteed to happen in the same tick that the rocket is destroyed, and the cutscene camera will immediately go to [gps=0,0] if the target is destroyed, we need to save the location of the rocket right before it's destroyed so we can teleport the player to that location immediately after the camera goes to [gps=0,0] so that the next cutscene starts where the rocket was destroyed and not at [gps=0,0] --]]
-- local function save_rocket_positions()
--   if global.rocket_positions then
--     for a,b in pairs(global.rocket_positions) do
--       local player = game.get_player(a)
--       if not player.connected then
--         return
--       end
--       table.insert(global.rocket_positions[a], game.tick, player.position)
--     end
--   end
-- end

--[[ while trainsaver is active, update current and total duration player has been viewing the screensaver, and unlock achievements as needed --]]
local function check_achievements()
  if not global.trainsaver_status then return end
  for player_index, status in pairs(global.trainsaver_status) do
    if not (status == "active") then goto next_player end
    local player = game.get_player(player_index)
    if not (player and player.connected) then goto next_player end
    --[[ update continuous duration timer global data --]]
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
    --[[ update total duration timer global data --]]
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

--[[ create any requested cutscenes and update achievement progress --]]
local function on_tick()
  cutscene_next_tick_function()
  -- save_rocket_positions()
  check_achievements()
end

--[[ auto-start the screensaver if player AFK time is greater than what is specified in mod settings --]]
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
    local command = {player_index = event.player_index, ending_transition = true}
    end_trainsaver(command)
  end
end

---end trainsaver when the /end-trainsaver command is used
---@param event EventData.on_console_command
local function end_trainsaver_on_command(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  if not (player.controller_type == defines.controllers.cutscene) then return end
  local command = {player_index = event.player_index, ending_transition = true}
  end_trainsaver(command)
end

---end trainsaver when the game menu is opened
---@param event EventData.CustomInputEvent
local function toggle_menu_pressed(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  if not (player.controller_type == defines.controllers.cutscene) then return end
  if not (player.mod_settings["ts-menu-hotkey"].value == true) then return end
  local command = {player_index = event.player_index}
  end_trainsaver(command)
end

---end trainsaver when a game control keybind is pressed
---@param event EventData.CustomInputEvent
local function game_control_pressed(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  if not (player.controller_type == defines.controllers.cutscene) then return end
  if not (player.mod_settings["ts-linked-game-control-hotkey"].value == true) then return end
  local command = {player_index = event.player_index}
  end_trainsaver(command)
end

--| event registration section |--

--[[ afk autostart --]]
script.on_nth_tick(600, on_nth_tick)

--[[ create any requested cutscenes and update achievement progress --]]
script.on_event(defines.events.on_tick, on_tick)

--[[ when any train changes state, check a whole bunch of stuff and tell trainsaver to focus on it depending on if various conditions are met --]]
script.on_event(defines.events.on_train_changed_state, train_changed_state)

--[[ if cutscene character takes any damage, immediately end cutscene so player can deal with that or see death screen message. Also unlock any achievements if available --]]
local character_damaged_filter = {{filter = "type", type = "character"}}
script.on_event(defines.events.on_entity_damaged, character_damaged, character_damaged_filter)

--[[ start a new cutscene if the followed locomotive dies or is mined or is destoryed --]]
local locomotive_filter = {{filter = "type", type = "locomotive"}}
script.on_event(defines.events.on_entity_died, locomotive_gone, locomotive_filter)
script.on_event(defines.events.on_player_mined_entity, locomotive_gone, locomotive_filter)
script.on_event(defines.events.on_robot_mined_entity, locomotive_gone, locomotive_filter)
script.on_event(defines.events.on_entity_destroyed, entity_destroyed)

--[[ start or end trainsaver based on various hotkeys and settings --]]
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
  for a,b in pairs(game.connected_players) do
    if b.controller_type == defines.controllers.cutscene then
      local player_index = b.index
      local player = b
      if player.mod_settings["ts-secrets"].value == false then
        return
      end
      local found_locomotive = {}
      if global.followed_loco and global.followed_loco[player_index] and global.followed_loco[player_index].loco and global.followed_loco[player_index].loco.valid then
        found_locomotive[1] = global.followed_loco[player_index].loco
      else
        found_locomotive = b.surface.find_entities_filtered({
          position = b.position,
          radius = 1,
          type = "locomotive",
          limit = 1
        })
      end
      if found_locomotive[1] then
        local found_train = found_locomotive[1].train
        local found_state = found_train.state
        if ((found_state == defines.train_state.wait_signal) or (found_state == defines.train_state.wait_station)) then
          if global.wait_at_signal and global.wait_at_signal[player_index] then
            if global.wait_at_signal[player_index] > game.tick then
              return
            end
          end
          if remote.interfaces["cc_check"] and remote.interfaces["cc_check"]["cc_status"] then
            if remote.call("cc_check", "cc_status", player_index) == "active" then
              return
            end
          end
          --[[ abort if the potential waypoint is on a different surface than the player --]]
          if player.surface.index ~= silo.surface.index then
            return
          end
          --[[ create the waypoints --]]
          local created_waypoints = create_waypoint(silo, player_index)
          silo_rocket_waypoint_2 = util.table.deepcopy(created_waypoints[1])
          table.insert(created_waypoints, 2, silo_rocket_waypoint_2)

          --[[ set waypoint 1 to proper settings (goal: get to rocket silo before rocket starts leaving)--]]
          if created_waypoints[1].transition_time > 440 then
            --[[ created_waypoints[1].transition_time = 440 --]]
            created_waypoints[1].transition_time = 0
          end
          created_waypoints[1].time_to_wait = 1
          created_waypoints[1].zoom = 0.5

          --[[ set waypoint 2 to proper settings (goal: zoom out from silo until rocket disapears from view and is destoryed.) --]]
          created_waypoints[2].transition_time = 1161 - created_waypoints[1].transition_time + 10
          created_waypoints[2].zoom = 0.2

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
          if not global.trainsaver_status then
            global.trainsaver_status = {}
            global.trainsaver_status[player_index] = "active"
          else
            global.trainsaver_status[player_index] = "active"
          end
          --[[
          if not global.rocket_positions then
            global.rocket_positions = {}
            global.rocket_positions[player_index] = {}
          else
            global.rocket_positions[player_index] = {}
          end
          --]]
          if global.followed_loco and global.followed_loco[player_index] then
            global.followed_loco[player_index] = nil
          end
          if not global.entity_destroyed_registration_numbers then
            global.entity_destroyed_registration_numbers = {}
            global.entity_destroyed_registration_numbers[player_index] = script.register_on_entity_destroyed(rocket)
          else
            global.entity_destroyed_registration_numbers[player_index] = script.register_on_entity_destroyed(rocket)
          end
        end
      end
    end
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

remote.add_interface("trainsaver",interface_functions)
