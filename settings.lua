
local transitionTimeSetting = {
  type = "int-setting",
  name = "ts-transition-time",
  setting_type = "runtime-per-user",
  minimum_value = 1,
  default_value = 120,
  order = "ts-1"
}

local timeWaitSetting = {
  type = "int-setting",
  name = "ts-time-wait",
  setting_type = "runtime-per-user",
  minimum_value = 1,
  default_value = 60,
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
