
script.on_init(function()
  commands.add_command("trainsaver", "starts a dynamic screensaver that follows active trains.", start_trainsaver)
  commands.add_command("end-trainsaver","- Ends the screensaver and immediately returns control to the player", end_trainsaver)
end)

script.on_load(function()
  commands.add_command("trainsaver", "starts a dynamic screensaver that follows active trains.", start_trainsaver)
  commands.add_command("end-trainsaver","- Ends the screensaver and immediately returns control to the player", end_trainsaver)
end)

function start_trainsaver(command)
  game.print("start_trainsaver() --> name = " .. command.name .. ", player_index = " .. command.player_index)
  local player_index = command.player_index
  local name = command.name
  if (name == "trainsaver") and ((game.players[player_index].controller_type == defines.controllers.character) or (command.entity_gone_restart == "yes")) then

    -- create a table of all the trains
    local table_of_trains = game.players[player_index].surface.get_trains()

    -- if there's no trains, end everything
      -- do we need to end_trainsaver() when entity_gone_restart() is called?
    if not table_of_trains[1] then
      game.players[player_index].print("no trains available")
      return

    -- if there are any trains, make a table of all the active (on_the_path) ones
    else
      local table_of_active_trains = {}
      for a,b in pairs(table_of_trains) do
        if b.state == defines.train_state.on_the_path then
          table.insert(table_of_active_trains, b)
        end
      end

      -- if there are any trains on_the_path, pick a random one and pass it through create_cutscene_next_tick global
      if table_of_active_trains[1] then
        local random_train_index = math.random(table_size(table_of_active_trains))
        if not create_cutscene_next_tick then
          create_cutscene_next_tick = {}
          create_cutscene_next_tick[player_index] = {table_of_active_trains[random_train_index], player_index}
        else
          create_cutscene_next_tick[player_index] = {table_of_active_trains[random_train_index], player_index}
        end
        if not command.entity_gone_restart == "yes" then
          sync_color(player_index)
        end

      -- if there are no trains on_the_path then make a table of trains waiting at stations
      else
        local table_of_trains_at_the_station = {}
        for c,d in pairs(table_of_trains) do
          if d.state == defines.train_state.wait_station then
            table.insert(table_of_trains_at_the_station, d)
          end
        end

        -- if there are any trains waiting at stations, pick a random one and play a cutscene from a front or back mover loco
        if table_of_trains_at_the_station[1] then
          local random_train_index = math.random(table_size(table_of_trains_at_the_station))
          local waypoint_target = {}
          if table_of_trains_at_the_station[random_train_index].locomotives.front_movers[1] then
            waypoint_target = table_of_trains_at_the_station[random_train_index].locomotives.front_movers[1]
          else if table_of_trains_at_the_station[random_train_index].locomotives.back_movers[1] then
            waypoint_target = table_of_trains_at_the_station[random_train_index].locomotives.back_movers[1]
          end
          local created_waypoints = create_waypoint(waypoint_target, player_index)
          if not command.entity_gone_restart == "yes" then
            sync_color(player_index)
          end
          play_cutscene(created_waypoints, player_index)

        -- if there are no trains on_the_path or waiting at stations, then pick the first train from table_of_trains and play cutscene with either front or back mover as target
        elseif table_of_trains[1].locomotives.front_movers[1] then
          local waypoint_target = table_of_trains[1].locomotives.front_movers[1]
          local created_waypoints = create_waypoint(waypoint_target, player_index)
          if not command.entity_gone_restart == "yes" then
            sync_color(player_index)
          end
          play_cutscene(created_waypoints, player_index)
        else
          if table_of_trains[1].locomotives.back_movers[1] then
            local waypoint_target = table_of_trains[1].locomotives.back_movers[1]
            local created_waypoints = create_waypoint(waypoint_target, player_index)
            if not command.entity_gone_restart == "yes" then
              sync_color(player_index)
            end
            play_cutscene(created_waypoints, player_index)

          -- if there are no trains on the path or waiting at station, and table_of_trains[1] didn't have a front or back mover (how would this happen?) then end_trainsaver()
          else
            game.print("no trains on the path or waiting at station and table_of_trains[1] didn't have front or back movers. ending trainsaver.")
            local command = {player_index = player_index}
            end_trainsaver(command)
          end
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
  local player_index = command.player_index
  if game.players[player_index].controller_type == defines.controllers.cutscene then
    game.players[player_index].exit_cutscene()
    if followed_loco then
      if followed_loco[player_index] then
        followed_loco[player_index] = nil
      end
    end
    if create_cutscene_next_tick then
      if create_cutscene_next_tick[player_index] then
        create_cutscene_next_tick[player_index]= nil
      end
    end
    if start_trainsaver_next_tick then
      if start_trainsaver_next_tick[player_index] then
        start_trainsaver_next_tick[player_index]= nil
      end
    end
    if wait_at_signal then
      if wait_at_signal[player_index] then
        wait_at_signal[player_index]= nil
      end
    end
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
  if not followed_loco then
    followed_loco = {}
    followed_loco[player_index] = created_waypoints[1].target.unit_number
    game.print("play_cutscene() -- followed_loco = " .. followed_loco[player_index])
  else
    followed_loco[player_index] = created_waypoints[1].target.unit_number
    game.print("play_cutscene() -- followed_loco = " .. followed_loco[player_index])
  end
end

script.on_event(defines.events.on_train_changed_state, function(train_changed_state_event)
  local train = train_changed_state_event.train
  local old_state = train_changed_state_event.old_state
  local new_state = train_changed_state_event.train.state
  if (--[[((old_state == defines.train_state.path_lost) or (old_state == defines.train_state.no_schedule) or (old_state == defines.train_state.no_path) or (old_state == defines.train_state.arrive_signal) or (old_state == defines.train_state.wait_signal) or (old_state == defines.train_state.arrive_station)or --]] (old_state == defines.train_state.wait_station) --[[or (old_state == defines.train_state.manual_control_stop) or (old_state == defines.train_state.manual_control))--]] and ((new_state == defines.train_state.on_the_path) or (new_state == defines.train_state.arrive_signal)) --[[or ((new_state == defines.train_state.manual_control) and (train.speed ~= 0))--]]) then
    for a,b in pairs(game.connected_players) do
      if b.controller_type == defines.controllers.cutscene then
        game.print("train " .. train.id .. " dispatched from station")
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

          -- when a train changes from stopped at station to on the path or arriving at signal, and player controller is cutscene, and there's a locomotive within 1 tile of player, and that locomotive train state is on the path or arriving at signal or station, then if the train that changed state is the same train under the player, make sure we're following the leading locomotive.
          if ((found_state == defines.train_state.on_the_path) or (found_state == defines.train_state.arrive_signal) or (found_state == defines.train_state.arrive_station)--[[or ((found_state == defines.train_state.manual_control) and (found_locomotive[1].train.speed ~= 0))--]]) then

            -- if camera is on train that changed state, switch to leading locomotive
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

            -- if camera train is waiting at signal, update the wait_at_signal global if necessary, then continue creating the cutscene (cutscene will not be constructed next tick depending on the value of untill_tick)
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

            -- if the train the camera is following has any state other than on_the_path, arrive_signal, or arrive_station, then create a cutscene following the train that generated the change_state event on the next tick
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

script.on_event(defines.events.on_entity_damaged, function(character_damaged_event) character_damaged(character_damaged_event) end, {{filter = "type", type = "character"}})

function character_damaged(character_damaged_event)
  local damaged_entity = character_damaged_event.entity
  for a,b in pairs(game.connected_players) do
    if b.controller_type == defines.controllers.cutscene then
      if b.cutscene_character == damaged_entity then
        local command = {player_index = b.index}
        end_trainsaver(command)
      end
    end
  end
end

script.on_event(defines.events.on_post_entity_died, function(event) locomotive_gone(event) end, {{filter = "type", type = "locomotive"}})
script.on_event(defines.events.on_player_mined_entity, function(event) locomotive_gone(event) end, {{filter = "type", type = "locomotive"}})
script.on_event(defines.events.on_robot_mined_entity, function(event) locomotive_gone(event) end, {{filter = "type", type = "locomotive"}})

function locomotive_gone(event)
  local locomotive = {}
  if event.entity then
    locomotive = event.entity
  end
  if event.unit_number then
    locomotive = {unit_number = event.unit_number}
  end
  for a,b in pairs(game.connected_players) do
    if b.controller_type == defines.controllers.cutscene then
      local player_index = b.index
      if followed_loco then
        game.print("check 1")
        if followed_loco[player_index] then
          game.print("check 2")
          if followed_loco[player_index] == locomotive.unit_number then
            game.print("check 3")
            local command = {
              name = "trainsaver",
              player_index = player_index,
              entity_gone_restart = "yes"
              }
            -- if not start_trainsaver_next_tick then
            --   start_trainsaver_next_tick = {}
            --   start_trainsaver_next_tick[player_index] = command
            -- else
            --   start_trainsaver_next_tick[player_index] = command
            -- end
            game.print("locomotive_gone() --> name = " .. command.name .. ", player_index = " .. command.player_index)
            start_trainsaver(command)
          end
        end
      end
    end
  end
end

script.on_event(defines.events.on_tick, function()
  -- if start_trainsaver_next_tick then
  --   for a,b in pairs(start_trainsaver_next_tick) do
  --     player_index = b.player_index
  --     start_trainsaver(start_trainsaver_next_tick[player_index])
  --     start_trainsaver_next_tick[player_index] = nil
  --     return
  --   end
  -- end
  if create_cutscene_next_tick then
    for a,b in pairs(create_cutscene_next_tick) do
      local target_train = b[1]
      local player_index = b[2]

      -- make sure the player is still connected
      if not game.players[player_index].connected then
        return
      end
      -- if not game.players[player_index].controller_type == defines.controllers.cutscene then
      --   return
      -- end

      -- is this one really necessary? not sure
      if not (target_train.locomotives.front_movers[1].valid or target_train.locomotives.back_movers[1].valid) then
        return
      end

      -- if wait_at_signal untill_tick is greater than current game tick, then don't create a new cutscene: end everything and wait until next train state update. If we've passed the untill_tick, then set it to nill and continue creating the cutscene
      if wait_at_signal then
        if wait_at_signal[player_index] then
          if wait_at_signal[player_index] > game.tick then
            game.print("train waiting at signal, no new cutscene")
            create_cutscene_next_tick[player_index] = nil
            return
          else
            wait_at_signal[player_index] = nil
          end
        end
      end

      -- if the target train has both front and back movers, then figure out which is leading the train based on if speed is + or -
      if ((target_train.locomotives.front_movers[1]) and (target_train.locomotives.back_movers[1])) then
        if target_train.speed > 0 then
          local created_waypoints = create_waypoint(target_train.locomotives.front_movers[1], player_index)
          if b[3] then
            game.print("b3= " .. b[3])
            created_waypoints[1].transition_time = table_size(target_train.carriages) * 15
            created_waypoints[1].zoom = nil
          end
          game.print("front and back, switched to front")
          play_cutscene(created_waypoints, player_index)
          create_cutscene_next_tick[player_index] = nil
        end
        if target_train.speed < 0 then
          local created_waypoints = create_waypoint(target_train.locomotives.back_movers[1], player_index)
          if b[3] then
            game.print("b3= " .. b[3])
            created_waypoints[1].transition_time = table_size(target_train.carriages) * 15
            created_waypoints[1].zoom = nil
          end
          game.print("front and back, switched to back")
          play_cutscene(created_waypoints, player_index)
          create_cutscene_next_tick[player_index] = nil
        end
      elseif ((target_train.locomotives.front_movers[1]) or (target_train.locomotives.back_movers[1])) then
        if target_train.locomotives.front_movers[1] then
          local created_waypoints = create_waypoint(target_train.locomotives.front_movers[1], player_index)
          if b[3] then
            game.print("b3= " .. b[3])
            created_waypoints[1].zoom = nil
          end
          game.print("only front, using front")
          play_cutscene(created_waypoints, player_index)
          create_cutscene_next_tick[player_index] = nil
        end
        if target_train.locomotives.back_movers[1] then
          local created_waypoints = create_waypoint(target_train.locomotives.back_movers[1], player_index)
          if b[3] then
            game.print("b3= " .. b[3])
            created_waypoints[1].zoom = nil
          end
          game.print("only back, using back")
          play_cutscene(created_waypoints, player_index)
          create_cutscene_next_tick[player_index] = nil
        end
      end
    end
  end
end)

script.on_nth_tick(1800, function()
  for a,b in pairs(game.connected_players) do
    if b.mod_settings["ts-afk-auto-start"].value == 0 then
      game.print("trainsaver afk auto start is off")
      return
    end
    if b.afk_time > (b.mod_settings["ts-afk-auto-start"].value * 60 * 60) then
      game.print("trainsaver afk auto start")
      local command = {name = "trainsaver", player_index = b.index}
      start_trainsaver(command)
    end
  end
end)
