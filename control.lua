
script.on_init(function()
  commands.add_command("trainsaver", "starts a dynamic screensaver that follows active trains.", start_trainsaver)
  commands.add_command("end-trainsaver","- Ends the screensaver and immediately returns control to the player", end_trainsaver)
end)

script.on_load(function()
  commands.add_command("trainsaver", "starts a dynamic screensaver that follows active trains.", start_trainsaver)
  commands.add_command("end-trainsaver","- Ends the screensaver and immediately returns control to the player", end_trainsaver)
end)

function start_trainsaver(command)
  local player_index = command.player_index
  local name = command.name
  if (name == "trainsaver") and (game.players[player_index].controller_type == defines.controllers.character) then
    local table_of_trains = game.players[player_index].surface.get_trains()
    if not table_of_trains[1] then
      game.players[player_index].print("no trains available")
      return
    else
      local table_of_active_trains = {}
      for a,b in pairs(table_of_trains) do
        if b.state == defines.train_state.on_the_path then
          table.insert(table_of_active_trains, b)
        end
      end
      if table_of_active_trains[1] then
        local random_train_index = math.random(table_size(table_of_active_trains))
        create_cutscene_next_tick = {}
        create_cutscene_next_tick[player_index] = {table_of_active_trains[random_train_index], player_index}
        sync_color(player_index)
      else
        if table_of_trains[1].locomotives.front_movers[1] then
          local waypoint_target = table_of_trains[1].locomotives.front_movers[1]
          local created_waypoints = create_waypoint(waypoint_target, player_index)
          sync_color(player_index)
          play_cutscene(created_waypoints, player_index)
        else
          local waypoint_target = table_of_trains[1].locomotives.back_movers[1]
          local created_waypoints = create_waypoint(waypoint_target, player_index)
          sync_color(player_index)
          play_cutscene(created_waypoints, player_index)
        end
      end
    end
  end
end

function create_waypoint(waypoint_target, player_index)
  local tt = {}
  local z = {}
  local mod_settings = game.players[player_index].mod_settings
  if mod_settings["ts-transition-time"].value == 0 then
    tt = 1
  else
    tt = mod_settings["ts-transition-time"].value * 60
  end
  local tw = mod_settings["ts-time-wait"].value * 60 * 60
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
      time_to_wait = tw,
      zoom = z
    }
  }
  return created_waypoints
end

function end_trainsaver(command)
  if game.players[command.player_index].controller_type == defines.controllers.cutscene then
    game.players[command.player_index].exit_cutscene()
  else
  end
end

function sync_color(player_index)
  game.players[player_index].character.color = game.players[player_index].color
end

function play_cutscene(created_waypoints, player_index)
  local player = game.players[player_index]
  player.set_controller(
    {
      type = defines.controllers.cutscene,
      waypoints = created_waypoints,
      start_position = player.position,
      final_transition_time = player.mod_settings["ts-transition-time"].value
    }
  )
end

script.on_event(defines.events.on_train_changed_state, function(train_changed_state_event)
  local train = train_changed_state_event.train
  local old_state = train_changed_state_event.old_state
  local new_state = train_changed_state_event.train.state
  if (--[[((old_state == defines.train_state.path_lost) or (old_state == defines.train_state.no_schedule) or (old_state == defines.train_state.no_path) or (old_state == defines.train_state.arrive_signal) or (old_state == defines.train_state.wait_signal) or (old_state == defines.train_state.arrive_station)or --]] (old_state == defines.train_state.wait_station) --[[or (old_state == defines.train_state.manual_control_stop) or (old_state == defines.train_state.manual_control))--]] and (new_state == defines.train_state.on_the_path) --[[or ((new_state == defines.train_state.manual_control) and (train.speed ~= 0))--]]) then
    game.print("train " .. train.id .. " dispatched from station")
    for a,b in pairs(game.connected_players) do
      if b.controller_type == defines.controllers.cutscene then
        local found_locomotive = b.surface.find_entities_filtered({
          position = b.position,
          radius = 1,
          name = "locomotive",
          limit = 1
        })
        if found_locomotive[1] then
          local player_index = b.index
          local found_train = found_locomotive[1].train
          local found_state = found_train.state
          if ((found_state == defines.train_state.on_the_path) or (found_state == defines.train_state.arrive_signal) or (found_state == defines.train_state.arrive_station)--[[or ((found_state == defines.train_state.manual_control) and (found_locomotive[1].train.speed ~= 0))--]]) then
            if found_train.id == train.id then
              if not create_cutscene_next_tick then
                create_cutscene_next_tick = {}
                create_cutscene_next_tick[player_index] = {train, player_index, "same train"} 
                if wait_at_signal then
                  if wait_at_signal[player_index] then
                    wait_at_signal[player_index] = nil
                  end
                end
              else
                create_cutscene_next_tick[player_index] = {train, player_index, "same train"}
                if wait_at_signal then
                  if wait_at_signal[player_index] then
                    wait_at_signal[player_index] = nil
                  end
                end
              end
            end
          else
            if (found_state == defines.train_state.wait_signal) then
              if not wait_at_signal then
                wait_at_signal = {}
                local until_tick = game.tick + (game.players[player_index].mod_settings["ts-wait-at-signal"].value * 60)
                wait_at_signal[player_index] = until_tick
              else
                if not wait_at_signal[player_index] then
                  local until_tick = game.tick + (game.players[player_index].mod_settings["ts-wait-at-signal"].value * 60)
                  wait_at_signal[player_index] = until_tick
                end
              end
            end
            if not create_cutscene_next_tick then
              create_cutscene_next_tick = {}
              create_cutscene_next_tick[player_index] = {train, player_index}
            else
              create_cutscene_next_tick[player_index] = {train, player_index}
            end
          end
        end
      end
    end
  end
end)

script.on_event(defines.events.on_tick, function()
  if create_cutscene_next_tick then
    for a,b in pairs(create_cutscene_next_tick) do
      local target_train = b[1]
      local player_index = b[2]
      if wait_at_signal then
        if wait_at_signal[player_index] then
          if wait_at_signal[player_index] > game.tick then
            create_cutscene_next_tick[player_index] = nil
            return
          else wait_at_signal[player_index] = nil
          end
        end
      end
      if ((target_train.locomotives.front_movers[1]) and (target_train.locomotives.back_movers[1])) then
        if target_train.speed > 0 then
          local created_waypoints = create_waypoint(target_train.locomotives.front_movers[1], player_index)
          if b[3] then
            created_waypoints[1].transition_time = table_size(target_train.carriages) * 15
          end
          play_cutscene(created_waypoints, player_index)
          create_cutscene_next_tick[player_index] = nil
        end
        if target_train.speed < 0 then
          local created_waypoints = create_waypoint(target_train.locomotives.back_movers[1], player_index)
          if b[3] then
            created_waypoints[1].transition_time = table_size(target_train.carriages) * 15
          end
          play_cutscene(created_waypoints, player_index)
          create_cutscene_next_tick[player_index] = nil
        end
      elseif ((target_train.locomotives.front_movers[1]) or (target_train.locomotives.back_movers[1])) then
        if target_train.locomotives.front_movers[1] then
          local created_waypoints = create_waypoint(target_train.locomotives.front_movers[1], player_index)
          play_cutscene(created_waypoints, player_index)
          create_cutscene_next_tick[player_index] = nil
        end
        if target_train.locomotives.back_movers[1] then
          local created_waypoints = create_waypoint(target_train.locomotives.front_movers[1], player_index)
          play_cutscene(created_waypoints, player_index)
          create_cutscene_next_tick[player_index] = nil
        end
      end
    end
  end
end)
