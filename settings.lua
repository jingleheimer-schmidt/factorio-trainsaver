
local transitionTimeSetting = {
  type = "double-setting",
  name = "ts-transition-time",
  setting_type = "runtime-per-user",
  minimum_value = 0,
--   maximum_value = 1800,
  default_value = 0, -- seconds, will be converted to ticks
  order = "ts-1"
}

local waitAtSignalSetting = {
  type = "int-setting",
  name = "ts-wait-at-signal",
  setting_type = "runtime-per-user",
  default_value = 30, -- seconds, will be converted to ticks
  order = "ts-2"
}

local zoomSetting = {
  type = "double-setting",
  name = "ts-zoom",
  setting_type = "runtime-per-user",
  minimum_value = .1,
  default_value = .3,
  maximum_value = 5,
  order = "ts-3"
}

local variableZoomSetting = {
  type = "bool-setting",
  name = "ts-variable-zoom",
  setting_type = "runtime-per-user",
  default_value = true,
  order = "ts-4"
}

local timeWaitSetting = {
  type = "double-setting",
  name = "ts-time-wait",
  setting_type = "runtime-per-user",
  minimum_value = 1/60,
  default_value = 10, -- minutes, will be converted to ticks
  order = "ts-5"
}

local afkAutoStartSetting = {
  type = "int-setting",
  name = "ts-afk-auto-start",
  setting_type = "runtime-per-user",
  minimum_value = 0,
  default_value = 5, -- minutes, will be converted to ticks
  order = "ts-6"
}

local menuEndsTrainsaverSetting = {
  type = "bool-setting",
  name = "ts-menu-hotkey",
  setting_type = "runtime-per-user",
  default_value = true,
  order = "ts-7"
}

local hiddenSecretsSetting = {
  type = "bool-setting",
  name = "ts-secrets",
  setting_type = "runtime-per-user",
  default_value = false,
  order = "ts-8"
}

data:extend({
  transitionTimeSetting,
  timeWaitSetting,
  zoomSetting,
  variableZoomSetting,
  waitAtSignalSetting,
  afkAutoStartSetting,
  menuEndsTrainsaverSetting,
  hiddenSecretsSetting,
})
