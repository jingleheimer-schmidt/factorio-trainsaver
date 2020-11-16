
local transitionTimeSetting = {
  type = "int-setting",
  name = "ts-transition-time",
  setting_type = "runtime-per-user",
  minimum_value = 1,
  maximum_value = 1800,
  default_value = 300,
  order = "ts-1"
}

local timeWaitSetting = {
  type = "int-setting",
  name = "ts-time-wait",
  setting_type = "runtime-per-user",
  minimum_value = 1800,
  default_value = 1800,
  order = "ts-2"
}

local zoomSetting = {
  type = "double-setting",
  name = "ts-zoom",
  setting_type = "runtime-per-user",
  minimum_value = .1,
  default_value = .75,
  maximum_value = 100,
  order = "ts-3"
}

data:extend({
  transitionTimeSetting,
  timeWaitSetting,
  zoomSetting
})
