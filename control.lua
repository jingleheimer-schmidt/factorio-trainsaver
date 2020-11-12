--[[
on command get all trains. find if train is moving, then make cutscene for various moving trains. 
  - still play cutscene if no trains are moving? i think yes, but cut to moving train as soon as one is available
When does it switch to a new train to follow?
  - maybe check every so often that followed train is still moving. If not then find a moving train and switch cutscene (end, create new) to new train
on_nth_tick search for new train to follow
  - check what controller player has, only search if player has cutscene controller
--]]

script.on_init(function()
  commands.add_command("trainsaver", "help text", start_trainsaver)
  commands.add_command("end-trainsaver","- Ends the currently playing cutscene and immediately returns control to the player", end_trainsaver)
end)

script.on_load(function()
  commands.add_command("trainsaver", "help text", start_trainsaver)
  commands.add_command("end-trainsaver","- Ends the currently playing cutscene and immediately returns control to the player", end_trainsaver)
end)

function end_trainsaver(command)
  if game.players[command.player_index].controller_type == defines.controllers.cutscene then
    game.players[command.player_index].exit_cutscene()
  else
    game.print("user error: no trainsaver to end")
  end
end

function start_trainsaver(command)
  local player_index = command.player_index
  local parameter = command.parameter
  local name = command.name
  if game.players[player_index].controller_type == defines.controllers.cutscene then
    game.print("[color=blue]Wait. That's illegal.[/color]")
    return
  end
  if name == "trainsaver" then
    local created_waypoints = create_waypoints(player_index)
    if created_wayypoints then
      for a,b in pairs(created_waypoints) do
        if not ( b.target or b.position ) then
          game.print("No trains available :(")
          return
        end
      end
    sync_color(player_index)
    play_cutscene(created_waypoints, player_index)
    end
  end
end
  
function create_waypoints(player_index)
  local table_of_trains = game.players[player_index].surface.get_trains()
  if not table_of_trains[1] then
    return
  else 
    local table_of_active_trains = {}
    for a,b in pairs(table_of_trains) do
      if b.speed > 0 then
        table.insert(table_of_active_trains, b)
      end
    end
    local waypoints = {
      {
        target = XYZ,
        
      },
      {},
      {},
    }

function sync_color(player_index)
  game.players[player_index].character.color = game.players[player_index].color
end
  
function play_cutscene(created_waypoints, player_index)
  game.players[player_index].set_controller{
    type = defines.controllers.cutscene,
    waypoints = created_waypoints,
    start_position = game.players[player_index].position,
    final_transition_time = game.players[player_index].mod_settings["cc-transition-time"].value
  }
end
