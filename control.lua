
--[[ factorio mod "trainsaver" control script created by asher_sky --]]

require "util"

script.on_init(function()
  add_commands()
end)

script.on_load(function()
  add_commands()
end)

function add_commands()
  commands.add_command("trainsaver", "- starts a dynamic screensaver that follows active trains.", start_trainsaver)
  commands.add_command("end-trainsaver","- ends the screensaver and immediately returns control to the player", end_trainsaver)
end

function start_trainsaver(command)
  local player_index = command.player_index
  local player = game.get_player(player_index)
  local name = command.name
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

    --[[ if there's no trains, end everything --]]
    if not table_of_trains[1] then
      if game.players[player_index].controller_type == defines.controllers.cutscene then
        local command = {player_index = player_index}
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

      --[[ if there are any trains on_the_path, pick a random one and pass it through global.create_cutscene_next_tick global --]]
      if table_of_active_trains[1] then
        local random_train_index = math.random(table_size(table_of_active_trains))
        if not global.create_cutscene_next_tick then
          global.create_cutscene_next_tick = {}
          global.create_cutscene_next_tick[player_index] = {table_of_active_trains[random_train_index], player_index}
        else
          global.create_cutscene_next_tick[player_index] = {table_of_active_trains[random_train_index], player_index}
        end
        --[[
        if not command.entity_gone_restart == "yes" then
          sync_color(player_index)
        end
        --]]

      --[[ if there are no trains on_the_path then make a table of trains waiting at stations --]]
      else
        local table_of_trains_at_the_station = {}
        for c,d in pairs(table_of_trains) do
          if d.state == defines.train_state.wait_station then
            table.insert(table_of_trains_at_the_station, d)
          end
        end

        --[[ if there are any trains waiting at stations, pick a random one and play a cutscene from a front or back mover loco --]]
        if table_of_trains_at_the_station[1] then
          local random_train_index = math.random(table_size(table_of_trains_at_the_station))
          local waypoint_target = {}
          if table_of_trains_at_the_station[random_train_index].locomotives.front_movers[1] then
            waypoint_target = table_of_trains_at_the_station[random_train_index].locomotives.front_movers[1]
          elseif table_of_trains_at_the_station[random_train_index].locomotives.back_movers[1] then
            waypoint_target = table_of_trains_at_the_station[random_train_index].locomotives.back_movers[1]
          end
          local created_waypoints = create_waypoint(waypoint_target, player_index)
          --[[
          if not command.entity_gone_restart == "yes" then
            sync_color(player_index)
          end
          --]]
          play_cutscene(created_waypoints, player_index)

        --[[ if there are no trains on_the_path or waiting at stations, then pick the first train from table_of_trains and play cutscene with either front or back mover as target --]]
        elseif table_of_trains[1].locomotives.front_movers[1] then
          local waypoint_target = table_of_trains[1].locomotives.front_movers[1]
          local created_waypoints = create_waypoint(waypoint_target, player_index)
          --[[
          if not command.entity_gone_restart == "yes" then
            sync_color(player_index)
          end
          --]]
          play_cutscene(created_waypoints, player_index)
        elseif table_of_trains[1].locomotives.back_movers[1] then
          local waypoint_target = table_of_trains[1].locomotives.back_movers[1]
          local created_waypoints = create_waypoint(waypoint_target, player_index)
          --[[
          if not command.entity_gone_restart == "yes" then
            sync_color(player_index)
          end
          --]]
          play_cutscene(created_waypoints, player_index)

          --[[ if there are no trains on the path or waiting at station, and table_of_trains[1] didn't have a front or back mover (this should never happen) then end_trainsaver() --]]
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

--[[ create a waypoint for given waypoint_target locomotive using player mod settings --]]
function create_waypoint(waypoint_target, player_index)
  local tt = {}
  local z = {}
  local mod_settings = game.get_player(player_index).mod_settings
  if mod_settings["ts-transition-time"].value == 0 then
    tt = 1
  else
    tt = mod_settings["ts-transition-time"].value * 60
  end
  local wt = mod_settings["ts-time-wait"].value * 60 * 60
  if mod_settings["ts-variable-zoom"].value == true then
    local temp_zoom = mod_settings["ts-zoom"].value
    z = (math.random(((temp_zoom - (temp_zoom*.15))*1000),(((temp_zoom + (temp_zoom*.15)))*1000)))/1000
  else
    z = mod_settings["ts-zoom"].value
  end
  local created_waypoints = {
    {
      target = waypoint_target,
      transition_time = tt,
      time_to_wait = wt,
      zoom = z
    }
  }
  return created_waypoints
end

--[[ end the screensaver and nil out any globals saved for given player --]]
function end_trainsaver(command)
  local player_index = command.player_index
  local player = game.get_player(player_index)
  if player.controller_type == defines.controllers.cutscene then
    if remote.interfaces["cc_check"] and remote.interfaces["cc_check"]["cc_status"] then
      if remote.call("cc_check", "cc_status", player_index) == "active" then
        return
      end
    end
    player.exit_cutscene()
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
  else
  end
end

--[[
-- set character color to player color so it's the same when controller switches from character to cutscene. Might not be necessary anymore since introduction of cutscene character, could be worth investigating further
function sync_color(player_index)
  game.players[player_index].character.color = game.players[player_index].color
end
--]]

--[[ play cutscene from given waypoints --]]
function play_cutscene(created_waypoints, player_index)
  local player = game.get_player(player_index)
  if remote.interfaces["cc_check"] and remote.interfaces["cc_check"]["cc_status"] then
    if remote.call("cc_check", "cc_status", player_index) == "active" then
      return
    end
  end
  --[[ abort if the waypoint is on a different surface than the player --]]
  if player.surface.index ~= created_waypoints[1].target.surface.index then
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
      final_transition_time = player.mod_settings["ts-transition-time"].value
    }
  )
  --[[ reset alt-mode to what it was before cutscene controller reset it --]]
  player.game_view_settings.show_entity_info = transfer_alt_mode
  --[[ unlock any achievements if possible --]]
  if created_waypoints[1].target.train.passengers then
    for a,b in pairs(created_waypoints[1].target.train.passengers) do
      if b.index == player.index then
        player.unlock_achievement("trainsaver-self-reflection")
      end
      if b.index ~= player.index then
        player.unlock_achievement("trainsaver-find-a-friend")
      end
    end
  end
  --[[ update trainsaver status global --]]
  if not global.trainsaver_status then
    global.trainsaver_status = {}
    global.trainsaver_status[player_index] = "active"
  else
    global.trainsaver_status[player_index] = "active"
  end
  --[[ update the followed_loco global --]]
  if not global.followed_loco then
    global.followed_loco = {}
    global.followed_loco[player_index] = {
      unit_number = created_waypoints[1].target.unit_number,
      train_id = created_waypoints[1].target.train.id,
      loco = created_waypoints[1].target,
    }
  else
    global.followed_loco[player_index] = {
      unit_number = created_waypoints[1].target.unit_number,
      train_id = created_waypoints[1].target.train.id,
      loco = created_waypoints[1].target,
    }
  end
  --[[ register the followed target so we get an event if it's destroyed, save the registration number in global so we can know if the destroyed event is for our target or not --]]
  if not global.entity_destroyed_registration_numbers then
    global.entity_destroyed_registration_numbers = {}
    global.entity_destroyed_registration_numbers[player_index] = script.register_on_entity_destroyed(created_waypoints[1].target)
  else
    global.entity_destroyed_registration_numbers[player_index] = script.register_on_entity_destroyed(created_waypoints[1].target)
  end
end

--[[ when any train changes state, check a whole bunch of stuff and tell trainsaver to focus on it depending on if various conditions are met --]]
script.on_event(defines.events.on_train_changed_state, function(train_changed_state_event)
  local train = train_changed_state_event.train
  local old_state = train_changed_state_event.old_state
  local new_state = train_changed_state_event.train.state
  if (--[[((old_state == defines.train_state.path_lost) or (old_state == defines.train_state.no_schedule) or (old_state == defines.train_state.no_path) or (old_state == defines.train_state.arrive_signal) or (old_state == defines.train_state.wait_signal) or (old_state == defines.train_state.arrive_station)or --]] (old_state == defines.train_state.wait_station) --[[or (old_state == defines.train_state.manual_control_stop) or (old_state == defines.train_state.manual_control))--]] and ((new_state == defines.train_state.on_the_path) or (new_state == defines.train_state.arrive_signal)) --[[or ((new_state == defines.train_state.manual_control) and (train.speed ~= 0))--]]) then
    for a,b in pairs(game.connected_players) do
      if b.controller_type == defines.controllers.cutscene then
        local found_locomotive = {}
        if global.followed_loco and global.followed_loco[b.index] and global.followed_loco[b.index].loco.valid then
          found_locomotive[1] = global.followed_loco[b.index].loco
        else
          found_locomotive = b.surface.find_entities_filtered({
            position = b.position,
            radius = 1,
            type = "locomotive",
            limit = 1
          })
        end
        if found_locomotive[1] then
          local player_index = b.index
          local found_train = found_locomotive[1].train
          local found_state = found_train.state

          --[[ when a train changes from stopped at station to on the path or arriving at signal, and player controller is cutscene, and there's a locomotive within 1 tile of player, and that locomotive train state is on the path or arriving at signal or station, then if the train that changed state is the same train under the player, make sure we're following the leading locomotive. --]]
          if ((found_state == defines.train_state.on_the_path) or (found_state == defines.train_state.arrive_signal) or (found_state == defines.train_state.arrive_station)--[[or ((found_state == defines.train_state.manual_control) and (found_locomotive[1].train.speed ~= 0))--]]) then

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
            end
          else

            --[[ if the train the camera is following has any state other than on_the_path, arrive_signal, or arrive_station, then create a cutscene following the train that generated the change_state event on the next tick --]]
            if not global.create_cutscene_next_tick then
              global.create_cutscene_next_tick = {}
              global.create_cutscene_next_tick[player_index] = {train, player_index}
            else
              global.create_cutscene_next_tick[player_index] = {train, player_index}
            end
          end
        end
      end
    end
  end

  --[[ if camera train is waiting at signal, update the global.wait_at_signal global if necessary, then continue creating the cutscene (cutscene will not be constructed next tick if untill_tick is greater than current tick) --]]
  if (old_state == defines.train_state.arrive_signal) and (new_state == defines.train_state.wait_signal) then
    for a,b in pairs(game.connected_players) do
      if b.controller_type == defines.controllers.cutscene then
        if global.followed_loco and global.followed_loco[b.index] then
          if train.id == global.followed_loco[b.index].train_id then
            if not global.wait_at_signal then
              global.wait_at_signal = {}
              local until_tick = game.tick + (b.mod_settings["ts-wait-at-signal"].value * 60)
              global.wait_at_signal[b.index] = until_tick
            else
              if not global.wait_at_signal[b.index] then
                local until_tick = game.tick + (b.mod_settings["ts-wait-at-signal"].value * 60)
                global.wait_at_signal[b.index] = until_tick
              end
            end
          end
        end
      end
    end
  end
  --[[ if camera train has switched from waiting at a signal to moving on the path, nil out the waiting at signal global timer thing --]]
  if (old_state == defines.train_state.wait_signal) and ((new_state == defines.train_state.on_the_path) or (new_state == defines.train_state.arrive_signal) or (new_state == defines.train_state.arrive_station)) then
    for a,b in pairs(game.connected_players) do
      if b.controller_type == defines.controllers.cutscene then
        if global.followed_loco and global.followed_loco[b.index] then
          if train.id == global.followed_loco[b.index].train_id then
            if global.wait_at_signal and global.wait_at_signal[b.index] then
              global.wait_at_signal[b.index] = nil
            end
          end
        end
      end
    end
  end
end)

--[[ if cutscene character takes any damage, immediately end cutscene so player can deal with that or see death screen message. Also unlock any achievements if available --]]
script.on_event(defines.events.on_entity_damaged, function(character_damaged_event) character_damaged(character_damaged_event) end, {{filter = "type", type = "character"}})

function character_damaged(character_damaged_event)
  local damaged_entity = character_damaged_event.entity
  for a,b in pairs(game.connected_players) do
    if ((b.controller_type == defines.controllers.cutscene) and (b.cutscene_character == damaged_entity) and (global.trainsaver_status[b.index] == "active")) then
      local command = {player_index = b.index}
      end_trainsaver(command)
      b.unlock_achievement("trainsaver-character-damaged")
      if character_damaged_event.cause and character_damaged_event.cause.train and (character_damaged_event.cause.train.id == global.followed_loco[b.index].train_id) then
        b.unlock_achievement("trainsaver-damaged-by-followed-train")
      end
    end
  end
end

--[[ start a new cutscene if the followed locomotive dies or is mined or is destoryed --]]
script.on_event(defines.events.on_entity_died, function(event) locomotive_gone(event) end, {{filter = "type", type = "locomotive"}})
script.on_event(defines.events.on_player_mined_entity, function(event) locomotive_gone(event) end, {{filter = "type", type = "locomotive"}})
script.on_event(defines.events.on_robot_mined_entity, function(event) locomotive_gone(event) end, {{filter = "type", type = "locomotive"}})
script.on_event(defines.events.on_entity_destroyed, function(event)
  local registration_number = event.registration_number
  if global.entity_destroyed_registration_numbers then
    for a,b in pairs(global.entity_destroyed_registration_numbers) do
      if b == registration_number then
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
          local player_index = a
          local player = game.get_player(player_index)
          if player.controller_type == defines.controllers.cutscene then
            local command = {
              name = "trainsaver",
              player_index = player_index,
              entity_gone_restart = "yes",
            }
            local rocket_destroyed_location_index = game.tick - 1
            player.teleport(global.rocket_positions[player_index][rocket_destroyed_location_index])
            global.rocket_positions[player_index] = nil
            player.unlock_achievement("trainsaver-a-spectacular-view")
            start_trainsaver(command)
          end
        end
      end
    end
  end
end)

function locomotive_gone(event)
  local locomotive = event.entity
  for a,b in pairs(game.connected_players) do
    if b.controller_type == defines.controllers.cutscene then
      local player_index = b.index
      if global.followed_loco and global.followed_loco[player_index] then
        if global.followed_loco[player_index].unit_number == locomotive.unit_number then
          local command = {
            name = "trainsaver",
            player_index = player_index,
            entity_gone_restart = "yes",
            train_to_ignore = event.entity.train
            }
          start_trainsaver(command)
        end
      end
    end
  end
end

--[[ every tick do a whole bunch of stuff that's hidden away in these little function calls --]]
script.on_event(defines.events.on_tick, function()
  cutscene_next_tick_function()
  save_rocket_positions()
  check_achievements()
end)

function cutscene_next_tick_function()

  --[[ every tick check if we need to create a new cutscene --]]
  if global.create_cutscene_next_tick then
    for a,b in pairs(global.create_cutscene_next_tick) do
      local target_train = b[1]
      local player_index = b[2]

      --[[ make sure the player is still connected --]]
      if not game.get_player(player_index).connected then
        return
      end

      --[[ make sure things are still valid. they should be but idk, i guess doesn't hurt too much to make sure? --]]
      if not (target_train.locomotives.front_movers[1].valid or target_train.locomotives.back_movers[1].valid) then
        return
      end

      --[[ if global.wait_at_signal untill_tick is greater than current game tick, then don't create a new cutscene: set create_cutscene_next_tick to nil and wait until next train state update. If we've passed the untill_tick, then set wait_at_signal to nill and continue creating the cutscene --]]
      if global.wait_at_signal and global.wait_at_signal[player_index] then
        if global.wait_at_signal[player_index] > game.tick then
          global.create_cutscene_next_tick[player_index] = nil
          return
        else
          global.wait_at_signal[player_index] = nil
        end
      end

      --[[ if the target train has both front and back movers, then figure out which is leading the train based on if speed is + or - --]]
      if ((target_train.locomotives.front_movers[1]) and (target_train.locomotives.back_movers[1])) then
        if target_train.speed > 0 then
          local created_waypoints = create_waypoint(target_train.locomotives.front_movers[1], player_index)
          if b[3] then
            created_waypoints[1].transition_time = table_size(target_train.carriages) * 15
            created_waypoints[1].zoom = nil
          end
          play_cutscene(created_waypoints, player_index)
          global.create_cutscene_next_tick[player_index] = nil
        end
        if target_train.speed < 0 then
          local created_waypoints = create_waypoint(target_train.locomotives.back_movers[1], player_index)
          if b[3] then
            created_waypoints[1].transition_time = table_size(target_train.carriages) * 15
            created_waypoints[1].zoom = nil
          end
          play_cutscene(created_waypoints, player_index)
          global.create_cutscene_next_tick[player_index] = nil
        end

      --[[ if target train doesn't have both front and back movers, then create waypoints/cutscene for whichever movers type it does have --]]
      elseif ((target_train.locomotives.front_movers[1]) or (target_train.locomotives.back_movers[1])) then
        if target_train.locomotives.front_movers[1] then
          local created_waypoints = create_waypoint(target_train.locomotives.front_movers[1], player_index)
          if b[3] then
            created_waypoints[1].zoom = nil
          end
          play_cutscene(created_waypoints, player_index)
          global.create_cutscene_next_tick[player_index] = nil
        end
        if target_train.locomotives.back_movers[1] then
          local created_waypoints = create_waypoint(target_train.locomotives.back_movers[1], player_index)
          if b[3] then
            created_waypoints[1].zoom = nil
          end
          play_cutscene(created_waypoints, player_index)
          global.create_cutscene_next_tick[player_index] = nil
        end
      end
    end
  end
end

--[[ because the rocket destroyed event is not guarenteed to happen in the same tick that the rocket is destroyed, and the cutscene camera will immediately go to [gps=0,0] if the target is destroyed, we need to save the location of the rocket right before it's destroyed so we can teleport the player to that location immediately after the camera goes to [gps=0,0] so that the next cutscene starts where the rocket was destroyed and not at [gps=0,0] --]]
function save_rocket_positions()
  if global.rocket_positions then
    for a,b in pairs(global.rocket_positions) do
      if not game.get_player(a).connected then
        return
      end
      table.insert(global.rocket_positions[a], game.tick, game.get_player(a).position)
      -- game.print(game.get_player(a).position)
    end
  end
end

--[[ while trainsaver is active, update current and total duration player has been viewing the screensaver, and unlock achievements as needed --]]
function check_achievements()
  if global.trainsaver_status then
    for a,b in pairs(global.trainsaver_status) do
      if b == "active" then
        if not game.get_player(a).connected then
          return
        end
        --[[ update continuous duration timer global data --]]
        if not global.current_continuous_duration then
          global.current_continuous_duration = {}
          global.current_continuous_duration[a] = 1
        else
          if not global.current_continuous_duration[a] then
            global.current_continuous_duration[a] = 1
          else
            global.current_continuous_duration[a] = global.current_continuous_duration[a] + 1
            if global.current_continuous_duration[a] == (60 * 60 * 10) then
              game.get_player(a).unlock_achievement("trainsaver-continuous-10-minutes")
            end
            if global.current_continuous_duration[a] == (60 * 60 * 30) then
              game.get_player(a).unlock_achievement("trainsaver-continuous-30-minutes")
            end
            if global.current_continuous_duration[a] == (60 * 60 * 60) then
              game.get_player(a).unlock_achievement("trainsaver-continuous-60-minutes")
            end
          end
        end
        --[[ update total duration timer global data --]]
        if not global.total_duration then
          global.total_duration = {}
          global.total_duration[a] = 1
        else
          if not global.total_duration[a] then
            global.total_duration[a] = 1
          else
            global.total_duration[a] = global.total_duration[a] + 1
            if global.total_duration[a] == (60 * 60 * 60) then
              game.get_player(a).unlock_achievement("trainsaver-1-hours-total")
            end
            if global.total_duration[a] == (60 * 60 * 60 * 2) then
              game.get_player(a).unlock_achievement("trainsaver-2-hours-total")
            end
            if global.total_duration[a] == (60 * 60 * 60 * 5) then
              game.get_player(a).unlock_achievement("trainsaver-5-hours-total")
            end
          end
        end
      end
    end
  end
end

--[[ auto-start the screensaver if player AFK time is greater than what is specified in mod settings --]]
script.on_nth_tick(600, function()
  for a,b in pairs(game.connected_players) do
    if ((b.controller_type == defines.controllers.character) or (b.controller_type == defines.controllers.god)) then
      if b.mod_settings["ts-afk-auto-start"].value == 0 then
        return
      end
      if ((b.render_mode ~= defines.render_mode.game) and (b.mod_settings["ts-autostart-while-viewing-map"].value == false)) then
        return
      end
      if (b.opened_gui_type and (b.opened_gui_type ~= defines.gui_type.none) and (b.mod_settings["ts-autostart-while-gui-is-open"].value == false)) then
        return
      end
      if b.afk_time > (b.mod_settings["ts-afk-auto-start"].value * 60 * 60) then
        local command = {name = "trainsaver", player_index = b.index}
        start_trainsaver(command)
      end
    end
  end
end)

--[[ start or end trainsaver based on various hotkeys and settings --]]
script.on_event("toggle-trainsaver", function(event)
  local player = game.get_player(event.player_index)
  if ((player.controller_type == defines.controllers.character) or (player.controller_type == defines.controllers.god)) then
    local command = {name = "trainsaver", player_index = event.player_index}
    start_trainsaver(command)
  elseif player.controller_type == defines.controllers.cutscene then
    local command = {player_index = event.player_index}
    end_trainsaver(command)
  end
end)

script.on_event("start-trainsaver", function(event)
  local player = game.get_player(event.player_index)
  if ((player.controller_type == defines.controllers.character) or (player.controller_type == defines.controllers.god)) then
    local command = {name = "trainsaver", player_index = event.player_index}
    start_trainsaver(command)
  end
end)

script.on_event("end-trainsaver", function(event)
  if game.get_player(event.player_index).controller_type == defines.controllers.cutscene then
    local command = {player_index = event.player_index}
    end_trainsaver(command)
  end
end)

script.on_event("open-inventory-trainsaver", function(event)
  game_control_pressed(event)
end)

script.on_event("open-research-trainsaver", function(event)
  game_control_pressed(event)
end)

script.on_event("open-production-stats-trainsaver", function(event)
  game_control_pressed(event)
end)

script.on_event("open-logistic-netowrk-trainsaver", function(event)
  game_control_pressed(event)
end)

script.on_event("open-train-gui-trainsaver", function(event)
  game_control_pressed(event)
end)

script.on_event("toggle-menu-trainsaver", function(event)
  local player = game.get_player(event.player_index)
  if player.controller_type == defines.controllers.cutscene then
    if player.mod_settings["ts-menu-hotkey"].value == true then
      local command = {player_index = event.player_index}
      end_trainsaver(command)
    end
  end
end)

function game_control_pressed(event)
  local player = game.get_player(event.player_index)
  if player.controller_type == defines.controllers.cutscene then
    if player.mod_settings["ts-linked-game-control-hotkey"].value == true then
      local command = {player_index = event.player_index}
      end_trainsaver(command)
    end
  end
end

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
          local created_waypoints = create_waypoint(rocket, player_index)
          if player.surface.index ~= created_waypoints[1].target.surface.index then
            return
          end
          created_waypoints[2] = util.table.deepcopy(created_waypoints[1])
          created_waypoints[1].time_to_wait = 1
          created_waypoints[1].zoom = 0.5
          created_waypoints[2].zoom = 0.2
          if created_waypoints[1].transition_time > (7 * 60) then
            created_waypoints[1].transition_time = 7 * 60
          end
          --[[ 1162 ticks is how long the rocket takes between launch_ordered and being destroyed, times it by 1.3 so the camera can't quite keep up, minus tt to account for how long it takes to get to the rocket silo from previous waypoint in the first place --]]
          local display_height = player.display_resolution.height
          local temp_tt = (((1162 * 1.4) - (800/4)) + (display_height / 4))
          --[[ 1510.6 transition time looks ok at 800 display height but not quite right at smaller heights, and also not quite right at different transition times (why?) --]]
          -- [[created_waypoints[2].transition_time = ((1162*1.3) - (60 * player.mod_settings["ts-transition-time"].value)) --]]
          created_waypoints[2].transition_time = (temp_tt - created_waypoints[1].transition_time)
          if created_waypoints[2].transition_time < 1 then
            created_waypoints[2].transition_time = 1
          end
          local transfer_alt_mode = player.game_view_settings.show_entity_info
          player.set_controller(
            {
              type = defines.controllers.cutscene,
              waypoints = created_waypoints,
              start_position = player.position,
              final_transition_time = player.mod_settings["ts-transition-time"].value
            }
          )
          player.game_view_settings.show_entity_info = transfer_alt_mode
          if not global.trainsaver_status then
            global.trainsaver_status = {}
            global.trainsaver_status[player_index] = "active"
          else
            global.trainsaver_status[player_index] = "active"
          end
          if not global.rocket_positions then
            global.rocket_positions = {}
            global.rocket_positions[player_index] = {}
          else
            global.rocket_positions[player_index] = {}
          end
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
