local escapeTrainsaverKey = {
  type = "custom-input",
  name = "escape-trainsaver",
  key_sequence = "ESCAPE",
  alternative_key_sequence = "RETURN",
  enabled_while_in_cutscene = true,
  action = "lua",
}

local openGuiTrainsaverKey = {
  type = "custom-input",
  name = "open-inventory-trainsaver",
  linked_game_control = "open-gui"
  enabled_while_in_cutscene = true,
  action = "lua",
}

local toggleTrainsaverKey = {
  type = "custom-input",
  name = "toggle-trainsaver",
  key_sequence = "COMMAND + T",
  alternative_key_sequence = "CONTROL + T",
  enabled_while_in_cutscene = true,
  action = "lua",
}

data:extend({
  escapeTrainsaverKey,
  openGuiTrainsaverKey,
  toggleTrainsaverKey,
})
