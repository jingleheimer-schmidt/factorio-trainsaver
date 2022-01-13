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

local toggleDrivingTrainsaverKey = {
  type = "custom-input",
  name = "toggle-driving-trainsaver",
  key_sequence = "",
  linked_game_control = "toggle-driving",
  enabled_while_in_cutscene = true,
  action = "lua",
}

local selfReflectionAchievement = {
  type = "achievement",
  name = "trainsaver-self-reflection",
  order = "t[secret]-a[1][self-reflection]",
  icon = "__base__/graphics/achievement/lazy-bastard.png",
  icon_size = 128,
  hidden = false,
}

local findAFriendAchievement = {
  type = "achievement",
  name = "trainsaver-find-a-friend",
  order = "t[secret]-a[2][find-a-friend]",
  icon = "__base__/graphics/achievement/lazy-bastard.png",
  icon_size = 128,
  hidden = false,
}

local continuousTenMinutesAchievement = {
  type = "achievement",
  name = "trainsaver-continuous-10-minutes",
  order = "t[secret]-b[1][continuous-10-minutes]",
  icon = "__base__/graphics/achievement/getting-on-track.png",
  icon_size = 128,
  hidden = true,
}

local continuousThirtyMinutesAchievement = {
  type = "achievement",
  name = "trainsaver-continuous-30-minutes",
  order = "t[secret]-b[2][continuous-30-minutes]",
  icon = "__base__/graphics/achievement/getting-on-track.png",
  icon_size = 128,
  hidden = true,
}

local continuousOneHourAchievement = {
  type = "achievement",
  name = "trainsaver-continuous-60-minutes",
  order = "t[secret]-b[3][continuous-60-minutes]",
  icon = "__base__/graphics/achievement/getting-on-track-like-a-pro.png",
  icon_size = 128,
  hidden = true,
}

local totalOneHoursAchievement = {
  type = "achievement",
  name = "trainsaver-1-hours-total",
  order = "t[secret]-c[1][1-hours-total]",
  icon = "__base__/graphics/achievement/getting-on-track.png",
  icon_size = 128,
  hidden = true,
}

local totalTwoHoursAchievement = {
  type = "achievement",
  name = "trainsaver-2-hours-total",
  order = "t[secret]-c[2][2-hours-total]",
  icon = "__base__/graphics/achievement/getting-on-track.png",
  icon_size = 128,
  hidden = true,
}

local totalFiveHoursAchievement = {
  type = "achievement",
  name = "trainsaver-5-hours-total",
  order = "t[secret]-c[3][5-hours-total]",
  icon = "__base__/graphics/achievement/getting-on-track-like-a-pro.png",
  icon_size = 128,
  hidden = true,
}

local rocketLaunchedAchievement = {
  type = "achievement",
  name = "trainsaver-a-spectacular-view",
  order = "t[secret]-d[1][a-spectacular-view]",
  icon = "__base__/graphics/achievement/smoke-me-a-kipper-i-will-be-back-for-breakfast.png",
  icon_size = 128,
  hidden = true,
}

local characterDamagedAchievement = {
  type = "achievement",
  name = "trainsaver-character-damaged",
  order = "t[secret]-d[2][character-damaged]",
  icon = "__base__/graphics/achievement/watch-your-step.png",
  icon_size = 128,
  hidden = true,
}

local damagedByFollowedTrainAchievement = {
  type = "achievement",
  name = "trainsaver-damaged-by-followed-train",
  order = "t[secret]-d[3][damaged-by-followed-train]",
  icon = "__base__/graphics/achievement/watch-your-step.png",
  icon_size = 128,
  hidden = true,
}

local theLongHaulAchievement = {
  type = "achievement",
  name = "trainsaver-long-haul",
  order = "t[secret]-a[3][long-haul]",
  icon = "__base__/graphics/achievement/watch-your-step.png",
  icon_size = 128,
  hidden = true,
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
  toggleDrivingTrainsaverKey,
  selfReflectionAchievement,
  findAFriendAchievement,
  continuousTenMinutesAchievement,
  continuousThirtyMinutesAchievement,
  continuousOneHourAchievement,
  totalOneHoursAchievement,
  totalTwoHoursAchievement,
  totalFiveHoursAchievement,
  rocketLaunchedAchievement,
  characterDamagedAchievement,
  damagedByFollowedTrainAchievement,
  theLongHaulAchievement,
})
