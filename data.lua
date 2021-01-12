local escapeTrainsaverKey = {
  type = "custom-input",
  name = "escape-trainsaver",
  key_sequence = "ESCAPE",
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
  toggleTrainsaverKey,
})
