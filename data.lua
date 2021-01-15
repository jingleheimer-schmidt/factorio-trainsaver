local toggleTrainsaverKey = {
  type = "custom-input",
  name = "toggle-trainsaver",
  key_sequence = "COMMAND + T",
  alternative_key_sequence = "CONTROL + T",
  enabled_while_in_cutscene = true,
  action = "lua",
}

local startTrainsaverKey = {
  type = "custom-input",
  name = "start-trainsaver",
  key_sequence = "",
  alternative_key_sequence = "",
  enabled_while_in_cutscene = true,
  action = "lua",
}

local endTrainsaverKey = {
  type = "custom-input",
  name = "end-trainsaver",
  key_sequence = "",
  alternative_key_sequence = "",
  enabled_while_in_cutscene = true,
  action = "lua",
}

local openInventoryTrainsaverKey = {
  type = "custom-input",
  name = "open-inventory-trainsaver",
  key_sequence = "",
  linked_game_control = "open-character-gui",
  enabled_while_in_cutscene = true,
  action = "lua",
}

local openTechnologyGuiTrainsaverKey = {
  type = "custom-input",
  name = "open-research-trainsaver",
  key_sequence = "",
  linked_game_control = "open-technology-gui",
  enabled_while_in_cutscene = true,
  action = "lua",
}

local openProductionStatsGuiTrainsaverKey = {
  type = "custom-input",
  name = "open-production-stats-trainsaver",
  key_sequence = "",
  linked_game_control = "production-statistics",
  enabled_while_in_cutscene = true,
  action = "lua",
}

local openLogisticNetworkGuiTrainsaverKey = {
  type = "custom-input",
  name = "open-logistic-netowrk-trainsaver",
  key_sequence = "",
  linked_game_control = "logistic-networks",
  enabled_while_in_cutscene = true,
  action = "lua",
}

local toggleMenuTrainsaverKey = {
  type = "custom-input",
  name = "toggle-menu-trainsaver",
  key_sequence = "",
  linked_game_control = "toggle-menu",
  enabled_while_in_cutscene = true,
  action = "lua",
}

data:extend({
  toggleTrainsaverKey,
  startTrainsaverKey,
  endTrainsaverKey,
  openInventoryTrainsaverKey,
  openTechnologyGuiTrainsaverKey,
  openProductionStatsGuiTrainsaverKey,
  openLogisticNetworkGuiTrainsaverKey,
  toggleMenuTrainsaverKey,
})
