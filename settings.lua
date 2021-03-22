
local transitionSpeedSetting = {
  type = "double-setting",
  name = "ts-transition-speed",
  setting_type = "runtime-per-user",
  minimum_value = 0,
  default_value = 0, -- km/h, will be converted to time (ticks)
  order = "ts-a-a"
}

local transitionTimeSetting = {
  type = "double-setting",
  name = "ts-transition-time",
  setting_type = "runtime-per-user",
  minimum_value = 0,
--   maximum_value = 1800,
  default_value = 0, -- km/h, will be converted to time (ticks)
  order = "ts-a-b"
}

local waitAtSignalSetting = {
  type = "int-setting",
  name = "ts-wait-at-signal",
  setting_type = "runtime-per-user",
  default_value = 30, -- seconds, will be converted to ticks
  order = "ts-b"
}

local timeWaitSetting = {
  type = "double-setting",
  name = "ts-time-wait",
  setting_type = "runtime-per-user",
  minimum_value = 1, -- need to have at least 1 minute of "inactivity", because it's not actually inactivity, it's how long the cutscene lasts before returning to player.
  default_value = 15, -- minutes, will be converted to ticks
  order = "ts-c"
}

local afkAutoStartSetting = {
  type = "double-setting",
  name = "ts-afk-auto-start",
  setting_type = "runtime-per-user",
  minimum_value = 0,
  default_value = 5, -- minutes, will be converted to ticks
  order = "ts-d"
}

local zoomSetting = {
  type = "double-setting",
  name = "ts-zoom",
  setting_type = "runtime-per-user",
  minimum_value = .1,
  default_value = .3,
  maximum_value = 5,
  order = "ts-e"
}

local variableZoomSetting = {
  type = "bool-setting",
  name = "ts-variable-zoom",
  setting_type = "runtime-per-user",
  default_value = true,
  order = "ts-f"
}

local autoStartWhileGuiIsOpenSetting = {
  type = "bool-setting",
  name = "ts-autostart-while-gui-is-open",
  setting_type = "runtime-per-user",
  default_value = false,
  order = "ts-g"
}

local autoStartWhileViewingMapSetting = {
  type = "bool-setting",
  name = "ts-autostart-while-viewing-map",
  setting_type = "runtime-per-user",
  default_value = true,
  order = "ts-h"
}

local menuEndsTrainsaverSetting = {
  type = "bool-setting",
  name = "ts-menu-hotkey",
  setting_type = "runtime-per-user",
  default_value = true,
  order = "ts-i"
}

local linkedGameControlEndsTrainsaverSetting = {
  type = "bool-setting",
  name = "ts-linked-game-control-hotkey",
  setting_type = "runtime-per-user",
  default_value = true,
  order = "ts-j"
}

local hiddenSecretsSetting = {
  type = "bool-setting",
  name = "ts-secrets",
  setting_type = "runtime-per-user",
  default_value = false,
  order = "ts-z"
}

data:extend({
  transitionSpeedSetting,
  transitionTimeSetting,
  timeWaitSetting,
  zoomSetting,
  variableZoomSetting,
  waitAtSignalSetting,
  afkAutoStartSetting,
  menuEndsTrainsaverSetting,
  autoStartWhileViewingMapSetting,
  autoStartWhileGuiIsOpenSetting,
  linkedGameControlEndsTrainsaverSetting,
  hiddenSecretsSetting,
})
