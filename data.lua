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

local openTrainGuiTrainsaverKey = {
  type = "custom-input",
  name = "open-train-gui-trainsaver",
  key_sequence = "",
  linked_game_control = "open-trains-gui",
  enabled_while_in_cutscene = true,
  action = "lua",
}

local selfReflectionAchievement = {
  type = "achievement",
  name = "trainsaver-self-reflection",
  order = "t[secret]-a[self-reflection]",
  icon = "__base__/graphics/achievement/so-long-and-thanks-for-all-the-fish.png",
  icon_size = 128,
  hidden = false,
}

local findAFriendAchievement = {
  type = "achievement",
  name = "trainsaver-find-a-friend",
  order = "t[secret]-a[find-a-friend]",
  icon = "__base__/graphics/achievement/so-long-and-thanks-for-all-the-fish.png",
  icon_size = 128,
  hidden = false,
}

local continuousTenMinuteschievement = {
  type = "achievement",
  name = "trainsaver-continuous-10-minutes",
  order = "t[secret]-b[1][continuous-10-minutes]",
  icon = "__base__/graphics/achievement/so-long-and-thanks-for-all-the-fish.png",
  icon_size = 128,
  hidden = false,
}

local continuousThirtyMinuteschievement = {
  type = "achievement",
  name = "trainsaver-continuous-30-minutes",
  order = "t[secret]-b[2][continuous-30-minutes]",
  icon = "__base__/graphics/achievement/so-long-and-thanks-for-all-the-fish.png",
  icon_size = 128,
  hidden = false,
}

local continuousOneHourchievement = {
  type = "achievement",
  name = "trainsaver-continuous-1-hour",
  order = "t[secret]-b[3][continuous-1-hour]",
  icon = "__base__/graphics/achievement/so-long-and-thanks-for-all-the-fish.png",
  icon_size = 128,
  hidden = false,
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
  openTrainGuiTrainsaverKey,
  selfReflectionAchievement,
  findAFriendAchievement,
  continuousTenMinuteschievement,
  continuousThirtyMinuteschievement,
  continuousOneHourchievement,
})
