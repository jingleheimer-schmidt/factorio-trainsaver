
script.on_init(function()
  commands.add_command("trainsaver", "help text", start_trainsaver)
  commands.add_command("end-trainsaver","- Ends the currently playing cutscene and immediately returns control to the player", end_trainsaver)
end)

script.on_load(function()
  commands.add_command("trainsaver", "help text", start_trainsaver)
  commands.add_command("end-trainsaver","- Ends the currently playing cutscene and immediately returns control to the player", end_trainsaver)
end)

function start_trainsaver(command)
  local player_index = command.player_index
  local name = command.name
  if (name == "trainsaver") and (game.players[player_index].controller_type == defines.controllers.character) then
    local table_of_trains = game.players[player_index].surface.get_trains()
    if not table_of_trains[1] then
      game.print("no trains available :(")
      return
    else
      game.print("syncing color and begining cutscene")
      local table_of_active_trains = {}
      for a,b in pairs(table_of_trains) do
        if b.state == defines.train_state.on_the_path then
          table.insert(table_of_active_trains, b)
        end
      end
      if table_of_active_trains[1] then
        local waypoint_target = {}
        local random_train_index = math.random(table_size(table_of_active_trains))
        game.print("found active train with state " .. table_of_active_trains[random_train_index].state)
        if table_of_active_trains[random_train_index].locomotives.front_movers[1] then
          game.print("found front mover [1]")
          local waypoint_target = table_of_active_trains[random_train_index].locomotives.front_movers[1]
          local created_waypoints = create_starting_waypoint(waypoint_target, player_index)
          sync_color(player_index)
          play_cutscene(created_waypoints, player_index)
        else
          game.print("found back mover [1]")
          local waypoint_target = table_of_active_trains[random_train_index].locomotives.back_movers[1]
          local created_waypoints = create_starting_waypoint(waypoint_target, player_index)
          sync_color(player_index)
          play_cutscene(created_waypoints, player_index)
        end
      else
        game.print("could not find active train")
        if table_of_trains[1].locomotives.front_movers[1] then
          local waypoint_target = table_of_trains[1].locomotives.front_movers[1]
          local created_waypoints = create_starting_waypoint(waypoint_target, player_index)
          sync_color(player_index)
          play_cutscene(created_waypoints, player_index)
        else
          local waypoint_target = table_of_trains[1].locomotives.back_movers[1]
          local created_waypoints = create_starting_waypoint(waypoint_target, player_index)
          sync_color(player_index)
          play_cutscene(created_waypoints, player_index)
        end
      end
    end
  end
end

function create_starting_waypoint(waypoint_target, player_index)
  local tt = {}
  local z = {}
  if game.players[player_index].mod_settings["ts-transition-time"].value == 0 then
    tt = 1
  else
    tt = game.players[player_index].mod_settings["ts-transition-time"].value * 60 -- convert seconds to ticks
  end
  local tw = game.players[player_index].mod_settings["ts-time-wait"].value * 60 * 60 -- convert minutes to ticks
  if game.players[player_index].mod_settings["ts-variable-zoom"].value == true then
    local temp_zoom = game.players[player_index].mod_settings["ts-zoom"].value
    z = (math.random(((temp_zoom - (temp_zoom*.1))*1000),(((temp_zoom + (temp_zoom*.1)))*1000)))/1000
  else
    z = game.players[player_index].mod_settings["ts-zoom"].value
  end
  game.print("tt= " .. tt)
  game.print(" tw= " .. tw)
  game.print(" z= " .. z)
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
  game.print("playing cutscene")
  game.players[player_index].set_controller(
    {
      type = defines.controllers.cutscene,
      waypoints = created_waypoints,
      start_position = game.players[player_index].position,
      final_transition_time = game.players[player_index].mod_settings["ts-transition-time"].value
    }
  )
end

script.on_event(defines.events.on_train_changed_state, function(train_changed_state_event)
  local train = train_changed_state_event.train
  local old_state = train_changed_state_event.old_state
  local new_state = train_changed_state_event.train.state
  -- if any stopped train starts moving, and the player train is stopped, then switch cutscene to the new moving train
  if (((old_state == defines.train_state.path_lost) or (old_state == defines.train_state.no_schedule) or (old_state == defines.train_state.no_path) or (old_state == defines.train_state.arrive_signal) or (old_state == defines.train_state.wait_signal) or (old_state == defines.train_state.arrive_station) or (old_state == defines.train_state.wait_station) or (old_state == defines.train_state.manual_control_stop) or (old_state == defines.train_state.manual_control)) and (new_state == defines.train_state.on_the_path)) then
    for a,b in pairs(game.connected_players) do
      if b.controller_type == defines.controllers.cutscene then
        local found_locomotive = b.surface.find_entities_filtered({
          position = b.position,
          radius = 5,
          name = "locomotive",
          limit = 1
        })
        if found_locomotive[1] then
          local found_state = found_locomotive[1].train.state
          if ((found_state == defines.train_state.on_the_path) or (found_state == defines.train_state.arrive_signal) --[[or (found_state == defines.train_state.arrive_station)--]]) then
            game.print("found train has state " .. found_state .. ". No new cutscene necessary")
            return
          else
            game.print("found train has state " .. found_state .. ". Creating new cutscene...")
            local created_waypoints = create_waypoints_from_event(train, b.index)
            if created_waypoints then
              play_cutscene(created_waypoints, b.index)
            else
              game.print("failed to create waypoints from event")
            end
          end
        else
          game.print("no locomotive near player")
        end
      end
    end
  end
end)

function create_waypoints_from_event(train, player_index)
  local waypoint_target = {}
  local tt = {}
  local z = {}
  if train.locomotives.front_movers[1] then
    waypoint_target = train.locomotives.front_movers[1]
  else
    if train.locomotives.back_movers[1] then
      waypoint_target = train.locomotives.back_movers[1]
    end
  end
  if game.players[player_index].mod_settings["ts-transition-time"].value == 0 then
    tt = 1
  else
    tt = game.players[player_index].mod_settings["ts-transition-time"].value * 60 -- convert seconds to ticks
  end
  local tw = game.players[player_index].mod_settings["ts-time-wait"].value * 60 * 60 -- convert minutes to ticks
  if game.players[player_index].mod_settings["ts-variable-zoom"].value == true then
    local temp_zoom = game.players[player_index].mod_settings["ts-zoom"].value
    z = (math.random(((temp_zoom - (temp_zoom*.1))*1000),(((temp_zoom + (temp_zoom*.1)))*1000)))/1000
  else
    z = game.players[player_index].mod_settings["variable-zoom"].value
  end
  local waypoints = {
    {
      target = waypoint_target,
      transition_time = tt,
      time_to_wait = tw,
      zoom = z,
    }
  }
  return waypoints
end

--[[
defines.train_state.on_the_path           Normal state -- following the path.
defines.train_state.path_lost             Had path and lost it -- must stop.
defines.train_state.no_schedule           Doesn't have anywhere to go.
defines.train_state.no_path               Has no path and is stopped.
defines.train_state.arrive_signal         Braking before a rail signal.
defines.train_state.wait_signal           Waiting at a signal.
defines.train_state.arrive_station        Braking before a station.
defines.train_state.wait_station          Waiting at a station.
defines.train_state.manual_control_stop   Switched to manual control and has to stop.
defines.train_state.manual_control        Can move if user explicitly sits in and rides the train.
--]]

--[[
local states = {
  defines.train_state.on_the_path,
  defines.train_state.path_lost,
  defines.train_state.no_schedule,
  defines.train_state.no_path,
  defines.train_state.arrive_signal,
  defines.train_state.wait_signal,
  defines.train_state.arrive_station,
  defines.train_state.wait_station,
  defines.train_state.manual_control_stop,
  defines.train_state.manual_control
}
--]]

--[[
script.on_nth_tick(60, function()
  -- continue_trainsaver()
  game.print("continuing trainsaver")
  for a,b in pairs(game.connected_players) do
    --game.print(b.name)
    if b.controller_type == defines.controllers.cutscene then
      -- game.print(b.name .. " is in cutscene")
      local found_locomotive = b.surface.find_entities_filtered(
        {
          position = b.position,
          radius = 5,
          name = "locomotive",
          limit = 1
        }
      )
      if found_locomotive[1] then
        game.print("found train with state " .. found_locomotive[1].train.state)
        local trainstate = found_locomotive[1].train.state
        if ((trainstate == defines.train_state.path_lost) or (trainstate == defines.train_state.no_schedule) or (trainstate == defines.train_state.no_path) or (trainstate == defines.train_state.wait_signal) or (trainstate == defines.train_state.wait_station) or (trainstate == defines.train_state.manual_control_stop) or (trainstate == defines.train_state.manual_control)) then
          game.print("train state = " .. found_locomotive[1].train.state .. " finding new train")
          local created_waypoints = create_waypoints(b.index)
          if created_waypoints then
            -- game.print("playing new cutscnene")
            -- sync_color(b.index)
            play_cutscene(created_waypoints, b.index)
          else return
          end
        else return
        end
      else game.print("no current train") return
      end
    else game.print("no one in cutscene") return
    end
  end
end
)
--]]

--[[
function create_waypoints(player_index)
  local table_of_trains = game.players[player_index].surface.get_trains()
  if not table_of_trains[1] then
    game.print("no trains")
    return
  else
    -- game.print("trains found")
    local table_of_active_trains = {}
    for a,b in pairs(table_of_trains) do
      if ((b.state == defines.train_state.on_the_path) or (b.state == defines.train_state.arrive_signal) or (b.state == defines.train_state.arrive_station)) then
        table.insert(table_of_active_trains, b)
      end
    end
    if table_of_active_trains[1] then
      local random_train_index = math.random(table_size(table_of_active_trains))
      game.print("found active train with state " .. table_of_active_trains[random_train_index].state)
      local waypoint_target = {}
      if table_of_active_trains[random_train_index].locomotives.front_movers then
        waypoint_target = table_of_active_trains[random_train_index].locomotives.front_movers[1]
      elseif table_of_active_trains[random_train_index].locomotives.back_movers then
        waypoint_target = table_of_active_trains[random_train_index].locomotives.back_movers[1]
      end
      local waypoints = {
        {
          target = waypoint_target,
          transition_time = game.players[player_index].mod_settings["ts-transition-time"].value,
          time_to_wait = game.players[player_index].mod_settings["ts-time-wait"].value,
          zoom = game.players[player_index].mod_settings["ts-zoom"].value
        }
      }
      -- game.print(waypoints[1].transition_time)
      return waypoints
    else
      game.print("could not find active train")
      if table_of_trains[1].locomotives.front_movers then
        waypoint_target = table_of_trains[1].locomotives.front_movers[1]
      elseif table_of_trains[1].locomotives.back_movers then
        waypoint_target = table_of_trains[1].locomotives.back_movers[1]
      end
      local waypoints = {
        {
          target = waypoint_target,
          transition_time = game.players[player_index].mod_settings["ts-transition-time"].value,
          time_to_wait = game.players[player_index].mod_settings["ts-time-wait"].value,
          zoom = game.players[player_index].mod_settings["ts-zoom"].value
        }
      }
      return waypoints
    end
  end
end
--]]
